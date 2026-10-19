// On-device pose tracking for Fitness Computer Vision Studio.
// Camera stream starts immediately without network blocking;
// MediaPipe Pose Landmarker loads in the background via WebAssembly.

const WASM = "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.14/wasm";
const MODEL =
  "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_full/float16/1/pose_landmarker_full.task";

let PoseLandmarker = null;
let FilesetResolver = null;
let DrawingUtils = null;
let landmarker = null;

// Clean fitness body connections excluding cluttered facial mesh lines
const FITNESS_CONNECTIONS = [
  // Shoulders & Arms
  { start: 11, end: 12 }, // Left shoulder to Right shoulder
  { start: 11, end: 13 }, // Left shoulder to Left elbow
  { start: 13, end: 15 }, // Left elbow to Left wrist
  { start: 12, end: 14 }, // Right shoulder to Right elbow
  { start: 14, end: 16 }, // Right elbow to Right wrist
  // Torso
  { start: 11, end: 23 }, // Left shoulder to Left hip
  { start: 12, end: 24 }, // Right shoulder to Right hip
  { start: 23, end: 24 }, // Left hip to Right hip
  // Lower body
  { start: 23, end: 25 }, // Left hip to Left knee
  { start: 25, end: 27 }, // Left knee to Left ankle
  { start: 24, end: 26 }, // Right hip to Right knee
  { start: 26, end: 28 }, // Right knee to Right ankle
];

function drawFitnessSkeleton(ctx, landmarks, boneColor, jointColor) {
  if (!landmarks || !landmarks.length) return;
  const w = ctx.canvas.width;
  const h = ctx.canvas.height;

  // 1. Draw body bones
  ctx.lineWidth = 4;
  ctx.lineCap = "round";
  ctx.strokeStyle = boneColor;

  for (const conn of FITNESS_CONNECTIONS) {
    const p1 = landmarks[conn.start];
    const p2 = landmarks[conn.end];
    if (p1 && p2 && (p1.visibility ?? 1) >= 0.35 && (p2.visibility ?? 1) >= 0.35) {
      ctx.beginPath();
      ctx.moveTo(p1.x * w, p1.y * h);
      ctx.lineTo(p2.x * w, p2.y * h);
      ctx.stroke();
    }
  }

  // 2. Draw fitness joints (shoulders, elbows, wrists, hips, knees, ankles)
  const keyJoints = [11, 12, 13, 14, 15, 16, 23, 24, 25, 26, 27, 28];
  for (const idx of keyJoints) {
    const pt = landmarks[idx];
    if (pt && (pt.visibility ?? 1) >= 0.35) {
      const x = pt.x * w;
      const y = pt.y * h;
      ctx.beginPath();
      ctx.arc(x, y, 6, 0, 2 * Math.PI);
      ctx.fillStyle = jointColor;
      ctx.fill();
      ctx.lineWidth = 2;
      ctx.strokeStyle = "#FFFFFF";
      ctx.stroke();
    }
  }
}
let stream = null;
let rafId = 0;
let video = null;
let canvas = null;
let activeContainer = null;
let lastSent = 0;
let facingMode = "user";
let smoothedWorld = null;
let smoothedVis = null;
const EMA_ALPHA = 0.65;

function status(msg) {
  if (typeof window.vitalPoseOnStatus === "function") {
    window.vitalPoseOnStatus(msg);
  }
}

let landmarkerPromise = null;
let lastVideoTimestamp = -1;

async function ensureLandmarker() {
  if (landmarker) return landmarker;
  if (landmarkerPromise) return landmarkerPromise;

  landmarkerPromise = (async () => {
    status("loading_ai");
    try {
      if (!PoseLandmarker) {
        const visionPkg = await import(
          "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.14/vision_bundle.mjs"
        );
        PoseLandmarker = visionPkg.PoseLandmarker;
        FilesetResolver = visionPkg.FilesetResolver;
        DrawingUtils = visionPkg.DrawingUtils;
      }
      const vision = await FilesetResolver.forVisionTasks(WASM);
      const opts = (delegate) => ({
        baseOptions: { modelAssetPath: MODEL, delegate },
        runningMode: "VIDEO",
        numPoses: 3,
        minPoseDetectionConfidence: 0.55,
        minPosePresenceConfidence: 0.55,
        minTrackingConfidence: 0.55,
      });
      try {
        landmarker = await PoseLandmarker.createFromOptions(vision, opts("GPU"));
      } catch (_) {
        landmarker = await PoseLandmarker.createFromOptions(vision, opts("CPU"));
      }
      status("ai_ready");
      return landmarker;
    } catch (err) {
      console.warn("[VitalPose] MediaPipe landmarker could not load:", err);
      landmarkerPromise = null;
      status("ai_fallback");
      throw err;
    }
  })();

  return landmarkerPromise;
}

function countValidPeople(landmarksList) {
  if (!landmarksList || !landmarksList.length) return 0;
  let valid = 0;
  for (const lm of landmarksList) {
    const coreIdx = [0, 11, 12, 23, 24];
    let visCount = 0;
    for (const idx of coreIdx) {
      if (lm[idx] && (lm[idx].visibility ?? 1) >= 0.45) visCount++;
    }
    if (visCount >= 2) valid++;
  }
  return Math.max(valid, landmarksList.length > 0 ? 1 : 0);
}

function smoothLandmarks(worldPts, imagePts) {
  if (!smoothedWorld || smoothedWorld.length !== worldPts.length) {
    smoothedWorld = worldPts.map((p) => ({ x: p.x, y: p.y, z: p.z }));
    smoothedVis = imagePts.map((p) => p.visibility ?? 1);
  } else {
    for (let i = 0; i < worldPts.length; i++) {
      smoothedWorld[i].x = EMA_ALPHA * worldPts[i].x + (1 - EMA_ALPHA) * smoothedWorld[i].x;
      smoothedWorld[i].y = EMA_ALPHA * worldPts[i].y + (1 - EMA_ALPHA) * smoothedWorld[i].y;
      smoothedWorld[i].z = EMA_ALPHA * worldPts[i].z + (1 - EMA_ALPHA) * smoothedWorld[i].z;
      const v = imagePts[i].visibility ?? 1;
      smoothedVis[i] = EMA_ALPHA * v + (1 - EMA_ALPHA) * smoothedVis[i];
    }
  }
  return smoothedWorld.map((p, i) => [p.x, p.y, p.z, smoothedVis[i]]);
}

function loop() {
  if (!video) return;
  const now = performance.now();

  if (landmarker && video.readyState >= 2 && video.videoWidth > 0 && video.videoHeight > 0) {
    if (now > lastVideoTimestamp) {
      lastVideoTimestamp = now;
      try {
        const res = landmarker.detectForVideo(video, now);
        const ctx = canvas.getContext("2d");
        if (canvas.width !== video.videoWidth || canvas.height !== video.videoHeight) {
          canvas.width = video.videoWidth;
          canvas.height = video.videoHeight;
        }
        ctx.clearRect(0, 0, canvas.width, canvas.height);

      const peopleCount = countValidPeople(res.landmarks);

      if (res.landmarks && res.landmarks.length) {
        if (peopleCount > 1) {
          for (let i = 0; i < res.landmarks.length; i++) {
            const isPrimary = i === 0;
            drawFitnessSkeleton(
              ctx,
              res.landmarks[i],
              isPrimary ? "#F59E0B" : "#EF4444",
              isPrimary ? "#F59E0B" : "#DC2626"
            );
          }
        } else {
          drawFitnessSkeleton(ctx, res.landmarks[0], "#00E5FF", "#CCFF00");
        }

        // ~20 frames per second to Dart for responsive rep tracking
        if (now - lastSent > 48 && res.worldLandmarks && res.worldLandmarks.length) {
          lastSent = now;
          const pts = smoothLandmarks(res.worldLandmarks[0], res.landmarks[0]);
          if (typeof window.vitalPoseOnFrame === "function") {
            window.vitalPoseOnFrame(JSON.stringify(pts), now / 1000, peopleCount);
          }
        }
      } else if (now - lastSent > 350) {
        lastSent = now;
        smoothedWorld = null;
        smoothedVis = null;
        if (typeof window.vitalPoseOnFrame === "function") {
          window.vitalPoseOnFrame("[]", now / 1000, 0);
        }
      }
      } catch (e) {
        console.warn("[VitalPose] Detection loop warning:", e);
      }
    }
  }

  rafId = requestAnimationFrame(loop);
}

window.vitalPose = {
  async start(container) {
    try {
      activeContainer = container || activeContainer;
      if (!activeContainer) {
        status("error: Camera container element not provided.");
        return;
      }

      status("requesting_camera");

      if (stream) {
        try {
          stream.getTracks().forEach((t) => t.stop());
        } catch (_) {}
        stream = null;
      }

      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        status("error: Camera API (getUserMedia) not supported in this browser. Please use HTTPS or localhost.");
        return;
      }

      const isMobile = window.innerWidth < 640 || /Mobi|Android|iPhone|iPad/i.test(navigator.userAgent);
      let mediaStream = null;

      try {
        mediaStream = await navigator.mediaDevices.getUserMedia({
          video: {
            facingMode: { ideal: facingMode },
            width: { ideal: isMobile ? 480 : 640 },
            height: { ideal: isMobile ? 640 : 480 },
          },
          audio: false,
        });
      } catch (constraintErr) {
        console.warn("[VitalPose] Ideal constraints failed, falling back to basic video constraint:", constraintErr);
        mediaStream = await navigator.mediaDevices.getUserMedia({
          video: true,
          audio: false,
        });
      }

      stream = mediaStream;
      activeContainer.innerHTML = "";
      activeContainer.style.position = "relative";
      activeContainer.style.overflow = "hidden";

      const mirror = facingMode === "user" ? "transform:scaleX(-1);" : "";
      const fit = isMobile ? "cover" : "contain";

      video = document.createElement("video");
      video.setAttribute("playsinline", "");
      video.setAttribute("webkit-playsinline", "");
      video.muted = true;
      video.autoplay = true;
      video.style.cssText = `position:absolute;inset:0;width:100%;height:100%;object-fit:${fit};${mirror};background:#000;`;

      canvas = document.createElement("canvas");
      canvas.style.cssText = `position:absolute;inset:0;width:100%;height:100%;object-fit:${fit};${mirror};pointer-events:none;`;

      activeContainer.appendChild(video);
      activeContainer.appendChild(canvas);
      video.srcObject = stream;
      await video.play();

      smoothedWorld = null;
      smoothedVis = null;
      status("ready");

      cancelAnimationFrame(rafId);
      rafId = requestAnimationFrame(loop);

      // Initialize or reuse MediaPipe landmarker in background
      ensureLandmarker().catch((lmErr) => {
        console.warn("[VitalPose] Continuing with webcam video stream (MediaPipe model pending):", lmErr);
      });
    } catch (e) {
      console.error("[VitalPose] Camera start error:", e);
      let errMsg = e && e.message ? e.message : String(e);
      if (e.name === "NotAllowedError" || e.name === "PermissionDeniedError") {
        errMsg = "Camera permission denied. Please click the camera icon in Chrome address bar to Allow.";
      } else if (e.name === "NotFoundError" || e.name === "DevicesNotFoundError") {
        errMsg = "No camera found on this computer. Please connect a webcam.";
      } else if (e.name === "NotReadableError" || e.name === "TrackStartError") {
        errMsg = "Camera is locked by another program (e.g. Zoom, FaceTime, Teams). Close it and retry.";
      }
      status("error: " + errMsg);
    }
  },

  async flipCamera() {
    facingMode = facingMode === "user" ? "environment" : "user";
    if (activeContainer && stream) {
      await this.start(activeContainer);
    }
  },

  stop() {
    cancelAnimationFrame(rafId);
    if (stream) {
      try {
        stream.getTracks().forEach((t) => t.stop());
      } catch (_) {}
    }
    stream = null;
    if (video) {
      try {
        video.pause();
        video.srcObject = null;
      } catch (_) {}
    }
    video = null;
    smoothedWorld = null;
    smoothedVis = null;
    status("stopped");
  },

  speak(text, lang) {
    if (!("speechSynthesis" in window)) return;
    try {
      window.speechSynthesis.cancel();
      const u = new SpeechSynthesisUtterance(text);
      u.lang = lang || "en-US";
      u.rate = 1.0;
      window.speechSynthesis.speak(u);
    } catch (_) {}
  },
};

// Pre-warm MediaPipe Pose Landmarker on startup in background
if (typeof window !== "undefined") {
  setTimeout(() => {
    ensureLandmarker().catch((e) => console.log("[VitalPose] Background pre-warm:", e));
  }, 200);
}

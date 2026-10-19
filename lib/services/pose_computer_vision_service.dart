import 'dart:math';
import '../models/body_joint_point.dart';
import '../models/safety_assessment.dart';

/// Core Computer Vision Service providing joint trigonometry, angle calculations,
/// kinematic form checking, and safety guardrails.
class PoseComputerVisionService {
  /// Calculates the 2D angle in degrees between three joints:
  /// vertex is the pivot (e.g. Elbow in Shoulder -> Elbow -> Wrist, or Knee in Hip -> Knee -> Ankle).
  static double calculateAngleDegrees(
    BodyJointPoint first,
    BodyJointPoint vertex,
    BodyJointPoint second,
  ) {
    final double radians = atan2(second.y - vertex.y, second.x - vertex.x) -
        atan2(first.y - vertex.y, first.x - vertex.x);
    double angle = (radians * 180.0 / pi).abs();
    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
  }

  /// Evaluates knee flexion safety during squats or wall-sits.
  /// Prevents patellofemoral cartilage overload when knee angles go below safe thresholds
  /// and detects medial knee collapse (knee valgus).
  static FormSafetyCheck evaluateSquatDepthAndKneeSafety({
    required BodyJointPoint hip,
    required BodyJointPoint knee,
    required BodyJointPoint ankle,
    required BodyJointPoint oppositeKnee,
    BodyJointPoint? oppositeHip,
    double minSafeAngle = 85.0,
  }) {
    final kneeAngle = calculateAngleDegrees(hip, knee, ankle);

    // Knee valgus check: detect if knee is displaced inward relative to hip stance
    final kneeDistance = (knee.x - oppositeKnee.x).abs();
    final hipDistance = oppositeHip != null
        ? (hip.x - oppositeHip.x).abs()
        : 0.32;
    final bool hasValgusCollapse = kneeDistance < (hipDistance * 0.65);

    if (hasValgusCollapse) {
      return FormSafetyCheck(
        isSafe: false,
        message: '⚠️ Knee Valgus Alert: Knees are caving inward. Press knees gently outward over your second toe.',
        kneeAngleDegrees: kneeAngle,
        hasValgusKneeCollapse: true,
        coachAudioCue: 'Knees caving inward! Push gently outward over your toes.',
      );
    }

    if (kneeAngle < minSafeAngle) {
      return FormSafetyCheck(
        isSafe: false,
        message: '🛑 Safe Depth Exceeded (${kneeAngle.toInt()}°): Rise up slightly to protect knee cartilage from excessive shear.',
        kneeAngleDegrees: kneeAngle,
        hasValgusKneeCollapse: false,
        coachAudioCue: 'Safe depth exceeded! Rise up slightly to protect your knees.',
      );
    }

    if (kneeAngle >= minSafeAngle && kneeAngle <= 120.0) {
      return FormSafetyCheck(
        isSafe: true,
        message: '✅ Optimal Joint-Safe Zone (${kneeAngle.toInt()}°): Cartilage protected, quads and glutes active!',
        kneeAngleDegrees: kneeAngle,
        hasValgusKneeCollapse: false,
        coachAudioCue: 'Perfect safe depth! Steady hold and smooth breathing.',
      );
    }

    return FormSafetyCheck(
      isSafe: true,
      message: 'Stand tall with soft knees and continuous breathing.',
      kneeAngleDegrees: kneeAngle,
      hasValgusKneeCollapse: false,
      coachAudioCue: 'Stand tall with soft knees. Begin lowering smoothly.',
    );
  }

  /// Evaluates dumbbell bicep curl kinematics:
  /// - Full contraction (<65°) and extension (>140°)
  /// - Elbow drift detection: ensures elbows remain pinned to torso without momentum swinging.
  static DumbbellCurlSafetyCheck evaluateDumbbellCurlForm({
    required BodyJointPoint shoulder,
    required BodyJointPoint elbow,
    required BodyJointPoint wrist,
    required BodyJointPoint hip,
  }) {
    final elbowAngle = calculateAngleDegrees(shoulder, elbow, wrist);

    // Elbow drift cheat check: if elbow drifts horizontally far in front of shoulder
    final horizontalDrift = (elbow.x - shoulder.x).abs();
    final bool hasElbowSwing = horizontalDrift > 0.18; // normalized frame units

    if (hasElbowSwing) {
      return DumbbellCurlSafetyCheck(
        isSafe: false,
        message: '⚠️ Elbow Swing / Momentum Cheat: Keep your elbow anchored close to your ribs to isolate the bicep.',
        elbowFlexionDegrees: elbowAngle,
        hasElbowSwingCheat: true,
        phaseDescription: 'Momentum Cheat Detected',
        coachAudioCue: 'Pin your elbow to your ribs and avoid swinging!',
      );
    }

    if (elbowAngle <= 65.0) {
      return DumbbellCurlSafetyCheck(
        isSafe: true,
        message: '🔥 Peak Bicep Contraction (${elbowAngle.toInt()}°): Hold for 1 second and exhale steadily.',
        elbowFlexionDegrees: elbowAngle,
        hasElbowSwingCheat: false,
        phaseDescription: 'Peak Contraction',
        coachAudioCue: 'Great peak squeeze! Now lower down slowly.',
      );
    } else if (elbowAngle >= 140.0) {
      return DumbbellCurlSafetyCheck(
        isSafe: true,
        message: '✅ Full Controlled Extension (${elbowAngle.toInt()}°): Complete eccentric range, do not lock out harshly.',
        elbowFlexionDegrees: elbowAngle,
        hasElbowSwingCheat: false,
        phaseDescription: 'Controlled Extension',
        coachAudioCue: 'Full safe extension. Ready for next curl.',
      );
    } else {
      return DumbbellCurlSafetyCheck(
        isSafe: true,
        message: '💪 Mid-Range Smooth Curl (${elbowAngle.toInt()}°): Keep wrists neutral, smooth tempo.',
        elbowFlexionDegrees: elbowAngle,
        hasElbowSwingCheat: false,
        phaseDescription: 'Mid-Range Lift',
        coachAudioCue: 'Keep wrists firm and breathe continuously.',
      );
    }
  }

  /// Evaluates chair stand-to-sit routine.
  /// Prevents excessive trunk forward bending and ensures soft knee deceleration.
  static ChairStandSafetyCheck evaluateChairStandSafety({
    required BodyJointPoint shoulder,
    required BodyJointPoint hip,
    required BodyJointPoint knee,
    required BodyJointPoint ankle,
  }) {
    final kneeAngle = calculateAngleDegrees(hip, knee, ankle);
    final trunkAngle = calculateAngleDegrees(shoulder, hip, knee);

    final bool excessiveForwardLean = trunkAngle < 65.0;

    if (excessiveForwardLean) {
      return ChairStandSafetyCheck(
        isSafe: false,
        message: '⚠️ Excessive Forward Lean: Keep your chest proud and look forward to protect your lumbar spine.',
        kneeAngleDegrees: kneeAngle,
        excessiveForwardLean: true,
        coachAudioCue: 'Keep your chest up and look forward!',
      );
    }

    if (kneeAngle >= 85.0 && kneeAngle <= 110.0) {
      return ChairStandSafetyCheck(
        isSafe: true,
        message: '✅ Safe Seated Transition (${kneeAngle.toInt()}°): Soft touch to chair, knees tracking over toes.',
        kneeAngleDegrees: kneeAngle,
        excessiveForwardLean: false,
        coachAudioCue: 'Gentle touch to chair. Press smoothly through your heels.',
      );
    }

    return ChairStandSafetyCheck(
      isSafe: true,
      message: 'Tall standing posture: Core engaged, ready for controlled descent.',
      kneeAngleDegrees: kneeAngle,
      excessiveForwardLean: false,
      coachAudioCue: 'Stand tall, core braced. Begin sitting down slowly.',
    );
  }

  /// Real-time Calorie Burn estimation based on ACSM MET formulation, weight, elapsed time, and completed reps.
  static double estimateLiveCalories({
    required double weightKg,
    required int elapsedSeconds,
    required int reps,
    required double met,
  }) {
    final double minutes = elapsedSeconds / 60.0;
    // Standard ACSM Calorie Formula: kcal/min = (MET * 3.5 * weightKg) / 200
    final double timeCalories = (met * 3.5 * weightKg / 200.0) * minutes;
    final double repCalories = reps * 0.35;
    final double total = timeCalories + repCalories;
    return double.parse(total.toStringAsFixed(1));
  }

  /// Emergency Fall & Floor Collapse Evaluator:
  /// Detects sudden drop of head landmark to bottom third of frame or horizontal posture collapse.
  static FallSafetyAssessment assessFallRiskAndPosture({
    required BodyJointPoint head,
    required BodyJointPoint hip,
    required BodyJointPoint ankle,
    required double frameHeight,
  }) {
    final bool headFloorDrop = head.y > (frameHeight * 0.72) || (head.y > hip.y + 0.1);
    final double torsoVerticality = (head.x - hip.x).abs();
    final bool horizontalCollapse = (head.y - hip.y).abs() < 0.15 && torsoVerticality > 0.3;

    if (headFloorDrop || horizontalCollapse) {
      return const FallSafetyAssessment(
        isEmergencyTriggered: true,
        dangerReason: '🚨 Emergency Fall / Floor Collapse Detected!',
        recommendedAction: 'Activating 10-second SOS dispatch window to designated emergency contact.',
      );
    }

    return const FallSafetyAssessment(
      isEmergencyTriggered: false,
      dangerReason: '',
      recommendedAction: 'Vertical stability verified.',
    );
  }
}

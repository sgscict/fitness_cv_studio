import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../models/pose_landmark.dart';
import 'pose_camera_stub.dart'
    if (dart.library.js_interop) 'pose_camera_web.dart'
    if (dart.library.io) 'pose_camera_native.dart' as impl;

/// Unified camera + on-device pose model abstraction.
/// Runs WebAssembly MediaPipe in modern web browsers, with native fallback stubs.
abstract class PoseCamera {
  factory PoseCamera() => impl.createPoseCamera();

  bool get isSupported;

  /// Number of people detected in current camera frame.
  int get peopleCount;

  /// Stream of 33 world landmarks with timestamp in seconds.
  Stream<(List<PoseLandmark>, double)> get frames;

  /// Lifecycle status: 'loading', 'camera', 'ready', 'stopped', or 'error: ...'
  Stream<String> get status;

  Widget view();
  Future<void> start();
  Future<void> flipCamera();
  void stop();
  void speak(String text, {String lang = 'en-US'});
  void dispose();
}

import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../models/pose_landmark.dart';
import 'pose_camera.dart';

PoseCamera createPoseCamera() => _NativePoseCamera();

/// Native mobile implementation stub.
/// To enable native camera ML Kit on Android/iOS, developers can bind
/// `google_mlkit_pose_detection` or `camera` package here.
class _NativePoseCamera implements PoseCamera {
  final _frames = StreamController<(List<PoseLandmark>, double)>.broadcast();
  final _status = StreamController<String>.broadcast();

  @override
  bool get isSupported => false;

  @override
  int get peopleCount => 0;

  @override
  Stream<(List<PoseLandmark>, double)> get frames => _frames.stream;

  @override
  Stream<String> get status => _status.stream;

  @override
  Widget view() => const Center(
        child: Text(
          'Native Camera Mode (Connect google_mlkit_pose_detection on Android/iOS)\nUse Simulator Mode for Desktop/Emulator testing.',
          textAlign: TextAlign.center,
        ),
      );

  @override
  Future<void> start() async {
    _status.add('ready');
  }

  @override
  Future<void> flipCamera() async {}

  @override
  void stop() {
    _status.add('stopped');
  }

  @override
  void speak(String text, {String lang = 'en-US'}) {}

  @override
  void dispose() {
    _frames.close();
    _status.close();
  }
}

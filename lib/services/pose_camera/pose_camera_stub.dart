import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../models/pose_landmark.dart';
import 'pose_camera.dart';

PoseCamera createPoseCamera() => _StubPoseCamera();

class _StubPoseCamera implements PoseCamera {
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
  Widget view() => const SizedBox.shrink();

  @override
  Future<void> start() async {
    _status.add('Camera not supported on this platform. Please switch to Simulator mode.');
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

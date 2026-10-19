import 'pose_camera/pose_camera.dart';

/// Lightweight voice coach service. Calls Web Speech API or PoseCamera bridge.
class VoiceCoachService {
  VoiceCoachService._();
  static final VoiceCoachService instance = VoiceCoachService._();

  bool isEnabled = true;
  String _lastSpoken = '';
  double _lastSpokenT = -10.0;

  void speak(
    String text, {
    PoseCamera? camera,
    double currentT = 0.0,
    bool force = false,
  }) {
    if (!isEnabled) return;
    if (text.isEmpty) return;

    // Avoid repetitive spam within 3 seconds unless forced
    if (!force && text == _lastSpoken && (currentT - _lastSpokenT) < 3.0) {
      return;
    }

    _lastSpoken = text;
    _lastSpokenT = currentT;
    final cam = camera ?? PoseCamera();
    cam.speak(text, lang: 'en-US');
  }

  void reset() {
    _lastSpoken = '';
    _lastSpokenT = -10.0;
  }
}

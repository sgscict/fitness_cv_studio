import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;
import '../../models/pose_landmark.dart';
import 'pose_camera.dart';

PoseCamera createPoseCamera() => _WebPoseCamera();

@JS('vitalPose')
external _VitalPose? get _vitalPose;

extension type _VitalPose(JSObject _) implements JSObject {
  external JSPromise<JSAny?> start(web.HTMLElement container);
  external JSPromise<JSAny?> flipCamera();
  external void stop();
  external void speak(String text, String lang);
}

@JS('vitalPoseOnFrame')
external set _onFrame(JSFunction? f);

@JS('vitalPoseOnStatus')
external set _onStatus(JSFunction? f);

class _WebPoseCamera implements PoseCamera {
  static int _nextId = 0;
  final String _viewType = 'fitness-cv-studio-view-${_nextId++}';
  final _frames = StreamController<(List<PoseLandmark>, double)>.broadcast();
  final _status = StreamController<String>.broadcast();
  final web.HTMLDivElement _container;
  int _peopleCount = 0;

  _WebPoseCamera() : _container = (web.document.createElement('div') as web.HTMLDivElement) {
    _container.style
      ..width = '100%'
      ..height = '100%'
      ..backgroundColor = '#000000'
      ..position = 'relative'
      ..overflow = 'hidden';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int id) {
      return _container;
    });
    _onFrame = ((JSString json, JSNumber t, [JSNumber? count]) {
      final raw = jsonDecode(json.toDart) as List;
      final pts = raw.map((p) {
        final l = (p as List).cast<num>();
        return PoseLandmark(l[0].toDouble(), l[1].toDouble(), l[2].toDouble(), l[3].toDouble());
      }).toList();
      _peopleCount = count?.toDartInt ?? (pts.isEmpty ? 0 : 1);
      _frames.add((pts, t.toDartDouble));
    }).toJS;
    _onStatus = ((JSString s) => _status.add(s.toDart)).toJS;
  }

  @override
  bool get isSupported => (web.window.navigator as JSObject).has('mediaDevices');

  @override
  int get peopleCount => _peopleCount;

  @override
  Stream<(List<PoseLandmark>, double)> get frames => _frames.stream;

  @override
  Stream<String> get status => _status.stream;

  @override
  Widget view() => HtmlElementView(viewType: _viewType);

  @override
  Future<void> start() async {
    for (var i = 0; i < 100 && _vitalPose == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    final bridge = _vitalPose;
    if (bridge == null) {
      _status.add('error: Camera JavaScript engine not initialized.');
      return;
    }
    try {
      await bridge.start(_container).toDart;
    } catch (e) {
      _status.add('error: $e');
    }
  }

  @override
  Future<void> flipCamera() async {
    final bridge = _vitalPose;
    if (bridge != null) {
      await bridge.flipCamera().toDart;
    }
  }

  @override
  void stop() {
    _vitalPose?.stop();
    _status.add('stopped');
  }

  @override
  void speak(String text, {String lang = 'en-US'}) {
    _vitalPose?.speak(text, lang);
  }

  @override
  void dispose() {
    stop();
    _frames.close();
    _status.close();
  }
}

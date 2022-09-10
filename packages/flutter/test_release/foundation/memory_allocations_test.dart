// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final MemoryAllocations ma = MemoryAllocations.instance;

  setUp(() {
    assert(!ma.hasListeners);
    _checkSdkHandlersNotSet();
  });

  test('kFlutterMemoryAllocationsEnabled is false in release mode.', () {
    expect(kFlutterMemoryAllocationsEnabled, isFalse);
  });

  test(
    '$MemoryAllocations is noop when kFlutterMemoryAllocationsEnabled is false.',
    () async {
      ObjectEvent? recievedEvent;
      ObjectEvent listener(ObjectEvent event) => recievedEvent = event;

      ma.addListener(listener);
      _checkSdkHandlersNotSet();

      await _activateFlutterObjects();
      _checkSdkHandlersNotSet();
      expect(recievedEvent, isNull);
      expect(ma.hasListeners, isFalse);

      ma.removeListener(listener);
      _checkSdkHandlersNotSet();
    },
  );
}

void _checkSdkHandlersNotSet() {
  expect(ui.Image.onCreate, isNull);
  expect(ui.Picture.onCreate, isNull);
  expect(ui.Image.onDispose, isNull);
  expect(ui.Picture.onDispose, isNull);
}

class _TestElement extends Element {
  _TestElement() : super(const Placeholder());

  @override
  bool get debugDoingBuild => throw UnimplementedError();
}

class _TestRenderObject extends RenderObject {
  @override
  void debugAssertDoesMeetConstraints() {}

  @override
  Rect get paintBounds => throw UnimplementedError();

  @override
  void performLayout() {}

  @override
  void performResize() {}

  @override
  Rect get semanticBounds => throw UnimplementedError();
}

class _TestLayer extends Layer{
  @override
  void addToScene(ui.SceneBuilder builder) {}
}

class _TestState extends State {
  @override
  Widget build(BuildContext context) => throw UnimplementedError();
}

/// Create and dispose Flutter objects to fire memory allocation events.
Future<void> _activateFlutterObjects() async {
  final ValueNotifier<bool> valueNotifier = ValueNotifier<bool>(true);
  final ChangeNotifier changeNotifier = ChangeNotifier()..addListener(() {});
  final ui.Image image = await _createImage();
  final ui.Picture picture = _createPicture();
   final Element element = _TestElement();
  final RenderObject renderObject = _TestRenderObject();
  final Layer layer = _TestLayer();
  final State state = _TestState();

  valueNotifier.dispose();
  changeNotifier.dispose();
  image.dispose();
  picture.dispose();
  element.unmount();
  renderObject.dispose();
  // It is ok to invoke protected and test only member for testing perposes.
  // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
  layer.dispose();
  // It is ok to invoke protected member for testing perposes.
  // ignore: invalid_use_of_protected_member
  state.dispose();
}

Future<ui.Image> _createImage() async {
  final ui.Picture picture = _createPicture();
  final ui.Image result = await picture.toImage(10, 10);
  picture.dispose();
  return result;
}

ui.Picture _createPicture() {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  const Rect rect = Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
  canvas.clipRect(rect);
  return recorder.endRecording();
}

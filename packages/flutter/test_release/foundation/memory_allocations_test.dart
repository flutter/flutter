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

  testWidgets(
    '$MemoryAllocations is noop when kFlutterMemoryAllocationsEnabled is false.',
    (WidgetTester tester) async {
      ObjectEvent? recievedEvent;
      ObjectEvent listener(ObjectEvent event) => recievedEvent = event;

      ma.addListener(listener);
      _checkSdkHandlersNotSet();
      expect(ma.hasListeners, isFalse);

      await _activateFlutterObjects(tester);
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

class _TestLeafRenderObjectWidget extends LeafRenderObjectWidget {
  @override
  RenderObject createRenderObject(BuildContext context) {
    return _TestRenderObject();
  }
}

class _TestElement extends RootRenderObjectElement{
  _TestElement(): super(_TestLeafRenderObjectWidget());

  void makeInactive() {
    assignOwner(BuildOwner(focusManager: FocusManager()));
    mount(null, null);
    deactivate();
  }
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

class _MyStateFulWidget extends StatefulWidget {
  const _MyStateFulWidget();

  @override
  State<_MyStateFulWidget> createState() => _MyStateFulWidgetState();
}

class _MyStateFulWidgetState extends State<_MyStateFulWidget> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class _TestLayer extends Layer{
  @override
  void addToScene(ui.SceneBuilder builder) {}
}

/// Create and dispose Flutter objects to fire memory allocation events.
Future<void> _activateFlutterObjects(WidgetTester tester) async {
  final ValueNotifier<bool> valueNotifier = ValueNotifier<bool>(true);
  final ChangeNotifier changeNotifier = ChangeNotifier()..addListener(() {});
  final ui.Picture picture = _createPicture();
  final _TestElement element = _TestElement();
  final RenderObject renderObject = _TestRenderObject();
  final Layer layer = _TestLayer();

  valueNotifier.dispose();
  changeNotifier.dispose();
  picture.dispose();
  element.makeInactive(); element.unmount();
  renderObject.dispose();
  // It is ok to use protected members for testing.
  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
  layer.dispose();

  // TODO(polina-c): Remove the condition after
  // https://github.com/flutter/flutter/issues/110599 is fixed.
  if (!kIsWeb) {
    final ui.Image image = await _createImage();
    image.dispose();
  }

  // Create and dispose State:
  await tester.pumpWidget(const _MyStateFulWidget());
  await tester.pumpWidget(const SizedBox.shrink());
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

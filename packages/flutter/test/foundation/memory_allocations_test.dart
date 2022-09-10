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

  test('addListener and removeListener add and remove listeners.', () {

    final ObjectEvent event = ObjectDisposed(object: 'object');
    ObjectEvent? recievedEvent;
    void listener(ObjectEvent event) => recievedEvent = event;
    expect(ma.hasListeners, isFalse);

    ma.addListener(listener);
    _checkSdkHandlersSet();
    ma.dispatchObjectEvent(() => event);
    expect(recievedEvent, equals(event));
    expect(ma.hasListeners, isTrue);
    recievedEvent = null;

    ma.removeListener(listener);
    ma.dispatchObjectEvent(() => event);
    expect(recievedEvent, isNull);
    expect(ma.hasListeners, isFalse);
    _checkSdkHandlersNotSet();
  });

  testWidgets('dispatchObjectEvent handles bad listeners', (WidgetTester tester) async {
    final ObjectEvent event = ObjectDisposed(object: 'object');
    final List<String> log = <String>[];
    void badListener1(ObjectEvent event) {
      log.add('badListener1');
      throw ArgumentError();
    }
    void listener1(ObjectEvent event) => log.add('listener1');
    void badListener2(ObjectEvent event) {
      log.add('badListener2');
      throw ArgumentError();
    }
    void listener2(ObjectEvent event) => log.add('listener2');

    ma.addListener(badListener1);
    _checkSdkHandlersSet();
    ma.addListener(listener1);
    ma.addListener(badListener2);
    ma.addListener(listener2);

    ma.dispatchObjectEvent(() => event);
    expect(log, <String>['badListener1', 'listener1', 'badListener2','listener2']);
    expect(tester.takeException(), contains('Multiple exceptions (2)'));

    ma.removeListener(badListener1);
    _checkSdkHandlersSet();
    ma.removeListener(listener1);
    ma.removeListener(badListener2);
    ma.removeListener(listener2);
    _checkSdkHandlersNotSet();

    log.clear();
    expect(ma.hasListeners, isFalse);
    ma.dispatchObjectEvent(() => event);
    expect(log, <String>[]);
  });

  test('dispatchObjectEvent does not invoke concurrently added listeners', () {
    final ObjectEvent event = ObjectDisposed(object: 'object');
    final List<String> log = <String>[];

    void listener2(ObjectEvent event) => log.add('listener2');
    void listener1(ObjectEvent event) {
      log.add('listener1');
      ma.addListener(listener2);
    }

    ma.addListener(listener1);
    _checkSdkHandlersSet();

    ma.dispatchObjectEvent(() => event);
    expect(log, <String>['listener1']);
    log.clear();

    ma.dispatchObjectEvent(() => event);
    expect(log, <String>['listener1','listener2']);
    log.clear();

    ma.removeListener(listener1);
    ma.removeListener(listener2);
    _checkSdkHandlersNotSet();

    expect(ma.hasListeners, isFalse);
    ma.dispatchObjectEvent(() => event);
    expect(log, <String>[]);
  });

  test('dispatchObjectEvent does not invoke concurrently removed listeners', () {
    final ObjectEvent event = ObjectDisposed(object: 'object');
    final List<String> log = <String>[];

    void listener2(ObjectEvent event) => log.add('listener2');
    void listener1(ObjectEvent event) {
      log.add('listener1');
      ma.removeListener(listener2);
      expect(ma.hasListeners, isFalse);
    }

    ma.addListener(listener1);
    ma.addListener(listener2);

    ma.dispatchObjectEvent(() => event);
    expect(log, <String>['listener1']);
    log.clear();

    ma.removeListener(listener1);
    _checkSdkHandlersNotSet();

    expect(ma.hasListeners, isFalse);
  });

  test('last removeListener unsubscribes from Flutter SDK events', () {
    void listener1(ObjectEvent event) {}
    void listener2(ObjectEvent event) {}

    ma.addListener(listener1);
    _checkSdkHandlersSet();

    ma.addListener(listener2);
    _checkSdkHandlersSet();

    ma.removeListener(listener1);
    _checkSdkHandlersSet();

    ma.removeListener(listener2);
    _checkSdkHandlersNotSet();
  });

  test('kFlutterMemoryAllocationsEnabled is true in debug mode.', () {
    expect(kFlutterMemoryAllocationsEnabled, isTrue);
  });

  test('publishers in Flutter dispatch events in debug mode', () async {
    int eventCount = 0;
    void listener(ObjectEvent event) => eventCount++;
    ma.addListener(listener);

    final int expectedEventCount = await _activateFlutterObjectsAndReturnCountOfEvents();
    expect(eventCount, expectedEventCount);

    ma.removeListener(listener);
    _checkSdkHandlersNotSet();
    expect(ma.hasListeners, isFalse);
  });
}

void _checkSdkHandlersSet() {
  expect(ui.Image.onCreate, isNotNull);
  expect(ui.Picture.onCreate, isNotNull);
  expect(ui.Image.onDispose, isNotNull);
  expect(ui.Picture.onDispose, isNotNull);
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
Future<int> _activateFlutterObjectsAndReturnCountOfEvents() async {
  int count = 0;

  final ValueNotifier<bool> valueNotifier = ValueNotifier<bool>(true); count++;
  final ChangeNotifier changeNotifier = ChangeNotifier()..addListener(() {}); count++;
  final ui.Picture picture = _createPicture(); count++;
  final Element element = _TestElement(); count++;
  final RenderObject renderObject = _TestRenderObject(); count++;
  final Layer layer = _TestLayer(); count++;
  final State state = _TestState(); count++;

  valueNotifier.dispose(); count++;
  changeNotifier.dispose(); count++;
  picture.dispose(); count++;
  element.unmount(); count++;
  renderObject.dispose(); count++;
  layer.dispose(); count++;
  // It is ok to invoke protected member for testing perposes.
  // ignore: invalid_use_of_protected_member
  state.dispose(); count++;

  // TODO(polina-c): Remove the condition after
  // https://github.com/flutter/flutter/issues/110599 is fixed.
  if (!kIsWeb) {
    final ui.Image image = await _createImage(); count++; count++; count++;
    image.dispose(); count++;
  }

  return count;
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

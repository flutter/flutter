// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

int eventCount = 0;

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


  testWidgets('publishers in Flutter dispatch events in debug mode', (WidgetTester tester) async {

    eventCount = 0;
    void listener(ObjectEvent event) =>  eventCount++;
    ma.addListener(listener);

    final int expectedEventCount = await _activateFlutterObjectsAndReturnCountOfEvents(tester);
    expect(eventCount, expectedEventCount);

    ma.removeListener(listener);
    _checkSdkHandlersNotSet();
    expect(ma.hasListeners, isFalse);
  });

  testWidgets('State dispatch events in debug mode', (WidgetTester tester) async {
    bool stateCreated = false;
    bool stateDisposed = false;

    void listener(ObjectEvent event) {
      if (event is ObjectCreated && event.object is State) {
        stateCreated = true;
      }
      if (event is ObjectDisposed && event.object is State) {
        stateDisposed = true;
      }
    }
    ma.addListener(listener);

    await tester.pumpWidget(const _TestStatefulWidget());
    await tester.pumpWidget(const SizedBox.shrink());

    expect(stateCreated, isTrue);
    expect(stateDisposed, isTrue);
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

class _TestLayer extends Layer{
  @override
  void addToScene(ui.SceneBuilder builder) {}
}

class _TestStatefulWidget extends StatefulWidget {
  const _TestStatefulWidget();

  @override
  State<_TestStatefulWidget> createState() => _TestStatefulWidgetState();
}

class _TestStatefulWidgetState extends State<_TestStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

/// Create and dispose Flutter objects to fire memory allocation events.
Future<int> _activateFlutterObjectsAndReturnCountOfEvents(WidgetTester tester) async {
  int count = 0;

  final ValueNotifier<bool> valueNotifier = ValueNotifier<bool>(true); count++;
  final ChangeNotifier changeNotifier = ChangeNotifier()..addListener(() {}); count++;
  final ui.Picture picture = _createPicture(); count++;
  final _TestElement element = _TestElement(); count++;
  final RenderObject renderObject = _TestRenderObject(); count++;
  final Layer layer = _TestLayer(); count++;

  valueNotifier.dispose(); count++;
  changeNotifier.dispose(); count++;
  picture.dispose(); count++;
  element.makeInactive(); element.unmount(); count++;
  renderObject.dispose(); count++;
  layer.dispose(); count++;

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

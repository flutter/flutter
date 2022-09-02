// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final MemoryAllocations ma = MemoryAllocations.instance;

  setUp(() {
    assert(!ma.hasListeners);
  });

  test('addListener and removeListener add and remove listeners.', () {
    final ObjectEvent event = ObjectDisposed(object: 'object');
    ObjectEvent? recievedEvent;
    void listener(ObjectEvent event) => recievedEvent = event;
    expect(ma.hasListeners, isFalse);

    ma.addListener(listener);
    ma.dispatchObjectEvent(() => event);
    expect(recievedEvent, equals(event));
    expect(ma.hasListeners, isTrue);
    recievedEvent = null;

    ma.removeListener(listener);
    ma.dispatchObjectEvent(() => event);
    expect(recievedEvent, isNull);
    expect(ma.hasListeners, isFalse);
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
    ma.addListener(listener1);
    ma.addListener(badListener2);
    ma.addListener(listener2);

    ma.dispatchObjectEvent(() => event);
    expect(log, <String>['badListener1', 'listener1', 'badListener2','listener2']);
    expect(tester.takeException(), contains('Multiple exceptions (2)'));

    ma.removeListener(badListener1);
    ma.removeListener(listener1);
    ma.removeListener(badListener2);
    ma.removeListener(listener2);

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

    ma.dispatchObjectEvent(() => event);
    expect(log, <String>['listener1']);
    log.clear();

    ma.dispatchObjectEvent(() => event);
    expect(log, <String>['listener1','listener2']);
    log.clear();

    ma.removeListener(listener1);
    ma.removeListener(listener2);

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

    expect(ma.hasListeners, isFalse);
  });

  test('addListener subscribes to Flutter SDK events', () {
    // TODO(polina-c): add test
  });

  test('last removeListener unsubscribes from Flutter SDK events', () {
    // TODO(polina-c): add test
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
    expect(ma.hasListeners, isFalse);
  });
}

Future<int> _activateFlutterObjectsAndReturnCountOfEvents() async {
  int count = 0;
  // TODO(polina-c): uncomment count increase for SDK events
  // when https://github.com/flutter/engine/pull/35274 lands.

  final ValueNotifier<bool> valueNotifier = ValueNotifier<bool>(true); count++;
  final ChangeNotifier changeNotifier = ChangeNotifier()..addListener(() {}); count++;
  final Picture picture = _createPicture(); //count++;

  valueNotifier.dispose(); count++;
  changeNotifier.dispose(); count++;
  picture.dispose(); //count++;

  // TODO(polina-c): Remove the condition after
  // https://github.com/flutter/engine/pull/35791 is fixed.
  if (!kIsWeb) {
    final Image image = await _createImage(); //count++; count++; count++;
    image.dispose(); //count++;
  }

  return count;
}

Future<Image> _createImage() async {
  final Picture picture = _createPicture();
  final Image result = await picture.toImage(10, 10);
  picture.dispose();
  return result;
}

Picture _createPicture() {
  final PictureRecorder recorder = PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  const Rect rect = Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
  canvas.clipRect(rect);
  return recorder.endRecording();
}

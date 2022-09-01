// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';


class TestNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }

  bool get isListenedTo => hasListeners;
}

void main() {
  final MemoryAllocations ma = MemoryAllocations.instance;

  setUp(() {
    assert(!ma.hasListeners);
  });

  test('addListener and removeListener add and remove listeners.', () {
    final ObjectEvent event = ObjectDisposed(object: 'object');
    ObjectEvent? recievedEvent;
    ObjectEvent listener(ObjectEvent event) => recievedEvent = event;
    expect(ma.hasListeners, isFalse);

    ma.addListener(listener);
    ma.dispatchObjectEvent(event);
    expect(recievedEvent, equals(event));
    expect(ma.hasListeners, isTrue);
    recievedEvent = null;

    ma.removeListener(listener);
    ma.dispatchObjectEvent(event);
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

    ma.dispatchObjectEvent(event);
    expect(log, <String>['badListener1', 'listener1', 'badListener2','listener2']);
    expect(tester.takeException(), contains('Multiple exceptions (2)'));

    ma.removeListener(badListener1);
    ma.removeListener(listener1);
    ma.removeListener(badListener2);
    ma.removeListener(listener2);

    log.clear();
    expect(ma.hasListeners, isFalse);
    ma.dispatchObjectEvent(event);
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

    ma.dispatchObjectEvent(event);
    expect(log, <String>['listener1']);
    log.clear();

    ma.dispatchObjectEvent(event);
    expect(log, <String>['listener1','listener2']);
    log.clear();

    ma.removeListener(listener1);
    ma.removeListener(listener2);

    expect(ma.hasListeners, isFalse);
    ma.dispatchObjectEvent(event);
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

    ma.dispatchObjectEvent(event);
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

}

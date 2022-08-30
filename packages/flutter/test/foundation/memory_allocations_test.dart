// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/foundation/memory_allocations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final MemoryAllocations ma = MemoryAllocations.instance;

  setUp(() {
    assert(!ma.hasListeners);
  });

  test('addListener and removeListener add and remove listeners.', () {
    final ObjectEvent event = ObjectTraced(object: 'object');
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

  testWidgets('bad listener is handled', (WidgetTester tester) async {
    final ObjectEvent event = ObjectTraced(object: 'object');
    final List<String> log = <String>[];
    void listener1(ObjectEvent event) => log.add('listener1');
    void badListener(ObjectEvent event) => log.add('badListener');
    void listener2(ObjectEvent event) => log.add('listener2');

    ma.addListener(listener1);
    ma.addListener(badListener);
    ma.addListener(listener2);

    ma.dispatchObjectEvent(event);
    expect(log, <String>['listener1', 'badListener','listener2']);
    expect(tester.takeException(), isArgumentError);

    ma.removeListener(listener1);
    ma.removeListener(badListener);
    ma.removeListener(listener2);

    log.clear();
    expect(ma.hasListeners, isFalse);
    ma.dispatchObjectEvent(event);
    expect(log, <String>[]);
  });
}

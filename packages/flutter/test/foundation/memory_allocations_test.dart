// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/foundation/memory_allocations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final MemoryAllocations ma = MemoryAllocations.instance;

  setUp(() => ma.removeAllListeners());

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

  test('removeAllListeners removes all listeners.', () {
    final ObjectEvent event = ObjectTraced(object: 'object');
    ObjectEvent? recievedEvent;
    ObjectEvent listener1(ObjectEvent event) => recievedEvent = event;
    ObjectEvent listener2(ObjectEvent event) => recievedEvent = event;
    expect(ma.hasListeners, isFalse);

    ma.addListener(listener1);
    expect(ma.hasListeners, isTrue);
    ma.addListener(listener2);
    expect(ma.hasListeners, isTrue);
    ma.dispatchObjectEvent(event);
    expect(recievedEvent, equals(event));
    recievedEvent = null;

    ma.removeAllListeners();
    ma.dispatchObjectEvent(event);
    expect(recievedEvent, isNull);
    expect(ma.hasListeners, isFalse);
  });
}

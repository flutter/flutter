// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/foundation/memory_allocations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final MemoryAllocations ma = MemoryAllocations.instance;

  setUp(() => ma.removeAllListeners());

  test('MemoryAllocations adds and removes listeners.', () {
    final ObjectEvent event = ObjectTraced(object: 'object');
    ObjectEvent? recievedEvent;
    ObjectEvent listener(ObjectEvent event) => recievedEvent = event;

    ma.addListener(listener);
    ma.dispatchObjectEvent(event);
    expect(recievedEvent, equals(event));
    recievedEvent = null;

    ma.removeListener(listener);
    ma.dispatchObjectEvent(event);
    expect(recievedEvent, isNull);
  });

  test('MemoryAllocations removes all listeners.', () {
    final ObjectEvent event = ObjectTraced(object: 'object');
    ObjectEvent? recievedEvent;
    ObjectEvent listener1(ObjectEvent event) => recievedEvent = event;
    ObjectEvent listener2(ObjectEvent event) => recievedEvent = event;

    ma.addListener(listener1);
    ma.addListener(listener2);
    ma.dispatchObjectEvent(event);
    expect(recievedEvent, equals(event));
    recievedEvent = null;

    ma.removeAllListeners();
    ma.dispatchObjectEvent(event);
    expect(recievedEvent, isNull);
  });
}

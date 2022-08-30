// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PerformanceModeHandler handler;

  setUpAll(() {
    handler = PerformanceModeHandler.instance;
  });

  test('PerformanceModeHandler make one request', () async {
    const int handle1 = 1;
    final bool success = handler.createRequest(handle1, DartPerformanceMode.latency);
    expect(success, isTrue);
    expect(handler.getRequestedPerformanceMode(), equals(DartPerformanceMode.latency));

    handler.disposeRequest(handle1);
    expect(handler.getRequestedPerformanceMode(), isNull);
  });

  test('PerformanceModeHandler make conflicting requests', () async {
    const int handle1 = 1;
    final bool success1 = handler.createRequest(handle1, DartPerformanceMode.latency);
    expect(success1, isTrue);

    const int handle2 = 2;
    final bool success2 = handler.createRequest(handle2, DartPerformanceMode.throughput);
    expect(success2, isFalse);

    expect(handler.getRequestedPerformanceMode(), equals(DartPerformanceMode.latency));

    handler.disposeRequest(handle1);
    expect(handler.getRequestedPerformanceMode(), isNull);
  });



  test('PerformanceModeHandler revert only after last requestor disposed', () async {
    const int handle1 = 1;
    final bool success1 = handler.createRequest(handle1, DartPerformanceMode.latency);
    expect(success1, isTrue);

    expect(handler.getRequestedPerformanceMode(), equals(DartPerformanceMode.latency));

    const int handle2 = 2;
    final bool success2 = handler.createRequest(handle2, DartPerformanceMode.latency);
    expect(success2, isTrue);

    expect(handler.getRequestedPerformanceMode(), equals(DartPerformanceMode.latency));
    handler.disposeRequest(handle1);
    expect(handler.getRequestedPerformanceMode(), equals(DartPerformanceMode.latency));
    handler.disposeRequest(handle2);
    expect(handler.getRequestedPerformanceMode(), isNull);
  });

}

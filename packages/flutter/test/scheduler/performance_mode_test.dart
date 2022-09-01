// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SchedulerBinding binding;

  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
    binding = SchedulerBinding.instance;
  });

  test('PerformanceModeHandler make one request', () async {
    const int handle1 = 1;
    final PerformanceModeRequestHandle? requestHandle = binding.requestPerformanceMode(handle1, DartPerformanceMode.latency);
    expect(requestHandle, isNotNull);
    expect(binding.getRequestedPerformanceMode(), equals(DartPerformanceMode.latency));
    requestHandle?.dispose();
    expect(binding.getRequestedPerformanceMode(), isNull);
  });

  test('PerformanceModeHandler make conflicting requests', () async {
    const int handle1 = 1;
    final PerformanceModeRequestHandle? requestHandle1 = binding.requestPerformanceMode(handle1, DartPerformanceMode.latency);
    expect(requestHandle1, isNotNull);

    const int handle2 = 2;
    final PerformanceModeRequestHandle? requestHandle2 = binding.requestPerformanceMode(handle2, DartPerformanceMode.throughput);
    expect(requestHandle2, isNull);

    expect(binding.getRequestedPerformanceMode(), equals(DartPerformanceMode.latency));

    requestHandle1?.dispose();
    expect(binding.getRequestedPerformanceMode(), isNull);
  });

  test('PerformanceModeHandler revert only after last requestor disposed',
      () async {
    const int handle1 = 1;
    final PerformanceModeRequestHandle? requestHandle1 = binding.requestPerformanceMode(handle1, DartPerformanceMode.latency);
    expect(requestHandle1, isNotNull);

    expect(binding.getRequestedPerformanceMode(), equals(DartPerformanceMode.latency));

    const int handle2 = 2;
    final PerformanceModeRequestHandle? requestHandle2 = binding.requestPerformanceMode(handle2, DartPerformanceMode.latency);
    expect(requestHandle2, isNotNull);

    expect(binding.getRequestedPerformanceMode(), equals(DartPerformanceMode.latency));
    requestHandle1?.dispose();
    expect(binding.getRequestedPerformanceMode(), equals(DartPerformanceMode.latency));
    requestHandle2?.dispose();
    expect(binding.getRequestedPerformanceMode(), isNull);
  });
}

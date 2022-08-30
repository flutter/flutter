// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter/src/foundation/constants.dart';
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
    final bool success = binding.createPerformanceModeRequest(handle1, DartPerformanceMode.latency);
    expect(success, isTrue);
    expect(binding.getRequestedPerformanceMode(), equals(DartPerformanceMode.latency));

    binding.disposePerformanceModeRequest(handle1);
    expect(binding.getRequestedPerformanceMode(), isNull);
  }, skip: kIsWeb); // [intended] performance mode handling is not supported on web.

  test('PerformanceModeHandler make conflicting requests', () async {
    const int handle1 = 1;
    final bool success1 = binding.createPerformanceModeRequest(handle1, DartPerformanceMode.latency);
    expect(success1, isTrue);

    const int handle2 = 2;
    final bool success2 = binding.createPerformanceModeRequest(handle2, DartPerformanceMode.throughput);
    expect(success2, isFalse);

    expect(binding.getRequestedPerformanceMode(), equals(DartPerformanceMode.latency));

    binding.disposePerformanceModeRequest(handle1);
    expect(binding.getRequestedPerformanceMode(), isNull);
  }, skip: kIsWeb); // [intended] performance mode handling is not supported on web.

  test('PerformanceModeHandler revert only after last requestor disposed', () async {
    const int handle1 = 1;
    final bool success1 = binding.createPerformanceModeRequest(handle1, DartPerformanceMode.latency);
    expect(success1, isTrue);

    expect(binding.getRequestedPerformanceMode(), equals(DartPerformanceMode.latency));

    const int handle2 = 2;
    final bool success2 = binding.createPerformanceModeRequest(handle2, DartPerformanceMode.latency);
    expect(success2, isTrue);

    expect(binding.getRequestedPerformanceMode(), equals(DartPerformanceMode.latency));
    binding.disposePerformanceModeRequest(handle1);
    expect(binding.getRequestedPerformanceMode(), equals(DartPerformanceMode.latency));
    binding.disposePerformanceModeRequest(handle2);
    expect(binding.getRequestedPerformanceMode(), isNull);
  }, skip: kIsWeb); // [intended] performance mode handling is not supported on web.

}

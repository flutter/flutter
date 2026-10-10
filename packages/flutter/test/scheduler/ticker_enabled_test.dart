// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Disabling callbacks preserves the clock and completion future', (
    WidgetTester tester,
  ) async {
    final ticks = <Duration>[];
    final ticker = Ticker(ticks.add)..enabled = false;
    addTearDown(ticker.dispose);
    var completed = false;
    ticker.start().then((_) => completed = true);
    expect(ticker.isActive, isTrue);
    expect(ticker.isTicking, isFalse);
    expect(tester.binding.transientCallbackCount, 0);

    ticker.enabled = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(ticks, <Duration>[Duration.zero, const Duration(milliseconds: 10)]);
    ticker.enabled = false;
    await tester.pump(const Duration(milliseconds: 20));
    expect(ticks.length, 2);
    expect(ticker.isActive, isTrue);
    expect(ticker.isTicking, isFalse);
    expect(completed, isFalse);
    expect(tester.binding.hasScheduledFrame, isFalse);

    ticker
      ..enabled = true
      ..enabled = true;
    expect(tester.binding.transientCallbackCount, 1);
    await tester.pump(const Duration(milliseconds: 10));
    expect(ticks.last, const Duration(milliseconds: 40));
    ticker.stop();
    await tester.pump();
    expect(completed, isTrue);
  });

  testWidgets('Muting and disabling callbacks are independent', (WidgetTester tester) async {
    final ticker = Ticker((Duration elapsed) {})..start();
    addTearDown(ticker.dispose);
    ticker
      ..muted = true
      ..enabled = false
      ..muted = false;
    expect(ticker.isTicking, isFalse);
    expect(tester.binding.transientCallbackCount, 0);
    ticker
      ..muted = true
      ..enabled = true;
    expect(ticker.isTicking, isFalse);
    expect(tester.binding.transientCallbackCount, 0);
    ticker.muted = false;
    expect(ticker.isTicking, isTrue);
    expect(tester.binding.transientCallbackCount, 1);
    ticker.stop();
  });

  testWidgets('Absorbing a disabled ticker preserves consumer and provider settings', (
    WidgetTester tester,
  ) async {
    final original = Ticker((Duration elapsed) {});
    final ticks = <Duration>[];
    final replacement = Ticker(ticks.add)..muted = true;
    addTearDown(replacement.dispose);
    var completed = false;
    original.start().then((_) => completed = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    original.enabled = false;
    replacement.absorbTicker(original);
    expect(replacement.enabled, isFalse);
    expect(replacement.muted, isTrue);
    expect(replacement.isActive, isTrue);
    expect(tester.binding.transientCallbackCount, 0);

    replacement.enabled = true;
    expect(tester.binding.transientCallbackCount, 0);
    replacement.muted = false;
    await tester.pump(const Duration(milliseconds: 20));
    expect(ticks, <Duration>[const Duration(milliseconds: 30)]);
    replacement.stop();
    await tester.pump();
    expect(completed, isTrue);
  });

  testWidgets('Disabled tickers can still be canceled and restarted', (WidgetTester tester) async {
    final ticker = Ticker((Duration elapsed) {})..enabled = false;
    addTearDown(ticker.dispose);
    final TickerFuture future = ticker.start();
    final Future<void> cancellation = expectLater(future.orCancel, throwsA(isA<TickerCanceled>()));
    ticker.stop(canceled: true);
    await cancellation;
    expect(ticker.isActive, isFalse);
    ticker.start();
    expect(ticker.isActive, isTrue);
    expect(ticker.enabled, isFalse);
    expect(tester.binding.transientCallbackCount, 0);
    ticker.enabled = true;
    expect(tester.binding.transientCallbackCount, 1);
    ticker.stop();
  });
}

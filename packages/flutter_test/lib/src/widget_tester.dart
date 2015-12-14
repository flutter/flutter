// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:quiver/testing/async.dart';
import 'package:quiver/time.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'instrumentation.dart';


/// Helper class for fluter tests providing fake async.
///
/// This class extends Instrumentation to also abstract away the beginFrame
/// and async/clock access to allow writing tests which depend on the passage
/// of time without actually moving the clock forward.
class WidgetTester extends Instrumentation {
  WidgetTester._(FakeAsync async)
    : async = async,
      clock = async.getClock(new DateTime.utc(2015, 1, 1)) {
    timeDilation = 1.0;
    ui.window.onBeginFrame = null;
    runApp(new ErrorWidget()); // flush out the last build entirely
  }

  final FakeAsync async;
  final Clock clock;

  void pumpWidget(Widget widget, [ Duration duration ]) {
    runApp(widget);
    pump(duration);
  }

  void setLocale(String languageCode, String countryCode) {
    ui.Locale locale = new ui.Locale(languageCode, countryCode);
    binding.dispatchLocaleChanged(locale);
    async.flushMicrotasks();
  }

  void pump([ Duration duration ]) {
    if (duration != null)
      async.elapse(duration);
    binding.handleBeginFrame(new Duration(
      milliseconds: clock.now().millisecondsSinceEpoch)
    );
    async.flushMicrotasks();
  }
}

void testWidgets(callback(WidgetTester tester)) {
  new FakeAsync().run((FakeAsync async) {
    callback(new WidgetTester._(async));
  });
}

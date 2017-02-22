// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debugAssertAllSchedulerVarsUnset control test', () {
    expect(() {
      debugAssertAllSchedulerVarsUnset('Example test');
    }, isNot(throwsFlutterError));

    debugPrintBeginFrameBanner = true;

    expect(() {
      debugAssertAllSchedulerVarsUnset('Example test');
    }, throwsFlutterError);

    debugPrintBeginFrameBanner = false;
    debugPrintEndFrameBanner = true;

    expect(() {
      debugAssertAllSchedulerVarsUnset('Example test');
    }, throwsFlutterError);

    debugPrintEndFrameBanner = false;

    expect(() {
      debugAssertAllSchedulerVarsUnset('Example test');
    }, isNot(throwsFlutterError));
  });
}

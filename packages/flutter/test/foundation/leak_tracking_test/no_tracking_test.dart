// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';

import 'leaking_widget.dart';

void main() {
  testWidgets(
      'Leak tracking is not started without `testWidgetsWithLeakTracking`',
      (WidgetTester widgetTester) async {
    expect(LeakTracking.isStarted, false);
    expect(LeakTracking.phase.name, null);
    await widgetTester.pumpWidget(StatelessLeakingWidget());

  },
  skip: kIsWeb); // [intended] Leak tracking is off for web.
}

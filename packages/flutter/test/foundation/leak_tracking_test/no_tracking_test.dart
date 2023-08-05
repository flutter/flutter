// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  });
}

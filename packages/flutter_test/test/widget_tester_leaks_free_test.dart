// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

void main() {
  LeakTesting.enable(); // Enable leak testing and use default collectedLeaksReporter.

  // Regression test for https://github.com/flutter/flutter/issues/169119.
  testWidgets('Does not leak if restorationManager is accessed', (WidgetTester tester) async {
    var counterByWidgets = 0;
    final RestorationManager managerByWidgets = WidgetsBinding.instance.restorationManager;
    expect(managerByWidgets, isA<TestRestorationManager>());
    managerByWidgets.addListener(() => counterByWidgets++);
    managerByWidgets.notifyListeners();
    expect(counterByWidgets, 1);

    var counterByServices = 0;
    final RestorationManager managerByServices = ServicesBinding.instance.restorationManager;
    expect(managerByServices, isA<TestRestorationManager>());
    managerByServices.addListener(() => counterByServices++);
    managerByServices.notifyListeners();
    expect(counterByServices, 1);
  });
}

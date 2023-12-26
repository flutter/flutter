// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

final List<LeakTestCase> tests = <LeakTestCase>[
  LeakTestCase(
    name: 'no leaks',
    body: (PumpWidgetsCallback? pumpWidgets,
        RunAsyncCallback<dynamic>? runAsync) async {
      await pumpWidgets!(Container());
    },
  ),
  LeakTestCase(
    name: 'leaking widget',
    body: (PumpWidgetsCallback? pumpWidgets,
        RunAsyncCallback<dynamic>? runAsync) async {
      StatelessLeakingWidget();
    },
  ),
  LeakTestCase(
      name: 'dispose in tear down',
      body: (PumpWidgetsCallback? pumpWidgets,
          RunAsyncCallback<dynamic>? runAsync) async {
        final InstrumentedDisposable myClass = InstrumentedDisposable();
        addTearDown(myClass.dispose);
      }),
  LeakTestCase(
    name: 'not disposed disposable',
    body: (PumpWidgetsCallback? pumpWidgets,
        RunAsyncCallback<dynamic>? runAsync) async {
      InstrumentedDisposable();
    },
  ),
  LeakTestCase(
    name: 'pumped leaking widget',
    body: (PumpWidgetsCallback? pumpWidgets,
        RunAsyncCallback<dynamic>? runAsync) async {
      await pumpWidgets!(StatelessLeakingWidget());
    },
  ),
  LeakTestCase(
    name: 'leaking widget in runAsync',
    body: (PumpWidgetsCallback? pumpWidgets,
        RunAsyncCallback<dynamic>? runAsync) async {
      await runAsync!(() async {
        await pumpWidgets!(StatelessLeakingWidget());
      });
    },
  ),
  LeakTestCase(
    name: 'pumped in runAsync',
    body: (PumpWidgetsCallback? pumpWidgets,
        RunAsyncCallback<dynamic>? runAsync) async {
      await runAsync!(() async {
        await pumpWidgets!(StatelessLeakingWidget());
      });
    },
  ),
];

final Map<String, LeakTesting> _usedSettings = <String, LeakTesting>{};

void main() {
  for (final LeakTestCase test in tests) {
    for (final  MapEntry<String, LeakTesting> settings in leakTestingSettingsCases.entries) {
      final String testName = '${test.name}, ${settings.key}';
      _usedSettings[settings.key] = settings.value;
      testWidgets(testName, experimentalLeakTesting: settings.value, (WidgetTester tester) async {
        await test.body(tester.pumpWidget, tester.runAsync);
      });
    }
  }
}

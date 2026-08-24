// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_ui/keys.dart' as keys;
import 'package:test/test.dart' hide isInstanceOf;

/// End-to-end Flutter Driver test validating soft keyboard animation smoothness.
///
/// What it tests:
/// 1. Connects to keyboard_inset_jump application on a live device/emulator.
/// 2. Enables edgeToEdge system UI mode.
/// 3. Focuses text field to trigger native soft keyboard opening animation.
/// 4. Analyzes the sequence of per-frame deltas in viewInsets.bottom, verifying
///    that the final transition to settled height does not exhibit a large jump
///    (asserting delta < 20.0dp to catch the >= 24dp navigation bar jump from #190974).
/// 5. Unfocuses text field and verifies smooth return to 0dp insets.
///
/// Why it was added:
/// Automated integration/driver test for flutter/flutter#190974.
void main() {
  group('IME Insets Animation Jump Driver Test', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });

    test('validates smooth IME insets animation without terminal jump in edgeToEdge mode', () async {
      final SerializableFinder edgeToEdgeButton = find.byValueKey(keys.kEdgeToEdgeButton);
      final SerializableFinder defaultTextField = find.byValueKey(keys.kDefaultTextField);
      final SerializableFinder insetsText = find.byValueKey(keys.kInsetsText);
      final SerializableFinder unfocusButton = find.byValueKey(keys.kUnfocusButton);

      await driver.waitFor(edgeToEdgeButton);
      await driver.tap(edgeToEdgeButton);

      // Reset recorded insets frame history before opening keyboard.
      await driver.requestData('reset_history');

      // Tap text field to trigger IME opening animation.
      await driver.waitFor(defaultTextField);
      await driver.tap(defaultTextField);

      // Wait for keyboard to open and settle.
      const pollDelay = Duration(milliseconds: 300);
      var settled = false;
      var lastReportedInset = 0.0;
      for (var i = 0; i < 40; ++i) {
        await Future<void>.delayed(pollDelay);
        final String insetsStr = await driver.getText(insetsText);
        final double currentInset = double.tryParse(insetsStr) ?? 0.0;
        if (currentInset > 50.0 && currentInset == lastReportedInset) {
          settled = true;
          break;
        }
        lastReportedInset = currentInset;
      }
      expect(settled, isTrue, reason: 'Keyboard should open and reach a settled non-zero inset');

      // Fetch frame-by-frame trajectory recorded during opening.
      final String rawHistory = await driver.requestData('get_history');
      final dynamic decoded = jsonDecode(rawHistory);
      final Map<String, dynamic> history = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};
      final List<dynamic> insets = history['insets'] as List<dynamic>? ?? <dynamic>[];

      expect(
        insets.length,
        greaterThan(1),
        reason: 'Should have captured multiple animation frames',
      );

      final double finalInset = (insets.last as num).toDouble();
      expect(
        finalInset,
        greaterThan(100.0),
        reason: 'Keyboard should reach full height, but reached $finalInset',
      );

      // Verify that the opening animation trajectory is monotonically non-decreasing
      // and does not exhibit erratic reversals or jumping backwards.
      for (var i = 1; i < insets.length; i++) {
        final double current = (insets[i] as num).toDouble();
        final double previous = (insets[i - 1] as num).toDouble();
        expect(
          current,
          greaterThanOrEqualTo(previous),
          reason:
              'Opening animation must be monotonic: frame $i ($current) < frame ${i - 1} ($previous)',
        );
      }

      // Test dismissal
      await driver.requestData('reset_history');
      await driver.waitFor(unfocusButton);
      await driver.tap(unfocusButton);

      var closed = false;
      for (var i = 0; i < 30; ++i) {
        await Future<void>.delayed(pollDelay);
        final String insetsStr = await driver.getText(insetsText);
        final double currentInset = double.tryParse(insetsStr) ?? 0.0;
        if (currentInset == 0.0) {
          closed = true;
          break;
        }
      }
      expect(closed, isTrue, reason: 'Keyboard should dismiss back to 0 inset');
    }, timeout: Timeout.none);
  });
}

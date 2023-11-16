// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show Tooltip;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';
import 'package:matcher/expect.dart' as matcher_expect;
import 'package:meta/meta.dart';
import 'package:test_api/scaffolding.dart' as test_package;

import 'binding.dart';
import 'controller.dart';
import 'finders.dart';
import 'leak_tracking.dart';
import 'matchers.dart';
import 'restoration.dart';
import 'test_async_utils.dart';
import 'test_compat.dart';
import 'test_pointer.dart';
import 'test_text_input.dart';
import 'tree_traversal.dart';
import 'widget_tester.dart';

// Examples can assume:
// typedef MyWidget = Placeholder;

/// Runs the [callback] inside the Flutter test environment.
///
/// Use this function for testing custom [StatelessWidget]s and
/// [StatefulWidget]s.
///
/// The callback can be asynchronous (using `async`/`await` or
/// using explicit [Future]s).
///
/// The `timeout` argument specifies the backstop timeout implemented by the
/// `test` package. If set, it should be relatively large (minutes). It defaults
/// to ten minutes for tests run by `flutter test`, and is unlimited for tests
/// run by `flutter run`; specifically, it defaults to
/// [TestWidgetsFlutterBinding.defaultTestTimeout].
///
/// If the `semanticsEnabled` parameter is set to `true`,
/// [WidgetTester.ensureSemantics] will have been called before the tester is
/// passed to the `callback`, and that handle will automatically be disposed
/// after the callback is finished. It defaults to true.
///
/// This function uses the [test] function in the test package to
/// register the given callback as a test. The callback, when run,
/// will be given a new instance of [WidgetTester]. The [find] object
/// provides convenient widget [Finder]s for use with the
/// [WidgetTester].
///
/// When the [variant] argument is set, [testWidgets] will run the test once for
/// each value of the [TestVariant.values]. If [variant] is not set, the test
/// will be run once using the base test environment.
///
/// If the [tags] are passed, they declare user-defined tags that are implemented by
/// the `test` package.
///
/// The argument [experimentalLeakTesting] is experimental and is not recommended
/// for use outside of the Flutter framework.
/// When [experimentalLeakTesting] is set, it is used for leak tracking.
/// Otherwise [LeakTesting.settings] is used.
/// Adjust [LeakTesting.settings] in flutter_test_config.dart
/// (see https://github.com/flutter/flutter/blob/master/packages/flutter_test/lib/flutter_test.dart)
/// for the entire package or folder, or in the test's main for a test file.
/// To turn off leak tracking just for one test, set [experimentalLeakTesting] to
/// `LeakTrackingForTests.ignore()`.
///
/// ## Sample code
///
/// ```dart
/// testWidgets('MyWidget', (WidgetTester tester) async {
///   await tester.pumpWidget(const MyWidget());
///   await tester.tap(find.text('Save'));
///   expect(find.text('Success'), findsOneWidget);
/// });
/// ```
@isTest
void testWidgets(
  String description,
  WidgetTesterCallback callback, {
  bool? skip,
  test_package.Timeout? timeout,
  bool semanticsEnabled = true,
  TestVariant<Object?> variant = const DefaultTestVariant(),
  dynamic tags,
  int? retry,
  LeakTesting? experimentalLeakTesting,
}) {
  assert(variant.values.isNotEmpty, 'There must be at least one value to test in the testing variant.');

  callback = wrapWithLeakTracking(description, callback, experimentalLeakTesting);

  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
  final WidgetTester tester = WidgetTester._(binding);
  for (final dynamic value in variant.values) {
    _plannedTests += 1;
    final String variationDescription = variant.describeValue(value);
    // IDEs may make assumptions about the format of this suffix in order to
    // support running tests directly from the editor (where they may have
    // access to only the test name, provided by the analysis server).
    // See https://github.com/flutter/flutter/issues/86659.
    final String combinedDescription = variationDescription.isNotEmpty
        ? '$description (variant: $variationDescription)'
        : description;
    test(
      combinedDescription,
      () {
        tester._testDescription = combinedDescription;
        SemanticsHandle? semanticsHandle;
        tester._recordNumberOfSemanticsHandles();
        if (semanticsEnabled) {
          semanticsHandle = tester.ensureSemantics();
        }

        // This tear down happens after in-test `addTearDown`, but before
        // separate `tearDown` in the test file.
        test_package.addTearDown(binding.postTest);

        return binding.runTest(
          () async {
            binding.reset(); // TODO(ianh): the binding should just do this itself in _runTest
            debugResetSemanticsIdCounter();
            Object? memento;
            try {
              memento = await variant.setUp(value);
              await callback(tester);
            } finally {
              _executedTests += 1;
              await variant.tearDown(value, memento);
            }
            semanticsHandle?.dispose();
          },
          tester._endOfTestVerifications,
          description: combinedDescription,
        );
      },
      skip: skip,
      timeout: timeout ?? binding.defaultTestTimeout,
      tags: tags,
      retry: retry,
    );
  }
}





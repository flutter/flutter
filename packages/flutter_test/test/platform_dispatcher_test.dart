// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show PlatformDispatcher;
import 'dart:ui' show Size, Locale, WindowPadding, AccessibilityFeatures, Brightness;

import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test/src/platform_dispatcher.dart';
import 'package:meta/meta.dart';

void main() {
  test('TestPlatformDispatcher can handle new methods without breaking', () {
    final dynamic testDispatcher= TestPlatformDispatcher(platformDispatcher: ui.PlatformDispatcher.instance);
    expect(testDispatcher.someNewProperty, null);
  });

  testWidgets('TestPlatformDispatcher can fake locale', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<Locale>(
      tester: tester,
      realValue: ui.PlatformDispatcher.instance.locale,
      fakeValue: const Locale('fake_language_code'),
      propertyRetriever: () {
        return WidgetsBinding.instance.platformDispatcher.locale;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, Locale fakeValue) {
        binding.platformDispatcher.localeTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake locales', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<List<Locale>>(
      tester: tester,
      realValue: ui.PlatformDispatcher.instance.locales,
      fakeValue: <Locale>[const Locale('fake_language_code')],
      propertyRetriever: () {
        return WidgetsBinding.instance.platformDispatcher.locales;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, List<Locale> fakeValue) {
        binding.platformDispatcher.localesTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake text scale factor', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<double>(
      tester: tester,
      realValue: ui.PlatformDispatcher.instance.textScaleFactor,
      fakeValue: 2.5,
      propertyRetriever: () {
        return WidgetsBinding.instance.platformDispatcher.textScaleFactor;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, double fakeValue) {
        binding.platformDispatcher.textScaleFactorTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake clock format', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<bool>(
      tester: tester,
      realValue: ui.PlatformDispatcher.instance.alwaysUse24HourFormat,
      fakeValue: !ui.PlatformDispatcher.instance.alwaysUse24HourFormat,
      propertyRetriever: () {
        return WidgetsBinding.instance.platformDispatcher.alwaysUse24HourFormat;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, bool fakeValue) {
        binding.platformDispatcher.alwaysUse24HourFormatTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake initial route name', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<String>(
      tester: tester,
      realValue: ui.PlatformDispatcher.instance.initialRouteName,
      fakeValue: 'fake_route',
      propertyRetriever: () {
        return WidgetsBinding.instance.platformDispatcher.initialRouteName;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, String fakeValue) {
        binding.platformDispatcher.initialRouteNameTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake accessibility features', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<AccessibilityFeatures>(
      tester: tester,
      realValue: ui.PlatformDispatcher.instance.accessibilityFeatures,
      fakeValue: const FakeAccessibilityFeatures(),
      propertyRetriever: () {
        return WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, AccessibilityFeatures fakeValue) {
        binding.platformDispatcher.accessibilityFeaturesTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake platform brightness', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<Brightness>(
      tester: tester,
      realValue: Brightness.light,
      fakeValue: Brightness.dark,
      propertyRetriever: () {
        return WidgetsBinding.instance.platformDispatcher.platformBrightness;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, Brightness fakeValue) {
        binding.platformDispatcher.platformBrightnessTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can clear out fake properties all at once', (WidgetTester tester) async {
    final String originalInitialRouteName = ui.PlatformDispatcher.instance.initialRouteName;
    final double originalTextScaleFactor = ui.PlatformDispatcher.instance.textScaleFactor;
    final TestPlatformDispatcher testPlatformDispatcher = retrieveTestBinding(tester).platformDispatcher;

    // Set fake values for dispatcher properties.
    testPlatformDispatcher.initialRouteNameTestValue = 'initialRoute';
    testPlatformDispatcher.textScaleFactorTestValue = 3.0;

    // Erase fake platform dispatcher property values.
    testPlatformDispatcher.clearAllTestValues();

    // Verify that the platform dispatcher once again reports real property
    // values.
    expect(WidgetsBinding.instance.platformDispatcher.initialRouteName, originalInitialRouteName);
    expect(WidgetsBinding.instance.platformDispatcher.textScaleFactor, originalTextScaleFactor);
  });
}

void verifyThatTestPlatformDispatcherCanFakeProperty<PropertyType>({
  @required WidgetTester tester,
  @required PropertyType realValue,
  @required PropertyType fakeValue,
  @required PropertyType Function() propertyRetriever,
  @required Function(TestWidgetsFlutterBinding, PropertyType fakeValue) propertyFaker,
}) {
  PropertyType propertyBeforeFaking;
  PropertyType propertyAfterFaking;

  propertyBeforeFaking = propertyRetriever();

  propertyFaker(retrieveTestBinding(tester), fakeValue);

  propertyAfterFaking = propertyRetriever();

  expect(propertyBeforeFaking, realValue);
  expect(propertyAfterFaking, fakeValue);
}

TestWidgetsFlutterBinding retrieveTestBinding(WidgetTester tester) {
  final WidgetsBinding binding = tester.binding;
  assert(binding is TestWidgetsFlutterBinding);
  final TestWidgetsFlutterBinding testBinding = binding as TestWidgetsFlutterBinding;
  return testBinding;
}

class FakeWindowPadding implements WindowPadding {
  const FakeWindowPadding({
    this.left = 0.0,
    this.top = 0.0,
    this.right = 0.0,
    this.bottom = 0.0,
  });

  @override
  final double left;

  @override
  final double top;

  @override
  final double right;

  @override
  final double bottom;
}

class FakeAccessibilityFeatures implements AccessibilityFeatures {
  const FakeAccessibilityFeatures({
    this.accessibleNavigation = false,
    this.invertColors = false,
    this.disableAnimations = false,
    this.boldText = false,
    this.reduceMotion = false,
    this.highContrast = false,
  });

  @override
  final bool accessibleNavigation;

  @override
  final bool invertColors;

  @override
  final bool disableAnimations;

  @override
  final bool boldText;

  @override
  final bool reduceMotion;

  @override
  final bool highContrast;

  /// This gives us some grace time when the dart:ui side adds something to
  /// [AccessibilityFeatures], and makes things easier when we do rolls to
  /// give us time to catch up.
  ///
  /// If you would like to add to this class, changes must first be made in the
  /// engine, followed by the framework.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

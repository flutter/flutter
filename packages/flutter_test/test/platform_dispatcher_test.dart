// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show window;
import 'dart:ui' show Size, Locale, WindowPadding, AccessibilityFeatures, Brightness, PlatformDispatcher;

import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TestPlatformDispatcher can handle new methods without breaking', () {
    // ignore: unnecessary_nullable_for_final_variable_declarations
    final dynamic testPlatformDispatcher = TestPlatformDispatcher(platformDispatcher: PlatformDispatcher.instance);
    expect(testPlatformDispatcher.someNewProperty, null);
  });

  testWidgets('TestPlatformDispatcher can fake device pixel ratio', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<double>(
      tester: tester,
      realValue: ui.window.devicePixelRatio,
      fakeValue: 2.5,
      propertyRetriever: () {
        return WidgetsBinding.instance!.window.devicePixelRatio;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, double fakeValue) {
        binding.window.devicePixelRatioTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake physical size', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<Size>(
      tester: tester,
      realValue: ui.window.physicalSize,
      fakeValue: const Size(50, 50),
      propertyRetriever: () {
        return WidgetsBinding.instance!.window.physicalSize;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, Size fakeValue) {
        binding.window.physicalSizeTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake view insets', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<WindowPadding>(
      tester: tester,
      realValue: ui.window.viewInsets,
      fakeValue: const FakeWindowPadding(),
      propertyRetriever: () {
        return WidgetsBinding.instance!.window.viewInsets;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, WindowPadding fakeValue) {
        binding.window.viewInsetsTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake padding', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<WindowPadding>(
      tester: tester,
      realValue: ui.window.padding,
      fakeValue: const FakeWindowPadding(),
      propertyRetriever: () {
        return WidgetsBinding.instance!.window.padding;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, WindowPadding fakeValue) {
        binding.window.paddingTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake locale', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<Locale>(
      tester: tester,
      realValue: ui.window.locale,
      fakeValue: const Locale('fake_language_code'),
      propertyRetriever: () {
        return WidgetsBinding.instance!.window.locale;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, Locale fakeValue) {
        binding.window.localeTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake locales', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<List<Locale>>(
      tester: tester,
      realValue: ui.window.locales,
      fakeValue: <Locale>[const Locale('fake_language_code')],
      propertyRetriever: () {
        return WidgetsBinding.instance!.window.locales;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, List<Locale> fakeValue) {
        binding.window.localesTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake text scale factor', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<double>(
      tester: tester,
      realValue: ui.window.textScaleFactor,
      fakeValue: 2.5,
      propertyRetriever: () {
        return WidgetsBinding.instance!.window.textScaleFactor;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, double fakeValue) {
        binding.window.textScaleFactorTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake clock format', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<bool>(
      tester: tester,
      realValue: ui.window.alwaysUse24HourFormat,
      fakeValue: !ui.window.alwaysUse24HourFormat,
      propertyRetriever: () {
        return WidgetsBinding.instance!.window.alwaysUse24HourFormat;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, bool fakeValue) {
        binding.window.alwaysUse24HourFormatTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake default route name', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<String>(
      tester: tester,
      realValue: ui.window.defaultRouteName,
      fakeValue: 'fake_route',
      propertyRetriever: () {
        return WidgetsBinding.instance!.window.defaultRouteName;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, String fakeValue) {
        binding.window.defaultRouteNameTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake accessibility features', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<AccessibilityFeatures>(
      tester: tester,
      realValue: ui.window.accessibilityFeatures,
      fakeValue: const FakeAccessibilityFeatures(),
      propertyRetriever: () {
        return WidgetsBinding.instance!.window.accessibilityFeatures;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, AccessibilityFeatures fakeValue) {
        binding.window.accessibilityFeaturesTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake platform brightness', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<Brightness>(
      tester: tester,
      realValue: Brightness.light,
      fakeValue: Brightness.dark,
      propertyRetriever: () {
        return WidgetsBinding.instance!.window.platformBrightness;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, Brightness fakeValue) {
        binding.window.platformBrightnessTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can clear out fake properties all at once', (WidgetTester tester) async {
    final double originalDevicePixelRatio = ui.window.devicePixelRatio;
    final double originalTextScaleFactor = ui.window.textScaleFactor;
    final TestPlatformDispatcher testPlatformDispatcher = retrieveTestBinding(tester).platformDispatcher as TestPlatformDispatcher;

    // Set fake values for window properties.
    testPlatformDispatcher.textScaleFactorTestValue = 3.0;

    // Erase fake window property values.
    testPlatformDispatcher.clearAllTestValues();

    // Verify that the window once again reports real property values.
    expect(WidgetsBinding.instance!.window.devicePixelRatio, originalDevicePixelRatio);
    expect(WidgetsBinding.instance!.window.textScaleFactor, originalTextScaleFactor);
  });
}

void verifyThatTestPlatformDispatcherCanFakeProperty<WindowPropertyType>({
  required WidgetTester tester,
  required WindowPropertyType? realValue,
  required WindowPropertyType fakeValue,
  required WindowPropertyType? Function() propertyRetriever,
  required Function(TestWidgetsFlutterBinding, WindowPropertyType fakeValue) propertyFaker,
}) {
  WindowPropertyType? propertyBeforeFaking;
  WindowPropertyType? propertyAfterFaking;

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

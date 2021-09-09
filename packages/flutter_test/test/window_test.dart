// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(gspencergoog): Remove this tag once this test's state leaks/test
// dependencies have been fixed.
// https://github.com/flutter/flutter/issues/85160
// Fails with "flutter test --test-randomize-ordering-seed=123"
@Tags(<String>['no-shuffle'])

import 'dart:ui' as ui show window;
import 'dart:ui' show Size, Locale, WindowPadding, AccessibilityFeatures, Brightness;

import 'package:flutter/widgets.dart' show WidgetsBinding, WidgetsBindingObserver;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TestWindow can handle new methods without breaking', () {
    final dynamic testWindow = TestWindow(window: ui.window);
    // ignore: avoid_dynamic_calls
    expect(testWindow.someNewProperty, null);
  });

  testWidgets('TestWindow can fake device pixel ratio', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<double>(
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

  testWidgets('TestWindow can fake physical size', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<Size>(
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

  testWidgets('TestWindow can fake view insets', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<WindowPadding>(
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

  testWidgets('TestWindow can fake padding', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<WindowPadding>(
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

  testWidgets('TestWindow can fake locale', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<Locale>(
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

  testWidgets('TestWindow can fake locales', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<List<Locale>>(
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

  testWidgets('TestWindow can fake text scale factor', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<double>(
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

  testWidgets('TestWindow can fake clock format', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<bool>(
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

  testWidgets('TestWindow can fake default route name', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<String>(
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

  testWidgets('TestWindow can fake accessibility features', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<AccessibilityFeatures>(
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

  testWidgets('TestWindow can fake platform brightness', (WidgetTester tester) async {
    verifyThatTestWindowCanFakeProperty<Brightness>(
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

  testWidgets('TestWindow can clear out fake properties all at once', (WidgetTester tester) async {
    final double originalDevicePixelRatio = ui.window.devicePixelRatio;
    final double originalTextScaleFactor = ui.window.textScaleFactor;
    final TestWindow testWindow = retrieveTestBinding(tester).window;

    // Set fake values for window properties.
    testWindow.devicePixelRatioTestValue = 2.5;
    testWindow.textScaleFactorTestValue = 3.0;

    // Erase fake window property values.
    testWindow.clearAllTestValues();

    // Verify that the window once again reports real property values.
    expect(WidgetsBinding.instance!.window.devicePixelRatio, originalDevicePixelRatio);
    expect(WidgetsBinding.instance!.window.textScaleFactor, originalTextScaleFactor);
  });

  testWidgets('TestWindow sends fake locales when WidgetsBindingObserver notifiers are called', (WidgetTester tester) async {
    final TestObserver observer = TestObserver();
    retrieveTestBinding(tester).addObserver(observer);
    final List<Locale> expectedValue = <Locale>[const Locale('fake_language_code')];
    retrieveTestBinding(tester).window.localesTestValue = expectedValue;
    expect(observer.locales, equals(expectedValue));
  });
}

void verifyThatTestWindowCanFakeProperty<WindowPropertyType>({
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

class TestObserver with WidgetsBindingObserver {
  List<Locale>? locales;
  Locale? locale;

  @override
  void didChangeLocales(List<Locale>? locales) {
    this.locales = locales;
  }
}

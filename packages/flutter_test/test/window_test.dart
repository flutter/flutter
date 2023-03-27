// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(goderbauer): Delete these tests when the deprecated window property is removed.
// ignore_for_file: deprecated_member_use

import 'dart:ui' as ui show window;
import 'dart:ui';

import 'package:flutter/widgets.dart' show WidgetsBinding, WidgetsBindingObserver;
import 'package:flutter_test/flutter_test.dart';

import 'utils/fake_and_mock_utils.dart';

void main() {
  tearDown(() {
    final TestWindow window = WidgetsBinding.instance.window as TestWindow;
    window.clearAllTestValues();
  });

  test('TestWindow can handle new methods without breaking', () {
    final dynamic testWindow = TestWindow(window: ui.window);
    // ignore: avoid_dynamic_calls
    expect(testWindow.someNewProperty, null);
  });

  testWidgets('TestWindow can fake device pixel ratio', (WidgetTester tester) async {
    verifyPropertyFaked<double>(
      tester: tester,
      realValue: ui.window.devicePixelRatio,
      fakeValue: 2.5,
      propertyRetriever: () {
        return WidgetsBinding.instance.window.devicePixelRatio;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, double fakeValue) {
        binding.window.devicePixelRatioTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake physical size', (WidgetTester tester) async {
    verifyPropertyFaked<Size>(
      tester: tester,
      realValue: ui.window.physicalSize,
      fakeValue: const Size(50, 50),
      propertyRetriever: () {
        return WidgetsBinding.instance.window.physicalSize;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, Size fakeValue) {
        binding.window.physicalSizeTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake view insets', (WidgetTester tester) async {
    verifyPropertyFaked<ViewPadding>(
      tester: tester,
      realValue: ui.window.viewInsets,
      fakeValue: FakeViewPadding.zero,
      propertyRetriever: () {
        return WidgetsBinding.instance.window.viewInsets;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, ViewPadding fakeValue) {
        binding.window.viewInsetsTestValue = fakeValue;
      },
      matcher: matchesViewPadding,
    );
  });

  testWidgets('TestWindow can fake padding', (WidgetTester tester) async {
    verifyPropertyFaked<ViewPadding>(
      tester: tester,
      realValue: ui.window.padding,
      fakeValue: FakeViewPadding.zero,
      propertyRetriever: () {
        return WidgetsBinding.instance.window.padding;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, ViewPadding fakeValue) {
        binding.window.paddingTestValue = fakeValue;
      },
      matcher: matchesViewPadding
    );
  });

  testWidgets('TestWindow can fake locale', (WidgetTester tester) async {
    verifyPropertyFaked<Locale>(
      tester: tester,
      realValue: ui.window.locale,
      fakeValue: const Locale('fake_language_code'),
      propertyRetriever: () {
        return WidgetsBinding.instance.window.locale;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, Locale fakeValue) {
        binding.window.localeTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake locales', (WidgetTester tester) async {
    verifyPropertyFaked<List<Locale>>(
      tester: tester,
      realValue: ui.window.locales,
      fakeValue: <Locale>[const Locale('fake_language_code')],
      propertyRetriever: () {
        return WidgetsBinding.instance.window.locales;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, List<Locale> fakeValue) {
        binding.window.localesTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake text scale factor', (WidgetTester tester) async {
    verifyPropertyFaked<double>(
      tester: tester,
      realValue: ui.window.textScaleFactor,
      fakeValue: 2.5,
      propertyRetriever: () {
        return WidgetsBinding.instance.window.textScaleFactor;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, double fakeValue) {
        binding.window.textScaleFactorTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake clock format', (WidgetTester tester) async {
    verifyPropertyFaked<bool>(
      tester: tester,
      realValue: ui.window.alwaysUse24HourFormat,
      fakeValue: !ui.window.alwaysUse24HourFormat,
      propertyRetriever: () {
        return WidgetsBinding.instance.window.alwaysUse24HourFormat;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, bool fakeValue) {
        binding.window.alwaysUse24HourFormatTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake brieflyShowPassword', (WidgetTester tester) async {
    verifyPropertyFaked<bool>(
      tester: tester,
      realValue: ui.window.brieflyShowPassword,
      fakeValue: !ui.window.brieflyShowPassword,
      propertyRetriever: () => WidgetsBinding.instance.window.brieflyShowPassword,
      propertyFaker: (TestWidgetsFlutterBinding binding, bool fakeValue) {
        binding.window.brieflyShowPasswordTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake default route name', (WidgetTester tester) async {
    verifyPropertyFaked<String>(
      tester: tester,
      realValue: ui.window.defaultRouteName,
      fakeValue: 'fake_route',
      propertyRetriever: () {
        return WidgetsBinding.instance.window.defaultRouteName;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, String fakeValue) {
        binding.window.defaultRouteNameTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake accessibility features', (WidgetTester tester) async {
    verifyPropertyFaked<AccessibilityFeatures>(
      tester: tester,
      realValue: ui.window.accessibilityFeatures,
      fakeValue: const FakeAccessibilityFeatures(),
      propertyRetriever: () {
        return WidgetsBinding.instance.window.accessibilityFeatures;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, AccessibilityFeatures fakeValue) {
        binding.window.accessibilityFeaturesTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake platform brightness', (WidgetTester tester) async {
    verifyPropertyFaked<Brightness>(
      tester: tester,
      realValue: Brightness.light,
      fakeValue: Brightness.dark,
      propertyRetriever: () {
        return WidgetsBinding.instance.window.platformBrightness;
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
    expect(WidgetsBinding.instance.window.devicePixelRatio, originalDevicePixelRatio);
    expect(WidgetsBinding.instance.window.textScaleFactor, originalTextScaleFactor);
  });

  testWidgets('TestWindow sends fake locales when WidgetsBindingObserver notifiers are called', (WidgetTester tester) async {
    final List<Locale> defaultLocales = WidgetsBinding.instance.window.locales;
    final TestObserver observer = TestObserver();
    retrieveTestBinding(tester).addObserver(observer);
    final List<Locale> expectedValue = <Locale>[const Locale('fake_language_code')];
    retrieveTestBinding(tester).window.localesTestValue = expectedValue;
    expect(observer.locales, equals(expectedValue));
    retrieveTestBinding(tester).window.localesTestValue = defaultLocales;
  });

  testWidgets('Updates to window also update tester.view', (WidgetTester tester) async {
    tester.binding.window.devicePixelRatioTestValue = 7;
    tester.binding.window.displayFeaturesTestValue = <DisplayFeature>[const DisplayFeature(bounds: Rect.fromLTWH(0, 0, 20, 300), type: DisplayFeatureType.unknown, state: DisplayFeatureState.unknown)];
    tester.binding.window.paddingTestValue = FakeViewPadding.zero;
    tester.binding.window.physicalSizeTestValue = const Size(505, 805);
    tester.binding.window.systemGestureInsetsTestValue = FakeViewPadding.zero;
    tester.binding.window.viewInsetsTestValue = FakeViewPadding.zero;
    tester.binding.window.viewPaddingTestValue = FakeViewPadding.zero;
    tester.binding.window.gestureSettingsTestValue = const GestureSettings(physicalTouchSlop: 4, physicalDoubleTapSlop: 5);

    expect(tester.binding.window.devicePixelRatio, tester.view.devicePixelRatio);
    expect(tester.binding.window.displayFeatures, tester.view.displayFeatures);
    expect(tester.binding.window.padding, tester.view.padding);
    expect(tester.binding.window.physicalSize, tester.view.physicalSize);
    expect(tester.binding.window.systemGestureInsets, tester.view.systemGestureInsets);
    expect(tester.binding.window.viewInsets, tester.view.viewInsets);
    expect(tester.binding.window.viewPadding, tester.view.viewPadding);
    expect(tester.binding.window.gestureSettings, tester.view.gestureSettings);
  });
}

class TestObserver with WidgetsBindingObserver {
  List<Locale>? locales;
  Locale? locale;

  @override
  void didChangeLocales(List<Locale>? locales) {
    this.locales = locales;
  }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Locale, AccessibilityFeatures, Brightness, PlatformDispatcher;

import 'package:flutter/widgets.dart' show WidgetsBinding, WidgetsBindingObserver;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TestWindow can handle new methods without breaking', () {
    final dynamic testPlatformDispatcher = TestPlatformDispatcher(platformDispatcher: PlatformDispatcher.instance);
    // ignore: avoid_dynamic_calls
    expect(testPlatformDispatcher.someNewProperty, null);
  });

  testWidgets('TestWindow can fake locale', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<Locale>(
      tester: tester,
      realValue: PlatformDispatcher.instance.locale,
      fakeValue: const Locale('fake_language_code'),
      propertyRetriever: () {
        return WidgetsBinding.instance.platformDispatcher.locale;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, Locale fakeValue) {
        binding.platformDispatcher.localeTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake locales', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<List<Locale>>(
      tester: tester,
      realValue: PlatformDispatcher.instance.locales,
      fakeValue: <Locale>[const Locale('fake_language_code')],
      propertyRetriever: () {
        return WidgetsBinding.instance.platformDispatcher.locales;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, List<Locale> fakeValue) {
        binding.platformDispatcher.localesTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake text scale factor', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<double>(
      tester: tester,
      realValue: PlatformDispatcher.instance.textScaleFactor,
      fakeValue: 2.5,
      propertyRetriever: () {
        return WidgetsBinding.instance.platformDispatcher.textScaleFactor;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, double fakeValue) {
        binding.platformDispatcher.textScaleFactorTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake clock format', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<bool>(
      tester: tester,
      realValue: PlatformDispatcher.instance.alwaysUse24HourFormat,
      fakeValue: !PlatformDispatcher.instance.alwaysUse24HourFormat,
      propertyRetriever: () {
        return WidgetsBinding.instance.platformDispatcher.alwaysUse24HourFormat;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, bool fakeValue) {
        binding.platformDispatcher.alwaysUse24HourFormatTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake brieflyShowPassword', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<bool>(
      tester: tester,
      realValue: PlatformDispatcher.instance.brieflyShowPassword,
      fakeValue: !PlatformDispatcher.instance.brieflyShowPassword,
      propertyRetriever: () => WidgetsBinding.instance.platformDispatcher.brieflyShowPassword,
      propertyFaker: (TestWidgetsFlutterBinding binding, bool fakeValue) {
        binding.platformDispatcher.brieflyShowPasswordTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake default route name', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<String>(
      tester: tester,
      realValue: PlatformDispatcher.instance.defaultRouteName,
      fakeValue: 'fake_route',
      propertyRetriever: () {
        return WidgetsBinding.instance.platformDispatcher.defaultRouteName;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, String fakeValue) {
        binding.platformDispatcher.defaultRouteNameTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake accessibility features', (WidgetTester tester) async {
    verifyThatTestPlatformDispatcherCanFakeProperty<AccessibilityFeatures>(
      tester: tester,
      realValue: PlatformDispatcher.instance.accessibilityFeatures,
      fakeValue: const FakeAccessibilityFeatures(),
      propertyRetriever: () {
        return WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
      },
      propertyFaker: (TestWidgetsFlutterBinding binding, AccessibilityFeatures fakeValue) {
        binding.platformDispatcher.accessibilityFeaturesTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestWindow can fake platform brightness', (WidgetTester tester) async {
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

  testWidgets('TestWindow can clear out fake properties all at once', (WidgetTester tester) async {
    final Locale originalLocale = PlatformDispatcher.instance.locale;
    final double originalTextScaleFactor = PlatformDispatcher.instance.textScaleFactor;
    final TestPlatformDispatcher testPlatformDispatcher = retrieveTestBinding(tester).platformDispatcher;

    // Set fake values for window properties.
    testPlatformDispatcher.localeTestValue = const Locale('foobar');
    testPlatformDispatcher.textScaleFactorTestValue = 3.0;

    // Erase fake window property values.
    testPlatformDispatcher.clearAllTestValues();

    // Verify that the window once again reports real property values.
    expect(WidgetsBinding.instance.platformDispatcher.locale, originalLocale);
    expect(WidgetsBinding.instance.platformDispatcher.textScaleFactor, originalTextScaleFactor);
  });

  testWidgets('TestWindow sends fake locales when WidgetsBindingObserver notifiers are called', (WidgetTester tester) async {
    final List<Locale> defaultLocales = WidgetsBinding.instance.platformDispatcher.locales;
    final TestObserver observer = TestObserver();
    retrieveTestBinding(tester).addObserver(observer);
    final List<Locale> expectedValue = <Locale>[const Locale('fake_language_code')];
    retrieveTestBinding(tester).platformDispatcher.localesTestValue = expectedValue;
    expect(observer.locales, equals(expectedValue));
    retrieveTestBinding(tester).platformDispatcher.localesTestValue = defaultLocales;
  });
}

void verifyThatTestPlatformDispatcherCanFakeProperty<PlatformDispatcherPropertyType>({
  required WidgetTester tester,
  required PlatformDispatcherPropertyType? realValue,
  required PlatformDispatcherPropertyType fakeValue,
  required PlatformDispatcherPropertyType? Function() propertyRetriever,
  required Function(TestWidgetsFlutterBinding, PlatformDispatcherPropertyType fakeValue) propertyFaker,
}) {
  PlatformDispatcherPropertyType? propertyBeforeFaking;
  PlatformDispatcherPropertyType? propertyAfterFaking;

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

class TestObserver with WidgetsBindingObserver {
  List<Locale>? locales;
  Locale? locale;

  @override
  void didChangeLocales(List<Locale>? locales) {
    this.locales = locales;
  }
}

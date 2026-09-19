// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui'
    show
        AccessibilityFeatures,
        Brightness,
        Display,
        FlutterView,
        Locale,
        PlatformDispatcher,
        Size,
        ViewFocusChangeCallback,
        ViewFocusDirection,
        ViewFocusEvent,
        ViewFocusState,
        VoidCallback;

import 'package:flutter/widgets.dart' show WidgetsBinding, WidgetsBindingObserver;
import 'package:flutter_test/flutter_test.dart';

import 'utils/fake_and_mock_utils.dart';

void main() {
  test('TestPlatformDispatcher can handle new methods without breaking', () {
    final VoidCallback? previousOnMetricsChanged = PlatformDispatcher.instance.onMetricsChanged;
    final ViewFocusChangeCallback? previousOnViewFocusChange =
        PlatformDispatcher.instance.onViewFocusChange;
    addTearDown(() {
      PlatformDispatcher.instance.onMetricsChanged = previousOnMetricsChanged;
      PlatformDispatcher.instance.onViewFocusChange = previousOnViewFocusChange;
    });
    final dynamic testPlatformDispatcher = TestPlatformDispatcher(
      platformDispatcher: PlatformDispatcher.instance,
    );
    // ignore: avoid_dynamic_calls
    expect(testPlatformDispatcher.someNewProperty, null);
  });

  testWidgets('TestPlatformDispatcher can fake locale', (WidgetTester tester) async {
    verifyPropertyFaked<Locale>(
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

  testWidgets('TestPlatformDispatcher can fake locales', (WidgetTester tester) async {
    verifyPropertyFaked<List<Locale>>(
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

  testWidgets('TestPlatformDispatcher can fake text scale factor', (WidgetTester tester) async {
    verifyPropertyFaked<double>(
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

  testWidgets('TestPlatformDispatcher can fake clock format', (WidgetTester tester) async {
    verifyPropertyFaked<bool>(
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

  testWidgets('TestPlatformDispatcher can fake supportsShowingSystemContextMenu', (
    WidgetTester tester,
  ) async {
    verifyPropertyFaked<bool>(
      tester: tester,
      realValue: PlatformDispatcher.instance.supportsShowingSystemContextMenu,
      fakeValue: !PlatformDispatcher.instance.supportsShowingSystemContextMenu,
      propertyRetriever: () =>
          WidgetsBinding.instance.platformDispatcher.supportsShowingSystemContextMenu,
      propertyFaker: (TestWidgetsFlutterBinding binding, bool fakeValue) {
        binding.platformDispatcher.supportsShowingSystemContextMenu = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake brieflyShowPassword', (WidgetTester tester) async {
    verifyPropertyFaked<bool>(
      tester: tester,
      realValue: PlatformDispatcher.instance.brieflyShowPassword,
      fakeValue: !PlatformDispatcher.instance.brieflyShowPassword,
      propertyRetriever: () => WidgetsBinding.instance.platformDispatcher.brieflyShowPassword,
      propertyFaker: (TestWidgetsFlutterBinding binding, bool fakeValue) {
        binding.platformDispatcher.brieflyShowPasswordTestValue = fakeValue;
      },
    );
  });

  testWidgets('TestPlatformDispatcher can fake default route name', (WidgetTester tester) async {
    verifyPropertyFaked<String>(
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

  testWidgets('TestPlatformDispatcher can fake accessibility features', (
    WidgetTester tester,
  ) async {
    verifyPropertyFaked<AccessibilityFeatures>(
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

  testWidgets('TestPlatformDispatcher can fake platform brightness', (WidgetTester tester) async {
    verifyPropertyFaked<Brightness>(
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

  testWidgets('TestPlatformDispatcher can clear out fake properties all at once', (
    WidgetTester tester,
  ) async {
    final Locale originalLocale = PlatformDispatcher.instance.locale;
    final double originalTextScaleFactor = PlatformDispatcher.instance.textScaleFactor;
    final TestPlatformDispatcher testPlatformDispatcher = retrieveTestBinding(tester)
        .platformDispatcher;

    // Set fake values for window properties.
    testPlatformDispatcher.localeTestValue = const Locale('foobar');
    testPlatformDispatcher.textScaleFactorTestValue = 3.0;
    testPlatformDispatcher.applicationLocale = const Locale('foobar_app');

    // Erase fake window property values.
    testPlatformDispatcher.clearAllTestValues();

    // Verify that the window once again reports real property values.
    expect(WidgetsBinding.instance.platformDispatcher.locale, originalLocale);
    expect(WidgetsBinding.instance.platformDispatcher.textScaleFactor, originalTextScaleFactor);
    expect(testPlatformDispatcher.applicationLocale, isNull);
  });

  testWidgets(
    'TestPlatformDispatcher sends fake locales when WidgetsBindingObserver notifiers are called',
    (WidgetTester tester) async {
      final List<Locale> defaultLocales = WidgetsBinding.instance.platformDispatcher.locales;
      final observer = TestObserver();
      retrieveTestBinding(tester).addObserver(observer);
      final expectedValue = <Locale>[const Locale('fake_language_code')];
      retrieveTestBinding(tester).platformDispatcher.localesTestValue = expectedValue;
      expect(observer.locales, equals(expectedValue));
      retrieveTestBinding(tester).platformDispatcher.localesTestValue = defaultLocales;
    },
  );

  testWidgets('TestPlatformDispatcher.view getter returns the implicit view', (
    WidgetTester tester,
  ) async {
    expect(
      WidgetsBinding.instance.platformDispatcher.view(id: tester.view.viewId),
      same(tester.view),
    );
  });

  testWidgets('TestPlatformDispatcher addTestView and removeTestView manages custom views', (
    WidgetTester tester,
  ) async {
    var metricsNotificationCount = 0;
    final VoidCallback? previousMetricsChanged = tester.platformDispatcher.onMetricsChanged;
    tester.platformDispatcher.onMetricsChanged = () {
      metricsNotificationCount++;
    };
    // The dispatcher is shared across the tests in this file, so the override
    // has to be put back or it leaks into every test that follows.
    addTearDown(() {
      tester.platformDispatcher.onMetricsChanged = previousMetricsChanged;
    });

    final customView = _FakeFlutterView(display: tester.view.display, viewId: 100);
    tester.platformDispatcher.addTestView(customView);
    addTearDown(() => tester.platformDispatcher.removeTestView(customView));

    expect(metricsNotificationCount, 1);
    final TestFlutterView? addedView = tester.platformDispatcher.view(id: customView.viewId);
    expect(addedView, isNotNull);
    expect(addedView!.viewId, customView.viewId);
    expect(tester.platformDispatcher.views, contains(addedView));

    // Ensure custom view survives metrics changed notifications. This has to go
    // through notifyMetricsChanged: the onMetricsChanged getter reports the
    // callback registered just above, so calling that would count a
    // notification without refreshing the registry the assertion reads.
    tester.platformDispatcher.notifyMetricsChanged();
    expect(metricsNotificationCount, 2);
    expect(tester.platformDispatcher.view(id: customView.viewId), same(addedView));
    expect(tester.platformDispatcher.views, contains(addedView));

    // Adding a replacement view with the same viewId updates the wrapped TestFlutterView.
    final replacementView = _FakeFlutterView(display: tester.view.display, viewId: 100);
    tester.platformDispatcher.addTestView(replacementView);
    expect(metricsNotificationCount, 3);
    final TestFlutterView? updatedView = tester.platformDispatcher.view(id: customView.viewId);
    expect(updatedView, isNotNull);
    expect(updatedView, isNot(same(addedView)));
    expect(tester.platformDispatcher.views, contains(updatedView));
    expect(tester.platformDispatcher.views, isNot(contains(addedView)));

    // Removing the view removes it from views and view(id:).
    tester.platformDispatcher.removeTestView(replacementView);
    expect(metricsNotificationCount, 4);
    expect(tester.platformDispatcher.view(id: customView.viewId), isNull);
    expect(tester.platformDispatcher.views, isNot(contains(updatedView)));

    // Removing an already removed or unadded view is a no-op.
    tester.platformDispatcher.removeTestView(replacementView);
    expect(metricsNotificationCount, 4);
  });

  testWidgets('TestPlatformDispatcher clearAllTestValues removes custom views', (
    WidgetTester tester,
  ) async {
    final customView = _FakeFlutterView(display: tester.view.display, viewId: 101);
    tester.platformDispatcher.addTestView(customView);
    addTearDown(() => tester.platformDispatcher.removeTestView(customView));

    expect(tester.platformDispatcher.view(id: customView.viewId), isNotNull);

    tester.platformDispatcher.clearAllTestValues();

    // clearAllTestValues drops the custom views and refreshes the registry, so
    // the view is gone from both view(id:) and views.
    expect(tester.platformDispatcher.view(id: customView.viewId), isNull);
    expect(
      tester.platformDispatcher.views.map((FlutterView view) => view.viewId),
      isNot(contains(customView.viewId)),
    );
  });

  testWidgets(
    'TestPlatformDispatcher updates display on TestFlutterView when view changes display',
    (WidgetTester tester) async {
      final display1 = _FakeDisplay(id: 1);
      final display2 = _FakeDisplay(id: 2);
      final fakeView = _FakeFlutterView(display: display1, viewId: 100);
      final backingDispatcher = _FakePlatformDispatcher(
        displays: <Display>[display1, display2],
        views: <FlutterView>[fakeView],
      );
      final testDispatcher = TestPlatformDispatcher(platformDispatcher: backingDispatcher);

      final TestFlutterView originalTestView = testDispatcher.views.single;
      expect(originalTestView.display.id, display1.id);

      // Set a test value override on the TestFlutterView.
      originalTestView.physicalSize = const Size(800, 600);
      expect(originalTestView.physicalSize, const Size(800, 600));

      // Move the view to display2 and trigger metrics change.
      fakeView.display = display2;
      backingDispatcher.onMetricsChanged?.call();

      final TestFlutterView updatedTestView = testDispatcher.views.single;
      // The instance is retained, preserving test value overrides.
      expect(updatedTestView, same(originalTestView));
      expect(updatedTestView.display.id, display2.id);
      expect(updatedTestView.physicalSize, const Size(800, 600));
    },
  );

  testWidgets('TestPlatformDispatcher keeps one view when a custom view shadows an engine view', (
    WidgetTester tester,
  ) async {
    final display = _FakeDisplay(id: 1);
    final engineView = _FakeFlutterView(display: display, viewId: 100);
    final backingDispatcher = _FakePlatformDispatcher(
      displays: <Display>[display],
      views: <FlutterView>[engineView],
    );
    final testDispatcher = TestPlatformDispatcher(platformDispatcher: backingDispatcher);

    final TestFlutterView engineTestView = testDispatcher.views.single;

    // A custom view registered for an id the engine also reports takes over
    // that id, rather than adding a second view alongside it.
    final customView = _FakeFlutterView(display: display, viewId: 100);
    testDispatcher.addTestView(customView);

    final TestFlutterView shadowing = testDispatcher.views.single;
    expect(shadowing, isNot(same(engineTestView)));
    expect(testDispatcher.view(id: 100), same(shadowing));

    // The wrapper survives refreshes, so the test values set on it survive too.
    shadowing.physicalSize = const Size(800, 600);
    backingDispatcher.onMetricsChanged?.call();
    expect(testDispatcher.views.single, same(shadowing));
    expect(shadowing.physicalSize, const Size(800, 600));
    backingDispatcher.onMetricsChanged?.call();
    expect(testDispatcher.views.single, same(shadowing));

    // Removing it brings the engine's view back.
    testDispatcher.removeTestView(customView);
    final TestFlutterView restored = testDispatcher.views.single;
    expect(restored, isNot(same(shadowing)));
    expect(restored.viewId, 100);
  });

  testWidgets('notifyViewFocusChanged records the focused view, and resetting unfocuses it', (
    WidgetTester tester,
  ) async {
    final display = _FakeDisplay(id: 1);
    final backingDispatcher = _FakePlatformDispatcher(
      displays: <Display>[display],
      views: <FlutterView>[_FakeFlutterView(display: display, viewId: 100)],
    );
    final testDispatcher = TestPlatformDispatcher(platformDispatcher: backingDispatcher);

    final received = <ViewFocusEvent>[];
    testDispatcher.onViewFocusChange = received.add;

    expect(testDispatcher.currentlyFocusedViewIdTestValue, isNull);

    testDispatcher.notifyViewFocusChanged(
      const ViewFocusEvent(
        viewId: 100,
        state: ViewFocusState.focused,
        direction: ViewFocusDirection.forward,
      ),
    );

    expect(testDispatcher.currentlyFocusedViewIdTestValue, 100);
    expect(received, hasLength(1));

    // Recording the focused view is what lets the reset unfocus it. Without it
    // a focused view outlives the test that focused it.
    testDispatcher.resetFocusedViewTestValues();

    expect(testDispatcher.currentlyFocusedViewIdTestValue, isNull);
    expect(received, hasLength(2));
    expect(received.last.viewId, 100);
    expect(received.last.state, ViewFocusState.unfocused);
  });

  testWidgets('a metrics change refreshes the view registry before it notifies', (
    WidgetTester tester,
  ) async {
    final display = _FakeDisplay(id: 1);
    final backingDispatcher = _FakePlatformDispatcher(
      displays: <Display>[display],
      views: <FlutterView>[_FakeFlutterView(display: display, viewId: 100)],
    );
    final testDispatcher = TestPlatformDispatcher(platformDispatcher: backingDispatcher);

    TestFlutterView? seenWhileNotifying;
    testDispatcher.onMetricsChanged = () {
      seenWhileNotifying = testDispatcher.view(id: 200);
    };

    testDispatcher.addTestView(_FakeFlutterView(display: display, viewId: 200));

    // The listener could already see the new view, so the registry was rebuilt
    // before the notification went out rather than after it.
    expect(seenWhileNotifying, isNotNull);
    expect(seenWhileNotifying!.viewId, 200);
  });

  testWidgets('TestPlatformDispatcher has a working scaleFontSize implementation', (
    WidgetTester tester,
  ) async {
    expect(
      TestPlatformDispatcher(
        platformDispatcher: _FakePlatformDispatcher(
          displays: <Display>[_FakeDisplay(id: 2)],
          views: <FlutterView>[_FakeFlutterView(display: _FakeDisplay(id: 1))],
        ),
      ).scaleFontSize(2.0),
      2.0,
    );
  });

  // TODO(pdblasi-google): Removed this group of tests when the Display API is stable and supported on all platforms.
  group('TestPlatformDispatcher with unsupported Display API', () {
    testWidgets('can initialize with empty displays', (WidgetTester tester) async {
      expect(() {
        TestPlatformDispatcher(
          platformDispatcher: _FakePlatformDispatcher(
            displays: <Display>[],
            views: <FlutterView>[_FakeFlutterView()],
          ),
        );
      }, isNot(throwsA(anything)));
    });

    testWidgets('can initialize with mismatched displays', (WidgetTester tester) async {
      expect(() {
        TestPlatformDispatcher(
          platformDispatcher: _FakePlatformDispatcher(
            displays: <Display>[_FakeDisplay(id: 2)],
            views: <FlutterView>[_FakeFlutterView(display: _FakeDisplay(id: 1))],
          ),
        );
      }, isNot(throwsA(anything)));
    });

    testWidgets('creates test views for all views', (WidgetTester tester) async {
      final PlatformDispatcher backingDispatcher = _FakePlatformDispatcher(
        displays: <Display>[],
        views: <FlutterView>[_FakeFlutterView()],
      );
      final testDispatcher = TestPlatformDispatcher(platformDispatcher: backingDispatcher);

      expect(testDispatcher.views.length, backingDispatcher.views.length);
    });

    group('creates TestFlutterViews', () {
      testWidgets('that defaults to the correct devicePixelRatio', (WidgetTester tester) async {
        const expectedDpr = 2.5;
        final testDispatcher = TestPlatformDispatcher(
          platformDispatcher: _FakePlatformDispatcher(
            displays: <Display>[],
            views: <FlutterView>[_FakeFlutterView(devicePixelRatio: expectedDpr)],
          ),
        );

        expect(testDispatcher.views.single.devicePixelRatio, expectedDpr);
      });

      testWidgets('with working devicePixelRatio setter', (WidgetTester tester) async {
        const expectedDpr = 2.5;
        const double defaultDpr = 4;
        final testDispatcher = TestPlatformDispatcher(
          platformDispatcher: _FakePlatformDispatcher(
            displays: <Display>[],
            views: <FlutterView>[_FakeFlutterView(devicePixelRatio: defaultDpr)],
          ),
        );

        testDispatcher.views.single.devicePixelRatio = expectedDpr;

        expect(testDispatcher.views.single.devicePixelRatio, expectedDpr);
      });

      testWidgets('with working resetDevicePixelRatio', (WidgetTester tester) async {
        const changedDpr = 2.5;
        const double defaultDpr = 4;
        final testDispatcher = TestPlatformDispatcher(
          platformDispatcher: _FakePlatformDispatcher(
            displays: <Display>[],
            views: <FlutterView>[_FakeFlutterView(devicePixelRatio: defaultDpr)],
          ),
        );

        testDispatcher.views.single.devicePixelRatio = changedDpr;
        testDispatcher.views.single.resetDevicePixelRatio();

        expect(testDispatcher.views.single.devicePixelRatio, defaultDpr);
      });
    });
  });

  testWidgets('saving and restoring onMetricsChanged does not cause infinite recursion', (
    WidgetTester tester,
  ) async {
    final VoidCallback? previous = tester.platformDispatcher.onMetricsChanged;
    // The restore below is the behaviour under test, but an expect that fails
    // before it would leak the override, so it is also guaranteed here.
    addTearDown(() {
      tester.platformDispatcher.onMetricsChanged = previous;
    });
    var callCount = 0;
    tester.platformDispatcher.onMetricsChanged = () {
      callCount++;
    };
    tester.platformDispatcher.onMetricsChanged?.call();
    expect(callCount, 1);

    // Restoring the previously saved callback must not cause infinite recursion.
    tester.platformDispatcher.onMetricsChanged = previous;
    expect(() => tester.platformDispatcher.onMetricsChanged?.call(), returnsNormally);
    expect(callCount, 1);
  });

  testWidgets('saving and restoring onViewFocusChange does not cause infinite recursion', (
    WidgetTester tester,
  ) async {
    final ViewFocusChangeCallback? previous = tester.platformDispatcher.onViewFocusChange;
    // The restore below is the behaviour under test, but an expect that fails
    // before it would leak the override, so it is also guaranteed here.
    addTearDown(() {
      tester.platformDispatcher.onViewFocusChange = previous;
    });
    var callCount = 0;
    tester.platformDispatcher.onViewFocusChange = (ViewFocusEvent event) {
      callCount++;
    };
    const event = ViewFocusEvent(
      viewId: 0,
      state: ViewFocusState.focused,
      direction: ViewFocusDirection.undefined,
    );
    tester.platformDispatcher.onViewFocusChange?.call(event);
    expect(callCount, 1);

    // Restoring the previously saved callback must not cause infinite recursion.
    tester.platformDispatcher.onViewFocusChange = previous;
    expect(() => tester.platformDispatcher.onViewFocusChange?.call(event), returnsNormally);
    expect(callCount, 1);
  });

  testWidgets('onMetricsChanged has symmetric getter and setter and supports chaining', (
    WidgetTester tester,
  ) async {
    final VoidCallback? previous = tester.platformDispatcher.onMetricsChanged;
    addTearDown(() {
      tester.platformDispatcher.onMetricsChanged = previous;
    });

    var initialCalled = false;
    void initialCallback() {
      initialCalled = true;
    }

    tester.platformDispatcher.onMetricsChanged = initialCallback;
    expect(tester.platformDispatcher.onMetricsChanged, initialCallback);

    // Chain through the getter, not through the local: reading back what was
    // set is the whole point, and a getter that reported the dispatcher's own
    // handler instead would drop the callback the test registered.
    final VoidCallback? existing = tester.platformDispatcher.onMetricsChanged;
    var chainedCalled = false;
    tester.platformDispatcher.onMetricsChanged = () {
      chainedCalled = true;
      existing?.call();
    };

    tester.platformDispatcher.onMetricsChanged?.call();
    expect(chainedCalled, isTrue);
    expect(initialCalled, isTrue);

    // Restoring initial callback returns original reference without losing listener.
    tester.platformDispatcher.onMetricsChanged = initialCallback;
    expect(tester.platformDispatcher.onMetricsChanged, initialCallback);
  });

  testWidgets('onViewFocusChange has symmetric getter and setter and supports chaining', (
    WidgetTester tester,
  ) async {
    final ViewFocusChangeCallback? previous = tester.platformDispatcher.onViewFocusChange;
    addTearDown(() {
      tester.platformDispatcher.onViewFocusChange = previous;
    });

    var initialCalled = false;
    void initialCallback(ViewFocusEvent event) {
      initialCalled = true;
    }

    tester.platformDispatcher.onViewFocusChange = initialCallback;
    expect(tester.platformDispatcher.onViewFocusChange, initialCallback);

    // Chain through the getter, not through the local: reading back what was
    // set is the whole point, and a getter that reported the dispatcher's own
    // handler instead would drop the callback the test registered.
    final ViewFocusChangeCallback? existing = tester.platformDispatcher.onViewFocusChange;
    var chainedCalled = false;
    tester.platformDispatcher.onViewFocusChange = (ViewFocusEvent event) {
      chainedCalled = true;
      existing?.call(event);
    };

    const event = ViewFocusEvent(
      viewId: 0,
      state: ViewFocusState.focused,
      direction: ViewFocusDirection.undefined,
    );
    tester.platformDispatcher.onViewFocusChange?.call(event);
    expect(chainedCalled, isTrue);
    expect(initialCalled, isTrue);

    // Restoring initial callback returns original reference without losing listener.
    tester.platformDispatcher.onViewFocusChange = initialCallback;
    expect(tester.platformDispatcher.onViewFocusChange, initialCallback);
  });
}

class TestObserver with WidgetsBindingObserver {
  List<Locale>? locales;

  @override
  void didChangeLocales(List<Locale>? locales) {
    this.locales = locales;
  }
}

class _FakeDisplay extends Fake implements Display {
  _FakeDisplay({this.id = 0});

  @override
  final int id;
}

class _FakeFlutterView extends Fake implements FlutterView {
  _FakeFlutterView({this.devicePixelRatio = 1, this._display, this.viewId = 1});

  @override
  final double devicePixelRatio;

  // This emulates the PlatformDispatcher not having a display on the engine
  // side. We don't have access to the `_displayId` used in the engine to try
  // to find it and can't directly extend `FlutterView` to emulate it closer.
  @override
  Display get display {
    assert(_display != null);
    return _display!;
  }

  set display(Display value) {
    _display = value;
  }

  Display? _display;

  @override
  final int viewId;
}

class _FakePlatformDispatcher extends Fake implements PlatformDispatcher {
  _FakePlatformDispatcher({required this.displays, required this.views});
  @override
  final Iterable<Display> displays;

  @override
  final Iterable<FlutterView> views;

  @override
  FlutterView? view({required int id}) {
    for (final FlutterView v in views) {
      if (v.viewId == id) {
        return v;
      }
    }
    return null;
  }

  @override
  VoidCallback? onMetricsChanged;

  @override
  ViewFocusChangeCallback? onViewFocusChange;

  @override
  VoidCallback? onTextScaleFactorChanged;

  @override
  VoidCallback? onPlatformBrightnessChanged;

  @override
  double get textScaleFactor => 1.0;
}

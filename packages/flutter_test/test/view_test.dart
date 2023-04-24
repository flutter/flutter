// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/fake_and_mock_utils.dart';

void main() {
  group('TestFlutterView', () {
    FlutterView trueImplicitView() => PlatformDispatcher.instance.implicitView!;
    FlutterView boundImplicitView() => WidgetsBinding.instance.platformDispatcher.implicitView!;

    tearDown(() {
      final TestFlutterView view = (WidgetsBinding.instance as TestWidgetsFlutterBinding).platformDispatcher.views.single;
      view.reset();
    });

    testWidgets('can handle new methods without breaking', (final WidgetTester tester) async {
      final dynamic testView = tester.view;
      // ignore: avoid_dynamic_calls
      expect(testView.someNewProperty, null);
    });

    testWidgets('can fake devicePixelRatio', (final WidgetTester tester) async {
      verifyPropertyFaked<double>(
        tester: tester,
        realValue: trueImplicitView().devicePixelRatio,
        fakeValue: 2.5,
        propertyRetriever: () => boundImplicitView().devicePixelRatio,
        propertyFaker: (final _, final double fakeValue) {
          tester.view.devicePixelRatio = fakeValue;
        },
      );
    });

    testWidgets('can reset devicePixelRatio', (final WidgetTester tester) async {
      verifyPropertyReset<double>(
        tester: tester,
        fakeValue: 2.5,
        propertyRetriever: () => boundImplicitView().devicePixelRatio,
        propertyResetter: () {
          tester.view.resetDevicePixelRatio();
        },
        propertyFaker: (final double fakeValue) {
          tester.view.devicePixelRatio = fakeValue;
        },
      );
    });

    testWidgets('can fake displayFeatures', (final WidgetTester tester) async {
      verifyPropertyFaked<List<DisplayFeature>>(
        tester: tester,
        realValue: trueImplicitView().displayFeatures,
        fakeValue: <DisplayFeature>[const DisplayFeature(bounds: Rect.fromLTWH(0, 0, 500, 30), type: DisplayFeatureType.unknown, state: DisplayFeatureState.unknown)],
        propertyRetriever: () => boundImplicitView().displayFeatures,
        propertyFaker: (final _, final List<DisplayFeature> fakeValue) {
          tester.view.displayFeatures = fakeValue;
        },
      );
    });

    testWidgets('can reset displayFeatures', (final WidgetTester tester) async {
      verifyPropertyReset<List<DisplayFeature>>(
        tester: tester,
        fakeValue: <DisplayFeature>[const DisplayFeature(bounds: Rect.fromLTWH(0, 0, 500, 30), type: DisplayFeatureType.unknown, state: DisplayFeatureState.unknown)],
        propertyRetriever: () => boundImplicitView().displayFeatures,
        propertyResetter: () {
          tester.view.resetDisplayFeatures();
        },
        propertyFaker: (final List<DisplayFeature> fakeValue) {
          tester.view.displayFeatures = fakeValue;
        },
      );
    });

    testWidgets('can fake padding', (final WidgetTester tester) async {
      verifyPropertyFaked<ViewPadding>(
        tester: tester,
        realValue: trueImplicitView().padding,
        fakeValue: FakeViewPadding.zero,
        propertyRetriever: () => boundImplicitView().padding,
        propertyFaker: (final _, final ViewPadding fakeValue) {
          tester.view.padding = fakeValue as FakeViewPadding;
        },
        matcher: matchesViewPadding
      );
    });

    testWidgets('can reset padding', (final WidgetTester tester) async {
      verifyPropertyReset<ViewPadding>(
        tester: tester,
        fakeValue: FakeViewPadding.zero,
        propertyRetriever: () => boundImplicitView().padding,
        propertyResetter: () {
          tester.view.resetPadding();
        },
        propertyFaker: (final ViewPadding fakeValue) {
          tester.view.padding = fakeValue as FakeViewPadding;
        },
        matcher: matchesViewPadding
      );
    });

    testWidgets('can fake physicalGeometry', (final WidgetTester tester) async {
      verifyPropertyFaked<Rect>(
        tester: tester,
        realValue: trueImplicitView().physicalGeometry,
        fakeValue: const Rect.fromLTWH(0, 0, 550, 850),
        propertyRetriever: () => boundImplicitView().physicalGeometry,
        propertyFaker: (final _, final Rect fakeValue) {
          tester.view.physicalGeometry = fakeValue;
        },
      );
    });

    testWidgets('can reset physicalGeometry', (final WidgetTester tester) async {
      verifyPropertyReset<Rect>(
        tester: tester,
        fakeValue: const Rect.fromLTWH(0, 0, 35, 475),
        propertyRetriever: () => boundImplicitView().physicalGeometry,
        propertyResetter: () {
          tester.view.resetPhysicalGeometry();
        },
        propertyFaker: (final Rect fakeValue) {
          tester.view.physicalGeometry = fakeValue;
        },
      );
    });

    testWidgets('updating physicalGeometry also updates physicalSize', (final WidgetTester tester) async {
      const Rect testGeometry = Rect.fromLTWH(0, 0, 450, 575);
      tester.view.physicalGeometry = testGeometry;

      expect(tester.view.physicalSize, testGeometry.size);
    });

    testWidgets('can fake physicalSize', (final WidgetTester tester) async {
      verifyPropertyFaked<Size>(
        tester: tester,
        realValue: trueImplicitView().physicalSize,
        fakeValue: const Size(50, 50),
        propertyRetriever: () => boundImplicitView().physicalSize,
        propertyFaker: (final _, final Size fakeValue) {
          tester.view.physicalSize = fakeValue;
        },
      );
    });

    testWidgets('can reset physicalSize', (final WidgetTester tester) async {
      verifyPropertyReset<Size>(
        tester: tester,
        fakeValue: const Size(50, 50),
        propertyRetriever: () => boundImplicitView().physicalSize,
        propertyResetter: () {
          tester.view.resetPhysicalSize();
        },
        propertyFaker: (final Size fakeValue) {
          tester.view.physicalSize = fakeValue;
        },
      );
    });

    testWidgets('updating physicalSize also updates physicalGeometry', (final WidgetTester tester) async {
      const Rect testGeometry = Rect.fromLTWH(0, 0, 450, 575);
      const Size testSize = Size(50, 50);
      const Rect expectedGeometry = Rect.fromLTWH(0, 0, 50, 50);

      tester.view.physicalGeometry = testGeometry;
      tester.view.physicalSize = testSize;

      expect(tester.view.physicalGeometry, expectedGeometry);
    });

    testWidgets('can fake systemGestureInsets', (final WidgetTester tester) async {
      verifyPropertyFaked<ViewPadding>(
        tester: tester,
        realValue: trueImplicitView().systemGestureInsets,
        fakeValue: FakeViewPadding.zero,
        propertyRetriever: () => boundImplicitView().systemGestureInsets,
        propertyFaker: (final _, final ViewPadding fakeValue) {
          tester.view.systemGestureInsets = fakeValue as FakeViewPadding;
        },
        matcher: matchesViewPadding
      );
    });

    testWidgets('can reset systemGestureInsets', (final WidgetTester tester) async {
      verifyPropertyReset<ViewPadding>(
        tester: tester,
        fakeValue: FakeViewPadding.zero,
        propertyRetriever: () => boundImplicitView().systemGestureInsets,
        propertyResetter: () {
          tester.view.resetSystemGestureInsets();
        },
        propertyFaker: (final ViewPadding fakeValue) {
          tester.view.systemGestureInsets = fakeValue as FakeViewPadding;
        },
        matcher: matchesViewPadding
      );
    });

    testWidgets('can fake viewInsets', (final WidgetTester tester) async {
      verifyPropertyFaked<ViewPadding>(
        tester: tester,
        realValue: trueImplicitView().viewInsets,
        fakeValue: FakeViewPadding.zero,
        propertyRetriever: () => boundImplicitView().viewInsets,
        propertyFaker: (final _, final ViewPadding fakeValue) {
          tester.view.viewInsets = fakeValue as FakeViewPadding;
        },
        matcher: matchesViewPadding
      );
    });

    testWidgets('can reset viewInsets', (final WidgetTester tester) async {
      verifyPropertyReset<ViewPadding>(
        tester: tester,
        fakeValue: FakeViewPadding.zero,
        propertyRetriever: () => boundImplicitView().viewInsets,
        propertyResetter: () {
          tester.view.resetViewInsets();
        },
        propertyFaker: (final ViewPadding fakeValue) {
          tester.view.viewInsets = fakeValue as FakeViewPadding;
        },
        matcher: matchesViewPadding
      );
    });

    testWidgets('can fake viewPadding', (final WidgetTester tester) async {
      verifyPropertyFaked<ViewPadding>(
        tester: tester,
        realValue: trueImplicitView().viewPadding,
        fakeValue: FakeViewPadding.zero,
        propertyRetriever: () => boundImplicitView().viewPadding,
        propertyFaker: (final _, final ViewPadding fakeValue) {
          tester.view.viewPadding = fakeValue as FakeViewPadding;
        },
        matcher: matchesViewPadding
      );
    });

    testWidgets('can reset viewPadding', (final WidgetTester tester) async {
      verifyPropertyReset<ViewPadding>(
        tester: tester,
        fakeValue: FakeViewPadding.zero,
        propertyRetriever: () => boundImplicitView().viewPadding,
        propertyResetter: () {
          tester.view.resetViewPadding();
        },
        propertyFaker: (final ViewPadding fakeValue) {
          tester.view.viewPadding = fakeValue as FakeViewPadding;
        },
        matcher: matchesViewPadding
      );
    });

    testWidgets('can clear out fake properties all at once', (final WidgetTester tester) async {
      final FlutterViewSnapshot initial = FlutterViewSnapshot(tester.view);

      tester.view.devicePixelRatio = 7;
      tester.view.displayFeatures = <DisplayFeature>[const DisplayFeature(bounds: Rect.fromLTWH(0, 0, 20, 300), type: DisplayFeatureType.unknown, state: DisplayFeatureState.unknown)];
      tester.view.padding = FakeViewPadding.zero;
      tester.view.physicalGeometry = const Rect.fromLTWH(0, 0, 505, 805);
      tester.view.systemGestureInsets = FakeViewPadding.zero;
      tester.view.viewInsets = FakeViewPadding.zero;
      tester.view.viewPadding = FakeViewPadding.zero;
      tester.view.gestureSettings = const GestureSettings(physicalTouchSlop: 4, physicalDoubleTapSlop: 5);

      final FlutterViewSnapshot faked = FlutterViewSnapshot(tester.view);

      tester.view.reset();

      final FlutterViewSnapshot reset = FlutterViewSnapshot(tester.view);

      expect(initial, isNot(matchesSnapshot(faked)));
      expect(initial, matchesSnapshot(reset));
    });

    testWidgets('render is passed through to backing FlutterView', (final WidgetTester tester) async {
      final Scene expectedScene = SceneBuilder().build();
      final _FakeFlutterView backingView = _FakeFlutterView();
      final TestFlutterView view = TestFlutterView(
        view: backingView,
        platformDispatcher: tester.binding.platformDispatcher,
      );

      view.render(expectedScene);

      expect(backingView.lastRenderedScene, isNotNull);
      expect(backingView.lastRenderedScene, expectedScene);
    });

    testWidgets('updateSemantics is passed through to backing FlutterView', (final WidgetTester tester) async {
      final SemanticsUpdate expectedUpdate = SemanticsUpdateBuilder().build();
      final _FakeFlutterView backingView = _FakeFlutterView();
      final TestFlutterView view = TestFlutterView(
        view: backingView,
        platformDispatcher: tester.binding.platformDispatcher,
      );

      view.updateSemantics(expectedUpdate);

      expect(backingView.lastSemanticsUpdate, isNotNull);
      expect(backingView.lastSemanticsUpdate, expectedUpdate);
    });
  });
}


Matcher matchesSnapshot(final FlutterViewSnapshot expected) => _FlutterViewSnapshotMatcher(expected);

class _FlutterViewSnapshotMatcher extends Matcher {
  _FlutterViewSnapshotMatcher(this.expected);

  final FlutterViewSnapshot expected;

  @override
  Description describe(final Description description) {
    description.add('snapshot of a FlutterView matches');
    return description;
  }

  @override
  Description describeMismatch(final dynamic item, final Description mismatchDescription, final Map<dynamic, dynamic> matchState, final bool verbose) {
    assert(item is FlutterViewSnapshot, 'Can only match against snapshots of FlutterView.');
    final FlutterViewSnapshot actual = item as FlutterViewSnapshot;

    if (actual.devicePixelRatio != expected.devicePixelRatio) {
      mismatchDescription.add('actual.devicePixelRatio (${actual.devicePixelRatio}) did not match expected.devicePixelRatio (${expected.devicePixelRatio})');
    }
    if (!actual.displayFeatures.equals(expected.displayFeatures)) {
      mismatchDescription.add('actual.displayFeatures did not match expected.devicePixelRatio');
      mismatchDescription.addAll('Actual: [', ',', ']', actual.displayFeatures);
      mismatchDescription.addAll('Expected: [', ',', ']', expected.displayFeatures);
    }
    if (actual.gestureSettings != expected.gestureSettings) {
      mismatchDescription.add('actual.gestureSettings (${actual.gestureSettings}) did not match expected.gestureSettings (${expected.gestureSettings})');
    }

    final Matcher paddingMatcher = matchesViewPadding(expected.padding);
    if (!paddingMatcher.matches(actual.padding, matchState)) {
      mismatchDescription.add('actual.padding (${actual.padding}) did not match expected.padding (${expected.padding})');
      paddingMatcher.describeMismatch(actual.padding, mismatchDescription, matchState, verbose);
    }

    if (actual.physicalGeometry != expected.physicalGeometry) {
      mismatchDescription.add('actual.physicalGeometry (${actual.physicalGeometry}) did not match expected.physicalGeometry (${expected.physicalGeometry})');
    }
    if (actual.physicalSize != expected.physicalSize) {
      mismatchDescription.add('actual.physicalSize (${actual.physicalSize}) did not match expected.physicalSize (${expected.physicalSize})');
    }

    final Matcher systemGestureInsetsMatcher = matchesViewPadding(expected.systemGestureInsets);
    if (!systemGestureInsetsMatcher.matches(actual.systemGestureInsets, matchState)) {
      mismatchDescription.add('actual.systemGestureInsets (${actual.systemGestureInsets}) did not match expected.systemGestureInsets (${expected.systemGestureInsets})');
      systemGestureInsetsMatcher.describeMismatch(actual.systemGestureInsets, mismatchDescription, matchState, verbose);
    }

    if (actual.viewId != expected.viewId) {
      mismatchDescription.add('actual.viewId (${actual.viewId}) did not match expected.viewId (${expected.viewId})');
    }

    final Matcher viewInsetsMatcher = matchesViewPadding(expected.viewInsets);
    if (!viewInsetsMatcher.matches(actual.viewInsets, matchState)) {
      mismatchDescription.add('actual.viewInsets (${actual.viewInsets}) did not match expected.viewInsets (${expected.viewInsets})');
      viewInsetsMatcher.describeMismatch(actual.viewInsets, mismatchDescription, matchState, verbose);
    }

    final Matcher viewPaddingMatcher = matchesViewPadding(expected.viewPadding);
    if (!viewPaddingMatcher.matches(actual.viewPadding, matchState)) {
      mismatchDescription.add('actual.viewPadding (${actual.viewPadding}) did not match expected.devicePixelRatio (${expected.viewPadding})');
      viewPaddingMatcher.describeMismatch(actual.viewPadding, mismatchDescription, matchState, verbose);
    }

    return mismatchDescription;
  }

  @override
  bool matches(final dynamic item, final Map<dynamic, dynamic> matchState) {
    assert(item is FlutterViewSnapshot, 'Can only match against snapshots of FlutterView.');
    final FlutterViewSnapshot actual = item as FlutterViewSnapshot;

    return actual.devicePixelRatio == expected.devicePixelRatio &&
      actual.displayFeatures.equals(expected.displayFeatures) &&
      actual.gestureSettings == expected.gestureSettings &&
      matchesViewPadding(expected.padding).matches(actual.padding, matchState) &&
      actual.physicalGeometry == expected.physicalGeometry &&
      actual.physicalSize == expected.physicalSize &&
      matchesViewPadding(expected.systemGestureInsets).matches(actual.padding, matchState) &&
      actual.viewId == expected.viewId &&
      matchesViewPadding(expected.viewInsets).matches(actual.viewInsets, matchState) &&
      matchesViewPadding(expected.viewPadding).matches(actual.viewPadding, matchState);
  }
}

class FlutterViewSnapshot {
  FlutterViewSnapshot(final FlutterView view) :
    devicePixelRatio = view.devicePixelRatio,
    displayFeatures = <DisplayFeature>[...view.displayFeatures],
    gestureSettings = view.gestureSettings,
    padding = view.padding,
    physicalGeometry = view.physicalGeometry,
    physicalSize = view.physicalSize,
    systemGestureInsets = view.systemGestureInsets,
    viewId = view.viewId,
    viewInsets = view.viewInsets,
    viewPadding = view.viewPadding;

  final double devicePixelRatio;
  final List<DisplayFeature> displayFeatures;
  final GestureSettings  gestureSettings;
  final ViewPadding  padding;
  final Rect physicalGeometry;
  final Size physicalSize;
  final ViewPadding systemGestureInsets;
  final Object viewId;
  final ViewPadding viewInsets;
  final ViewPadding viewPadding;
}

class _FakeFlutterView implements FlutterView {
  SemanticsUpdate? lastSemanticsUpdate;
  Scene? lastRenderedScene;

  @override
  void updateSemantics(final SemanticsUpdate update) {
    lastSemanticsUpdate = update;
  }

  @override
  void render(final Scene scene) {
    lastRenderedScene = scene;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) {
    return null;
  }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/src/foundation/_features.dart';
import 'package:flutter/src/widgets/_accessibility_evaluations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'multi_view_testing.dart';

/// A [ui.FlutterView] that reports an id its [platformDispatcher] does not
/// resolve, standing in for a view the framework did not produce.
class _UnboundView implements ui.FlutterView {
  _UnboundView(this._view, this.viewId);

  final ui.FlutterView _view;

  @override
  final int viewId;

  @override
  ui.PlatformDispatcher get platformDispatcher => _view.platformDispatcher;

  @override
  double get devicePixelRatio => _view.devicePixelRatio;

  @override
  ui.Size get physicalSize => _view.physicalSize;

  @override
  ui.ViewPadding get padding => _view.padding;

  @override
  ui.ViewPadding get viewPadding => _view.viewPadding;

  @override
  ui.ViewPadding get viewInsets => _view.viewInsets;

  @override
  ui.ViewPadding get systemGestureInsets => _view.systemGestureInsets;

  @override
  List<ui.DisplayFeature> get displayFeatures => _view.displayFeatures;

  @override
  ui.DisplayCornerRadii? get displayCornerRadii => _view.displayCornerRadii;

  @override
  ui.GestureSettings get gestureSettings => _view.gestureSettings;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not needed by these tests.');
}

/// Every metric [DebugViewMetricsOverride] can set that [MediaQueryData]
/// surfaces: an override that sets it, how to read it back, and the value
/// [MediaQueryData] must then report.
///
/// The test view reports 2400x1800 physical pixels at a device pixel ratio of
/// 3, which is what the logical expectations below are derived from.
///
/// A metric that is in neither this table nor [_notSurfacedByMediaQuery] is one
/// [MediaQueryData] could silently stop honoring, which is the failure the
/// per-view resolution in `MediaQueryData.fromView` exists to prevent.
final Map<String, (DebugViewMetricsOverride, Object? Function(MediaQueryData), Object?)>
_surfacedMetrics = <String, (DebugViewMetricsOverride, Object? Function(MediaQueryData), Object?)>{
  'devicePixelRatio': (
    const DebugViewMetricsOverride(devicePixelRatio: 6.0),
    (MediaQueryData data) => data.devicePixelRatio,
    6.0,
  ),
  'physicalSize': (
    const DebugViewMetricsOverride(physicalSize: ui.Size(600, 900)),
    (MediaQueryData data) => data.size,
    const Size(200, 300),
  ),
  'padding': (
    const DebugViewMetricsOverride(padding: DebugViewPadding(top: 30)),
    (MediaQueryData data) => data.padding,
    const EdgeInsets.only(top: 10),
  ),
  'viewPadding': (
    const DebugViewMetricsOverride(viewPadding: DebugViewPadding(top: 30)),
    (MediaQueryData data) => data.viewPadding,
    const EdgeInsets.only(top: 10),
  ),
  'viewInsets': (
    const DebugViewMetricsOverride(viewInsets: DebugViewPadding(bottom: 30)),
    (MediaQueryData data) => data.viewInsets,
    const EdgeInsets.only(bottom: 10),
  ),
  'textScaleFactor': (
    const DebugViewMetricsOverride(textScaleFactor: 3.0),
    (MediaQueryData data) => data.textScaler.scale(10),
    30.0,
  ),
  'platformBrightness': (
    const DebugViewMetricsOverride(platformBrightness: ui.Brightness.dark),
    (MediaQueryData data) => data.platformBrightness,
    ui.Brightness.dark,
  ),
  'alwaysUse24HourFormat': (
    const DebugViewMetricsOverride(alwaysUse24HourFormat: true),
    (MediaQueryData data) => data.alwaysUse24HourFormat,
    true,
  ),
  'accessibleNavigation': (
    const DebugViewMetricsOverride(accessibleNavigation: true),
    (MediaQueryData data) => data.accessibleNavigation,
    true,
  ),
  'invertColors': (
    const DebugViewMetricsOverride(invertColors: true),
    (MediaQueryData data) => data.invertColors,
    true,
  ),
  'disableAnimations': (
    const DebugViewMetricsOverride(disableAnimations: true),
    (MediaQueryData data) => data.disableAnimations,
    true,
  ),
  'boldText': (
    const DebugViewMetricsOverride(boldText: true),
    (MediaQueryData data) => data.boldText,
    true,
  ),
  'reduceMotion': (
    const DebugViewMetricsOverride(reduceMotion: true),
    (MediaQueryData data) => data.reduceMotion,
    true,
  ),
  'highContrast': (
    const DebugViewMetricsOverride(highContrast: true),
    (MediaQueryData data) => data.highContrast,
    true,
  ),
  'onOffSwitchLabels': (
    const DebugViewMetricsOverride(onOffSwitchLabels: true),
    (MediaQueryData data) => data.onOffSwitchLabels,
    true,
  ),
  'supportsAnnounce': (
    const DebugViewMetricsOverride(supportsAnnounce: false),
    (MediaQueryData data) => data.supportsAnnounce,
    false,
  ),
};

/// Accessibility flags [DebugViewMetricsOverride] can set that [MediaQueryData]
/// does not expose, so there is nothing for it to honor.
const Set<String> _notSurfacedByMediaQuery = <String>{
  'autoPlayAnimatedImages',
  'autoPlayVideos',
  'deterministicCursor',
};

/// Every metric [DebugViewMetricsOverride] accepts, taken from the class rather
/// than restated here, so that adding one to it fails this file until the new
/// metric is classified above.
///
/// [DebugViewMetricsOverride.fromJson] rejects keys it does not recognize and
/// names the ones it does, which is the only place the full set is available at
/// runtime.
Set<String> _allOverridableMetrics() {
  try {
    DebugViewMetricsOverride.fromJson(const <String, Object?>{'not-a-metric': true});
  } on FormatException catch (error) {
    const marker = 'Supported metrics are: ';
    final int start = error.message.indexOf(marker);
    expect(start, isNonNegative, reason: 'fromJson no longer lists the metrics it supports');
    return error.message.substring(start + marker.length).replaceAll('.', '').split(', ').toSet();
  }
  fail('fromJson accepted an unknown metric');
}

/// Records which [WidgetsBindingObserver] notifications the framework sends.
class _NotificationRecorder with WidgetsBindingObserver {
  int metrics = 0;
  int accessibilityFeatures = 0;
  int textScaleFactor = 0;
  int platformBrightness = 0;

  @override
  void didChangeMetrics() => metrics += 1;

  @override
  void didChangeAccessibilityFeatures() => accessibilityFeatures += 1;

  @override
  void didChangeTextScaleFactor() => textScaleFactor += 1;

  @override
  void didChangePlatformBrightness() => platformBrightness += 1;

  @override
  String toString() =>
      'metrics: $metrics, accessibilityFeatures: $accessibilityFeatures, '
      'textScaleFactor: $textScaleFactor, platformBrightness: $platformBrightness';
}

/// Builds `child` under a [MediaQuery] derived from the view under test, and
/// captures the [MediaQueryData] that reaches it.
Widget _capture(void Function(MediaQueryData data) onData, {Widget? child}) {
  return Builder(
    builder: (BuildContext context) {
      onData(MediaQuery.of(context));
      return child ?? const SizedBox.expand();
    },
  );
}

void main() {
  // Overrides have to be cleared inside the test body rather than in a tear
  // down: debugAssertAllFoundationVarsUnset runs from the test binding's
  // invariant check, which happens before tear downs.

  group('MediaQuery', () {
    testWidgets('reports overridden accessibility features', (WidgetTester tester) async {
      late MediaQueryData data;
      await tester.pumpWidget(_capture((MediaQueryData value) => data = value));
      expect(data.boldText, isFalse);
      expect(data.highContrast, isFalse);
      expect(data.accessibleNavigation, isFalse);
      expect(data.invertColors, isFalse);
      expect(data.disableAnimations, isFalse);
      expect(data.reduceMotion, isFalse);
      expect(data.onOffSwitchLabels, isFalse);
      expect(data.supportsAnnounce, isTrue);

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(
          boldText: true,
          highContrast: true,
          accessibleNavigation: true,
          invertColors: true,
          disableAnimations: true,
          reduceMotion: true,
          onOffSwitchLabels: true,
          supportsAnnounce: false,
        ),
      );
      await tester.pump();

      expect(data.boldText, isTrue);
      expect(data.highContrast, isTrue);
      expect(data.accessibleNavigation, isTrue);
      expect(data.invertColors, isTrue);
      expect(data.disableAnimations, isTrue);
      expect(data.reduceMotion, isTrue);
      expect(data.onOffSwitchLabels, isTrue);
      expect(data.supportsAnnounce, isFalse);

      debugClearViewMetricsOverrides();
      await tester.pump();
      expect(data.boldText, isFalse);
      expect(data.supportsAnnounce, isTrue);
    });

    testWidgets('reports an overridden text scale factor, and scales text with it', (
      WidgetTester tester,
    ) async {
      late MediaQueryData data;
      await tester.pumpWidget(_capture((MediaQueryData value) => data = value));
      expect(data.textScaler.scale(14.0), 14.0);

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(textScaleFactor: 2.5),
      );
      await tester.pump();

      expect(data.textScaler.textScaleFactor, 2.5);
      // The scaled size matters more than the reported factor: SystemTextScaler
      // asks the platform to scale, so an override that only changed the
      // reported factor would leave every piece of text the same size.
      expect(data.textScaler.scale(14.0), 35.0);

      debugClearViewMetricsOverrides();
      await tester.pump();
      expect(data.textScaler.scale(14.0), 14.0);
    });

    testWidgets('reports an overridden brightness and 24 hour format', (WidgetTester tester) async {
      late MediaQueryData data;
      await tester.pumpWidget(_capture((MediaQueryData value) => data = value));
      expect(data.platformBrightness, ui.Brightness.light);
      expect(data.alwaysUse24HourFormat, isFalse);

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(
          platformBrightness: ui.Brightness.dark,
          alwaysUse24HourFormat: true,
        ),
      );
      await tester.pump();

      expect(data.platformBrightness, ui.Brightness.dark);
      expect(data.alwaysUse24HourFormat, isTrue);

      debugClearViewMetricsOverrides();
      await tester.pump();
      expect(data.platformBrightness, ui.Brightness.light);
      expect(data.alwaysUse24HourFormat, isFalse);
    });

    testWidgets('reports overridden padding and insets in logical pixels', (
      WidgetTester tester,
    ) async {
      late MediaQueryData data;
      await tester.pumpWidget(_capture((MediaQueryData value) => data = value));
      expect(data.devicePixelRatio, 3.0);
      expect(data.padding, EdgeInsets.zero);
      expect(data.viewInsets, EdgeInsets.zero);

      // The override is in physical pixels; MediaQuery reports logical ones.
      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(
          padding: DebugViewPadding(top: 141),
          viewPadding: DebugViewPadding(top: 141, bottom: 102),
          viewInsets: DebugViewPadding(bottom: 900),
        ),
      );
      await tester.pump();

      expect(data.padding, const EdgeInsets.only(top: 47));
      expect(data.viewPadding, const EdgeInsets.only(top: 47, bottom: 34));
      expect(data.viewInsets, const EdgeInsets.only(bottom: 300));

      debugClearViewMetricsOverrides();
      await tester.pump();
      expect(data.padding, EdgeInsets.zero);
    });

    testWidgets('yields platformBrightness to debugBrightnessOverride', (
      WidgetTester tester,
    ) async {
      // debugBrightnessOverride is applied by MediaQuery after the data has
      // been built, so it wins there. Pinned because the two mechanisms
      // overlap, and because everything that reads the dispatcher rather than
      // MediaQuery still sees the view override.
      late MediaQueryData data;
      await tester.pumpWidget(_capture((MediaQueryData value) => data = value));

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(platformBrightness: ui.Brightness.dark),
      );
      await tester.pump();
      expect(data.platformBrightness, ui.Brightness.dark);

      debugBrightnessOverride = ui.Brightness.light;
      await tester.pumpWidget(
        _capture((MediaQueryData value) => data = value, child: const SizedBox()),
      );
      final ui.Brightness withBoth = data.platformBrightness;
      final ui.Brightness fromDispatcher = tester.binding.platformDispatcher.platformBrightness;

      debugBrightnessOverride = null;
      debugClearViewMetricsOverrides();

      expect(withBoth, ui.Brightness.light);
      expect(fromDispatcher, ui.Brightness.dark);
    });

    testWidgets('an override for another view leaves this one alone', (WidgetTester tester) async {
      late MediaQueryData data;
      await tester.pumpWidget(_capture((MediaQueryData value) => data = value));

      debugSetViewMetricsOverride(
        tester.view.viewId + 1,
        const DebugViewMetricsOverride(devicePixelRatio: 7.0, boldText: true),
      );
      await tester.pump();

      expect(data.devicePixelRatio, 3.0);
      expect(data.boldText, isFalse);
      debugClearViewMetricsOverrides();
    });

    testWidgets('view overrides selectively replace inherited platform data', (
      WidgetTester tester,
    ) async {
      late MediaQueryData data;
      final MediaQueryData inherited = MediaQueryData.fromView(tester.view).copyWith(
        textScaler: const TextScaler.linear(4.0),
        platformBrightness: ui.Brightness.light,
        alwaysUse24HourFormat: false,
        boldText: false,
        highContrast: true,
      );
      await tester.pumpWidget(
        MediaQuery(
          data: inherited,
          child: MediaQuery.fromView(
            view: tester.view,
            child: _capture((MediaQueryData value) => data = value),
          ),
        ),
      );

      expect(data.textScaler.scale(10), 40);
      expect(data.platformBrightness, ui.Brightness.light);
      expect(data.alwaysUse24HourFormat, isFalse);
      expect(data.boldText, isFalse);
      expect(data.highContrast, isTrue);

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(
          textScaleFactor: 2.0,
          platformBrightness: ui.Brightness.dark,
          alwaysUse24HourFormat: true,
          boldText: true,
        ),
      );
      await tester.pump();

      expect(data.textScaler.scale(10), 20);
      expect(data.platformBrightness, ui.Brightness.dark);
      expect(data.alwaysUse24HourFormat, isTrue);
      expect(data.boldText, isTrue);
      // The parent still supplies fields the view override does not name.
      expect(data.highContrast, isTrue);

      debugClearViewMetricsOverrides();
      await tester.pump();
      expect(data.textScaler.scale(10), 40);
      expect(data.platformBrightness, ui.Brightness.light);
      expect(data.alwaysUse24HourFormat, isFalse);
      expect(data.boldText, isFalse);
      expect(data.highContrast, isTrue);
    });

    testWidgets("a nested view resolves its own override, not the wrapped view's", (
      WidgetTester tester,
    ) async {
      // FakeView reports viewId 100 while wrapping the implicit view, which is
      // exactly the case where the override registered for a view and the
      // dispatcher that reports its metrics can disagree. The value a metric
      // takes has to come from the override registered for the id the view
      // reports.
      final nested = FakeView(tester.view);
      expect(nested.viewId, isNot(tester.view.viewId));

      late MediaQueryData data;
      final MediaQueryData inherited = MediaQueryData.fromView(
        tester.view,
      ).copyWith(textScaler: const TextScaler.linear(4.0), boldText: false, highContrast: true);
      await tester.pumpWidget(
        MediaQuery(
          data: inherited,
          child: MediaQuery.fromView(
            view: nested,
            child: _capture((MediaQueryData value) => data = value),
          ),
        ),
      );
      expect(data.textScaler.scale(10), 40);
      expect(data.boldText, isFalse);

      // An override on the nested view wins over the inherited data, and takes
      // the value that was registered for it.
      debugSetViewMetricsOverride(
        nested.viewId,
        const DebugViewMetricsOverride(textScaleFactor: 5.0, boldText: true),
      );
      await tester.pump();
      expect(data.textScaler.scale(10), 50);
      expect(data.boldText, isTrue);
      expect(data.highContrast, isTrue, reason: 'the parent still supplies unnamed metrics');
      debugClearViewMetricsOverrides();
      await tester.pump();

      // An override on the wrapped view must not reach the nested one.
      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(textScaleFactor: 7.0, boldText: true),
      );
      await tester.pump();
      expect(data.textScaler.scale(10), 40, reason: 'view ${tester.view.viewId} must not leak');
      expect(data.boldText, isFalse, reason: 'view ${tester.view.viewId} must not leak');
      expect(
        nested.platformDispatcher.textScaleFactor,
        1.0,
        reason: 'the nested view resolves its own id',
      );
      debugClearViewMetricsOverrides();
      await tester.pump();
    });

    testWidgets('an overridden metric takes its value from the override itself', (
      WidgetTester tester,
    ) async {
      // A FlutterView whose dispatcher resolves a different id than the view
      // reports. The overridden value has to come from the override registered
      // for the reported id, not from a dispatcher read, or the result would be
      // neither the override's value nor the inherited one.
      final unbound = _UnboundView(tester.view, tester.view.viewId + 999);
      final MediaQueryData inherited = MediaQueryData.fromView(
        tester.view,
      ).copyWith(textScaler: const TextScaler.linear(4.0), boldText: false, highContrast: true);

      debugSetViewMetricsOverride(
        unbound.viewId,
        const DebugViewMetricsOverride(textScaleFactor: 5.0, boldText: true),
      );
      final data = MediaQueryData.fromView(unbound, platformData: inherited);
      debugClearViewMetricsOverrides();

      expect(data.textScaler.scale(10), 50, reason: 'the override supplies the value');
      expect(data.boldText, isTrue, reason: 'the override supplies the value');
      expect(data.highContrast, isTrue, reason: 'the parent supplies unnamed metrics');
    });
  });

  group('every overridable metric MediaQuery surfaces', () {
    testWidgets('is honored over inherited platform data', (WidgetTester tester) async {
      // The table is the enumeration, checked against the class itself, so a
      // metric added to DebugViewMetricsOverride has to be classified rather
      // than silently never applying under a parent MediaQuery.
      expect(<String>{
        ..._surfacedMetrics.keys,
        ..._notSurfacedByMediaQuery,
      }, unorderedEquals(_allOverridableMetrics()));
      expect(tester.view.physicalSize, const Size(2400, 1800));
      expect(tester.view.devicePixelRatio, 3.0);

      late MediaQueryData data;
      // A parent that disagrees with every override in the table, so inheriting
      // from it instead of honoring the override is visible.
      final MediaQueryData parent = MediaQueryData.fromView(tester.view).copyWith(
        textScaler: const TextScaler.linear(9.0),
        platformBrightness: ui.Brightness.light,
        alwaysUse24HourFormat: false,
        accessibleNavigation: false,
        invertColors: false,
        disableAnimations: false,
        boldText: false,
        reduceMotion: false,
        highContrast: false,
        onOffSwitchLabels: false,
        supportsAnnounce: true,
      );
      await tester.pumpWidget(
        MediaQuery(
          data: parent,
          child: MediaQuery.fromView(
            view: tester.view,
            child: _capture((MediaQueryData value) => data = value),
          ),
        ),
      );

      for (final MapEntry<
            String,
            (DebugViewMetricsOverride, Object? Function(MediaQueryData), Object?)
          >
          entry
          in _surfacedMetrics.entries) {
        final (
          DebugViewMetricsOverride override,
          Object? Function(MediaQueryData) read,
          Object? expected,
        ) = entry.value;
        final Object? inherited = read(data);
        debugSetViewMetricsOverride(tester.view.viewId, override);
        await tester.pump();
        final Object? overridden = read(data);
        debugSetViewMetricsOverride(tester.view.viewId, null);
        await tester.pump();

        expect(overridden, expected, reason: '${entry.key} was not honored');
        expect(
          inherited,
          isNot(expected),
          reason:
              '${entry.key} would read the same without the override, so the '
              'test cannot tell whether it was honored',
        );
      }
      debugClearViewMetricsOverrides();
      await tester.pump();
    });
  });

  group('layout', () {
    testWidgets('the application relayouts at an overridden device pixel ratio', (
      WidgetTester tester,
    ) async {
      late MediaQueryData data;
      await tester.pumpWidget(
        _capture((MediaQueryData value) => data = value, child: const SizedBox.expand()),
      );
      expect(data.size, const Size(800, 600));
      expect(tester.getSize(find.byType(SizedBox)), const Size(800, 600));

      // 3.0 -> 7.0 rather than a power of two: 2400 / 7 does not divide evenly,
      // so a mismatch between the size MediaQuery reports and the size the tree
      // is laid out at cannot hide behind exact binary arithmetic.
      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(devicePixelRatio: 7.0),
      );
      await tester.pump();

      expect(data.devicePixelRatio, 7.0);
      expect(data.size, const Size(2400 / 7, 1800 / 7));
      expect(tester.binding.renderView.configuration.devicePixelRatio, 7.0);
      // The tree really laid out at the size MediaQuery reports, rather than
      // merely being told about it.
      expect(tester.getSize(find.byType(SizedBox)), data.size);

      debugClearViewMetricsOverrides();
      await tester.pump();
      expect(tester.getSize(find.byType(SizedBox)), const Size(800, 600));
      expect(data.size, const Size(800, 600));
    });

    testWidgets('the application relayouts at an overridden physical size', (
      WidgetTester tester,
    ) async {
      late MediaQueryData data;
      await tester.pumpWidget(
        _capture((MediaQueryData value) => data = value, child: const SizedBox.expand()),
      );

      debugSetViewMetricsOverride(
        tester.view.viewId,
        // A 1170x2532 device at 3x, which is not the 2400x1800 the test
        // environment reports.
        const DebugViewMetricsOverride(physicalSize: ui.Size(1170, 2532)),
      );
      await tester.pump();

      expect(data.size, const Size(390, 844));
      expect(tester.getSize(find.byType(SizedBox)), const Size(390, 844));

      debugClearViewMetricsOverrides();
      await tester.pump();
      expect(tester.getSize(find.byType(SizedBox)), const Size(800, 600));
    });

    testWidgets('an overridden size and ratio combine', (WidgetTester tester) async {
      late MediaQueryData data;
      await tester.pumpWidget(
        _capture((MediaQueryData value) => data = value, child: const SizedBox.expand()),
      );

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(physicalSize: ui.Size(1170, 2532), devicePixelRatio: 7.0),
      );
      await tester.pump();

      expect(data.size, const Size(1170 / 7, 2532 / 7));
      expect(tester.getSize(find.byType(SizedBox)), data.size);

      debugClearViewMetricsOverrides();
      await tester.pump();
    });
  });

  group('pointer conversion', () {
    testWidgets('pointers land on the widget they were aimed at', (WidgetTester tester) async {
      // WidgetTester's own gestures are already in logical pixels and bypass
      // PointerEventConverter, so this dispatches raw pointer data the way the
      // engine does.
      final tapped = <String>[];
      Widget listener(String name) {
        return Expanded(
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (PointerDownEvent event) => tapped.add(name),
          ),
        );
      }

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(devicePixelRatio: 6.0),
      );
      await tester.pumpWidget(
        Row(
          textDirection: TextDirection.ltr,
          children: <Widget>[listener('left'), listener('right')],
        ),
      );
      // The logical viewport is 2400/6 = 400 wide, so the two halves meet at
      // logical x = 200. Physical x = 900 is logical 150 at the overridden
      // ratio and logical 300 at the real ratio of 3.0, so a pointer converted
      // with the wrong ratio lands on the wrong half.
      expect(tester.getSize(find.byType(Listener).first).width, 200);

      tester.binding.platformDispatcher.onPointerDataPacket!(
        ui.PointerDataPacket(
          data: <ui.PointerData>[
            ui.PointerData(
              viewId: tester.view.viewId,
              change: ui.PointerChange.down,
              physicalX: 900,
              physicalY: 900,
            ),
            ui.PointerData(
              viewId: tester.view.viewId,
              change: ui.PointerChange.up,
              physicalX: 900,
              physicalY: 900,
            ),
          ],
        ),
      );
      await tester.pump();

      expect(tapped, <String>['left']);
      debugClearViewMetricsOverrides();
    });
  });

  group('accessibility evaluations', () {
    late Set<String> originalFeatureFlags;

    setUp(() {
      originalFeatureFlags = <String>{...debugEnabledFeatureFlags};
      debugEnabledFeatureFlags.add('accessibility_evaluations');
    });

    tearDown(() {
      debugEnabledFeatureFlags
        ..clear()
        ..addAll(originalFeatureFlags);
    });

    testWidgets('measure the overridden geometry', (WidgetTester tester) async {
      const evaluation = MinimumTapTargetEvaluation(size: Size(48.0, 48.0));
      // Disposed inside the test body rather than in a tear down: the test
      // framework checks for leaked semantics handles before tear downs run.
      final SemanticsHandle handle = tester.ensureSemantics();

      Widget build() {
        return TestWidgetsApp(
          home: Center(
            child: SizedBox.square(
              dimension: 40.0,
              child: Semantics(label: 'button', onTap: () {}),
            ),
          ),
        );
      }

      await tester.pumpWidget(build());
      expect((await evaluation.evaluate(tester.binding)).violations, hasLength(1));

      // A 40 logical pixel target is still 40 logical pixels when the device
      // pixel ratio changes, so the violation has to survive. It only
      // disappears if the evaluation divides physical bounds produced at one
      // ratio by a different one.
      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(devicePixelRatio: 6.0),
      );
      await tester.pump();
      final EvaluationResult overridden = await evaluation.evaluate(tester.binding);
      debugClearViewMetricsOverrides();
      handle.dispose();

      expect(overridden.violations, hasLength(1));
      expect(
        overridden.violations.first.reason,
        contains('expected tap target size of at least Size(48.0, 48.0)'),
      );
    });
  });

  group('image resolution', () {
    testWidgets('picks the asset variant for the overridden ratio', (WidgetTester tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            capturedContext = context;
            return const SizedBox.expand();
          },
        ),
      );
      expect(createLocalImageConfiguration(capturedContext).devicePixelRatio, 3.0);

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(devicePixelRatio: 1.0),
      );
      await tester.pump();
      final double ratio = createLocalImageConfiguration(capturedContext).devicePixelRatio!;
      debugClearViewMetricsOverrides();

      expect(ratio, 1.0);
    });
  });

  group('SemanticsBinding', () {
    testWidgets('re-reads its cached accessibility features', (WidgetTester tester) async {
      // SemanticsBinding caches AccessibilityFeatures and only refreshes it when
      // dart:ui reports a change, so this only works if installing an override
      // replays that notification.
      expect(SemanticsBinding.instance.accessibilityFeatures.boldText, isFalse);
      expect(SemanticsBinding.instance.disableAnimations, isFalse);

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(boldText: true, disableAnimations: true),
      );
      final bool boldText = SemanticsBinding.instance.accessibilityFeatures.boldText;
      final bool disableAnimations = SemanticsBinding.instance.disableAnimations;
      debugClearViewMetricsOverrides();

      expect(boldText, isTrue);
      expect(disableAnimations, isTrue);
      expect(SemanticsBinding.instance.accessibilityFeatures.boldText, isFalse);
    });
  });

  group('propagation', () {
    testWidgets('tells the framework only about what changed', (WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.expand());
      final recorder = _NotificationRecorder();
      tester.binding.addObserver(recorder);
      addTearDown(() => tester.binding.removeObserver(recorder));

      // An accessibility flag is not a change of window size.
      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(boldText: true),
      );
      expect(recorder.accessibilityFeatures, 1, reason: '$recorder');
      expect(recorder.metrics, 0, reason: '$recorder');
      expect(recorder.textScaleFactor, 0, reason: '$recorder');
      expect(recorder.platformBrightness, 0, reason: '$recorder');

      // ...nor is a text scale factor, or a brightness.
      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(boldText: true, textScaleFactor: 2.0),
      );
      expect(recorder.textScaleFactor, 1, reason: '$recorder');
      expect(recorder.accessibilityFeatures, 1, reason: '$recorder');
      expect(recorder.metrics, 0, reason: '$recorder');

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(
          boldText: true,
          textScaleFactor: 2.0,
          platformBrightness: ui.Brightness.dark,
        ),
      );
      expect(recorder.platformBrightness, 1, reason: '$recorder');
      expect(recorder.metrics, 0, reason: '$recorder');

      // A geometry change is.
      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(
          boldText: true,
          textScaleFactor: 2.0,
          platformBrightness: ui.Brightness.dark,
          devicePixelRatio: 4.0,
        ),
      );
      expect(recorder.metrics, 1, reason: '$recorder');
      expect(recorder.accessibilityFeatures, 1, reason: '$recorder');
      expect(recorder.textScaleFactor, 1, reason: '$recorder');
      expect(recorder.platformBrightness, 1, reason: '$recorder');

      // Setting the same override again changes nothing at all.
      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(
          boldText: true,
          textScaleFactor: 2.0,
          platformBrightness: ui.Brightness.dark,
          devicePixelRatio: 4.0,
        ),
      );
      expect(recorder.metrics, 1, reason: '$recorder');
      expect(recorder.accessibilityFeatures, 1, reason: '$recorder');

      // Clearing reverts every group that was overridden.
      debugClearViewMetricsOverrides();
      expect(recorder.metrics, 2, reason: '$recorder');
      expect(recorder.accessibilityFeatures, 2, reason: '$recorder');
      expect(recorder.textScaleFactor, 2, reason: '$recorder');
      expect(recorder.platformBrightness, 2, reason: '$recorder');

      await tester.pump();
    });

    testWidgets('schedules the frame that applies an overridden size', (WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.expand());
      expect(tester.binding.hasScheduledFrame, isFalse);

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(devicePixelRatio: 4.0),
      );
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pump();
      expect(tester.getSize(find.byType(SizedBox)), const Size(600, 450));

      debugClearViewMetricsOverrides();
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pump();
      expect(tester.getSize(find.byType(SizedBox)), const Size(800, 600));
    });
  });
}

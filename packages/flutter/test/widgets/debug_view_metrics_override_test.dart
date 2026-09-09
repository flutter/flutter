// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/src/foundation/_features.dart';
import 'package:flutter/src/widgets/_accessibility_evaluations.dart';
import 'package:flutter/src/widgets/_window.dart' show WindowController;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'multi_view_testing.dart';

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
  'systemGestureInsets': (
    const DebugViewMetricsOverride(systemGestureInsets: DebugViewPadding(bottom: 30)),
    (MediaQueryData data) => data.systemGestureInsets,
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

/// A [TextScaler] whose factor is not a number, which [TextScaler] permits:
/// [TextScaler.textScaleFactor] is documented as an estimate, with no range.
class _NaNTextScaler extends TextScaler {
  const _NaNTextScaler();
  @override
  double get textScaleFactor => double.nan;
  @override
  double scale(double fontSize) => fontSize;
}

/// The same, for a factor below the zero [TextScaler.linear] requires.
class _NegativeTextScaler extends TextScaler {
  const _NegativeTextScaler();
  @override
  double get textScaleFactor => -1.0;
  @override
  double scale(double fontSize) => fontSize;
}

void main() {
  // Construct this before testWidgets initializes the binding. Keeping the
  // fixture here lets the bootstrap regression share this test file.
  assert(BindingBase.debugBindingType() == null);
  final ui.FlutterView rawBeforeBinding = ui.PlatformDispatcher.instance.implicitView!;
  late ui.FlutterView inheritedBeforeBinding;
  final viewBeforeBinding = View(
    view: rawBeforeBinding,
    child: Builder(
      builder: (BuildContext context) {
        inheritedBeforeBinding = View.of(context);
        return const SizedBox.expand();
      },
    ),
  );
  isWindowingEnabled = true;
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
      final ui.Brightness initialBrightness = data.platformBrightness;
      final bool initialClockFormat = data.alwaysUse24HourFormat;
      final ui.Brightness overriddenBrightness = initialBrightness == ui.Brightness.light
          ? ui.Brightness.dark
          : ui.Brightness.light;

      debugSetViewMetricsOverride(
        tester.view.viewId,
        DebugViewMetricsOverride(
          platformBrightness: overriddenBrightness,
          alwaysUse24HourFormat: !initialClockFormat,
        ),
      );
      await tester.pump();

      expect(data.platformBrightness, overriddenBrightness);
      expect(data.alwaysUse24HourFormat, !initialClockFormat);

      debugClearViewMetricsOverrides();
      await tester.pump();
      expect(data.platformBrightness, initialBrightness);
      expect(data.alwaysUse24HourFormat, initialClockFormat);
    });

    testWidgets('reports overridden padding and insets in logical pixels', (
      WidgetTester tester,
    ) async {
      late MediaQueryData data;
      await tester.pumpWidget(_capture((MediaQueryData value) => data = value));
      expect(data.devicePixelRatio, 3.0);
      expect(data.padding, EdgeInsets.zero);
      expect(data.viewInsets, EdgeInsets.zero);
      expect(data.systemGestureInsets, EdgeInsets.zero);

      // The override is in physical pixels; MediaQuery reports logical ones.
      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(
          padding: DebugViewPadding(top: 141),
          viewPadding: DebugViewPadding(top: 141, bottom: 102),
          viewInsets: DebugViewPadding(bottom: 900),
          systemGestureInsets: DebugViewPadding(left: 60, right: 60),
        ),
      );
      await tester.pump();

      expect(data.padding, const EdgeInsets.only(top: 47));
      expect(data.viewPadding, const EdgeInsets.only(top: 47, bottom: 34));
      expect(data.viewInsets, const EdgeInsets.only(bottom: 300));
      expect(data.systemGestureInsets, const EdgeInsets.symmetric(horizontal: 20));

      debugClearViewMetricsOverrides();
      await tester.pump();
      expect(data.padding, EdgeInsets.zero);
      expect(data.systemGestureInsets, EdgeInsets.zero);
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

    testWidgets('renders into the same view its MediaQuery describes', (WidgetTester tester) async {
      // A view read straight from a wrapped dispatcher reports the metrics the
      // platform reports, while MediaQueryData.fromView resolves the override
      // through the wrapper. Handed to View unchanged, it would lay the render
      // tree out at one size while telling descendants another.
      final dispatcher = _RenderableViewPlatformDispatcher();
      final ui.PlatformDispatcher wrapped = debugApplyViewMetricsOverrides(dispatcher);
      final ui.FlutterView raw = dispatcher.rawView;
      expect(raw, isNot(same(wrapped.view(id: raw.viewId))));

      late MediaQueryData data;
      await tester.pumpWidget(
        wrapWithView: false,
        View(
          view: raw,
          child: Builder(
            builder: (BuildContext context) {
              data = MediaQuery.of(context);
              return const SizedBox.expand();
            },
          ),
        ),
      );

      // Looked up the way flutter_test looks it up — by identity against the
      // view the widget reports — because a widget whose `view` is not what it
      // renders into fails every such lookup, tester.tap's hit-test diagnostics
      // among them.
      final ui.FlutterView reported = tester.widget<View>(find.byType(View)).view;
      expect(reported, same(debugViewWithMetricsOverrides(raw)));
      RenderView renderViewFor(int id) => RendererBinding.instance.renderViews.firstWhere(
        (RenderView renderView) => renderView.flutterView == reported,
      );

      void expectRenderTreeAgrees(String when) {
        final RenderView renderView = renderViewFor(raw.viewId);
        expect(renderView.flutterView.devicePixelRatio, data.devicePixelRatio, reason: when);
        expect(
          renderView.flutterView.physicalSize,
          data.size * data.devicePixelRatio,
          reason: when,
        );
        expect(renderView.size, data.size, reason: when);
        expect(renderView.configuration.devicePixelRatio, data.devicePixelRatio, reason: when);
        renderView.compositeFrame();
        expect(
          (raw as _RenderableFakeView).lastRenderedSize,
          data.size * data.devicePixelRatio,
          reason: when,
        );
      }

      expect(data.size, const Size(400, 300));
      expectRenderTreeAgrees('with no override registered');

      debugSetViewMetricsOverride(
        raw.viewId,
        const DebugViewMetricsOverride(physicalSize: ui.Size(1200, 400), devicePixelRatio: 4.0),
      );
      await tester.pump();
      expect(data.size, const Size(300, 100), reason: 'the override reaches MediaQuery');
      expect(data.devicePixelRatio, 4.0);
      expectRenderTreeAgrees('with an override installed');

      debugClearViewMetricsOverrides();
      await tester.pump();
      expect(data.size, const Size(400, 300));
      expectRenderTreeAgrees('after the override was removed');
    });

    testWidgets('normalizes a view read directly from dart:ui throughout the tree', (
      WidgetTester tester,
    ) async {
      final ui.FlutterView raw = ui.PlatformDispatcher.instance.implicitView!;
      final ui.Size originalSize = raw.physicalSize;
      final double originalRatio = raw.devicePixelRatio;
      late MediaQueryData data;
      late ui.FlutterView inheritedView;
      await tester.pumpWidget(
        wrapWithView: false,
        View(
          view: raw,
          child: Builder(
            builder: (BuildContext context) {
              inheritedView = View.of(context);
              data = MediaQuery.of(context);
              return const SizedBox.expand();
            },
          ),
        ),
      );
      final RenderView renderView = tester.binding.renderViews.single;
      final stableView = inheritedView;
      void check(ui.Size physicalSize, double ratio) {
        expect(inheritedView, same(stableView));
        expect(tester.widget<View>(find.byType(View)).view, same(stableView));
        expect(tester.widget<RawView>(find.byType(RawView)).view, same(stableView));
        expect(renderView.flutterView, same(stableView));
        expect(renderView.configuration.devicePixelRatio, ratio);
        expect(renderView.configuration.physicalConstraints, BoxConstraints.tight(physicalSize));
        expect(
          renderView.configuration.logicalConstraints,
          BoxConstraints.tight(physicalSize / ratio),
        );
        expect(renderView.size, physicalSize / ratio);
        expect(renderView.configuration.toPhysicalSize(renderView.size), physicalSize);
        expect(data.size, physicalSize / ratio);
        expect(data.devicePixelRatio, ratio);
      }

      check(originalSize, originalRatio);
      debugSetViewMetricsOverride(
        raw.viewId,
        const DebugViewMetricsOverride(physicalSize: Size(1200, 400), devicePixelRatio: 4),
      );
      await tester.pump();
      check(const Size(1200, 400), 4);
      debugClearViewMetricsOverrides();
      await tester.pump();
      check(originalSize, originalRatio);
    });

    testWidgets('renders a bare RawView into the overridden view too', (WidgetTester tester) async {
      // RawView is public and used without a View, so it has to resolve the
      // view for itself rather than relying on the one View resolved.
      final dispatcher = _RenderableViewPlatformDispatcher();
      debugApplyViewMetricsOverrides(dispatcher);
      final ui.FlutterView raw = dispatcher.rawView;
      debugSetViewMetricsOverride(
        raw.viewId,
        const DebugViewMetricsOverride(physicalSize: ui.Size(1200, 400), devicePixelRatio: 4.0),
      );

      await tester.pumpWidget(
        wrapWithView: false,
        RawView(view: raw, child: const SizedBox.expand()),
      );

      final RenderView renderView = RendererBinding.instance.renderViews.firstWhere(
        (RenderView candidate) => candidate.flutterView.viewId == raw.viewId,
      );
      expect(renderView.flutterView.physicalSize, const ui.Size(1200, 400));
      expect(renderView.size, const Size(300, 100));
      // And the widget names the view it renders into, which is what looks a
      // RenderView up by identity.
      expect(tester.widget<RawView>(find.byType(RawView)).view, same(renderView.flutterView));

      debugClearViewMetricsOverrides();
    });

    testWidgets('a deprecated RenderView and its View share the normalized raw view', (
      WidgetTester tester,
    ) async {
      final dispatcher = _RenderableViewPlatformDispatcher();
      debugApplyViewMetricsOverrides(dispatcher);
      final ui.FlutterView raw = dispatcher.rawView;
      final renderView = RenderView(view: raw);
      addTearDown(renderView.dispose);
      final pipelineOwner = PipelineOwner();
      addTearDown(pipelineOwner.dispose);
      final widget = View(
        view: raw,
        deprecatedDoNotUseWillBeRemovedWithoutNoticePipelineOwner: pipelineOwner,
        deprecatedDoNotUseWillBeRemovedWithoutNoticeRenderView: renderView,
        child: const SizedBox.expand(),
      );
      expect(renderView.flutterView, same(widget.view));
      expect(widget.view, same(debugViewWithMetricsOverrides(raw)));
    });

    testWidgets('explicit test values outrank a debug override', (WidgetTester tester) async {
      // DebugViewMetricsOverride documents that a value set on a
      // TestPlatformDispatcher or TestFlutterView wins over an override, and
      // the dispatcher implements that by resolving the test value first.
      // MediaQuery has to agree with it, or the two report different platforms.
      tester.platformDispatcher.textScaleFactorTestValue = 4.0;
      tester.platformDispatcher.platformBrightnessTestValue = ui.Brightness.dark;
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        boldText: true,
      );
      tester.view.devicePixelRatio = 5.0;

      late MediaQueryData data;
      await tester.pumpWidget(_capture((MediaQueryData value) => data = value));

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(
          textScaleFactor: 3.0,
          platformBrightness: ui.Brightness.light,
          boldText: false,
          devicePixelRatio: 7.0,
        ),
      );
      await tester.pump();

      final ui.PlatformDispatcher dispatcher = tester.view.platformDispatcher;
      final double dispatcherTextScale = dispatcher.textScaleFactor;
      final ui.Brightness dispatcherBrightness = dispatcher.platformBrightness;
      final bool dispatcherBoldText = dispatcher.accessibilityFeatures.boldText;
      final double viewRatio = tester.view.devicePixelRatio;
      final reported = data;
      // SystemTextScaler asks the dispatcher at scale() time, so this has to be
      // evaluated before the test values are cleared.
      final double reportedTextScale = reported.textScaler.scale(10);

      debugClearViewMetricsOverrides();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      tester.view.resetDevicePixelRatio();
      await tester.pump();

      // The dispatcher and the view report the test values, not the override.
      expect(dispatcherTextScale, 4.0);
      expect(dispatcherBrightness, ui.Brightness.dark);
      expect(dispatcherBoldText, isTrue);
      expect(viewRatio, 5.0);
      // MediaQuery agrees with them.
      expect(reportedTextScale, 40.0);
      expect(reported.platformBrightness, ui.Brightness.dark);
      expect(reported.boldText, isTrue);
      expect(reported.devicePixelRatio, 5.0);
    });

    testWidgets('a view read straight from the platform applies its override', (
      WidgetTester tester,
    ) async {
      // MediaQueryData.fromView documents that its view may come from
      // PlatformDispatcher.views. Such a view applies no override itself, so
      // resolving one against it reported neither the override nor the
      // inherited value.
      final ui.FlutterView rawView = ui.PlatformDispatcher.instance.implicitView!;
      final MediaQueryData inherited = MediaQueryData.fromView(
        rawView,
      ).copyWith(boldText: false, highContrast: true);
      debugSetViewMetricsOverride(
        rawView.viewId,
        const DebugViewMetricsOverride(
          devicePixelRatio: 4.0,
          physicalSize: ui.Size(400, 800),
          boldText: true,
        ),
      );

      final data = MediaQueryData.fromView(rawView, platformData: inherited);
      expect(data.boldText, isTrue);
      // The view geometry the override sets reaches it too.
      expect(data.devicePixelRatio, 4.0);
      expect(data.size, const Size(100, 200));
      // What the override does not name still comes from the parent.
      expect(data.highContrast, isTrue);

      debugClearViewMetricsOverrides();
    });

    testWidgets('the deprecated window builds data that honors an override', (
      WidgetTester tester,
    ) async {
      // The window itself reports the platform's own metrics, as its
      // documentation says, but it stands for a view of the wrapped dispatcher,
      // so the data built from it resolves that view's override like any other.
      final ui.SingletonFlutterWindow window = ui.window;
      debugSetViewMetricsOverride(
        window.viewId,
        const DebugViewMetricsOverride(devicePixelRatio: 4.0, physicalSize: ui.Size(400, 800)),
      );

      expect(window.devicePixelRatio, isNot(4.0));
      final data = MediaQueryData.fromWindow(window);
      expect(data.devicePixelRatio, 4.0);
      expect(data.size, const Size(100, 200));

      debugClearViewMetricsOverrides();
    });

    testWidgets('an overridden factor of 1.0 still equals no scaling at all', (
      WidgetTester tester,
    ) async {
      // Both a reported and an overridden factor of 1.0 equal
      // TextScaler.noScaling, so they have to equal each other, or MediaQuery's
      // idea of text scaling is not even transitive. dart:ui returns the font
      // size unchanged at 1.0 rather than applying its curve, so they really do
      // scale alike.
      final TextScaler reported = MediaQueryData.fromView(tester.view).textScaler;
      expect(reported.textScaleFactor, 1.0);

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(textScaleFactor: 1.0),
      );
      final TextScaler overridden = MediaQueryData.fromView(tester.view).textScaler;

      expect(overridden.textScaleFactor, 1.0);
      expect(overridden == reported, isTrue);
      expect(reported == overridden, isTrue);
      expect(overridden == TextScaler.noScaling, isTrue);

      // TextScaler equality is not mutual across types — TextScaler.noScaling
      // does not accept a SystemTextScaler — so MediaQueryData compares those
      // by factor, which has to hold whichever way round they are asked.
      final fromView = MediaQueryData.fromView(tester.view);
      final MediaQueryData withNoScaling = fromView.copyWith(textScaler: TextScaler.noScaling);
      expect(fromView == withNoScaling, isTrue);
      expect(withNoScaling == fromView, isTrue);

      debugClearViewMetricsOverrides();
    });

    testWidgets('a view read straight from the platform keeps one identity', (
      WidgetTester tester,
    ) async {
      // The view a raw one is read through is built whether or not an override
      // is registered, so that it does not change identity under a RenderView
      // or a View as tooling installs and removes overrides.
      final ui.FlutterView rawView = ui.PlatformDispatcher.instance.implicitView!;
      final ui.FlutterView applied = debugViewWithMetricsOverrides(rawView);
      expect(applied.viewId, rawView.viewId);
      // A view that already applies its own override is its own answer.
      expect(debugViewWithMetricsOverrides(applied), same(applied));

      debugSetViewMetricsOverride(
        rawView.viewId,
        const DebugViewMetricsOverride(devicePixelRatio: 4.0),
      );
      expect(debugViewWithMetricsOverrides(rawView), same(applied));

      debugClearViewMetricsOverrides();
      expect(debugViewWithMetricsOverrides(rawView), same(applied));
    });

    testWidgets('an adapter reporting a different dispatcher does not claim its own override', (
      WidgetTester tester,
    ) async {
      final view = _DifferentDispatcherTestView(tester.view, tester.platformDispatcher);
      const inherited = MediaQueryData(textScaler: TextScaler.linear(4), highContrast: true);
      debugSetViewMetricsOverride(
        view.viewId,
        const DebugViewMetricsOverride(textScaleFactor: 3, highContrast: false),
      );
      final data = MediaQueryData.fromView(view, platformData: inherited);
      debugClearViewMetricsOverrides();
      expect(data.textScaler, same(inherited.textScaler));
      expect(data.highContrast, isTrue);
    });

    testWidgets('inherited platform data does not read unused dispatcher metrics', (
      WidgetTester tester,
    ) async {
      final ui.FlutterView view = _FakeView(_GeometryOnlyPlatformDispatcher());
      const inherited = MediaQueryData(
        textScaler: TextScaler.linear(4),
        platformBrightness: ui.Brightness.dark,
        highContrast: true,
        lineHeightScaleFactorOverride: 1,
        letterSpacingOverride: 2,
        wordSpacingOverride: 3,
        paragraphSpacingOverride: 4,
      );
      final data = MediaQueryData.fromView(view, platformData: inherited);
      expect(data.textScaler, same(inherited.textScaler));
      expect(data.platformBrightness, inherited.platformBrightness);
      expect(data.highContrast, inherited.highContrast);
    });

    testWidgets('inherited data also works with a geometry-only fake view', (
      WidgetTester tester,
    ) async {
      final view = _DispatcherlessView();
      const inherited = MediaQueryData(
        textScaler: TextScaler.linear(4),
        lineHeightScaleFactorOverride: 1,
        letterSpacingOverride: 2,
        wordSpacingOverride: 3,
        paragraphSpacingOverride: 4,
      );
      expect(
        MediaQueryData.fromView(view, platformData: inherited).textScaler,
        same(inherited.textScaler),
      );
      debugSetViewMetricsOverride(view.viewId, const DebugViewMetricsOverride(textScaleFactor: 3));
      final data = MediaQueryData.fromView(view, platformData: inherited);
      debugClearViewMetricsOverrides();
      expect(data.textScaler, same(inherited.textScaler));
    });

    testWidgets('public data constructors retain the overridden scaling strategy', (
      WidgetTester tester,
    ) async {
      final dispatcher = _CurvedTextScalingPlatformDispatcher();
      final ui.FlutterView view = debugApplyViewMetricsOverrides(dispatcher).implicitView!;
      final before = MediaQueryData.fromView(view);
      debugSetViewMetricsOverride(view.viewId, const DebugViewMetricsOverride(textScaleFactor: 2));
      final after = MediaQueryData.fromView(view);
      debugClearViewMetricsOverrides();
      expect(
        MediaQueryData(textScaler: before.textScaler),
        isNot(MediaQueryData(textScaler: after.textScaler)),
      );
      expect(
        MediaQueryData(textScaler: before.textScaler.clamp(maxScaleFactor: 3)),
        isNot(MediaQueryData(textScaler: after.textScaler.clamp(maxScaleFactor: 3))),
      );
      expect(
        after.textScaler.scale(10),
        20,
        reason: 'an overridden scaler retains its captured linear factor after removal',
      );
    });

    testWidgets('equality stays an equivalence across scaling strategies', (
      WidgetTester tester,
    ) async {
      // Three values that report the same text scale factor: one scaling by the
      // platform's own curve, one by a linear scaler of its own, and one by an
      // override that supplies the factor. However they are grouped, equality
      // has to be symmetric and transitive — MediaQueryData is a public value
      // type, and a Set or a Map of one answers by insertion order otherwise.
      final dispatcher = _CurvedTextScalingPlatformDispatcher();
      final ui.FlutterView view = debugApplyViewMetricsOverrides(dispatcher).implicitView!;

      final platform = MediaQueryData.fromView(view);
      final MediaQueryData linear = platform.copyWith(textScaler: const TextScaler.linear(2.0));
      debugSetViewMetricsOverride(
        view.viewId,
        const DebugViewMetricsOverride(textScaleFactor: 2.0),
      );
      final overridden = MediaQueryData.fromView(view);
      debugClearViewMetricsOverrides();

      expect(platform.textScaler.textScaleFactor, 2.0);
      expect(linear.textScaler.textScaleFactor, 2.0);
      expect(overridden.textScaler.textScaleFactor, 2.0);

      final values = <MediaQueryData>[
        platform,
        linear,
        overridden,
        platform.copyWith(textScaler: platform.textScaler.clamp(maxScaleFactor: 3)),
        overridden.copyWith(textScaler: overridden.textScaler.clamp(maxScaleFactor: 3)),
        MediaQueryData(textScaler: platform.textScaler),
        MediaQueryData(textScaler: overridden.textScaler),
        MediaQueryData(
          textScaler: overridden.textScaler.clamp(maxScaleFactor: 3).clamp(maxScaleFactor: 2.5),
        ),
        platform.copyWith(textScaler: const _CustomTextScaler()),
      ];
      for (final x in values) {
        expect(x == x, isTrue, reason: 'equality is not reflexive');
        for (final y in values) {
          expect(x == y, y == x, reason: 'equality is not symmetric');
          for (final z in values) {
            if (x == y && y == z) {
              expect(x == z, isTrue, reason: 'equality is not transitive');
            }
          }
        }
      }

      // The classes: the override's factor is applied as a multiplication, so
      // it scales unlike the platform's curve, and the data built from it has
      // to compare unequal to the data built before it was installed.
      expect(platform == overridden, isFalse);
      expect(linear == overridden, isFalse);
      // What a caller set for itself is compared as it always was.
      expect(platform == linear, isTrue);
      // Hash codes stay consistent with all of it, including the pair that is
      // equal despite disagreeing about where its scaler came from: at a factor
      // of 1.0 there is nothing for an override to have changed, and a value
      // that hashed that disagreement would break equal-hashes-alike.
      expect(platform.hashCode, linear.hashCode);
      debugSetViewMetricsOverride(
        view.viewId,
        const DebugViewMetricsOverride(textScaleFactor: 1.0),
      );
      final unscaledOverride = MediaQueryData.fromView(view);
      debugClearViewMetricsOverrides();
      final MediaQueryData unscaledPlatform = platform.copyWith(textScaler: TextScaler.noScaling);
      expect(unscaledOverride.textScaler.textScaleFactor, 1.0);
      expect(unscaledOverride == unscaledPlatform, isTrue);
      expect(unscaledPlatform == unscaledOverride, isTrue);
      expect(unscaledOverride.hashCode, unscaledPlatform.hashCode);
      // The scaler owes the same promise, for the same reason: it makes the
      // same exemption at a factor of 1.0.
      expect(unscaledOverride.textScaler == unscaledPlatform.textScaler, isTrue);
      expect(unscaledOverride.textScaler.hashCode, unscaledPlatform.textScaler.hashCode);
    });

    testWidgets('equality tolerates a scaler that reports a factor it cannot have', (
      WidgetTester tester,
    ) async {
      // TextScaler is public and subclassable, and textScaleFactor is only
      // documented as an estimate. Asking whether such a scaler is a linear one
      // must not be what builds a TextScaler.linear out of the answer, because
      // that asserts on a factor like this.
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(textScaleFactor: 2.0),
      );
      final overridden = MediaQueryData.fromView(tester.view);
      debugClearViewMetricsOverrides();

      for (final scaler in const <TextScaler>[_NaNTextScaler(), _NegativeTextScaler()]) {
        expect(() => overridden.copyWith(textScaler: scaler), returnsNormally);
      }
    });

    testWidgets('carries what supplied the scaler through every copy of the data', (
      WidgetTester tester,
    ) async {
      // The override reports the factor the platform already reports, so
      // nothing but where the scaler came from tells two of these apart — and
      // a copy of the data holds a scaler that came from the same place.
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final ui.FlutterView nested = FakeView(tester.view);
      MediaQueryData styled(MediaQueryData data) => data.applyTextStyleOverrides(
        lineHeightScaleFactorOverride: null,
        letterSpacingOverride: null,
        wordSpacingOverride: null,
        paragraphSpacingOverride: null,
      );

      final reported = MediaQueryData.fromView(tester.view);
      final inheritedFromReported = MediaQueryData.fromView(nested, platformData: reported);
      final MediaQueryData styledFromReported = styled(reported);
      final MediaQueryData radiiFromReported = reported.applyDisplayCornerRadii(null);

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(textScaleFactor: 2.0),
      );
      final overridden = MediaQueryData.fromView(tester.view);
      debugClearViewMetricsOverrides();

      expect(overridden.textScaler.textScaleFactor, reported.textScaler.textScaleFactor);
      expect(overridden == reported, isFalse);
      // A view with no override of its own takes the scaler an ancestor
      // supplied, so it takes what that scaler is as well.
      expect(
        MediaQueryData.fromView(nested, platformData: overridden) == inheritedFromReported,
        isFalse,
      );
      // So does every copy, whichever method made it.
      expect(styled(overridden) == styledFromReported, isFalse);
      expect(overridden.applyDisplayCornerRadii(null) == radiiFromReported, isFalse);
      expect(
        overridden.copyWith(devicePixelRatio: 3.0) == reported.copyWith(devicePixelRatio: 3.0),
        isFalse,
      );
      // Except a copy whose scaler was replaced by one that scales by its
      // factor and nothing else: there is nothing left for an override to have
      // changed about it. The factor is not 1.0, so it is the replacement and
      // not the factor that makes these two equal.
      expect(
        overridden.copyWith(textScaler: const TextScaler.linear(3.0)) ==
            reported.copyWith(textScaler: const TextScaler.linear(3.0)),
        isTrue,
      );
      // A copy that replaces nothing is equal to what it copied, whatever the
      // two disagree about — including data a caller built for itself around a
      // scaler an override supplied, which the const constructor cannot ask
      // about and so records as not overridden.
      expect(overridden.copyWith() == overridden, isTrue);
      expect(reported.copyWith() == reported, isTrue);
      final built = MediaQueryData(textScaler: overridden.textScaler);
      expect(built.copyWith() == built, isTrue);
      expect(
        built.copyWith(devicePixelRatio: 3.0) == built.copyWith(devicePixelRatio: 3.0),
        isTrue,
      );
      // Handing back the scaler it already holds is keeping it too, which is
      // what MediaQuery.withClampedTextScaling does at its default bounds:
      // TextScaler.clamp returns the scaler it was asked to clamp.
      expect(built.copyWith(textScaler: built.textScaler) == built, isTrue);
      expect(built.copyWith(textScaler: built.textScaler.clamp()) == built, isTrue);
      // A scaler a caller built out of this data's own keeps this data's
      // answer, which is what the clamped scaler
      // MediaQuery.withClampedTextScaling installs is.
      expect(
        overridden.copyWith(textScaler: overridden.textScaler.clamp(maxScaleFactor: 1.5)) ==
            reported.copyWith(textScaler: reported.textScaler.clamp(maxScaleFactor: 1.5)),
        isFalse,
      );
      // And a copy handed the scaler of data that was built over an override
      // takes that answer from the scaler, rather than from the data it is
      // copying: the scaler is what does the scaling.
      expect(reported.copyWith(textScaler: overridden.textScaler) == reported, isFalse);
      expect(
        overridden.copyWith(textScaler: reported.textScaler) == reported,
        isTrue,
        reason: "a platform scaler copied onto overridden data is still the platform's",
      );
      // A metric that is not the text scale factor says nothing about how text
      // scales, so it must not make two of these differ. Compared against the
      // data itself rather than a copy of it, because a copy asks the scaler
      // and would answer correctly however this data was built.
      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(boldText: true),
      );
      final boldOnly = MediaQueryData.fromView(tester.view);
      debugClearViewMetricsOverrides();
      expect(boldOnly == reported.copyWith(boldText: true), isTrue);
    });

    testWidgets('says so when it prints data whose scaler an override supplied', (
      WidgetTester tester,
    ) async {
      // Two values that compare unequal have to print differently, or a
      // diagnostic dump of the rebuild this causes shows nothing that changed.
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final reported = MediaQueryData.fromView(tester.view);

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(textScaleFactor: 2.0),
      );
      final overridden = MediaQueryData.fromView(tester.view);
      debugClearViewMetricsOverrides();

      expect(overridden == reported, isFalse);
      // On the scaler, which is the thing the override changed, and nowhere
      // else: a marker on another property would say the wrong thing changed.
      expect(overridden.toString(), contains('textScaler: ${overridden.textScaler} (overridden)'));
      expect(reported.toString(), contains('textScaler: ${reported.textScaler},'));
      expect(reported.toString(), isNot(contains('(overridden)')));
      expect(
        overridden.toString().replaceAll(' (overridden)', ''),
        reported.toString(),
        reason: 'nothing but where the scaler came from should differ',
      );
    });

    testWidgets('rebuilds when an override changes how text scales, not by how much', (
      WidgetTester tester,
    ) async {
      // A platform whose own curve is not a multiplication by the factor it
      // reports: installing an override of that same factor leaves the factor
      // alone and replaces the curve, which widgets that scale text have to be
      // told about.
      final dispatcher = _CurvedTextScalingPlatformDispatcher();
      final ui.FlutterView view = debugApplyViewMetricsOverrides(dispatcher).implicitView!;
      var builds = 0;
      late MediaQueryData data;
      await tester.pumpWidget(
        MediaQuery(
          // The platform data an ancestor would supply, taken from the same
          // platform, so that the only thing the override changes below is how
          // the factor both of them report is applied.
          data: MediaQueryData.fromView(view),
          child: MediaQuery.fromView(
            view: view,
            child: Builder(
              builder: (BuildContext context) {
                builds += 1;
                data = MediaQuery.of(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      expect(data.textScaler.textScaleFactor, 2.0);
      expect(data.textScaler.scale(10), 25.0);
      final buildsBeforeOverride = builds;

      debugSetViewMetricsOverride(
        view.viewId,
        const DebugViewMetricsOverride(textScaleFactor: 2.0),
      );
      await tester.pump();

      expect(builds, buildsBeforeOverride + 1);
      expect(data.textScaler.textScaleFactor, 2.0);
      expect(data.textScaler.scale(10), 20.0);

      // A change to another view is not a change to this one. The comparison
      // has to be able to say "the same" as well, or every notification the
      // framework replays rebuilds everything that reads a MediaQuery.
      final buildsBeforeOtherView = builds;
      debugSetViewMetricsOverride(
        view.viewId + 1,
        const DebugViewMetricsOverride(textScaleFactor: 4.0),
      );
      await tester.pump();

      expect(builds, buildsBeforeOtherView);

      debugClearViewMetricsOverrides();
      await tester.pump();

      expect(builds, buildsBeforeOverride + 2);
      expect(data.textScaler.scale(10), 25.0);
    });

    testWidgets('rebuilds through a scaler that wraps the one that changed', (
      WidgetTester tester,
    ) async {
      // MediaQuery.withClampedTextScaling hands its subtree a TextScaler that
      // wraps this one, and the material and cupertino libraries put it above a
      // great deal of text. What it wraps has to keep deciding whether the
      // subtree rebuilds.
      final dispatcher = _CurvedTextScalingPlatformDispatcher();
      final ui.FlutterView view = debugApplyViewMetricsOverrides(dispatcher).implicitView!;
      var builds = 0;
      late TextScaler scaler;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData.fromView(view),
          child: MediaQuery.fromView(
            view: view,
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 3.0,
              child: Builder(
                builder: (BuildContext context) {
                  builds += 1;
                  scaler = MediaQuery.textScalerOf(context);
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      );
      expect(scaler.scale(10), 25.0);
      final buildsBeforeOverride = builds;

      debugSetViewMetricsOverride(
        view.viewId,
        const DebugViewMetricsOverride(textScaleFactor: 2.0),
      );
      await tester.pump();

      expect(builds, buildsBeforeOverride + 1);
      expect(scaler.scale(10), 20.0);

      debugClearViewMetricsOverrides();
      await tester.pump();

      expect(scaler.scale(10), 25.0);
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

  group('disableAnimations', () {
    testWidgets('reaches MediaQuery per view but AnimationController process-wide', (
      WidgetTester tester,
    ) async {
      // AnimationBehavior.normal shortens a controller's duration according to
      // SemanticsBinding.disableAnimations, which the binding caches from its
      // own dispatcher and which therefore resolves the implicit view's
      // override however many views there are. This pins that boundary: it is
      // the documented limit of the per-view contract, not an accident.
      final secondary = FakeView(tester.view);
      expect(secondary.viewId, isNot(tester.view.viewId));

      final controller = AnimationController(vsync: tester, duration: const Duration(seconds: 1));
      addTearDown(controller.dispose);

      // A one second animation is scaled to 50ms when animations are disabled,
      // so whether it has finished after 100ms says which value was used.
      Future<bool> finishesShortened() async {
        controller.value = 0.0;
        controller.forward();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final bool finished = controller.isCompleted;
        controller.stop();
        return finished;
      }

      expect(SemanticsBinding.instance.disableAnimations, isFalse);
      expect(await finishesShortened(), isFalse);

      // The implicit view's override reaches the binding, so it shortens
      // controllers belonging to every view.
      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(disableAnimations: true),
      );
      final bool bindingFromImplicit = SemanticsBinding.instance.disableAnimations;
      final bool shortenedByImplicit = await finishesShortened();
      debugClearViewMetricsOverrides();

      // A secondary view's override does not, even though that view and its
      // MediaQuery both report animations as disabled.
      debugSetViewMetricsOverride(
        secondary.viewId,
        const DebugViewMetricsOverride(disableAnimations: true),
      );
      final bool bindingFromSecondary = SemanticsBinding.instance.disableAnimations;
      final bool shortenedBySecondary = await finishesShortened();
      final bool secondaryReports =
          secondary.platformDispatcher.accessibilityFeatures.disableAnimations;
      late MediaQueryData secondaryData;
      await tester.pumpWidget(
        MediaQuery.fromView(
          view: secondary,
          child: _capture((MediaQueryData value) => secondaryData = value),
        ),
      );
      final bool secondaryMediaQuery = secondaryData.disableAnimations;
      debugClearViewMetricsOverrides();
      await tester.pump();

      expect(bindingFromImplicit, isTrue);
      expect(shortenedByImplicit, isTrue, reason: 'the implicit view shortens every controller');
      expect(bindingFromSecondary, isFalse);
      expect(
        shortenedBySecondary,
        isFalse,
        reason: 'a secondary view does not shorten any controller',
      );
      expect(secondaryReports, isTrue, reason: 'the view itself does report it');
      expect(secondaryMediaQuery, isTrue, reason: 'and so does its MediaQuery');
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

  testWidgets('a View constructed before the binding keeps one normalized identity', (
    WidgetTester tester,
  ) async {
    expect(viewBeforeBinding.view, isNot(same(rawBeforeBinding)));
    await tester.pumpWidget(viewBeforeBinding, wrapWithView: false);
    expect(inheritedBeforeBinding, same(viewBeforeBinding.view));
    expect(tester.binding.renderViews.single.flutterView, same(viewBeforeBinding.view));
    debugSetViewMetricsOverride(
      rawBeforeBinding.viewId,
      const DebugViewMetricsOverride(physicalSize: Size(800, 400), devicePixelRatio: 4),
    );
    await tester.pump();
    final Size size = tester.binding.renderViews.single.size;
    debugClearViewMetricsOverrides();
    await tester.pump();
    expect(inheritedBeforeBinding, same(viewBeforeBinding.view));
    expect(size, const Size(200, 100));
  });

  testWidgets(
    'TestFlutterView.platformDispatcher getter returns identical instance and is idempotent',
    (WidgetTester tester) async {
      final TestFlutterView view = tester.view;
      final TestPlatformDispatcher first = view.platformDispatcher;
      final TestPlatformDispatcher second = view.platformDispatcher;
      expect(identical(first, second), isTrue);
      expect(debugViewMetricsOverrideApplied(view), isNull);
      debugSetViewMetricsOverride(
        view.viewId,
        const DebugViewMetricsOverride(textScaleFactor: 2.0),
      );
      expect(debugViewMetricsOverrideApplied(view), isNotNull);
      debugClearViewMetricsOverrides();
    },
  );

  group('windowing', () {
    testWidgets('secondary windows apply their own geometry and platform overrides', (
      WidgetTester tester,
    ) async {
      final first = WindowController(size: const Size(400, 300));
      final second = WindowController(size: const Size(500, 200));
      addTearDown(first.destroy);
      addTearDown(second.destroy);
      final views = <ui.FlutterView>[first.rootView, second.rootView];
      final List<ui.Size> before = views.map((ui.FlutterView view) => view.physicalSize).toList();
      const inherited = MediaQueryData(
        textScaler: TextScaler.linear(4),
        platformBrightness: ui.Brightness.dark,
        highContrast: true,
      );
      final data = <int, MediaQueryData>{};
      await tester.pumpWidget(
        wrapWithView: false,
        ViewCollection(
          views: <Widget>[
            for (final ui.FlutterView view in views)
              MediaQuery(
                data: inherited,
                child: View(
                  view: view,
                  child: Builder(
                    builder: (BuildContext context) {
                      data[view.viewId] = MediaQuery.of(context);
                      return const SizedBox.expand();
                    },
                  ),
                ),
              ),
          ],
        ),
      );
      debugSetViewMetricsOverride(
        views.first.viewId,
        const DebugViewMetricsOverride(
          physicalSize: Size(1200, 400),
          devicePixelRatio: 4,
          textScaleFactor: 3,
          platformBrightness: ui.Brightness.light,
          highContrast: false,
        ),
      );
      await tester.pump();
      final MediaQueryData applied = data[views.first.viewId]!;
      final MediaQueryData untouched = data[views.last.viewId]!;
      final ui.Size geometry = views.first.physicalSize;
      final double factor = views.first.platformDispatcher.textScaleFactor;
      debugClearViewMetricsOverrides();
      await tester.pump();
      expect(geometry, const Size(1200, 400));
      expect(factor, 3);
      expect(applied.size, const Size(300, 100));
      expect(applied.devicePixelRatio, 4);
      expect(applied.textScaler.textScaleFactor, 3);
      expect(applied.platformBrightness, ui.Brightness.light);
      expect(applied.highContrast, isFalse);
      expect(untouched.textScaler.textScaleFactor, 4);
      expect(untouched.platformBrightness, ui.Brightness.dark);
      expect(untouched.highContrast, isTrue);
      for (var i = 0; i < views.length; i++) {
        expect(views[i].physicalSize, before[i]);
        expect(data[views[i].viewId]!.textScaler.textScaleFactor, 4);
        expect(data[views[i].viewId]!.highContrast, isTrue);
      }
    });

    testWidgets('secondary window test values retain precedence over debug overrides', (
      WidgetTester tester,
    ) async {
      final controller = WindowController(size: const Size(400, 300));
      addTearDown(controller.destroy);
      final view = controller.rootView as TestFlutterView;
      view.physicalSize = const Size(900, 600);
      view.devicePixelRatio = 6;
      tester.platformDispatcher.textScaleFactorTestValue = 5;
      addTearDown(view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      debugSetViewMetricsOverride(
        view.viewId,
        const DebugViewMetricsOverride(
          physicalSize: Size(1200, 400),
          devicePixelRatio: 4,
          textScaleFactor: 3,
        ),
      );
      final data = MediaQueryData.fromView(
        view,
        platformData: const MediaQueryData(textScaler: TextScaler.linear(7)),
      );
      debugClearViewMetricsOverrides();
      expect(view.physicalSize, const Size(900, 600));
      expect(view.devicePixelRatio, 6);
      expect(data.size, const Size(150, 100));
      expect(data.textScaler.scale(10), 50);
    });

    testWidgets('a custom view that resolves no override reports what it inherits', (
      WidgetTester tester,
    ) async {
      // A custom adapter can report geometry from one view and a dispatcher
      // belonging to another. Its own registry entry is not thereby applied.
      //
      // Crediting it with that entry would make MediaQueryData.fromView supersede
      // the platform data an ancestor supplies with values read from a view and a
      // dispatcher that never had the override applied, so the data would carry
      // neither the override nor what the ancestor supplied.
      final controller = WindowController(size: const Size(400, 300));
      addTearDown(controller.destroy);
      final ui.FlutterView window = _UnwrappedView(
        controller.rootView,
        tester.view.platformDispatcher,
      );
      expect(window.viewId, isNot(tester.view.viewId));

      // Choose inherited values that differ from this platform's settings.
      final ui.Brightness inheritedBrightness =
          tester.platformDispatcher.platformBrightness == ui.Brightness.light
          ? ui.Brightness.dark
          : ui.Brightness.light;
      final bool inheritedContrast = !tester.platformDispatcher.accessibilityFeatures.highContrast;
      final MediaQueryData inherited = MediaQueryData.fromView(
        tester.view,
      ).copyWith(platformBrightness: inheritedBrightness, highContrast: inheritedContrast);
      expect(inherited.platformBrightness, isNot(tester.platformDispatcher.platformBrightness));

      late MediaQueryData data;
      await tester.pumpWidget(
        MediaQuery(
          data: inherited,
          child: MediaQuery.fromView(
            view: window,
            child: Builder(
              builder: (BuildContext context) {
                data = MediaQuery.of(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );

      void expectInheritedValuesAndItsOwnGeometry(MediaQueryData data, String when) {
        // The platform-wide values are the ones the ancestor supplied.
        expect(data.platformBrightness, inheritedBrightness, reason: when);
        expect(data.highContrast, inheritedContrast, reason: when);
        // The geometry is this view's own, which is what it reports.
        expect(data.size, window.physicalSize / window.devicePixelRatio, reason: when);
        expect(data.devicePixelRatio, window.devicePixelRatio, reason: when);
      }

      expectInheritedValuesAndItsOwnGeometry(data, 'with no override registered');

      // Registering one for the id it reports changes nothing, because this is
      // not a view that applies it.
      debugSetViewMetricsOverride(
        window.viewId,
        DebugViewMetricsOverride(
          platformBrightness: tester.platformDispatcher.platformBrightness,
          highContrast: !inheritedContrast,
          physicalSize: const ui.Size(1234, 5678),
          devicePixelRatio: 7.0,
        ),
      );
      await tester.pump();
      // Snapshotted and the registry cleared before asserting, because a failure
      // that leaves an override installed is reported as a leak from the binding's
      // invariant check instead of as this test failing.
      expectInheritedValuesAndItsOwnGeometry(data, 'with an override it cannot apply');
      debugClearViewMetricsOverrides();

      await tester.pump();
      expectInheritedValuesAndItsOwnGeometry(data, 'after the override was removed');
    });

    testWidgets('a custom view that resolves no override keeps its inherited brightness', (
      WidgetTester tester,
    ) async {
      // MediaQuery.fromView replaces the brightness with debugBrightnessOverride
      // when the value came from the PlatformDispatcher rather than from a
      // parent, and a per-view override is one way of making that true. An entry
      // registered for a view that resolves nothing does not make it true, so
      // acting on the entry alone would drop what the parent supplied in favour
      // of a value nothing asked for.
      debugBrightnessOverride = ui.Brightness.light;
      final controller = WindowController(size: const Size(400, 300));
      addTearDown(controller.destroy);
      final ui.FlutterView window = _UnwrappedView(
        controller.rootView,
        tester.view.platformDispatcher,
      );

      late MediaQueryData data;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData.fromView(
            tester.view,
          ).copyWith(platformBrightness: ui.Brightness.dark),
          child: MediaQuery.fromView(
            view: window,
            child: Builder(
              builder: (BuildContext context) {
                data = MediaQuery.of(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      expect(data.platformBrightness, ui.Brightness.dark);

      // Installed while the tree is up, so this also covers the state noticing an
      // override that leaves the data it computes unchanged.
      debugSetViewMetricsOverride(
        window.viewId,
        const DebugViewMetricsOverride(platformBrightness: ui.Brightness.dark),
      );
      await tester.pump();
      final ui.Brightness afterInstalling = data.platformBrightness;
      debugClearViewMetricsOverrides();
      debugBrightnessOverride = null;
      await tester.pump();

      expect(
        afterInstalling,
        ui.Brightness.dark,
        reason: 'the parent supplies it, so debugBrightnessOverride does not replace it',
      );
      expect(data.platformBrightness, ui.Brightness.dark);
    });

    testWidgets('a window whose view does apply one takes debugBrightnessOverride', (
      WidgetTester tester,
    ) async {
      // The other direction: the implicit view does apply its own entry, so an
      // override of its brightness is what supersedes the parent — and that is
      // what lets debugBrightnessOverride replace it.
      debugBrightnessOverride = ui.Brightness.light;

      late MediaQueryData data;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData.fromView(
            tester.view,
          ).copyWith(platformBrightness: ui.Brightness.dark),
          child: MediaQuery.fromView(
            view: tester.view,
            child: Builder(
              builder: (BuildContext context) {
                data = MediaQuery.of(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      expect(data.platformBrightness, ui.Brightness.dark, reason: 'the parent supplies it');

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(platformBrightness: ui.Brightness.dark),
      );
      await tester.pump();
      final ui.Brightness afterInstalling = data.platformBrightness;
      debugClearViewMetricsOverrides();
      debugBrightnessOverride = null;
      await tester.pump();

      expect(
        afterInstalling,
        ui.Brightness.light,
        reason: 'the override supersedes the parent, so the debug brightness applies',
      );
      expect(data.platformBrightness, ui.Brightness.dark, reason: 'and is undone with it');
    });
  });
}

/// A [ui.PlatformDispatcher] that scales font sizes the way a platform does:
/// along a curve of its own rather than by the factor it reports.
///
/// The curve below is affine rather than piecewise, which is enough: what
/// matters is that it is not a multiplication by [textScaleFactor], so that
/// overriding the factor with the one already reported still changes how text
/// is scaled.
class _CurvedTextScalingPlatformDispatcher implements ui.PlatformDispatcher {
  late final _FakeView _view = _createView();

  /// The view this dispatcher reports, for a subclass that needs a different
  /// one; a field a subclass overrode would be two fields.
  _FakeView _createView() => _FakeView(this);

  @override
  Iterable<ui.FlutterView> get views => <ui.FlutterView>[_view];

  @override
  ui.FlutterView? view({required int id}) => id == _view.viewId ? _view : null;

  @override
  ui.FlutterView? get implicitView => _view;

  @override
  double get textScaleFactor => 2.0;

  @override
  double scaleFontSize(double unscaledFontSize) => unscaledFontSize * 2.0 + 5.0;

  @override
  ui.AccessibilityFeatures get accessibilityFeatures =>
      ui.PlatformDispatcher.instance.accessibilityFeatures;

  @override
  ui.Brightness get platformBrightness => ui.Brightness.light;

  @override
  bool get alwaysUse24HourFormat => false;

  @override
  bool get supportsShowingSystemContextMenu => false;

  @override
  double? get letterSpacingOverride => null;

  @override
  double? get lineHeightScaleFactorOverride => null;

  @override
  double? get paragraphSpacingOverride => null;

  @override
  double? get wordSpacingOverride => null;

  @override
  ui.VoidCallback? onAccessibilityFeaturesChanged;

  @override
  ui.VoidCallback? onMetricsChanged;

  @override
  ui.VoidCallback? onPlatformBrightnessChanged;

  @override
  ui.VoidCallback? onPlatformConfigurationChanged;

  @override
  ui.VoidCallback? onTextScaleFactorChanged;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not needed by these tests.');
}

/// A [ui.FlutterView] with an id no other view in these tests reports — not the
/// test view's 0, and not the 100 that `FakeView` reports — so that an override
/// registered for it cannot reach anything else.
class _FakeView implements ui.FlutterView {
  _FakeView(this.platformDispatcher);

  @override
  final ui.PlatformDispatcher platformDispatcher;

  @override
  int get viewId => 200;

  @override
  double get devicePixelRatio => 2.0;

  @override
  ui.Size get physicalSize => const ui.Size(800, 600);

  @override
  ui.ViewConstraints get physicalConstraints => ui.ViewConstraints.tight(physicalSize);

  @override
  ui.ViewPadding get padding => ui.ViewPadding.zero;

  @override
  ui.ViewPadding get viewInsets => ui.ViewPadding.zero;

  @override
  ui.ViewPadding get viewPadding => ui.ViewPadding.zero;

  @override
  ui.ViewPadding get systemGestureInsets => ui.ViewPadding.zero;

  @override
  ui.GestureSettings get gestureSettings => const ui.GestureSettings();

  @override
  List<ui.DisplayFeature> get displayFeatures => const <ui.DisplayFeature>[];

  @override
  ui.DisplayCornerRadii? get displayCornerRadii => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not needed by these tests.');
}

/// A [_FakeView] a render tree can actually be attached to, for the test that
/// checks what a [View] renders into against what its [MediaQuery] describes.
class _RenderableFakeView extends _FakeView {
  _RenderableFakeView(super.platformDispatcher);

  @override
  ui.Display get display => ui.PlatformDispatcher.instance.displays.first;

  @override
  void render(ui.Scene scene, {ui.Size? size}) {
    lastRenderedSize = size;
  }

  ui.Size? lastRenderedSize;

  @override
  void updateSemantics(ui.SemanticsUpdate update) {}
}

/// A dispatcher whose view can be read either raw or through the wrapper, which
/// is the difference the [View]/[RawView] boundary has to erase.
class _RenderableViewPlatformDispatcher extends _CurvedTextScalingPlatformDispatcher {
  @override
  _FakeView _createView() => _RenderableFakeView(this);

  /// The view as the platform reports it, which is what a caller reading
  /// [ui.PlatformDispatcher.views] directly gets.
  ui.FlutterView get rawView => _view;
}

class _CustomTextScaler extends TextScaler {
  const _CustomTextScaler();
  @override
  double get textScaleFactor => 2;
  @override
  double scale(double fontSize) => fontSize * 2 + 1;
}

class _GeometryOnlyPlatformDispatcher implements ui.PlatformDispatcher {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected ${invocation.memberName}');
}

class _DifferentDispatcherTestView extends TestFlutterView {
  _DifferentDispatcherTestView(TestFlutterView view, this.otherDispatcher)
    : super(view: view, platformDispatcher: view.platformDispatcher, display: view.display);

  final TestPlatformDispatcher otherDispatcher;
  @override
  int get viewId => 9876;
  @override
  TestPlatformDispatcher get platformDispatcher {
    super.platformDispatcher; // Registers the superclass's own dispatcher.
    return otherDispatcher;
  }
}

class _DispatcherlessView extends _FakeView {
  _DispatcherlessView() : super(_GeometryOnlyPlatformDispatcher());

  @override
  ui.PlatformDispatcher get platformDispatcher => throw UnimplementedError('geometry only');
}

class _UnwrappedView implements ui.FlutterView {
  _UnwrappedView(this.view, this.platformDispatcher);

  final ui.FlutterView view;
  @override
  final ui.PlatformDispatcher platformDispatcher;
  @override
  int get viewId => view.viewId;
  @override
  double get devicePixelRatio => view.devicePixelRatio;
  @override
  ui.Size get physicalSize => view.physicalSize;
  @override
  ui.ViewPadding get padding => view.padding;
  @override
  ui.ViewPadding get viewPadding => view.viewPadding;
  @override
  ui.ViewPadding get viewInsets => view.viewInsets;
  @override
  ui.ViewPadding get systemGestureInsets => view.systemGestureInsets;
  @override
  ui.GestureSettings get gestureSettings => view.gestureSettings;
  @override
  List<ui.DisplayFeature> get displayFeatures => view.displayFeatures;
  @override
  ui.DisplayCornerRadii? get displayCornerRadii => view.displayCornerRadii;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

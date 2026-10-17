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

/// The brightness the test environment does not report, so that overriding to
/// it is a visible change on every platform these tests run on.
final ui.Brightness _otherBrightness = switch (ui.PlatformDispatcher.instance.platformBrightness) {
  ui.Brightness.dark => ui.Brightness.light,
  ui.Brightness.light => ui.Brightness.dark,
};

/// Every metric [DebugViewMetricsOverride] can set that [MediaQueryData]
/// surfaces: an override that sets it, how to read it back, and the value
/// [MediaQueryData] must then report.
///
/// The test view reports 2400x1800 physical pixels at a device pixel ratio of
/// 3, which is what the logical expectations below are derived from.
///
/// A metric that is in neither this table nor [_notSurfacedByMediaQuery] is one
/// [MediaQueryData] could silently stop honoring, which is the failure the
/// tests over this table exist to catch.
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
    const DebugViewMetricsOverride(padding: FakeViewPadding(top: 30)),
    (MediaQueryData data) => data.padding,
    const EdgeInsets.only(top: 10),
  ),
  'viewPadding': (
    const DebugViewMetricsOverride(viewPadding: FakeViewPadding(top: 30)),
    (MediaQueryData data) => data.viewPadding,
    const EdgeInsets.only(top: 10),
  ),
  'viewInsets': (
    const DebugViewMetricsOverride(viewInsets: FakeViewPadding(bottom: 30)),
    (MediaQueryData data) => data.viewInsets,
    const EdgeInsets.only(bottom: 10),
  ),
  'systemGestureInsets': (
    const DebugViewMetricsOverride(systemGestureInsets: FakeViewPadding(bottom: 30)),
    (MediaQueryData data) => data.systemGestureInsets,
    const EdgeInsets.only(bottom: 10),
  ),
  'textScaling': (
    const DebugViewMetricsOverride(textScaling: <ui.Offset>[ui.Offset(1, 3)]),
    (MediaQueryData data) => data.textScaler.scale(10),
    30.0,
  ),
  'platformBrightness': (
    DebugViewMetricsOverride(platformBrightness: _otherBrightness),
    (MediaQueryData data) => data.platformBrightness,
    _otherBrightness,
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

/// The metrics [MediaQueryData.fromView] always reads from the view itself,
/// rather than taking from the `platformData` an ancestor [MediaQuery] supplies.
const Set<String> _viewGeometryMetrics = <String>{
  'devicePixelRatio',
  'physicalSize',
  'padding',
  'viewPadding',
  'viewInsets',
  'systemGestureInsets',
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
Set<String> _allOverridableMetrics() {
  return <String>{for (final DebugViewMetric metric in DebugViewMetric.values) metric.name};
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

/// An observer that fails on one notification, to check that the ones after
/// it are still delivered.
class _ThrowingObserver with WidgetsBindingObserver {
  @override
  void didChangeTextScaleFactor() => throw StateError('observer failed');
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
  // Construct this before testWidgets initializes the binding: a View can be
  // built before runWidget, and has to end up with the same normalized view the
  // binding vends later.
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
  // Overrides must be cleared inside the test body before the test ends because
  // debugAssertAllFoundationVarsUnset runs from the test binding's invariant
  // check, which happens before tear downs. A top-level tearDown is also
  // installed so that if any expectation throws before reaching the explicit
  // cleanup, leftover overrides do not leak into subsequent tests.
  tearDown(debugClearViewMetricsOverrides);

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

    testWidgets('reports an overridden text scaling table, and scales text with it', (
      WidgetTester tester,
    ) async {
      late MediaQueryData data;
      await tester.pumpWidget(_capture((MediaQueryData value) => data = value));
      expect(data.textScaler.scale(14.0), 14.0);

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(textScaling: <ui.Offset>[ui.Offset(2, 5)]),
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
          padding: FakeViewPadding(top: 141),
          viewPadding: FakeViewPadding(top: 141, bottom: 102),
          viewInsets: FakeViewPadding(bottom: 900),
          systemGestureInsets: FakeViewPadding(left: 60, right: 60),
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

    testWidgets('inherited platform data outranks a view override, and geometry does not', (
      WidgetTester tester,
    ) async {
      // An ancestor MediaQuery that supplies the platform-wide values dictates
      // them, override or not, just as it does when the real platform settings
      // change. Geometry is never inherited: MediaQueryData.fromView reads it
      // from the view, so an override of it still shows.
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

      void expectInheritedValues(String when) {
        expect(data.textScaler.scale(10), 40, reason: when);
        expect(data.platformBrightness, ui.Brightness.light, reason: when);
        expect(data.alwaysUse24HourFormat, isFalse, reason: when);
        expect(data.boldText, isFalse, reason: when);
        expect(data.highContrast, isTrue, reason: when);
      }

      expectInheritedValues('with no override registered');
      expect(data.devicePixelRatio, 3.0);
      expect(data.size, const Size(800, 600));

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(
          textScaling: <ui.Offset>[ui.Offset(1, 2)],
          platformBrightness: ui.Brightness.dark,
          alwaysUse24HourFormat: true,
          boldText: true,
          devicePixelRatio: 6.0,
          physicalSize: ui.Size(600, 900),
        ),
      );
      await tester.pump();

      expectInheritedValues('with an override registered');
      expect(data.devicePixelRatio, 6.0);
      expect(data.size, const Size(100, 150));

      debugClearViewMetricsOverrides();
      await tester.pump();
      expectInheritedValues('after the override was removed');
      expect(data.devicePixelRatio, 3.0);
      expect(data.size, const Size(800, 600));
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
        // With a size override the scene is rendered at the view's real size,
        // which an omitted size resolves to; otherwise the size laid out at.
        expect(
          (raw as _RenderableFakeView).lastRenderedSize,
          debugViewMetricsOverrides[raw.viewId]?.physicalSize == null
              ? data.size * data.devicePixelRatio
              : isNull,
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
      // TestPlatformDispatcher or TestFlutterView wins over an override; the
      // test doubles implement that by consulting the test value before the
      // wrapped dispatcher. MediaQuery has to agree with it, or the two report
      // different platforms.
      tester.platformDispatcher.textScaleFactorTestValue = 4.0;
      tester.platformDispatcher.platformBrightnessTestValue = ui.Brightness.dark;
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        boldText: true,
      );
      tester.view.devicePixelRatio = 5.0;
      tester.view.physicalSize = const ui.Size(800, 600);

      late MediaQueryData data;
      await tester.pumpWidget(_capture((MediaQueryData value) => data = value));

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(
          textScaling: <ui.Offset>[ui.Offset(1, 3)],
          platformBrightness: ui.Brightness.light,
          boldText: false,
          devicePixelRatio: 7.0,
          physicalSize: ui.Size(400, 300),
        ),
      );
      await tester.pump();

      final ui.PlatformDispatcher dispatcher = tester.view.platformDispatcher;
      final double dispatcherTextScale = dispatcher.textScaleFactor;
      final ui.Brightness dispatcherBrightness = dispatcher.platformBrightness;
      final bool dispatcherBoldText = dispatcher.accessibilityFeatures.boldText;
      final double viewRatio = tester.view.devicePixelRatio;
      final ui.Size viewSize = tester.view.physicalSize;
      final ui.ViewConstraints viewConstraints = tester.view.physicalConstraints;
      final reported = data;
      // SystemTextScaler asks the dispatcher at scale() time, so this has to be
      // evaluated before the test values are cleared.
      final double reportedTextScale = reported.textScaler.scale(10);

      debugClearViewMetricsOverrides();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
      await tester.pump();

      // The dispatcher and the view report the test values, not the override.
      expect(dispatcherTextScale, 4.0);
      expect(dispatcherBrightness, ui.Brightness.dark);
      expect(dispatcherBoldText, isTrue);
      expect(viewRatio, 5.0);
      expect(viewSize, const ui.Size(800, 600));
      expect(viewConstraints, ui.ViewConstraints.tight(const ui.Size(800, 600)));
      // MediaQuery agrees with them.
      expect(reportedTextScale, 40.0);
      expect(reported.platformBrightness, ui.Brightness.dark);
      expect(reported.boldText, isTrue);
      expect(reported.devicePixelRatio, 5.0);
      expect(reported.size, const ui.Size(160, 120));
    });

    testWidgets('a view read straight from the platform applies its override', (
      WidgetTester tester,
    ) async {
      // MediaQueryData.fromView documents that its view may come from
      // PlatformDispatcher.views. Such a view applies no override itself, so
      // the constructor reads it through the one that does.
      final ui.FlutterView rawView = ui.PlatformDispatcher.instance.implicitView!;
      debugSetViewMetricsOverride(
        rawView.viewId,
        const DebugViewMetricsOverride(
          devicePixelRatio: 4.0,
          physicalSize: ui.Size(400, 800),
          boldText: true,
        ),
      );

      final data = MediaQueryData.fromView(rawView);
      expect(data.boldText, isTrue);
      expect(data.devicePixelRatio, 4.0);
      expect(data.size, const Size(100, 200));

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

    testWidgets('the test view keeps its identity through View.of', (WidgetTester tester) async {
      // A TestFlutterView is read through its own dispatcher, so normalization
      // leaves it alone: the view a test hands to View is the view View.of
      // reports, override or not.
      late ui.FlutterView inherited;
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            inherited = View.of(context);
            return const SizedBox.expand();
          },
        ),
      );
      expect(inherited, same(tester.view));
      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(devicePixelRatio: 4.0),
      );
      await tester.pump();
      expect(inherited, same(tester.view));
      expect(inherited.devicePixelRatio, 4.0);
      debugClearViewMetricsOverrides();
      await tester.pump();
    });
  });

  group('every overridable metric MediaQuery surfaces', () {
    // The table is the enumeration, checked against the class itself, so a
    // metric added to DebugViewMetricsOverride has to be classified rather
    // than silently never reaching MediaQuery.
    void expectTableIsComplete() {
      expect(<String>{
        ..._surfacedMetrics.keys,
        ..._notSurfacedByMediaQuery,
      }, unorderedEquals(_allOverridableMetrics()));
      expect(_viewGeometryMetrics, everyElement(isIn(_surfacedMetrics.keys)));
    }

    testWidgets('is honored', (WidgetTester tester) async {
      expectTableIsComplete();
      expect(tester.view.physicalSize, const Size(2400, 1800));
      expect(tester.view.devicePixelRatio, 3.0);

      late MediaQueryData data;
      await tester.pumpWidget(_capture((MediaQueryData value) => data = value));

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
        final Object? reported = read(data);
        debugSetViewMetricsOverride(tester.view.viewId, override);
        await tester.pump();
        final Object? overridden = read(data);
        debugSetViewMetricsOverride(tester.view.viewId, null);
        await tester.pump();

        expect(overridden, expected, reason: '${entry.key} was not honored');
        expect(
          reported,
          isNot(expected),
          reason:
              '${entry.key} would read the same without the override, so the '
              'test cannot tell whether it was honored',
        );
        expect(read(data), reported, reason: '${entry.key} was not restored');
      }
      debugClearViewMetricsOverrides();
      await tester.pump();
    });

    testWidgets('defers to inherited platform data, except for geometry', (
      WidgetTester tester,
    ) async {
      expectTableIsComplete();

      late MediaQueryData data;
      // A parent that disagrees with every override in the table, so honoring
      // an override instead of inheriting is visible.
      final MediaQueryData parent = MediaQueryData.fromView(tester.view).copyWith(
        textScaler: const TextScaler.linear(9.0),
        platformBrightness: ui.PlatformDispatcher.instance.platformBrightness,
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

        expect(
          inherited,
          isNot(expected),
          reason:
              '${entry.key} would read the same without the override, so the '
              'test cannot tell whether it was honored',
        );
        if (_viewGeometryMetrics.contains(entry.key)) {
          expect(overridden, expected, reason: '${entry.key} is read from the view');
        } else {
          expect(overridden, inherited, reason: '${entry.key} is dictated by the parent');
        }
        expect(read(data), inherited, reason: '${entry.key} was not restored');
      }
      debugClearViewMetricsOverrides();
      await tester.pump();
    });
  });

  group('disableAnimations', () {
    testWidgets('reaches AnimationController through the binding', (WidgetTester tester) async {
      // AnimationBehavior.normal shortens a controller's duration according to
      // SemanticsBinding.disableAnimations, which the binding caches from its
      // own dispatcher and refreshes when dart:ui reports a change. An override
      // for the implicit view has to reach it, which only works if installing
      // the override replays that notification.
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

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(disableAnimations: true),
      );
      final bool binding = SemanticsBinding.instance.disableAnimations;
      final bool shortened = await finishesShortened();
      debugClearViewMetricsOverrides();
      await tester.pump();

      expect(binding, isTrue);
      expect(shortened, isTrue);
      expect(SemanticsBinding.instance.disableAnimations, isFalse);
      expect(await finishesShortened(), isFalse);
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

      // ...nor is a text scaling table, or a brightness.
      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(boldText: true, textScaling: <ui.Offset>[ui.Offset(1, 2)]),
      );
      expect(recorder.textScaleFactor, 1, reason: '$recorder');
      expect(recorder.accessibilityFeatures, 1, reason: '$recorder');
      expect(recorder.metrics, 0, reason: '$recorder');

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(
          boldText: true,
          textScaling: <ui.Offset>[ui.Offset(1, 2)],
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
          textScaling: <ui.Offset>[ui.Offset(1, 2)],
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
          textScaling: <ui.Offset>[ui.Offset(1, 2)],
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

    testWidgets('a failing observer does not cancel the notifications after it', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const SizedBox.expand());
      final throwing = _ThrowingObserver();
      final recorder = _NotificationRecorder();
      tester.binding.addObserver(throwing);
      tester.binding.addObserver(recorder);
      addTearDown(() {
        tester.binding.removeObserver(throwing);
        tester.binding.removeObserver(recorder);
      });

      debugSetViewMetricsOverride(
        tester.view.viewId,
        const DebugViewMetricsOverride(
          textScaling: <ui.Offset>[ui.Offset(1, 2)],
          devicePixelRatio: 6.0,
        ),
      );
      // Reported rather than thrown, and the metrics were still announced.
      expect(tester.takeException(), isStateError);
      expect(recorder.textScaleFactor, 1, reason: '$recorder');
      expect(recorder.metrics, 1, reason: '$recorder');
      await tester.pump();
      expect(tester.getSize(find.byType(SizedBox)), const Size(400, 300));

      debugClearViewMetricsOverrides();
      expect(tester.takeException(), isStateError);
      expect(recorder.metrics, 2, reason: '$recorder');
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

  testWidgets('every consumer sees one override, and all of them revert', (
    WidgetTester tester,
  ) async {
    // The acceptance test for the application layer, with real wrapped views
    // and no test doubles: one override, read by every consumer that bypasses
    // MediaQuery as well as by MediaQuery itself, all after a single pump.
    final tapped = <Offset>[];
    late MediaQueryData data;
    late ui.FlutterView viewOf;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          data = MediaQuery.of(context);
          viewOf = View.of(context);
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (PointerDownEvent event) => tapped.add(event.localPosition),
            child: const SizedBox.expand(),
          );
        },
      ),
    );

    void tapPhysically() {
      tester.binding.platformDispatcher.onPointerDataPacket!(
        ui.PointerDataPacket(
          data: <ui.PointerData>[
            ui.PointerData(
              viewId: tester.view.viewId,
              change: ui.PointerChange.down,
              physicalX: 600,
              physicalY: 600,
            ),
            ui.PointerData(
              viewId: tester.view.viewId,
              change: ui.PointerChange.up,
              physicalX: 600,
              physicalY: 600,
            ),
          ],
        ),
      );
    }

    tapPhysically();
    expect(tapped, <Offset>[const Offset(200, 200)]);
    tapped.clear();

    debugSetViewMetricsOverride(
      tester.view.viewId,
      const DebugViewMetricsOverride(
        devicePixelRatio: 6.0,
        textScaling: <ui.Offset>[ui.Offset(1, 2)],
        boldText: true,
        platformBrightness: ui.Brightness.dark,
      ),
    );
    await tester.pump();
    tapPhysically();

    expect(data.devicePixelRatio, 6.0);
    expect(data.size, const Size(400, 300));
    expect(data.textScaler.scale(10), 20);
    expect(data.boldText, isTrue);
    expect(data.platformBrightness, ui.Brightness.dark);
    expect(viewOf.devicePixelRatio, 6.0);
    expect(tester.binding.renderView.configuration.devicePixelRatio, 6.0);
    expect(tester.binding.renderView.size, const Size(400, 300));
    expect(SemanticsBinding.instance.accessibilityFeatures.boldText, isTrue);
    expect(tapped, <Offset>[const Offset(100, 100)]);
    tapped.clear();

    debugClearViewMetricsOverrides();
    await tester.pump();
    tapPhysically();

    expect(data.devicePixelRatio, 3.0);
    expect(data.size, const Size(800, 600));
    expect(data.textScaler.scale(10), 10);
    expect(data.boldText, isFalse);
    expect(viewOf.devicePixelRatio, 3.0);
    expect(tester.binding.renderView.size, const Size(800, 600));
    expect(SemanticsBinding.instance.accessibilityFeatures.boldText, isFalse);
    expect(tapped, <Offset>[const Offset(200, 200)]);
    // The test binding verifies debugAssertAllFoundationVarsUnset itself once
    // the body returns, which is what makes a leftover override a test failure.
    expect(debugViewMetricsOverrides, isEmpty);
  });
}

/// A [ui.PlatformDispatcher] whose text scaling is a curve rather than a
/// factor, so that a test can tell the platform's scaling from an override's.
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

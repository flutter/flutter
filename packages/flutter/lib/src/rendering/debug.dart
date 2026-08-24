// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'dart:developer';
///
/// @docImport 'package:flutter/scheduler.dart';
/// @docImport 'package:flutter/semantics.dart';
/// @docImport 'package:flutter/widgets.dart';
///
/// @docImport 'binding.dart';
/// @docImport 'box.dart';
/// @docImport 'layer.dart';
/// @docImport 'proxy_box.dart';
/// @docImport 'shifted_box.dart';
/// @docImport 'view.dart';
library;

import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'box.dart';
import 'object.dart';

export 'package:flutter/foundation.dart' show debugPrint;

// Any changes to this file should be reflected in the debugAssertAllRenderVarsUnset()
// function below.

const HSVColor _kDebugDefaultRepaintColor = HSVColor.fromAHSV(0.4, 60.0, 1.0, 1.0);

/// Causes each RenderBox to paint a box around its bounds, and some extra
/// boxes, such as [RenderPadding], to draw construction lines.
///
/// The edges of the boxes are painted as a one-pixel-thick `const Color(0xFF00FFFF)` outline.
///
/// Spacing is painted as a solid `const Color(0x90909090)` area.
///
/// Padding is filled in solid `const Color(0x900090FF)`, with the inner edge
/// outlined in `const Color(0xFF0090FF)`, using [debugPaintPadding].
bool debugPaintSizeEnabled = false;

/// Causes each RenderBox to paint a line at each of its baselines.
bool debugPaintBaselinesEnabled = false;

/// Causes each RenderParagraph to paint the layout boxes of its text.
///
/// {@macro flutter.painting.textPainter.debugPaintTextLayoutBoxes}
///
/// See also:
///
///  * [debugPaintBaselinesEnabled] which helps debug text alignment.
bool debugPaintTextLayoutBoxes = false;

/// Causes each Layer to paint a box around its bounds.
bool debugPaintLayerBordersEnabled = false;

/// Causes objects like [RenderPointerListener] to flash while they are being
/// tapped. This can be useful to see how large the hit box is, e.g. when
/// debugging buttons that are harder to hit than expected.
///
/// For details on how to support this in your [RenderBox] subclass, see
/// [RenderBox.debugHandleEvent].
bool debugPaintPointersEnabled = false;

/// Overlay a rotating set of colors when repainting layers in debug mode.
///
/// See also:
///
///  * [RepaintBoundary], which can be used to contain repaints when unchanged
///    areas are being excessively repainted.
bool debugRepaintRainbowEnabled = false;

/// Overlay a rotating set of colors when repainting text in debug mode.
bool debugRepaintTextRainbowEnabled = false;

/// The current color to overlay when repainting a layer.
///
/// This is used by painting debug code that implements
/// [debugRepaintRainbowEnabled] or [debugRepaintTextRainbowEnabled].
///
/// The value is incremented by [RenderView.compositeFrame] if either of those
/// flags is enabled.
HSVColor debugCurrentRepaintColor = _kDebugDefaultRepaintColor;

/// Log the call stacks that mark render objects as needing layout.
///
/// For sanity, this only logs the stack traces of cases where an object is
/// added to the list of nodes needing layout. This avoids printing multiple
/// redundant stack traces as a single [RenderObject.markNeedsLayout] call walks
/// up the tree.
bool debugPrintMarkNeedsLayoutStacks = false;

/// Log the call stacks that mark render objects as needing paint.
bool debugPrintMarkNeedsPaintStacks = false;

/// Log the dirty render objects that are laid out each frame.
///
/// Combined with [debugPrintBeginFrameBanner], this allows you to distinguish
/// layouts triggered by the initial mounting of a render tree (e.g. in a call
/// to [runApp]) from the regular layouts triggered by the pipeline.
///
/// Combined with [debugPrintMarkNeedsLayoutStacks], this lets you watch a
/// render object's dirty/clean lifecycle.
///
/// See also:
///
///  * [debugProfileLayoutsEnabled], which does something similar for layout
///    but using the timeline view.
///  * [debugProfilePaintsEnabled], which does something similar for painting
///    but using the timeline view.
///  * [debugPrintRebuildDirtyWidgets], which does something similar for widgets
///    being rebuilt.
///  * The discussion at [RendererBinding.drawFrame].
bool debugPrintLayouts = false;

/// Check the intrinsic sizes of each [RenderBox] during layout.
///
/// By default this is turned off since these checks are expensive. If you are
/// implementing your own children of [RenderBox] with custom intrinsics, turn
/// this on in your unit tests for additional validations.
bool debugCheckIntrinsicSizes = false;

/// Adds [Timeline] events for every [RenderObject] layout.
///
/// The timing information this flag exposes is not representative of the actual
/// cost of layout, because the overhead of adding timeline events is
/// significant relative to the time each object takes to lay out. However, it
/// can expose unexpected layout behavior in the timeline.
///
/// In debug builds, additional information is included in the trace (such as
/// the properties of render objects being laid out). Collecting this data is
/// expensive and further makes these traces non-representative of actual
/// performance. This data is omitted in profile builds.
///
/// For more information about performance debugging in Flutter, see
/// <https://docs.flutter.dev/perf/ui-performance>.
///
/// See also:
///
///  * [debugPrintLayouts], which does something similar for layout but using
///    console output.
///  * [debugProfileBuildsEnabled], which does something similar for widgets
///    being rebuilt.
///  * [debugProfilePaintsEnabled], which does something similar for painting.
///  * [debugEnhanceLayoutTimelineArguments], which enhances the trace with
///    debugging information related to [RenderObject] layouts.
bool debugProfileLayoutsEnabled = false;

/// Adds [Timeline] events for every [RenderObject] painted.
///
/// The timing information this flag exposes is not representative of actual
/// paints, because the overhead of adding timeline events is significant
/// relative to the time each object takes to paint. However, it can expose
/// unexpected painting in the timeline.
///
/// In debug builds, additional information is included in the trace (such as
/// the properties of render objects being painted). Collecting this data is
/// expensive and further makes these traces non-representative of actual
/// performance. This data is omitted in profile builds.
///
/// For more information about performance debugging in Flutter, see
/// <https://docs.flutter.dev/perf/ui-performance>.
///
/// See also:
///
///  * [debugProfileBuildsEnabled], which does something similar for widgets
///    being rebuilt, and [debugPrintRebuildDirtyWidgets], its console
///    equivalent.
///  * [debugProfileLayoutsEnabled], which does something similar for layout,
///    and [debugPrintLayouts], its console equivalent.
///  * The discussion at [RendererBinding.drawFrame].
///  * [RepaintBoundary], which can be used to contain repaints when unchanged
///    areas are being excessively repainted.
///  * [debugEnhancePaintTimelineArguments], which enhances the trace with
///    debugging information related to [RenderObject] paints.
bool debugProfilePaintsEnabled = false;

/// Adds debugging information to [Timeline] events related to [RenderObject]
/// layouts.
///
/// This flag will only add [Timeline] event arguments for debug builds.
/// Additional arguments will be added for the "LAYOUT" timeline event and for
/// all [RenderObject] layout [Timeline] events, which are the events that are
/// added when [debugProfileLayoutsEnabled] is true. The debugging information
/// that will be added in trace arguments includes stats around [RenderObject]
/// dirty states and [RenderObject] diagnostic information (i.e. [RenderObject]
/// properties).
///
/// See also:
///
///  * [debugProfileLayoutsEnabled], which adds [Timeline] events for every
///    [RenderObject] layout.
///  * [debugEnhancePaintTimelineArguments], which does something similar for
///    events related to [RenderObject] paints.
///  * [debugEnhanceBuildTimelineArguments], which does something similar for
///    events related to [Widget] builds.
bool debugEnhanceLayoutTimelineArguments = false;

/// Adds debugging information to [Timeline] events related to [RenderObject]
/// paints.
///
/// This flag will only add [Timeline] event arguments for debug builds.
/// Additional arguments will be added for the "PAINT" timeline event and for
/// all [RenderObject] paint [Timeline] events, which are the [Timeline] events
/// that are added when [debugProfilePaintsEnabled] is true. The debugging
/// information that will be added in trace arguments includes stats around
/// [RenderObject] dirty states and [RenderObject] diagnostic information
/// (i.e. [RenderObject] properties).
///
/// See also:
///
///  * [debugProfilePaintsEnabled], which adds [Timeline] events for every
///    [RenderObject] paint.
///  * [debugEnhanceLayoutTimelineArguments], which does something similar for
///    events related to [RenderObject] layouts.
///  * [debugEnhanceBuildTimelineArguments], which does something similar for
///    events related to [Widget] builds.
bool debugEnhancePaintTimelineArguments = false;

/// Signature for [debugOnProfilePaint] implementations.
typedef ProfilePaintCallback = void Function(RenderObject renderObject);

/// Callback invoked for every [RenderObject] painted each frame.
///
/// This callback is only invoked in debug builds.
///
/// See also:
///
///  * [debugProfilePaintsEnabled], which does something similar but adds
///    [dart:developer.Timeline] events instead of invoking a callback.
///  * [debugOnRebuildDirtyWidget], which does something similar for widgets
///    being built.
///  * [WidgetInspectorService], which uses the [debugOnProfilePaint]
///    callback to generate aggregate profile statistics describing what paints
///    occurred when the `ext.flutter.inspector.trackRepaintWidgets` service
///    extension is enabled.
ProfilePaintCallback? debugOnProfilePaint;

/// Setting to true will cause all clipping effects from the layer tree to be
/// ignored.
///
/// Can be used to debug whether objects being clipped are painting excessively
/// in clipped areas. Can also be used to check whether excessive use of
/// clipping is affecting performance.
///
/// This will not reduce the number of [Layer] objects created; the compositing
/// strategy is unaffected. It merely causes the clipping layers to be skipped
/// when building the scene.
bool debugDisableClipLayers = false;

/// Setting to true will cause all physical modeling effects from the layer
/// tree, such as shadows from elevations, to be ignored.
///
/// Can be used to check whether excessive use of physical models is affecting
/// performance.
///
/// This will not reduce the number of [Layer] objects created; the compositing
/// strategy is unaffected. It merely causes the physical shape layers to be
/// skipped when building the scene.
bool debugDisablePhysicalShapeLayers = false;

/// Setting to true will cause all opacity effects from the layer tree to be
/// ignored.
///
/// An optimization to not paint the child at all when opacity is 0 will still
/// remain.
///
/// Can be used to check whether excessive use of opacity effects is affecting
/// performance.
///
/// This will not reduce the number of [Layer] objects created; the compositing
/// strategy is unaffected. It merely causes the opacity layers to be skipped
/// when building the scene.
bool debugDisableOpacityLayers = false;

void _debugDrawDoubleRect(Canvas canvas, Rect outerRect, Rect innerRect, Color color) {
  final path = Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(outerRect)
    ..addRect(innerRect);
  final paint = Paint()..color = color;
  canvas.drawPath(path, paint);
}

/// Paint a diagram showing the given area as padding.
///
/// The `innerRect` argument represents the position of the child, if any.
///
/// When `innerRect` is null, the method draws the entire `outerRect` in a
/// grayish color representing _spacing_.
///
/// When `innerRect` is non-null, the method draws the padding region around the
/// `innerRect` in a tealish color, with a solid outline around the inner
/// region.
///
/// This method is used by [RenderPadding.debugPaintSize] when
/// [debugPaintSizeEnabled] is true.
void debugPaintPadding(
  Canvas canvas,
  Rect outerRect,
  Rect? innerRect, {
  double outlineWidth = 2.0,
}) {
  assert(() {
    if (innerRect != null && !innerRect.isEmpty) {
      _debugDrawDoubleRect(canvas, outerRect, innerRect, const Color(0x900090FF));
      _debugDrawDoubleRect(
        canvas,
        innerRect.inflate(outlineWidth).intersect(outerRect),
        innerRect,
        const Color(0xFF0090FF),
      );
    } else {
      final paint = Paint()..color = const Color(0x90909090);
      canvas.drawRect(outerRect, paint);
    }
    return true;
  }());
}

/// Returns true if none of the rendering library debug variables have been changed.
///
/// This function is used by the test framework to ensure that debug variables
/// haven't been inadvertently changed.
///
/// See [the rendering library](rendering/rendering-library.html) for a complete
/// list.
///
/// The `debugCheckIntrinsicSizesOverride` argument can be provided to override
/// the expected value for [debugCheckIntrinsicSizes]. (This exists because the
/// test framework itself overrides this value in some cases.)
bool debugAssertAllRenderVarsUnset(String reason, {bool debugCheckIntrinsicSizesOverride = false}) {
  assert(() {
    if (debugPaintSizeEnabled ||
        debugPaintBaselinesEnabled ||
        debugPaintLayerBordersEnabled ||
        debugPaintTextLayoutBoxes ||
        debugPaintPointersEnabled ||
        debugRepaintRainbowEnabled ||
        debugRepaintTextRainbowEnabled ||
        debugCurrentRepaintColor != _kDebugDefaultRepaintColor ||
        debugPrintMarkNeedsLayoutStacks ||
        debugPrintMarkNeedsPaintStacks ||
        debugPrintLayouts ||
        debugCheckIntrinsicSizes != debugCheckIntrinsicSizesOverride ||
        debugProfileLayoutsEnabled ||
        debugProfilePaintsEnabled ||
        debugOnProfilePaint != null ||
        debugDisableClipLayers ||
        debugDisablePhysicalShapeLayers ||
        debugDisableOpacityLayers ||
        debugViewMetricsOverrides.isNotEmpty) {
      throw FlutterError(reason);
    }
    return true;
  }());
  return true;
}

/// Returns true if the given [Axis] is bounded within the given
/// [BoxConstraints] in both the main and cross axis, throwing an exception
/// otherwise.
///
/// This is used by viewports during `performLayout` and `computeDryLayout`
/// because bounded constraints are required in order to layout their children.
bool debugCheckHasBoundedAxis(Axis axis, BoxConstraints constraints) {
  assert(() {
    if (!constraints.hasBoundedHeight || !constraints.hasBoundedWidth) {
      switch (axis) {
        case Axis.vertical:
          if (!constraints.hasBoundedHeight) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary('Vertical viewport was given unbounded height.'),
              ErrorDescription(
                'Viewports expand in the scrolling direction to fill their container. '
                'In this case, a vertical viewport was given an unlimited amount of '
                'vertical space in which to expand. This situation typically happens '
                'when a scrollable widget is nested inside another scrollable widget.',
              ),
              ErrorHint(
                'If this widget is always nested in a scrollable widget there '
                'is no need to use a viewport because there will always be enough '
                'vertical space for the children. In this case, consider using a '
                'Column or Wrap instead. Otherwise, consider using a '
                'CustomScrollView to concatenate arbitrary slivers into a '
                'single scrollable.',
              ),
            ]);
          }
          if (!constraints.hasBoundedWidth) {
            throw FlutterError(
              'Vertical viewport was given unbounded width.\n'
              'Viewports expand in the cross axis to fill their container and '
              'constrain their children to match their extent in the cross axis. '
              'In this case, a vertical viewport was given an unlimited amount of '
              'horizontal space in which to expand.',
            );
          }
        case Axis.horizontal:
          if (!constraints.hasBoundedWidth) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary('Horizontal viewport was given unbounded width.'),
              ErrorDescription(
                'Viewports expand in the scrolling direction to fill their container. '
                'In this case, a horizontal viewport was given an unlimited amount of '
                'horizontal space in which to expand. This situation typically happens '
                'when a scrollable widget is nested inside another scrollable widget.',
              ),
              ErrorHint(
                'If this widget is always nested in a scrollable widget there '
                'is no need to use a viewport because there will always be enough '
                'horizontal space for the children. In this case, consider using a '
                'Row or Wrap instead. Otherwise, consider using a '
                'CustomScrollView to concatenate arbitrary slivers into a '
                'single scrollable.',
              ),
            ]);
          }
          if (!constraints.hasBoundedHeight) {
            throw FlutterError(
              'Horizontal viewport was given unbounded height.\n'
              'Viewports expand in the cross axis to fill their container and '
              'constrain their children to match their extent in the cross axis. '
              'In this case, a horizontal viewport was given an unlimited amount of '
              'vertical space in which to expand.',
            );
          }
      }
    }
    return true;
  }());
  return true;
}

/// Debug-only overrides for the view metrics of a single [ui.FlutterView].
///
/// View metrics are platform-level settings that influence how an application
/// is presented, such as the text scale factor, whether bold text is requested,
/// or how large the window is. They originate in the platform embedding, are
/// exposed to the framework through `dart:ui`, and are consumed by widgets
/// through [MediaQuery].
///
/// An instance of this class describes how those metrics should be altered
/// before they reach the widget tree. A null field means "do not override this
/// metric"; the value reported by the platform is used instead.
///
/// Overrides are registered per view in [debugViewMetricsOverrides], and are
/// intended to be driven by developer tooling (DevTools, or an MCP server)
/// through the `ext.flutter.viewMetricsOverride` service extension so that an
/// application can be audited under many device configurations without
/// changing any real device settings.
///
/// This class has no effect in release mode.
///
/// ## Limitations
///
/// Overrides are applied where the framework consumes view metrics: the
/// [MediaQuery] a [View] creates, the [ViewConfiguration] of its [RenderView],
/// and the conversion of incoming pointer events. They do not reach back into
/// `dart:ui`, so code that reads the platform objects directly — for example
/// [SemanticsBinding.accessibilityFeatures], image resolution
/// selection based on [ui.FlutterView.devicePixelRatio], or the keyboard inset
/// calculations that consult [ui.FlutterView.viewInsets] for the real keyboard
/// — continues to see the real values. Content composited by the engine rather
/// than the framework, such as platform views and system UI, is likewise
/// unaffected.
///
/// See also:
///
///  * [debugViewMetricsOverrides], the map this class is registered in.
///  * [MediaQuery], which surfaces the overridden values to widgets.
@immutable
class DebugViewMetricsOverride with Diagnosticable {
  /// Creates a set of view metric overrides.
  ///
  /// Every argument is optional. A null argument means the corresponding
  /// metric is not overridden.
  ///
  /// [devicePixelRatio], if given, must be finite and greater than zero,
  /// because it is divided into layout constraints and a zero or non-finite
  /// value would produce infinite or NaN sizes throughout the render tree.
  ///
  /// [physicalSize] is subject to the same requirement, but cannot be asserted
  /// here without making this constructor unusable in a `const` expression.
  /// [ViewMetricsOverride.fromJson] rejects invalid sizes, which covers values
  /// arriving from developer tooling; a bad size passed directly is caught
  /// downstream by [BoxConstraints.debugAssertIsValid].
  const DebugViewMetricsOverride({
    this.devicePixelRatio,
    this.physicalSize,
    this.textScaler,
    this.platformBrightness,
    this.padding,
    this.viewPadding,
    this.viewInsets,
    this.alwaysUse24HourFormat,
    this.accessibleNavigation,
    this.invertColors,
    this.disableAnimations,
    this.boldText,
    this.reduceMotion,
    this.highContrast,
    this.onOffSwitchLabels,
    this.supportsAnnounce,
  }) : assert(
         devicePixelRatio == null || (devicePixelRatio > 0 && devicePixelRatio < double.infinity),
         'devicePixelRatio must be finite and greater than zero.',
       );

  /// Creates a set of view metric overrides from the wire format produced by
  /// [toJson].
  ///
  /// Keys that are absent are treated as "not overridden". Keys that are
  /// present but of an unexpected type cause a [FormatException], so that
  /// tooling errors surface at the service extension boundary rather than as
  /// silently ignored overrides.
  factory DebugViewMetricsOverride.fromJson(Map<String, Object?> json) {
    return DebugViewMetricsOverride(
      devicePixelRatio: _checkedDevicePixelRatio(_doubleFromJson(json, 'devicePixelRatio')),
      physicalSize: _checkedPhysicalSize(_sizeFromJson(json, 'physicalSize')),
      textScaler: switch (_doubleFromJson(json, 'textScaleFactor')) {
        final double factor when factor >= 0 && factor < double.infinity => TextScaler.linear(
          factor,
        ),
        final double factor => throw FormatException(
          'textScaleFactor must be finite and non-negative, got $factor.',
        ),
        null => null,
      },
      platformBrightness: switch (json['platformBrightness']) {
        null => null,
        'light' => ui.Brightness.light,
        'dark' => ui.Brightness.dark,
        final Object? value => throw FormatException(
          'Expected "light" or "dark" for platformBrightness, got $value.',
        ),
      },
      padding: _edgeInsetsFromJson(json, 'padding'),
      viewPadding: _edgeInsetsFromJson(json, 'viewPadding'),
      viewInsets: _edgeInsetsFromJson(json, 'viewInsets'),
      alwaysUse24HourFormat: _boolFromJson(json, 'alwaysUse24HourFormat'),
      accessibleNavigation: _boolFromJson(json, 'accessibleNavigation'),
      invertColors: _boolFromJson(json, 'invertColors'),
      disableAnimations: _boolFromJson(json, 'disableAnimations'),
      boldText: _boolFromJson(json, 'boldText'),
      reduceMotion: _boolFromJson(json, 'reduceMotion'),
      highContrast: _boolFromJson(json, 'highContrast'),
      onOffSwitchLabels: _boolFromJson(json, 'onOffSwitchLabels'),
      supportsAnnounce: _boolFromJson(json, 'supportsAnnounce'),
    );
  }

  /// Overrides [ui.FlutterView.devicePixelRatio].
  ///
  /// Unlike the other metrics on this class, this one is applied to the
  /// [ViewConfiguration] of the corresponding [RenderView] as well as to
  /// [MediaQuery], so that the render tree and [MediaQuery] agree.
  final double? devicePixelRatio;

  /// Overrides [ui.FlutterView.physicalSize].
  ///
  /// The value is in physical pixels, matching [ui.FlutterView.physicalSize].
  ///
  /// Like [devicePixelRatio], this is applied to the [ViewConfiguration] of the
  /// corresponding [RenderView] as well as to [MediaQuery], so the application
  /// really does lay out at the overridden size rather than merely reporting
  /// it.
  ///
  /// In a widget test, a surface size set through
  /// `TestWidgetsFlutterBinding.setSurfaceSize` takes precedence over this for
  /// the implicit view, because the test binding resolves that size before
  /// consulting [debugViewMetricsOverrides].
  final ui.Size? physicalSize;

  /// Overrides the [TextScaler] that would otherwise be derived from
  /// [ui.PlatformDispatcher.textScaleFactor].
  final TextScaler? textScaler;

  /// Overrides [ui.PlatformDispatcher.platformBrightness].
  final ui.Brightness? platformBrightness;

  /// Overrides [ui.FlutterView.padding], in logical pixels.
  final EdgeInsets? padding;

  /// Overrides [ui.FlutterView.viewPadding], in logical pixels.
  final EdgeInsets? viewPadding;

  /// Overrides [ui.FlutterView.viewInsets], in logical pixels.
  final EdgeInsets? viewInsets;

  /// Overrides [ui.PlatformDispatcher.alwaysUse24HourFormat].
  final bool? alwaysUse24HourFormat;

  /// Overrides [ui.AccessibilityFeatures.accessibleNavigation].
  ///
  /// This changes how widgets behave when they believe a screen reader is
  /// active. It does not start a real screen reader, and it does not change
  /// whether the engine requests a semantics tree.
  final bool? accessibleNavigation;

  /// Overrides [ui.AccessibilityFeatures.invertColors].
  final bool? invertColors;

  /// Overrides [ui.AccessibilityFeatures.disableAnimations].
  final bool? disableAnimations;

  /// Overrides [ui.AccessibilityFeatures.boldText].
  final bool? boldText;

  /// Overrides [ui.AccessibilityFeatures.reduceMotion].
  ///
  /// This is a separate platform setting from [disableAnimations] (on iOS it is
  /// "Reduce Motion" rather than "Prefer Cross-Fade Transitions"), so overriding
  /// one does not imply the other.
  final bool? reduceMotion;

  /// Overrides [ui.AccessibilityFeatures.highContrast].
  final bool? highContrast;

  /// Overrides [ui.AccessibilityFeatures.onOffSwitchLabels].
  final bool? onOffSwitchLabels;

  /// Overrides [ui.AccessibilityFeatures.supportsAnnounce].
  final bool? supportsAnnounce;

  /// Whether this instance overrides nothing at all.
  bool get isEmpty =>
      devicePixelRatio == null &&
      physicalSize == null &&
      textScaler == null &&
      platformBrightness == null &&
      padding == null &&
      viewPadding == null &&
      viewInsets == null &&
      alwaysUse24HourFormat == null &&
      accessibleNavigation == null &&
      invertColors == null &&
      disableAnimations == null &&
      boldText == null &&
      reduceMotion == null &&
      highContrast == null &&
      onOffSwitchLabels == null &&
      supportsAnnounce == null;

  /// Whether this instance overrides a metric that participates in layout, and
  /// therefore requires the [RenderView]'s [ViewConfiguration] to be rebuilt.
  bool get affectsViewConfiguration => devicePixelRatio != null || physicalSize != null;

  /// Creates a copy of this object with the given fields replaced.
  ///
  /// Because a null field means "not overridden", passing null for an argument
  /// leaves the existing override in place rather than clearing it. To clear an
  /// override, construct a new [DebugViewMetricsOverride].
  DebugViewMetricsOverride copyWith({
    double? devicePixelRatio,
    ui.Size? physicalSize,
    TextScaler? textScaler,
    ui.Brightness? platformBrightness,
    EdgeInsets? padding,
    EdgeInsets? viewPadding,
    EdgeInsets? viewInsets,
    bool? alwaysUse24HourFormat,
    bool? accessibleNavigation,
    bool? invertColors,
    bool? disableAnimations,
    bool? boldText,
    bool? reduceMotion,
    bool? highContrast,
    bool? onOffSwitchLabels,
    bool? supportsAnnounce,
  }) {
    return DebugViewMetricsOverride(
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
      physicalSize: physicalSize ?? this.physicalSize,
      textScaler: textScaler ?? this.textScaler,
      platformBrightness: platformBrightness ?? this.platformBrightness,
      padding: padding ?? this.padding,
      viewPadding: viewPadding ?? this.viewPadding,
      viewInsets: viewInsets ?? this.viewInsets,
      alwaysUse24HourFormat: alwaysUse24HourFormat ?? this.alwaysUse24HourFormat,
      accessibleNavigation: accessibleNavigation ?? this.accessibleNavigation,
      invertColors: invertColors ?? this.invertColors,
      disableAnimations: disableAnimations ?? this.disableAnimations,
      boldText: boldText ?? this.boldText,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      highContrast: highContrast ?? this.highContrast,
      onOffSwitchLabels: onOffSwitchLabels ?? this.onOffSwitchLabels,
      supportsAnnounce: supportsAnnounce ?? this.supportsAnnounce,
    );
  }

  /// Serializes this object to the wire format used by the
  /// `ext.flutter.viewMetricsOverride` service extension.
  ///
  /// Metrics that are not overridden are omitted from the result.
  ///
  /// A non-linear [textScaler] is reported as the factor it applies to a
  /// 1.0-sized font, because the wire format only carries a linear factor.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (devicePixelRatio != null) 'devicePixelRatio': devicePixelRatio,
      if (physicalSize != null)
        'physicalSize': <String, Object?>{
          'width': physicalSize!.width,
          'height': physicalSize!.height,
        },
      if (textScaler != null) 'textScaleFactor': textScaler!.scale(1.0),
      if (platformBrightness != null) 'platformBrightness': platformBrightness!.name,
      if (padding != null) 'padding': _edgeInsetsToJson(padding!),
      if (viewPadding != null) 'viewPadding': _edgeInsetsToJson(viewPadding!),
      if (viewInsets != null) 'viewInsets': _edgeInsetsToJson(viewInsets!),
      if (alwaysUse24HourFormat != null) 'alwaysUse24HourFormat': alwaysUse24HourFormat,
      if (accessibleNavigation != null) 'accessibleNavigation': accessibleNavigation,
      if (invertColors != null) 'invertColors': invertColors,
      if (disableAnimations != null) 'disableAnimations': disableAnimations,
      if (boldText != null) 'boldText': boldText,
      if (reduceMotion != null) 'reduceMotion': reduceMotion,
      if (highContrast != null) 'highContrast': highContrast,
      if (onOffSwitchLabels != null) 'onOffSwitchLabels': onOffSwitchLabels,
      if (supportsAnnounce != null) 'supportsAnnounce': supportsAnnounce,
    };
  }

  static Map<String, Object?> _edgeInsetsToJson(EdgeInsets insets) {
    return <String, Object?>{
      'left': insets.left,
      'top': insets.top,
      'right': insets.right,
      'bottom': insets.bottom,
    };
  }

  // Tooling supplies these values, so reject the ones that would divide into
  // infinite or NaN layout constraints before they reach the constructor's
  // asserts, where they would take the whole application down.
  static double? _checkedDevicePixelRatio(double? value) {
    if (value != null && !(value > 0 && value < double.infinity)) {
      throw FormatException('devicePixelRatio must be finite and greater than zero, got $value.');
    }
    return value;
  }

  static ui.Size? _checkedPhysicalSize(ui.Size? value) {
    if (value != null && !(value.isFinite && value.width >= 0 && value.height >= 0)) {
      throw FormatException('physicalSize must be finite and non-negative, got $value.');
    }
    return value;
  }

  static double? _doubleFromJson(Map<String, Object?> json, String key) {
    return switch (json[key]) {
      null => null,
      final num value => value.toDouble(),
      final Object value => throw FormatException('Expected a number for $key, got $value.'),
    };
  }

  static bool? _boolFromJson(Map<String, Object?> json, String key) {
    return switch (json[key]) {
      null => null,
      final bool value => value,
      final Object value => throw FormatException('Expected a boolean for $key, got $value.'),
    };
  }

  static ui.Size? _sizeFromJson(Map<String, Object?> json, String key) {
    return switch (json[key]) {
      null => null,
      {'width': final num width, 'height': final num height} => ui.Size(
        width.toDouble(),
        height.toDouble(),
      ),
      final Object value => throw FormatException(
        'Expected {"width": num, "height": num} for $key, got $value.',
      ),
    };
  }

  static EdgeInsets? _edgeInsetsFromJson(Map<String, Object?> json, String key) {
    return switch (json[key]) {
      null => null,
      {
        'left': final num left,
        'top': final num top,
        'right': final num right,
        'bottom': final num bottom,
      } =>
        EdgeInsets.fromLTRB(
          _checkedInsetComponent(left, key, 'left'),
          _checkedInsetComponent(top, key, 'top'),
          _checkedInsetComponent(right, key, 'right'),
          _checkedInsetComponent(bottom, key, 'bottom'),
        ),
      final Object value => throw FormatException(
        'Expected {"left": num, "top": num, "right": num, "bottom": num} for $key, got $value.',
      ),
    };
  }

  // Insets are platform-reported distances that feed straight into layout, so
  // a negative or non-finite component from tooling would produce negative or
  // NaN geometry rather than an obviously wrong-looking screen.
  static double _checkedInsetComponent(num value, String key, String edge) {
    final double component = value.toDouble();
    if (!component.isFinite || component < 0) {
      throw FormatException('$key.$edge must be finite and non-negative, got $component.');
    }
    return component;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is DebugViewMetricsOverride &&
        other.devicePixelRatio == devicePixelRatio &&
        other.physicalSize == physicalSize &&
        other.textScaler == textScaler &&
        other.platformBrightness == platformBrightness &&
        other.padding == padding &&
        other.viewPadding == viewPadding &&
        other.viewInsets == viewInsets &&
        other.alwaysUse24HourFormat == alwaysUse24HourFormat &&
        other.accessibleNavigation == accessibleNavigation &&
        other.invertColors == invertColors &&
        other.disableAnimations == disableAnimations &&
        other.boldText == boldText &&
        other.reduceMotion == reduceMotion &&
        other.highContrast == highContrast &&
        other.onOffSwitchLabels == onOffSwitchLabels &&
        other.supportsAnnounce == supportsAnnounce;
  }

  @override
  int get hashCode => Object.hash(
    devicePixelRatio,
    physicalSize,
    textScaler,
    platformBrightness,
    padding,
    viewPadding,
    viewInsets,
    alwaysUse24HourFormat,
    accessibleNavigation,
    invertColors,
    disableAnimations,
    boldText,
    reduceMotion,
    highContrast,
    onOffSwitchLabels,
    supportsAnnounce,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('devicePixelRatio', devicePixelRatio, defaultValue: null));
    properties.add(DiagnosticsProperty<ui.Size>('physicalSize', physicalSize, defaultValue: null));
    properties.add(DiagnosticsProperty<TextScaler>('textScaler', textScaler, defaultValue: null));
    properties.add(
      EnumProperty<ui.Brightness>('platformBrightness', platformBrightness, defaultValue: null),
    );
    properties.add(DiagnosticsProperty<EdgeInsets>('padding', padding, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsets>('viewPadding', viewPadding, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsets>('viewInsets', viewInsets, defaultValue: null));
    _addFlag(properties, 'alwaysUse24HourFormat', alwaysUse24HourFormat);
    _addFlag(properties, 'accessibleNavigation', accessibleNavigation);
    _addFlag(properties, 'invertColors', invertColors);
    _addFlag(properties, 'disableAnimations', disableAnimations);
    _addFlag(properties, 'boldText', boldText);
    _addFlag(properties, 'reduceMotion', reduceMotion);
    _addFlag(properties, 'highContrast', highContrast);
    _addFlag(properties, 'onOffSwitchLabels', onOffSwitchLabels);
    _addFlag(properties, 'supportsAnnounce', supportsAnnounce);
  }

  static void _addFlag(DiagnosticPropertiesBuilder properties, String name, bool? value) {
    properties.add(FlagProperty(name, value: value, ifTrue: name, ifFalse: 'not $name'));
  }
}

/// Debug-only view metric overrides, keyed by [ui.FlutterView.viewId].
///
/// Developer tooling installs entries here — normally through the
/// `ext.flutter.viewMetricsOverride` service extension rather than directly —
/// to make an application render as though the platform reported different
/// settings. Entries are read by [MediaQuery] and by
/// [RendererBinding.createViewConfigurationFor].
///
/// This map is read-only. Modifying it has to notify the views that depend on
/// it, so use [debugSetViewMetricsOverride] and
/// [debugClearViewMetricsOverrides] instead; mutating the map directly throws
/// an [UnsupportedError] rather than silently leaving views stale.
///
/// This map is ignored in release mode.
Map<int, DebugViewMetricsOverride> get debugViewMetricsOverrides =>
    _unmodifiableViewMetricsOverrides;

final Map<int, DebugViewMetricsOverride> _viewMetricsOverrides = <int, DebugViewMetricsOverride>{};
final Map<int, DebugViewMetricsOverride> _unmodifiableViewMetricsOverrides =
    UnmodifiableMapView<int, DebugViewMetricsOverride>(_viewMetricsOverrides);

/// Notifies listeners when [debugViewMetricsOverrides] changes.
///
/// [MediaQuery] listens to this so that a view rebuilds when its override is
/// installed, changed, or removed, and [RendererBinding] listens to it so that
/// an overridden size is applied to the [RenderView].
///
/// Mutate [debugViewMetricsOverrides] through [debugSetViewMetricsOverride] or
/// [debugClearViewMetricsOverrides], which notify this object for you.
Listenable get debugViewMetricsOverridesNotifier => _overridesNotifier;

final _DebugViewMetricsOverridesNotifier _overridesNotifier = _DebugViewMetricsOverridesNotifier();

// Deliberately not registered with ChangeNotifier.maybeDispatchObjectCreation:
// this is a process-lifetime singleton that is never disposed, and leak
// tracking would report it as a leak in every test that enables it.
class _DebugViewMetricsOverridesNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Installs [override] for the view with the given [viewId] and notifies
/// listeners.
///
/// Passing a null [override], or one for which [ViewMetricsOverride.isEmpty] is
/// true, removes the entry.
///
/// Returns true if the override actually changed. This has no effect in release
/// mode, where it always returns false.
///
/// Listeners are notified synchronously, which marks affected views dirty.
/// Do not call this during a build; the service extension that normally drives
/// it runs on the event loop, outside the build phase.
///
/// Tests that call this must reset it before the test body ends, because
/// [debugAssertAllRenderVarsUnset] treats a leftover override as a leaked
/// debug variable.
bool debugSetViewMetricsOverride(int viewId, DebugViewMetricsOverride? override) {
  if (kReleaseMode) {
    return false;
  }
  final DebugViewMetricsOverride? previous = _viewMetricsOverrides[viewId];
  if (override == null || override.isEmpty) {
    if (previous == null) {
      return false;
    }
    _viewMetricsOverrides.remove(viewId);
  } else {
    if (previous == override) {
      return false;
    }
    _viewMetricsOverrides[viewId] = override;
  }
  _overridesNotifier.notify();
  return true;
}

/// Removes every entry from [debugViewMetricsOverrides] and notifies listeners.
///
/// Returns true if anything was removed.
bool debugClearViewMetricsOverrides() {
  if (kReleaseMode || _viewMetricsOverrides.isEmpty) {
    return false;
  }
  _viewMetricsOverrides.clear();
  _overridesNotifier.notify();
  return true;
}

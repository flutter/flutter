// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'dart:developer';
///
/// @docImport 'package:flutter/foundation.dart';
/// @docImport 'package:flutter/rendering.dart';
/// @docImport 'package:flutter/semantics.dart';
/// @docImport 'package:flutter/widgets.dart';
/// @docImport 'package:flutter_test/flutter_test.dart';
library;

import 'dart:collection';
import 'dart:ui'
    as ui
    show
        AccessibilityFeatures,
        Brightness,
        FlutterView,
        PlatformDispatcher,
        Size,
        ViewConstraints,
        ViewPadding;

import 'package:meta/meta.dart';

import '_view_metrics.dart' show debugReplayViewMetricsNotifications;
import 'assertions.dart';
import 'diagnostics.dart';
import 'memory_allocations.dart';
import 'platform.dart';
import 'print.dart';

export 'dart:ui' show Brightness;

export '_view_metrics.dart'
    show
        debugApplyViewMetricsOverrides,
        debugApplyViewMetricsOverridesForView,
        debugApplyViewMetricsOverridesToView,
        debugMarkViewAppliesItsOwnMetricsOverride,
        debugReadViewMetrics,
        debugViewMetricsOverrideApplied,
        debugViewWithMetricsOverrides;
export 'print.dart' show DebugPrintCallback;

/// Returns true if none of the foundation library debug variables have been
/// changed.
///
/// This function is used by the test framework to ensure that debug variables
/// haven't been inadvertently changed.
///
/// The `debugPrintOverride` argument can be specified to indicate the expected
/// value of the [debugPrint] variable. This is useful for test frameworks that
/// override [debugPrint] themselves and want to check that their own custom
/// value wasn't overridden by a test.
///
/// See [the foundation library](foundation/foundation-library.html)
/// for a complete list.
bool debugAssertAllFoundationVarsUnset(
  String reason, {
  DebugPrintCallback debugPrintOverride = debugPrintThrottled,
}) {
  assert(() {
    if (debugPrint != debugPrintOverride ||
        debugDefaultTargetPlatformOverride != null ||
        debugDoublePrecision != null ||
        debugBrightnessOverride != null ||
        debugViewMetricsOverrides.isNotEmpty) {
      throw FlutterError(reason);
    }
    return true;
  }());
  return true;
}

/// Boolean value indicating whether [debugInstrumentAction] will instrument
/// actions in debug builds.
///
/// The framework does not use [debugInstrumentAction] internally, so this
/// does not enable any additional instrumentation for the framework itself.
///
/// See also:
///
///  * [debugProfileBuildsEnabled], which enables additional tracing of builds
///    in [Widget]s.
///  * [debugProfileLayoutsEnabled], which enables additional tracing of layout
///    events in [RenderObject]s.
///  * [debugProfilePaintsEnabled], which enables additional tracing of paint
///    events in [RenderObject]s.
bool debugInstrumentationEnabled = false;

/// Runs the specified [action], timing how long the action takes in debug
/// builds when [debugInstrumentationEnabled] is true.
///
/// The instrumentation will be printed to the logs using [debugPrint]. In
/// non-debug builds, or when [debugInstrumentationEnabled] is false, this will
/// run [action] without any instrumentation.
///
/// Returns the result of running [action].
///
/// See also:
///
///  * [Timeline], which is used to record synchronous tracing events for
///    visualization in Chrome's tracing format. This method does not
///    implicitly add any timeline events.
Future<T> debugInstrumentAction<T>(String description, Future<T> Function() action) async {
  var instrument = false;
  assert(() {
    instrument = debugInstrumentationEnabled;
    return true;
  }());
  if (instrument) {
    // dart format off
    final stopwatch = Stopwatch() ..start(); // flutter_ignore: stopwatch (see analyze.dart)
    // Ignore context: The framework does not use this function internally so it will not cause flakes.
    // dart format on
    try {
      return await action();
    } finally {
      stopwatch.stop();
      debugPrint('Action "$description" took ${stopwatch.elapsed}');
    }
  } else {
    return action();
  }
}

/// Configure [debugFormatDouble] using [num.toStringAsPrecision].
///
/// Defaults to null, which uses the default logic of [debugFormatDouble].
int? debugDoublePrecision;

/// Formats a double to have standard formatting.
///
/// This behavior can be overridden by [debugDoublePrecision].
String debugFormatDouble(double? value) {
  if (value == null) {
    return 'null';
  }
  if (debugDoublePrecision != null) {
    return value.toStringAsPrecision(debugDoublePrecision!);
  }
  return value.toStringAsFixed(1);
}

/// A setting that can be used to override the platform [Brightness] exposed
/// from [BindingBase.platformDispatcher].
///
/// See also:
///
///  * [WidgetsApp], which uses the [debugBrightnessOverride] setting in debug mode
///    to construct a [MediaQueryData].
ui.Brightness? debugBrightnessOverride;

/// The address for the active DevTools server used for debugging this
/// application.
String? activeDevToolsServerAddress;

/// The uri for the connected vm service protocol.
String? connectedVmServiceUri;

/// If memory allocation tracking is enabled, dispatch Flutter object creation.
///
/// This method is not member of FlutterMemoryAllocations, because
/// [FlutterMemoryAllocations] should not increase size of the Flutter application
/// if memory allocations are disabled.
///
/// The [flutterLibrary] argument is the name of the Flutter library where
/// the object is declared. For example, 'widgets' for widgets.dart.
///
/// Should be called only from within an assert and only inside Flutter Framework.
///
/// Returns true to make it easier to be wrapped into `assert`.
bool debugMaybeDispatchCreated(String flutterLibrary, String className, Object object) {
  if (kFlutterMemoryAllocationsEnabled) {
    FlutterMemoryAllocations.instance.dispatchObjectCreated(
      library: 'package:flutter/$flutterLibrary.dart',
      className: className,
      object: object,
    );
  }
  return true;
}

/// If memory allocations tracking is enabled, dispatch object disposal.
///
/// Should be called only from within an assert.
///
/// Returns true to make it easier to be wrapped into `assert`.
bool debugMaybeDispatchDisposed(Object object) {
  if (kFlutterMemoryAllocationsEnabled) {
    FlutterMemoryAllocations.instance.dispatchObjectDisposed(object: object);
  }
  return true;
}

/// A distance for each of the four edges of a [ui.FlutterView], in physical
/// pixels, for use in a [DebugViewMetricsOverride].
///
/// [ui.ViewPadding] cannot be constructed outside `dart:ui`, so this stands in
/// for it. It is only a value holder: the framework reads it through the
/// [ui.ViewPadding] interface, exactly as it reads the padding the platform
/// reports.
///
/// The values are in physical pixels, like [ui.FlutterView.padding], not in
/// logical pixels like [EdgeInsets]. To express a 24 logical pixel status bar
/// on a device with a device pixel ratio of 3, use `24 * 3`.
@immutable
class DebugViewPadding implements ui.ViewPadding {
  /// Creates a view padding.
  ///
  /// All four distances default to zero.
  const DebugViewPadding({this.left = 0.0, this.top = 0.0, this.right = 0.0, this.bottom = 0.0})
    : assert(left >= 0.0 && left < double.infinity, 'left must be non-negative and finite.'),
      assert(top >= 0.0 && top < double.infinity, 'top must be non-negative and finite.'),
      assert(right >= 0.0 && right < double.infinity, 'right must be non-negative and finite.'),
      assert(bottom >= 0.0 && bottom < double.infinity, 'bottom must be non-negative and finite.');

  /// Creates a view padding with the same distance on all four edges.
  const DebugViewPadding.all(double value)
    : assert(value >= 0.0 && value < double.infinity, 'value must be non-negative and finite.'),
      left = value,
      top = value,
      right = value,
      bottom = value;

  /// Creates a view padding with the same distances as [padding].
  DebugViewPadding.fromViewPadding(ui.ViewPadding padding)
    : assert(
        padding.left >= 0.0 && padding.left < double.infinity,
        'left must be non-negative and finite.',
      ),
      assert(
        padding.top >= 0.0 && padding.top < double.infinity,
        'top must be non-negative and finite.',
      ),
      assert(
        padding.right >= 0.0 && padding.right < double.infinity,
        'right must be non-negative and finite.',
      ),
      assert(
        padding.bottom >= 0.0 && padding.bottom < double.infinity,
        'bottom must be non-negative and finite.',
      ),
      left = padding.left,
      top = padding.top,
      right = padding.right,
      bottom = padding.bottom;

  @override
  final double left;

  @override
  final double top;

  @override
  final double right;

  @override
  final double bottom;

  /// Creates a copy of this object with the given fields replaced.
  DebugViewPadding copyWith({double? left, double? top, double? right, double? bottom}) {
    return DebugViewPadding(
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
    );
  }

  /// A view padding that is zero on all four edges.
  static const DebugViewPadding zero = DebugViewPadding();

  // Only compares equal to other DebugViewPaddings, never to a ui.ViewPadding
  // reported by the platform. ui.ViewPadding does not define == at all, so
  // making this asymmetric with it would be worse than leaving those
  // comparisons identity based, which is what they already are.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is DebugViewPadding &&
        other.left == left &&
        other.top == top &&
        other.right == right &&
        other.bottom == bottom;
  }

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  /// This gives us some grace time when the dart:ui side adds something to
  /// [ui.ViewPadding], and makes things easier when we do rolls to give
  /// us time to catch up.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }

  @override
  String toString() => 'DebugViewPadding(left: $left, top: $top, right: $right, bottom: $bottom)';
}

/// Debug-only overrides for the view metrics of a single [ui.FlutterView].
///
/// View metrics are platform-level settings that influence how an application
/// is presented, such as the text scale factor, whether bold text is requested,
/// or how large the window is. They originate in the platform embedding and are
/// exposed to the framework through `dart:ui`, on [ui.FlutterView] and on
/// [ui.PlatformDispatcher].
///
/// An instance of this class describes how those metrics should be altered
/// before the framework reads them. A null field means "do not override this
/// metric"; the value the platform reports is used instead.
///
/// Overrides are registered per view in [debugViewMetricsOverrides] and are
/// intended to be driven by developer tooling (DevTools, or an MCP server)
/// through the `ext.flutter.viewMetricsOverride` service extension, so that an
/// application can be audited under many device configurations without changing
/// any real device setting.
///
/// Because the override is applied at the `dart:ui` layer — see
/// [debugApplyViewMetricsOverrides] — it reaches everything downstream of it:
/// the [MediaQuery] a [View] creates, the [ViewConfiguration] a [RenderView]
/// lays out with, the conversion of incoming pointer events,
/// [SemanticsBinding.accessibilityFeatures], accessibility evaluations, image
/// resolution, and the keyboard inset calculations in [EditableText]. Content
/// the engine composites rather than the framework, such as platform views and
/// system UI, is unaffected: this changes what the framework believes about the
/// platform, not the platform itself.
///
/// All values are in the units `dart:ui` uses, which for sizes and insets means
/// physical pixels rather than the logical pixels [MediaQueryData] reports.
///
/// Direct reads from [ui.PlatformDispatcher.instance] still report the real
/// platform metrics. Engine views passed to [View], [RenderView], or
/// [MediaQueryData.fromView] are normalized to apply overrides.
///
/// The deprecated [BindingBase.window] reports the platform's own metrics, and with it
/// the deprecated [ScrollPhysics.tolerance] that reads it. The deprecated
/// [MediaQuery.fromWindow] does apply them: it builds its data with
/// [MediaQueryData.fromView], which resolves the override registered for the
/// view the window stands for.
///
/// In a widget test, a value set on [TestFlutterView] or
/// [TestPlatformDispatcher] — including the size
/// `TestWidgetsFlutterBinding.setSurfaceSize` sets — takes precedence over the
/// corresponding metric here, because those objects wrap the ones this
/// overrides and resolve their own value first.
///
/// This class has no effect outside of debug mode (in profile or release mode).
///
/// See also:
///
///  * [debugViewMetricsOverrides], the map this class is registered in.
///  * [debugSetViewMetricsOverride], which registers an instance for a view.
@immutable
class DebugViewMetricsOverride with Diagnosticable {
  /// Creates a set of view metric overrides.
  ///
  /// Every argument is optional. A null argument means the corresponding metric
  /// is not overridden.
  ///
  /// [devicePixelRatio], if given, must be finite and greater than zero,
  /// because it is divided into layout constraints and a zero or non-finite
  /// value would produce infinite or NaN sizes throughout the render tree.
  /// [textScaleFactor], if given, must be finite and non-negative.
  ///
  /// [physicalSize], [padding], [viewPadding], [viewInsets], and
  /// [systemGestureInsets] are subject to similar requirements, which cannot
  /// be asserted here because reading a field off one of them is not a constant
  /// expression and would make this constructor unusable in a `const`
  /// expression.
  /// [DebugViewMetricsOverride.fromJson] rejects invalid values, which covers
  /// everything arriving from developer tooling.
  const DebugViewMetricsOverride({
    this.devicePixelRatio,
    this.physicalSize,
    this.textScaleFactor,
    this.platformBrightness,
    this.padding,
    this.viewPadding,
    this.viewInsets,
    this.systemGestureInsets,
    this.alwaysUse24HourFormat,
    this.accessibleNavigation,
    this.invertColors,
    this.disableAnimations,
    this.boldText,
    this.reduceMotion,
    this.highContrast,
    this.onOffSwitchLabels,
    this.supportsAnnounce,
    this.autoPlayAnimatedImages,
    this.autoPlayVideos,
    this.deterministicCursor,
  }) : assert(
         devicePixelRatio == null || (devicePixelRatio > 0 && devicePixelRatio < double.infinity),
         'devicePixelRatio must be finite and greater than zero.',
       ),
       assert(
         textScaleFactor == null || (textScaleFactor >= 0 && textScaleFactor < double.infinity),
         'textScaleFactor must be finite and non-negative.',
       );

  /// Creates a set of view metric overrides from the wire format [toJson]
  /// produces.
  ///
  /// Keys that are absent are treated as "not overridden". A key that is
  /// present but of an unexpected type, out of range, or not recognized at all
  /// throws a [FormatException], so that a tooling mistake surfaces at the
  /// service extension boundary instead of as a metric that silently failed to
  /// apply.
  factory DebugViewMetricsOverride.fromJson(Map<Object?, Object?> json) {
    final Iterable<Object?> unknownKeys = json.keys.where(
      (Object? key) => !_jsonKeys.contains(key),
    );
    if (unknownKeys.isNotEmpty) {
      throw FormatException(
        'Unknown view metric override(s): ${unknownKeys.join(', ')}. '
        'Supported metrics are: ${_jsonKeys.join(', ')}.',
      );
    }
    return DebugViewMetricsOverride(
      devicePixelRatio: switch (_doubleFromJson(json, 'devicePixelRatio')) {
        final double value when value > 0 && value < double.infinity => value,
        final double value => throw FormatException(
          'devicePixelRatio must be finite and greater than zero, got $value.',
        ),
        null => null,
      },
      physicalSize: _sizeFromJson(json, 'physicalSize'),
      textScaleFactor: switch (_doubleFromJson(json, 'textScaleFactor')) {
        final double value when value >= 0 && value < double.infinity => value,
        final double value => throw FormatException(
          'textScaleFactor must be finite and non-negative, got $value.',
        ),
        null => null,
      },
      platformBrightness: switch (json['platformBrightness']) {
        null => null,
        'light' || 'Brightness.light' => ui.Brightness.light,
        'dark' || 'Brightness.dark' => ui.Brightness.dark,
        final Object? value => throw FormatException(
          'Expected "light", "dark", "Brightness.light", or "Brightness.dark" for platformBrightness, got $value.',
        ),
      },
      padding: _viewPaddingFromJson(json, 'padding'),
      viewPadding: _viewPaddingFromJson(json, 'viewPadding'),
      viewInsets: _viewPaddingFromJson(json, 'viewInsets'),
      systemGestureInsets: _viewPaddingFromJson(json, 'systemGestureInsets'),
      alwaysUse24HourFormat: _boolFromJson(json, 'alwaysUse24HourFormat'),
      accessibleNavigation: _boolFromJson(json, 'accessibleNavigation'),
      invertColors: _boolFromJson(json, 'invertColors'),
      disableAnimations: _boolFromJson(json, 'disableAnimations'),
      boldText: _boolFromJson(json, 'boldText'),
      reduceMotion: _boolFromJson(json, 'reduceMotion'),
      highContrast: _boolFromJson(json, 'highContrast'),
      onOffSwitchLabels: _boolFromJson(json, 'onOffSwitchLabels'),
      supportsAnnounce: _boolFromJson(json, 'supportsAnnounce'),
      autoPlayAnimatedImages: _boolFromJson(json, 'autoPlayAnimatedImages'),
      autoPlayVideos: _boolFromJson(json, 'autoPlayVideos'),
      deterministicCursor: _boolFromJson(json, 'deterministicCursor'),
    );
  }

  /// Overrides [ui.FlutterView.devicePixelRatio].
  ///
  /// This changes the ratio the view actually lays out at, not just the one
  /// [MediaQueryData.devicePixelRatio] reports: the application is laid out in
  /// a logical space of `physicalSize / devicePixelRatio` and scaled back up by
  /// this ratio when it is composited, so the same physical area of the screen
  /// is covered.
  final double? devicePixelRatio;

  /// Overrides [ui.FlutterView.physicalSize], in physical pixels.
  ///
  /// This also makes [ui.FlutterView.physicalConstraints] tight around the
  /// given size, so that the application really lays out at the overridden size
  /// instead of merely reporting it.
  final ui.Size? physicalSize;

  /// Overrides [ui.PlatformDispatcher.textScaleFactor].
  ///
  /// Font sizes are then scaled linearly by this factor, because the platform
  /// curve [ui.PlatformDispatcher.scaleFontSize] normally applies is not
  /// parameterized by a factor and cannot be evaluated for a hypothetical one.
  final double? textScaleFactor;

  /// Overrides [ui.PlatformDispatcher.platformBrightness].
  ///
  /// Unlike [debugBrightnessOverride], which replaces the brightness of every
  /// view, this applies only to the view it is registered for. When
  /// [debugBrightnessOverride] is also set, it wins in [MediaQuery], which
  /// applies it after the [MediaQueryData] has been built from this.
  final ui.Brightness? platformBrightness;

  /// Overrides [ui.FlutterView.padding], in physical pixels.
  final DebugViewPadding? padding;

  /// Overrides [ui.FlutterView.viewPadding], in physical pixels.
  final DebugViewPadding? viewPadding;

  /// Overrides [ui.FlutterView.viewInsets], in physical pixels.
  ///
  /// This is what an on-screen keyboard occupies, so overriding it exercises
  /// the layout an application adopts while the keyboard is up without a
  /// keyboard being up.
  final DebugViewPadding? viewInsets;

  /// Overrides [ui.FlutterView.systemGestureInsets], in physical pixels.
  final DebugViewPadding? systemGestureInsets;

  /// Overrides [ui.PlatformDispatcher.alwaysUse24HourFormat].
  final bool? alwaysUse24HourFormat;

  /// Overrides [ui.AccessibilityFeatures.accessibleNavigation].
  ///
  /// This changes how widgets behave when they believe a screen reader is
  /// active. It does not start a real screen reader, and it does not change
  /// whether the engine asks the framework for a semantics tree.
  final bool? accessibleNavigation;

  /// Overrides [ui.AccessibilityFeatures.invertColors].
  final bool? invertColors;

  /// Overrides [ui.AccessibilityFeatures.disableAnimations].
  ///
  /// This reaches [MediaQueryData.disableAnimations], and so
  /// [MediaQuery.disableAnimationsOf], for the view it is registered for, along
  /// with the [ui.AccessibilityFeatures] that view's [ui.PlatformDispatcher]
  /// reports.
  ///
  /// It does not reach [AnimationController]s built with
  /// [AnimationBehavior.normal], which shorten their duration according to
  /// [SemanticsBinding.disableAnimations]. That is process-wide: the binding
  /// caches it from its own [ui.PlatformDispatcher], which has no view to
  /// resolve against and so uses the override of
  /// [ui.PlatformDispatcher.implicitView]. An override on the implicit view
  /// therefore shortens those animations in every view, and an override on any
  /// other view shortens them in none. Only widgets that read the value out of
  /// [MediaQuery] honor it per view.
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

  /// Overrides [ui.AccessibilityFeatures.autoPlayAnimatedImages].
  final bool? autoPlayAnimatedImages;

  /// Overrides [ui.AccessibilityFeatures.autoPlayVideos].
  final bool? autoPlayVideos;

  /// Overrides [ui.AccessibilityFeatures.deterministicCursor].
  final bool? deterministicCursor;

  /// Whether this instance overrides nothing at all.
  bool get isEmpty => this == const DebugViewMetricsOverride();

  /// A sentinel value used by [copyWith] as the default argument value to indicate
  /// that an argument was omitted.
  static const Object _omitted = _Omitted();

  /// Creates a copy of this object with the given fields replaced.
  ///
  /// The arguments, if provided, must match the types of the corresponding
  /// fields: [num] for [devicePixelRatio] and [textScaleFactor], [ui.Size] for
  /// [physicalSize], [ui.Brightness] for [platformBrightness],
  /// [DebugViewPadding] for insets and paddings, and [bool] for accessibility flags.
  ///
  /// Passing `null` for an argument clears the override for that field
  /// (resetting it to null, so that the underlying platform value is used).
  /// Omitting an argument leaves the existing override in place.
  DebugViewMetricsOverride copyWith({
    Object? devicePixelRatio = _omitted,
    Object? physicalSize = _omitted,
    Object? textScaleFactor = _omitted,
    Object? platformBrightness = _omitted,
    Object? padding = _omitted,
    Object? viewPadding = _omitted,
    Object? viewInsets = _omitted,
    Object? systemGestureInsets = _omitted,
    Object? alwaysUse24HourFormat = _omitted,
    Object? accessibleNavigation = _omitted,
    Object? invertColors = _omitted,
    Object? disableAnimations = _omitted,
    Object? boldText = _omitted,
    Object? reduceMotion = _omitted,
    Object? highContrast = _omitted,
    Object? onOffSwitchLabels = _omitted,
    Object? supportsAnnounce = _omitted,
    Object? autoPlayAnimatedImages = _omitted,
    Object? autoPlayVideos = _omitted,
    Object? deterministicCursor = _omitted,
  }) {
    bool check<T>(Object? value) => identical(value, _omitted) || value == null || value is T;

    assert(
      check<num>(devicePixelRatio),
      'devicePixelRatio must be a num or null, got ${devicePixelRatio.runtimeType} ($devicePixelRatio).',
    );
    assert(
      check<ui.Size>(physicalSize),
      'physicalSize must be a ui.Size or null, got ${physicalSize.runtimeType} ($physicalSize).',
    );
    assert(
      check<num>(textScaleFactor),
      'textScaleFactor must be a num or null, got ${textScaleFactor.runtimeType} ($textScaleFactor).',
    );
    assert(
      check<ui.Brightness>(platformBrightness),
      'platformBrightness must be a ui.Brightness or null, got ${platformBrightness.runtimeType} ($platformBrightness).',
    );
    assert(
      check<DebugViewPadding>(padding),
      'padding must be a DebugViewPadding or null, got ${padding.runtimeType} ($padding).',
    );
    assert(
      check<DebugViewPadding>(viewPadding),
      'viewPadding must be a DebugViewPadding or null, got ${viewPadding.runtimeType} ($viewPadding).',
    );
    assert(
      check<DebugViewPadding>(viewInsets),
      'viewInsets must be a DebugViewPadding or null, got ${viewInsets.runtimeType} ($viewInsets).',
    );
    assert(
      check<DebugViewPadding>(systemGestureInsets),
      'systemGestureInsets must be a DebugViewPadding or null, got ${systemGestureInsets.runtimeType} ($systemGestureInsets).',
    );
    assert(
      check<bool>(alwaysUse24HourFormat),
      'alwaysUse24HourFormat must be a bool or null, got ${alwaysUse24HourFormat.runtimeType} ($alwaysUse24HourFormat).',
    );
    assert(
      check<bool>(accessibleNavigation),
      'accessibleNavigation must be a bool or null, got ${accessibleNavigation.runtimeType} ($accessibleNavigation).',
    );
    assert(
      check<bool>(invertColors),
      'invertColors must be a bool or null, got ${invertColors.runtimeType} ($invertColors).',
    );
    assert(
      check<bool>(disableAnimations),
      'disableAnimations must be a bool or null, got ${disableAnimations.runtimeType} ($disableAnimations).',
    );
    assert(
      check<bool>(boldText),
      'boldText must be a bool or null, got ${boldText.runtimeType} ($boldText).',
    );
    assert(
      check<bool>(reduceMotion),
      'reduceMotion must be a bool or null, got ${reduceMotion.runtimeType} ($reduceMotion).',
    );
    assert(
      check<bool>(highContrast),
      'highContrast must be a bool or null, got ${highContrast.runtimeType} ($highContrast).',
    );
    assert(
      check<bool>(onOffSwitchLabels),
      'onOffSwitchLabels must be a bool or null, got ${onOffSwitchLabels.runtimeType} ($onOffSwitchLabels).',
    );
    assert(
      check<bool>(supportsAnnounce),
      'supportsAnnounce must be a bool or null, got ${supportsAnnounce.runtimeType} ($supportsAnnounce).',
    );
    assert(
      check<bool>(autoPlayAnimatedImages),
      'autoPlayAnimatedImages must be a bool or null, got ${autoPlayAnimatedImages.runtimeType} ($autoPlayAnimatedImages).',
    );
    assert(
      check<bool>(autoPlayVideos),
      'autoPlayVideos must be a bool or null, got ${autoPlayVideos.runtimeType} ($autoPlayVideos).',
    );
    assert(
      check<bool>(deterministicCursor),
      'deterministicCursor must be a bool or null, got ${deterministicCursor.runtimeType} ($deterministicCursor).',
    );

    double? resolveDouble(Object? value, double? current, String name) {
      if (identical(value, _omitted)) {
        return current;
      }
      if (value == null) {
        return null;
      }
      if (value is! num) {
        throw ArgumentError.value(value, name, 'Expected a num or null.');
      }
      return value.toDouble();
    }

    T? resolve<T extends Object>(Object? value, T? current, String name) {
      if (identical(value, _omitted)) {
        return current;
      }
      if (value == null) {
        return null;
      }
      if (value is! T) {
        throw ArgumentError.value(value, name, 'Expected a $T or null.');
      }
      return value;
    }

    final result = DebugViewMetricsOverride(
      devicePixelRatio: resolveDouble(devicePixelRatio, this.devicePixelRatio, 'devicePixelRatio'),
      physicalSize: resolve<ui.Size>(physicalSize, this.physicalSize, 'physicalSize'),
      textScaleFactor: resolveDouble(textScaleFactor, this.textScaleFactor, 'textScaleFactor'),
      platformBrightness: resolve<ui.Brightness>(
        platformBrightness,
        this.platformBrightness,
        'platformBrightness',
      ),
      padding: resolve<DebugViewPadding>(padding, this.padding, 'padding'),
      viewPadding: resolve<DebugViewPadding>(viewPadding, this.viewPadding, 'viewPadding'),
      viewInsets: resolve<DebugViewPadding>(viewInsets, this.viewInsets, 'viewInsets'),
      systemGestureInsets: resolve<DebugViewPadding>(
        systemGestureInsets,
        this.systemGestureInsets,
        'systemGestureInsets',
      ),
      alwaysUse24HourFormat: resolve<bool>(
        alwaysUse24HourFormat,
        this.alwaysUse24HourFormat,
        'alwaysUse24HourFormat',
      ),
      accessibleNavigation: resolve<bool>(
        accessibleNavigation,
        this.accessibleNavigation,
        'accessibleNavigation',
      ),
      invertColors: resolve<bool>(invertColors, this.invertColors, 'invertColors'),
      disableAnimations: resolve<bool>(
        disableAnimations,
        this.disableAnimations,
        'disableAnimations',
      ),
      boldText: resolve<bool>(boldText, this.boldText, 'boldText'),
      reduceMotion: resolve<bool>(reduceMotion, this.reduceMotion, 'reduceMotion'),
      highContrast: resolve<bool>(highContrast, this.highContrast, 'highContrast'),
      onOffSwitchLabels: resolve<bool>(
        onOffSwitchLabels,
        this.onOffSwitchLabels,
        'onOffSwitchLabels',
      ),
      supportsAnnounce: resolve<bool>(supportsAnnounce, this.supportsAnnounce, 'supportsAnnounce'),
      autoPlayAnimatedImages: resolve<bool>(
        autoPlayAnimatedImages,
        this.autoPlayAnimatedImages,
        'autoPlayAnimatedImages',
      ),
      autoPlayVideos: resolve<bool>(autoPlayVideos, this.autoPlayVideos, 'autoPlayVideos'),
      deterministicCursor: resolve<bool>(
        deterministicCursor,
        this.deterministicCursor,
        'deterministicCursor',
      ),
    );
    assert(result._debugAssertGeometryIsValid());
    return result;
  }

  /// Serializes this object to the wire format the
  /// `ext.flutter.viewMetricsOverride` service extension uses.
  ///
  /// Metrics that are not overridden are omitted from the result.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (devicePixelRatio != null) 'devicePixelRatio': devicePixelRatio,
      if (physicalSize != null)
        'physicalSize': <String, Object?>{
          'width': physicalSize!.width,
          'height': physicalSize!.height,
        },
      if (textScaleFactor != null) 'textScaleFactor': textScaleFactor,
      if (platformBrightness != null) 'platformBrightness': platformBrightness!.name,
      if (padding != null) 'padding': _viewPaddingToJson(padding!),
      if (viewPadding != null) 'viewPadding': _viewPaddingToJson(viewPadding!),
      if (viewInsets != null) 'viewInsets': _viewPaddingToJson(viewInsets!),
      if (systemGestureInsets != null)
        'systemGestureInsets': _viewPaddingToJson(systemGestureInsets!),
      if (alwaysUse24HourFormat != null) 'alwaysUse24HourFormat': alwaysUse24HourFormat,
      if (accessibleNavigation != null) 'accessibleNavigation': accessibleNavigation,
      if (invertColors != null) 'invertColors': invertColors,
      if (disableAnimations != null) 'disableAnimations': disableAnimations,
      if (boldText != null) 'boldText': boldText,
      if (reduceMotion != null) 'reduceMotion': reduceMotion,
      if (highContrast != null) 'highContrast': highContrast,
      if (onOffSwitchLabels != null) 'onOffSwitchLabels': onOffSwitchLabels,
      if (supportsAnnounce != null) 'supportsAnnounce': supportsAnnounce,
      if (autoPlayAnimatedImages != null) 'autoPlayAnimatedImages': autoPlayAnimatedImages,
      if (autoPlayVideos != null) 'autoPlayVideos': autoPlayVideos,
      if (deterministicCursor != null) 'deterministicCursor': deterministicCursor,
    };
  }

  // The metrics dart:ui delivers through PlatformDispatcher.onMetricsChanged.
  //
  // This grouping, `_accessibilityFeatures`, and the standalone `textScaleFactor`
  // and `platformBrightness` are what == and hashCode compare, and what decides
  // which platform notification an override change replays, so a metric that
  // reaches none of them is neither compared nor propagated. A record is used
  // so that adding a field without adding it here shows up as a completeness
  // guard failure rather than as a metric that only sometimes takes effect.
  (
    double?,
    ui.Size?,
    DebugViewPadding?,
    DebugViewPadding?,
    DebugViewPadding?,
    DebugViewPadding?,
    bool?,
  )
  get _viewMetrics => (
    devicePixelRatio,
    physicalSize,
    padding,
    viewPadding,
    viewInsets,
    systemGestureInsets,
    alwaysUse24HourFormat,
  );

  // Everything dart:ui keeps in its platform configuration — the metrics that
  // belong to the application rather than to one view, which it reports through
  // PlatformDispatcher.onPlatformConfigurationChanged as well as through the
  // callback for the field that changed, when that field has one.
  //
  // This grouping overlaps the others rather than partitioning with them: every
  // metric it names is also compared elsewhere. A metric added to
  // DebugViewMetricsOverride has to be classified here too, or the umbrella
  // notification silently never fires for it.
  (double?, ui.Brightness?, bool?, Object?) get _platformConfiguration =>
      (textScaleFactor, platformBrightness, alwaysUse24HourFormat, _accessibilityFeatures);

  // The flags dart:ui delivers through
  // PlatformDispatcher.onAccessibilityFeaturesChanged.
  (bool?, bool?, bool?, bool?, bool?, bool?, bool?, bool?, bool?, bool?, bool?)
  get _accessibilityFeatures => (
    accessibleNavigation,
    invertColors,
    disableAnimations,
    boldText,
    reduceMotion,
    highContrast,
    onOffSwitchLabels,
    supportsAnnounce,
    autoPlayAnimatedImages,
    autoPlayVideos,
    deterministicCursor,
  );

  static const (bool?, bool?, bool?, bool?, bool?, bool?, bool?, bool?, bool?, bool?, bool?)
  _emptyAccessibilityFeatures = (null, null, null, null, null, null, null, null, null, null, null);

  /// Whether any [ui.AccessibilityFeatures] are overridden by this instance.
  bool get hasAccessibilityFeatures => _accessibilityFeatures != _emptyAccessibilityFeatures;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is DebugViewMetricsOverride &&
        other._viewMetrics == _viewMetrics &&
        other.textScaleFactor == textScaleFactor &&
        other.platformBrightness == platformBrightness &&
        other._accessibilityFeatures == _accessibilityFeatures;
  }

  @override
  int get hashCode =>
      Object.hash(_viewMetrics, textScaleFactor, platformBrightness, _accessibilityFeatures);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('devicePixelRatio', devicePixelRatio, defaultValue: null));
    properties.add(DiagnosticsProperty<ui.Size>('physicalSize', physicalSize, defaultValue: null));
    properties.add(DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: null));
    properties.add(
      EnumProperty<ui.Brightness>('platformBrightness', platformBrightness, defaultValue: null),
    );
    properties.add(DiagnosticsProperty<DebugViewPadding>('padding', padding, defaultValue: null));
    properties.add(
      DiagnosticsProperty<DebugViewPadding>('viewPadding', viewPadding, defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<DebugViewPadding>('viewInsets', viewInsets, defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<DebugViewPadding>(
        'systemGestureInsets',
        systemGestureInsets,
        defaultValue: null,
      ),
    );
    _addFlag(properties, 'alwaysUse24HourFormat', alwaysUse24HourFormat);
    _addFlag(properties, 'accessibleNavigation', accessibleNavigation);
    _addFlag(properties, 'invertColors', invertColors);
    _addFlag(properties, 'disableAnimations', disableAnimations);
    _addFlag(properties, 'boldText', boldText);
    _addFlag(properties, 'reduceMotion', reduceMotion);
    _addFlag(properties, 'highContrast', highContrast);
    _addFlag(properties, 'onOffSwitchLabels', onOffSwitchLabels);
    _addFlag(properties, 'supportsAnnounce', supportsAnnounce);
    _addFlag(properties, 'autoPlayAnimatedImages', autoPlayAnimatedImages);
    _addFlag(properties, 'autoPlayVideos', autoPlayVideos);
    _addFlag(properties, 'deterministicCursor', deterministicCursor);
  }

  static void _addFlag(DiagnosticPropertiesBuilder properties, String name, bool? value) {
    // A null defaultValue, which FlagProperty already uses, is what keeps a
    // metric that is not overridden from being listed.
    properties.add(FlagProperty(name, value: value, ifTrue: name, ifFalse: 'not $name'));
  }

  // Every key [toJson] can emit and [fromJson] accepts. Anything else in an
  // incoming payload is a tooling mistake rather than a metric to ignore.
  static const Set<String> _jsonKeys = <String>{
    'devicePixelRatio',
    'physicalSize',
    'textScaleFactor',
    'platformBrightness',
    'padding',
    'viewPadding',
    'viewInsets',
    'systemGestureInsets',
    'alwaysUse24HourFormat',
    'accessibleNavigation',
    'invertColors',
    'disableAnimations',
    'boldText',
    'reduceMotion',
    'highContrast',
    'onOffSwitchLabels',
    'supportsAnnounce',
    'autoPlayAnimatedImages',
    'autoPlayVideos',
    'deterministicCursor',
  };

  static Map<String, Object?> _viewPaddingToJson(DebugViewPadding padding) {
    return <String, Object?>{
      'left': padding.left,
      'top': padding.top,
      'right': padding.right,
      'bottom': padding.bottom,
    };
  }

  static double? _doubleFromJson(Map<Object?, Object?> json, String key) {
    return switch (json[key]) {
      null => null,
      final num value => value.toDouble(),
      final Object value => throw FormatException('Expected a number for $key, got $value.'),
    };
  }

  static bool? _boolFromJson(Map<Object?, Object?> json, String key) {
    return switch (json[key]) {
      null => null,
      final bool value => value,
      final Object value => throw FormatException('Expected a boolean for $key, got $value.'),
    };
  }

  static ui.Size? _sizeFromJson(Map<Object?, Object?> json, String key) {
    final Object? value = _checkedMembers(json[key], key, const <String>{'width', 'height'});
    return switch (value) {
      null => null,
      {'width': final num width, 'height': final num height} => ui.Size(
        _checkedExtent(width, key, 'width'),
        _checkedExtent(height, key, 'height'),
      ),
      _ => throw FormatException('Expected {"width": num, "height": num} for $key, got $value.'),
    };
  }

  static DebugViewPadding? _viewPaddingFromJson(Map<Object?, Object?> json, String key) {
    const members = <String>{'left', 'top', 'right', 'bottom'};
    final Object? value = _checkedMembers(json[key], key, members);
    if (value == null) {
      return null;
    }
    if (value is! Map<Object?, Object?>) {
      throw FormatException(
        'Expected {"left": num, "top": num, "right": num, "bottom": num} for $key, got $value.',
      );
    }
    num? checkEdge(String edge) {
      final Object? edgeValue = value[edge];
      if (edgeValue == null) {
        return null;
      }
      if (edgeValue is! num) {
        throw FormatException('$key.$edge must be a number, got $edgeValue.');
      }
      return edgeValue;
    }

    final num? left = checkEdge('left');
    final num? top = checkEdge('top');
    final num? right = checkEdge('right');
    final num? bottom = checkEdge('bottom');
    return DebugViewPadding(
      left: left != null ? _checkedExtent(left, key, 'left') : 0.0,
      top: top != null ? _checkedExtent(top, key, 'top') : 0.0,
      right: right != null ? _checkedExtent(right, key, 'right') : 0.0,
      bottom: bottom != null ? _checkedExtent(bottom, key, 'bottom') : 0.0,
    );
  }

  /// Throws a [FlutterError] describing the first geometry this override sets
  /// that cannot be used as layout input.
  ///
  /// The constructor checks [devicePixelRatio] and [textScaleFactor], and
  /// [DebugViewPadding] asserts on its own edges, but [physicalSize] cannot be
  /// asserted in a `const` constructor because reading a field off a [ui.Size]
  /// is not a constant expression.
  /// [DebugViewMetricsOverride.fromJson] rejects them for values arriving from
  /// tooling, and [debugSetViewMetricsOverride] calls this for values built
  /// directly, so that a negative or non-finite size cannot reach layout as a
  /// tight [ui.ViewConstraints] or as NaN [MediaQueryData] geometry.
  ///
  /// Returns true so it can be used inside an `assert`.
  bool _debugAssertGeometryIsValid() {
    void checkExtent(double extent, String description) {
      if (!_isUsableExtent(extent)) {
        throw FlutterError(
          'DebugViewMetricsOverride.$description must be finite and non-negative, '
          'but was $extent.',
        );
      }
    }

    void checkPadding(DebugViewPadding? padding, String name) {
      if (padding == null) {
        return;
      }
      checkExtent(padding.left, '$name.left');
      checkExtent(padding.top, '$name.top');
      checkExtent(padding.right, '$name.right');
      checkExtent(padding.bottom, '$name.bottom');
    }

    if (physicalSize case final ui.Size size) {
      checkExtent(size.width, 'physicalSize.width');
      checkExtent(size.height, 'physicalSize.height');
    }
    checkPadding(padding, 'padding');
    checkPadding(viewPadding, 'viewPadding');
    checkPadding(viewInsets, 'viewInsets');
    checkPadding(systemGestureInsets, 'systemGestureInsets');
    return true;
  }

  // A nested object with an unrecognized member is a tooling mistake for the
  // same reason an unrecognized metric is: the value it was meant to carry is
  // silently not applied, and the call still reports success. Returns [value]
  // so that it can wrap the read.
  static Object? _checkedMembers(Object? value, String key, Set<String> members) {
    if (value is Map<Object?, Object?>) {
      final Iterable<Object?> unknown = value.keys.where((Object? k) => !members.contains(k));
      if (unknown.isNotEmpty) {
        throw FormatException(
          'Unknown member(s) of $key: ${unknown.join(', ')}. '
          'Supported members are: ${members.join(', ')}.',
        );
      }
    }
    return value;
  }

  static double _checkedExtent(num value, String key, String component) {
    final double extent = value.toDouble();
    if (!_isUsableExtent(extent)) {
      throw FormatException('$key.$component must be finite and non-negative, got $extent.');
    }
    return extent;
  }

  // What a size or inset component has to be for layout to be able to use it,
  // stated once so that the JSON boundary and the direct one accept the same
  // values. A negative or non-finite component would produce negative or NaN
  // geometry rather than an obviously wrong looking screen.
  static bool _isUsableExtent(double extent) => extent.isFinite && extent >= 0;
}

/// Debug-only view metric overrides, keyed by [ui.FlutterView.viewId].
///
/// Developer tooling installs entries here — normally through the
/// `ext.flutter.viewMetricsOverride` service extension rather than directly —
/// to make an application behave as though the platform reported different
/// settings. They are applied by the [ui.PlatformDispatcher]
/// [debugApplyViewMetricsOverrides] installs, which is what
/// [BindingBase.platformDispatcher] returns, so every part of the framework
/// that reads a view metric sees them.
///
/// This map is read-only. Changing an override has to tell the framework to
/// re-read the affected metrics, so use [debugSetViewMetricsOverride] and
/// [debugClearViewMetricsOverrides] instead; mutating the map directly throws
/// an [UnsupportedError] rather than silently leaving the application stale.
///
/// Entries survive a hot reload, which rebuilds the application against them,
/// and are lost on a hot restart, which starts the isolate over. Tooling that
/// wants an override to outlive a restart has to install it again.
///
/// A view that is removed while it has an override leaves its entry behind;
/// the entry becomes inert, and applies again if a view is later created with
/// the same [ui.FlutterView.viewId].
///
/// This map is always empty outside of debug mode (in profile or release mode).
Map<int, DebugViewMetricsOverride> get debugViewMetricsOverrides =>
    _unmodifiableViewMetricsOverrides;

final Map<int, DebugViewMetricsOverride> _viewMetricsOverrides = <int, DebugViewMetricsOverride>{};
final Map<int, DebugViewMetricsOverride> _unmodifiableViewMetricsOverrides =
    UnmodifiableMapView<int, DebugViewMetricsOverride>(_viewMetricsOverrides);

/// Registers [override] for the view with the given [viewId], replacing any
/// override already registered for it.
///
/// Passing null, or an override for which [DebugViewMetricsOverride.isEmpty] is
/// true, removes the entry.
///
/// Returns true if the registered override actually changed. Always returns
/// false, and does nothing, outside of debug mode (in profile or release mode).
///
/// The framework is told to re-read the metrics that changed, synchronously,
/// before this returns. Do not call this during a build: the service extension
/// that normally drives it runs on the event loop, outside the build phase.
///
/// Tests that call this must reset it before the test body ends, because
/// [debugAssertAllFoundationVarsUnset] treats a leftover override as a leaked
/// debug variable.
bool debugSetViewMetricsOverride(int viewId, DebugViewMetricsOverride? override) {
  var changed = false;
  assert(() {
    assert(override?._debugAssertGeometryIsValid() ?? true);
    final DebugViewMetricsOverride? previous = _viewMetricsOverrides[viewId];
    final DebugViewMetricsOverride? next = override == null || override.isEmpty ? null : override;
    if (previous == next) {
      return true;
    }
    if (next == null) {
      _viewMetricsOverrides.remove(viewId);
    } else {
      _viewMetricsOverrides[viewId] = next;
    }
    changed = true;
    _debugReplayPlatformNotifications(<(DebugViewMetricsOverride?, DebugViewMetricsOverride?)>[
      (previous, next),
    ]);
    return true;
  }());
  return changed;
}

/// Removes every entry from [debugViewMetricsOverrides].
///
/// Returns true if anything was removed. Always returns false, and does
/// nothing, outside of debug mode (in profile or release mode).
bool debugClearViewMetricsOverrides() {
  var changed = false;
  assert(() {
    if (_viewMetricsOverrides.isEmpty) {
      return true;
    }
    final removed = <(DebugViewMetricsOverride?, DebugViewMetricsOverride?)>[
      for (final DebugViewMetricsOverride override in _viewMetricsOverrides.values)
        (override, null),
    ];
    _viewMetricsOverrides.clear();
    changed = true;
    _debugReplayPlatformNotifications(removed);
    return true;
  }());
  return changed;
}

// Tells the framework that the metrics which differ between [before] and
// [after] changed, by invoking the dart:ui callbacks that deliver them.
//
// An override change is, from the framework's point of view, exactly what a
// platform settings change is: the values it reads from dart:ui are now
// different. Replaying the platform's own notifications is therefore not a lie,
// and it means overrides get the same handling real changes do —
// RendererBinding.handleMetricsChanged rebuilds every ViewConfiguration,
// SemanticsBinding re-reads its cached AccessibilityFeatures, and every
// WidgetsBindingObserver is notified — with no code in those paths that knows
// about overrides at all.
//
// The callbacks are invoked on every dispatcher an override applies to rather
// than on ui.PlatformDispatcher.instance, because a binding that supplies its
// own dispatcher registers the framework's callbacks on that one, and each runs
// in the zone it was registered in; see
// [debugReplayViewMetricsNotifications], which owns both.
//
// Only the notifications whose metrics actually changed are replayed, so that
// toggling an accessibility flag does not tell the application its window
// changed size. alwaysUse24HourFormat is the exception: dart:ui has no
// dedicated callback for it, and onMetricsChanged is the only notification the
// framework treats as "re-read everything about this view".
void _debugReplayPlatformNotifications(
  Iterable<(DebugViewMetricsOverride?, DebugViewMetricsOverride?)> changes,
) {
  var viewMetrics = false;
  var textScaleFactor = false;
  var platformBrightness = false;
  var accessibilityFeatures = false;
  var platformConfiguration = false;
  for (final (DebugViewMetricsOverride? previous, DebugViewMetricsOverride? next) in changes) {
    // No override at all and an override that leaves a group alone report the
    // same metrics, so a missing override is compared as the empty one.
    // Comparing null against an all-null group would report every group as
    // changed whenever any override is installed or removed.
    final DebugViewMetricsOverride before = previous ?? const DebugViewMetricsOverride();
    final DebugViewMetricsOverride after = next ?? const DebugViewMetricsOverride();
    viewMetrics = viewMetrics || before._viewMetrics != after._viewMetrics;
    textScaleFactor = textScaleFactor || before.textScaleFactor != after.textScaleFactor;
    platformBrightness =
        platformBrightness || before.platformBrightness != after.platformBrightness;
    accessibilityFeatures =
        accessibilityFeatures || before._accessibilityFeatures != after._accessibilityFeatures;
    // Reported once, and before the callback for the field that changed, the
    // way dart:ui reports it. A consumer that listens to the umbrella
    // notification rather than to the narrower ones — and alwaysUse24HourFormat
    // has no narrower one at all — has to hear about an override too.
    platformConfiguration =
        platformConfiguration || before._platformConfiguration != after._platformConfiguration;
  }
  debugReplayViewMetricsNotifications(
    platformConfiguration: platformConfiguration,
    textScaleFactor: textScaleFactor,
    platformBrightness: platformBrightness,
    accessibilityFeatures: accessibilityFeatures,
    viewMetrics: viewMetrics,
  );
}

class _Omitted {
  const _Omitted();
}

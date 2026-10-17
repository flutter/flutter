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
///
/// @docImport 'binding.dart';
/// @docImport 'service_extensions.dart';
library;

import 'dart:collection';
import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:meta/meta.dart';

import 'assertions.dart';
import 'collections.dart';
import 'diagnostics.dart';
import 'memory_allocations.dart';
import 'platform.dart';
import 'print.dart';

export 'dart:ui' show Brightness;

export 'print.dart' show DebugPrintCallback;

// Examples can assume:
// late DebugViewMetricsOverride metricsOverride;

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

/// Debug-only overrides for the view metrics of a single [ui.FlutterView].
///
/// View metrics are platform-level settings that influence how an application
/// is presented, such as how text is scaled, whether bold text is requested,
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
/// An override changes what the framework is told about the platform, not the
/// platform itself, so content the engine composites rather than the framework,
/// such as platform views and system UI, is unaffected. Direct reads from
/// [ui.PlatformDispatcher.instance] also continue to report the real platform
/// metrics.
///
/// All values are in the units `dart:ui` uses, which for [physicalSize] and the
/// paddings means physical pixels rather than the logical pixels
/// [MediaQueryData] reports.
///
/// This class has no effect outside of debug mode (in profile or release mode).
///
/// ## How overrides are applied
///
/// In debug mode, [BindingBase.platformDispatcher] is
/// [ui.PlatformDispatcher.instance] wrapped by [debugApplyViewMetricsOverrides],
/// so that it and the [ui.FlutterView]s it reports apply the entry registered
/// for each view, and registering or removing an entry invokes the `dart:ui`
/// callbacks that announce the metrics it changed —
/// [ui.PlatformDispatcher.onMetricsChanged] and its siblings — the way the
/// platform would. Everything the framework reads through the binding, from
/// [MediaQueryData.fromView] and the [RenderView]'s [ViewConfiguration] to
/// pointer coordinate conversion and [SemanticsBinding.accessibilityFeatures],
/// therefore sees the overridden values and re-reads them when they change.
/// [RenderView], [View] and [MediaQueryData.fromView] normalize a view they
/// are handed with [debugViewWithMetricsOverrides], so a view read straight
/// from `dart:ui` is treated the same way.
///
/// An override does not take precedence over values an application supplies
/// itself, such as the data of an ancestor [MediaQuery], nor over values a
/// test sets explicitly on a [TestFlutterView] or [TestPlatformDispatcher].
///
/// The platform-wide metrics — [textScaling], [platformBrightness],
/// [alwaysUse24HourFormat] and the accessibility flags — are resolved per view
/// when read through a view's [ui.FlutterView.platformDispatcher], and from
/// the implicit view's entry when read off the binding's dispatcher, which has
/// no view of its own. A consumer that reads them there, such as
/// [SemanticsBinding], therefore follows the implicit view however many views
/// there are.
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
  ///
  /// [physicalSize] and the paddings must have finite, non-negative extents,
  /// and [textScaling] has the requirements described on it, but a `const`
  /// constructor cannot inspect a [ui.Size], a [ui.ViewPadding] or a [List],
  /// so those are checked by [DebugViewMetricsOverride.fromJson] and
  /// [debugSetViewMetricsOverride] instead.
  const DebugViewMetricsOverride({
    this.devicePixelRatio,
    this.physicalSize,
    this.textScaling,
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
       );

  /// Creates a set of view metric overrides from the wire format [toJson]
  /// produces.
  ///
  /// Keys that are absent are treated as "not overridden". A key that is
  /// present but of an unexpected type, out of range, or not recognized at all
  /// throws a [FormatException], so that a tooling mistake surfaces at the
  /// service extension boundary instead of as a metric that silently failed to
  /// apply.
  ///
  /// [textScaling] is a list of `[unscaled, scaled]` number pairs, such as
  /// `[[8, 16], [100, 100]]`.
  ///
  /// [platformBrightness] is `'light'` or `'dark'`. `'Brightness.light'` and
  /// `'Brightness.dark'`, the spelling
  /// [FoundationServiceExtensions.brightnessOverride] uses, are accepted too.
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
      textScaling: _textScalingFromJson(json, 'textScaling'),
      platformBrightness: switch (json['platformBrightness']) {
        null => null,
        'light' || 'Brightness.light' => ui.Brightness.light,
        'dark' || 'Brightness.dark' => ui.Brightness.dark,
        final Object? value => throw FormatException(
          'Expected "light" or "dark" for platformBrightness, got $value.',
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
  ///
  /// The scene is still composited into the surface the platform provides,
  /// anchored at its top left and clipped by it: the engine discards a frame
  /// of any other size, so the overridden size is not passed on to
  /// [ui.FlutterView.render]. Tooling that presents an overridden size
  /// therefore either shows it as a preview region inside the real surface or
  /// clamps it to the real size.
  final ui.Size? physicalSize;

  /// Overrides [ui.PlatformDispatcher.scaleFontSize] and
  /// [ui.PlatformDispatcher.textScaleFactor].
  ///
  /// Each point maps an unscaled font size, its [ui.Offset.dx], to the size it
  /// is scaled to, its [ui.Offset.dy], both in logical pixels. A font size
  /// between two points is interpolated linearly between them, and one outside
  /// the points is scaled by the ratio of the nearest point, which is how
  /// Android applies its non-linear font scaling tables.
  /// [ui.PlatformDispatcher.textScaleFactor] then reports the ratio of the
  /// first point, `dy / dx`.
  ///
  /// A single point therefore scales every font size linearly:
  /// `<ui.Offset>[ui.Offset(1, 2)]` doubles them all.
  ///
  /// The unscaled sizes must be finite, greater than zero and increasing, and
  /// the scaled sizes finite, non-negative and non-decreasing.
  final List<ui.Offset>? textScaling;

  /// Overrides [ui.PlatformDispatcher.platformBrightness].
  ///
  /// Unlike [debugBrightnessOverride], which replaces the brightness of every
  /// view, this applies only to the view it is registered for.
  final ui.Brightness? platformBrightness;

  /// Overrides [ui.FlutterView.padding], in physical pixels.
  ///
  /// [ui.ViewPadding] has no public constructor, so a value for this and the
  /// other paddings comes from [DebugViewMetricsOverride.fromJson] or from an
  /// implementation of the interface, such as `FakeViewPadding` in
  /// `flutter_test`.
  final ui.ViewPadding? padding;

  /// Overrides [ui.FlutterView.viewPadding], in physical pixels.
  final ui.ViewPadding? viewPadding;

  /// Overrides [ui.FlutterView.viewInsets], in physical pixels.
  ///
  /// This is what an on-screen keyboard occupies, so overriding it exercises
  /// the layout an application adopts while the keyboard is up without a
  /// keyboard being up.
  final ui.ViewPadding? viewInsets;

  /// Overrides [ui.FlutterView.systemGestureInsets], in physical pixels.
  final ui.ViewPadding? systemGestureInsets;

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
  /// [MediaQueryData.disableAnimations] follows the view the [MediaQuery] was
  /// built from. [AnimationController] and the rest of the framework consult
  /// [SemanticsBinding.disableAnimations] instead, which is read off the
  /// binding's dispatcher and so follows the implicit view's entry whichever
  /// view the animation is in.
  final bool? disableAnimations;

  /// Overrides [ui.AccessibilityFeatures.boldText].
  final bool? boldText;

  /// Overrides [ui.AccessibilityFeatures.reduceMotion].
  ///
  /// This is a separate platform setting from [disableAnimations], so
  /// overriding one does not imply the other.
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

  /// Whether this instance overrides at least one metric.
  bool get isNotEmpty => !isEmpty;

  // Whether at least one flag of [ui.AccessibilityFeatures] is overridden, so
  // that the platform's own object is reported when none is.
  bool get _overridesAccessibilityFeatures =>
      _accessibilityFeatures != const DebugViewMetricsOverride()._accessibilityFeatures;

  /// Creates a copy of this object with the given metrics replaced.
  ///
  /// A null argument leaves the corresponding metric as this object has it,
  /// which is the ordinary `copyWith` rule. A null field already means "not
  /// overridden", so giving up an override is a different request rather than
  /// the same one spelled with a null: name the metric in [clear].
  ///
  /// Passing a value for a metric that is also named in [clear] is a
  /// contradiction, and asserts.
  ///
  /// {@tool snippet}
  /// This stops overriding text scaling while leaving every other metric of
  /// `metricsOverride` in place:
  ///
  /// ```dart
  /// metricsOverride.copyWith(
  ///   clear: <DebugViewMetric>{DebugViewMetric.textScaling},
  /// );
  /// ```
  /// {@end-tool}
  DebugViewMetricsOverride copyWith({
    double? devicePixelRatio,
    ui.Size? physicalSize,
    List<ui.Offset>? textScaling,
    ui.Brightness? platformBrightness,
    ui.ViewPadding? padding,
    ui.ViewPadding? viewPadding,
    ui.ViewPadding? viewInsets,
    ui.ViewPadding? systemGestureInsets,
    bool? alwaysUse24HourFormat,
    bool? accessibleNavigation,
    bool? invertColors,
    bool? disableAnimations,
    bool? boldText,
    bool? reduceMotion,
    bool? highContrast,
    bool? onOffSwitchLabels,
    bool? supportsAnnounce,
    bool? autoPlayAnimatedImages,
    bool? autoPlayVideos,
    bool? deterministicCursor,
    Set<DebugViewMetric> clear = const <DebugViewMetric>{},
  }) {
    T? resolve<T>(DebugViewMetric metric, T? value, T? current) {
      final bool cleared = clear.contains(metric);
      assert(
        !cleared || value == null,
        'DebugViewMetricsOverride.copyWith was asked both to set ${metric.name} '
        'and to clear it.',
      );
      return cleared ? null : (value ?? current);
    }

    final result = DebugViewMetricsOverride(
      devicePixelRatio: resolve(
        DebugViewMetric.devicePixelRatio,
        devicePixelRatio,
        this.devicePixelRatio,
      ),
      physicalSize: resolve(DebugViewMetric.physicalSize, physicalSize, this.physicalSize),
      textScaling: resolve(DebugViewMetric.textScaling, textScaling, this.textScaling),
      platformBrightness: resolve(
        DebugViewMetric.platformBrightness,
        platformBrightness,
        this.platformBrightness,
      ),
      padding: resolve(DebugViewMetric.padding, padding, this.padding),
      viewPadding: resolve(DebugViewMetric.viewPadding, viewPadding, this.viewPadding),
      viewInsets: resolve(DebugViewMetric.viewInsets, viewInsets, this.viewInsets),
      systemGestureInsets: resolve(
        DebugViewMetric.systemGestureInsets,
        systemGestureInsets,
        this.systemGestureInsets,
      ),
      alwaysUse24HourFormat: resolve(
        DebugViewMetric.alwaysUse24HourFormat,
        alwaysUse24HourFormat,
        this.alwaysUse24HourFormat,
      ),
      accessibleNavigation: resolve(
        DebugViewMetric.accessibleNavigation,
        accessibleNavigation,
        this.accessibleNavigation,
      ),
      invertColors: resolve(DebugViewMetric.invertColors, invertColors, this.invertColors),
      disableAnimations: resolve(
        DebugViewMetric.disableAnimations,
        disableAnimations,
        this.disableAnimations,
      ),
      boldText: resolve(DebugViewMetric.boldText, boldText, this.boldText),
      reduceMotion: resolve(DebugViewMetric.reduceMotion, reduceMotion, this.reduceMotion),
      highContrast: resolve(DebugViewMetric.highContrast, highContrast, this.highContrast),
      onOffSwitchLabels: resolve(
        DebugViewMetric.onOffSwitchLabels,
        onOffSwitchLabels,
        this.onOffSwitchLabels,
      ),
      supportsAnnounce: resolve(
        DebugViewMetric.supportsAnnounce,
        supportsAnnounce,
        this.supportsAnnounce,
      ),
      autoPlayAnimatedImages: resolve(
        DebugViewMetric.autoPlayAnimatedImages,
        autoPlayAnimatedImages,
        this.autoPlayAnimatedImages,
      ),
      autoPlayVideos: resolve(DebugViewMetric.autoPlayVideos, autoPlayVideos, this.autoPlayVideos),
      deterministicCursor: resolve(
        DebugViewMetric.deterministicCursor,
        deterministicCursor,
        this.deterministicCursor,
      ),
    );
    assert(result._debugAssertIsValid());
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
      if (textScaling != null)
        'textScaling': <List<double>>[
          for (final ui.Offset point in textScaling!) <double>[point.dx, point.dy],
        ],
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

  // The metrics dart:ui delivers through PlatformDispatcher.onMetricsChanged,
  // plus alwaysUse24HourFormat, which dart:ui reports through
  // PlatformDispatcher.onPlatformConfigurationChanged because it has no
  // callback of its own.
  //
  // This grouping, `_accessibilityFeatures`, and the standalone `textScaling`
  // and `platformBrightness` are what == and hashCode compare, so a metric that
  // reaches none of them is never compared. A record is used so that adding a
  // field without adding it here shows up as a completeness guard failure
  // rather than as a metric that only sometimes takes effect. The paddings are
  // reduced to their edges because ui.ViewPadding has no == of its own.
  (double?, ui.Size?, _Edges?, _Edges?, _Edges?, _Edges?, bool?) get _viewMetrics => (
    devicePixelRatio,
    physicalSize,
    _edges(padding),
    _edges(viewPadding),
    _edges(viewInsets),
    _edges(systemGestureInsets),
    alwaysUse24HourFormat,
  );

  static _Edges? _edges(ui.ViewPadding? padding) =>
      padding == null ? null : (padding.left, padding.top, padding.right, padding.bottom);

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is DebugViewMetricsOverride &&
        other._viewMetrics == _viewMetrics &&
        listEquals(other.textScaling, textScaling) &&
        other.platformBrightness == platformBrightness &&
        other._accessibilityFeatures == _accessibilityFeatures;
  }

  @override
  int get hashCode => Object.hash(
    _viewMetrics,
    textScaling == null ? null : Object.hashAll(textScaling!),
    platformBrightness,
    _accessibilityFeatures,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('devicePixelRatio', devicePixelRatio, defaultValue: null));
    properties.add(DiagnosticsProperty<ui.Size>('physicalSize', physicalSize, defaultValue: null));
    properties.add(IterableProperty<ui.Offset>('textScaling', textScaling, defaultValue: null));
    properties.add(
      EnumProperty<ui.Brightness>('platformBrightness', platformBrightness, defaultValue: null),
    );
    properties.add(DiagnosticsProperty<ui.ViewPadding>('padding', padding, defaultValue: null));
    properties.add(
      DiagnosticsProperty<ui.ViewPadding>('viewPadding', viewPadding, defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<ui.ViewPadding>('viewInsets', viewInsets, defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<ui.ViewPadding>(
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

  // Every key [toJson] can emit and [fromJson] accepts, which is exactly the
  // set of metrics there are: deriving it from [DebugViewMetric] keeps a metric
  // from being added without the wire format learning about it. Anything else
  // in an incoming payload is a tooling mistake rather than a metric to ignore.
  static final Set<String> _jsonKeys = <String>{
    for (final DebugViewMetric metric in DebugViewMetric.values) metric.name,
  };

  static Map<String, Object?> _viewPaddingToJson(ui.ViewPadding padding) {
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

  static ui.ViewPadding? _viewPaddingFromJson(Map<Object?, Object?> json, String key) {
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
    double edgeExtent(String edge) {
      return switch (value[edge]) {
        null => 0.0,
        final num extent => _checkedExtent(extent, key, edge),
        final Object other => throw FormatException('$key.$edge must be a number, got $other.'),
      };
    }

    return _ViewPadding(
      left: edgeExtent('left'),
      top: edgeExtent('top'),
      right: edgeExtent('right'),
      bottom: edgeExtent('bottom'),
    );
  }

  static List<ui.Offset>? _textScalingFromJson(Map<Object?, Object?> json, String key) {
    final Object? value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! List<Object?>) {
      throw FormatException('Expected a list of [unscaled, scaled] pairs for $key, got $value.');
    }
    final points = <ui.Offset>[
      for (final Object? point in value)
        switch (point) {
          [final num unscaled, final num scaled] => ui.Offset(
            unscaled.toDouble(),
            scaled.toDouble(),
          ),
          _ => throw FormatException(
            'Expected [unscaled, scaled] number pairs in $key, got $point.',
          ),
        },
    ];
    if (_textScalingProblem(points) case final String problem) {
      throw FormatException('$key $problem.');
    }
    return points;
  }

  /// Throws a [FlutterError] describing the first value this override sets
  /// that cannot be applied.
  ///
  /// The constructor checks [devicePixelRatio], but [physicalSize], the
  /// paddings and [textScaling] cannot be asserted in a `const` constructor
  /// because reading a field off a [ui.Size] or a [ui.ViewPadding], or an
  /// element of a [List], is not a constant expression.
  /// [DebugViewMetricsOverride.fromJson] rejects them for values arriving from
  /// tooling, and [debugSetViewMetricsOverride] calls this for values built
  /// directly, so that a negative or non-finite size cannot reach layout as a
  /// tight [ui.ViewConstraints] or as NaN [MediaQueryData] geometry, and a
  /// table that cannot be interpolated cannot reach text layout.
  ///
  /// Returns true so it can be used inside an `assert`.
  bool _debugAssertIsValid() {
    void checkExtent(double extent, String description) {
      if (!_isUsableExtent(extent)) {
        throw FlutterError(
          'DebugViewMetricsOverride.$description must be finite and non-negative, '
          'but was $extent.',
        );
      }
    }

    void checkPadding(ui.ViewPadding? padding, String name) {
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
    if (textScaling case final List<ui.Offset> points) {
      if (_textScalingProblem(points) case final String problem) {
        throw FlutterError('DebugViewMetricsOverride.textScaling $problem.');
      }
    }
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

  // What is wrong with [points] as a value for [textScaling], or null if
  // nothing is, stated once so that the JSON boundary and the direct one accept
  // the same tables: the ones that interpolate every font size to a finite,
  // non-negative one that does not shrink as the input grows, and whose first
  // point yields a finite scale factor.
  static String? _textScalingProblem(List<ui.Offset> points) {
    if (points.isEmpty) {
      return 'must have at least one point';
    }
    for (var i = 0; i < points.length; i += 1) {
      final ui.Offset point = points[i];
      if (!point.dx.isFinite || point.dx <= 0) {
        return 'must have finite, positive unscaled font sizes, but point $i is $point';
      }
      if (!_isUsableExtent(point.dy)) {
        return 'must have finite, non-negative scaled font sizes, but point $i is $point';
      }
      if (i > 0 && point.dx <= points[i - 1].dx) {
        return 'must have increasing unscaled font sizes, '
            'but point $i is $point after ${points[i - 1]}';
      }
      if (i > 0 && point.dy < points[i - 1].dy) {
        return 'must have non-decreasing scaled font sizes, '
            'but point $i is $point after ${points[i - 1]}';
      }
    }
    return null;
  }
}

/// Debug-only view metric overrides, keyed by [ui.FlutterView.viewId].
///
/// Developer tooling installs entries here — normally through the
/// `ext.flutter.viewMetricsOverride` service extension rather than directly —
/// to make an application behave as though the platform reported different
/// settings.
///
/// This map is read-only. Use [debugSetViewMetricsOverride] and
/// [debugClearViewMetricsOverrides] to change it; mutating the map directly
/// throws an [UnsupportedError].
///
/// Entries survive a hot reload, and are lost on a hot restart, which starts
/// the isolate over. Tooling that wants an override to outlive a restart has to
/// install it again.
///
/// A view that is removed while it has an override leaves its entry behind.
/// Entries are keyed by view ID alone, so the entry matches again if a view is
/// later created with the same [ui.FlutterView.viewId].
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
/// Tests that call this must reset it before the test body ends, because
/// [debugAssertAllFoundationVarsUnset] treats a leftover override as a leaked
/// debug variable.
bool debugSetViewMetricsOverride(int viewId, DebugViewMetricsOverride? override) {
  var changed = false;
  assert(() {
    assert(viewId >= 0, 'viewId must be non-negative, got $viewId.');
    assert(override?._debugAssertIsValid() ?? true);
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
    _debugNotifyViewMetricsOverrideChanged(
      previous ?? const DebugViewMetricsOverride(),
      next ?? const DebugViewMetricsOverride(),
    );
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
    final List<DebugViewMetricsOverride> removed = _viewMetricsOverrides.values.toList();
    _viewMetricsOverrides.clear();
    changed = true;
    for (final override in removed) {
      _debugNotifyViewMetricsOverrideChanged(override, const DebugViewMetricsOverride());
    }
    return true;
  }());
  return changed;
}

/// Wraps [dispatcher] so that it and the [ui.FlutterView]s it reports apply
/// the entries of [debugViewMetricsOverrides].
///
/// [BindingBase.platformDispatcher] applies this to
/// [ui.PlatformDispatcher.instance], which is what makes overrides visible to
/// the framework; see [DebugViewMetricsOverride]. A binding that overrides
/// that getter to supply a different dispatcher should wrap it the same way,
/// or overrides never reach the framework running on it. A change of an
/// override is announced through the callbacks registered on every dispatcher
/// wrapped this way.
///
/// Returns the same wrapper every time it is called with the same
/// [dispatcher], so that the views it reports keep a stable identity, and
/// returns a wrapper itself unchanged. Returns [dispatcher] itself outside of
/// debug mode (in profile or release mode).
ui.PlatformDispatcher debugApplyViewMetricsOverrides(ui.PlatformDispatcher dispatcher) {
  var result = dispatcher;
  assert(() {
    result = _debugWrapDispatcher(dispatcher);
    return true;
  }());
  return result;
}

/// Returns the [ui.FlutterView] that applies the [debugViewMetricsOverrides]
/// entry registered for [view]'s id.
///
/// A view read straight from a wrapped [ui.PlatformDispatcher] — from
/// [ui.PlatformDispatcher.instance] rather than from
/// [BindingBase.platformDispatcher] — reports the metrics the platform
/// reports. [RenderView], [View] and [MediaQueryData.fromView] pass the view
/// they are handed through this, so that such a view renders and reports the
/// same override as one read from the binding.
///
/// Engine views are normalized even before the binding wraps their
/// dispatcher, because a [View] can be constructed before [runWidget]. A view
/// that already applies its override, a view of a dispatcher that was never
/// wrapped (a [TestFlutterView], say, which applies its own test values over
/// the wrapper), and a view that reports no dispatcher or id at all are
/// returned unchanged, as is every view outside of debug mode (in profile or
/// release mode).
ui.FlutterView debugViewWithMetricsOverrides(ui.FlutterView view) {
  var result = view;
  assert(() {
    if (view is _DebugViewMetricsFlutterView) {
      return true;
    }
    final ui.PlatformDispatcher? dispatcher = _debugIfImplemented(() => view.platformDispatcher)
        ?.$1;
    final int? viewId = _debugIfImplemented(() => view.viewId)?.$1;
    if (dispatcher == null || viewId == null) {
      return true;
    }
    // The engine's dispatcher is wrapped on demand, so that a View constructed
    // before the binding ends up with the view the binding vends later. Any
    // other dispatcher has to have been wrapped already: a view of a dispatcher
    // nobody wrapped is one nobody asked to apply overrides.
    if (identical(dispatcher, ui.PlatformDispatcher.instance)) {
      _debugWrapDispatcher(dispatcher);
    }
    if (_debugDispatcherWrappers[dispatcher] != null) {
      result = _debugWrapView(view);
    }
    return true;
  }());
  return result;
}

// Reads one member of a dart:ui object that an incomplete test double may not
// implement, and reports "not implemented" as null. The value comes back in a
// one-element record so that a member whose own type is nullable can still be
// told apart from an absent one. A rendering-layer double can omit `viewId` or
// `platformDispatcher`: `Fake` answers with an UnimplementedError, a
// noSuchMethod of the double's own with a NoSuchMethodError. [read] must do
// nothing but read the member, or its own failures would be misattributed.
(T,)? _debugIfImplemented<T>(T Function() read) {
  try {
    return (read(),);
  } on NoSuchMethodError {
    return null;
  } on UnimplementedError {
    return null;
  }
}

// Invokes the dart:ui callbacks that announce the metrics that differ between
// [before] and [after] on every wrapped dispatcher, so that the framework
// re-reads them as it would after a platform change: the platform
// configuration first when a platform-wide setting changed, then the callback
// of each group that changed, in the order dart:ui uses. alwaysUse24HourFormat
// has no callback of its own and rides onMetricsChanged, the one notification
// the framework treats as "re-read everything about this view".
//
// Like the engine, this does not let one callback's failure cancel the ones
// after it, or the framework would be left reading a metric it was never told
// to re-read. The callbacks run in the caller's zone, as they do when a
// TestPlatformDispatcher test value is set.
@pragma('vm:notify-debugger-on-exception')
void _debugNotifyViewMetricsOverrideChanged(
  DebugViewMetricsOverride before,
  DebugViewMetricsOverride after,
) {
  final bool textScaling = !listEquals(before.textScaling, after.textScaling);
  final platformBrightness = before.platformBrightness != after.platformBrightness;
  final accessibilityFeatures = before._accessibilityFeatures != after._accessibilityFeatures;
  final bool platformConfiguration =
      textScaling ||
      platformBrightness ||
      accessibilityFeatures ||
      before.alwaysUse24HourFormat != after.alwaysUse24HourFormat;
  final callbacks = <ui.VoidCallback? Function(ui.PlatformDispatcher)>[
    if (platformConfiguration) (ui.PlatformDispatcher d) => d.onPlatformConfigurationChanged,
    if (textScaling) (ui.PlatformDispatcher d) => d.onTextScaleFactorChanged,
    if (platformBrightness) (ui.PlatformDispatcher d) => d.onPlatformBrightnessChanged,
    if (accessibilityFeatures) (ui.PlatformDispatcher d) => d.onAccessibilityFeaturesChanged,
    if (before._viewMetrics != after._viewMetrics) (ui.PlatformDispatcher d) => d.onMetricsChanged,
  ];
  // Iterated over a copy, because a callback is free to wrap another dispatcher.
  for (final WeakReference<_DebugViewMetricsPlatformDispatcher> reference
      in _debugWrappedDispatchers.toList()) {
    final ui.PlatformDispatcher? dispatcher = reference.target?._dispatcher;
    if (dispatcher == null) {
      continue;
    }
    for (final read in callbacks) {
      try {
        read(dispatcher)?.call();
      } catch (exception, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'foundation library',
            context: ErrorDescription('while announcing a change of a view metrics override'),
          ),
        );
      }
    }
  }
}

/// A view metric a [DebugViewMetricsOverride] can override.
///
/// Names the metrics [DebugViewMetricsOverride.copyWith] can be asked to stop
/// overriding, and supplies the set of keys the wire format
/// [DebugViewMetricsOverride.toJson] produces and
/// [DebugViewMetricsOverride.fromJson] accepts, so that the accepted keys are
/// not a second list to keep in step with this one.
///
/// A metric added here still has to be added to the fields, to `copyWith`, to
/// `toJson` and to `fromJson` by hand.
enum DebugViewMetric {
  /// Names [DebugViewMetricsOverride.devicePixelRatio].
  devicePixelRatio,

  /// Names [DebugViewMetricsOverride.physicalSize].
  physicalSize,

  /// Names [DebugViewMetricsOverride.textScaling].
  textScaling,

  /// Names [DebugViewMetricsOverride.platformBrightness].
  platformBrightness,

  /// Names [DebugViewMetricsOverride.padding].
  padding,

  /// Names [DebugViewMetricsOverride.viewPadding].
  viewPadding,

  /// Names [DebugViewMetricsOverride.viewInsets].
  viewInsets,

  /// Names [DebugViewMetricsOverride.systemGestureInsets].
  systemGestureInsets,

  /// Names [DebugViewMetricsOverride.alwaysUse24HourFormat].
  alwaysUse24HourFormat,

  /// Names [DebugViewMetricsOverride.accessibleNavigation].
  accessibleNavigation,

  /// Names [DebugViewMetricsOverride.invertColors].
  invertColors,

  /// Names [DebugViewMetricsOverride.disableAnimations].
  disableAnimations,

  /// Names [DebugViewMetricsOverride.boldText].
  boldText,

  /// Names [DebugViewMetricsOverride.reduceMotion].
  reduceMotion,

  /// Names [DebugViewMetricsOverride.highContrast].
  highContrast,

  /// Names [DebugViewMetricsOverride.onOffSwitchLabels].
  onOffSwitchLabels,

  /// Names [DebugViewMetricsOverride.supportsAnnounce].
  supportsAnnounce,

  /// Names [DebugViewMetricsOverride.autoPlayAnimatedImages].
  autoPlayAnimatedImages,

  /// Names [DebugViewMetricsOverride.autoPlayVideos].
  autoPlayVideos,

  /// Names [DebugViewMetricsOverride.deterministicCursor].
  deterministicCursor,
}

// The edges of a [ui.ViewPadding], which has no == of its own, as left, top,
// right, bottom.
typedef _Edges = (double, double, double, double);

// What [DebugViewMetricsOverride.fromJson] builds for the paddings, because
// [ui.ViewPadding] cannot be constructed outside `dart:ui`.
class _ViewPadding implements ui.ViewPadding {
  const _ViewPadding({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  @override
  final double left;

  @override
  final double top;

  @override
  final double right;

  @override
  final double bottom;

  @override
  String toString() => 'ViewPadding(left: $left, top: $top, right: $right, bottom: $bottom)';
}

// The wrapper of each wrapped dispatcher, keyed by the dispatcher so that the
// wrapper cannot outlive it. An Expando cannot be enumerated, so the wrappers
// are also kept in a list, weakly, because every one of them is told when an
// override changes; dead references are pruned whenever one is added, which
// bounds the list by the number of live wrappers plus the ones that died since.
final Expando<_DebugViewMetricsPlatformDispatcher> _debugDispatcherWrappers =
    Expando<_DebugViewMetricsPlatformDispatcher>();
final List<WeakReference<_DebugViewMetricsPlatformDispatcher>> _debugWrappedDispatchers =
    <WeakReference<_DebugViewMetricsPlatformDispatcher>>[];

_DebugViewMetricsPlatformDispatcher _debugWrapDispatcher(ui.PlatformDispatcher dispatcher) {
  if (dispatcher is _DebugViewMetricsPlatformDispatcher) {
    return dispatcher;
  }
  _DebugViewMetricsPlatformDispatcher? wrapper = _debugDispatcherWrappers[dispatcher];
  if (wrapper == null) {
    wrapper = _DebugViewMetricsPlatformDispatcher(dispatcher);
    _debugDispatcherWrappers[dispatcher] = wrapper;
    _debugWrappedDispatchers
      ..removeWhere(
        (WeakReference<_DebugViewMetricsPlatformDispatcher> reference) => reference.target == null,
      )
      ..add(WeakReference<_DebugViewMetricsPlatformDispatcher>(wrapper));
  }
  return wrapper;
}

// Keyed by the engine view so that repeated reads return the same wrapper: the
// framework compares views by identity.
final Expando<_DebugViewMetricsFlutterView> _debugViewMetricsViews =
    Expando<_DebugViewMetricsFlutterView>();

_DebugViewMetricsFlutterView _debugWrapView(ui.FlutterView view) =>
    _debugViewMetricsViews[view] ??= _DebugViewMetricsFlutterView(view);

// A [ui.PlatformDispatcher] that reports the platform-wide metrics of a
// [debugViewMetricsOverrides] entry in place of the ones the platform reports,
// and wraps the views it reports.
//
// The entry is the one of [_viewId], the view whose
// [ui.FlutterView.platformDispatcher] this is. The dispatcher
// [debugApplyViewMetricsOverrides] returns has no view of its own and follows
// the implicit view's entry: consumers that read these metrics off the binding
// rather than off a view, such as SemanticsBinding, have no view to resolve
// against.
//
// Every other member is forwarded explicitly, and a member added to dart:ui has
// to be forwarded here too: a noSuchMethod would hand the framework null for it.
class _DebugViewMetricsPlatformDispatcher implements ui.PlatformDispatcher {
  _DebugViewMetricsPlatformDispatcher(this._dispatcher, [this._viewId]);

  final ui.PlatformDispatcher _dispatcher;
  final int? _viewId;

  DebugViewMetricsOverride? get _override {
    final int? viewId = _viewId ?? _dispatcher.implicitView?.viewId;
    return viewId == null ? null : _viewMetricsOverrides[viewId];
  }

  @override
  ui.AccessibilityFeatures get accessibilityFeatures {
    final ui.AccessibilityFeatures features = _dispatcher.accessibilityFeatures;
    final DebugViewMetricsOverride? override = _override;
    return override == null || !override._overridesAccessibilityFeatures
        ? features
        : _DebugAccessibilityFeatures(features, override);
  }

  @override
  bool get alwaysUse24HourFormat =>
      _override?.alwaysUse24HourFormat ?? _dispatcher.alwaysUse24HourFormat;

  @override
  ui.Brightness get platformBrightness =>
      _override?.platformBrightness ?? _dispatcher.platformBrightness;

  @override
  double get textScaleFactor {
    final List<ui.Offset>? points = _override?.textScaling;
    return points == null ? _dispatcher.textScaleFactor : points.first.dy / points.first.dx;
  }

  // Applies the table the way [DebugViewMetricsOverride.textScaling] documents:
  // linear interpolation between points, the nearest point's ratio beyond them.
  @override
  double scaleFontSize(double unscaledFontSize) {
    final List<ui.Offset>? points = _override?.textScaling;
    if (points == null) {
      return _dispatcher.scaleFontSize(unscaledFontSize);
    }
    if (unscaledFontSize <= points.first.dx) {
      return unscaledFontSize * (points.first.dy / points.first.dx);
    }
    for (var i = 1; i < points.length; i += 1) {
      if (unscaledFontSize <= points[i].dx) {
        final ui.Offset lower = points[i - 1];
        final ui.Offset upper = points[i];
        return lower.dy +
            (upper.dy - lower.dy) * (unscaledFontSize - lower.dx) / (upper.dx - lower.dx);
      }
    }
    return unscaledFontSize * (points.last.dy / points.last.dx);
  }

  @override
  Iterable<ui.FlutterView> get views => _dispatcher.views.map(_debugWrapView);

  @override
  ui.FlutterView? view({required int id}) {
    final ui.FlutterView? view = _dispatcher.view(id: id);
    return view == null ? null : _debugWrapView(view);
  }

  @override
  ui.FlutterView? get implicitView {
    final ui.FlutterView? view = _dispatcher.implicitView;
    return view == null ? null : _debugWrapView(view);
  }

  // Everything below is forwarded unchanged.

  @override
  String get defaultRouteName => _dispatcher.defaultRouteName;

  @override
  Iterable<ui.Display> get displays => _dispatcher.displays;

  @override
  int? get engineId => _dispatcher.engineId;

  @override
  ui.FrameData get frameData => _dispatcher.frameData;

  @override
  String get initialLifecycleState => _dispatcher.initialLifecycleState;

  @override
  double? get letterSpacingOverride => _dispatcher.letterSpacingOverride;

  @override
  double? get lineHeightScaleFactorOverride => _dispatcher.lineHeightScaleFactorOverride;

  @override
  ui.Locale get locale => _dispatcher.locale;

  @override
  List<ui.Locale> get locales => _dispatcher.locales;

  @override
  bool get nativeSpellCheckServiceDefined => _dispatcher.nativeSpellCheckServiceDefined;

  @override
  bool get brieflyShowPassword => _dispatcher.brieflyShowPassword;

  @override
  double? get paragraphSpacingOverride => _dispatcher.paragraphSpacingOverride;

  @override
  bool get semanticsEnabled => _dispatcher.semanticsEnabled;

  @override
  bool get supportsShowingSystemContextMenu => _dispatcher.supportsShowingSystemContextMenu;

  @override
  String? get systemFontFamily => _dispatcher.systemFontFamily;

  @override
  double? get wordSpacingOverride => _dispatcher.wordSpacingOverride;

  @override
  ui.VoidCallback? get onAccessibilityFeaturesChanged => _dispatcher.onAccessibilityFeaturesChanged;
  @override
  set onAccessibilityFeaturesChanged(ui.VoidCallback? callback) =>
      _dispatcher.onAccessibilityFeaturesChanged = callback;

  @override
  ui.FrameCallback? get onBeginFrame => _dispatcher.onBeginFrame;
  @override
  set onBeginFrame(ui.FrameCallback? callback) => _dispatcher.onBeginFrame = callback;

  @override
  ui.VoidCallback? get onDrawFrame => _dispatcher.onDrawFrame;
  @override
  set onDrawFrame(ui.VoidCallback? callback) => _dispatcher.onDrawFrame = callback;

  @override
  ui.ErrorCallback? get onError => _dispatcher.onError;
  @override
  set onError(ui.ErrorCallback? callback) => _dispatcher.onError = callback;

  @override
  ui.VoidCallback? get onFrameDataChanged => _dispatcher.onFrameDataChanged;
  @override
  set onFrameDataChanged(ui.VoidCallback? callback) => _dispatcher.onFrameDataChanged = callback;

  @override
  ui.HitTestCallback? get onHitTest => _dispatcher.onHitTest;
  @override
  set onHitTest(ui.HitTestCallback? callback) => _dispatcher.onHitTest = callback;

  @override
  ui.KeyDataCallback? get onKeyData => _dispatcher.onKeyData;
  @override
  set onKeyData(ui.KeyDataCallback? callback) => _dispatcher.onKeyData = callback;

  @override
  ui.VoidCallback? get onLocaleChanged => _dispatcher.onLocaleChanged;
  @override
  set onLocaleChanged(ui.VoidCallback? callback) => _dispatcher.onLocaleChanged = callback;

  @override
  ui.VoidCallback? get onMetricsChanged => _dispatcher.onMetricsChanged;
  @override
  set onMetricsChanged(ui.VoidCallback? callback) => _dispatcher.onMetricsChanged = callback;

  @override
  ui.VoidCallback? get onPlatformBrightnessChanged => _dispatcher.onPlatformBrightnessChanged;
  @override
  set onPlatformBrightnessChanged(ui.VoidCallback? callback) =>
      _dispatcher.onPlatformBrightnessChanged = callback;

  @override
  ui.VoidCallback? get onPlatformConfigurationChanged => _dispatcher.onPlatformConfigurationChanged;
  @override
  set onPlatformConfigurationChanged(ui.VoidCallback? callback) =>
      _dispatcher.onPlatformConfigurationChanged = callback;

  @override
  ui.PlatformMessageCallback? get onPlatformMessage => _dispatcher.onPlatformMessage;
  @override
  set onPlatformMessage(ui.PlatformMessageCallback? callback) =>
      _dispatcher.onPlatformMessage = callback;

  @override
  ui.PointerDataPacketCallback? get onPointerDataPacket => _dispatcher.onPointerDataPacket;
  @override
  set onPointerDataPacket(ui.PointerDataPacketCallback? callback) =>
      _dispatcher.onPointerDataPacket = callback;

  @override
  ui.TimingsCallback? get onReportTimings => _dispatcher.onReportTimings;
  @override
  set onReportTimings(ui.TimingsCallback? callback) => _dispatcher.onReportTimings = callback;

  @override
  ui.SemanticsActionEventCallback? get onSemanticsActionEvent => _dispatcher.onSemanticsActionEvent;
  @override
  set onSemanticsActionEvent(ui.SemanticsActionEventCallback? callback) =>
      _dispatcher.onSemanticsActionEvent = callback;

  @override
  ui.VoidCallback? get onSemanticsEnabledChanged => _dispatcher.onSemanticsEnabledChanged;
  @override
  set onSemanticsEnabledChanged(ui.VoidCallback? callback) =>
      _dispatcher.onSemanticsEnabledChanged = callback;

  @override
  ui.VoidCallback? get onSystemFontFamilyChanged => _dispatcher.onSystemFontFamilyChanged;
  @override
  set onSystemFontFamilyChanged(ui.VoidCallback? callback) =>
      _dispatcher.onSystemFontFamilyChanged = callback;

  @override
  ui.VoidCallback? get onTextScaleFactorChanged => _dispatcher.onTextScaleFactorChanged;
  @override
  set onTextScaleFactorChanged(ui.VoidCallback? callback) =>
      _dispatcher.onTextScaleFactorChanged = callback;

  @override
  ui.ViewFocusChangeCallback? get onViewFocusChange => _dispatcher.onViewFocusChange;
  @override
  set onViewFocusChange(ui.ViewFocusChangeCallback? callback) =>
      _dispatcher.onViewFocusChange = callback;

  @override
  ui.Locale? computePlatformResolvedLocale(List<ui.Locale> supportedLocales) =>
      _dispatcher.computePlatformResolvedLocale(supportedLocales);

  @override
  ByteData? getPersistentIsolateData() => _dispatcher.getPersistentIsolateData();

  @override
  void registerBackgroundIsolate(ui.RootIsolateToken token) =>
      _dispatcher.registerBackgroundIsolate(token);

  @override
  void requestDartPerformanceMode(ui.DartPerformanceMode mode) =>
      _dispatcher.requestDartPerformanceMode(mode);

  @override
  void requestViewFocusChange({
    required int viewId,
    required ui.ViewFocusState state,
    required ui.ViewFocusDirection direction,
  }) => _dispatcher.requestViewFocusChange(viewId: viewId, state: state, direction: direction);

  @override
  void resetInternalState() => _dispatcher.resetInternalState();

  @override
  void scheduleFrame() => _dispatcher.scheduleFrame();

  @override
  void scheduleWarmUpFrame({
    required ui.VoidCallback beginFrame,
    required ui.VoidCallback drawFrame,
  }) => _dispatcher.scheduleWarmUpFrame(beginFrame: beginFrame, drawFrame: drawFrame);

  @override
  void sendPlatformMessage(
    String name,
    ByteData? data,
    ui.PlatformMessageResponseCallback? callback,
  ) => _dispatcher.sendPlatformMessage(name, data, callback);

  @override
  void sendPortPlatformMessage(String name, ByteData? data, int identifier, Object port) {
    // `port` is a SendPort on the VM and an Object on the web, so the parameter
    // is widened to Object and the VM's downcast goes through dynamic.
    final dynamic sendPort = port;
    // ignore: argument_type_not_assignable
    _dispatcher.sendPortPlatformMessage(name, data, identifier, sendPort);
  }

  @override
  void setApplicationLocale(ui.Locale locale) => _dispatcher.setApplicationLocale(locale);

  @override
  void setIsolateDebugName(String name) => _dispatcher.setIsolateDebugName(name);

  @override
  void setSemanticsTreeEnabled(bool enabled) => _dispatcher.setSemanticsTreeEnabled(enabled);

  @override
  void updateSemantics(ui.SemanticsUpdate update) => _dispatcher.updateSemantics(update);

  @override
  String toString() =>
      'DebugViewMetricsPlatformDispatcher(${_viewId == null ? 'implicit view' : 'view $_viewId'})';
}

// A [ui.FlutterView] that reports the metrics of its [debugViewMetricsOverrides]
// entry in place of the ones the platform reports.
class _DebugViewMetricsFlutterView implements ui.FlutterView {
  _DebugViewMetricsFlutterView(this._view);

  final ui.FlutterView _view;

  DebugViewMetricsOverride? get _override => _viewMetricsOverrides[_view.viewId];

  @override
  late final ui.PlatformDispatcher platformDispatcher = _DebugViewMetricsPlatformDispatcher(
    _view.platformDispatcher,
    _view.viewId,
  );

  @override
  double get devicePixelRatio => _override?.devicePixelRatio ?? _view.devicePixelRatio;

  @override
  ui.Size get physicalSize => _override?.physicalSize ?? _view.physicalSize;

  // An overridden size makes the view fixed-size; a loose constraint would let
  // layout pick the real size back up.
  @override
  ui.ViewConstraints get physicalConstraints {
    final ui.Size? physicalSize = _override?.physicalSize;
    return physicalSize == null
        ? _view.physicalConstraints
        : ui.ViewConstraints.tight(physicalSize);
  }

  @override
  ui.ViewPadding get padding => _override?.padding ?? _view.padding;

  @override
  ui.ViewPadding get viewInsets => _override?.viewInsets ?? _view.viewInsets;

  @override
  ui.ViewPadding get viewPadding => _override?.viewPadding ?? _view.viewPadding;

  @override
  ui.ViewPadding get systemGestureInsets =>
      _override?.systemGestureInsets ?? _view.systemGestureInsets;

  // The engine discards a frame whose size does not satisfy the real
  // constraints, so an overridden size is withheld: the scene is then rendered
  // at the real size, with its content anchored at the top left.
  @override
  void render(ui.Scene scene, {ui.Size? size}) =>
      _view.render(scene, size: _override?.physicalSize == null ? size : null);

  // The one metric the platform reports in logical pixels, so it moves with an
  // overridden device pixel ratio like everything laid out against it does.
  @override
  List<ui.DisplayFeature> get displayFeatures {
    final double? devicePixelRatio = _override?.devicePixelRatio;
    final List<ui.DisplayFeature> features = _view.displayFeatures;
    if (devicePixelRatio == null || features.isEmpty) {
      return features;
    }
    final double scale = _view.devicePixelRatio / devicePixelRatio;
    return <ui.DisplayFeature>[
      for (final ui.DisplayFeature feature in features)
        ui.DisplayFeature(
          bounds: ui.Rect.fromLTRB(
            feature.bounds.left * scale,
            feature.bounds.top * scale,
            feature.bounds.right * scale,
            feature.bounds.bottom * scale,
          ),
          type: feature.type,
          state: feature.state,
        ),
    ];
  }

  // Everything below is forwarded unchanged.

  @override
  int get viewId => _view.viewId;

  @override
  ui.Display get display => _view.display;

  @override
  ui.DisplayCornerRadii? get displayCornerRadii => _view.displayCornerRadii;

  @override
  ui.GestureSettings get gestureSettings => _view.gestureSettings;

  @override
  void updateSemantics(ui.SemanticsUpdate update) => _view.updateSemantics(update);

  @override
  String toString() => 'DebugViewMetricsFlutterView(id: $viewId)';
}

// The platform's [ui.AccessibilityFeatures] with the flags an override
// specifies replaced; the real class cannot be constructed outside dart:ui.
@immutable
class _DebugAccessibilityFeatures implements ui.AccessibilityFeatures {
  const _DebugAccessibilityFeatures(this._features, this._override);

  final ui.AccessibilityFeatures _features;
  final DebugViewMetricsOverride _override;

  @override
  bool get accessibleNavigation => _override.accessibleNavigation ?? _features.accessibleNavigation;

  @override
  bool get autoPlayAnimatedImages =>
      _override.autoPlayAnimatedImages ?? _features.autoPlayAnimatedImages;

  @override
  bool get autoPlayVideos => _override.autoPlayVideos ?? _features.autoPlayVideos;

  @override
  bool get boldText => _override.boldText ?? _features.boldText;

  @override
  bool get deterministicCursor => _override.deterministicCursor ?? _features.deterministicCursor;

  @override
  bool get disableAnimations => _override.disableAnimations ?? _features.disableAnimations;

  @override
  bool get highContrast => _override.highContrast ?? _features.highContrast;

  @override
  bool get invertColors => _override.invertColors ?? _features.invertColors;

  @override
  bool get onOffSwitchLabels => _override.onOffSwitchLabels ?? _features.onOffSwitchLabels;

  @override
  bool get reduceMotion => _override.reduceMotion ?? _features.reduceMotion;

  @override
  bool get supportsAnnounce => _override.supportsAnnounce ?? _features.supportsAnnounce;

  // ui.AccessibilityFeatures compares by value (after a runtimeType check that
  // excludes this class), so this does the same among its own instances.
  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is _DebugAccessibilityFeatures && other._flags == _flags;
  }

  @override
  int get hashCode => _flags.hashCode;

  (bool, bool, bool, bool, bool, bool, bool, bool, bool, bool, bool) get _flags => (
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

  @override
  String toString() {
    final features = <String>[
      if (accessibleNavigation) 'accessibleNavigation',
      if (invertColors) 'invertColors',
      if (disableAnimations) 'disableAnimations',
      if (boldText) 'boldText',
      if (reduceMotion) 'reduceMotion',
      if (highContrast) 'highContrast',
      if (onOffSwitchLabels) 'onOffSwitchLabels',
      if (supportsAnnounce) 'supportsAnnounce',
      if (autoPlayAnimatedImages) 'autoPlayAnimatedImages',
      if (autoPlayVideos) 'autoPlayVideos',
      if (deterministicCursor) 'deterministicCursor',
    ];
    return 'AccessibilityFeatures$features';
  }
}

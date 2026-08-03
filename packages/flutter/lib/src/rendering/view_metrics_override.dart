// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
///
/// @docImport 'binding.dart';
/// @docImport 'box.dart';
/// @docImport 'view.dart';
library;

import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

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
/// See also:
///
///  * [debugViewMetricsOverrides], the map this class is registered in.
///  * [MediaQuery], which surfaces the overridden values to widgets.
@immutable
class ViewMetricsOverride with Diagnosticable {
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
  const ViewMetricsOverride({
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
    this.highContrast,
    this.onOffSwitchLabels,
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
  factory ViewMetricsOverride.fromJson(Map<String, Object?> json) {
    return ViewMetricsOverride(
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
      highContrast: _boolFromJson(json, 'highContrast'),
      onOffSwitchLabels: _boolFromJson(json, 'onOffSwitchLabels'),
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

  /// Overrides [ui.AccessibilityFeatures.highContrast].
  final bool? highContrast;

  /// Overrides [ui.AccessibilityFeatures.onOffSwitchLabels].
  final bool? onOffSwitchLabels;

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
      highContrast == null &&
      onOffSwitchLabels == null;

  /// Whether this instance overrides a metric that participates in layout, and
  /// therefore requires the [RenderView]'s [ViewConfiguration] to be rebuilt.
  bool get affectsViewConfiguration => devicePixelRatio != null || physicalSize != null;

  /// Creates a copy of this object with the given fields replaced.
  ///
  /// Because a null field means "not overridden", passing null for an argument
  /// leaves the existing override in place rather than clearing it. To clear an
  /// override, construct a new [ViewMetricsOverride].
  ViewMetricsOverride copyWith({
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
    bool? highContrast,
    bool? onOffSwitchLabels,
  }) {
    return ViewMetricsOverride(
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
      highContrast: highContrast ?? this.highContrast,
      onOffSwitchLabels: onOffSwitchLabels ?? this.onOffSwitchLabels,
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
      if (highContrast != null) 'highContrast': highContrast,
      if (onOffSwitchLabels != null) 'onOffSwitchLabels': onOffSwitchLabels,
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
        EdgeInsets.fromLTRB(left.toDouble(), top.toDouble(), right.toDouble(), bottom.toDouble()),
      final Object value => throw FormatException(
        'Expected {"left": num, "top": num, "right": num, "bottom": num} for $key, got $value.',
      ),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ViewMetricsOverride &&
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
        other.highContrast == highContrast &&
        other.onOffSwitchLabels == onOffSwitchLabels;
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
    highContrast,
    onOffSwitchLabels,
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
    _addFlag(properties, 'highContrast', highContrast);
    _addFlag(properties, 'onOffSwitchLabels', onOffSwitchLabels);
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
Map<int, ViewMetricsOverride> get debugViewMetricsOverrides => _unmodifiableViewMetricsOverrides;

final Map<int, ViewMetricsOverride> _viewMetricsOverrides = <int, ViewMetricsOverride>{};
final Map<int, ViewMetricsOverride> _unmodifiableViewMetricsOverrides =
    UnmodifiableMapView<int, ViewMetricsOverride>(_viewMetricsOverrides);

/// Notifies listeners when [debugViewMetricsOverrides] changes.
///
/// [MediaQuery] listens to this so that a view rebuilds when its override is
/// installed, changed, or removed, and [RendererBinding] listens to it so that
/// an overridden size is applied to the [RenderView].
///
/// Mutate [debugViewMetricsOverrides] through [debugSetViewMetricsOverride] or
/// [debugClearViewMetricsOverrides], which notify this object for you.
Listenable get debugViewMetricsOverridesNotifier => _overridesNotifier;

final _ViewMetricsOverridesNotifier _overridesNotifier = _ViewMetricsOverridesNotifier();

// Deliberately not registered with ChangeNotifier.maybeDispatchObjectCreation:
// this is a process-lifetime singleton that is never disposed, and leak
// tracking would report it as a leak in every test that enables it.
class _ViewMetricsOverridesNotifier extends ChangeNotifier {
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
bool debugSetViewMetricsOverride(int viewId, ViewMetricsOverride? override) {
  if (kReleaseMode) {
    return false;
  }
  final ViewMetricsOverride? previous = _viewMetricsOverrides[viewId];
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

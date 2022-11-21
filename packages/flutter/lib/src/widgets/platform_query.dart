// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'binding.dart';
import 'debug.dart';
import 'framework.dart';
import 'inherited_model.dart';

// Examples can assume:
// late BuildContext context;

enum _PlatformQueryAspect {
  textScaleFactor,
  platformBrightness,
  alwaysUse24HourFormat,
  accessibleNavigation,
  invertColors,
  highContrast,
  disableAnimations,
  boldText,
  navigationMode,
}

/// Information about platform settings.
///
/// To obtain the current [PlatformQueryData] for a given [BuildContext], use the
/// [PlatformQuery.of] function. For example, to obtain the size of the current
/// window, use `PlatformQuery.of(context).size`.
///
/// If no [PlatformQuery] is in scope then the [PlatformQuery.of] method will throw an
/// exception. Alternatively, [PlatformQuery.maybeOf] may be used, which returns
/// null instead of throwing if no [PlatformQuery] is in scope.
@immutable
class PlatformQueryData {
  /// Creates data for a media query with explicit values.
  ///
  /// Consider using [PlatformQueryData.fromPlatformDispatcher] to create data
  /// based on a [dart:ui.PlatformDispatcher].
  const PlatformQueryData({
    this.textScaleFactor = 1.0,
    this.platformBrightness = Brightness.light,
    this.alwaysUse24HourFormat = false,
    this.accessibleNavigation = false,
    this.invertColors = false,
    this.highContrast = false,
    this.disableAnimations = false,
    this.boldText = false,
    this.navigationMode = NavigationMode.traditional,
  }) : assert(textScaleFactor != null),
       assert(platformBrightness != null),
       assert(alwaysUse24HourFormat != null),
       assert(accessibleNavigation != null),
       assert(invertColors != null),
       assert(highContrast != null),
       assert(disableAnimations != null),
       assert(boldText != null),
       assert(navigationMode != null);

  /// Creates data for a platform query based on the given platform dispatcher.
  ///
  /// If you use this, you should ensure that you also register for
  /// notifications so that you can update your [PlatformQueryData] when the
  /// data on the platform dispatcher changes. For example, see
  /// [WidgetsBindingObserver.onAccessibilityFeaturesChanged] or
  /// [dart:ui.PlatformDispatcher.onMetricsChanged].
  PlatformQueryData.fromPlatformDispatcher(ui.PlatformDispatcher platformDispatcher)
      : textScaleFactor = platformDispatcher.textScaleFactor,
        platformBrightness = platformDispatcher.platformBrightness,
        accessibleNavigation = platformDispatcher.accessibilityFeatures.accessibleNavigation,
        invertColors = platformDispatcher.accessibilityFeatures.invertColors,
        disableAnimations = platformDispatcher.accessibilityFeatures.disableAnimations,
        boldText = platformDispatcher.accessibilityFeatures.boldText,
        highContrast = platformDispatcher.accessibilityFeatures.highContrast,
        alwaysUse24HourFormat = platformDispatcher.alwaysUse24HourFormat,
        navigationMode = NavigationMode.traditional;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  ///
  /// See also:
  ///
  ///  * [PlatformQuery.textScaleFactorOf], a method to find and depend on the
  ///    textScaleFactor defined for a [BuildContext].
  final double textScaleFactor;

  /// The current brightness mode of the host platform.
  ///
  /// For example, starting in Android Pie, battery saver mode asks all apps to
  /// render in a "dark mode".
  ///
  /// Not all platforms necessarily support a concept of brightness mode. Those
  /// platforms will report [Brightness.light] in this property.
  ///
  /// See also:
  ///
  ///  * [PlatformQuery.platformBrightnessOf], a method to find and depend on the
  ///    platformBrightness defined for a [BuildContext].
  final Brightness platformBrightness;

  /// Whether to use 24-hour format when formatting time.
  ///
  /// The behavior of this flag is different across platforms:
  ///
  /// - On Android this flag is reported directly from the user settings called
  ///   "Use 24-hour format". It applies to any locale used by the application,
  ///   whether it is the system-wide locale, or the custom locale set by the
  ///   application.
  /// - On iOS this flag is set to true when the user setting called "24-Hour
  ///   Time" is set or the system-wide locale's default uses 24-hour
  ///   formatting.
  final bool alwaysUse24HourFormat;

  /// Whether the user is using an accessibility service like TalkBack or
  /// VoiceOver to interact with the application.
  ///
  /// When this setting is true, features such as timeouts should be disabled or
  /// have minimum durations increased.
  ///
  /// See also:
  ///
  ///  * [dart:ui.PlatformDispatcher.accessibilityFeatures], where the setting originates.
  final bool accessibleNavigation;

  /// Whether the device is inverting the colors of the platform.
  ///
  /// This flag is currently only updated on iOS devices.
  ///
  /// See also:
  ///
  ///  * [dart:ui.PlatformDispatcher.accessibilityFeatures], where the setting
  ///    originates.
  final bool invertColors;

  /// Whether the user requested a high contrast between foreground and background
  /// content on iOS, via Settings -> Accessibility -> Increase Contrast.
  ///
  /// This flag is currently only updated on iOS devices that are running iOS 13
  /// or above.
  final bool highContrast;

  /// Whether the platform is requesting that animations be disabled or reduced
  /// as much as possible.
  ///
  /// See also:
  ///
  ///  * [dart:ui.PlatformDispatcher.accessibilityFeatures], where the setting
  ///    originates.
  final bool disableAnimations;

  /// Whether the platform is requesting that text be drawn with a bold font
  /// weight.
  ///
  /// See also:
  ///
  ///  * [dart:ui.PlatformDispatcher.accessibilityFeatures], where the setting
  ///    originates.
  final bool boldText;

  /// Describes the navigation mode requested by the platform.
  ///
  /// Some user interfaces are better navigated using a directional pad (DPAD)
  /// or arrow keys, and for those interfaces, some widgets need to handle these
  /// directional events differently. In order to know when to do that, these
  /// widgets will look for the navigation mode in effect for their context.
  ///
  /// For instance, in a television interface, [NavigationMode.directional]
  /// should be set, so that directional navigation is used to navigate away
  /// from a text field using the DPAD. In contrast, on a regular desktop
  /// application with the [navigationMode] set to [NavigationMode.traditional],
  /// the arrow keys are used to move the cursor instead of navigating away.
  ///
  /// The [NavigationMode] values indicate the type of navigation to be used in
  /// a widget subtree for those widgets sensitive to it.
  final NavigationMode navigationMode;

  /// Creates a copy of this media query data but with the given fields replaced
  /// with the new values.
  PlatformQueryData copyWith({
    double? textScaleFactor,
    Brightness? platformBrightness,
    bool? alwaysUse24HourFormat,
    bool? highContrast,
    bool? disableAnimations,
    bool? invertColors,
    bool? accessibleNavigation,
    bool? boldText,
    NavigationMode? navigationMode,
  }) {
    return PlatformQueryData(
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      platformBrightness: platformBrightness ?? this.platformBrightness,
      alwaysUse24HourFormat: alwaysUse24HourFormat ?? this.alwaysUse24HourFormat,
      invertColors: invertColors ?? this.invertColors,
      highContrast: highContrast ?? this.highContrast,
      disableAnimations: disableAnimations ?? this.disableAnimations,
      accessibleNavigation: accessibleNavigation ?? this.accessibleNavigation,
      boldText: boldText ?? this.boldText,
      navigationMode: navigationMode ?? this.navigationMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is PlatformQueryData
        && other.textScaleFactor == textScaleFactor
        && other.platformBrightness == platformBrightness
        && other.alwaysUse24HourFormat == alwaysUse24HourFormat
        && other.highContrast == highContrast
        && other.disableAnimations == disableAnimations
        && other.invertColors == invertColors
        && other.accessibleNavigation == accessibleNavigation
        && other.boldText == boldText
        && other.navigationMode == navigationMode;
  }

  @override
  int get hashCode => Object.hash(
    textScaleFactor,
    platformBrightness,
    alwaysUse24HourFormat,
    highContrast,
    disableAnimations,
    invertColors,
    accessibleNavigation,
    boldText,
    navigationMode,
  );

  @override
  String toString() {
    final List<String> properties = <String>[
      'textScaleFactor: ${textScaleFactor.toStringAsFixed(1)}',
      'platformBrightness: $platformBrightness',
      'alwaysUse24HourFormat: $alwaysUse24HourFormat',
      'accessibleNavigation: $accessibleNavigation',
      'highContrast: $highContrast',
      'disableAnimations: $disableAnimations',
      'invertColors: $invertColors',
      'boldText: $boldText',
      'navigationMode: ${navigationMode.name}',
    ];
    return '${objectRuntimeType(this, 'PlatformQueryData')}(${properties.join(', ')})';
  }
}

/// Establishes a subtree in which platform queries resolve to the given data.
///
/// Querying the current platform using [PlatformQuery.of] will cause your widget to
/// rebuild automatically whenever the [PlatformQueryData] changes.
///
/// If no [PlatformQuery] is in scope then the [PlatformQuery.of] method will throw an
/// exception. Alternatively, [PlatformQuery.maybeOf] may be used, which returns
/// null instead of throwing if no [PlatformQuery] is in scope.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=A3WrA4zAaPw}
///
/// See also:
///
///  * [WidgetsApp] and [MaterialApp], which introduce a [PlatformQuery] and keep
///    it up to date with the current screen metrics as they change.
///  * [PlatformQueryData], the data structure that represents the metrics.
class PlatformQuery extends InheritedModel<_PlatformQueryAspect> {
  /// Creates a widget that provides [PlatformQueryData] to its descendants.
  ///
  /// The [data] and [child] arguments must not be null.
  const PlatformQuery({
    super.key,
    required this.data,
    required super.child,
  }) : assert(child != null),
       assert(data != null);

  /// Provides a [PlatformQuery] which is built and updated using the latest
  /// [WidgetsBinding.platformDispatcher] values.
  ///
  /// The [PlatformQuery] is wrapped in a separate widget to ensure that only it
  /// and its dependents are updated when the data on the platform dispatcher
  /// changes, instead of rebuilding the whole widget tree.
  ///
  /// The [child] argument is required and must not be null.
  static Widget fromPlatformDispatcher({
    Key? key,
    required Widget child,
  }) {
    return _PlatformQueryFromPlatformDispatcher(
      key: key,
      child: child,
    );
  }

  /// Contains information about the current platform.
  final PlatformQueryData data;

  /// The data from the closest instance of this class that encloses the given
  /// context.
  ///
  /// If the widget only requires a subset of properties of the [PlatformQueryData]
  /// object, it is preferred to use the specific methods (for example:
  /// [PlatformQuery.textScaleFactorOf] and [PlatformQuery.platformBrightnessOf]),
  /// as those methods will not cause a widget to rebuild when unrelated
  /// properties are updated.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// PlatformQueryData media = PlatformQuery.of(context);
  /// ```
  ///
  /// If there is no [PlatformQuery] in scope, this will throw a [TypeError]
  /// exception in release builds, and throw a descriptive [FlutterError] in
  /// debug builds.
  ///
  /// See also:
  ///
  ///  * [maybeOf], which doesn't throw or assert if it doesn't find a
  ///    [PlatformQuery] ancestor, it returns null instead.
  static PlatformQueryData of(BuildContext context) {
    assert(context != null);
    return _of(context);
  }

  static PlatformQueryData _of(BuildContext context, [_PlatformQueryAspect? aspect]) {
    assert(debugCheckHasPlatformQuery(context));
    return InheritedModel.inheritFrom<PlatformQuery>(context, aspect: aspect)!.data;
  }

  /// The data from the closest instance of this class that encloses the given
  /// context, if any.
  ///
  /// Use this function if you want to allow situations where no [PlatformQuery] is
  /// in scope. Prefer using [PlatformQuery.of] in situations where a media query
  /// is always expected to exist.
  ///
  /// If there is no [PlatformQuery] in scope, then this function will return null.
  ///
  /// If the widget only requires a subset of properties of the [PlatformQueryData]
  /// object, it is preferred to use the specific methods (for example:
  /// [PlatformQuery.textScaleFactorOf] and [PlatformQuery.platformBrightnessOf]),
  /// as those methods will not cause a widget to rebuild when unrelated
  /// properties are updated.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// PlatformQueryData? PlatformQuery = PlatformQuery.maybeOf(context);
  /// if (PlatformQuery == null) {
  ///   // Do something else instead.
  /// }
  /// ```
  ///
  /// See also:
  ///
  ///  * [of], which will throw if it doesn't find a [PlatformQuery] ancestor,
  ///    instead of returning null.
  static PlatformQueryData? maybeOf(BuildContext context) {
    assert(context != null);
    return _maybeOf(context);
  }

  static PlatformQueryData? _maybeOf(BuildContext context, [_PlatformQueryAspect? aspect]) {
    return InheritedModel.inheritFrom<PlatformQuery>(context, aspect: aspect)?.data;
  }

  /// Returns textScaleFactor for the nearest PlatformQuery ancestor or
  /// 1.0, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [PlatformQueryData.textScaleFactor] property of the ancestor [PlatformQuery] changes.
  static double textScaleFactorOf(BuildContext context) => maybeTextScaleFactorOf(context) ?? 1.0;

  /// Returns textScaleFactor for the nearest PlatformQuery ancestor or
  /// null, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [PlatformQueryData.textScaleFactor] property of the ancestor [PlatformQuery] changes.
  static double? maybeTextScaleFactorOf(BuildContext context) => _maybeOf(context, _PlatformQueryAspect.textScaleFactor)?.textScaleFactor;

  /// Returns platformBrightness for the nearest PlatformQuery ancestor or
  /// [Brightness.light], if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [PlatformQueryData.platformBrightness] property of the ancestor
  /// [PlatformQuery] changes.
  static Brightness platformBrightnessOf(BuildContext context) => maybePlatformBrightnessOf(context) ?? Brightness.light;

  /// Returns platformBrightness for the nearest PlatformQuery ancestor or
  /// null, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [PlatformQueryData.platformBrightness] property of the ancestor
  /// [PlatformQuery] changes.
  static Brightness? maybePlatformBrightnessOf(BuildContext context) => _maybeOf(context, _PlatformQueryAspect.platformBrightness)?.platformBrightness;

  /// Returns alwaysUse for the nearest PlatformQuery ancestor or
  /// throws an exception, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [PlatformQueryData.devicePixelRatio] property of the ancestor [PlatformQuery] changes.
  static bool alwaysUse24HourFormatOf(BuildContext context) => _of(context, _PlatformQueryAspect.alwaysUse24HourFormat).alwaysUse24HourFormat;

  /// Returns alwaysUse24HourFormat for the nearest PlatformQuery ancestor or
  /// null, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [PlatformQueryData.alwaysUse24HourFormat] property of the ancestor [PlatformQuery] changes.
  static bool? maybeAlwaysUse24HourFormatOf(BuildContext context) => _maybeOf(context, _PlatformQueryAspect.alwaysUse24HourFormat)?.alwaysUse24HourFormat;

  /// Returns accessibleNavigationOf for the nearest PlatformQuery ancestor or
  /// throws an exception, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [PlatformQueryData.accessibleNavigation] property of the ancestor [PlatformQuery] changes.
  static bool accessibleNavigationOf(BuildContext context) => _of(context, _PlatformQueryAspect.accessibleNavigation).accessibleNavigation;

  /// Returns accessibleNavigation for the nearest PlatformQuery ancestor or
  /// null, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [PlatformQueryData.accessibleNavigation] property of the ancestor [PlatformQuery] changes.
  static bool? maybeAccessibleNavigationOf(BuildContext context) => _maybeOf(context, _PlatformQueryAspect.accessibleNavigation)?.accessibleNavigation;

  /// Returns invertColorsOf for the nearest PlatformQuery ancestor or
  /// throws an exception, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [PlatformQueryData.invertColors] property of the ancestor [PlatformQuery] changes.
  static bool invertColorsOf(BuildContext context) => _of(context, _PlatformQueryAspect.invertColors).invertColors;

  /// Returns invertColors for the nearest PlatformQuery ancestor or
  /// null, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [PlatformQueryData.invertColors] property of the ancestor [PlatformQuery] changes.
  static bool? maybeInvertColorsOf(BuildContext context) => _maybeOf(context, _PlatformQueryAspect.invertColors)?.invertColors;

  /// Returns highContrast for the nearest PlatformQuery ancestor or false, if no
  /// such ancestor exists.
  ///
  /// See also:
  ///
  ///  * [PlatformQueryData.highContrast], which indicates the platform's
  ///    desire to increase contrast.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [PlatformQueryData.highContrast] property of the ancestor [PlatformQuery] changes.
  static bool highContrastOf(BuildContext context) => maybeHighContrastOf(context) ?? false;

  /// Returns highContrast for the nearest PlatformQuery ancestor or
  /// null, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [PlatformQueryData.highContrast] property of the ancestor [PlatformQuery] changes.
  static bool? maybeHighContrastOf(BuildContext context) => _maybeOf(context, _PlatformQueryAspect.highContrast)?.highContrast;

  /// Returns disableAnimations for the nearest PlatformQuery ancestor or
  /// [Brightness.light], if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [PlatformQueryData.disableAnimations] property of the ancestor
  /// [PlatformQuery] changes.
  static bool disableAnimationsOf(BuildContext context) => _of(context, _PlatformQueryAspect.disableAnimations).disableAnimations;

  /// Returns disableAnimations for the nearest PlatformQuery ancestor or
  /// null, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [PlatformQueryData.disableAnimations] property of the ancestor [PlatformQuery] changes.
  static bool? maybeDisableAnimationsOf(BuildContext context) => _maybeOf(context, _PlatformQueryAspect.disableAnimations)?.disableAnimations;


  /// Returns the boldText accessibility setting for the nearest PlatformQuery
  /// ancestor or false, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [PlatformQueryData.boldText] property of the ancestor [PlatformQuery] changes.
  static bool boldTextOf(BuildContext context) => maybeBoldTextOf(context) ?? false;

  /// Returns the boldText accessibility setting for the nearest PlatformQuery
  /// ancestor or null, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [PlatformQueryData.boldText] property of the ancestor [PlatformQuery] changes.
  static bool? maybeBoldTextOf(BuildContext context) => _maybeOf(context, _PlatformQueryAspect.boldText)?.boldText;

  /// Returns navigationMode for the nearest PlatformQuery ancestor or
  /// throws an exception, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [PlatformQueryData.navigationMode] property of the ancestor [PlatformQuery] changes.
  static NavigationMode navigationModeOf(BuildContext context) => _of(context, _PlatformQueryAspect.navigationMode).navigationMode;

  /// Returns navigationMode for the nearest PlatformQuery ancestor or
  /// null, if no such ancestor exists.
  ///
  /// Use of this method will cause the given [context] to rebuild any time that
  /// the [PlatformQueryData.navigationMode] property of the ancestor [PlatformQuery] changes.
  static NavigationMode? maybeNavigationModeOf(BuildContext context) => _maybeOf(context, _PlatformQueryAspect.navigationMode)?.navigationMode;

  @override
  bool updateShouldNotify(PlatformQuery oldWidget) => data != oldWidget.data;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<PlatformQueryData>('data', data, showName: false));
  }

  @override
  bool updateShouldNotifyDependent(PlatformQuery oldWidget, Set<Object> dependencies) {
    return (data.textScaleFactor != oldWidget.data.textScaleFactor && dependencies.contains(_PlatformQueryAspect.textScaleFactor))
        || (data.platformBrightness != oldWidget.data.platformBrightness && dependencies.contains(_PlatformQueryAspect.platformBrightness))
        || (data.alwaysUse24HourFormat != oldWidget.data.alwaysUse24HourFormat && dependencies.contains(_PlatformQueryAspect.alwaysUse24HourFormat))
        || (data.accessibleNavigation != oldWidget.data.accessibleNavigation && dependencies.contains(_PlatformQueryAspect.accessibleNavigation))
        || (data.invertColors != oldWidget.data.invertColors && dependencies.contains(_PlatformQueryAspect.invertColors))
        || (data.highContrast != oldWidget.data.highContrast && dependencies.contains(_PlatformQueryAspect.highContrast))
        || (data.disableAnimations != oldWidget.data.disableAnimations && dependencies.contains(_PlatformQueryAspect.disableAnimations))
        || (data.boldText != oldWidget.data.boldText && dependencies.contains(_PlatformQueryAspect.boldText))
        || (data.navigationMode != oldWidget.data.navigationMode && dependencies.contains(_PlatformQueryAspect.navigationMode));
  }
}

/// Describes the navigation mode to be set by a [PlatformQuery] widget.
///
/// The different modes indicate the type of navigation to be used in a widget
/// subtree for those widgets sensitive to it.
///
/// Use `PlatformQuery.navigationModeOf(context)` to determine the navigation mode
/// in effect for the given context. Use a [PlatformQuery] widget to set the
/// navigation mode for its descendant widgets.
enum NavigationMode {
  /// This indicates a traditional keyboard-and-mouse navigation modality.
  ///
  /// This navigation mode is where the arrow keys can be used for secondary
  /// modification operations, like moving sliders or cursors, and disabled
  /// controls will lose focus and not be traversable.
  traditional,

  /// This indicates a directional-based navigation mode.
  ///
  /// This navigation mode indicates that arrow keys should be reserved for
  /// navigation operations, and secondary modifications operations, like moving
  /// sliders or cursors, will use alternative bindings or be disabled.
  ///
  /// Some behaviors are also affected by this mode. For instance, disabled
  /// controls will retain focus when disabled, and will be able to receive
  /// focus (although they remain disabled) when traversed.
  directional,
}

class _PlatformQueryFromPlatformDispatcher extends StatefulWidget {
  const _PlatformQueryFromPlatformDispatcher({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<_PlatformQueryFromPlatformDispatcher> createState() => _PlatformQueryFromPlatformDispatcherState();
}

class _PlatformQueryFromPlatformDispatcherState extends State<_PlatformQueryFromPlatformDispatcher> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAccessibilityFeatures() {
    setState(() {
      // The properties of window have changed. We use them in our build
      // function, so we need setState(), but we don't cache anything locally.
    });
  }

  @override
  void didChangeTextScaleFactor() {
    setState(() {
      // The textScaleFactor property of window has changed. We reference
      // window in our build function, so we need to call setState(), but
      // we don't need to cache anything locally.
    });
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {
      // The platformBrightness property of window has changed. We reference
      // window in our build function, so we need to call setState(), but
      // we don't need to cache anything locally.
    });
  }

  @override
  Widget build(BuildContext context) {
    PlatformQueryData data = PlatformQueryData.fromPlatformDispatcher(WidgetsBinding.instance.platformDispatcher);
    if (!kReleaseMode) {
      data = data.copyWith(platformBrightness: debugBrightnessOverride);
    }
    return PlatformQuery(
      data: data,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

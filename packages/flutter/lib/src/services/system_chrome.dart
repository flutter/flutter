// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'system_channels.dart';

export 'dart:ui' show Brightness;

/// Specifies a particular device orientation.
///
/// To determine which values correspond to which orientations, first position
/// the device in its default orientation (this is the orientation that the
/// system first uses for its boot logo, or the orientation in which the
/// hardware logos or markings are upright, or the orientation in which the
/// cameras are at the top). If this is a portrait orientation, then this is
/// [portraitUp]. Otherwise, it's [landscapeLeft]. As you rotate the device by
/// 90 degrees in a counter-clockwise direction around the axis that pierces the
/// screen, you step through each value in this enum in the order given.
///
/// For a device with a landscape default orientation, the orientation obtained
/// by rotating the device 90 degrees clockwise from its default orientation is
/// [portraitUp].
///
/// Used by [SystemChrome.setPreferredOrientations].
enum DeviceOrientation {
  /// If the device shows its boot logo in portrait, then the boot logo is shown
  /// in [portraitUp]. Otherwise, the device shows its boot logo in landscape
  /// and this orientation is obtained by rotating the device 90 degrees
  /// clockwise from its boot orientation.
  portraitUp,

  /// The orientation that is 90 degrees clockwise from [portraitUp].
  ///
  /// If the device shows its boot logo in landscape, then the boot logo is
  /// shown in [landscapeLeft].
  landscapeLeft,

  /// The orientation that is 180 degrees from [portraitUp].
  portraitDown,

  /// The orientation that is 90 degrees counterclockwise from [portraitUp].
  landscapeRight,
}

/// Specifies a description of the application that is pertinent to the
/// embedder's application switcher (also known as "recent tasks") user
/// interface.
///
/// Used by [SystemChrome.setApplicationSwitcherDescription].
@immutable
class ApplicationSwitcherDescription {
  /// Creates an ApplicationSwitcherDescription.
  const ApplicationSwitcherDescription({ this.label, this.primaryColor });

  /// A label and description of the current state of the application.
  final String? label;

  /// The application's primary color.
  ///
  /// This may influence the color that the operating system uses to represent
  /// the application.
  final int? primaryColor;
}

/// Specifies a system overlay at a particular location.
///
/// Used by [SystemChrome.setEnabledSystemUIOverlays].
enum SystemUiOverlay {
  /// The status bar provided by the embedder on the top of the application
  /// surface, if any.
  top,

  /// The status bar provided by the embedder on the bottom of the application
  /// surface, if any.
  bottom,
}

/// Specifies a preference for the style of the system overlays.
///
/// Used by [SystemChrome.setSystemUIOverlayStyle].
@immutable
class SystemUiOverlayStyle {
  /// Creates a new [SystemUiOverlayStyle].
  const SystemUiOverlayStyle({
    this.systemNavigationBarColor,
    this.systemNavigationBarDividerColor,
    this.systemNavigationBarIconBrightness,
    this.statusBarColor,
    this.statusBarBrightness,
    this.statusBarIconBrightness,
  });

  /// The color of the system bottom navigation bar.
  ///
  /// Only honored in Android versions O and greater.
  final Color? systemNavigationBarColor;

  /// The color of the divider between the system's bottom navigation bar and the app's content.
  ///
  /// Only honored in Android versions P and greater.
  final Color? systemNavigationBarDividerColor;

  /// The brightness of the system navigation bar icons.
  ///
  /// Only honored in Android versions O and greater.
  /// When set to [Brightness.light], the system navigation bar icons are light.
  /// When set to [Brightness.dark], the system navigation bar icons are dark.
  final Brightness? systemNavigationBarIconBrightness;

  /// The color of top status bar.
  ///
  /// Only honored in Android version M and greater.
  final Color? statusBarColor;

  /// The brightness of top status bar.
  ///
  /// Only honored in iOS.
  final Brightness? statusBarBrightness;

  /// The brightness of the top status bar icons.
  ///
  /// Only honored in Android version M and greater.
  final Brightness? statusBarIconBrightness;

  /// System overlays should be drawn with a light color. Intended for
  /// applications with a dark background.
  static const SystemUiOverlayStyle light = SystemUiOverlayStyle(
    systemNavigationBarColor: Color(0xFF000000),
    systemNavigationBarDividerColor: null,
    statusBarColor: null,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  /// System overlays should be drawn with a dark color. Intended for
  /// applications with a light background.
  static const SystemUiOverlayStyle dark = SystemUiOverlayStyle(
    systemNavigationBarColor: Color(0xFF000000),
    systemNavigationBarDividerColor: null,
    statusBarColor: null,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  /// Convert this event to a map for serialization.
  Map<String, dynamic> _toMap() {
    return <String, dynamic>{
      'systemNavigationBarColor': systemNavigationBarColor?.value,
      'systemNavigationBarDividerColor': systemNavigationBarDividerColor?.value,
      'statusBarColor': statusBarColor?.value,
      'statusBarBrightness': statusBarBrightness?.toString(),
      'statusBarIconBrightness': statusBarIconBrightness?.toString(),
      'systemNavigationBarIconBrightness': systemNavigationBarIconBrightness?.toString(),
    };
  }

  @override
  String toString() => _toMap().toString();

  /// Creates a copy of this theme with the given fields replaced with new values.
  SystemUiOverlayStyle copyWith({
    Color? systemNavigationBarColor,
    Color? systemNavigationBarDividerColor,
    Color? statusBarColor,
    Brightness? statusBarBrightness,
    Brightness? statusBarIconBrightness,
    Brightness? systemNavigationBarIconBrightness,
  }) {
    return SystemUiOverlayStyle(
      systemNavigationBarColor: systemNavigationBarColor ?? this.systemNavigationBarColor,
      systemNavigationBarDividerColor: systemNavigationBarDividerColor ?? this.systemNavigationBarDividerColor,
      statusBarColor: statusBarColor ?? this.statusBarColor,
      statusBarIconBrightness: statusBarIconBrightness ?? this.statusBarIconBrightness,
      statusBarBrightness: statusBarBrightness ?? this.statusBarBrightness,
      systemNavigationBarIconBrightness: systemNavigationBarIconBrightness ?? this.systemNavigationBarIconBrightness,
    );
  }

  @override
  int get hashCode {
    return hashValues(
      systemNavigationBarColor,
      systemNavigationBarDividerColor,
      statusBarColor,
      statusBarBrightness,
      statusBarIconBrightness,
      systemNavigationBarIconBrightness,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is SystemUiOverlayStyle
        && other.systemNavigationBarColor == systemNavigationBarColor
        && other.systemNavigationBarDividerColor == systemNavigationBarDividerColor
        && other.statusBarColor == statusBarColor
        && other.statusBarIconBrightness == statusBarIconBrightness
        && other.statusBarBrightness == statusBarBrightness
        && other.systemNavigationBarIconBrightness == systemNavigationBarIconBrightness;
  }
}

List<String> _stringify(List<dynamic> list) => <String>[
  for (final dynamic item in list) item.toString(),
];

/// Controls specific aspects of the operating system's graphical interface and
/// how it interacts with the application.
class SystemChrome {
  // This class is not meant to be instantiated or extended; this constructor
  // prevents instantiation and extension.
  // ignore: unused_element
  SystemChrome._();

  /// Specifies the set of orientations the application interface can
  /// be displayed in.
  ///
  /// The `orientation` argument is a list of [DeviceOrientation] enum values.
  /// The empty list causes the application to defer to the operating system
  /// default.
  ///
  /// ## Limitations
  ///
  /// This setting will only be respected on iPad if multitasking is disabled.
  ///
  /// You can decide to opt out of multitasking on iPad, then
  /// setPreferredOrientations will work but your app will not
  /// support Slide Over and Split View multitasking anymore.
  ///
  /// Should you decide to opt out of multitasking you can do this by
  /// setting "Requires full screen" to true in the Xcode Deployment Info.
  static Future<void> setPreferredOrientations(List<DeviceOrientation> orientations) async {
    await SystemChannels.platform.invokeMethod<void>(
      'SystemChrome.setPreferredOrientations',
      _stringify(orientations),
    );
  }

  /// Specifies the description of the current state of the application as it
  /// pertains to the application switcher (also known as "recent tasks").
  ///
  /// Any part of the description that is unsupported on the current platform
  /// will be ignored.
  static Future<void> setApplicationSwitcherDescription(ApplicationSwitcherDescription description) async {
    await SystemChannels.platform.invokeMethod<void>(
      'SystemChrome.setApplicationSwitcherDescription',
      <String, dynamic>{
        'label': description.label,
        'primaryColor': description.primaryColor,
      },
    );
  }

  /// Specifies the set of system overlays to have visible when the application
  /// is running.
  ///
  /// The `overlays` argument is a list of [SystemUiOverlay] enum values
  /// denoting the overlays to show.
  ///
  /// If a particular overlay is unsupported on the platform, enabling or
  /// disabling that overlay will be ignored.
  ///
  /// The settings here can be overridden by the platform when System UI becomes
  /// necessary for functionality.
  ///
  /// For example, on Android, when the keyboard becomes visible, it will enable the
  /// navigation bar and status bar system UI overlays. When the keyboard is closed,
  /// Android will not restore the previous UI visibility settings, and the UI
  /// visibility cannot be changed until 1 second after the keyboard is closed to
  /// prevent malware locking users from navigation buttons.
  ///
  /// To regain "fullscreen" after text entry, the UI overlays should be set again
  /// after a delay of 1 second. This can be achieved through [restoreSystemUIOverlays]
  /// or calling this again. Otherwise, the original UI overlay settings will be
  /// automatically restored only when the application loses and regains focus.
  static Future<void> setEnabledSystemUIOverlays(List<SystemUiOverlay> overlays) async {
    await SystemChannels.platform.invokeMethod<void>(
      'SystemChrome.setEnabledSystemUIOverlays',
      _stringify(overlays),
    );
  }

  /// Restores the system overlays to the last settings provided via
  /// [setEnabledSystemUIOverlays]. May be used when the platform force enables/disables
  /// UI elements.
  ///
  /// For example, when the Android keyboard disables hidden status and navigation bars,
  /// this can be called to re-disable the bars when the keyboard is closed.
  ///
  /// On Android, the system UI cannot be changed until 1 second after the previous
  /// change. This is to prevent malware from permanently hiding navigation buttons.
  static Future<void> restoreSystemUIOverlays() async {
    await SystemChannels.platform.invokeMethod<void>(
      'SystemChrome.restoreSystemUIOverlays',
      null,
    );
  }

  /// Specifies the style to use for the system overlays that are visible (if
  /// any).
  ///
  /// This method will schedule the embedder update to be run in a microtask.
  /// Any subsequent calls to this method during the current event loop will
  /// overwrite the pending value, such that only the last specified value takes
  /// effect.
  ///
  /// Call this API in code whose lifecycle matches that of the desired
  /// system UI styles. For instance, to change the system UI style on a new
  /// page, consider calling when pushing/popping a new [PageRoute].
  ///
  /// However, the [AppBar] widget automatically sets the system overlay style
  /// based on its [AppBar.brightness], so configure that instead of calling
  /// this method directly. Likewise, do the same for [CupertinoNavigationBar]
  /// via [CupertinoNavigationBar.backgroundColor].
  ///
  /// If a particular style is not supported on the platform, selecting it will
  /// have no effect.
  ///
  /// {@tool snippet}
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  ///   return Placeholder();
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// For more complex control of the system overlay styles, consider using
  /// an [AnnotatedRegion] widget instead of calling [setSystemUIOverlayStyle]
  /// directly. This widget places a value directly into the layer tree where
  /// it can be hit-tested by the framework. On every frame, the framework will
  /// hit-test and select the annotated region it finds under the status and
  /// navigation bar and synthesize them into a single style. This can be used
  /// to configure the system styles when an app bar is not used.
  ///
  /// {@tool sample --template=stateful_widget_material}
  /// The following example creates a widget that changes the status bar color
  /// to a random value on Android.
  ///
  /// ```dart imports
  /// import 'package:flutter/services.dart';
  /// import 'dart:math' as math;
  /// ```
  ///
  /// ```dart
  /// final _random = math.Random();
  /// SystemUiOverlayStyle _currentStyle = SystemUiOverlayStyle.light;
  ///
  /// void _changeColor() {
  ///   final color = Color.fromRGBO(
  ///     _random.nextInt(255),
  ///     _random.nextInt(255),
  ///     _random.nextInt(255),
  ///     1.0,
  ///   );
  ///   setState(() {
  ///     _currentStyle = SystemUiOverlayStyle.dark.copyWith(
  ///       statusBarColor: color,
  ///     );
  ///   });
  /// }
  ///
  /// @override
  /// Widget build(BuildContext context) {
  ///   return AnnotatedRegion(
  ///     value: _currentStyle,
  ///     child: Center(
  ///       child: ElevatedButton(
  ///         child: const Text('Change Color'),
  ///         onPressed: _changeColor,
  ///        ),
  ///      ),
  ///    );
  ///  }
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [AnnotatedRegion], the widget used to place data into the layer tree.
  static void setSystemUIOverlayStyle(SystemUiOverlayStyle style) {
    assert(style != null);
    if (_pendingStyle != null) {
      // The microtask has already been queued; just update the pending value.
      _pendingStyle = style;
      return;
    }
    if (style == _latestStyle) {
      // Trivial success: no microtask has been queued and the given style is
      // already in effect, so no need to queue a microtask.
      return;
    }
    _pendingStyle = style;
    scheduleMicrotask(() {
      assert(_pendingStyle != null);
      if (_pendingStyle != _latestStyle) {
        SystemChannels.platform.invokeMethod<void>(
          'SystemChrome.setSystemUIOverlayStyle',
          _pendingStyle!._toMap(),
        );
        _latestStyle = _pendingStyle;
      }
      _pendingStyle = null;
    });
  }

  static SystemUiOverlayStyle? _pendingStyle;

  /// The last style that was set using [SystemChrome.setSystemUIOverlayStyle].
  @visibleForTesting
  static SystemUiOverlayStyle? get latestStyle => _latestStyle;
  static SystemUiOverlayStyle? _latestStyle;
}

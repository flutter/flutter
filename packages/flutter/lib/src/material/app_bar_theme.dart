// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'app_bar.dart';
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

// Examples can assume:
// late BuildContext context;

/// Defines default property values for descendant [AppBar] widgets.
///
/// Descendant widgets obtain the current [AppBarThemeData] object with
/// [AppBarTheme.of]. Instances of [AppBarThemeData] can be customized
/// with [AppBarThemeData.copyWith].
///
/// Typically an [AppBarThemeData] is specified as part of the overall [Theme] with
/// [ThemeData.appBarTheme].
///
/// All [AppBarTheme] properties are `null` by default. When null, the
//  [AppBar] constructor provides defaults.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
class AppBarTheme extends InheritedTheme with Diagnosticable {
  /// Creates a theme that can be used for [ThemeData.appBarTheme].
  const AppBarTheme({
    super.key,
    @Deprecated(
      'Use backgroundColor instead. '
      'This feature was deprecated after v3.33.0-0.2.pre.',
    )
    Color? color,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    double? scrolledUnderElevation,
    Color? shadowColor,
    Color? surfaceTintColor,
    ShapeBorder? shape,
    IconThemeData? iconTheme,
    IconThemeData? actionsIconTheme,
    bool? centerTitle,
    double? titleSpacing,
    double? leadingWidth,
    double? toolbarHeight,
    TextStyle? toolbarTextStyle,
    TextStyle? titleTextStyle,
    SystemUiOverlayStyle? systemOverlayStyle,
    EdgeInsetsGeometry? actionsPadding,
    AppBarThemeData? data,
    Widget? child,
  }) : assert(
         color == null || backgroundColor == null,
         'The color and backgroundColor parameters mean the same thing. Only specify one.',
       ),
       assert(
         data == null ||
             (color ??
                     backgroundColor ??
                     foregroundColor ??
                     elevation ??
                     scrolledUnderElevation ??
                     shadowColor ??
                     surfaceTintColor ??
                     shape ??
                     iconTheme ??
                     actionsIconTheme ??
                     centerTitle ??
                     titleSpacing ??
                     leadingWidth ??
                     toolbarHeight ??
                     toolbarTextStyle ??
                     titleTextStyle ??
                     systemOverlayStyle ??
                     actionsPadding) ==
                 null,
       ),
       _backgroundColor = backgroundColor ?? color,
       _foregroundColor = foregroundColor,
       _elevation = elevation,
       _scrolledUnderElevation = scrolledUnderElevation,
       _shadowColor = shadowColor,
       _surfaceTintColor = surfaceTintColor,
       _shape = shape,
       _iconTheme = iconTheme,
       _actionsIconTheme = actionsIconTheme,
       _centerTitle = centerTitle,
       _titleSpacing = titleSpacing,
       _leadingWidth = leadingWidth,
       _toolbarHeight = toolbarHeight,
       _toolbarTextStyle = toolbarTextStyle,
       _titleTextStyle = titleTextStyle,
       _systemOverlayStyle = systemOverlayStyle,
       _actionsPadding = actionsPadding,
       _data = data,
       super(child: child ?? const SizedBox());

  final AppBarThemeData? _data;
  final Color? _backgroundColor;
  final Color? _foregroundColor;
  final double? _elevation;
  final double? _scrolledUnderElevation;
  final Color? _shadowColor;
  final Color? _surfaceTintColor;
  final ShapeBorder? _shape;
  final IconThemeData? _iconTheme;
  final IconThemeData? _actionsIconTheme;
  final bool? _centerTitle;
  final double? _titleSpacing;
  final double? _leadingWidth;
  final double? _toolbarHeight;
  final TextStyle? _toolbarTextStyle;
  final TextStyle? _titleTextStyle;
  final SystemUiOverlayStyle? _systemOverlayStyle;
  final EdgeInsetsGeometry? _actionsPadding;

  /// Overrides the default value of [AppBar.backgroundColor] in all
  /// descendant [AppBar] widgets.
  ///
  /// See also:
  ///
  ///  * [foregroundColor], which overrides the default value of
  ///    [AppBar.foregroundColor] in all descendant [AppBar] widgets.
  Color? get backgroundColor => _data != null ? _data.backgroundColor : _backgroundColor;

  /// Overrides the default value of [AppBar.foregroundColor] in all
  /// descendant [AppBar] widgets.
  ///
  /// See also:
  ///
  ///  * [backgroundColor], which overrides the default value of
  ///    [AppBar.backgroundColor] in all descendant [AppBar] widgets.
  Color? get foregroundColor => _data != null ? _data.foregroundColor : _foregroundColor;

  /// Overrides the default value of [AppBar.elevation] in all
  /// descendant [AppBar] widgets.
  double? get elevation => _data != null ? _data.elevation : _elevation;

  /// Overrides the default value of [AppBar.scrolledUnderElevation] in all
  /// descendant [AppBar] widgets.
  double? get scrolledUnderElevation =>
      _data != null ? _data.scrolledUnderElevation : _scrolledUnderElevation;

  /// Overrides the default value of [AppBar.shadowColor] in all
  /// descendant [AppBar] widgets.
  Color? get shadowColor => _data != null ? _data.shadowColor : _shadowColor;

  /// Overrides the default value of [AppBar.surfaceTintColor] in all
  /// descendant [AppBar] widgets.
  Color? get surfaceTintColor => _data != null ? _data.surfaceTintColor : _surfaceTintColor;

  /// Overrides the default value of [AppBar.shape] in all
  /// descendant [AppBar] widgets.
  ShapeBorder? get shape => _data != null ? _data.shape : _shape;

  /// Overrides the default value of [AppBar.iconTheme] in all
  /// descendant [AppBar] widgets.
  ///
  /// See also:
  ///
  ///  * [actionsIconTheme], which overrides the default value of
  ///    [AppBar.actionsIconTheme] in all descendant [AppBar] widgets.
  ///  * [foregroundColor], which overrides the default value
  ///    [AppBar.foregroundColor] in all descendant [AppBar] widgets.
  IconThemeData? get iconTheme => _data != null ? _data.iconTheme : _iconTheme;

  /// Overrides the default value of [AppBar.actionsIconTheme] in all
  /// descendant [AppBar] widgets.
  ///
  /// See also:
  ///
  ///  * [iconTheme], which overrides the default value of
  ///    [AppBar.iconTheme] in all descendant [AppBar] widgets.
  ///  * [foregroundColor], which overrides the default value
  ///    [AppBar.foregroundColor] in all descendant [AppBar] widgets.
  IconThemeData? get actionsIconTheme => _data != null ? _data.actionsIconTheme : _actionsIconTheme;

  /// Overrides the default value of [AppBar.centerTitle]
  /// property in all descendant [AppBar] widgets.
  bool? get centerTitle => _data != null ? _data.centerTitle : _centerTitle;

  /// Overrides the default value of the obsolete [AppBar.titleSpacing]
  /// property in all descendant [AppBar] widgets.
  ///
  /// If null, [AppBar] uses default value of [NavigationToolbar.kMiddleSpacing].
  double? get titleSpacing => _data != null ? _data.titleSpacing : _titleSpacing;

  /// Overrides the default value of the [AppBar.leadingWidth]
  /// property in all descendant [AppBar] widgets.
  double? get leadingWidth => _data != null ? _data.leadingWidth : _leadingWidth;

  /// Overrides the default value of the [AppBar.toolbarHeight]
  /// property in all descendant [AppBar] widgets.
  ///
  /// See also:
  ///
  ///  * [AppBar.preferredHeightFor], which computes the overall
  ///    height of an AppBar widget, taking this value into account.
  double? get toolbarHeight => _data != null ? _data.toolbarHeight : _toolbarHeight;

  /// Overrides the default value of the obsolete [AppBar.toolbarTextStyle]
  /// property in all descendant [AppBar] widgets.
  ///
  /// See also:
  ///
  ///  * [titleTextStyle], which overrides the default of [AppBar.titleTextStyle]
  ///    in all descendant [AppBar] widgets.
  TextStyle? get toolbarTextStyle => _data != null ? _data.toolbarTextStyle : _toolbarTextStyle;

  /// Overrides the default value of [AppBar.titleTextStyle]
  /// property in all descendant [AppBar] widgets.
  ///
  /// See also:
  ///
  ///  * [toolbarTextStyle], which overrides the default of [AppBar.toolbarTextStyle]
  ///    in all descendant [AppBar] widgets.
  TextStyle? get titleTextStyle => _data != null ? _data.titleTextStyle : _titleTextStyle;

  /// Overrides the default value of [AppBar.systemOverlayStyle]
  /// property in all descendant [AppBar] widgets.
  SystemUiOverlayStyle? get systemOverlayStyle =>
      _data != null ? _data.systemOverlayStyle : _systemOverlayStyle;

  /// Overrides the default value of [AppBar.actionsPadding]
  /// property in all descendant [AppBar] widgets.
  EdgeInsetsGeometry? get actionsPadding => _data != null ? _data.actionsPadding : _actionsPadding;

  /// The properties used for all descendant [AppBar] widgets.
  AppBarThemeData get data =>
      _data ??
      AppBarThemeData(
        backgroundColor: _backgroundColor,
        foregroundColor: _foregroundColor,
        elevation: _elevation,
        scrolledUnderElevation: _scrolledUnderElevation,
        shadowColor: _shadowColor,
        surfaceTintColor: _surfaceTintColor,
        shape: _shape,
        iconTheme: _iconTheme,
        actionsIconTheme: _actionsIconTheme,
        centerTitle: _centerTitle,
        titleSpacing: _titleSpacing,
        leadingWidth: _leadingWidth,
        toolbarHeight: _toolbarHeight,
        toolbarTextStyle: _toolbarTextStyle,
        titleTextStyle: _titleTextStyle,
        systemOverlayStyle: _systemOverlayStyle,
        actionsPadding: _actionsPadding,
      );

  /// Creates a copy of this object with the given fields replaced with the
  /// new values.
  ///
  /// This method is obsolete and will be deprecated in a future release:
  /// please use the [AppBarThemeData.copyWith] method instead.
  AppBarTheme copyWith({
    IconThemeData? actionsIconTheme,
    @Deprecated(
      'Use backgroundColor instead. '
      'This feature was deprecated after v3.33.0-0.2.pre.',
    )
    Color? color,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    double? scrolledUnderElevation,
    Color? shadowColor,
    Color? surfaceTintColor,
    ShapeBorder? shape,
    IconThemeData? iconTheme,
    bool? centerTitle,
    double? titleSpacing,
    double? leadingWidth,
    double? toolbarHeight,
    TextStyle? toolbarTextStyle,
    TextStyle? titleTextStyle,
    SystemUiOverlayStyle? systemOverlayStyle,
    EdgeInsetsGeometry? actionsPadding,
  }) {
    assert(
      color == null || backgroundColor == null,
      'The color and backgroundColor parameters mean the same thing. Only specify one.',
    );
    return AppBarTheme(
      backgroundColor: backgroundColor ?? color ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      elevation: elevation ?? this.elevation,
      scrolledUnderElevation: scrolledUnderElevation ?? this.scrolledUnderElevation,
      shadowColor: shadowColor ?? this.shadowColor,
      surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
      shape: shape ?? this.shape,
      iconTheme: iconTheme ?? this.iconTheme,
      actionsIconTheme: actionsIconTheme ?? this.actionsIconTheme,
      centerTitle: centerTitle ?? this.centerTitle,
      titleSpacing: titleSpacing ?? this.titleSpacing,
      leadingWidth: leadingWidth ?? this.leadingWidth,
      toolbarHeight: toolbarHeight ?? this.toolbarHeight,
      toolbarTextStyle: toolbarTextStyle ?? this.toolbarTextStyle,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      systemOverlayStyle: systemOverlayStyle ?? this.systemOverlayStyle,
      actionsPadding: actionsPadding ?? this.actionsPadding,
    );
  }

  /// Retrieves the [AppBarThemeData] from the closest ancestor [AppBarTheme].
  ///
  /// If there is no enclosing [AppBarTheme] widget, then
  /// [ThemeData.appBarTheme] is used.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// AppBarThemeData theme = AppBarTheme.of(context);
  /// ```
  static AppBarThemeData of(BuildContext context) {
    final AppBarTheme? appBarTheme = context.dependOnInheritedWidgetOfExactType<AppBarTheme>();
    return appBarTheme?.data ?? Theme.of(context).appBarTheme;
  }

  /// Linearly interpolate between two AppBar themes.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static AppBarTheme lerp(AppBarTheme? a, AppBarTheme? b, double t) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return AppBarTheme(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      foregroundColor: Color.lerp(a?.foregroundColor, b?.foregroundColor, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      scrolledUnderElevation: lerpDouble(a?.scrolledUnderElevation, b?.scrolledUnderElevation, t),
      shadowColor: Color.lerp(a?.shadowColor, b?.shadowColor, t),
      surfaceTintColor: Color.lerp(a?.surfaceTintColor, b?.surfaceTintColor, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
      iconTheme: IconThemeData.lerp(a?.iconTheme, b?.iconTheme, t),
      actionsIconTheme: IconThemeData.lerp(a?.actionsIconTheme, b?.actionsIconTheme, t),
      centerTitle: t < 0.5 ? a?.centerTitle : b?.centerTitle,
      titleSpacing: lerpDouble(a?.titleSpacing, b?.titleSpacing, t),
      leadingWidth: lerpDouble(a?.leadingWidth, b?.leadingWidth, t),
      toolbarHeight: lerpDouble(a?.toolbarHeight, b?.toolbarHeight, t),
      toolbarTextStyle: TextStyle.lerp(a?.toolbarTextStyle, b?.toolbarTextStyle, t),
      titleTextStyle: TextStyle.lerp(a?.titleTextStyle, b?.titleTextStyle, t),
      systemOverlayStyle: t < 0.5 ? a?.systemOverlayStyle : b?.systemOverlayStyle,
      actionsPadding: EdgeInsetsGeometry.lerp(a?.actionsPadding, b?.actionsPadding, t),
    );
  }

  @override
  bool updateShouldNotify(covariant AppBarTheme oldWidget) => data != oldWidget.data;

  @override
  Widget wrap(BuildContext context, Widget child) {
    return AppBarTheme(data: data, child: child);
  }
}

/// Defines default property values for descendant [AppBar] widgets.
///
/// Descendant widgets obtain the current [AppBarThemeData] object using
/// [AppBarTheme.of]. Instances of [AppBarThemeData] can be
/// customized with [AppBarThemeData.copyWith].
///
/// Typically an [AppBarThemeData] is specified as part of the overall [Theme]
/// with [ThemeData.appBarTheme].
///
/// All [AppBarThemeData] properties are `null` by default. When null, the [AppBar]
/// will use the values from [ThemeData] if they exist, otherwise it will
/// provide its own defaults. See the individual [AppBar] properties for details.
///
/// See also:
///
///  * [AppBar], which is the widget that this theme configures.
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
class AppBarThemeData with Diagnosticable {
  /// Creates an app bar theme that can be used with [ThemeData.appBarTheme].
  const AppBarThemeData({
    this.backgroundColor,
    this.foregroundColor,
    @Deprecated(
      'Use backgroundColor instead. '
      'This feature was deprecated after v3.33.0-0.2.pre.',
    )
    Color? color,
    this.elevation,
    this.scrolledUnderElevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.shape,
    this.iconTheme,
    this.actionsIconTheme,
    this.centerTitle,
    this.titleSpacing,
    this.leadingWidth,
    this.toolbarHeight,
    this.toolbarTextStyle,
    this.titleTextStyle,
    this.systemOverlayStyle,
    this.actionsPadding,
  }) : assert(
         color == null || backgroundColor == null,
         'The color and backgroundColor parameters mean the same thing. Only specify one.',
       );

  /// Overrides the default value of [AppBar.backgroundColor].
  final Color? backgroundColor;

  /// Overrides the default value of [AppBar.foregroundColor].
  final Color? foregroundColor;

  /// Overrides the default value of [AppBar.elevation].
  final double? elevation;

  /// Overrides the default value of [AppBar.scrolledUnderElevation].
  final double? scrolledUnderElevation;

  /// Overrides the default value of [AppBar.shadowColor].
  final Color? shadowColor;

  /// Overrides the default value of [AppBar.surfaceTintColor].
  final Color? surfaceTintColor;

  /// Overrides the default value of [AppBar.shape].
  final ShapeBorder? shape;

  /// Overrides the default value of [AppBar.iconTheme].
  final IconThemeData? iconTheme;

  /// Overrides the default value of [AppBar.actionsIconTheme].
  final IconThemeData? actionsIconTheme;

  /// Overrides the default value of [AppBar.centerTitle].
  final bool? centerTitle;

  /// Overrides the default value of [AppBar.titleSpacing].
  final double? titleSpacing;

  /// Overrides the default value of [AppBar.leadingWidth].
  final double? leadingWidth;

  /// Overrides the default value of [AppBar.toolbarHeight].
  final double? toolbarHeight;

  /// Overrides the default value of [AppBar.toolbarTextStyle].
  final TextStyle? toolbarTextStyle;

  /// Overrides the default value of [AppBar.titleTextStyle].
  final TextStyle? titleTextStyle;

  /// Overrides the default value of [AppBar.systemOverlayStyle].
  final SystemUiOverlayStyle? systemOverlayStyle;

  /// Overrides the default value of [AppBar.actionsPadding].
  final EdgeInsetsGeometry? actionsPadding;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  AppBarThemeData copyWith({
    Color? backgroundColor,
    Color? foregroundColor,
    @Deprecated(
      'Use backgroundColor instead. '
      'This feature was deprecated after v3.33.0-0.2.pre.',
    )
    Color? color,
    double? elevation,
    double? scrolledUnderElevation,
    Color? shadowColor,
    Color? surfaceTintColor,
    ShapeBorder? shape,
    IconThemeData? iconTheme,
    IconThemeData? actionsIconTheme,
    bool? centerTitle,
    double? titleSpacing,
    double? leadingWidth,
    double? toolbarHeight,
    TextStyle? toolbarTextStyle,
    TextStyle? titleTextStyle,
    SystemUiOverlayStyle? systemOverlayStyle,
    EdgeInsetsGeometry? actionsPadding,
  }) {
    return AppBarThemeData(
      backgroundColor: backgroundColor ?? color ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      elevation: elevation ?? this.elevation,
      scrolledUnderElevation: scrolledUnderElevation ?? this.scrolledUnderElevation,
      shadowColor: shadowColor ?? this.shadowColor,
      surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
      shape: shape ?? this.shape,
      iconTheme: iconTheme ?? this.iconTheme,
      actionsIconTheme: actionsIconTheme ?? this.actionsIconTheme,
      centerTitle: centerTitle ?? this.centerTitle,
      titleSpacing: titleSpacing ?? this.titleSpacing,
      leadingWidth: leadingWidth ?? this.leadingWidth,
      toolbarHeight: toolbarHeight ?? this.toolbarHeight,
      toolbarTextStyle: toolbarTextStyle ?? this.toolbarTextStyle,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      systemOverlayStyle: systemOverlayStyle ?? this.systemOverlayStyle,
      actionsPadding: actionsPadding ?? this.actionsPadding,
    );
  }

  /// Linearly interpolate between two app bar themes.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static AppBarThemeData lerp(AppBarThemeData a, AppBarThemeData b, double t) {
    if (identical(a, b)) {
      return a;
    }
    return AppBarThemeData(
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t),
      foregroundColor: Color.lerp(a.foregroundColor, b.foregroundColor, t),
      elevation: lerpDouble(a.elevation, b.elevation, t),
      scrolledUnderElevation: lerpDouble(a.scrolledUnderElevation, b.scrolledUnderElevation, t),
      shadowColor: Color.lerp(a.shadowColor, b.shadowColor, t),
      surfaceTintColor: Color.lerp(a.surfaceTintColor, b.surfaceTintColor, t),
      shape: ShapeBorder.lerp(a.shape, b.shape, t),
      iconTheme: IconThemeData.lerp(a.iconTheme, b.iconTheme, t),
      actionsIconTheme: IconThemeData.lerp(a.actionsIconTheme, b.actionsIconTheme, t),
      centerTitle: t < 0.5 ? a.centerTitle : b.centerTitle,
      titleSpacing: lerpDouble(a.titleSpacing, b.titleSpacing, t),
      leadingWidth: lerpDouble(a.leadingWidth, b.leadingWidth, t),
      toolbarHeight: lerpDouble(a.toolbarHeight, b.toolbarHeight, t),
      toolbarTextStyle: TextStyle.lerp(a.toolbarTextStyle, b.toolbarTextStyle, t),
      titleTextStyle: TextStyle.lerp(a.titleTextStyle, b.titleTextStyle, t),
      systemOverlayStyle: t < 0.5 ? a.systemOverlayStyle : b.systemOverlayStyle,
      actionsPadding: EdgeInsetsGeometry.lerp(a.actionsPadding, b.actionsPadding, t),
    );
  }

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    elevation,
    scrolledUnderElevation,
    shadowColor,
    surfaceTintColor,
    shape,
    iconTheme,
    actionsIconTheme,
    centerTitle,
    titleSpacing,
    leadingWidth,
    toolbarHeight,
    toolbarTextStyle,
    titleTextStyle,
    systemOverlayStyle,
    actionsPadding,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is AppBarThemeData &&
        other.backgroundColor == backgroundColor &&
        other.foregroundColor == foregroundColor &&
        other.elevation == elevation &&
        other.scrolledUnderElevation == scrolledUnderElevation &&
        other.shadowColor == shadowColor &&
        other.surfaceTintColor == surfaceTintColor &&
        other.shape == shape &&
        other.iconTheme == iconTheme &&
        other.actionsIconTheme == actionsIconTheme &&
        other.centerTitle == centerTitle &&
        other.titleSpacing == titleSpacing &&
        other.leadingWidth == leadingWidth &&
        other.toolbarHeight == toolbarHeight &&
        other.toolbarTextStyle == toolbarTextStyle &&
        other.titleTextStyle == titleTextStyle &&
        other.systemOverlayStyle == systemOverlayStyle &&
        other.actionsPadding == actionsPadding;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(ColorProperty('foregroundColor', foregroundColor, defaultValue: null));
    properties.add(DoubleProperty('elevation', elevation, defaultValue: null));
    properties.add(
      DoubleProperty('scrolledUnderElevation', scrolledUnderElevation, defaultValue: null),
    );
    properties.add(ColorProperty('shadowColor', shadowColor, defaultValue: null));
    properties.add(ColorProperty('surfaceTintColor', surfaceTintColor, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
    properties.add(DiagnosticsProperty<IconThemeData>('iconTheme', iconTheme, defaultValue: null));
    properties.add(
      DiagnosticsProperty<IconThemeData>('actionsIconTheme', actionsIconTheme, defaultValue: null),
    );
    properties.add(DiagnosticsProperty<bool>('centerTitle', centerTitle, defaultValue: null));
    properties.add(DoubleProperty('titleSpacing', titleSpacing, defaultValue: null));
    properties.add(DoubleProperty('leadingWidth', leadingWidth, defaultValue: null));
    properties.add(DoubleProperty('toolbarHeight', toolbarHeight, defaultValue: null));
    properties.add(
      DiagnosticsProperty<TextStyle>('toolbarTextStyle', toolbarTextStyle, defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<TextStyle>('titleTextStyle', titleTextStyle, defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<SystemUiOverlayStyle?>(
        'systemOverlayStyle',
        systemOverlayStyle,
        defaultValue: null,
        description: systemOverlayStyle == null
            ? null
            : 'SystemUiOverlayStyle(${<String>[if (systemOverlayStyle?.systemNavigationBarColor != null) 'systemNavigationBarColor: ${systemOverlayStyle?.systemNavigationBarColor}', if (systemOverlayStyle?.systemNavigationBarDividerColor != null) 'systemNavigationBarDividerColor: ${systemOverlayStyle?.systemNavigationBarDividerColor}', if (systemOverlayStyle?.systemNavigationBarIconBrightness != null) 'systemNavigationBarIconBrightness: ${systemOverlayStyle?.systemNavigationBarIconBrightness}', if (systemOverlayStyle?.statusBarColor != null) 'statusBarColor: ${systemOverlayStyle?.statusBarColor}', if (systemOverlayStyle?.statusBarBrightness != null) 'statusBarBrightness: ${systemOverlayStyle?.statusBarBrightness}', if (systemOverlayStyle?.statusBarIconBrightness != null) 'statusBarIconBrightness: ${systemOverlayStyle?.statusBarIconBrightness}', if (systemOverlayStyle?.systemStatusBarContrastEnforced != null) 'systemStatusBarContrastEnforced: ${systemOverlayStyle?.systemStatusBarContrastEnforced}', if (systemOverlayStyle?.systemNavigationBarContrastEnforced != null) 'systemNavigationBarContrastEnforced: ${systemOverlayStyle?.systemNavigationBarContrastEnforced}'].where((String s) => s.isNotEmpty).join(', ')})',
      ),
    );
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry?>(
        'actionsPadding',
        actionsPadding,
        defaultValue: null,
      ),
    );
  }
}

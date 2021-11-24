// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'material_state.dart';
import 'theme.dart';

const double _kArrowButtonsWidth = 8.0;
const Color _kActiveArrowColor = Color(0xFF505050);
const Color _kInactiveArrowColor = Color(0xFFA3A3A3);
const Color _kHoveredBackgroundColor = Color(0xFFD2D2D2);
const Color _kPressedBackgroundColor = Color(0xFF787878);
const Color _kWhiteColor = Color(0xFFFFFFFF);

/// Defines default property values for descendant [Scrollbar] widgets.
///
/// Descendant widgets obtain the current [ScrollbarThemeData] object with
/// `ScrollbarTheme.of(context)`. Instances of [ScrollbarThemeData] can be customized
/// with [ScrollbarThemeData.copyWith].
///
/// Typically the [ScrollbarThemeData] of a [ScrollbarTheme] is specified as part of the overall
/// [Theme] with [ThemeData.scrollbarTheme].
///
/// All [ScrollbarThemeData] properties are `null` by default. When null, the [Scrollbar]
/// computes its own default values, typically based on the overall theme's
/// [ThemeData.colorScheme].
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
class ScrollbarThemeData with Diagnosticable {
  /// Creates a theme that can be used for [ThemeData.scrollbarTheme].
  const ScrollbarThemeData({
    this.thickness,
    this.showTrackOnHover,
    this.isAlwaysShown,
    this.radius,
    this.buttonStyle,
    this.buttonShape,
    this.thumbColor,
    this.trackColor,
    this.trackBorderColor,
    this.crossAxisMargin,
    this.mainAxisMargin,
    this.minThumbLength,
    this.interactive,
  });

  /// Overrides the default value of [Scrollbar.thickness] in all
  /// descendant [Scrollbar] widgets.
  ///
  /// Resolves in the following states:
  ///  * [MaterialState.hovered] on web and desktop platforms.
  final MaterialStateProperty<double?>? thickness;

  /// Overrides the default value of [Scrollbar.showTrackOnHover] in all
  /// descendant [Scrollbar] widgets.
  final bool? showTrackOnHover;

  /// Overrides the default value of [Scrollbar.isAlwaysShown] in all
  /// descendant [Scrollbar] widgets.
  final bool? isAlwaysShown;

  /// Overrides the default value of [Scrollbar.interactive] in all
  /// descendant [Scrollbar] widgets.
  final bool? interactive;

  /// Overrides the default value of [Scrollbar.radius] in all
  /// descendant widgets.
  final Radius? radius;

  /// Overrides the default value of [Scrollbar.buttonStyle] in all
  /// descendant [Scrollbar] widgets.
  final MaterialStateProperty<ScrollbarButtonStyle?>? buttonStyle;

  /// Overrides the default value of [Scrollbar.buttonShape] in all
  /// descendant [Scrollbar] widgets.
  final ScrollbarButtonShape? buttonShape;

  /// Overrides the default [Color] of the [Scrollbar] thumb in all descendant
  /// [Scrollbar] widgets.
  ///
  /// Resolves in the following states:
  ///  * [MaterialState.dragged].
  ///  * [MaterialState.hovered] on web and desktop platforms.
  final MaterialStateProperty<Color?>? thumbColor;

  /// Overrides the default [Color] of the [Scrollbar] track when
  /// [showTrackOnHover] is true in all descendant [Scrollbar] widgets.
  ///
  /// Resolves in the following states:
  ///  * [MaterialState.hovered] on web and desktop platforms.
  final MaterialStateProperty<Color?>? trackColor;

  /// Overrides the default [Color] of the [Scrollbar] track border when
  /// [showTrackOnHover] is true in all descendant [Scrollbar] widgets.
  ///
  /// Resolves in the following states:
  ///  * [MaterialState.hovered] on web and desktop platforms.
  final MaterialStateProperty<Color?>? trackBorderColor;

  /// Overrides the default value of the [ScrollbarPainter.crossAxisMargin]
  /// property in all descendant [Scrollbar] widgets.
  ///
  /// See also:
  ///
  ///  * [ScrollbarPainter.crossAxisMargin], which sets the distance from the
  ///    scrollbar's side to the nearest edge in logical pixels.
  final double? crossAxisMargin;

  /// Overrides the default value of the [ScrollbarPainter.mainAxisMargin]
  /// property in all descendant [Scrollbar] widgets.
  ///
  /// See also:
  ///
  ///  * [ScrollbarPainter.mainAxisMargin], which sets the distance from the
  ///    scrollbar's start and end to the edge of the viewport in logical pixels.
  final double? mainAxisMargin;

  /// Overrides the default value of the [ScrollbarPainter.minLength]
  /// property in all descendant [Scrollbar] widgets.
  ///
  /// See also:
  ///
  ///  * [ScrollbarPainter.minLength], which sets the preferred smallest size
  ///    the scrollbar can shrink to when the total scrollable extent is large,
  ///    the current visible viewport is small, and the viewport is not
  ///    overscrolled.
  final double? minThumbLength;

  /// Creates a copy of this object with the given fields replaced with the
  /// new values.
  ScrollbarThemeData copyWith({
    MaterialStateProperty<double?>? thickness,
    bool? showTrackOnHover,
    bool? isAlwaysShown,
    bool? interactive,
    Radius? radius,
    MaterialStateProperty<ScrollbarButtonStyle?>? buttonStyle,
    ScrollbarButtonShape? buttonShape,
    MaterialStateProperty<Color?>? thumbColor,
    MaterialStateProperty<Color?>? trackColor,
    MaterialStateProperty<Color?>? trackBorderColor,
    double? crossAxisMargin,
    double? mainAxisMargin,
    double? minThumbLength,
  }) {
    return ScrollbarThemeData(
      thickness: thickness ?? this.thickness,
      showTrackOnHover: showTrackOnHover ?? this.showTrackOnHover,
      isAlwaysShown: isAlwaysShown ?? this.isAlwaysShown,
      interactive: interactive ?? this.interactive,
      radius: radius ?? this.radius,
      buttonStyle: buttonStyle ?? this.buttonStyle,
      buttonShape: buttonShape ?? this.buttonShape,
      thumbColor: thumbColor ?? this.thumbColor,
      trackColor: trackColor ?? this.trackColor,
      trackBorderColor: trackBorderColor ?? this.trackBorderColor,
      crossAxisMargin: crossAxisMargin ?? this.crossAxisMargin,
      mainAxisMargin: mainAxisMargin ?? this.mainAxisMargin,
      minThumbLength: minThumbLength ?? this.minThumbLength,
    );
  }

  /// Linearly interpolate between two Scrollbar themes.
  ///
  /// The argument `t` must not be null.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static ScrollbarThemeData lerp(ScrollbarThemeData? a, ScrollbarThemeData? b, double t) {
    assert(t != null);
    return ScrollbarThemeData(
      thickness: _lerpProperties<double?>(a?.thickness, b?.thickness, t, lerpDouble),
      showTrackOnHover: t < 0.5 ? a?.showTrackOnHover : b?.showTrackOnHover,
      isAlwaysShown: t < 0.5 ? a?.isAlwaysShown : b?.isAlwaysShown,
      interactive: t < 0.5 ? a?.interactive : b?.interactive,
      radius: Radius.lerp(a?.radius, b?.radius, t),
      buttonStyle: _lerpProperties<ScrollbarButtonStyle?>(a?.buttonStyle, b?.buttonStyle, t, (ScrollbarButtonStyle? a, ScrollbarButtonStyle? b, double t) => t < 0.5 ? a : b),
      buttonShape: t < 0.5 ? a?.buttonShape : b?.buttonShape,
      thumbColor: _lerpProperties<Color?>(a?.thumbColor, b?.thumbColor, t, Color.lerp),
      trackColor: _lerpProperties<Color?>(a?.trackColor, b?.trackColor, t, Color.lerp),
      trackBorderColor: _lerpProperties<Color?>(a?.trackBorderColor, b?.trackBorderColor, t, Color.lerp),
      crossAxisMargin: lerpDouble(a?.crossAxisMargin, b?.crossAxisMargin, t),
      mainAxisMargin: lerpDouble(a?.mainAxisMargin, b?.mainAxisMargin, t),
      minThumbLength: lerpDouble(a?.minThumbLength, b?.minThumbLength, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      thickness,
      showTrackOnHover,
      isAlwaysShown,
      interactive,
      radius,
      buttonStyle,
      buttonShape,
      thumbColor,
      trackColor,
      trackBorderColor,
      crossAxisMargin,
      mainAxisMargin,
      minThumbLength,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is ScrollbarThemeData
      && other.thickness == thickness
      && other.showTrackOnHover == showTrackOnHover
      && other.isAlwaysShown == isAlwaysShown
      && other.interactive == interactive
      && other.radius == radius
      && other.buttonStyle == buttonStyle
      && other.buttonShape == buttonShape
      && other.thumbColor == thumbColor
      && other.trackColor == trackColor
      && other.trackBorderColor == trackBorderColor
      && other.crossAxisMargin == crossAxisMargin
      && other.mainAxisMargin == mainAxisMargin
      && other.minThumbLength == minThumbLength;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const ScrollbarThemeData defaultData = ScrollbarThemeData();
    properties.add(DiagnosticsProperty<MaterialStateProperty<double?>>('thickness', thickness, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('showTrackOnHover', showTrackOnHover, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('isAlwaysShown', isAlwaysShown, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('interactive', interactive, defaultValue: null));
    properties.add(DiagnosticsProperty<Radius>('radius', radius, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<ScrollbarButtonStyle?>>('buttonStyle', buttonStyle, defaultValue: defaultData.buttonStyle));
    properties.add(DiagnosticsProperty<ScrollbarButtonShape>('buttonShape', buttonShape, defaultValue: defaultData.buttonShape));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('thumbColor', thumbColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('trackColor', trackColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('trackBorderColor', trackBorderColor, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('crossAxisMargin', crossAxisMargin, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('mainAxisMargin', mainAxisMargin, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('minThumbLength', minThumbLength, defaultValue: null));
  }

  static MaterialStateProperty<T>? _lerpProperties<T>(
    MaterialStateProperty<T>? a,
    MaterialStateProperty<T>? b,
    double t,
    T Function(T?, T?, double) lerpFunction,
  ) {
    // Avoid creating a _LerpProperties object for a common case.
    if (a == null && b == null)
      return null;
    return _LerpProperties<T>(a, b, t, lerpFunction);
  }
}

class _LerpProperties<T> implements MaterialStateProperty<T> {
  const _LerpProperties(this.a, this.b, this.t, this.lerpFunction);

  final MaterialStateProperty<T>? a;
  final MaterialStateProperty<T>? b;
  final double t;
  final T Function(T?, T?, double) lerpFunction;

  @override
  T resolve(Set<MaterialState> states) {
    final T? resolvedA = a?.resolve(states);
    final T? resolvedB = b?.resolve(states);
    return lerpFunction(resolvedA, resolvedB, t);
  }
}

/// Applies a scrollbar theme to descendant [Scrollbar] widgets.
///
/// Descendant widgets obtain the current theme's [ScrollbarThemeData] using
/// [ScrollbarTheme.of]. When a widget uses [ScrollbarTheme.of], it is
/// automatically rebuilt if the theme later changes.
///
/// A scrollbar theme can be specified as part of the overall Material theme
/// using [ThemeData.scrollbarTheme].
///
/// See also:
///
///  * [ScrollbarThemeData], which describes the configuration of a
///    scrollbar theme.
class ScrollbarTheme extends InheritedWidget {
  /// Constructs a scrollbar theme that configures all descendant [Scrollbar]
  /// widgets.
  const ScrollbarTheme({
    Key? key,
    required this.data,
    required Widget child,
  }) : super(key: key, child: child);

  /// The properties used for all descendant [Scrollbar] widgets.
  final ScrollbarThemeData data;

  /// Returns the configuration [data] from the closest [ScrollbarTheme]
  /// ancestor. If there is no ancestor, it returns [ThemeData.scrollbarTheme].
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// ScrollbarThemeData theme = ScrollbarTheme.of(context);
  /// ```
  static ScrollbarThemeData of(BuildContext context) {
    final ScrollbarTheme? scrollbarTheme = context.dependOnInheritedWidgetOfExactType<ScrollbarTheme>();
    return scrollbarTheme?.data ?? Theme.of(context).scrollbarTheme;
  }

  @override
  bool updateShouldNotify(ScrollbarTheme oldWidget) => data != oldWidget.data;
}

/// The leading and trailing Scrollbar buttons that are simple arrows.
class ArrowScrollbarButtonShape extends ScrollbarButtonShape {
  /// This abstract const constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const ArrowScrollbarButtonShape();

  @override
  void paint(
      Canvas canvas,
      Rect leadingButtonRect,
      Set<ScrollbarButtonState> leadingButtonStates,
      Rect trailingButtonRect,
      Set<ScrollbarButtonState> trailingButtonStates,
      ScrollbarButtonStyle buttonStyle,
      Paint trackPaint,
      Paint borderPaint,
      ScrollMetrics scrollMetrics,
      ScrollbarOrientation orientation,
      ) {
    final Rect leadingArrowRect, trailingArrowRect;
    final Offset leadingBorderStart, leadingBorderEnd, trailingBorderStart, trailingBorderEnd;
    final Path leadingPath, trailingPath;
    // If the buttons are grouped layout, paint three divider line.
    final Offset leadingDividerStart, leadingDividerEnd;
    final Offset middleDividerStart, middleDividerEnd;
    final Offset trailingDividerStart, trailingDividerEnd;

    switch(orientation) {
      case ScrollbarOrientation.left:
      case ScrollbarOrientation.right:
        if (orientation == ScrollbarOrientation.left) {
          leadingBorderStart = leadingButtonRect.topRight;
          leadingBorderEnd = leadingButtonRect.bottomRight;
          trailingBorderStart = trailingButtonRect.topRight;
          trailingBorderEnd = trailingButtonRect.bottomRight;
        } else {
          leadingBorderStart = leadingButtonRect.topLeft;
          leadingBorderEnd = leadingButtonRect.bottomLeft;
          trailingBorderStart = trailingButtonRect.topLeft;
          trailingBorderEnd = trailingButtonRect.bottomLeft;
        }

        leadingDividerStart = leadingButtonRect.topLeft;
        leadingDividerEnd = leadingButtonRect.topRight;
        middleDividerStart = leadingButtonRect.bottomLeft;
        middleDividerEnd = leadingButtonRect.bottomRight;
        trailingDividerStart = trailingButtonRect.bottomLeft;
        trailingDividerEnd = trailingButtonRect.bottomRight;

        leadingArrowRect = Rect.fromCenter(
          center: leadingButtonRect.center,
          width: _kArrowButtonsWidth,
          height: _kArrowButtonsWidth / 2.0,
        ).intersect(leadingButtonRect);

        trailingArrowRect = Rect.fromCenter(
          center: trailingButtonRect.center,
          width: _kArrowButtonsWidth,
          height: _kArrowButtonsWidth / 2.0,
        ).intersect(trailingButtonRect);

        leadingPath = Path()
          ..moveTo(leadingArrowRect.topCenter.dx, leadingArrowRect.topCenter.dy)
          ..lineTo(leadingArrowRect.bottomLeft.dx, leadingArrowRect.bottomLeft.dy)
          ..lineTo(leadingArrowRect.bottomRight.dx, leadingArrowRect.bottomRight.dy);
        trailingPath = Path()
          ..moveTo(trailingArrowRect.bottomCenter.dx, trailingArrowRect.bottomCenter.dy)
          ..lineTo(trailingArrowRect.topLeft.dx, trailingArrowRect.topLeft.dy)
          ..lineTo(trailingArrowRect.topRight.dx, trailingArrowRect.topRight.dy);
        break;
      case ScrollbarOrientation.top:
      case ScrollbarOrientation.bottom:
        if (orientation == ScrollbarOrientation.top) {
          leadingBorderStart = leadingButtonRect.bottomLeft;
          leadingBorderEnd = leadingButtonRect.bottomRight;
          trailingBorderStart = trailingButtonRect.bottomLeft;
          trailingBorderEnd = trailingButtonRect.bottomRight;
        } else {
          leadingBorderStart = leadingButtonRect.topLeft;
          leadingBorderEnd = leadingButtonRect.topRight;
          trailingBorderStart = trailingButtonRect.topLeft;
          trailingBorderEnd = trailingButtonRect.topRight;
        }

        leadingDividerStart = leadingButtonRect.topLeft;
        leadingDividerEnd = leadingButtonRect.bottomLeft;
        middleDividerStart = leadingButtonRect.topRight;
        middleDividerEnd = leadingButtonRect.bottomRight;
        trailingDividerStart = trailingButtonRect.topRight;
        trailingDividerEnd = trailingButtonRect.bottomRight;

        leadingArrowRect = Rect.fromCenter(
          center: leadingButtonRect.center,
          width: _kArrowButtonsWidth / 2.0,
          height: _kArrowButtonsWidth,
        ).intersect(leadingButtonRect);

        trailingArrowRect = Rect.fromCenter(
          center: trailingButtonRect.center,
          width: _kArrowButtonsWidth / 2.0,
          height: _kArrowButtonsWidth,
        ).intersect(trailingButtonRect);

        leadingPath = Path()
          ..moveTo(leadingArrowRect.centerLeft.dx, leadingArrowRect.centerLeft.dy)
          ..lineTo(leadingArrowRect.topRight.dx, leadingArrowRect.topRight.dy)
          ..lineTo(leadingArrowRect.bottomRight.dx, leadingArrowRect.bottomRight.dy);
        trailingPath = Path()
          ..moveTo(trailingArrowRect.centerRight.dx, trailingArrowRect.centerRight.dy)
          ..lineTo(trailingArrowRect.topLeft.dx, trailingArrowRect.topLeft.dy)
          ..lineTo(trailingArrowRect.bottomLeft.dx, trailingArrowRect.bottomLeft.dy);
        break;
    }

    final Color leadingBackgroundColor;
    final Color leadingArrowColor;
    if (_isLeadingButtonInteractive(scrollMetrics)) {
      if (leadingButtonStates.contains(ScrollbarButtonState.pressed)) {
        leadingBackgroundColor = _kPressedBackgroundColor;
        leadingArrowColor = _kWhiteColor;
      } else if (leadingButtonStates.contains(ScrollbarButtonState.hovered)) {
        leadingBackgroundColor = _kHoveredBackgroundColor;
        leadingArrowColor = _kActiveArrowColor;
      } else {
        leadingBackgroundColor = trackPaint.color;
        leadingArrowColor = _kActiveArrowColor;
      }
    } else {
      leadingBackgroundColor = trackPaint.color;
      leadingArrowColor = _kInactiveArrowColor;
    }
    // Paint the leading button.
    // background
    canvas.drawRect(leadingButtonRect, Paint()..color = leadingBackgroundColor);
    // arrow
    canvas.drawPath(leadingPath, Paint()..color = leadingArrowColor);
    // border
    canvas.drawLine(leadingBorderStart, leadingBorderEnd, borderPaint);

    final Color trailingBackgroundColor;
    final Color trailingArrowColor;
    if (_isTrailingButtonInteractive(scrollMetrics)) {
      if (trailingButtonStates.contains(ScrollbarButtonState.pressed)) {
        trailingBackgroundColor = _kPressedBackgroundColor;
        trailingArrowColor = _kWhiteColor;
      } else if (trailingButtonStates.contains(ScrollbarButtonState.hovered)) {
        trailingBackgroundColor = _kHoveredBackgroundColor;
        trailingArrowColor = _kActiveArrowColor;
      } else {
        trailingBackgroundColor = trackPaint.color;
        trailingArrowColor = _kActiveArrowColor;
      }
    } else {
      trailingBackgroundColor = trackPaint.color;
      trailingArrowColor = _kInactiveArrowColor;
    }

    // Paint the trailing button.
    // background
    canvas.drawRect(trailingButtonRect, Paint()..color = trailingBackgroundColor);
    // arrow
    canvas.drawPath(trailingPath, Paint()..color = trailingArrowColor);
    // border
    canvas.drawLine(trailingBorderStart, trailingBorderEnd, borderPaint);
    if (buttonStyle == ScrollbarButtonStyle.groupedTrailing || buttonStyle == ScrollbarButtonStyle.groupedLeading) {
      final Paint dividerPaint = Paint()
        ..color = _kHoveredBackgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(leadingDividerStart, leadingDividerEnd, dividerPaint);
      canvas.drawLine(middleDividerStart, middleDividerEnd, dividerPaint);
      canvas.drawLine(trailingDividerStart, trailingDividerEnd, dividerPaint);
    }
  }

  bool _isLeadingButtonInteractive(ScrollMetrics scrollMetrics) {
    switch(scrollMetrics.axisDirection) {
      case AxisDirection.down:
      case AxisDirection.right:
        return scrollMetrics.extentBefore > 0.0;
      case AxisDirection.up:
      case AxisDirection.left:
        return scrollMetrics.extentAfter > 0.0;
    }
  }

  bool _isTrailingButtonInteractive(ScrollMetrics scrollMetrics) {
    switch(scrollMetrics.axisDirection) {
      case AxisDirection.down:
      case AxisDirection.right:
        return scrollMetrics.extentAfter > 0.0;
      case AxisDirection.up:
      case AxisDirection.left:
        return scrollMetrics.extentBefore > 0.0;
    }
  }
}

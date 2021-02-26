// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'button_theme.dart';
import 'material_button.dart';
import 'theme.dart';
import 'theme_data.dart';

/// A Material Design "raised button".
///
/// ### This class is deprecated, please use [ElevatedButton] instead.
///
/// FlatButton, RaisedButton, and OutlineButton have been replaced by
/// [TextButton], [ElevatedButton], and [OutlinedButton] respectively.
/// ButtonTheme has been replaced by [TextButtonTheme],
/// [ElevatedButtonTheme], and [OutlinedButtonTheme]. The original classes
/// will eventually be removed, please migrate code that uses them.
/// There's a detailed migration guide for the new button and button
/// theme classes in
/// [flutter.dev/go/material-button-migration-guide](https://flutter.dev/go/material-button-migration-guide).
@Deprecated(
  'Use ElevatedButton instead. See the migration guide in flutter.dev/go/material-button-migration-guide). '
  'This feature was deprecated after v1.26.0-18.0.pre.'
)
class RaisedButton extends MaterialButton {
  /// Create a filled button.
  ///
  /// The [autofocus] and [clipBehavior] arguments must not be null.
  /// Additionally,  [elevation], [hoverElevation], [focusElevation],
  /// [highlightElevation], and [disabledElevation] must be non-negative, if
  /// specified.
  @Deprecated(
    'Use ElevatedButton instead. See the migration guide in flutter.dev/go/material-button-migration-guide). '
    'This feature was deprecated after v1.26.0-18.0.pre.'
  )
  const RaisedButton({
    Key? key,
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
    ValueChanged<bool>? onHighlightChanged,
    MouseCursor? mouseCursor,
    ButtonTextTheme? textTheme,
    Color? textColor,
    Color? disabledTextColor,
    Color? color,
    Color? disabledColor,
    Color? focusColor,
    Color? hoverColor,
    Color? highlightColor,
    Color? splashColor,
    Brightness? colorBrightness,
    double? elevation,
    double? focusElevation,
    double? hoverElevation,
    double? highlightElevation,
    double? disabledElevation,
    EdgeInsetsGeometry? padding,
    VisualDensity? visualDensity,
    ShapeBorder? shape,
    Clip clipBehavior = Clip.none,
    FocusNode? focusNode,
    bool autofocus = false,
    MaterialTapTargetSize? materialTapTargetSize,
    Duration? animationDuration,
    Widget? child,
  }) : assert(autofocus != null),
       assert(elevation == null || elevation >= 0.0),
       assert(focusElevation == null || focusElevation >= 0.0),
       assert(hoverElevation == null || hoverElevation >= 0.0),
       assert(highlightElevation == null || highlightElevation >= 0.0),
       assert(disabledElevation == null || disabledElevation >= 0.0),
       assert(clipBehavior != null),
       super(
         key: key,
         onPressed: onPressed,
         onLongPress: onLongPress,
         onHighlightChanged: onHighlightChanged,
         mouseCursor: mouseCursor,
         textTheme: textTheme,
         textColor: textColor,
         disabledTextColor: disabledTextColor,
         color: color,
         disabledColor: disabledColor,
         focusColor: focusColor,
         hoverColor: hoverColor,
         highlightColor: highlightColor,
         splashColor: splashColor,
         colorBrightness: colorBrightness,
         elevation: elevation,
         focusElevation: focusElevation,
         hoverElevation: hoverElevation,
         highlightElevation: highlightElevation,
         disabledElevation: disabledElevation,
         padding: padding,
         visualDensity: visualDensity,
         shape: shape,
         clipBehavior: clipBehavior,
         focusNode: focusNode,
         autofocus: autofocus,
         materialTapTargetSize: materialTapTargetSize,
         animationDuration: animationDuration,
         child: child,
       );

  /// Create a filled button from a pair of widgets that serve as the button's
  /// [icon] and [label].
  ///
  /// The icon and label are arranged in a row and padded by 12 logical pixels
  /// at the start, and 16 at the end, with an 8 pixel gap in between.
  ///
  /// The [elevation], [highlightElevation], [disabledElevation], [icon],
  /// [label], and [clipBehavior] arguments must not be null.
  @Deprecated(
    'Use ElevatedButton instead. See the migration guide in flutter.dev/go/material-button-migration-guide). '
    'This feature was deprecated after v1.26.0-18.0.pre.'
  )
  factory RaisedButton.icon({
    Key? key,
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
    ValueChanged<bool>? onHighlightChanged,
    MouseCursor? mouseCursor,
    ButtonTextTheme? textTheme,
    Color? textColor,
    Color? disabledTextColor,
    Color? color,
    Color? disabledColor,
    Color? focusColor,
    Color? hoverColor,
    Color? highlightColor,
    Color? splashColor,
    Brightness? colorBrightness,
    double? elevation,
    double? highlightElevation,
    double? disabledElevation,
    ShapeBorder? shape,
    Clip clipBehavior,
    FocusNode? focusNode,
    bool autofocus,
    EdgeInsetsGeometry? padding,
    MaterialTapTargetSize? materialTapTargetSize,
    Duration? animationDuration,
    required Widget icon,
    required Widget label,
  }) = _RaisedButtonWithIcon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ButtonThemeData buttonTheme = ButtonTheme.of(context);
    return RawMaterialButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      onHighlightChanged: onHighlightChanged,
      mouseCursor: mouseCursor,
      clipBehavior: clipBehavior,
      fillColor: buttonTheme.getFillColor(this),
      textStyle: theme.textTheme.button!.copyWith(color: buttonTheme.getTextColor(this)),
      focusColor: buttonTheme.getFocusColor(this),
      hoverColor: buttonTheme.getHoverColor(this),
      highlightColor: buttonTheme.getHighlightColor(this),
      splashColor: buttonTheme.getSplashColor(this),
      elevation: buttonTheme.getElevation(this),
      focusElevation: buttonTheme.getFocusElevation(this),
      hoverElevation: buttonTheme.getHoverElevation(this),
      highlightElevation: buttonTheme.getHighlightElevation(this),
      disabledElevation: buttonTheme.getDisabledElevation(this),
      padding: buttonTheme.getPadding(this),
      visualDensity: visualDensity ?? theme.visualDensity,
      constraints: buttonTheme.getConstraints(this),
      shape: buttonTheme.getShape(this),
      focusNode: focusNode,
      autofocus: autofocus,
      animationDuration: buttonTheme.getAnimationDuration(this),
      materialTapTargetSize: buttonTheme.getMaterialTapTargetSize(this),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<double>('elevation', elevation, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('focusElevation', focusElevation, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('hoverElevation', hoverElevation, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('highlightElevation', highlightElevation, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('disabledElevation', disabledElevation, defaultValue: null));
  }
}

/// The type of RaisedButtons created with [RaisedButton.icon].
///
/// This class only exists to give RaisedButtons created with [RaisedButton.icon]
/// a distinct class for the sake of [ButtonTheme]. It can not be instantiated.
class _RaisedButtonWithIcon extends RaisedButton with MaterialButtonWithIconMixin {
  _RaisedButtonWithIcon({
    Key? key,
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
    ValueChanged<bool>? onHighlightChanged,
    MouseCursor? mouseCursor,
    ButtonTextTheme? textTheme,
    Color? textColor,
    Color? disabledTextColor,
    Color? color,
    Color? disabledColor,
    Color? focusColor,
    Color? hoverColor,
    Color? highlightColor,
    Color? splashColor,
    Brightness? colorBrightness,
    double? elevation,
    double? highlightElevation,
    double? disabledElevation,
    ShapeBorder? shape,
    Clip clipBehavior = Clip.none,
    FocusNode? focusNode,
    bool autofocus = false,
    EdgeInsetsGeometry? padding,
    MaterialTapTargetSize? materialTapTargetSize,
    Duration? animationDuration,
    required Widget icon,
    required Widget label,
  }) : assert(elevation == null || elevation >= 0.0),
       assert(highlightElevation == null || highlightElevation >= 0.0),
       assert(disabledElevation == null || disabledElevation >= 0.0),
       assert(clipBehavior != null),
       assert(icon != null),
       assert(label != null),
       assert(autofocus != null),
       super(
         key: key,
         onPressed: onPressed,
         onLongPress: onLongPress,
         onHighlightChanged: onHighlightChanged,
         mouseCursor: mouseCursor,
         textTheme: textTheme,
         textColor: textColor,
         disabledTextColor: disabledTextColor,
         color: color,
         disabledColor: disabledColor,
         focusColor: focusColor,
         hoverColor: hoverColor,
         highlightColor: highlightColor,
         splashColor: splashColor,
         colorBrightness: colorBrightness,
         elevation: elevation,
         highlightElevation: highlightElevation,
         disabledElevation: disabledElevation,
         shape: shape,
         clipBehavior: clipBehavior,
         focusNode: focusNode,
         autofocus: autofocus,
         padding: padding,
         materialTapTargetSize: materialTapTargetSize,
         animationDuration: animationDuration,
         child: Row(
           mainAxisSize: MainAxisSize.min,
           children: <Widget>[
             icon,
             const SizedBox(width: 8.0),
             label,
           ],
         ),
       );
}

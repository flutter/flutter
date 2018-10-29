// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'button_theme.dart';
import 'material_button.dart';
import 'theme.dart';
import 'theme_data.dart';

/// A material design "raised button".
///
/// A raised button is based on a [Material] widget whose [Material.elevation]
/// increases when the button is pressed.
///
/// Use raised buttons to add dimension to otherwise mostly flat layouts, e.g.
/// in long busy lists of content, or in wide spaces. Avoid using raised buttons
/// on already-raised content such as dialogs or cards.
///
/// If the [onPressed] callback is null, then the button will be disabled and by
/// default will resemble a flat button in the [disabledColor]. If you are
/// trying to change the button's [color] and it is not having any effect, check
/// that you are passing a non-null [onPressed] handler.
///
/// If you want an ink-splash effect for taps, but don't want to use a button,
/// consider using [InkWell] directly.
///
/// Raised buttons have a minimum size of 88.0 by 36.0 which can be overidden
/// with [ButtonTheme].
///
/// See also:
///
///  * [FlatButton], a material design button without a shadow.
///  * [DropdownButton], a button that shows options to select from.
///  * [FloatingActionButton], the round button in material applications.
///  * [IconButton], to create buttons that just contain icons.
///  * [InkWell], which implements the ink splash part of a flat button.
///  * [RawMaterialButton], the widget this widget is based on.
///  * <https://material.google.com/components/buttons.html>
class RaisedButton extends MaterialButton {
  /// Create a filled button.
  ///
  /// The [elevation], [highlightElevation], [disabledElevation], and
  /// [clipBehavior] arguments must not be null.
  const RaisedButton({
    Key key,
    @required VoidCallback onPressed,
    ValueChanged<bool> onHighlightChanged,
    ButtonTextTheme textTheme,
    Color textColor,
    Color disabledTextColor,
    Color color,
    Color disabledColor,
    Color highlightColor,
    Color splashColor,
    Brightness colorBrightness,
    double elevation,
    double highlightElevation,
    double disabledElevation,
    EdgeInsetsGeometry padding,
    ShapeBorder shape,
    Clip clipBehavior = Clip.none,
    MaterialTapTargetSize materialTapTargetSize,
    Duration animationDuration,
    Widget child,
  }) : assert(elevation == null || elevation >= 0.0),
       assert(highlightElevation == null || highlightElevation >= 0.0),
       assert(disabledElevation == null || disabledElevation >= 0.0),
       super(
         key: key,
         onPressed: onPressed,
         onHighlightChanged: onHighlightChanged,
         textTheme: textTheme,
         textColor: textColor,
         disabledTextColor: disabledTextColor,
         color: color,
         disabledColor: disabledColor,
         highlightColor: highlightColor,
         splashColor: splashColor,
         colorBrightness: colorBrightness,
         elevation: elevation,
         highlightElevation: highlightElevation,
         disabledElevation: disabledElevation,
         padding: padding,
         shape: shape,
         clipBehavior: clipBehavior,
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
  factory RaisedButton.icon({
    Key key,
    @required VoidCallback onPressed,
    ValueChanged<bool> onHighlightChanged,
    ButtonTextTheme textTheme,
    Color textColor,
    Color disabledTextColor,
    Color color,
    Color disabledColor,
    Color highlightColor,
    Color splashColor,
    Brightness colorBrightness,
    double elevation,
    double highlightElevation,
    double disabledElevation,
    ShapeBorder shape,
    Clip clipBehavior,
    MaterialTapTargetSize materialTapTargetSize,
    Duration animationDuration,
    @required Widget icon,
    @required Widget label,
  }) = _RaisedButtonWithIcon;

 @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ButtonThemeData buttonTheme = ButtonTheme.of(context);

    return RawMaterialButton(
      onPressed: onPressed,
      onHighlightChanged: onHighlightChanged,
      clipBehavior: clipBehavior ?? Clip.none,
      fillColor: buttonTheme.getFillColor(this),
      textStyle: theme.textTheme.button.copyWith(color: buttonTheme.getTextColor(this)),
      highlightColor: buttonTheme.getHighlightColor(this),
      splashColor: buttonTheme.getSplashColor(this),
      elevation: buttonTheme.getElevation(this),
      highlightElevation: buttonTheme.getHighlightElevation(this),
      disabledElevation: buttonTheme.getDisabledElevation(this),
      padding: buttonTheme.getPadding(this),
      constraints: buttonTheme.getConstraints(this),
      shape: buttonTheme.getShape(this),
      animationDuration: buttonTheme.getAnimationDuration(this),
      materialTapTargetSize: buttonTheme.getMaterialTapTargetSize(this),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<VoidCallback>('onPressed', onPressed, ifNull: 'disabled'));
    properties.add(DiagnosticsProperty<Color>('textColor', textColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('disabledTextColor', disabledTextColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('color', color, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('disabledColor', disabledColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('highlightColor', highlightColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('splashColor', splashColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Brightness>('colorBrightness', colorBrightness, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('elevation', elevation, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('highlightElevation', highlightElevation, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('disabledElevation', disabledElevation, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
  }
}

/// The type of of RaisedButtons created with [RaisedButton.icon].
///
/// This class only exists to give RaisedButtons created with [RaisedButton.icon]
/// a distinct class for the sake of [ButtonTheme]. It can not be instantiated.
class _RaisedButtonWithIcon extends RaisedButton with MaterialButtonWithIconMixin {
  _RaisedButtonWithIcon({
    Key key,
    @required VoidCallback onPressed,
    ValueChanged<bool> onHighlightChanged,
    ButtonTextTheme textTheme,
    Color textColor,
    Color disabledTextColor,
    Color color,
    Color disabledColor,
    Color highlightColor,
    Color splashColor,
    Brightness colorBrightness,
    double elevation,
    double highlightElevation,
    double disabledElevation,
    ShapeBorder shape,
    Clip clipBehavior = Clip.none,
    MaterialTapTargetSize materialTapTargetSize,
    Duration animationDuration,
    @required Widget icon,
    @required Widget label,
  }) : assert(elevation == null || elevation >= 0.0),
       assert(highlightElevation == null || highlightElevation >= 0.0),
       assert(disabledElevation == null || disabledElevation >= 0.0),
       assert(icon != null),
       assert(label != null),
       super(
         key: key,
         onPressed: onPressed,
         onHighlightChanged: onHighlightChanged,
         textTheme: textTheme,
         textColor: textColor,
         disabledTextColor: disabledTextColor,
         color: color,
         disabledColor: disabledColor,
         highlightColor: highlightColor,
         splashColor: splashColor,
         colorBrightness: colorBrightness,
         elevation: elevation,
         highlightElevation: highlightElevation,
         disabledElevation: disabledElevation,
         shape: shape,
         clipBehavior: clipBehavior,
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

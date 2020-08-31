// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'button_theme.dart';
import 'material_button.dart';
import 'theme.dart';
import 'theme_data.dart';

/// A material design "raised button".
///
/// ### This class is obsolete, please use [ElevatedButton] instead.
///
/// FlatButton, RaisedButton, and OutlineButton have been replaced by
/// TextButton, ElevatedButton, and OutlinedButton respectively.
/// ButtonTheme has been replaced by TextButtonTheme,
/// ElevatedButtonTheme, and OutlinedButtonTheme. The original classes
/// will be deprecated soon, please migrate code that uses them.
/// There's a detailed migration guide for the new button and button
/// theme classes in
/// [flutter.dev/go/material-button-migration-guide](https://flutter.dev/go/material-button-migration-guide).
///
/// A raised button is based on a [Material] widget whose [Material.elevation]
/// increases when the button is pressed.
///
/// Use raised buttons to add dimension to otherwise mostly flat layouts, e.g.
/// in long busy lists of content, or in wide spaces. Avoid using raised buttons
/// on already-raised content such as dialogs or cards.
///
/// If [onPressed] and [onLongPress] callbacks are null, then the button will be disabled and by
/// default will resemble a flat button in the [disabledColor]. If you are
/// trying to change the button's [color] and it is not having any effect, check
/// that you are passing a non-null [onPressed] or [onLongPress] callbacks.
///
/// If you want an ink-splash effect for taps, but don't want to use a button,
/// consider using [InkWell] directly.
///
/// Raised buttons have a minimum size of 88.0 by 36.0 which can be overridden
/// with [ButtonTheme].
///
/// {@tool dartpad --template=stateless_widget_scaffold}
///
/// This sample shows how to render a disabled RaisedButton, an enabled RaisedButton
/// and lastly a RaisedButton with gradient background.
///
/// ![Three raised buttons, one enabled, another disabled, and the last one
/// styled with a blue gradient background](https://flutter.github.io/assets-for-api-docs/assets/material/raised_button.png)
///
/// ```dart
/// Widget build(BuildContext context) {
///   return Center(
///     child: Column(
///       mainAxisSize: MainAxisSize.min,
///       children: <Widget>[
///         const RaisedButton(
///           onPressed: null,
///           child: Text(
///             'Disabled Button',
///             style: TextStyle(fontSize: 20)
///           ),
///         ),
///         const SizedBox(height: 30),
///         RaisedButton(
///           onPressed: () {},
///           child: const Text(
///             'Enabled Button',
///             style: TextStyle(fontSize: 20)
///           ),
///         ),
///         const SizedBox(height: 30),
///         RaisedButton(
///           onPressed: () {},
///           textColor: Colors.white,
///           padding: const EdgeInsets.all(0.0),
///           child: Container(
///             decoration: const BoxDecoration(
///               gradient: LinearGradient(
///                 colors: <Color>[
///                   Color(0xFF0D47A1),
///                   Color(0xFF1976D2),
///                   Color(0xFF42A5F5),
///                 ],
///               ),
///             ),
///             padding: const EdgeInsets.all(10.0),
///             child: const Text(
///               'Gradient Button',
///               style: TextStyle(fontSize: 20)
///             ),
///           ),
///         ),
///       ],
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [FlatButton], a material design button without a shadow.
///  * [DropdownButton], a button that shows options to select from.
///  * [FloatingActionButton], the round button in material applications.
///  * [IconButton], to create buttons that just contain icons.
///  * [InkWell], which implements the ink splash part of a flat button.
///  * [RawMaterialButton], the widget this widget is based on.
///  * <https://material.io/design/components/buttons.html>
///  * Cookbook: [Build a form with validation](https://flutter.dev/docs/cookbook/forms/validation)
class RaisedButton extends MaterialButton {
  /// Create a filled button.
  ///
  /// The [autofocus] and [clipBehavior] arguments must not be null.
  /// Additionally,  [elevation], [hoverElevation], [focusElevation],
  /// [highlightElevation], and [disabledElevation] must be non-negative, if
  /// specified.
  const RaisedButton({
    Key key,
    @required VoidCallback onPressed,
    VoidCallback onLongPress,
    ValueChanged<bool> onHighlightChanged,
    MouseCursor mouseCursor,
    ButtonTextTheme textTheme,
    Color textColor,
    Color disabledTextColor,
    Color color,
    Color disabledColor,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
    Brightness colorBrightness,
    double elevation,
    double focusElevation,
    double hoverElevation,
    double highlightElevation,
    double disabledElevation,
    EdgeInsetsGeometry padding,
    VisualDensity visualDensity,
    ShapeBorder shape,
    Clip clipBehavior = Clip.none,
    FocusNode focusNode,
    bool autofocus = false,
    MaterialTapTargetSize materialTapTargetSize,
    Duration animationDuration,
    Widget child,
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
  factory RaisedButton.icon({
    Key key,
    @required VoidCallback onPressed,
    VoidCallback onLongPress,
    ValueChanged<bool> onHighlightChanged,
    MouseCursor mouseCursor,
    ButtonTextTheme textTheme,
    Color textColor,
    Color disabledTextColor,
    Color color,
    Color disabledColor,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
    Brightness colorBrightness,
    double elevation,
    double highlightElevation,
    double disabledElevation,
    ShapeBorder shape,
    Clip clipBehavior,
    FocusNode focusNode,
    bool autofocus,
    EdgeInsetsGeometry padding,
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
      onLongPress: onLongPress,
      onHighlightChanged: onHighlightChanged,
      mouseCursor: mouseCursor,
      clipBehavior: clipBehavior,
      fillColor: buttonTheme.getFillColor(this),
      textStyle: theme.textTheme.button.copyWith(color: buttonTheme.getTextColor(this)),
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
    Key key,
    @required VoidCallback onPressed,
    VoidCallback onLongPress,
    ValueChanged<bool> onHighlightChanged,
    MouseCursor mouseCursor,
    ButtonTextTheme textTheme,
    Color textColor,
    Color disabledTextColor,
    Color color,
    Color disabledColor,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
    Brightness colorBrightness,
    double elevation,
    double highlightElevation,
    double disabledElevation,
    ShapeBorder shape,
    Clip clipBehavior = Clip.none,
    FocusNode focusNode,
    bool autofocus = false,
    EdgeInsetsGeometry padding,
    MaterialTapTargetSize materialTapTargetSize,
    Duration animationDuration,
    @required Widget icon,
    @required Widget label,
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

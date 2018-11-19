// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'color_scheme.dart';
import 'colors.dart';
import 'constants.dart';
import 'flat_button.dart';
import 'material_button.dart';
import 'outline_button.dart';
import 'raised_button.dart';
import 'theme.dart';
import 'theme_data.dart' show MaterialTapTargetSize;

/// Used with [ButtonTheme] and [ButtonThemeData] to define a button's base
/// colors, and the defaults for the button's minimum size, internal padding,
/// and shape.
///
/// See also:
///
///  * [RaisedButton], [FlatButton], [OutlineButton], which are configured
///    based on the ambient [ButtonTheme].
enum ButtonTextTheme {
  /// Button text is black or white depending on [ThemeData.brightness].
  normal,

  /// Button text is [ThemeData.accentColor].
  accent,

  /// Button text is based on [ThemeData.primaryColor].
  primary,
}

/// Used with [ButtonTheme] and [ButtonThemeData] to define how the button bar
/// should size itself with either constraints or internal padding.
enum ButtonBarLayoutBehavior {
  /// Button bars will be constrained to a minimum height of 52.
  ///
  /// This setting is require to create button bars which conform to the
  /// material specification.
  constrained,

  /// Button bars will calculate their padding from the button theme padding.
  padded,
}

/// Used with [ButtonThemeData] to configure the color and geometry of buttons.
///
/// A button theme can be specified as part of the overall Material theme
/// using [ThemeData.buttonTheme]. The Material theme's button theme data
/// can be overridden with [ButtonTheme].
///
/// The actual appearance of buttons depends on the button theme, the
/// button's enabled state, its elevation (if any), and the overall [Theme].
///
/// See also:
///
///  * [FlatButton] [RaisedButton], and [OutlineButton], which are styled
///    based on the ambient button theme.
///  * [RawMaterialButton], which can be used to configure a button that doesn't
///    depend on any inherited themes.
class ButtonTheme extends InheritedWidget {
  /// Creates a button theme.
  ///
  /// The [textTheme], [minWidth], [height], and [colorScheme] arguments
  /// must not be null.
  ButtonTheme({
    Key key,
    ButtonTextTheme textTheme = ButtonTextTheme.normal,
    ButtonBarLayoutBehavior layoutBehavior = ButtonBarLayoutBehavior.padded,
    double minWidth = 88.0,
    double height = 36.0,
    EdgeInsetsGeometry padding,
    ShapeBorder shape,
    bool alignedDropdown = false,
    Color buttonColor,
    Color disabledColor,
    Color highlightColor,
    Color splashColor,
    ColorScheme colorScheme,
    MaterialTapTargetSize materialTapTargetSize,
    Widget child,
  }) : assert(textTheme != null),
       assert(minWidth != null && minWidth >= 0.0),
       assert(height != null && height >= 0.0),
       assert(alignedDropdown != null),
       assert(layoutBehavior != null),
       data = ButtonThemeData(
         textTheme: textTheme,
         minWidth: minWidth,
         height: height,
         padding: padding,
         shape: shape,
         alignedDropdown: alignedDropdown,
         layoutBehavior: layoutBehavior,
         buttonColor: buttonColor,
         disabledColor: disabledColor,
         highlightColor: highlightColor,
         splashColor: splashColor,
         colorScheme: colorScheme,
         materialTapTargetSize: materialTapTargetSize,
       ),
       super(key: key, child: child);

  /// Creates a button theme from [data].
  ///
  /// The [data] argument must not be null.
  const ButtonTheme.fromButtonThemeData({
    Key key,
    @required this.data,
    Widget child,
  }) : assert(data != null),
       super(key: key, child: child);

  /// Creates a button theme that is appropriate for button bars, as used in
  /// dialog footers and in the headers of data tables.
  ///
  /// This theme is denser, with a smaller [minWidth] and [padding], than the
  /// default theme. Also, this theme uses [ButtonTextTheme.accent] rather than
  /// [ButtonTextTheme.normal].
  ///
  /// For best effect, the label of the button at the edge of the container
  /// should have text that ends up wider than 64.0 pixels. This ensures that
  /// the alignment of the text matches the alignment of the edge of the
  /// container.
  ///
  /// For example, buttons at the bottom of [Dialog] or [Card] widgets use this
  /// button theme.
  ButtonTheme.bar({
    Key key,
    ButtonTextTheme textTheme = ButtonTextTheme.accent,
    double minWidth = 64.0,
    double height = 36.0,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 8.0),
    ShapeBorder shape,
    bool alignedDropdown = false,
    Color buttonColor,
    Color disabledColor,
    Color highlightColor,
    Color splashColor,
    ColorScheme colorScheme,
    Widget child,
    ButtonBarLayoutBehavior layoutBehavior = ButtonBarLayoutBehavior.padded,
  }) : assert(textTheme != null),
       assert(minWidth != null && minWidth >= 0.0),
       assert(height != null && height >= 0.0),
       assert(alignedDropdown != null),
       data = ButtonThemeData(
         textTheme: textTheme,
         minWidth: minWidth,
         height: height,
         padding: padding,
         shape: shape,
         alignedDropdown: alignedDropdown,
         layoutBehavior: layoutBehavior,
         buttonColor: buttonColor,
         disabledColor: disabledColor,
         highlightColor: highlightColor,
         splashColor: splashColor,
         colorScheme: colorScheme,
       ),
       super(key: key, child: child);

  /// Specifies the color and geometry of buttons.
  final ButtonThemeData data;

  /// The closest instance of this class that encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// ButtonThemeData theme = ButtonTheme.of(context);
  /// ```
  static ButtonThemeData of(BuildContext context) {
    final ButtonTheme inheritedButtonTheme = context.inheritFromWidgetOfExactType(ButtonTheme);
    ButtonThemeData buttonTheme = inheritedButtonTheme?.data;
    if (buttonTheme?.colorScheme == null) { // if buttonTheme or buttonTheme.colorScheme is null
      final ThemeData theme = Theme.of(context);
      buttonTheme ??= theme.buttonTheme;
      if (buttonTheme.colorScheme == null) {
        buttonTheme = buttonTheme.copyWith(
          colorScheme: theme.buttonTheme.colorScheme ?? theme.colorScheme,
        );
        assert(buttonTheme.colorScheme != null);
      }
    }
    return buttonTheme;
  }

  @override
  bool updateShouldNotify(ButtonTheme oldWidget) => data != oldWidget.data;
}

/// Used with [ButtonTheme] to configure the color and geometry of buttons.
///
/// A button theme can be specified as part of the overall Material theme
/// using [ThemeData.buttonTheme]. The Material theme's button theme data
/// can be overridden with [ButtonTheme].
class ButtonThemeData extends Diagnosticable {
  /// Create a button theme object that can be used with [ButtonTheme]
  /// or [ThemeData].
  ///
  /// The [textTheme], [minWidth], [height], [alignedDropDown], and
  /// [layoutBehavior] parameters must not be null. The [minWidth] and
  /// [height] parameters must greater than or equal to zero.
  ///
  /// The ButtonTheme's methods that have a [MaterialButton] parameter and
  /// have a name with a `get` prefix are used by [RaisedButton],
  /// [OutlineButton], and [FlatButton] to configure a [RawMaterialButton].
  const ButtonThemeData({
    this.textTheme = ButtonTextTheme.normal,
    this.minWidth = 88.0,
    this.height = 36.0,
    EdgeInsetsGeometry padding,
    ShapeBorder shape,
    this.layoutBehavior = ButtonBarLayoutBehavior.padded,
    this.alignedDropdown = false,
    Color buttonColor,
    Color disabledColor,
    Color highlightColor,
    Color splashColor,
    this.colorScheme,
    MaterialTapTargetSize materialTapTargetSize,
  }) : assert(textTheme != null),
       assert(minWidth != null && minWidth >= 0.0),
       assert(height != null && height >= 0.0),
       assert(alignedDropdown != null),
       assert(layoutBehavior != null),
       _buttonColor = buttonColor,
       _disabledColor = disabledColor,
       _highlightColor = highlightColor,
       _splashColor = splashColor,
       _padding = padding,
       _shape = shape,
       _materialTapTargetSize = materialTapTargetSize;

  /// The minimum width for buttons.
  ///
  /// The actual horizontal space allocated for a button's child is
  /// at least this value less the theme's horizontal [padding].
  ///
  /// Defaults to 88.0 logical pixels.
  final double minWidth;

  /// The minimum height for buttons.
  ///
  /// Defaults to 36.0 logical pixels.
  final double height;

  /// Defines a button's base colors, and the defaults for the button's minimum
  /// size, internal padding, and shape.
  ///
  /// Despite the name, this property is not a [TextTheme], its value is not a
  /// collection of [TextStyle]s.
  final ButtonTextTheme textTheme;

  /// Defines whether a [ButtonBar] should size itself with a minimum size
  /// constraint or with padding.
  ///
  /// Defaults to [ButtonBarLayoutBehavior.padded].
  final ButtonBarLayoutBehavior layoutBehavior;

  /// Simply a convenience that returns [minWidth] and [height] as a
  /// [BoxConstraints] object:
  /// ```dart
  /// return BoxConstraints(
  ///   minWidth: minWidth,
  ///   minHeight: height,
  /// );
  /// ```
  BoxConstraints get constraints {
    return BoxConstraints(
      minWidth: minWidth,
      minHeight: height,
    );
  }

  /// Padding for a button's child (typically the button's label).
  ///
  /// Defaults to 24.0 on the left and right if [textTheme] is
  /// [ButtonTextTheme.primary], 16.0 on the left and right otherwise.
  ///
  /// See also:
  ///
  ///  * [getPadding], which is used by [RaisedButton], [OutlineButton]
  ///    and [FlatButton].
  EdgeInsetsGeometry get padding {
    if (_padding != null)
      return _padding;
   switch (textTheme) {
      case ButtonTextTheme.normal:
      case ButtonTextTheme.accent:
        return const EdgeInsets.symmetric(horizontal: 16.0);
      case ButtonTextTheme.primary:
       return const EdgeInsets.symmetric(horizontal: 24.0);
    }
    assert(false);
    return EdgeInsets.zero;
  }
  final EdgeInsetsGeometry _padding;

  /// The shape of a button's material.
  ///
  /// The button's highlight and splash are clipped to this shape. If the
  /// button has an elevation, then its drop shadow is defined by this
  /// shape as well.
  ///
  /// Defaults to a rounded rectangle with circular corner radii of 4.0 if
  /// [textTheme] is [ButtonTextTheme.primary], a rounded rectangle with
  /// circular corner radii of 2.0 otherwise.
  ///
  /// See also:
  ///
  ///  * [getShape], which is used by [RaisedButton], [OutlineButton]
  ///    and [FlatButton].
  ShapeBorder get shape {
    if (_shape != null)
      return _shape;
    switch (textTheme) {
      case ButtonTextTheme.normal:
      case ButtonTextTheme.accent:
        return const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2.0)),
        );
      case ButtonTextTheme.primary:
        return const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        );
    }
    return const RoundedRectangleBorder();
  }
  final ShapeBorder _shape;

  /// If true, then a [DropdownButton] menu's width will match the button's
  /// width.
  ///
  /// If false (the default), then the dropdown's menu will be wider than
  /// its button. In either case the dropdown button will line up the leading
  /// edge of the menu's value with the leading edge of the values
  /// displayed by the menu items.
  ///
  /// This property only affects [DropdownButton] and its menu.
  final bool alignedDropdown;

  /// The background fill color for [RaisedButton]s.
  ///
  /// This property is null by default.
  ///
  /// See also:
  ///
  ///  * [getFillColor], which is used by [RaisedButton] to compute its
  ///    background fill color.
  final Color _buttonColor;

  /// The background fill color for disabled [RaisedButton]s.
  ///
  /// This property is null by default.
  ///
  /// See also:
  ///
  ///  * [getDisabledFillColor], which is used by [RaisedButton] to compute its
  ///    background fill color.
  final Color _disabledColor;

  /// The color of the overlay that appears when a button is pressed.
  ///
  /// This property is null by default.
  ///
  /// See also:
  ///
  ///  * [getHighlightColor], which is used by [RaisedButton], [OutlineButton]
  ///    and [FlatButton].
  final Color _highlightColor;

  /// The color of the ink "splash" overlay that appears when a button is tapped.
  ///
  /// This property is null by default.
  ///
  /// See also:
  ///
  ///  * [getSplashColor], which is used by [RaisedButton], [OutlineButton]
  ///    and [FlatButton].
  final Color _splashColor;

  /// A set of thirteen colors that can be used to derive the button theme's
  /// colors.
  ///
  /// This property was added much later than the theme's set of highly
  /// specific colors, like [ThemeData.buttonColor], [ThemeData.highlightColor],
  /// [ThemeData.splashColor] etc.
  ///
  /// The colors for new button classes can be defined exclusively in terms
  /// of [colorScheme]. When it's possible, the existing buttons will
  /// (continue to) gradually migrate to it.
  final ColorScheme colorScheme;

  // The minimum size of a button's tap target.
  //
  // This property is null by default.
  //
  // See also:
  //
  //  * [getMaterialTargetTapSize], which is used by [RaisedButton],
  //    [OutlineButton] and [FlatButton].
  final MaterialTapTargetSize _materialTapTargetSize;

  /// The [button]'s overall brightness.
  ///
  /// Returns the button's [MaterialButton.colorBrightness] if it is non-null,
  /// otherwise the color scheme's [ColorScheme.brightness] is returned.
  Brightness getBrightness(MaterialButton button) {
    return button.colorBrightness ?? colorScheme.brightness;
  }

  /// Defines the [button]'s base colors, and the defaults for the button's
  /// minimum size, internal padding, and shape.
  ///
  /// Despite the name, this property is not the [TextTheme] whose
  /// [TextTheme.button] is used as the button text's [TextStyle].
  ButtonTextTheme getTextTheme(MaterialButton button) {
    return button.textTheme ?? textTheme;
  }

  Color _getDisabledColor(MaterialButton button) {
    return getBrightness(button) == Brightness.dark
      ? colorScheme.onSurface.withOpacity(0.30)  // default == Colors.white30
      : colorScheme.onSurface.withOpacity(0.38); // default == Colors.black38;
  }

  /// The foreground color of the [button]'s text and icon when
  /// [MaterialButton.onPressed] is null (when MaterialButton.enabled is false).
  ///
  /// Returns the button's [MaterialButton.disabledColor] if it is non-null.
  /// Otherwise the color scheme's [ColorScheme.onSurface] color is returned
  /// with its opacity set to 0.30 if [getBrightness] is dark, 0.38 otherwise.
  Color getDisabledTextColor(MaterialButton button) {
    if (button.disabledTextColor != null)
      return button.disabledTextColor;
    return _getDisabledColor(button);
  }

  /// The [button]'s background color when [MaterialButton.onPressed] is null
  /// (when MaterialButton.enabled is false).
  ///
  /// Returns the button's [MaterialButton.disabledColor] if it is non-null.
  ///
  /// Otherwise the value of the `disabledColor` constructor parameter
  /// is returned, if it is non-null.
  ///
  /// Otherwise the color scheme's [ColorScheme.onSurface] color is returned
  /// with its opacity set to 0.3 if [getBrightness] is dark, 0.38 otherwise.
  Color getDisabledFillColor(MaterialButton button) {
    if (button.disabledColor != null)
      return button.disabledColor;
    if (_disabledColor != null)
      return _disabledColor;
    return _getDisabledColor(button);
  }

  /// The button's background fill color or null for buttons that don't have
  /// a background color.
  ///
  /// Returns [MaterialButton.color] if it is non-null and the button
  /// is enabled.
  ///
  /// Otherwise, returns [MaterialButton.disabledColor] if it is non-null and
  /// the button is disabled.
  ///
  /// Otherwise, if button is a [FlatButton] or an [OutlineButton] then null is
  /// returned.
  ///
  /// Otherwise, if button is a [RaisedButton], returns the `buttonColor`
  /// constructor parameter if it was non-null and the button is enabled.
  ///
  /// Otherwise the fill color depends on the value of [getTextTheme].
  ///
  ///  * [ButtonTextTheme.normal] or [ButtonTextTheme.accent], the
  ///    color scheme's [ColorScheme.primary] color if the [button] is enabled
  ///    the value of [getDisabledFillColor] otherwise.
  ///  * [ButtonTextTheme.primary], if the [button] is enabled then the value
  ///    of the `buttonColor` constructor parameter if it is non-null,
  ///    otherwise the color scheme's ColorScheme.primary color. If the button
  ///    is not enabled then the colorScheme's [ColorScheme.onSurface] color
  ///    with opacity 0.12.
  Color getFillColor(MaterialButton button) {
    final Color fillColor = button.enabled ? button.color : button.disabledColor;
    if (fillColor != null)
      return fillColor;

    if (button is FlatButton || button is OutlineButton)
      return null;

    if (button.enabled && button is RaisedButton && _buttonColor != null)
      return _buttonColor;

    switch (getTextTheme(button)) {
      case ButtonTextTheme.normal:
      case ButtonTextTheme.accent:
        return button.enabled ? colorScheme.primary : getDisabledFillColor(button);
      case ButtonTextTheme.primary:
        return button.enabled
          ? _buttonColor ?? colorScheme.primary
          : colorScheme.onSurface.withOpacity(0.12);
    }

    assert(false);
    return null;
  }

  /// The foreground color of the [button]'s text and icon.
  ///
  /// If [button] is not [MaterialButton.enabled], the value of
  /// [getDisabledTextColor] is returned. If the button is enabled and
  /// [buttonTextColor] is non-null, then [buttonTextColor] is returned.
  ///
  /// Otherwise the text color depends on the value of [getTextTheme]
  /// and [getBrightness].
  ///
  ///  * [ButtonTextTheme.normal], [Colors.white] if [getBrightness] is dark,
  ///    otherwise [Colors.black87].
  ///  * ButtonTextTheme.accent], [colorScheme.secondary].
  ///  * [ButtonTextTheme.primary], if [getFillColor] is dark then [Colors.white],
  ///    otherwise if [button] is a [FlatButton] or an [OutlineButton] then
  ///    [colorScheme.primary], otherwise [Colors.black].
  Color getTextColor(MaterialButton button) {
    if (!button.enabled)
      return getDisabledTextColor(button);

    if (button.textColor != null)
      return button.textColor;

    switch (getTextTheme(button)) {
      case ButtonTextTheme.normal:
        return getBrightness(button) == Brightness.dark ? Colors.white : Colors.black87;

      case ButtonTextTheme.accent:
        return colorScheme.secondary;

      case ButtonTextTheme.primary: {
        final Color fillColor = getFillColor(button);
        final bool fillIsDark = fillColor != null
          ? ThemeData.estimateBrightnessForColor(fillColor) == Brightness.dark
          : getBrightness(button) == Brightness.dark;
        if (fillIsDark)
          return Colors.white;
        if (button is FlatButton || button is OutlineButton)
          return colorScheme.primary;
        return Colors.black;
      }
    }

    assert(false);
    return null;
  }

  /// The color of the ink "splash" overlay that appears when the (enabled)
  /// [button] is tapped.
  ///
  /// Returns the button's [MaterialButton.splashColor] if it is non-null.
  ///
  /// Otherwise, returns the value of the `splashColor` constructor parameter
  /// it is non-null and [button] is a [RaisedButton] or an [OutlineButton].
  ///
  /// Otherwise, returns the value of the `splashColor` constructor parameter
  /// if it is non-null and [button] is a [FlatButton] and
  /// [getTextTheme] is not [ButtonTextTheme.primary]
  ///
  /// Otherwise, returns [getTextColor] with an opacity of 0.12.
  Color getSplashColor(MaterialButton button) {
    if (button.splashColor != null)
      return button.splashColor;

    if (_splashColor != null && (button is RaisedButton || button is OutlineButton))
      return _splashColor;

    if (_splashColor != null && button is FlatButton) {
      switch (getTextTheme(button)) {
        case ButtonTextTheme.normal:
        case ButtonTextTheme.accent:
          return _splashColor;
        case ButtonTextTheme.primary:
          break;
      }
    }

    return getTextColor(button).withOpacity(0.12);
  }

  /// The color of the overlay that appears when the [button] is pressed.
  ///
  /// Returns the button's [MaterialButton.highlightColor] if it is non-null.
  /// Otherwise the highlight color depends on [getTextTheme]:
  ///
  ///  * [ButtonTextTheme.normal], [ButtonTextTheme.accent]: returns the
  ///    value of the `highlightColor` constructor parameter if it is non-null,
  ///    otherwise the value of [getTextColor] with opacity 0.16.
  ///  * [ButtonTextTheme.primary], returns [Colors.transparent].
  Color getHighlightColor(MaterialButton button) {
    if (button.highlightColor != null)
      return button.highlightColor;

    switch (getTextTheme(button)) {
      case ButtonTextTheme.normal:
      case ButtonTextTheme.accent:
        return _highlightColor ?? getTextColor(button).withOpacity(0.16);
      case ButtonTextTheme.primary:
        return Colors.transparent;
    }

    assert(false);
    return Colors.transparent;
  }

  /// The [button]'s elevation when it is enabled and has not been pressed.
  ///
  /// Returns the button's [MaterialButton.elevation] if it is non-null.
  ///
  /// If button is a [FlatButton] then elevation is 0.0, otherwise it is 2.0.
  double getElevation(MaterialButton button) {
    if (button.elevation != null)
      return button.elevation;
    if (button is FlatButton)
      return 0.0;
    return 2.0;
  }

  /// The [button]'s elevation when it is enabled and has been pressed.
  ///
  /// Returns the button's [MaterialButton.highlightElevation] if it is non-null.
  ///
  /// If button is a [FlatButton] then the highlight elevation is 0.0, if it's
  /// a [OutlineButton] then the highlight elevation is 2.0, otherise the
  /// highlight elevation is 8.0.
  double getHighlightElevation(MaterialButton button) {
    if (button.highlightElevation != null)
      return button.highlightElevation;
    if (button is FlatButton)
      return 0.0;
    if (button is OutlineButton)
      return 2.0;
    return 8.0;
  }

  /// The [button]'s elevation when [MaterialButton.onPressed] is null (when
  /// MaterialButton.enabled is false).
  ///
  /// Returns the button's [MaterialButton.elevation] if it is non-null.
  ///
  /// Otheriwse the disabled elevation is 0.0.
  double getDisabledElevation(MaterialButton button) {
    if (button.disabledElevation != null)
      return button.disabledElevation;
    return 0.0;
  }

  /// Padding for the [button]'s child (typically the button's label).
  ///
  /// Returns the button's [MaterialButton.padding] if it is non-null.
  ///
  /// If this is a button constructed with [RaisedButton.icon] or
  /// [FlatButton.icon] or [OutlineButton.icon] then the padding is:
  /// `EdgeInsetsDirectional.only(start: 12.0, end: 16.0)`.
  ///
  /// Otherwise, returns [padding] if it is non-null.
  ///
  /// Otherwise, returns horizontal padding of 24.0 on the left and right if
  /// [getTextTheme] is [ButtonTextTheme.primary], 16.0 on the left and right
  /// otherwise.
  EdgeInsetsGeometry getPadding(MaterialButton button) {
    if (button.padding != null)
      return button.padding;

    if (button is MaterialButtonWithIconMixin)
      return const EdgeInsetsDirectional.only(start: 12.0, end: 16.0);

    if (_padding != null)
      return _padding;

    switch (getTextTheme(button)) {
      case ButtonTextTheme.normal:
      case ButtonTextTheme.accent:
        return const EdgeInsets.symmetric(horizontal: 16.0);
      case ButtonTextTheme.primary:
        return const EdgeInsets.symmetric(horizontal: 24.0);
    }
    assert(false);
    return EdgeInsets.zero;
  }

  /// The shape of the [button]'s [Material].
  ///
  /// Returns the button's [MaterialButton.shape] if it is non-null, otherwise
  /// [shape] is returned.
  ShapeBorder getShape(MaterialButton button) {
    return button.shape ?? shape;
  }

  /// The duration of the [button]'s highlight animation.
  ///
  /// Returns the button's [MaterialButton.animationDuration] it if is non-null,
  /// otherwise 200ms.
  Duration getAnimationDuration(MaterialButton button) {
    return button.animationDuration ?? kThemeChangeDuration;
  }

  /// The [BoxConstraints] that the define the [button]'s size.
  ///
  /// By default this method just returns [constraints]. Subclasses
  /// could override this method to return a value that was,
  /// for example, based on the button's type.
  BoxConstraints getConstraints(MaterialButton button) => constraints;

  /// The minimum size of the [button]'s tap target.
  ///
  /// Returns the button's [MaterialButton.tapTargetSize] if it is non-null.
  ///
  /// Otherwise the value of the [materialTapTargetSize] constructor
  /// parameter is returned if that's non-null.
  ///
  /// Otherwise [MaterialTapTargetSize.padded] is returned.
  MaterialTapTargetSize getMaterialTapTargetSize(MaterialButton button) {
    return button.materialTapTargetSize ?? _materialTapTargetSize ?? MaterialTapTargetSize.padded;
  }

  /// Creates a copy of this button theme data object with the matching fields
  /// replaced with the non-null parameter values.
  ButtonThemeData copyWith({
    ButtonTextTheme textTheme,
    ButtonBarLayoutBehavior layoutBehavior,
    double minWidth,
    double height,
    EdgeInsetsGeometry padding,
    ShapeBorder shape,
    bool alignedDropdown,
    Color buttonColor,
    Color disabledColor,
    Color highlightColor,
    Color splashColor,
    ColorScheme colorScheme,
    MaterialTapTargetSize materialTapTargetSize,
  }) {
    return ButtonThemeData(
      textTheme: textTheme ?? this.textTheme,
      layoutBehavior: layoutBehavior ?? this.layoutBehavior,
      minWidth: minWidth ?? this.minWidth,
      height: height ?? this.height,
      padding: padding ?? this.padding,
      shape: shape ?? this.shape,
      alignedDropdown: alignedDropdown ?? this.alignedDropdown,
      buttonColor: buttonColor ?? _buttonColor,
      disabledColor: disabledColor ?? _disabledColor,
      highlightColor: highlightColor ?? _highlightColor,
      splashColor: splashColor ?? _splashColor,
      colorScheme: colorScheme ?? this.colorScheme,
      materialTapTargetSize: materialTapTargetSize ?? _materialTapTargetSize,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final ButtonThemeData typedOther = other;
    return textTheme == typedOther.textTheme
        && minWidth == typedOther.minWidth
        && height == typedOther.height
        && padding == typedOther.padding
        && shape == typedOther.shape
        && alignedDropdown == typedOther.alignedDropdown
        && _buttonColor == typedOther._buttonColor
        && _disabledColor == typedOther._disabledColor
        && _highlightColor == typedOther._highlightColor
        && _splashColor == typedOther._splashColor
        && colorScheme == typedOther.colorScheme
        && _materialTapTargetSize == typedOther._materialTapTargetSize;
  }

  @override
  int get hashCode {
    return hashValues(
      textTheme,
      minWidth,
      height,
      padding,
      shape,
      alignedDropdown,
      _buttonColor,
      _disabledColor,
      _highlightColor,
      _splashColor,
      colorScheme,
      _materialTapTargetSize,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const ButtonThemeData defaultTheme = ButtonThemeData();
    properties.add(EnumProperty<ButtonTextTheme>('textTheme', textTheme, defaultValue: defaultTheme.textTheme));
    properties.add(DoubleProperty('minWidth', minWidth, defaultValue: defaultTheme.minWidth));
    properties.add(DoubleProperty('height', height, defaultValue: defaultTheme.height));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding, defaultValue: defaultTheme.padding));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: defaultTheme.shape));
    properties.add(FlagProperty('alignedDropdown',
      value: alignedDropdown,
      defaultValue: defaultTheme.alignedDropdown,
      ifTrue: 'dropdown width matches button',
    ));
    properties.add(DiagnosticsProperty<Color>('buttonColor', _buttonColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('disabledColor', _disabledColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('highlightColor', _highlightColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('splashColor', _splashColor, defaultValue: null));
    properties.add(DiagnosticsProperty<ColorScheme>('colorScheme', colorScheme, defaultValue: defaultTheme.colorScheme));
    properties.add(DiagnosticsProperty<MaterialTapTargetSize>('materialTapTargetSize', _materialTapTargetSize, defaultValue: null));
  }
}

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'color_scheme.dart';
import 'colors.dart';
import 'constants.dart';
import 'material_button.dart';
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
/// button's enabled state, its elevation (if any) and the overall Material
/// theme.
///
/// See also:
///
///  * [FlatButton] [RaisedButton], and [OutlineButton], which are styled
///    based on the ambient button theme.
///  * [ThemeData.textTheme], `button` is the default text style for button labels.
///  * [ThemeData.buttonColor], the fill color for [RaisedButton]s unless the
///    button theme's text theme is [ButtonTextTheme.primary].
///  * [ThemeData.primaryColor], the fill or text color if a button theme's text
///    theme is [ButtonTextTheme.primary].
///  * [ThemeData.accentColor], the text color for buttons when button theme's
///    text theme is [ButtonTextTheme.accent].
///  * [ThemeData.disabled], the default text color for disabled buttons.
///  * [ThemeData.brightness], used to select contrasting text and fill colors.
///  * [ThemeData.highlightColor], a button [InkWell]'s default highlight color.
///  * [ThemeData.splashColor], a button [InkWell]'s default splash color.
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
    ColorScheme colorScheme = const ColorScheme.light(),
    MaterialTapTargetSize materialTapTargetSize,
    Widget child,
  }) : assert(textTheme != null),
       assert(minWidth != null && minWidth >= 0.0),
       assert(height != null && height >= 0.0),
       assert(alignedDropdown != null),
       assert(layoutBehavior != null),
       assert(colorScheme != null),
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
    Widget child,
    ButtonBarLayoutBehavior layoutBehavior = ButtonBarLayoutBehavior.padded,
    ColorScheme colorScheme = const ColorScheme.light(),
  }) : assert(textTheme != null),
       assert(minWidth != null && minWidth >= 0.0),
       assert(height != null && height >= 0.0),
       assert(alignedDropdown != null),
       assert(colorScheme != null),
       data = ButtonThemeData(
         textTheme: textTheme,
         minWidth: minWidth,
         height: height,
         padding: padding,
         shape: shape,
         alignedDropdown: alignedDropdown,
         layoutBehavior: layoutBehavior,
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
    final ButtonTheme result = context.inheritFromWidgetOfExactType(ButtonTheme);
    return result?.data ?? Theme.of(context).buttonTheme;
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
  /// The [textTheme], [minWidth], and [height] parameters must not be null.
  const ButtonThemeData({
    this.textTheme = ButtonTextTheme.normal,
    this.minWidth = 88.0,
    this.height = 36.0,
    EdgeInsetsGeometry padding,
    ShapeBorder shape,
    this.layoutBehavior = ButtonBarLayoutBehavior.padded,
    this.alignedDropdown = false,
    this.buttonColor,
    this.disabledColor,
    this.highlightColor,
    this.splashColor,
    this.colorScheme = const ColorScheme.light(),
    this.materialTapTargetSize,
  }) : assert(textTheme != null),
       assert(minWidth != null && minWidth >= 0.0),
       assert(height != null && height >= 0.0),
       assert(alignedDropdown != null),
       assert(layoutBehavior != null),
       assert(colorScheme != null),
       _padding = padding,
       _shape = shape;

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
  final ButtonTextTheme textTheme;

  /// Defines whether a button bar should size itself with a minimum size
  /// constraint or padding.
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

  final Color buttonColor;
  final Color disabledColor;
  final Color highlightColor;
  final Color splashColor;
  final ColorScheme colorScheme;
  final MaterialTapTargetSize materialTapTargetSize;

  Brightness getBrightness(MaterialButton button) {
    return button.colorBrightness ?? colorScheme.brightness;
  }

  ButtonTextTheme getTextTheme(MaterialButton button) {
    return button.textTheme ?? textTheme;
  }

  bool _isFlatButton(MaterialButton button) {
    return button.type == 'FlatButton' || button.type == 'FlatButton.icon';
  }

  bool _isRaisedButton(MaterialButton button) {
    return button.type == 'RaisedButton' || button.type == 'RaisedButton.icon';
  }

  bool _isOutlineButton(MaterialButton button) {
    return button.type == 'OutlineButton' || button.type == 'OutlineButton.icon';
  }

  bool _isIconButton(MaterialButton button) {
    return button.type == 'RaisedButton.icon' || button.type == 'FlatButton.icon' || button.type == 'OutlineButton.icon';
  }

  Color _getDisabledColor(MaterialButton button) {
    return getBrightness(button) == Brightness.dark
      ? colorScheme.onSurface.withOpacity(0.30)  // default == Colors.white30
      : colorScheme.onSurface.withOpacity(0.38); // default == Colors.black38;
  }

  Color getDisabledTextColor(MaterialButton button) {
    if (button.disabledTextColor != null)
      return button.disabledTextColor;
    return _getDisabledColor(button);
  }

  Color getDisabledFillColor(MaterialButton button) {
    if (button.disabledColor != null)
      return button.disabledColor;
    return _getDisabledColor(button);
  }

  Color getFillColor(MaterialButton button) {
    final Color fillColor = button.enabled ? button.color : button.disabledColor;
    if (fillColor != null)
      return fillColor;

    if (_isRaisedButton(button)) {
      if (button.enabled && buttonColor != null)
        return buttonColor;
      if (!button.enabled && disabledColor != null)
        return disabledColor;
    }

    if (_isFlatButton(button) || _isOutlineButton(button))
      return null;

    switch (getTextTheme(button)) {
      case ButtonTextTheme.normal:
      case ButtonTextTheme.accent:
        return button.enabled ? colorScheme.primary : getDisabledFillColor(button);
      case ButtonTextTheme.primary:
        return button.enabled
          ? buttonColor ?? colorScheme.primary
          : colorScheme.onSurface.withOpacity(0.12);
    }

    assert(false);
    return null;
  }

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
        if (_isFlatButton(button) || _isOutlineButton(button))
          return colorScheme.primary;
        return Colors.black;
      }
    }

    assert(false);
    return null;
  }

  Color getSplashColor(MaterialButton button) {
    if (button.splashColor != null)
      return button.splashColor;

    if (splashColor != null && (_isRaisedButton(button) || _isOutlineButton(button)))
      return splashColor;

    if (splashColor != null && _isFlatButton(button)) {
      switch (getTextTheme(button)) {
        case ButtonTextTheme.normal:
        case ButtonTextTheme.accent:
          return splashColor;
        case ButtonTextTheme.primary:
          break;
      }
    }

    return getTextColor(button).withOpacity(0.12);
  }

  Color getHighlightColor(MaterialButton button) {
    if (button.highlightColor != null)
      return button.highlightColor;

    switch (getTextTheme(button)) {
      case ButtonTextTheme.normal:
      case ButtonTextTheme.accent:
        return highlightColor ?? getTextColor(button).withOpacity(0.16);
      case ButtonTextTheme.primary:
        return Colors.transparent;
    }

    assert(false);
    return Colors.transparent;
  }

  double getElevation(MaterialButton button) {
    if (button.elevation != null)
      return button.elevation;
    if (_isFlatButton(button))
      return 0.0;
    return 2.0;
  }

  double getHighlightElevation(MaterialButton button) {
    if (button.highlightElevation != null)
      return button.highlightElevation;
    if (_isFlatButton(button))
      return 0.0;
    if (_isOutlineButton(button))
      return 2.0;
    return 8.0;
  }

  double getDisabledElevation(MaterialButton button) {
    if (button.disabledElevation != null)
      return button.disabledElevation;
    return 0.0;
  }

  EdgeInsetsGeometry getPadding(MaterialButton button) {
    if (button.padding != null)
      return button.padding;
    if (_isIconButton(button))
      return const EdgeInsetsDirectional.only(start: 12.0, end: 16.0);
    return padding;
  }

  BoxConstraints getConstraints(MaterialButton button) => constraints;

  ShapeBorder getShape(MaterialButton button) {
    return button.shape ?? shape;
  }

  Duration getAnimationDuration(MaterialButton button) {
    return button.animationDuration ?? kThemeChangeDuration;
  }

  MaterialTapTargetSize getMaterialTapTargetSize(MaterialButton button) {
    return button.materialTapTargetSize ?? materialTapTargetSize ?? MaterialTapTargetSize.padded;
  }

  /// Creates a copy of this button theme data object with the matching fields
  /// replaced with the non-null parameter values.
  ButtonThemeData copyWith({
    ButtonTextTheme textTheme,
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
      minWidth: minWidth ?? this.minWidth,
      height: height ?? this.height,
      padding: padding ?? this.padding,
      shape: shape ?? this.shape,
      alignedDropdown: alignedDropdown ?? this.alignedDropdown,
      buttonColor: buttonColor ?? this.buttonColor,
      disabledColor: disabledColor ?? this.disabledColor,
      highlightColor: highlightColor ?? this.highlightColor,
      splashColor: splashColor ?? this.splashColor,
      colorScheme: colorScheme ?? this.colorScheme,
      materialTapTargetSize: materialTapTargetSize ?? this.materialTapTargetSize,
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
        && buttonColor == typedOther.buttonColor
        && disabledColor == typedOther.disabledColor
        && highlightColor == typedOther.highlightColor
        && splashColor == typedOther.splashColor
        && colorScheme == typedOther.colorScheme
        && materialTapTargetSize == typedOther.materialTapTargetSize;
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
      buttonColor,
      disabledColor,
      highlightColor,
      splashColor,
      colorScheme,
      materialTapTargetSize,
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
    properties.add(DiagnosticsProperty<Color>('buttonColor', buttonColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('disabledColor', disabledColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('highlightColor', highlightColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('splashColor', splashColor, defaultValue: null));
    properties.add(DiagnosticsProperty<ColorScheme>('colorScheme', colorScheme, defaultValue: defaultTheme.colorScheme));
    properties.add(DiagnosticsProperty<MaterialTapTargetSize>('materialTapTargetSize', materialTapTargetSize, defaultValue: null));
  }
}

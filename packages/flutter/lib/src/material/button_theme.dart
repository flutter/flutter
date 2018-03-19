// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Used with [ButtonTheme] and [ButtonThemeData] to define a button's base
/// colors, and the defaults for the button's minimum size, internal padding,
/// and shape.
///
/// See also:
///
///  * [RaisedButton], which styles itself based on the ambient [ButtonTheme].
///  * [FlatButton], which styles itself based on the ambient [ButtonTheme].
enum ButtonTextTheme {
  /// Button text is black or white depending on [ThemeData.brightness].
  normal,

  /// Button text is [ThemeData.accentColor].
  accent,

  /// Button text is based on [ThemeData.primaryColor].
  primary,
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
///  * [FlatButton] and [RaisedButton], which are styled based on the
///    ambient button theme.
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
  /// The [textTheme], [minWidth], and [height] arguments must not be null.
  ButtonTheme({
    Key key,
    ButtonTextTheme textTheme: ButtonTextTheme.normal,
    double minWidth: 88.0,
    double height: 36.0,
    EdgeInsetsGeometry padding,
    ShapeBorder shape,
    bool alignedDropdown: false,
    Widget child,
  }) : assert(textTheme != null),
       assert(minWidth != null && minWidth >= 0.0),
       assert(height != null && height >= 0.0),
       assert(alignedDropdown != null),
       data = new ButtonThemeData(
         textTheme: textTheme,
         minWidth: minWidth,
         height: height,
         padding: padding,
         shape: shape,
         alignedDropdown: alignedDropdown
       ),
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
    ButtonTextTheme textTheme: ButtonTextTheme.accent,
    double minWidth: 64.0,
    double height: 36.0,
    EdgeInsetsGeometry padding: const EdgeInsets.symmetric(horizontal: 8.0),
    ShapeBorder shape,
    bool alignedDropdown: false,
    Widget child,
  }) : assert(textTheme != null),
       assert(minWidth != null && minWidth >= 0.0),
       assert(height != null && height >= 0.0),
       assert(alignedDropdown != null),
       data = new ButtonThemeData(
         textTheme: textTheme,
         minWidth: minWidth,
         height: height,
         padding: padding,
         shape: shape,
         alignedDropdown: alignedDropdown,
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
  bool updateShouldNotify(ButtonTheme oldTheme) => data != oldTheme.data;
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
    this.textTheme: ButtonTextTheme.normal,
    this.minWidth: 88.0,
    this.height: 36.0,
    EdgeInsetsGeometry padding,
    ShapeBorder shape,
    this.alignedDropdown: false,
  }) : assert(textTheme != null),
       assert(minWidth != null && minWidth >= 0.0),
       assert(height != null && height >= 0.0),
       assert(alignedDropdown != null),
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

  /// Simply a convenience that returns [minWidth] and [height] as a
  /// [BoxConstraints] object:
  /// ```dart
  /// return new BoxConstraints(
  ///   minWidth: minWidth,
  ///    minHeight: height,
  /// );
  /// ```
  BoxConstraints get constraints {
    return new BoxConstraints(
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
          borderRadius: const BorderRadius.all(const Radius.circular(2.0)),
        );
      case ButtonTextTheme.primary:
        return const RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(const Radius.circular(4.0)),
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
        && alignedDropdown == typedOther.alignedDropdown;
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
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    const ButtonThemeData defaultTheme = const ButtonThemeData();
    description.add(new EnumProperty<ButtonTextTheme>('textTheme', textTheme, defaultValue: defaultTheme.textTheme));
    description.add(new DoubleProperty('minWidth', minWidth, defaultValue: defaultTheme.minWidth));
    description.add(new DoubleProperty('height', height, defaultValue: defaultTheme.height));
    description.add(new DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding, defaultValue: defaultTheme.padding));
    description.add(new DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: defaultTheme.shape));
    description.add(new FlagProperty('alignedDropdown',
      value: alignedDropdown,
      defaultValue: defaultTheme.alignedDropdown,
      ifTrue: 'dropdown width matches button',
    ));
  }
}

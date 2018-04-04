// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'theme.dart';
import 'theme_data.dart';

/// Applies a chip theme to descendant [RawChip]-based widgets.
///
/// A chip theme describes the color, shape and text choices for the chips it is
/// applied to
///
/// Descendant widgets obtain the current theme's [ChipThemeData] object using
/// [ChipTheme.of]. When a widget uses [ChipTheme.of], it is automatically
/// rebuilt if the theme later changes.
///
/// See also:
///
///  * [ChipThemeData], which describes the actual configuration of a chip
///    theme.
class ChipTheme extends InheritedWidget {
  /// Applies the given theme [data] to [child].
  ///
  /// The [data] and [child] arguments must not be null.
  const ChipTheme({
    Key key,
    @required this.data,
    @required Widget child,
  })  : assert(child != null),
        assert(data != null),
        super(key: key, child: child);

  /// Specifies the color and shape values for descendant chip widgets.
  final ChipThemeData data;

  /// Returns the data from the closest [ChipTheme] instance that encloses
  /// the given context.
  ///
  /// Defaults to the ambient [ThemeData.chipTheme] if there is no
  /// [ChipTheme] in the given build context.
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// class Launch extends StatelessWidget {
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return new ChipTheme(
  ///       data: ChipTheme.of(context).copyWith(backgroundColor: const Color(0xff804040)),
  ///       child: new ActionChip(
  ///         onPressed: () { print('Launch!'); },
  ///         value: _rocketThrust,
  ///       ),
  ///     );
  ///   }
  /// }
  /// ```
  ///
  /// See also:
  ///
  ///  * [ChipThemeData], which describes the actual configuration of a chip
  ///    theme.
  static ChipThemeData of(BuildContext context) {
    final ChipTheme inheritedTheme = context.inheritFromWidgetOfExactType(ChipTheme);
    return inheritedTheme != null ? inheritedTheme.data : Theme.of(context).chipTheme;
  }

  @override
  bool updateShouldNotify(ChipTheme oldWidget) => data != oldWidget.data;
}

/// Holds the color, shape, and typography values for a material design chip
/// theme.
///
/// Use this class to configure a [ChipTheme] widget, or to set the
/// [ThemeData.chipTheme] for a [Theme] widget.
///
/// To obtain the current ambient chip theme, use [ChipTheme.of].
///
/// The parts of a chip are:
///
///  * The "avatar", which is a widget that appears at the beginning of the
///    chip.
///  * The "label", which is the widget displayed in the center of the chip,
///    typically this is a [Text] widget.
///  * The "delete icon", which is a widget that appears at the end of the chip.
///  * The chip is disabled when it is not accepting user input. Only some chips
///    have a disabled state (i.e. [InputChip], [ChoiceChip], [FilterChip]).
///
/// See also:
///
///  * [ChipTheme] widget, which can override the chip theme of its
///    children.
///  * [Theme] widget, which performs a similar function to [ChipTheme],
///    but for overall themes.
///  * [ThemeData], which has a default [ChipThemeData].
class ChipThemeData extends Diagnosticable {
  /// Create a [ChipThemeData] given a set of exact values. All the values
  /// must be specified.
  ///
  /// This will rarely be used directly. It is used by [lerp] to
  /// create intermediate themes based on two themes.
  ///
  /// The simplest way to create a ChipThemeData is to use
  /// [copyWith] on the one you get from [ChipTheme.of], or create an
  /// entirely new one with [ChipThemeData.fromPrimaryColors].
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// class Blissful extends StatefulWidget {
  ///   @override
  ///   State createState() => new BlissfulState();
  /// }
  ///
  /// class BlissfulState extends State<Blissful> {
  ///   bool _bliss = false;
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return new ChipTheme(
  ///       data: ChipTheme.of(context).copyWith(backgroundColor: const Color(0xff404080)),
  ///       child: new ChoiceChip(
  ///         onSelected: (bool value) { setState(() { _bliss = value; }); },
  ///         selected: _bliss,
  ///       ),
  ///     );
  ///   }
  /// }
  /// ```
  const ChipThemeData({
    @required this.labelStyle,
    @required this.secondaryLabelStyle,
    @required this.shape,
    @required this.backgroundColor,
    @required this.padding,
    @required this.labelPadding,
    @required this.deleteIconColor,
    @required this.selectedColor,
    @required this.secondarySelectedColor,
    @required this.disabledColor,
    @required this.brightness,
  })  : assert(labelStyle != null),
        assert(secondaryLabelStyle != null),
        assert(shape != null),
        assert(backgroundColor != null),
        assert(padding != null),
        assert(labelPadding != null),
        assert(deleteIconColor != null),
        assert(selectedColor != null),
        assert(disabledColor != null),
        assert(brightness != null);

  /// Generates a ChipThemeData from a brightness and a text style.
  ///
  /// This is used to generate the default chip theme for a [ThemeData].
  factory ChipThemeData.defaults({
    @required Color primaryColor,
    @required Brightness brightness,
    @required TextStyle labelStyle,
  }) {
    assert(brightness != null);
    assert(labelStyle != null);

    // These are Material Design defaults, and are used to derive
    // component Colors (with opacity) from base colors.
    const int backgroundAlpha = 0x1f; // 12%
    const int textLabelAlpha = 0xde; // 87%
    const int deleteIconAlpha = 0xde; // 87%
    const int selectAlpha = 0x3d; // 12% + 12% = 24%
    const int disabledAlpha = 0x0c; // 38% * 12% = 5%
    const EdgeInsetsGeometry padding = const EdgeInsets.all(4.0);
    const EdgeInsetsGeometry labelPadding = const EdgeInsets.symmetric(horizontal: 8.0);
    const ShapeBorder shape = const StadiumBorder();

    final Color baseColor = brightness == Brightness.light ? Colors.black : Colors.white;
    final Color backgroundColor = baseColor.withAlpha(backgroundAlpha);
    final Color deleteIconColor = baseColor.withAlpha(deleteIconAlpha);
    final Color disabledColor = baseColor.withAlpha(disabledAlpha);
    final Color selectedColor = baseColor.withAlpha(selectAlpha);
    final Color secondartSelectedColor = primaryColor.withAlpha(selectAlpha);
    final TextStyle secondaryLabelStyle = labelStyle.copyWith(color: primaryColor.withAlpha(textLabelAlpha));
    labelStyle = labelStyle.copyWith(color: baseColor.withAlpha(textLabelAlpha));

    return new ChipThemeData(
      labelStyle: labelStyle,
      secondaryLabelStyle: secondaryLabelStyle,
      shape: shape,
      backgroundColor: backgroundColor,
      padding: padding,
      labelPadding: labelPadding,
      deleteIconColor: deleteIconColor,
      selectedColor: selectedColor,
      secondarySelectedColor: secondartSelectedColor,
      disabledColor: disabledColor,
      brightness: brightness,
    );
  }

  /// Color to be used for the unselected, enabled chip's background.
  ///
  /// The default is light grey.
  final Color backgroundColor;

  /// The [Color] for the delete icon. The default is based on the ambient
  /// [IconTheme.color].
  final Color deleteIconColor;

  /// Color to be used for the chip's background indicating that it is disabled.
  ///
  /// The chip is disabled when [isEnabled] is false, or all three of
  /// [SelectableChipAttributes.onSelected], [TappableChipAttributes.onPressed],
  /// and [DeletableChipAttributes.onDelete] are null.
  ///
  /// It defaults to [Colors.black38].
  final Color disabledColor;

  /// Color to be used for the chip's background, indicating that it is
  /// selected.
  ///
  /// The chip is selected when [selected] is true.
  final Color selectedColor;

  /// An alternate color to be used for the chip's background, indicating that
  /// it is selected. For example, this color is used by [ChoiceChip] when the
  /// choice is selected.
  ///
  /// The chip is selected when [selected] is true.
  final Color secondarySelectedColor;

  /// The padding around the [label] widget.
  ///
  /// By default, this is 4 logical pixels at the beginning and the end of the
  /// label, and zero on top and bottom.
  final EdgeInsetsGeometry labelPadding;

  /// The padding between the contents of the chip and the outside [border].
  ///
  /// Defaults to 4 logical pixels on all sides.
  final EdgeInsetsGeometry padding;

  /// The border to draw around the chip.
  ///
  /// Defaults to a [StadiumBorder]. Must not be null.
  final ShapeBorder shape;

  /// The style to be applied to the chip's label.
  ///
  /// This only has an effect on label widgets that respect the
  /// [DefaultTextStyle], such as [Text].
  final TextStyle labelStyle;

  /// An alternate style to be applied to the chip's label. For example, this
  /// style is applied to the text of a selected [ChoiceChip].
  ///
  /// This only has an effect on label widgets that respect the
  /// [DefaultTextStyle], such as [Text].
  final TextStyle secondaryLabelStyle;

  /// The brightness setting for this theme.
  ///
  /// This affects various base material color choices in the chip rendering.
  final Brightness brightness;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  ChipThemeData copyWith({
    Color backgroundColor,
    Color deleteIconColor,
    Color disabledColor,
    Color selectedColor,
    Color secondarySelectedColor,
    EdgeInsetsGeometry labelPadding,
    EdgeInsetsGeometry padding,
    ShapeBorder shape,
    String deleteButtonTooltipMessage,
    TextStyle labelStyle,
    TextStyle secondaryLabelStyle,
    Brightness brightness,
  }) {
    return new ChipThemeData(
      labelStyle: labelStyle ?? this.labelStyle,
      secondaryLabelStyle: secondaryLabelStyle ?? this.secondaryLabelStyle,
      shape: shape ?? this.shape,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      padding: padding ?? this.padding,
      labelPadding: labelPadding ?? this.labelPadding,
      deleteIconColor: deleteIconColor ?? this.deleteIconColor,
      selectedColor: selectedColor ?? this.selectedColor,
      secondarySelectedColor: secondarySelectedColor ?? this.selectedColor,
      disabledColor: disabledColor ?? this.disabledColor,
      brightness: brightness ?? this.brightness,
    );
  }

  /// Linearly interpolate between two chip themes.
  ///
  /// The arguments must not be null.
  ///
  /// The `t` argument represents position on the timeline, with 0.0 meaning
  /// that the interpolation has not started, returning `a` (or something
  /// equivalent to `a`), 1.0 meaning that the interpolation has finished,
  /// returning `b` (or something equivalent to `b`), and values in between
  /// meaning that the interpolation is at the relevant point on the timeline
  /// between `a` and `b`. The interpolation can be extrapolated beyond 0.0 and
  /// 1.0, so negative values and values greater than 1.0 are valid (and can
  /// easily be generated by curves such as [Curves.elasticInOut]).
  ///
  /// Values for `t` are usually obtained from an [Animation<double>], such as
  /// an [AnimationController].
  static ChipThemeData lerp(ChipThemeData a, ChipThemeData b, double t) {
    assert(a != null);
    assert(b != null);
    assert(t != null);
    return new ChipThemeData(
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t),
      deleteIconColor: Color.lerp(a.deleteIconColor, b.deleteIconColor, t),
      disabledColor: Color.lerp(a.disabledColor, b.disabledColor, t),
      selectedColor: Color.lerp(a.selectedColor, b.selectedColor, t),
      secondarySelectedColor: Color.lerp(a.secondarySelectedColor, b.secondarySelectedColor, t),
      labelPadding: EdgeInsetsGeometry.lerp(a.labelPadding, b.labelPadding, t),
      padding: EdgeInsetsGeometry.lerp(a.padding, b.padding, t),
      shape: ShapeBorder.lerp(a.shape, b.shape, t),
      labelStyle: TextStyle.lerp(a.labelStyle, b.labelStyle, t),
      secondaryLabelStyle: TextStyle.lerp(a.secondaryLabelStyle, b.secondaryLabelStyle, t),
      brightness: t < 0.5 ? a.brightness : b.brightness,
    );
  }

  @override
  int get hashCode {
    return hashValues(
      backgroundColor,
      deleteIconColor,
      disabledColor,
      selectedColor,
      secondarySelectedColor,
      labelPadding,
      padding,
      shape,
      labelStyle,
      secondaryLabelStyle,
      brightness,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final ChipThemeData otherData = other;
    return otherData.backgroundColor == backgroundColor &&
        otherData.deleteIconColor == deleteIconColor &&
        otherData.disabledColor == disabledColor &&
        otherData.selectedColor == selectedColor &&
        otherData.secondarySelectedColor == secondarySelectedColor &&
        otherData.labelPadding == labelPadding &&
        otherData.padding == padding &&
        otherData.shape == shape &&
        otherData.labelStyle == labelStyle &&
        otherData.secondaryLabelStyle == secondaryLabelStyle &&
        otherData.brightness == brightness;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final ThemeData defaultTheme = new ThemeData.fallback();
    final ChipThemeData defaultData = new ChipThemeData.defaults(
      primaryColor: defaultTheme.primaryColor,
      brightness: defaultTheme.brightness,
      labelStyle: defaultTheme.textTheme.body2,
    );
    properties.add(new DiagnosticsProperty<Color>('backgroundColor', backgroundColor, defaultValue: defaultData.backgroundColor));
    properties.add(new DiagnosticsProperty<Color>('deleteIconColor', deleteIconColor, defaultValue: defaultData.deleteIconColor));
    properties.add(new DiagnosticsProperty<Color>('disabledColor', disabledColor, defaultValue: defaultData.disabledColor));
    properties.add(new DiagnosticsProperty<Color>('selectedColor', selectedColor, defaultValue: defaultData.selectedColor));
    properties.add(new DiagnosticsProperty<Color>('secondarySelectedColor', secondarySelectedColor, defaultValue: defaultData.secondarySelectedColor));
    properties.add(new DiagnosticsProperty<EdgeInsetsGeometry>('labelPadding', labelPadding, defaultValue: defaultData.labelPadding));
    properties.add(new DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding, defaultValue: defaultData.padding));
    properties.add(new DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: defaultData.shape));
    properties.add(new DiagnosticsProperty<TextStyle>('labelStyle', labelStyle, defaultValue: defaultData.labelStyle));
    properties.add(new DiagnosticsProperty<TextStyle>('secondaryLabelStyle', secondaryLabelStyle, defaultValue: defaultData.secondaryLabelStyle));
  }
}

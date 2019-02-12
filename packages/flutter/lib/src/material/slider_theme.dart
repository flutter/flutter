// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show Path, lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';
import 'theme_data.dart';

/// Applies a slider theme to descendant [Slider] widgets.
///
/// A slider theme describes the colors and shape choices of the slider
/// components.
///
/// Descendant widgets obtain the current theme's [SliderThemeData] object using
/// [SliderTheme.of]. When a widget uses [SliderTheme.of], it is automatically
/// rebuilt if the theme later changes.
///
/// The slider is as big as the largest of
/// the [SliderComponentShape.getPreferredSize] of the thumb shape,
/// the [SliderComponentShape.getPreferredSize] of the overlay shape,
/// and the [SliderTickMarkShape.getPreferredSize] of the tick mark shape
///
/// See also:
///
///  * [SliderThemeData], which describes the actual configuration of a slider
///    theme.
///  * [SliderComponentShape], which can be used to create custom shapes for
///    the slider thumb, overlay, and value indicator.
///  * [SliderTrackShape], which can be used to create custom shapes for the
///    slider track.
///  * [SliderTickMarkShape], which can be used to create custom shapes for the
///    slider tick marks.
class SliderTheme extends InheritedWidget {
  /// Applies the given theme [data] to [child].
  ///
  /// The [data] and [child] arguments must not be null.
  const SliderTheme({
    Key key,
    @required this.data,
    @required Widget child,
  }) : assert(child != null),
       assert(data != null),
       super(key: key, child: child);

  /// Specifies the color and shape values for descendant slider widgets.
  final SliderThemeData data;

  /// Returns the data from the closest [SliderTheme] instance that encloses
  /// the given context.
  ///
  /// Defaults to the ambient [ThemeData.sliderTheme] if there is no
  /// [SliderTheme] in the given build context.
  ///
  /// {@tool sample}
  ///
  /// ```dart
  /// class Launch extends StatefulWidget {
  ///   @override
  ///   State createState() => LaunchState();
  /// }
  ///
  /// class LaunchState extends State<Launch> {
  ///   double _rocketThrust;
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return SliderTheme(
  ///       data: SliderTheme.of(context).copyWith(activeTrackColor: const Color(0xff804040)),
  ///       child: Slider(
  ///         onChanged: (double value) { setState(() { _rocketThrust = value; }); },
  ///         value: _rocketThrust,
  ///       ),
  ///     );
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [SliderThemeData], which describes the actual configuration of a slider
  ///    theme.
  static SliderThemeData of(BuildContext context) {
    final SliderTheme inheritedTheme = context.inheritFromWidgetOfExactType(SliderTheme);
    return inheritedTheme != null ? inheritedTheme.data : Theme.of(context).sliderTheme;
  }

  @override
  bool updateShouldNotify(SliderTheme oldWidget) => data != oldWidget.data;
}

/// Describes the conditions under which the value indicator on a [Slider]
/// will be shown. Used with [SliderThemeData.showValueIndicator].
///
/// See also:
///
///  * [Slider], a Material Design slider widget.
///  * [SliderThemeData], which describes the actual configuration of a slider
///    theme.
enum ShowValueIndicator {
  /// The value indicator will only be shown for discrete sliders (sliders
  /// where [Slider.divisions] is non-null).
  onlyForDiscrete,

  /// The value indicator will only be shown for continuous sliders (sliders
  /// where [Slider.divisions] is null).
  onlyForContinuous,

  /// The value indicator will be shown for all types of sliders.
  always,

  /// The value indicator will never be shown.
  never,
}

/// Holds the color, shape, and typography values for a material design slider
/// theme.
///
/// Use this class to configure a [SliderTheme] widget, or to set the
/// [ThemeData.sliderTheme] for a [Theme] widget.
///
/// To obtain the current ambient slider theme, use [SliderTheme.of].
///
/// The parts of a slider are:
///
///  * The "thumb", which is a shape that slides horizontally when the user
///    drags it.
///  * The "track", which is the line that the slider thumb slides along.
///  * The "tick marks", which are regularly spaced marks that are drawn when
///    using discrete divisions.
///  * The "value indicator", which appears when the user is dragging the thumb
///    to indicate the value being selected.
///  * The "overlay", which appears around the thumb, and is shown when the
///    thumb is pressed, focused, or hovered. It is painted underneath the
///    thumb, so it must extend beyond the bounds of the thumb itself to
///    actually be visible.
///  * The "active" side of the slider is the side between the thumb and the
///    minimum value.
///  * The "inactive" side of the slider is the side between the thumb and the
///    maximum value.
///  * The [Slider] is disabled when it is not accepting user input. See
///    [Slider] for details on when this happens.
///
/// The thumb, track, tick marks, value indicator, and overlay can be customized
/// by creating subclasses of [SliderTrackShape],
/// [SliderComponentShape], and/or [SliderTickMarkShape]. See
/// [RoundSliderThumbShape], [RectangularSliderTrackShape],
/// [RoundSliderTickMarkShape], [PaddleSliderValueIndicatorShape], and
/// [RoundSliderOverlayShape] for examples.
///
/// The track painting can be skipped by specifying 0 for [trackHeight].
/// The thumb painting can be skipped by specifying
/// [SliderComponentShape.noThumb] for [SliderThemeData.thumbShape].
/// The overlay painting can be skipped by specifying
/// [SliderComponentShape.noOverlay] for [SliderThemeData.overlayShape].
/// The tick mark painting can be skipped by specifying
/// [SliderTickMarkShape.noTickMark] for [SliderThemeData.tickMarkShape].
/// The value indicator painting can be skipped by specifying the
/// appropriate [ShowValueIndicator] for [SliderThemeData.showValueIndicator].
///
/// See also:
///
///  * [SliderTheme] widget, which can override the slider theme of its
///    children.
///  * [Theme] widget, which performs a similar function to [SliderTheme],
///    but for overall themes.
///  * [ThemeData], which has a default [SliderThemeData].
///  * [SliderTrackShape], to define custom slider track shapes.
///  * [SliderComponentShape], to define custom slider component shapes.
///  * [SliderTickMarkShape], to define custom slider tick mark shapes.
class SliderThemeData extends Diagnosticable {
  /// Create a [SliderThemeData] given a set of exact values. All the values
  /// must be specified.
  ///
  /// This will rarely be used directly. It is used by [lerp] to
  /// create intermediate themes based on two themes.
  ///
  /// The simplest way to create a SliderThemeData is to use
  /// [copyWith] on the one you get from [SliderTheme.of], or create an
  /// entirely new one with [SliderThemeData.fromPrimaryColors].
  ///
  /// {@tool sample}
  ///
  /// ```dart
  /// class Blissful extends StatefulWidget {
  ///   @override
  ///   State createState() => BlissfulState();
  /// }
  ///
  /// class BlissfulState extends State<Blissful> {
  ///   double _bliss;
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return SliderTheme(
  ///       data: SliderTheme.of(context).copyWith(activeTrackColor: const Color(0xff404080)),
  ///       child: Slider(
  ///         onChanged: (double value) { setState(() { _bliss = value; }); },
  ///         value: _bliss,
  ///       ),
  ///     );
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  const SliderThemeData({
    @required this.trackHeight,
    @required this.activeTrackColor,
    @required this.inactiveTrackColor,
    @required this.disabledActiveTrackColor,
    @required this.disabledInactiveTrackColor,
    @required this.activeTickMarkColor,
    @required this.inactiveTickMarkColor,
    @required this.disabledActiveTickMarkColor,
    @required this.disabledInactiveTickMarkColor,
    @required this.thumbColor,
    @required this.disabledThumbColor,
    @required this.overlayColor,
    @required this.valueIndicatorColor,
    @required this.trackShape,
    @required this.tickMarkShape,
    @required this.thumbShape,
    @required this.overlayShape,
    @required this.valueIndicatorShape,
    @required this.showValueIndicator,
    @required this.valueIndicatorTextStyle,
  })  : assert(trackHeight != null),
        assert(activeTrackColor != null),
        assert(inactiveTrackColor != null),
        assert(disabledActiveTrackColor != null),
        assert(disabledInactiveTrackColor != null),
        assert(activeTickMarkColor != null),
        assert(inactiveTickMarkColor != null),
        assert(disabledActiveTickMarkColor != null),
        assert(disabledInactiveTickMarkColor != null),
        assert(thumbColor != null),
        assert(disabledThumbColor != null),
        assert(overlayColor != null),
        assert(valueIndicatorColor != null),
        assert(trackShape != null),
        assert(tickMarkShape != null),
        assert(thumbShape != null),
        assert(overlayShape != null),
        assert(valueIndicatorShape != null),
        assert(valueIndicatorTextStyle != null),
        assert(showValueIndicator != null);

  /// Generates a SliderThemeData from three main colors.
  ///
  /// Usually these are the primary, dark and light colors from
  /// a [ThemeData].
  ///
  /// The opacities of these colors will be overridden with the Material Design
  /// defaults when assigning them to the slider theme component colors.
  ///
  /// This is used to generate the default slider theme for a [ThemeData].
  factory SliderThemeData.fromPrimaryColors({
    @required Color primaryColor,
    @required Color primaryColorDark,
    @required Color primaryColorLight,
    @required TextStyle valueIndicatorTextStyle,
  }) {
    assert(primaryColor != null);
    assert(primaryColorDark != null);
    assert(primaryColorLight != null);
    assert(valueIndicatorTextStyle != null);

    // These are Material Design defaults, and are used to derive
    // component Colors (with opacity) from base colors.
    const int activeTrackAlpha = 0xff;
    const int inactiveTrackAlpha = 0x3d; // 24% opacity
    const int disabledActiveTrackAlpha = 0x52; // 32% opacity
    const int disabledInactiveTrackAlpha = 0x1f; // 12% opacity
    const int activeTickMarkAlpha = 0x8a; // 54% opacity
    const int inactiveTickMarkAlpha = 0x8a; // 54% opacity
    const int disabledActiveTickMarkAlpha = 0x1f; // 12% opacity
    const int disabledInactiveTickMarkAlpha = 0x1f; // 12% opacity
    const int thumbAlpha = 0xff;
    const int disabledThumbAlpha = 0x52; // 32% opacity
    const int valueIndicatorAlpha = 0xff;

    // TODO(gspencer): We don't really follow the spec here for overlays.
    // The spec says to use 16% opacity for drawing over light material,
    // and 32% for colored material, but we don't really have a way to
    // know what the underlying color is, so there's no easy way to
    // implement this. Choosing the "light" version for now.
    const int overlayLightAlpha = 0x29; // 16% opacity

    return SliderThemeData(
      trackHeight: 2.0,
      activeTrackColor: primaryColor.withAlpha(activeTrackAlpha),
      inactiveTrackColor: primaryColor.withAlpha(inactiveTrackAlpha),
      disabledActiveTrackColor: primaryColorDark.withAlpha(disabledActiveTrackAlpha),
      disabledInactiveTrackColor: primaryColorDark.withAlpha(disabledInactiveTrackAlpha),
      activeTickMarkColor: primaryColorLight.withAlpha(activeTickMarkAlpha),
      inactiveTickMarkColor: primaryColor.withAlpha(inactiveTickMarkAlpha),
      disabledActiveTickMarkColor: primaryColorLight.withAlpha(disabledActiveTickMarkAlpha),
      disabledInactiveTickMarkColor: primaryColorDark.withAlpha(disabledInactiveTickMarkAlpha),
      thumbColor: primaryColor.withAlpha(thumbAlpha),
      disabledThumbColor: primaryColorDark.withAlpha(disabledThumbAlpha),
      overlayColor: primaryColor.withAlpha(overlayLightAlpha),
      valueIndicatorColor: primaryColor.withAlpha(valueIndicatorAlpha),
      trackShape: const RectangularSliderTrackShape(),
      tickMarkShape: const RoundSliderTickMarkShape(),
      thumbShape: const RoundSliderThumbShape(),
      overlayShape: const RoundSliderOverlayShape(),
      valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
      valueIndicatorTextStyle: valueIndicatorTextStyle,
      showValueIndicator: ShowValueIndicator.onlyForDiscrete,
    );
  }

  /// The height of the [Slider] track.
  final double trackHeight;

  /// The color of the [Slider] track between the [Slider.min] position and the
  /// current thumb position.
  final Color activeTrackColor;

  /// The color of the [Slider] track between the current thumb position and the
  /// [Slider.max] position.
  final Color inactiveTrackColor;

  /// The color of the [Slider] track between the [Slider.min] position and the
  /// current thumb position when the [Slider] is disabled.
  final Color disabledActiveTrackColor;

  /// The color of the [Slider] track between the current thumb position and the
  /// [Slider.max] position when the [Slider] is disabled.
  final Color disabledInactiveTrackColor;

  /// The color of the track's tick marks that are drawn between the [Slider.min]
  /// position and the current thumb position.
  final Color activeTickMarkColor;

  /// The color of the track's tick marks that are drawn between the current
  /// thumb position and the [Slider.max] position.
  final Color inactiveTickMarkColor;

  /// The color of the track's tick marks that are drawn between the [Slider.min]
  /// position and the current thumb position when the [Slider] is disabled.
  final Color disabledActiveTickMarkColor;

  /// The color of the track's tick marks that are drawn between the current
  /// thumb position and the [Slider.max] position when the [Slider] is
  /// disabled.
  final Color disabledInactiveTickMarkColor;

  /// The color given to the [thumbShape] to draw itself with.
  final Color thumbColor;

  /// The color given to the [thumbShape] to draw itself with when the
  /// [Slider] is disabled.
  final Color disabledThumbColor;

  /// The color of the overlay drawn around the slider thumb when it is pressed.
  ///
  /// This is typically a semi-transparent color.
  final Color overlayColor;

  /// The color given to the [valueIndicatorShape] to draw itself with.
  final Color valueIndicatorColor;

  /// The shape that will be used to draw the [Slider]'s track.
  ///
  /// The [SliderTrackShape.getPreferredRect] method is used to to map
  /// slider-relative gesture coordinates to the correct thumb position on the
  /// track. It is also used to horizontally position tick marks, when he slider
  /// is discrete.
  ///
  /// The default value is [RectangularSliderTrackShape].
  final SliderTrackShape trackShape;

  /// The shape that will be used to draw the [Slider]'s tick marks.
  ///
  /// The [SliderTickMarkShape.getPreferredSize] is used to help determine the
  /// location of each tick mark on the track. The slider's minimum size will
  /// be at least this big.
  ///
  /// The default value is [RoundSliderTickMarkShape].
  final SliderTickMarkShape tickMarkShape;

  /// The shape that will be used to draw the [Slider]'s overlay.
  ///
  /// Both the [overlayColor] and a non default [overlayShape] may be specified.
  /// In this case, the [overlayColor] is only used if the [overlayShape]
  /// explicitly does so.
  ///
  /// The default value is [RoundSliderOverlayShape].
  final SliderComponentShape overlayShape;

  /// The shape that will be used to draw the [Slider]'s thumb.
  final SliderComponentShape thumbShape;

  /// The shape that will be used to draw the [Slider]'s value
  /// indicator.
  final SliderComponentShape valueIndicatorShape;

  /// Whether the value indicator should be shown for different types of
  /// sliders.
  ///
  /// By default, [showValueIndicator] is set to
  /// [ShowValueIndicator.onlyForDiscrete]. The value indicator is only shown
  /// when the thumb is being touched.
  final ShowValueIndicator showValueIndicator;

  /// The text style for the text on the value indicator.
  ///
  /// By default this is the [ThemeData.accentTextTheme.body2] text theme.
  final TextStyle valueIndicatorTextStyle;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  SliderThemeData copyWith({
    double trackHeight,
    Color activeTrackColor,
    Color inactiveTrackColor,
    Color disabledActiveTrackColor,
    Color disabledInactiveTrackColor,
    Color activeTickMarkColor,
    Color inactiveTickMarkColor,
    Color disabledActiveTickMarkColor,
    Color disabledInactiveTickMarkColor,
    Color thumbColor,
    Color disabledThumbColor,
    Color overlayColor,
    Color valueIndicatorColor,
    SliderTrackShape trackShape,
    SliderTickMarkShape tickMarkShape,
    SliderComponentShape thumbShape,
    SliderComponentShape overlayShape,
    SliderComponentShape valueIndicatorShape,
    ShowValueIndicator showValueIndicator,
    TextStyle valueIndicatorTextStyle,
  }) {
    return SliderThemeData(
      trackHeight: trackHeight ?? this.trackHeight,
      activeTrackColor: activeTrackColor ?? this.activeTrackColor,
      inactiveTrackColor: inactiveTrackColor ?? this.inactiveTrackColor,
      disabledActiveTrackColor: disabledActiveTrackColor ?? this.disabledActiveTrackColor,
      disabledInactiveTrackColor: disabledInactiveTrackColor ?? this.disabledInactiveTrackColor,
      activeTickMarkColor: activeTickMarkColor ?? this.activeTickMarkColor,
      inactiveTickMarkColor: inactiveTickMarkColor ?? this.inactiveTickMarkColor,
      disabledActiveTickMarkColor: disabledActiveTickMarkColor ?? this.disabledActiveTickMarkColor,
      disabledInactiveTickMarkColor: disabledInactiveTickMarkColor ?? this.disabledInactiveTickMarkColor,
      thumbColor: thumbColor ?? this.thumbColor,
      disabledThumbColor: disabledThumbColor ?? this.disabledThumbColor,
      overlayColor: overlayColor ?? this.overlayColor,
      valueIndicatorColor: valueIndicatorColor ?? this.valueIndicatorColor,
      trackShape: trackShape ?? this.trackShape,
      tickMarkShape: tickMarkShape ?? this.tickMarkShape,
      thumbShape: thumbShape ?? this.thumbShape,
      overlayShape: overlayShape ?? this.overlayShape,
      valueIndicatorShape: valueIndicatorShape ?? this.valueIndicatorShape,
      showValueIndicator: showValueIndicator ?? this.showValueIndicator,
      valueIndicatorTextStyle: valueIndicatorTextStyle ?? this.valueIndicatorTextStyle,
    );
  }

  /// Linearly interpolate between two slider themes.
  ///
  /// The arguments must not be null.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static SliderThemeData lerp(SliderThemeData a, SliderThemeData b, double t) {
    assert(a != null);
    assert(b != null);
    assert(t != null);
    return SliderThemeData(
      trackHeight: lerpDouble(a.trackHeight, b.trackHeight, t),
      activeTrackColor: Color.lerp(a.activeTrackColor, b.activeTrackColor, t),
      inactiveTrackColor: Color.lerp(a.inactiveTrackColor, b.inactiveTrackColor, t),
      disabledActiveTrackColor: Color.lerp(a.disabledActiveTrackColor, b.disabledActiveTrackColor, t),
      disabledInactiveTrackColor: Color.lerp(a.disabledInactiveTrackColor, b.disabledInactiveTrackColor, t),
      activeTickMarkColor: Color.lerp(a.activeTickMarkColor, b.activeTickMarkColor, t),
      inactiveTickMarkColor: Color.lerp(a.inactiveTickMarkColor, b.inactiveTickMarkColor, t),
      disabledActiveTickMarkColor: Color.lerp(a.disabledActiveTickMarkColor, b.disabledActiveTickMarkColor, t),
      disabledInactiveTickMarkColor: Color.lerp(a.disabledInactiveTickMarkColor, b.disabledInactiveTickMarkColor, t),
      thumbColor: Color.lerp(a.thumbColor, b.thumbColor, t),
      disabledThumbColor: Color.lerp(a.disabledThumbColor, b.disabledThumbColor, t),
      overlayColor: Color.lerp(a.overlayColor, b.overlayColor, t),
      valueIndicatorColor: Color.lerp(a.valueIndicatorColor, b.valueIndicatorColor, t),
      trackShape: t < 0.5 ? a.trackShape : b.trackShape,
      tickMarkShape: t < 0.5 ? a.tickMarkShape : b.tickMarkShape,
      thumbShape: t < 0.5 ? a.thumbShape : b.thumbShape,
      overlayShape: t < 0.5 ? a.overlayShape : b.overlayShape,
      valueIndicatorShape: t < 0.5 ? a.valueIndicatorShape : b.valueIndicatorShape,
      showValueIndicator: t < 0.5 ? a.showValueIndicator : b.showValueIndicator,
      valueIndicatorTextStyle: TextStyle.lerp(a.valueIndicatorTextStyle, b.valueIndicatorTextStyle, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      trackHeight,
      activeTrackColor,
      inactiveTrackColor,
      disabledActiveTrackColor,
      disabledInactiveTrackColor,
      activeTickMarkColor,
      inactiveTickMarkColor,
      disabledActiveTickMarkColor,
      disabledInactiveTickMarkColor,
      thumbColor,
      disabledThumbColor,
      overlayColor,
      valueIndicatorColor,
      trackShape,
      tickMarkShape,
      thumbShape,
      overlayShape,
      valueIndicatorShape,
      showValueIndicator,
      valueIndicatorTextStyle,
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
    final SliderThemeData otherData = other;
    return otherData.trackHeight == trackHeight
      && otherData.activeTrackColor == activeTrackColor
      && otherData.inactiveTrackColor == inactiveTrackColor
      && otherData.disabledActiveTrackColor == disabledActiveTrackColor
      && otherData.disabledInactiveTrackColor == disabledInactiveTrackColor
      && otherData.activeTickMarkColor == activeTickMarkColor
      && otherData.inactiveTickMarkColor == inactiveTickMarkColor
      && otherData.disabledActiveTickMarkColor == disabledActiveTickMarkColor
      && otherData.disabledInactiveTickMarkColor == disabledInactiveTickMarkColor
      && otherData.thumbColor == thumbColor
      && otherData.disabledThumbColor == disabledThumbColor
      && otherData.overlayColor == overlayColor
      && otherData.valueIndicatorColor == valueIndicatorColor
      && otherData.trackShape == trackShape
      && otherData.tickMarkShape == tickMarkShape
      && otherData.thumbShape == thumbShape
      && otherData.overlayShape == overlayShape
      && otherData.valueIndicatorShape == valueIndicatorShape
      && otherData.showValueIndicator == showValueIndicator
      && otherData.valueIndicatorTextStyle == valueIndicatorTextStyle;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final ThemeData defaultTheme = ThemeData.fallback();
    final SliderThemeData defaultData = SliderThemeData.fromPrimaryColors(
      primaryColor: defaultTheme.primaryColor,
      primaryColorDark: defaultTheme.primaryColorDark,
      primaryColorLight: defaultTheme.primaryColorLight,
      valueIndicatorTextStyle: defaultTheme.accentTextTheme.body2,
    );
    properties.add(DiagnosticsProperty<Color>('activeTrackColor', activeTrackColor, defaultValue: defaultData.activeTrackColor));
    properties.add(DiagnosticsProperty<Color>('activeTrackColor', activeTrackColor, defaultValue: defaultData.activeTrackColor));
    properties.add(DiagnosticsProperty<Color>('inactiveTrackColor', inactiveTrackColor, defaultValue: defaultData.inactiveTrackColor));
    properties.add(DiagnosticsProperty<Color>('disabledActiveTrackColor', disabledActiveTrackColor, defaultValue: defaultData.disabledActiveTrackColor, level: DiagnosticLevel.debug));
    properties.add(DiagnosticsProperty<Color>('disabledInactiveTrackColor', disabledInactiveTrackColor, defaultValue: defaultData.disabledInactiveTrackColor, level: DiagnosticLevel.debug));
    properties.add(DiagnosticsProperty<Color>('activeTickMarkColor', activeTickMarkColor, defaultValue: defaultData.activeTickMarkColor, level: DiagnosticLevel.debug));
    properties.add(DiagnosticsProperty<Color>('inactiveTickMarkColor', inactiveTickMarkColor, defaultValue: defaultData.inactiveTickMarkColor, level: DiagnosticLevel.debug));
    properties.add(DiagnosticsProperty<Color>('disabledActiveTickMarkColor', disabledActiveTickMarkColor, defaultValue: defaultData.disabledActiveTickMarkColor, level: DiagnosticLevel.debug));
    properties.add(DiagnosticsProperty<Color>('disabledInactiveTickMarkColor', disabledInactiveTickMarkColor, defaultValue: defaultData.disabledInactiveTickMarkColor, level: DiagnosticLevel.debug));
    properties.add(DiagnosticsProperty<Color>('thumbColor', thumbColor, defaultValue: defaultData.thumbColor));
    properties.add(DiagnosticsProperty<Color>('disabledThumbColor', disabledThumbColor, defaultValue: defaultData.disabledThumbColor, level: DiagnosticLevel.debug));
    properties.add(DiagnosticsProperty<Color>('overlayColor', overlayColor, defaultValue: defaultData.overlayColor, level: DiagnosticLevel.debug));
    properties.add(DiagnosticsProperty<Color>('valueIndicatorColor', valueIndicatorColor, defaultValue: defaultData.valueIndicatorColor));
    properties.add(DiagnosticsProperty<SliderTrackShape>('trackShape', trackShape, defaultValue: defaultData.trackShape, level: DiagnosticLevel.debug));
    properties.add(DiagnosticsProperty<SliderTickMarkShape>('tickMarkShape', tickMarkShape, defaultValue: defaultData.tickMarkShape, level: DiagnosticLevel.debug));
    properties.add(DiagnosticsProperty<SliderComponentShape>('thumbShape', thumbShape, defaultValue: defaultData.thumbShape, level: DiagnosticLevel.debug));
    properties.add(DiagnosticsProperty<SliderComponentShape>('overlayShape', overlayShape, defaultValue: defaultData.overlayShape, level: DiagnosticLevel.debug));
    properties.add(DiagnosticsProperty<SliderComponentShape>('valueIndicatorShape', valueIndicatorShape, defaultValue: defaultData.valueIndicatorShape, level: DiagnosticLevel.debug));
    properties.add(EnumProperty<ShowValueIndicator>('showValueIndicator', showValueIndicator, defaultValue: defaultData.showValueIndicator));
    properties.add(DiagnosticsProperty<TextStyle>('valueIndicatorTextStyle', valueIndicatorTextStyle, defaultValue: defaultData.valueIndicatorTextStyle));
  }
}

// TEMPLATES FOR ALL SHAPES

/// {@template flutter.material.slider.shape.context}
/// [context] is the same context for the render box of the [Slider].
/// {@endtemplate}
///
/// {@template flutter.material.slider.shape.center}
/// [center] is the offset of the center where this shape should be painted.
/// This offset is relative to the origin of the [context] canvas.
/// {@endtemplate}
///
/// {@template flutter.material.slider.shape.sliderTheme}
/// [sliderTheme] is the theme assigned to the [Slider] that this shape
/// belongs to.
/// {@endtemplate}
///
/// {@template flutter.material.slider.shape.isEnabled}
/// [isEnabled] has the same value as [Slider.isInteractive]. If true, the
/// slider will respond to input.
/// {@endtemplate}
///
/// {@template flutter.material.slider.shape.enableAnimation}
/// [enableAnimation] is an animation triggered when the [Slider] is enabled,
/// and it reverses when the slider is disabled. Enabled is the
/// [Slider.isInteractive] state. Use this to paint intermediate frames for
/// this shape when the slider changes enabled state.
/// {@endtemplate}
///
/// {@template flutter.material.slider.shape.isDiscrete}
/// [isDiscrete] is true if [Slider.divisions] is non-null. If true, the
/// slider will render tick marks on top of the track.
/// {@endtemplate}
///
/// {@template flutter.material.slider.shape.parentBox}
/// [parentBox] is the [RenderBox] of the [Slider]. Its attributes, such as
/// size, can be used to assist in painting this shape.
/// {@endtemplate}

/// Base class for slider track shapes.
///
/// The slider's thumb moves along the track. A discrete slider's tick marks
/// are drawn after the track, but before the thumb, and are aligned with the
/// track.
///
/// The [getPreferredRect] helps position the slider thumb and tick marks
/// relative to the track.
///
/// See also:
///
///  * [RectangularSliderTrackShape], which is the default track shape.
///  * [SliderTickMarkShape], which is the default tick mark shape.
///  * [SliderComponentShape], which is the base class for custom a component
///    shape.
abstract class SliderTrackShape {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const SliderTrackShape();

  /// Returns the preferred bounds of the shape.
  ///
  /// It is used to provide horizontal boundaries for the thumb's position, and
  /// to help position the slider thumb and tick marks relative to the track.
  ///
  /// [parentBox] can be used to help determine the preferredRect relative to
  /// attributes of the render box of the slider itself, such as size.
  ///
  /// [offset] is relative to the caller's bounding box. It can be used to
  /// convert gesture coordinates from global to slider-relative coordinates.
  ///
  /// {@macro flutter.material.slider.shape.sliderTheme}
  ///
  /// {@macro flutter.material.slider.shape.isEnabled}
  ///
  /// {@macro flutter.material.slider.shape.isDiscrete}
  Rect getPreferredRect({
    RenderBox parentBox,
    Offset offset = Offset.zero,
    SliderThemeData sliderTheme,
    bool isEnabled,
    bool isDiscrete,
  });

  /// Paints the track shape based on the state passed to it.
  ///
  /// {@macro flutter.material.slider.shape.context}
  ///
  /// [offset] is the offset of the origin of the [parentBox] to the origin of
  /// its [context] canvas. This shape must be painted relative to this
  /// offset. See [PaintingContextCallback].
  ///
  /// {@macro flutter.material.slider.shape.parentBox}
  ///
  /// {@macro flutter.material.slider.shape.sliderTheme}
  ///
  /// {@macro flutter.material.slider.shape.enableAnimation}
  ///
  /// [thumbCenter] is the offset of the center of the thumb relative to the
  /// origin of the [PaintingContext.canvas]. It can be used as the point that
  /// divides the track into 2 segments.
  ///
  /// {@macro flutter.material.slider.shape.isEnabled}
  ///
  /// {@macro flutter.material.slider.shape.isDiscrete}
  ///
  /// [textDirection] can be used to determine how the track segments are
  /// painted depending on whether they are active or not. The track segment
  /// between the start of the slider and the thumb is the active track segment.
  /// The track segment between the thumb and the end of the slider is the
  /// inactive track segment. In LTR text direction, the start of the slider is
  /// on the left, and in RTL text direction, the start of the slider is on the
  /// right.
  void paint(
    PaintingContext context,
    Offset offset, {
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    Animation<double> enableAnimation,
    Offset thumbCenter,
    bool isEnabled,
    bool isDiscrete,
    TextDirection textDirection,
  });
}

/// Base class for slider tick mark shapes.
///
/// Create a subclass of this if you would like a custom slider tick mark shape.
/// This is a simplified version of [SliderComponentShape] with a
/// [SliderThemeData] passed when getting the preferred size.
///
/// The tick mark painting can be skipped by specifying [noTickMark] for
/// [SliderThemeData.tickMarkShape].
///
/// See also:
///
///  * [RoundSliderTickMarkShape] for a simple example of a tick mark shape.
///  * [SliderTrackShape] for the base class for custom a track shape.
///  * [SliderComponentShape] for the base class for custom a component shape.
abstract class SliderTickMarkShape {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const SliderTickMarkShape();

  /// Returns the preferred size of the shape.
  ///
  /// It is used to help position the tick marks within the slider.
  ///
  /// {@macro flutter.material.slider.shape.sliderTheme}
  ///
  /// {@macro flutter.material.slider.shape.isEnabled}
  Size getPreferredSize({
    SliderThemeData sliderTheme,
    bool isEnabled,
  });

  /// Paints the slider track.
  ///
  /// {@macro flutter.material.slider.shape.context}
  ///
  /// {@macro flutter.material.slider.shape.center}
  ///
  /// {@macro flutter.material.slider.shape.parentBox}
  ///
  /// {@macro flutter.material.slider.shape.sliderTheme}
  ///
  /// {@macro flutter.material.slider.shape.enableAnimation}
  ///
  /// {@macro flutter.material.slider.shape.isEnabled}
  ///
  /// [textDirection] can be used to determine how the tick marks are painting
  /// depending on whether they are on an active track segment or not. The track
  /// segment between the start of the slider and the thumb is the active track
  /// segment. The track segment between the thumb and the end of the slider is
  /// the inactive track segment. In LTR text direction, the start of the slider
  /// is on the left, and in RTL text direction, the start of the slider is on
  /// the right.
  void paint(
    PaintingContext context,
    Offset center, {
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    Animation<double> enableAnimation,
    Offset thumbCenter,
    bool isEnabled,
    TextDirection textDirection,
  });

  /// Special instance of [SliderTickMarkShape] to skip the tick mark painting.
  ///
  /// See also:
  ///
  /// * [SliderThemeData.tickMarkShape], which is the shape that the [Slider]
  /// uses when painting tick marks.
  static final SliderTickMarkShape noTickMark = _EmptySliderTickMarkShape();
}

/// A special version of [SliderTickMarkShape] that has a zero size and paints
/// nothing.
///
/// This class is used to create a special instance of a [SliderTickMarkShape]
/// that will not paint any tick mark shape. A static reference is stored in
/// [SliderTickMarkShape.noTickMark]. When this value  is specified for
/// [SliderThemeData.tickMarkShape], the tick mark painting is skipped.
class _EmptySliderTickMarkShape extends SliderTickMarkShape {
  @override
  Size getPreferredSize({
    SliderThemeData sliderTheme,
    bool isEnabled,
  }) {
    return Size.zero;
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    Animation<double> enableAnimation,
    Offset thumbCenter,
    bool isEnabled,
    TextDirection textDirection,
  }) {
    // no-op.
  }
}

/// Base class for slider thumb, thumb overlay, and value indicator shapes.
///
/// Create a subclass of this if you would like a custom shape.
///
/// All shapes are painted to the same canvas and ordering is important.
/// The overlay is painted first, then the value indicator, then the thumb.
///
/// The thumb painting can be skipped by specifying [noThumb] for
/// [SliderThemeData.thumbShape].
///
/// The overlay painting can be skipped by specifying [noOverlay] for
/// [SliderThemeData.overlayShape].
///
/// See also:
///
///  * [RoundSliderThumbShape], which is the the default thumb shape.
///  * [RoundSliderOverlayShape], which is the the default overlay shape.
///  * [PaddleSliderValueIndicatorShape], which is the the default value
///    indicator shape.
abstract class SliderComponentShape {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const SliderComponentShape();

  /// Returns the preferred size of the shape, based on the given conditions.
  Size getPreferredSize(bool isEnabled, bool isDiscrete);

  /// Paints the shape, taking into account the state passed to it.
  ///
  /// {@macro flutter.material.slider.shape.context}
  ///
  /// {@macro flutter.material.slider.shape.center}
  ///
  /// [activationAnimation] is an animation triggered when the user beings
  /// to interact with the slider. It reverses when the user stops interacting
  /// with the slider.
  ///
  /// {@macro flutter.material.slider.shape.enableAnimation}
  ///
  /// {@macro flutter.material.slider.shape.isDiscrete}
  ///
  /// If [labelPainter] is non-null, then [labelPainter.paint] should be
  /// called with the location that the label should appear. If the labelPainter
  /// passed is null, then no label was supplied to the [Slider].
  ///
  /// {@macro flutter.material.slider.shape.parentBox}
  ///
  /// {@macro flutter.material.slider.shape.sliderTheme}
  ///
  /// [textDirection] can be used to determine how any extra text or graphics,
  /// besides the text painted by the [labelPainter] should be positioned. The
  /// [labelPainter] already has the [textDirection] set.
  ///
  /// [value] is the current parametric value (from 0.0 to 1.0) of the slider.
  void paint(
    PaintingContext context,
    Offset center, {
    Animation<double> activationAnimation,
    Animation<double> enableAnimation,
    bool isDiscrete,
    TextPainter labelPainter,
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    TextDirection textDirection,
    double value,
  });

  /// Special instance of [SliderComponentShape] to skip the thumb drawing.
  ///
  /// See also:
  ///
  /// * [SliderThemeData.thumbShape], which is the shape that the [Slider]
  /// uses when painting the thumb.
  static final SliderComponentShape noThumb = _EmptySliderComponentShape();

  /// Special instance of [SliderComponentShape] to skip the overlay drawing.
  ///
  /// See also:
  ///
  /// * [SliderThemeData.overlayShape], which is the shape that the [Slider]
  /// uses when painting the overlay.
  static final SliderComponentShape noOverlay = _EmptySliderComponentShape();
}

/// A special version of [SliderComponentShape] that has a zero size and paints
/// nothing.
///
/// This class is used to create a special instance of a [SliderComponentShape]
/// that will not paint any component shape. A static reference is stored in
/// [SliderTickMarkShape.noThumb] and [SliderTickMarkShape.noOverlay]. When this value
/// is specified for [SliderThemeData.thumbShape], the thumb painting is
/// skipped.  When this value is specified for [SliderThemeData.overlaySHape],
/// the overlay painting is skipped.
class _EmptySliderComponentShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.zero;

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    Animation<double> activationAnimation,
    Animation<double> enableAnimation,
    bool isDiscrete,
    TextPainter labelPainter,
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    TextDirection textDirection,
    double value,
  }) {
    // no-op.
  }
}

// The following shapes are the material defaults.

/// This is the default shape of a [Slider]'s track.
///
/// It paints a solid colored rectangle, vertically centered in the
/// [parentBox]. The track rectangle extends to the bounds of the [parentBox],
/// but is padded by the [RoundSliderOverlayShape] radius. The height is defined
/// by the [SliderThemeData.trackHeight]. The color is determined by the
/// [Slider]'s enabled state and the track piece's active state which are
/// defined by:
///   [SliderThemeData.activeTrackColor],
///   [SliderThemeData.inactiveTrackColor],
///   [SliderThemeData.disabledActiveTrackColor],
///   [SliderThemeData.disabledInactiveTrackColor].
///
/// See also:
///
///  * [Slider] for the component that this is meant to display this shape.
///  * [SliderThemeData] where an instance of this class is set to inform the
///    slider of the visual details of the its track.
///  * [SliderTrackShape] Base component for creating other custom track
///    shapes.
class RectangularSliderTrackShape extends SliderTrackShape {
  /// Create a slider track that draws 2 rectangles.
  const RectangularSliderTrackShape({ this.disabledThumbGapWidth = 2.0 });

  /// Horizontal spacing, or gap, between the disabled thumb and the track.
  ///
  /// This is only used when the slider is disabled. There is no gap around
  /// the thumb and any part of the track when the slider is enabled. The
  /// Material spec defaults this gap width 2, which is half of the disabled
  /// thumb radius.
  final double disabledThumbGapWidth;

  @override
  Rect getPreferredRect({
    RenderBox parentBox,
    Offset offset = Offset.zero,
    SliderThemeData sliderTheme,
    bool isEnabled,
    bool isDiscrete,
  }) {
    final double overlayWidth = sliderTheme.overlayShape.getPreferredSize(isEnabled, isDiscrete).width;
    final double trackHeight = sliderTheme.trackHeight;
    assert(overlayWidth >= 0);
    assert(trackHeight >= 0);
    assert(parentBox.size.width >= overlayWidth);
    assert(parentBox.size.height >= trackHeight);

    final double trackLeft = offset.dx + overlayWidth / 2;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    // TODO(clocksmith): Although this works for a material, perhaps the default
    // rectangular track should be padded not just by the overlay, but by the
    // max of the thumb and the overlay, in case there is no overlay.
    final double trackWidth = parentBox.size.width - overlayWidth;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }


  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    Animation<double> enableAnimation,
    TextDirection textDirection,
    Offset thumbCenter,
    bool isDiscrete,
    bool isEnabled,
  }) {
    // If the slider track height is 0, then it makes no difference whether the
    // track is painted or not, therefore the painting can be a no-op.
    if (sliderTheme.trackHeight == 0) {
      return;
    }

    // Assign the track segment paints, which are left: active, right: inactive,
    // but reversed for right to left text.
    final ColorTween activeTrackColorTween = ColorTween(begin: sliderTheme.disabledActiveTrackColor , end: sliderTheme.activeTrackColor);
    final ColorTween inactiveTrackColorTween = ColorTween(begin: sliderTheme.disabledInactiveTrackColor , end: sliderTheme.inactiveTrackColor);
    final Paint activePaint = Paint()..color = activeTrackColorTween.evaluate(enableAnimation);
    final Paint inactivePaint = Paint()..color = inactiveTrackColorTween.evaluate(enableAnimation);
    Paint leftTrackPaint;
    Paint rightTrackPaint;
    switch (textDirection) {
      case TextDirection.ltr:
        leftTrackPaint = activePaint;
        rightTrackPaint = inactivePaint;
        break;
      case TextDirection.rtl:
        leftTrackPaint = inactivePaint;
        rightTrackPaint = activePaint;
        break;
    }

    // Used to create a gap around the thumb iff the slider is disabled.
    // If the slider is enabled, the track can be drawn beneath the thumb
    // without a gap. But when the slider is disabled, the track is shortened
    // and this gap helps determine how much shorter it should be.
    // TODO(clocksmith): The new Material spec has a gray circle in place of this gap.
    double horizontalAdjustment = 0.0;
    if (!isEnabled) {
      final double disabledThumbRadius = sliderTheme.thumbShape.getPreferredSize(false, isDiscrete).width / 2.0;
      final double gap = disabledThumbGapWidth * (1.0 - enableAnimation.value);
      horizontalAdjustment = disabledThumbRadius + gap;
    }

    final Rect trackRect = getPreferredRect(
        parentBox: parentBox,
        offset: offset,
        sliderTheme: sliderTheme,
        isEnabled: isEnabled,
        isDiscrete: isDiscrete
    );
    final Rect leftTrackSegment = Rect.fromLTRB(trackRect.left, trackRect.top, thumbCenter.dx - horizontalAdjustment, trackRect.bottom);
    context.canvas.drawRect(leftTrackSegment, leftTrackPaint);
    final Rect rightTrackSegment = Rect.fromLTRB(thumbCenter.dx + horizontalAdjustment, trackRect.top, trackRect.right, trackRect.bottom);
    context.canvas.drawRect(rightTrackSegment, rightTrackPaint);
  }
}

/// This is the default shape of each [Slider] tick mark.
///
/// Tick marks are only displayed if the slider is discrete, which can be done
/// by setting the [Slider.divisions] as non-null.
///
/// It paints a solid circle, centered in the on the track.
/// The color is determined by the [Slider]'s enabled state and track's active
/// states. These colors are defined in:
///   [SliderThemeData.activeTrackColor],
///   [SliderThemeData.inactiveTrackColor],
///   [SliderThemeData.disabledActiveTrackColor],
///   [SliderThemeData.disabledInactiveTrackColor].
///
/// See also:
///
///  * [Slider], which includes tick marks defined by this shape.
///  * [SliderTheme], which can be used to configure the tick mark shape of all
///    sliders in a widget subtree.
class RoundSliderTickMarkShape extends SliderTickMarkShape {
  /// Create a slider tick mark that draws a circle.
  const RoundSliderTickMarkShape({ this.tickMarkRadius });

  /// The preferred radius of the round tick mark.
  ///
  /// If it is not provided, then half of the track height is used.
  final double tickMarkRadius;

  @override
  Size getPreferredSize({
    bool isEnabled,
    SliderThemeData sliderTheme,
  }) {
    // The tick marks are tiny circles. If no radius is provided, then they are
    // defaulted to be the same height as the track.
    return Size.fromRadius(tickMarkRadius ?? sliderTheme.trackHeight / 2);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    Animation<double> enableAnimation,
    TextDirection textDirection,
    Offset thumbCenter,
    bool isEnabled,
  }) {
    // The paint color of the tick mark depends on its position relative
    // to the thumb and the text direction.
    Color begin;
    Color end;
    switch (textDirection) {
      case TextDirection.ltr:
        final bool isTickMarkRightOfThumb = center.dx > thumbCenter.dx;
        begin = isTickMarkRightOfThumb ? sliderTheme.disabledInactiveTickMarkColor : sliderTheme.disabledActiveTickMarkColor;
        end = isTickMarkRightOfThumb ? sliderTheme.inactiveTickMarkColor : sliderTheme.activeTickMarkColor;
        break;
      case TextDirection.rtl:
        final bool isTickMarkLeftOfThumb = center.dx < thumbCenter.dx;
        begin = isTickMarkLeftOfThumb ? sliderTheme.disabledInactiveTickMarkColor : sliderTheme.disabledActiveTickMarkColor;
        end = isTickMarkLeftOfThumb ? sliderTheme.inactiveTickMarkColor : sliderTheme.activeTickMarkColor;
        break;
    }
    final Paint paint = Paint()..color = ColorTween(begin: begin, end: end).evaluate(enableAnimation);

    // The tick marks are tiny circles that are the same height as the track.
    final double tickMarkRadius = getPreferredSize(
      isEnabled: isEnabled,
      sliderTheme: sliderTheme,
    ).width / 2;
    context.canvas.drawCircle(center, tickMarkRadius, paint);
  }
}

/// This is the default shape of a [Slider]'s thumb.
///
/// See also:
///
///  * [Slider], which includes a thumb defined by this shape.
///  * [SliderTheme], which can be used to configure the thumb shape of all
///    sliders in a widget subtree.
class RoundSliderThumbShape extends SliderComponentShape {
  /// Create a slider thumb that draws a circle.
  // TODO(clocksmith): This needs to be changed to 10 according to spec.
  const RoundSliderThumbShape({
    this.enabledThumbRadius = 6.0,
    this.disabledThumbRadius
  });

  /// The preferred radius of the round thumb shape when the slider is enabled.
  ///
  /// If it is not provided, then the material default is used.
  final double enabledThumbRadius;

  /// The preferred radius of the round thumb shape when the slider is disabled.
  ///
  /// If no disabledRadius is provided, then it is is derived from the enabled
  /// thumb radius and has the same ratio of enabled size to disabled size as
  /// the Material spec. The default resolves to 4, which is 2 / 3 of the
  /// default enabled thumb.
  final double disabledThumbRadius;
  // TODO(clocksmith): This needs to be updated once the thumb size is updated to the Material spec.
  double get _disabledThumbRadius =>  disabledThumbRadius ?? enabledThumbRadius * 2 / 3;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(isEnabled ? enabledThumbRadius : _disabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    Animation<double> activationAnimation,
    Animation<double> enableAnimation,
    bool isDiscrete,
    TextPainter labelPainter,
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    TextDirection textDirection,
    double value,
  }) {
    final Canvas canvas = context.canvas;
    final Tween<double> radiusTween = Tween<double>(
      begin: _disabledThumbRadius,
      end: enabledThumbRadius,
    );
    final ColorTween colorTween = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    );
    canvas.drawCircle(
      center,
      radiusTween.evaluate(enableAnimation),
      Paint()..color = colorTween.evaluate(enableAnimation),
    );
  }
}

/// This is the default shape of a [Slider]'s thumb overlay.
///
/// The shape of the overlay is a circle with the same center as the thumb, but
/// with a larger radius. It animates to full size when the thumb is pressed,
/// and animates back down to size 0 when it is released. It is painted behind
/// the thumb, and is expected to extend beyond the bounds of the thumb so that
/// it is visible.
///
/// The overlay color is defined by [SliderThemeData.overlayColor].
///
/// See also:
///
///  * [Slider], which includes an overlay defined by this shape.
///  * [SliderTheme], which can be used to configure the overlay shape of all
///    sliders in a widget subtree.
class RoundSliderOverlayShape extends SliderComponentShape {
  /// Create a slider thumb overlay that draws a circle.
  // TODO(clocksmith): This needs to be changed to 24 according to spec.
  const RoundSliderOverlayShape({ this.overlayRadius = 16.0 });

  /// The preferred radius of the round thumb shape when enabled.
  ///
  /// If it is not provided, then half of the track height is used.
  final double overlayRadius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(overlayRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    Animation<double> activationAnimation,
    Animation<double> enableAnimation,
    bool isDiscrete,
    TextPainter labelPainter,
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    TextDirection textDirection,
    double value,
  }) {
    final Canvas canvas = context.canvas;
    final Tween<double> radiusTween = Tween<double>(
      begin: 0.0,
      end: overlayRadius,
    );

    // TODO(gspencer): We don't really follow the spec here for overlays.
    // The spec says to use 16% opacity for drawing over light material,
    // and 32% for colored material, but we don't really have a way to
    // know what the underlying color is, so there's no easy way to
    // implement this. Choosing the "light" version for now.
    canvas.drawCircle(
      center,
      radiusTween.evaluate(activationAnimation),
      Paint()..color = sliderTheme.overlayColor,
    );
  }
}

/// This is the default shape of a [Slider]'s value indicator.
///
/// See also:
///
///  * [Slider], which includes a value indicator defined by this shape.
///  * [SliderTheme], which can be used to configure the slider value indicator
///    of all sliders in a widget subtree.
class PaddleSliderValueIndicatorShape extends SliderComponentShape {
  /// Create a slider value indicator in the shape of an upside-down pear.
  const PaddleSliderValueIndicatorShape();

  // These constants define the shape of the default value indicator.
  // The value indicator changes shape based on the size of
  // the label: The top lobe spreads horizontally, and the
  // top arc on the neck moves down to keep it merging smoothly
  // with the top lobe as it expands.

  // Radius of the top lobe of the value indicator.
  static const double _topLobeRadius = 16.0;
  // Designed size of the label text. This is the size that the value indicator
  // was designed to contain. We scale it from here to fit other sizes.
  static const double _labelTextDesignSize = 14.0;
  // Radius of the bottom lobe of the value indicator.
  static const double _bottomLobeRadius = 6.0;
  // The starting angle for the bottom lobe. Picked to get the desired
  // thickness for the neck.
  static const double _bottomLobeStartAngle = -1.1 * math.pi / 4.0;
  // The ending angle for the bottom lobe. Picked to get the desired
  // thickness for the neck.
  static const double _bottomLobeEndAngle = 1.1 * 5 * math.pi / 4.0;
  // The padding on either side of the label.
  static const double _labelPadding = 8.0;
  static const double _distanceBetweenTopBottomCenters = 40.0;
  static const Offset _topLobeCenter = Offset(0.0, -_distanceBetweenTopBottomCenters);
  static const double _topNeckRadius = 14.0;
  // The length of the hypotenuse of the triangle formed by the center
  // of the left top lobe arc and the center of the top left neck arc.
  // Used to calculate the position of the center of the arc.
  static const double _neckTriangleHypotenuse = _topLobeRadius + _topNeckRadius;
  // Some convenience values to help readability.
  static const double _twoSeventyDegrees = 3.0 * math.pi / 2.0;
  static const double _ninetyDegrees = math.pi / 2.0;
  static const double _thirtyDegrees = math.pi / 6.0;
  static const Size _preferredSize = Size.fromHeight(_distanceBetweenTopBottomCenters + _topLobeRadius + _bottomLobeRadius);
  // Set to true if you want a rectangle to be drawn around the label bubble.
  // This helps with building tests that check that the label draws in the right
  // place (because it prints the rect in the failed test output). It should not
  // be checked in while set to "true".
  static const bool _debuggingLabelLocation = false;

  static Path _bottomLobePath; // Initialized by _generateBottomLobe
  static Offset _bottomLobeEnd; // Initialized by _generateBottomLobe

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => _preferredSize;

  // Adds an arc to the path that has the attributes passed in. This is
  // a convenience to make adding arcs have less boilerplate.
  static void _addArc(Path path, Offset center, double radius, double startAngle, double endAngle) {
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);
    path.arcTo(arcRect, startAngle, endAngle - startAngle, false);
  }

  // Generates the bottom lobe path, which is the same for all instances of
  // the value indicator, so we reuse it for each one.
  static void _generateBottomLobe() {
    const double bottomNeckRadius = 4.5;
    const double bottomNeckStartAngle = _bottomLobeEndAngle - math.pi;
    const double bottomNeckEndAngle = 0.0;

    final Path path = Path();
    final Offset bottomKnobStart = Offset(
      _bottomLobeRadius * math.cos(_bottomLobeStartAngle),
      _bottomLobeRadius * math.sin(_bottomLobeStartAngle),
    );
    final Offset bottomNeckRightCenter = bottomKnobStart +
        Offset(
          bottomNeckRadius * math.cos(bottomNeckStartAngle),
          -bottomNeckRadius * math.sin(bottomNeckStartAngle),
        );
    final Offset bottomNeckLeftCenter = Offset(
      -bottomNeckRightCenter.dx,
      bottomNeckRightCenter.dy,
    );
    final Offset bottomNeckStartRight = Offset(
      bottomNeckRightCenter.dx - bottomNeckRadius,
      bottomNeckRightCenter.dy,
    );
    path.moveTo(bottomNeckStartRight.dx, bottomNeckStartRight.dy);
    _addArc(
      path,
      bottomNeckRightCenter,
      bottomNeckRadius,
      math.pi - bottomNeckEndAngle,
      math.pi - bottomNeckStartAngle,
    );
    _addArc(
      path,
      Offset.zero,
      _bottomLobeRadius,
      _bottomLobeStartAngle,
      _bottomLobeEndAngle,
    );
    _addArc(
      path,
      bottomNeckLeftCenter,
      bottomNeckRadius,
      bottomNeckStartAngle,
      bottomNeckEndAngle,
    );

    _bottomLobeEnd = Offset(
      -bottomNeckStartRight.dx,
      bottomNeckStartRight.dy,
    );
    _bottomLobePath = path;
  }

  Offset _addBottomLobe(Path path) {
    if (_bottomLobePath == null || _bottomLobeEnd == null) {
      // Generate this lazily so as to not slow down app startup.
      _generateBottomLobe();
    }
    path.extendWithPath(_bottomLobePath, Offset.zero);
    return _bottomLobeEnd;
  }

  // Determines the "best" offset to keep the bubble on the screen. The calling
  // code will bound that with the available movement in the paddle shape.
  double _getIdealOffset(
    RenderBox parentBox,
    double halfWidthNeeded,
    double scale,
    Offset center,
  ) {
    const double edgeMargin = 4.0;
    final Rect topLobeRect = Rect.fromLTWH(
      -_topLobeRadius - halfWidthNeeded,
      -_topLobeRadius - _distanceBetweenTopBottomCenters,
      2.0 * (_topLobeRadius + halfWidthNeeded),
      2.0 * _topLobeRadius,
    );
    // We can just multiply by scale instead of a transform, since we're scaling
    // around (0, 0).
    final Offset topLeft = (topLobeRect.topLeft * scale) + center;
    final Offset bottomRight = (topLobeRect.bottomRight * scale) + center;
    double shift = 0.0;
    if (topLeft.dx < edgeMargin) {
      shift = edgeMargin - topLeft.dx;
    }
    if (bottomRight.dx > parentBox.size.width - edgeMargin) {
      shift = parentBox.size.width - bottomRight.dx - edgeMargin;
    }
    shift = scale == 0.0 ? 0.0 : shift / scale;
    return shift;
  }

  void _drawValueIndicator(
    RenderBox parentBox,
    Canvas canvas,
    Offset center,
    Paint paint,
    double scale,
    TextPainter labelPainter,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    // The entire value indicator should scale with the size of the label,
    // to keep it large enough to encompass the label text.
    final double textScaleFactor = labelPainter.height / _labelTextDesignSize;
    final double overallScale = scale * textScaleFactor;
    canvas.scale(overallScale, overallScale);
    final double inverseTextScale = textScaleFactor != 0 ? 1.0 / textScaleFactor : 0.0;
    final double labelHalfWidth = labelPainter.width / 2.0;

    // This is the needed extra width for the label.  It is only positive when
    // the label exceeds the minimum size contained by the round top lobe.
    final double halfWidthNeeded = math.max(
      0.0,
      inverseTextScale * labelHalfWidth - (_topLobeRadius - _labelPadding),
    );

    double shift = _getIdealOffset(parentBox, halfWidthNeeded, overallScale, center);
    double leftWidthNeeded;
    double rightWidthNeeded;
    if (shift < 0.0) {
      // shifting to the left
      shift = math.max(shift, -halfWidthNeeded);
    } else {
      // shifting to the right
      shift = math.min(shift, halfWidthNeeded);
    }
    rightWidthNeeded = halfWidthNeeded + shift;
    leftWidthNeeded = halfWidthNeeded - shift;

    final Path path = Path();
    final Offset bottomLobeEnd = _addBottomLobe(path);

    // The base of the triangle between the top lobe center and the centers of
    // the two top neck arcs.
    final double neckTriangleBase = _topNeckRadius - bottomLobeEnd.dx;
    // The parameter that describes how far along the transition from round to
    // stretched we are.
    final double leftAmount = math.max(0.0, math.min(1.0, leftWidthNeeded / neckTriangleBase));
    final double rightAmount = math.max(0.0, math.min(1.0, rightWidthNeeded / neckTriangleBase));
    // The angle between the top neck arc's center and the top lobe's center
    // and vertical.
    final double leftTheta = (1.0 - leftAmount) * _thirtyDegrees;
    final double rightTheta = (1.0 - rightAmount) * _thirtyDegrees;
    // The center of the top left neck arc.
    final Offset neckLeftCenter = Offset(
      -neckTriangleBase,
      _topLobeCenter.dy + math.cos(leftTheta) * _neckTriangleHypotenuse,
    );
    final Offset neckRightCenter = Offset(
      neckTriangleBase,
      _topLobeCenter.dy + math.cos(rightTheta) * _neckTriangleHypotenuse,
    );
    final double leftNeckArcAngle = _ninetyDegrees - leftTheta;
    final double rightNeckArcAngle = math.pi + _ninetyDegrees - rightTheta;
    // The distance between the end of the bottom neck arc and the beginning of
    // the top neck arc. We use this to shrink/expand it based on the scale
    // factor of the value indicator.
    final double neckStretchBaseline = bottomLobeEnd.dy - math.max(neckLeftCenter.dy, neckRightCenter.dy);
    final double t = math.pow(inverseTextScale, 3.0);
    final double stretch = (neckStretchBaseline * t).clamp(0.0, 10.0 * neckStretchBaseline);
    final Offset neckStretch = Offset(0.0, neckStretchBaseline - stretch);

    assert(!_debuggingLabelLocation ||
        () {
          final Offset leftCenter = _topLobeCenter - Offset(leftWidthNeeded, 0.0) + neckStretch;
          final Offset rightCenter = _topLobeCenter + Offset(rightWidthNeeded, 0.0) + neckStretch;
          final Rect valueRect = Rect.fromLTRB(
            leftCenter.dx - _topLobeRadius,
            leftCenter.dy - _topLobeRadius,
            rightCenter.dx + _topLobeRadius,
            rightCenter.dy + _topLobeRadius,
          );
          final Paint outlinePaint = Paint()
            ..color = const Color(0xffff0000)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;
          canvas.drawRect(valueRect, outlinePaint);
          return true;
        }());

    _addArc(
      path,
      neckLeftCenter + neckStretch,
      _topNeckRadius,
      0.0,
      -leftNeckArcAngle,
    );
    _addArc(
      path,
      _topLobeCenter - Offset(leftWidthNeeded, 0.0) + neckStretch,
      _topLobeRadius,
      _ninetyDegrees + leftTheta,
      _twoSeventyDegrees,
    );
    _addArc(
      path,
      _topLobeCenter + Offset(rightWidthNeeded, 0.0) + neckStretch,
      _topLobeRadius,
      _twoSeventyDegrees,
      _twoSeventyDegrees + math.pi - rightTheta,
    );
    _addArc(
      path,
      neckRightCenter + neckStretch,
      _topNeckRadius,
      rightNeckArcAngle,
      math.pi,
    );
    canvas.drawPath(path, paint);

    // Draw the label.
    canvas.save();
    canvas.translate(shift, -_distanceBetweenTopBottomCenters + neckStretch.dy);
    canvas.scale(inverseTextScale, inverseTextScale);
    labelPainter.paint(canvas, Offset.zero - Offset(labelHalfWidth, labelPainter.height / 2.0));
    canvas.restore();
    canvas.restore();
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    Animation<double> activationAnimation,
    Animation<double> enableAnimation,
    bool isDiscrete,
    TextPainter labelPainter,
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    TextDirection textDirection,
    double value,
  }) {
    final ColorTween enableColor = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.valueIndicatorColor,
    );
    _drawValueIndicator(
      parentBox,
      context.canvas,
      center,
      Paint()..color = enableColor.evaluate(enableAnimation),
      activationAnimation.value,
      labelPainter,
    );
  }
}

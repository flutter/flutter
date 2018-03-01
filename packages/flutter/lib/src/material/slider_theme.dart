// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show Path;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
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
/// See also:
///
///  * [SliderThemeData], which describes the actual configuration of a slider
///    theme.
///  * [SliderComponentShape], which can be used to create custom shapes for
///    the slider thumb and value indicator.
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
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// double _rocketThrust;
  ///
  /// @override
  /// Widget build(BuildContext context) {
  ///   return new SliderTheme(
  ///     data: SliderTheme.of(context).copyWith(activeRail: Colors.orange),
  ///     child: new Slider(
  ///       onChanged: (double value) => setState(() => _rocketThrust = value),
  ///       value: _rocketThrust;
  ///     ),
  ///   );
  /// }
  /// ```
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
  bool updateShouldNotify(SliderTheme old) => data != old.data;
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
///  * The "rail", which is the line that the slider thumb slides along.
///  * The "value indicator", which is a shape that pops up when the user
///    is dragging the thumb to indicate the value being selected.
///  * The "active" side of the slider is the side between the thumb and the
///    minimum value.
///  * The "inactive" side of the slider is the side between the thumb and the
///    maximum value.
///  * The [Slider] is disabled when it is not accepting user input. See
///    [Slider] for details on when this happens.
///
/// The thumb and the value indicator may have their shapes and behavior
/// customized by creating your own [SliderComponentShape] that does what
/// you want. See [RoundSliderThumbShape] and
/// [PaddleSliderValueIndicatorShape] for examples.
///
/// See also:
///
///  * [SliderTheme] widget, which can override the slider theme of its
///    children.
///  * [Theme] widget, which performs a similar function to [SliderTheme],
///    but for overall themes.
///  * [ThemeData], which has a default [SliderThemeData].
///  * [SliderComponentShape], to define custom slider component shapes.
class SliderThemeData extends Diagnosticable {
  /// Create a [SliderThemeData] given a set of exact values. All the values
  /// must be specified.
  ///
  /// This will rarely be used directly. It is used by [lerp] to
  /// create intermediate themes based on two themes.
  ///
  /// The simplest way to create a SliderThemeData is to use
  /// [copyWith] on the one you get from [SliderTheme.of], or create an
  /// entirely new one with [SliderThemeData.materialDefaults].
  const SliderThemeData({
    @required this.activeRailColor,
    @required this.inactiveRailColor,
    @required this.disabledActiveRailColor,
    @required this.disabledInactiveRailColor,
    @required this.activeTickMarkColor,
    @required this.inactiveTickMarkColor,
    @required this.disabledActiveTickMarkColor,
    @required this.disabledInactiveTickMarkColor,
    @required this.thumbColor,
    @required this.disabledThumbColor,
    @required this.overlayColor,
    @required this.valueIndicatorColor,
    @required this.thumbShape,
    @required this.valueIndicatorShape,
    @required this.showValueIndicator,
  }) : assert(activeRailColor != null),
       assert(inactiveRailColor != null),
       assert(disabledActiveRailColor != null),
       assert(disabledInactiveRailColor != null),
       assert(activeTickMarkColor != null),
       assert(inactiveTickMarkColor != null),
       assert(disabledActiveTickMarkColor != null),
       assert(disabledInactiveTickMarkColor != null),
       assert(thumbColor != null),
       assert(disabledThumbColor != null),
       assert(overlayColor != null),
       assert(valueIndicatorColor != null),
       assert(thumbShape != null),
       assert(valueIndicatorShape != null),
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
  factory SliderThemeData.materialDefaults({
    @required Color primaryColor,
    @required Color primaryColorDark,
    @required Color primaryColorLight,
  }) {
    assert(primaryColor != null);
    assert(primaryColorDark != null);
    assert(primaryColorLight != null);

    // These are Material Design defaults, and are used to derive
    // component Colors (with opacity) from base colors.
    const int activeRailAlpha = 0xff;
    const int inactiveRailAlpha = 0x3d; // 24% opacity
    const int disabledActiveRailAlpha = 0x52; // 32% opacity
    const int disabledInactiveRailAlpha = 0x1f; // 12% opacity
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

    return new SliderThemeData(
      activeRailColor: primaryColor.withAlpha(activeRailAlpha),
      inactiveRailColor: primaryColor.withAlpha(inactiveRailAlpha),
      disabledActiveRailColor: primaryColorDark.withAlpha(disabledActiveRailAlpha),
      disabledInactiveRailColor: primaryColorDark.withAlpha(disabledInactiveRailAlpha),
      activeTickMarkColor: primaryColorLight.withAlpha(activeTickMarkAlpha),
      inactiveTickMarkColor: primaryColor.withAlpha(inactiveTickMarkAlpha),
      disabledActiveTickMarkColor: primaryColorLight.withAlpha(disabledActiveTickMarkAlpha),
      disabledInactiveTickMarkColor: primaryColorDark.withAlpha(disabledInactiveTickMarkAlpha),
      thumbColor: primaryColor.withAlpha(thumbAlpha),
      disabledThumbColor: primaryColorDark.withAlpha(disabledThumbAlpha),
      overlayColor: primaryColor.withAlpha(overlayLightAlpha),
      valueIndicatorColor: primaryColor.withAlpha(valueIndicatorAlpha),
      thumbShape: const RoundSliderThumbShape(),
      valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
      showValueIndicator: ShowValueIndicator.onlyForDiscrete,
    );
  }

  final Color activeRailColor;
  final Color inactiveRailColor;
  final Color disabledActiveRailColor;
  final Color disabledInactiveRailColor;
  final Color activeTickMarkColor;
  final Color inactiveTickMarkColor;
  final Color disabledActiveTickMarkColor;
  final Color disabledInactiveTickMarkColor;
  final Color thumbColor;
  final Color disabledThumbColor;
  final Color overlayColor;
  final Color valueIndicatorColor;
  final SliderComponentShape thumbShape;
  final SliderComponentShape valueIndicatorShape;

  /// Whether the value indicator should be shown for different types of sliders.
  ///
  /// By default, [showValueIndicator] is set to
  /// [ShowValueIndicator.onlyForDiscrete]. The value indicator is only shown
  /// when the thumb is being touched.
  final ShowValueIndicator showValueIndicator;

  SliderThemeData copyWith({
    Color activeRailColor,
    Color inactiveRailColor,
    Color disabledActiveRailColor,
    Color disabledInactiveRailColor,
    Color activeTickMarkColor,
    Color inactiveTickMarkColor,
    Color disabledActiveTickMarkColor,
    Color disabledInactiveTickMarkColor,
    Color thumbColor,
    Color disabledThumbColor,
    Color overlayColor,
    Color valueIndicatorColor,
    SliderComponentShape thumbShape,
    SliderComponentShape valueIndicatorShape,
    ShowValueIndicator showValueIndicator,
  }) {
    return new SliderThemeData(
      activeRailColor: activeRailColor ?? this.activeRailColor,
      inactiveRailColor: inactiveRailColor ?? this.inactiveRailColor,
      disabledActiveRailColor: disabledActiveRailColor ?? this.disabledActiveRailColor,
      disabledInactiveRailColor: disabledInactiveRailColor ?? this.disabledInactiveRailColor,
      activeTickMarkColor: activeTickMarkColor ?? this.activeTickMarkColor,
      inactiveTickMarkColor: inactiveTickMarkColor ?? this.inactiveTickMarkColor,
      disabledActiveTickMarkColor: disabledActiveTickMarkColor ?? this.disabledActiveTickMarkColor,
      disabledInactiveTickMarkColor:
          disabledInactiveTickMarkColor ?? this.disabledInactiveTickMarkColor,
      thumbColor: thumbColor ?? this.thumbColor,
      disabledThumbColor: disabledThumbColor ?? this.disabledThumbColor,
      overlayColor: overlayColor ?? this.overlayColor,
      valueIndicatorColor: valueIndicatorColor ?? this.valueIndicatorColor,
      thumbShape: thumbShape ?? this.thumbShape,
      valueIndicatorShape: valueIndicatorShape ?? this.valueIndicatorShape,
      showValueIndicator: showValueIndicator ?? this.showValueIndicator,
    );
  }

  /// Linearly interpolate between two slider themes.
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
  static SliderThemeData lerp(SliderThemeData a, SliderThemeData b, double t) {
    assert(a != null);
    assert(b != null);
    assert(t != null);
    return new SliderThemeData(
      activeRailColor: Color.lerp(a.activeRailColor, b.activeRailColor, t),
      inactiveRailColor: Color.lerp(a.inactiveRailColor, b.inactiveRailColor, t),
      disabledActiveRailColor: Color.lerp(a.disabledActiveRailColor, b.disabledActiveRailColor, t),
      disabledInactiveRailColor:
          Color.lerp(a.disabledInactiveRailColor, b.disabledInactiveRailColor, t),
      activeTickMarkColor: Color.lerp(a.activeTickMarkColor, b.activeTickMarkColor, t),
      inactiveTickMarkColor: Color.lerp(a.inactiveTickMarkColor, b.inactiveTickMarkColor, t),
      disabledActiveTickMarkColor:
          Color.lerp(a.disabledActiveTickMarkColor, b.disabledActiveTickMarkColor, t),
      disabledInactiveTickMarkColor:
          Color.lerp(a.disabledInactiveTickMarkColor, b.disabledInactiveTickMarkColor, t),
      thumbColor: Color.lerp(a.thumbColor, b.thumbColor, t),
      disabledThumbColor: Color.lerp(a.disabledThumbColor, b.disabledThumbColor, t),
      overlayColor: Color.lerp(a.overlayColor, b.overlayColor, t),
      valueIndicatorColor: Color.lerp(a.valueIndicatorColor, b.valueIndicatorColor, t),
      thumbShape: t < 0.5 ? a.thumbShape : b.thumbShape,
      valueIndicatorShape: t < 0.5 ? a.valueIndicatorShape : b.valueIndicatorShape,
      showValueIndicator: t < 0.5 ? a.showValueIndicator : b.showValueIndicator,
    );
  }

  @override
  int get hashCode {
    return hashValues(
      activeRailColor,
      inactiveRailColor,
      disabledActiveRailColor,
      disabledInactiveRailColor,
      activeTickMarkColor,
      inactiveTickMarkColor,
      disabledActiveTickMarkColor,
      disabledInactiveTickMarkColor,
      thumbColor,
      disabledThumbColor,
      overlayColor,
      valueIndicatorColor,
      thumbShape,
      valueIndicatorShape,
      showValueIndicator,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final SliderThemeData otherData = other;
    return otherData.activeRailColor == activeRailColor &&
        otherData.inactiveRailColor == inactiveRailColor &&
        otherData.disabledActiveRailColor == disabledActiveRailColor &&
        otherData.disabledInactiveRailColor == disabledInactiveRailColor &&
        otherData.activeTickMarkColor == activeTickMarkColor &&
        otherData.inactiveTickMarkColor == inactiveTickMarkColor &&
        otherData.disabledActiveTickMarkColor == disabledActiveTickMarkColor &&
        otherData.disabledInactiveTickMarkColor == disabledInactiveTickMarkColor &&
        otherData.thumbColor == thumbColor &&
        otherData.disabledThumbColor == disabledThumbColor &&
        otherData.overlayColor == overlayColor &&
        otherData.valueIndicatorColor == valueIndicatorColor &&
        otherData.thumbShape == thumbShape &&
        otherData.valueIndicatorShape == valueIndicatorShape &&
        otherData.showValueIndicator == showValueIndicator;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    final ThemeData defaultTheme = new ThemeData.fallback();
    final SliderThemeData defaultData = new SliderThemeData.materialDefaults(
      primaryColor: defaultTheme.primaryColor,
      primaryColorDark: defaultTheme.primaryColorDark,
      primaryColorLight: defaultTheme.primaryColorLight,
    );
    description.add(new DiagnosticsProperty<Color>('activeRailColor', activeRailColor,
        defaultValue: defaultData.activeRailColor));
    description.add(new DiagnosticsProperty<Color>('inactiveRailColor', inactiveRailColor,
        defaultValue: defaultData.inactiveRailColor));
    description.add(new DiagnosticsProperty<Color>(
        'disabledActiveRailColor', disabledActiveRailColor,
        defaultValue: defaultData.disabledActiveRailColor));
    description.add(new DiagnosticsProperty<Color>(
        'disabledInactiveRailColor', disabledInactiveRailColor,
        defaultValue: defaultData.disabledInactiveRailColor));
    description.add(new DiagnosticsProperty<Color>('activeTickMarkColor', activeTickMarkColor,
        defaultValue: defaultData.activeTickMarkColor));
    description.add(new DiagnosticsProperty<Color>('inactiveTickMarkColor', inactiveTickMarkColor,
        defaultValue: defaultData.inactiveTickMarkColor));
    description.add(new DiagnosticsProperty<Color>(
        'disabledActiveTickMarkColor', disabledActiveTickMarkColor,
        defaultValue: defaultData.disabledActiveTickMarkColor));
    description.add(new DiagnosticsProperty<Color>(
        'disabledInactiveTickMarkColor', disabledInactiveTickMarkColor,
        defaultValue: defaultData.disabledInactiveTickMarkColor));
    description.add(new DiagnosticsProperty<Color>('thumbColor', thumbColor,
        defaultValue: defaultData.thumbColor));
    description.add(new DiagnosticsProperty<Color>('disabledThumbColor', disabledThumbColor,
        defaultValue: defaultData.disabledThumbColor));
    description.add(new DiagnosticsProperty<Color>('overlayColor', overlayColor,
        defaultValue: defaultData.overlayColor));
    description.add(new DiagnosticsProperty<Color>('valueIndicatorColor', valueIndicatorColor,
        defaultValue: defaultData.valueIndicatorColor));
    description.add(new DiagnosticsProperty<SliderComponentShape>('thumbShape', thumbShape,
        defaultValue: defaultData.thumbShape));
    description.add(new DiagnosticsProperty<SliderComponentShape>(
        'valueIndicatorShape', valueIndicatorShape,
        defaultValue: defaultData.valueIndicatorShape));
    description.add(new DiagnosticsProperty<ShowValueIndicator>(
        'showValueIndicator', showValueIndicator,
        defaultValue: defaultData.showValueIndicator));
  }
}

/// Base class for slider thumb and value indicator shapes.
///
/// Create a subclass of this if you would like a custom slider thumb or
/// value indicator shape.
///
/// See also:
///
///  * [RoundSliderThumbShape] for a simple example of a thumb shape.
///  * [PaddleSliderValueIndicatorShape], for a complex example of a value
///    indicator shape.
abstract class SliderComponentShape {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const SliderComponentShape();

  /// Returns the preferred size of the shape, based on the given conditions.
  Size getPreferredSize(bool isEnabled, bool isDiscrete);

  /// Paints the shape, taking into account the state passed to it.
  ///
  /// [activationAnimation] is an animation triggered when the user beings
  /// to interact with the slider. It reverses when the user stops interacting
  /// with the slider.
  /// [enableAnimation] is an animation triggered when the [Slider] is enabled,
  /// and it reverses when the slider is disabled.
  /// If [labelPainter] is non-null, then [labelPainter.paint] should be
  /// called with the location that the label should appear. If the labelPainter
  /// passed is null, then no label was supplied to the [Slider].
  /// [value] is the current parametric value (from 0.0 to 1.0) of the slider.
  void paint(
    PaintingContext context,
    bool isDiscrete,
    Offset thumbCenter,
    Animation<double> activationAnimation,
    Animation<double> enableAnimation,
    TextPainter labelPainter,
    SliderThemeData sliderTheme,
    TextDirection textDirection,
    double textScaleFactor,
    double value,
  );
}

/// This is the default shape to a [Slider]'s thumb if no
/// other shape is specified.
///
/// See also:
///
///  * [Slider] for the component that this is meant to display this shape.
///  * [SliderThemeData] where an instance of this class is set to inform the
///    slider of the shape of the its thumb.
class RoundSliderThumbShape extends SliderComponentShape {
  const RoundSliderThumbShape();
  static const double _thumbRadius = 6.0;
  static const double _disabledThumbRadius = 4.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return new Size.fromRadius(isEnabled ? _thumbRadius : _disabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    bool isDiscrete,
    Offset thumbCenter,
    Animation<double> activationAnimation,
    Animation<double> enableAnimation,
    TextPainter labelPainter,
    SliderThemeData sliderTheme,
    TextDirection textDirection,
    double textScaleFactor,
    double value,
  ) {
    final Canvas canvas = context.canvas;
    final Tween<double> radiusTween =
        new Tween<double>(begin: _disabledThumbRadius, end: _thumbRadius);
    final ColorTween colorTween =
        new ColorTween(begin: sliderTheme.disabledThumbColor, end: sliderTheme.thumbColor);
    canvas.drawCircle(
      thumbCenter,
      radiusTween.evaluate(enableAnimation),
      new Paint()..color = colorTween.evaluate(enableAnimation),
    );
  }
}

/// This is the default shape to a [Slider]'s value indicator if no
/// other shape is specified.
///
/// See also:
///
///  * [Slider] for the component that this is meant to display this shape.
///  * [SliderThemeData] where an instance of this class is set to inform the
///    slider of the shape of the its value indicator.
class PaddleSliderValueIndicatorShape extends SliderComponentShape {
  const PaddleSliderValueIndicatorShape();

  // These constants define the shape of the default value indicator.
  // The value indicator changes shape based on the size of
  // the label: The top lobe spreads horizontally, and the
  // top arc on the neck moves down to keep it merging smoothly
  // with the top lobe as it expands.

  // Radius of the top lobe of the value indicator.
  static const double _topLobeRadius = 16.0;
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
  static const Offset _topLobeCenter = const Offset(0.0, -_distanceBetweenTopBottomCenters);
  static const double _topNeckRadius = 14.0;
  // The length of the hypotenuse of the triangle formed by the center
  // of the left top lobe arc and the center of the top left neck arc.
  // Used to calculate the position of the center of the arc.
  static const double _neckTriangleHypotenuse = _topLobeRadius + _topNeckRadius;
  // Some convenience values to help readability.
  static const double _twoSeventyDegrees = 3.0 * math.pi / 2.0;
  static const double _ninetyDegrees = math.pi / 2.0;
  static const double _thirtyDegrees = math.pi / 6.0;
  static const Size preferredSize =
      const Size.fromHeight(_distanceBetweenTopBottomCenters + _topLobeRadius + _bottomLobeRadius);

  static final Tween<double> _slideUpTween = new Tween<double>(begin: 0.0, end: 1.0);
  static Path _bottomLobePath; // Initialized by _generateBottomLobe
  static Offset _bottomLobeEnd; // Initialized by _generateBottomLobe

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => preferredSize;

  // Adds an arc to the path that has the attributes passed in. This is
  // a convenience to make adding arcs have less boilerplate.
  static void _addArc(Path path, Offset center, double radius, double startAngle, double endAngle) {
    final Rect arcRect = new Rect.fromCircle(center: center, radius: radius);
    path.arcTo(arcRect, startAngle, endAngle - startAngle, false);
  }

  // Generates the bottom lobe path, which is the same for all instances of
  // the value indicator, so we reuse it for each one.
  static void _generateBottomLobe() {
    const double bottomNeckRadius = 4.5;
    const double bottomNeckStartAngle = _bottomLobeEndAngle - math.pi;
    const double bottomNeckEndAngle = 0.0;

    final Path path = new Path();
    final Offset bottomKnobStart = new Offset(
      _bottomLobeRadius * math.cos(_bottomLobeStartAngle),
      _bottomLobeRadius * math.sin(_bottomLobeStartAngle),
    );
    final Offset bottomNeckRightCenter = bottomKnobStart +
        new Offset(
          bottomNeckRadius * math.cos(bottomNeckStartAngle),
          -bottomNeckRadius * math.sin(bottomNeckStartAngle),
        );
    final Offset bottomNeckLeftCenter = new Offset(
      -bottomNeckRightCenter.dx,
      bottomNeckRightCenter.dy,
    );
    final Offset bottomNeckStartRight = new Offset(
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

    _bottomLobeEnd = new Offset(
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

  void _drawValueIndicator(Canvas canvas, Offset center, Paint paint, double scale,
      TextPainter labelPainter, double textScaleFactor) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    // The entire value indicator should scale with the text scale factor,
    // to keep it large enough to encompass the label text.
    canvas.scale(scale * textScaleFactor, scale * textScaleFactor);
    final double inverseTextScale = 1.0 / textScaleFactor;
    final double labelHalfWidth = labelPainter.width / 2.0;

    // This is the needed extra width for the label.  It is only positive when
    // the label exceeds the minimum size contained by the round top lobe.
    final double halfWidthNeeded =
        math.max(0.0, inverseTextScale * labelHalfWidth - (_topLobeRadius - _labelPadding));

    final Path path = new Path();
    final Offset bottomLobeEnd = _addBottomLobe(path);
    // The base of the triangle between the top lobe center and the centers of
    // the two top neck arcs.
    final double neckTriangleBase = _topNeckRadius - bottomLobeEnd.dx;
    // The parameter that describes how far along the transition from round to
    // stretched we are.
    final double t = math.max(0.0, math.min(1.0, halfWidthNeeded / neckTriangleBase));
    // The angle between the top neck arc's center and the top lobe's center
    // and vertical.
    final double theta = (1.0 - t) * _thirtyDegrees;
    // The center of the top left neck arc.
    final Offset neckLeftCenter = new Offset(
        -neckTriangleBase, _topLobeCenter.dy + math.cos(theta) * _neckTriangleHypotenuse);
    final Offset topLobeShift = new Offset(halfWidthNeeded, 0.0);
    final double neckArcAngle = _ninetyDegrees - theta;
    _addArc(
      path,
      neckLeftCenter,
      _topNeckRadius,
      0.0,
      -neckArcAngle,
    );
    _addArc(path, _topLobeCenter - topLobeShift, _topLobeRadius, _ninetyDegrees + theta,
        _twoSeventyDegrees);
    _addArc(path, _topLobeCenter + topLobeShift, _topLobeRadius, _twoSeventyDegrees,
        _twoSeventyDegrees + math.pi - theta);
    final Offset neckRightCenter = new Offset(-neckLeftCenter.dx, neckLeftCenter.dy);
    _addArc(
      path,
      neckRightCenter,
      _topNeckRadius,
      math.pi + neckArcAngle,
      math.pi,
    );
    canvas.drawPath(path, paint);

    // Draw the label.
    canvas.save();
    canvas.translate(0.0, -_distanceBetweenTopBottomCenters);
    canvas.scale(inverseTextScale, inverseTextScale);
    labelPainter.paint(canvas, Offset.zero - new Offset(labelHalfWidth, labelPainter.height / 2.0));
    canvas.restore();
    canvas.restore();
  }

  @override
  void paint(
    PaintingContext context,
    bool isDiscrete,
    Offset thumbCenter,
    Animation<double> activationAnimation,
    Animation<double> enableAnimation,
    TextPainter labelPainter,
    SliderThemeData sliderTheme,
    TextDirection textDirection,
    double textScaleFactor,
    double value,
  ) {
    assert(labelPainter != null);
    final ColorTween colorTween =
        new ColorTween(begin: Colors.transparent, end: sliderTheme.valueIndicatorColor);
    final ColorTween enableColor = new ColorTween(
        begin: sliderTheme.disabledThumbColor, end: colorTween.evaluate(activationAnimation));
    _drawValueIndicator(
      context.canvas,
      thumbCenter,
      new Paint()..color = enableColor.evaluate(enableAnimation),
      _slideUpTween.evaluate(activationAnimation),
      labelPainter,
      textScaleFactor,
    );
  }
}

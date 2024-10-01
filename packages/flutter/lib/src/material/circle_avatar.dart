// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

/// @docImport 'chip.dart';
/// @docImport 'color_scheme.dart';
/// @docImport 'list_tile.dart';
library;

import 'dart:core';
import 'dart:math';

import 'package:flutter/material.dart';

// Examples can assume:
// late String userAvatarUrl;

/// A circle that represents a user.
///
/// Typically used with a user's profile image, or, in the absence of
/// such an image, the user's initials. A given user's initials should
/// always be paired with the same background color, for consistency.
///
/// If [foregroundImage] fails then [backgroundImage] is used. If
/// [backgroundImage] fails too, [backgroundColor] is used.
///
/// The [onBackgroundImageError] parameter must be null if the [backgroundImage]
/// is null.
/// The [onForegroundImageError] parameter must be null if the [foregroundImage]
/// is null.
///
/// {@tool snippet}
///
/// If the avatar is to have an image, the image should be specified in the
/// [backgroundImage] property:
///
/// ```dart
/// CircleAvatar(
///   backgroundImage: NetworkImage(userAvatarUrl),
/// )
/// ```
/// {@end-tool}
///
/// The image will be cropped to have a circle shape.
///
/// {@tool snippet}
///
/// If the avatar is to just have the user's initials, they are typically
/// provided using a [Text] widget as the [child] and a [backgroundColor]:
///
/// ```dart
/// CircleAvatar(
///   backgroundColor: Colors.brown.shade800,
///   child: const Text('AH'),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Chip], for representing users or concepts in long form.
///  * [ListTile], which can combine an icon (such as a [CircleAvatar]) with
///    some text for a fixed height list entry.
///  * <https://material.io/design/components/chips.html#input-chips>
class CircleAvatar extends StatelessWidget {
  /// Creates a circle that represents a user.
  CircleAvatar({
    super.key,
    this.child,
    this.backgroundColor,
    this.backgroundImage,
    this.foregroundImage,
    this.onBackgroundImageError,
    this.onForegroundImageError,
    this.foregroundColor,
    this.radius,
    this.minRadius,
    this.maxRadius,
    this.border,
  })  : assert(radius == null || (minRadius == null && maxRadius == null)),
        assert(backgroundImage != null || onBackgroundImageError == null),
        assert(foregroundImage != null || onForegroundImageError == null);

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text] widget. If the [CircleAvatar] is to have an image, use
  /// [backgroundImage] instead.
  final Widget? child;

  /// The color with which to fill the circle. Changing the background
  /// color will cause the avatar to animate to the new color.
  ///
  /// If a [backgroundColor] is not specified and [ThemeData.useMaterial3] is true,
  /// [ColorScheme.primaryContainer] will be used, otherwise the theme's
  /// [ThemeData.primaryColorLight] is used with dark foreground colors, and
  /// [ThemeData.primaryColorDark] with light foreground colors.
  final Color? backgroundColor;

  /// The default text color for text in the circle.
  ///
  /// Defaults to the primary text theme color if no [backgroundColor] is
  /// specified.
  ///
  /// If a [foregroundColor] is not specified and [ThemeData.useMaterial3] is true,
  /// [ColorScheme.onPrimaryContainer] will be used, otherwise the theme's
  /// [ThemeData.primaryColorLight] for dark background colors, and
  /// [ThemeData.primaryColorDark] for light background colors.
  final Color? foregroundColor;

  /// The background image of the circle. Changing the background
  /// image will cause the avatar to animate to the new image.
  ///
  /// Typically used as a fallback image for [foregroundImage].
  ///
  /// If the [CircleAvatar] is to have the user's initials, use [child] instead.
  final ImageProvider? backgroundImage;

  /// The foreground image of the circle.
  ///
  /// Typically used as profile image. For fallback use [backgroundImage].
  final ImageProvider? foregroundImage;

  /// An optional error callback for errors emitted when loading
  /// [backgroundImage].
  final ImageErrorListener? onBackgroundImageError;

  /// An optional error callback for errors emitted when loading
  /// [foregroundImage].
  final ImageErrorListener? onForegroundImageError;

  /// The size of the avatar, expressed as the radius (half the diameter).
  ///
  /// If [radius] is specified, then neither [minRadius] nor [maxRadius] may be
  /// specified. Specifying [radius] is equivalent to specifying a [minRadius]
  /// and [maxRadius], both with the value of [radius].
  ///
  /// If neither [minRadius] nor [maxRadius] are specified, defaults to 20
  /// logical pixels. This is the appropriate size for use with
  /// [ListTile.leading].
  ///
  /// Changes to the [radius] are animated (including changing from an explicit
  /// [radius] to a [minRadius]/[maxRadius] pair or vice versa).
  final double? radius;

  /// The minimum size of the avatar, expressed as the radius (half the
  /// diameter).
  ///
  /// If [minRadius] is specified, then [radius] must not also be specified.
  ///
  /// Defaults to zero.
  ///
  /// Constraint changes are animated, but size changes due to the environment
  /// itself changing are not. For example, changing the [minRadius] from 10 to
  /// 20 when the [CircleAvatar] is in an unconstrained environment will cause
  /// the avatar to animate from a 20 pixel diameter to a 40 pixel diameter.
  /// However, if the [minRadius] is 40 and the [CircleAvatar] has a parent
  /// [SizedBox] whose size changes instantaneously from 20 pixels to 40 pixels,
  /// the size will snap to 40 pixels instantly.
  final double? minRadius;

  /// The maximum size of the avatar, expressed as the radius (half the
  /// diameter).
  ///
  /// If [maxRadius] is specified, then [radius] must not also be specified.
  ///
  /// Defaults to [double.infinity].
  ///
  /// Constraint changes are animated, but size changes due to the environment
  /// itself changing are not. For example, changing the [maxRadius] from 10 to
  /// 20 when the [CircleAvatar] is in an unconstrained environment will cause
  /// the avatar to animate from a 20 pixel diameter to a 40 pixel diameter.
  /// However, if the [maxRadius] is 40 and the [CircleAvatar] has a parent
  /// [SizedBox] whose size changes instantaneously from 20 pixels to 40 pixels,
  /// the size will snap to 40 pixels instantly.
  final double? maxRadius;

  /// An optional border property using the [Borders] class.
  ///
  /// This property allows you to define a border for a widget using an instance of the [Borders] class.
  ///
  /// If no border is provided, it defaults to a new instance of [Borders] with the following default values:
  ///
  /// * `color`: Black (`Color(0xFF000000)`).
  /// * `width`: 1.0 logical pixels.
  /// * `style`: [BorderStyle.solid].
  /// * `strokeAlign`: [BorderSide.strokeAlignInside].
  ///
  /// Example usage:
  ///
  /// ```dart
  /// CircleAvatar(
  ///   border: Borders(
  ///     color: Colors.blue,
  ///     width: 2.0,
  ///     style: BorderStyle.dashed,
  ///   ),
  /// );
  /// ```
  ///
  /// If you don't need to customize the border, you can also omit this parameter, and the default values will be used:
  ///
  /// The `border` can be applied to various UI components, such as [Container], [BoxDecoration], or any widget that supports borders.
  Borders? border = Borders();


  /// Represents a gradient color configuration.
///
/// The [GradientColor] class is used to define and manage a gradient color, which
/// can be applied to various UI components like backgrounds, borders, or custom-painted elements.
///
/// ### Example Usage:
///
/// ```dart
/// GradientColor gradientColor = GradientColor(
///   colors: [Colors.blue, Colors.green],
///   begin: Alignment.topLeft,
///   end: Alignment.bottomRight,
/// );
/// withBorder: 1.0
///
/// ```
///
/// In this example, a gradient is created from blue to green, starting from the top-left
/// and ending at the bottom-right. You can apply this gradient to widgets such as containers,
/// buttons, or custom painters.
///
/// ### Parameters:
///
/// * `colors`: A list of [Color] objects that defines the colors of the gradient.
///   If not specified, default gradient colors will be used.
///
/// * `begin`: The starting alignment of the gradient. Defaults to [Alignment.center].
///
/// * `end`: The ending alignment of the gradient. Defaults to [Alignment.center].
/// ### Properties:
///
/// * `colors`: A list of colors that defines the gradient.
/// * `begin`: The starting point of the gradient.
/// * `end`: The ending point of the gradient.
  GradientColor  gradientColor = GradientColor();

  // The default radius if nothing is specified.
  static const double _defaultRadius = 20.0;

  // The default min if only the max is specified.
  static const double _defaultMinRadius = 0.0;

  // The default max if only the min is specified.
  static const double _defaultMaxRadius = double.infinity;

  double get _minDiameter {
    if (radius == null && minRadius == null && maxRadius == null) {
      return _defaultRadius * 2.0;
    }
    return 2.0 * (radius ?? minRadius ?? _defaultMinRadius);
  }

  double get _maxDiameter {
    if (radius == null && minRadius == null && maxRadius == null) {
      return _defaultRadius * 2.0;
    }
    return 2.0 * (radius ?? maxRadius ?? _defaultMaxRadius);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final ThemeData theme = Theme.of(context);
    final Color? effectiveForegroundColor = foregroundColor ?? (theme.useMaterial3 ? theme.colorScheme.onPrimaryContainer : null);
    final TextStyle effectiveTextStyle = theme.useMaterial3 ? theme.textTheme.titleMedium! : theme.primaryTextTheme.titleMedium!;
    TextStyle textStyle = effectiveTextStyle.copyWith(color: effectiveForegroundColor);
    Color? effectiveBackgroundColor = backgroundColor ?? (theme.useMaterial3 ? theme.colorScheme.primaryContainer : null);
    if (effectiveBackgroundColor == null) {
      effectiveBackgroundColor = switch (ThemeData.estimateBrightnessForColor(textStyle.color!)) {
        Brightness.dark => theme.primaryColorLight,
        Brightness.light => theme.primaryColorDark,
      };
    } else if (effectiveForegroundColor == null) {
      textStyle = switch (ThemeData.estimateBrightnessForColor(backgroundColor!)) {
        Brightness.dark => textStyle.copyWith(color: theme.primaryColorLight),
        Brightness.light => textStyle.copyWith(color: theme.primaryColorDark),
      };
    }
    final double minDiameter = _minDiameter;
    final double maxDiameter = _maxDiameter;
    return CustomPaint(
      painter: GradientCirclePainter(
        gradientColors: gradientColor.gradientColors,
        withBorder: gradientColor.withBorder,

      ),
      child: AnimatedContainer(
        constraints: BoxConstraints(
          minHeight: minDiameter,
          minWidth: minDiameter,
          maxWidth: maxDiameter,
          maxHeight: maxDiameter,
        ),
        duration: kThemeChangeDuration,
        decoration: BoxDecoration(
          border: Border.all(color: border!.color, width: border!.width, style: border!.style, strokeAlign: border!.strokeAlign),
          color: effectiveBackgroundColor,
          image: backgroundImage != null
              ? DecorationImage(
                  image: backgroundImage!,
                  onError: onBackgroundImageError,
                  fit: BoxFit.cover,
                )
              : null,
          shape: BoxShape.circle,
        ),
        foregroundDecoration: foregroundImage != null
            ? BoxDecoration(
                image: DecorationImage(
                  image: foregroundImage!,
                  onError: onForegroundImageError,
                  fit: BoxFit.cover,
                ),
                shape: BoxShape.circle,
              )
            : null,
        child: child == null
            ? null
            : Center(
                // Need to disable text scaling here so that the text doesn't
                // escape the avatar when the textScaleFactor is large.
                child: MediaQuery.withNoTextScaling(
                  child: IconTheme(
                    data: theme.iconTheme.copyWith(color: textStyle.color),
                    child: DefaultTextStyle(
                      style: textStyle,
                      child: child!,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// A class representing a border with customizable color, width, style, and stroke alignment.
///
/// This class allows you to define a border with the following properties:
///
/// * `color`: The color of the border. Defaults to black.
/// * `width`: The width of the border in logical pixels. Defaults to 1.0.
/// * `style`: The style of the border (e.g., solid, dashed). Defaults to solid.
/// * `strokeAlign`: The position of the stroke relative to the border's edge.
///   Defaults to [BorderSide.strokeAlignInside].
///
/// Example usage:
///
/// ```dart
/// Borders border = Borders(
///   color: Colors.red,
///   width: 2.0,
///   style: BorderStyle.solid,
///   strokeAlign: BorderSide.strokeAlignCenter,
/// );
/// ```
///
/// This can be used for customizable borders in widgets such as [Container],
/// [BoxDecoration], or any widget that supports border styling.
class Borders {
  /// Creates a new Borders instance with the given parameters.
  ///
  /// The default values are:
  ///
  /// * `color`: Black (`Color(0xFF000000)`).
  /// * `width`: 1.0 logical pixels.
  /// * `style`: [BorderStyle.solid].
  /// * `strokeAlign`: [BorderSide.strokeAlignInside].
  Borders({
    this.color = const Color(0xFF000000),
    this.width = 1.0,
    this.style = BorderStyle.solid,
    this.strokeAlign = BorderSide.strokeAlignInside,
  });

  /// The color of the border.
  ///
  /// Defaults to black (`Color(0xFF000000)`).
  final Color color;

  /// The width of the border in logical pixels.
  ///
  /// Defaults to 1.0.
  final double width;

  /// The style of the border.
  ///
  /// Can be [BorderStyle.solid] (default) or [BorderStyle.none].
  final BorderStyle style;

  /// The position of the stroke relative to the border's edge.
  ///
  /// Defaults to [BorderSide.strokeAlignInside], meaning the stroke is
  /// fully drawn inside the border's bounds. Other possible values include
  /// [BorderSide.strokeAlignCenter] and [BorderSide.strokeAlignOutside].
  final double strokeAlign;
}

/// A custom painter that draws a circular gradient with an optional border.
///
/// The [GradientCirclePainter] class is used to create a circular gradient effect,
/// with an optional border that can be customized using the provided properties.
///
/// ### Parameters:
///
/// * `gradientColors`: An optional [Gradient] that defines the colors for the gradient.
///   If `null`, the default gradient colors are [Colors.blue] and [Colors.green].
///
/// * `withBorder`: A [double] that specifies the width of the border. The default
///   behavior will apply the provided width to the stroke of the circle.
///
/// ### Example Usage:
///
/// ```dart
/// GradientCirclePainter(
///   gradientColors: LinearGradient(
///     colors: [Colors.red, Colors.orange],
///   ),
///   withBorder: 4.0,
/// );
/// ```
///
/// In this example, a circular gradient is drawn with the colors red and orange, and
/// the border is applied with a stroke width of 4.0.
///
/// ### Drawing Mechanism:
///
/// The painter draws a circular gradient with the center point located in the middle
/// of the widget (`Offset`), and it uses the provided or default gradient colors to
/// fill the circle. The stroke width for the border is determined by the `withBorder`
/// parameter.
///
/// The `paint()` method utilizes the [Canvas.drawArc] method to create the circular
/// shape and fill it with the gradient.
///
/// ### Methods:
///
/// * `paint`: This method is responsible for rendering the gradient circle on the provided
///   canvas with the size passed by the widget.
///
/// * `shouldRepaint`: Returns `false` since no dynamic properties are present that require
///   the circle to be redrawn.
class GradientCirclePainter extends CustomPainter {
  /// Creates a [GradientCirclePainter].
  ///
  /// The [gradientColors] parameter defines the colors of the gradient. If `null`, a default
  /// gradient of blue and green will be used.
  ///
  /// The [withBorder] parameter defines the width of the border.
  GradientCirclePainter({
    this.gradientColors,
    required this.withBorder,
  });

  /// The gradient colors for the circular shape.
  ///
  /// If not provided, the gradient will default to a blue and green combination.
  final Gradient? gradientColors;

  /// The width of the border.
  ///
  /// This specifies the stroke width of the border around the gradient circle.
  final double withBorder;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    const double startAngle = -pi / 2;
    const double sweepAngle = 2 * pi;

    final List<Color> colors = gradientColors?.colors ?? <Color>[Colors.blue, Colors.green];

    final SweepGradient gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: colors,
    );

    final Rect rect = Rect.fromCircle(center: center, radius: size.width / 2);

    final Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = withBorder;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class GradientColor {
  /// Creates a [GradientColor].
  GradientColor({this.gradientColors = const LinearGradient(colors: <Color>[Colors.blue, Colors.green]),  this.withBorder = 1.0});

  /// The gradient colors for the circular shape.
  ///
  /// If not provided, the gradient will default to a blue and green combination.
  final Gradient gradientColors;

  /// The width of the border.
  ///
  /// This specifies the stroke width of the border around the gradient circle.
  final double withBorder;
}

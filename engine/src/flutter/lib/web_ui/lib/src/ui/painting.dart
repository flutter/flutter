// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of ui;

// ignore: unused_element, Used in Shader assert.
bool _offsetIsValid(Offset offset) {
  assert(offset != null,
      'Offset argument was null.'); // ignore: unnecessary_null_comparison
  assert(!offset.dx.isNaN && !offset.dy.isNaN,
      'Offset argument contained a NaN value.');
  return true;
}

// ignore: unused_element, Used in Shader assert.
bool _matrix4IsValid(Float32List matrix4) {
  assert(matrix4 != null,
      'Matrix4 argument was null.'); // ignore: unnecessary_null_comparison
  assert(matrix4.length == 16, 'Matrix4 must have 16 entries.');
  return true;
}

void _validateColorStops(List<Color> colors, List<double>? colorStops) {
  if (colorStops == null) {
    if (colors.length != 2)
      throw ArgumentError(
          '"colors" must have length 2 if "colorStops" is omitted.');
  } else {
    if (colors.length != colorStops.length)
      throw ArgumentError(
          '"colors" and "colorStops" arguments must have equal length.');
  }
}

Color _scaleAlpha(Color a, double factor) {
  return a.withAlpha(_clampInt((a.alpha * factor).round(), 0, 255));
}

/// An immutable 32 bit color value in ARGB
class Color {
  /// Construct a color from the lower 32 bits of an int.
  ///
  /// Bits 24-31 are the alpha value.
  /// Bits 16-23 are the red value.
  /// Bits 8-15 are the green value.
  /// Bits 0-7 are the blue value.
  const Color(int value) : this.value = value & 0xFFFFFFFF;

  /// Construct a color from the lower 8 bits of four integers.
  const Color.fromARGB(int a, int r, int g, int b)
      : value = (((a & 0xff) << 24) |
                ((r & 0xff) << 16) |
                ((g & 0xff) << 8) |
                ((b & 0xff) << 0)) &
            0xFFFFFFFF;

  /// Create a color from red, green, blue, and opacity, similar to `rgba()` in CSS.
  ///
  /// * `r` is [red], from 0 to 255.
  /// * `g` is [green], from 0 to 255.
  /// * `b` is [blue], from 0 to 255.
  /// * `opacity` is alpha channel of this color as a double, with 0.0 being
  ///   transparent and 1.0 being fully opaque.
  ///
  /// Out of range values are brought into range using modulo 255.
  ///
  /// See also [fromARGB], which takes the opacity as an integer value.
  const Color.fromRGBO(int r, int g, int b, double opacity)
      : value = ((((opacity * 0xff ~/ 1) & 0xff) << 24) |
                ((r & 0xff) << 16) |
                ((g & 0xff) << 8) |
                ((b & 0xff) << 0)) &
            0xFFFFFFFF;

  /// A 32 bit value representing this color.
  ///
  /// Bits 24-31 are the alpha value.
  /// Bits 16-23 are the red value.
  /// Bits 8-15 are the green value.
  /// Bits 0-7 are the blue value.
  final int value;

  /// The alpha channel of this color in an 8 bit value.
  int get alpha => (0xff000000 & value) >> 24;

  /// The alpha channel of this color as a double.
  double get opacity => alpha / 0xFF;

  /// The red channel of this color in an 8 bit value.
  int get red => (0x00ff0000 & value) >> 16;

  /// The green channel of this color in an 8 bit value.
  int get green => (0x0000ff00 & value) >> 8;

  /// The blue channel of this color in an 8 bit value.
  int get blue => (0x000000ff & value) >> 0;

  /// Returns a new color that matches this color with the alpha channel
  /// replaced with a (which ranges from 0 to 255).
  Color withAlpha(int a) {
    return Color.fromARGB(a, red, green, blue);
  }

  /// Returns a new color that matches this color with the alpha channel
  /// replaced with the given opacity (which ranges from 0.0 to 1.0).
  Color withOpacity(double opacity) {
    assert(opacity >= 0.0 && opacity <= 1.0);
    return withAlpha((255.0 * opacity).round());
  }

  /// Returns a new color that matches this color with the red channel replaced
  /// with r.
  Color withRed(int r) {
    return Color.fromARGB(alpha, r, green, blue);
  }

  /// Returns a new color that matches this color with the green channel
  /// replaced with g.
  Color withGreen(int g) {
    return Color.fromARGB(alpha, red, g, blue);
  }

  /// Returns a new color that matches this color with the blue channel replaced
  /// with b.
  Color withBlue(int b) {
    return Color.fromARGB(alpha, red, green, b);
  }

  // See <https://www.w3.org/TR/WCAG20/#relativeluminancedef>
  static double _linearizeColorComponent(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    }
    return math.pow((component + 0.055) / 1.055, 2.4) as double;
  }

  /// Returns a brightness value between 0 for darkest and 1 for lightest.
  ///
  /// Represents the relative luminance of the color. This value is
  /// computationally expensive to calculate.
  ///
  /// See <https://en.wikipedia.org/wiki/Relative_luminance>.
  double computeLuminance() {
    // See <https://www.w3.org/TR/WCAG20/#relativeluminancedef>
    final double R = _linearizeColorComponent(red / 0xFF);
    final double G = _linearizeColorComponent(green / 0xFF);
    final double B = _linearizeColorComponent(blue / 0xFF);
    return 0.2126 * R + 0.7152 * G + 0.0722 * B;
  }

  /// Linearly interpolate between two colors.
  ///
  /// This is intended to be fast but as a result may be ugly. Consider
  /// [HSVColor] or writing custom logic for interpolating colors.
  ///
  /// If either color is null, this function linearly interpolates from a
  /// transparent instance of the other color. This is usually preferable to
  /// interpolating from [material.Colors.transparent] (`const
  /// Color(0x00000000)`), which is specifically transparent _black_.
  ///
  /// The `t` argument represents position on the timeline, with 0.0 meaning
  /// that the interpolation has not started, returning `a` (or something
  /// equivalent to `a`), 1.0 meaning that the interpolation has finished,
  /// returning `b` (or something equivalent to `b`), and values in between
  /// meaning that the interpolation is at the relevant point on the timeline
  /// between `a` and `b`. The interpolation can be extrapolated beyond 0.0 and
  /// 1.0, so negative values and values greater than 1.0 are valid (and can
  /// easily be generated by curves such as [Curves.elasticInOut]). Each channel
  /// will be clamped to the range 0 to 255.
  ///
  /// Values for `t` are usually obtained from an [Animation<double>], such as
  /// an [AnimationController].
  static Color? lerp(Color? a, Color? b, double t) {
    assert(t != null); // ignore: unnecessary_null_comparison
    if (b == null) {
      if (a == null) {
        return null;
      } else {
        return _scaleAlpha(a, 1.0 - t);
      }
    } else {
      if (a == null) {
        return _scaleAlpha(b, t);
      } else {
        return Color.fromARGB(
          _clampInt(_lerpInt(a.alpha, b.alpha, t).toInt(), 0, 255),
          _clampInt(_lerpInt(a.red, b.red, t).toInt(), 0, 255),
          _clampInt(_lerpInt(a.green, b.green, t).toInt(), 0, 255),
          _clampInt(_lerpInt(a.blue, b.blue, t).toInt(), 0, 255),
        );
      }
    }
  }

  /// Combine the foreground color as a transparent color over top
  /// of a background color, and return the resulting combined color.
  ///
  /// This uses standard alpha blending ("SRC over DST") rules to produce a
  /// blended color from two colors. This can be used as a performance
  /// enhancement when trying to avoid needless alpha blending compositing
  /// operations for two things that are solid colors with the same shape, but
  /// overlay each other: instead, just paint one with the combined color.
  static Color alphaBlend(Color foreground, Color background) {
    final int alpha = foreground.alpha;
    if (alpha == 0x00) {
      // Foreground completely transparent.
      return background;
    }
    final int invAlpha = 0xff - alpha;
    int backAlpha = background.alpha;
    if (backAlpha == 0xff) {
      // Opaque background case
      return Color.fromARGB(
        0xff,
        (alpha * foreground.red + invAlpha * background.red) ~/ 0xff,
        (alpha * foreground.green + invAlpha * background.green) ~/ 0xff,
        (alpha * foreground.blue + invAlpha * background.blue) ~/ 0xff,
      );
    } else {
      // General case
      backAlpha = (backAlpha * invAlpha) ~/ 0xff;
      final int outAlpha = alpha + backAlpha;
      assert(outAlpha != 0x00);
      return Color.fromARGB(
        outAlpha,
        (foreground.red * alpha + background.red * backAlpha) ~/ outAlpha,
        (foreground.green * alpha + background.green * backAlpha) ~/ outAlpha,
        (foreground.blue * alpha + background.blue * backAlpha) ~/ outAlpha,
      );
    }
  }

  /// Returns an alpha value representative of the provided [opacity] value.
  ///
  /// The [opacity] value may not be null.
  static int getAlphaFromOpacity(double opacity) {
    assert(opacity != null); // ignore: unnecessary_null_comparison
    return (opacity.clamp(0.0, 1.0) * 255).round();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is Color && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() {
    return 'Color(0x${value.toRadixString(16).padLeft(8, '0')})';
  }
}

/// Styles to use for line endings.
///
/// See [Paint.strokeCap].
enum StrokeCap {
  /// Begin and end contours with a flat edge and no extension.
  butt,

  /// Begin and end contours with a semi-circle extension.
  round,

  /// Begin and end contours with a half square extension. This is
  /// similar to extending each contour by half the stroke width (as
  /// given by [Paint.strokeWidth]).
  square,
}

/// Styles to use for line segment joins.
///
/// This only affects line joins for polygons drawn by [Canvas.drawPath] and
/// rectangles, not points drawn as lines with [Canvas.drawPoints].
///
/// See also:
///
/// * [Paint.strokeJoin] and [Paint.strokeMiterLimit] for how this value is
///   used.
/// * [StrokeCap] for the different kinds of line endings.
// These enum values must be kept in sync with SkPaint::Join.
enum StrokeJoin {
  /// Joins between line segments form sharp corners.
  ///
  /// {@animation 300 300 https://flutter.github.io/assets-for-api-docs/assets/dart-ui/miter_4_join.mp4}
  ///
  /// The center of the line segment is colored in the diagram above to
  /// highlight the join, but in normal usage the join is the same color as the
  /// line.
  ///
  /// See also:
  ///
  ///   * [Paint.strokeJoin], used to set the line segment join style to this
  ///     value.
  ///   * [Paint.strokeMiterLimit], used to define when a miter is drawn instead
  ///     of a bevel when the join is set to this value.
  miter,

  /// Joins between line segments are semi-circular.
  ///
  /// {@animation 300 300 https://flutter.github.io/assets-for-api-docs/assets/dart-ui/round_join.mp4}
  ///
  /// The center of the line segment is colored in the diagram above to
  /// highlight the join, but in normal usage the join is the same color as the
  /// line.
  ///
  /// See also:
  ///
  ///   * [Paint.strokeJoin], used to set the line segment join style to this
  ///     value.
  round,

  /// Joins between line segments connect the corners of the butt ends of the
  /// line segments to give a beveled appearance.
  ///
  /// {@animation 300 300 https://flutter.github.io/assets-for-api-docs/assets/dart-ui/bevel_join.mp4}
  ///
  /// The center of the line segment is colored in the diagram above to
  /// highlight the join, but in normal usage the join is the same color as the
  /// line.
  ///
  /// See also:
  ///
  ///   * [Paint.strokeJoin], used to set the line segment join style to this
  ///     value.
  bevel,
}

/// Strategies for painting shapes and paths on a canvas.
///
/// See [Paint.style].
enum PaintingStyle {
  /// Apply the [Paint] to the inside of the shape. For example, when
  /// applied to the [Paint.drawCircle] call, this results in a disc
  /// of the given size being painted.
  fill,

  /// Apply the [Paint] to the edge of the shape. For example, when
  /// applied to the [Paint.drawCircle] call, this results is a hoop
  /// of the given size being painted. The line drawn on the edge will
  /// be the width given by the [Paint.strokeWidth] property.
  stroke,
}

/// Algorithms to use when painting on the canvas.
///
/// When drawing a shape or image onto a canvas, different algorithms can be
/// used to blend the pixels. The different values of [BlendMode] specify
/// different such algorithms.
///
/// Each algorithm has two inputs, the _source_, which is the image being drawn,
/// and the _destination_, which is the image into which the source image is
/// being composited. The destination is often thought of as the _background_.
/// The source and destination both have four color channels, the red, green,
/// blue, and alpha channels. These are typically represented as numbers in the
/// range 0.0 to 1.0. The output of the algorithm also has these same four
/// channels, with values computed from the source and destination.
///
/// The documentation of each value below describes how the algorithm works. In
/// each case, an image shows the output of blending a source image with a
/// destination image. In the images below, the destination is represented by an
/// image with horizontal lines and an opaque landscape photograph, and the
/// source is represented by an image with vertical lines (the same lines but
/// rotated) and a bird clip-art image. The [src] mode shows only the source
/// image, and the [dst] mode shows only the destination image. In the
/// documentation below, the transparency is illustrated by a checkerboard
/// pattern. The [clear] mode drops both the source and destination, resulting
/// in an output that is entirely transparent (illustrated by a solid
/// checkerboard pattern).
///
/// The horizontal and vertical bars in these images show the red, green, and
/// blue channels with varying opacity levels, then all three color channels
/// together with those same varying opacity levels, then all three color
/// channels set to zero with those varying opacity levels, then two bars
/// showing a red/green/blue repeating gradient, the first with full opacity and
/// the second with partial opacity, and finally a bar with the three color
/// channels set to zero but the opacity varying in a repeating gradient.
///
/// ## Application to the [Canvas] API
///
/// When using [Canvas.saveLayer] and [Canvas.restore], the blend mode of the
/// [Paint] given to the [Canvas.saveLayer] will be applied when
/// [Canvas.restore] is called. Each call to [Canvas.saveLayer] introduces a new
/// layer onto which shapes and images are painted; when [Canvas.restore] is
/// called, that layer is then composited onto the parent layer, with the source
/// being the most-recently-drawn shapes and images, and the destination being
/// the parent layer. (For the first [Canvas.saveLayer] call, the parent layer
/// is the canvas itself.)
///
/// See also:
///
///  * [Paint.blendMode], which uses [BlendMode] to define the compositing
///    strategy.
enum BlendMode {
  // This list comes from Skia's SkXfermode.h and the values (order) should be
  // kept in sync.
  // See: https://skia.org/user/api/skpaint#SkXfermode

  /// Drop both the source and destination images, leaving nothing.
  ///
  /// This corresponds to the "clear" Porter-Duff operator.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_clear.png)
  clear,

  /// Drop the destination image, only paint the source image.
  ///
  /// Conceptually, the destination is first cleared, then the source image is
  /// painted.
  ///
  /// This corresponds to the "Copy" Porter-Duff operator.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_src.png)
  src,

  /// Drop the source image, only paint the destination image.
  ///
  /// Conceptually, the source image is discarded, leaving the destination
  /// untouched.
  ///
  /// This corresponds to the "Destination" Porter-Duff operator.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_dst.png)
  dst,

  /// Composite the source image over the destination image.
  ///
  /// This is the default value. It represents the most intuitive case, where
  /// shapes are painted on top of what is below, with transparent areas showing
  /// the destination layer.
  ///
  /// This corresponds to the "Source over Destination" Porter-Duff operator,
  /// also known as the Painter's Algorithm.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_srcOver.png)
  srcOver,

  /// Composite the source image under the destination image.
  ///
  /// This is the opposite of [srcOver].
  ///
  /// This corresponds to the "Destination over Source" Porter-Duff operator.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_dstOver.png)
  ///
  /// This is useful when the source image should have been painted before the
  /// destination image, but could not be.
  dstOver,

  /// Show the source image, but only where the two images overlap. The
  /// destination image is not rendered, it is treated merely as a mask. The
  /// color channels of the destination are ignored, only the opacity has an
  /// effect.
  ///
  /// To show the destination image instead, consider [dstIn].
  ///
  /// To reverse the semantic of the mask (only showing the source where the
  /// destination is absent, rather than where it is present), consider
  /// [srcOut].
  ///
  /// This corresponds to the "Source in Destination" Porter-Duff operator.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_srcIn.png)
  srcIn,

  /// Show the destination image, but only where the two images overlap. The
  /// source image is not rendered, it is treated merely as a mask. The color
  /// channels of the source are ignored, only the opacity has an effect.
  ///
  /// To show the source image instead, consider [srcIn].
  ///
  /// To reverse the semantic of the mask (only showing the source where the
  /// destination is present, rather than where it is absent), consider
  /// [dstOut].
  ///
  /// This corresponds to the "Destination in Source" Porter-Duff operator.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_dstIn.png)
  dstIn,

  /// Show the source image, but only where the two images do not overlap. The
  /// destination image is not rendered, it is treated merely as a mask. The color
  /// channels of the destination are ignored, only the opacity has an effect.
  ///
  /// To show the destination image instead, consider [dstOut].
  ///
  /// To reverse the semantic of the mask (only showing the source where the
  /// destination is present, rather than where it is absent), consider [srcIn].
  ///
  /// This corresponds to the "Source out Destination" Porter-Duff operator.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_srcOut.png)
  srcOut,

  /// Show the destination image, but only where the two images do not overlap.
  /// The source image is not rendered, it is treated merely as a mask. The
  /// color channels of the source are ignored, only the opacity has an effect.
  ///
  /// To show the source image instead, consider [srcOut].
  ///
  /// To reverse the semantic of the mask (only showing the destination where
  /// the source is present, rather than where it is absent), consider [dstIn].
  ///
  /// This corresponds to the "Destination out Source" Porter-Duff operator.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_dstOut.png)
  dstOut,

  /// Composite the source image over the destination image, but only where it
  /// overlaps the destination.
  ///
  /// This corresponds to the "Source atop Destination" Porter-Duff operator.
  ///
  /// This is essentially the [srcOver] operator, but with the output's opacity
  /// channel being set to that of the destination image instead of being a
  /// combination of both image's opacity channels.
  ///
  /// For a variant with the destination on top instead of the source, see
  /// [dstATop].
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_srcATop.png)
  srcATop,

  /// Composite the destination image over the source image, but only where it
  /// overlaps the source.
  ///
  /// This corresponds to the "Destination atop Source" Porter-Duff operator.
  ///
  /// This is essentially the [dstOver] operator, but with the output's opacity
  /// channel being set to that of the source image instead of being a
  /// combination of both image's opacity channels.
  ///
  /// For a variant with the source on top instead of the destination, see
  /// [srcATop].
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_dstATop.png)
  dstATop,

  /// Apply a bitwise `xor` operator to the source and destination images. This
  /// leaves transparency where they would overlap.
  ///
  /// This corresponds to the "Source xor Destination" Porter-Duff operator.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_xor.png)
  xor,

  /// Sum the components of the source and destination images.
  ///
  /// Transparency in a pixel of one of the images reduces the contribution of
  /// that image to the corresponding output pixel, as if the color of that
  /// pixel in that image was darker.
  ///
  /// This corresponds to the "Source plus Destination" Porter-Duff operator.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_plus.png)
  plus,

  /// Multiply the color components of the source and destination images.
  ///
  /// This can only result in the same or darker colors (multiplying by white,
  /// 1.0, results in no change; multiplying by black, 0.0, results in black).
  ///
  /// When compositing two opaque images, this has similar effect to overlapping
  /// two transparencies on a projector.
  ///
  /// For a variant that also multiplies the alpha channel, consider [multiply].
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_modulate.png)
  ///
  /// See also:
  ///
  ///  * [screen], which does a similar computation but inverted.
  ///  * [overlay], which combines [modulate] and [screen] to favor the
  ///    destination image.
  ///  * [hardLight], which combines [modulate] and [screen] to favor the
  ///    source image.
  modulate,

  // Following blend modes are defined in the CSS Compositing standard.

  /// Multiply the inverse of the components of the source and destination
  /// images, and inverse the result.
  ///
  /// Inverting the components means that a fully saturated channel (opaque
  /// white) is treated as the value 0.0, and values normally treated as 0.0
  /// (black, transparent) are treated as 1.0.
  ///
  /// This is essentially the same as [modulate] blend mode, but with the values
  /// of the colors inverted before the multiplication and the result being
  /// inverted back before rendering.
  ///
  /// This can only result in the same or lighter colors (multiplying by black,
  /// 1.0, results in no change; multiplying by white, 0.0, results in white).
  /// Similarly, in the alpha channel, it can only result in more opaque colors.
  ///
  /// This has similar effect to two projectors displaying their images on the
  /// same screen simultaneously.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_screen.png)
  ///
  /// See also:
  ///
  ///  * [modulate], which does a similar computation but without inverting the
  ///    values.
  ///  * [overlay], which combines [modulate] and [screen] to favor the
  ///    destination image.
  ///  * [hardLight], which combines [modulate] and [screen] to favor the
  ///    source image.
  screen, // The last coeff mode.

  /// Multiply the components of the source and destination images after
  /// adjusting them to favor the destination.
  ///
  /// Specifically, if the destination value is smaller, this multiplies it with
  /// the source value, whereas is the source value is smaller, it multiplies
  /// the inverse of the source value with the inverse of the destination value,
  /// then inverts the result.
  ///
  /// Inverting the components means that a fully saturated channel (opaque
  /// white) is treated as the value 0.0, and values normally treated as 0.0
  /// (black, transparent) are treated as 1.0.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_overlay.png)
  ///
  /// See also:
  ///
  ///  * [modulate], which always multiplies the values.
  ///  * [screen], which always multiplies the inverses of the values.
  ///  * [hardLight], which is similar to [overlay] but favors the source image
  ///    instead of the destination image.
  overlay,

  /// Composite the source and destination image by choosing the lowest value
  /// from each color channel.
  ///
  /// The opacity of the output image is computed in the same way as for
  /// [srcOver].
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_darken.png)
  darken,

  /// Composite the source and destination image by choosing the highest value
  /// from each color channel.
  ///
  /// The opacity of the output image is computed in the same way as for
  /// [srcOver].
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_lighten.png)
  lighten,

  /// Divide the destination by the inverse of the source.
  ///
  /// Inverting the components means that a fully saturated channel (opaque
  /// white) is treated as the value 0.0, and values normally treated as 0.0
  /// (black, transparent) are treated as 1.0.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_colorDodge.png)
  colorDodge,

  /// Divide the inverse of the destination by the source, and inverse the result.
  ///
  /// Inverting the components means that a fully saturated channel (opaque
  /// white) is treated as the value 0.0, and values normally treated as 0.0
  /// (black, transparent) are treated as 1.0.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_colorBurn.png)
  colorBurn,

  /// Multiply the components of the source and destination images after
  /// adjusting them to favor the source.
  ///
  /// Specifically, if the source value is smaller, this multiplies it with the
  /// destination value, whereas is the destination value is smaller, it
  /// multiplies the inverse of the destination value with the inverse of the
  /// source value, then inverts the result.
  ///
  /// Inverting the components means that a fully saturated channel (opaque
  /// white) is treated as the value 0.0, and values normally treated as 0.0
  /// (black, transparent) are treated as 1.0.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_hardLight.png)
  ///
  /// See also:
  ///
  ///  * [modulate], which always multiplies the values.
  ///  * [screen], which always multiplies the inverses of the values.
  ///  * [overlay], which is similar to [hardLight] but favors the destination
  ///    image instead of the source image.
  hardLight,

  /// Use [colorDodge] for source values below 0.5 and [colorBurn] for source
  /// values above 0.5.
  ///
  /// This results in a similar but softer effect than [overlay].
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_softLight.png)
  ///
  /// See also:
  ///
  ///  * [color], which is a more subtle tinting effect.
  softLight,

  /// Subtract the smaller value from the bigger value for each channel.
  ///
  /// Compositing black has no effect; compositing white inverts the colors of
  /// the other image.
  ///
  /// The opacity of the output image is computed in the same way as for
  /// [srcOver].
  ///
  /// The effect is similar to [exclusion] but harsher.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_difference.png)
  difference,

  /// Subtract double the product of the two images from the sum of the two
  /// images.
  ///
  /// Compositing black has no effect; compositing white inverts the colors of
  /// the other image.
  ///
  /// The opacity of the output image is computed in the same way as for
  /// [srcOver].
  ///
  /// The effect is similar to [difference] but softer.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_exclusion.png)
  exclusion,

  /// Multiply the components of the source and destination images, including
  /// the alpha channel.
  ///
  /// This can only result in the same or darker colors (multiplying by white,
  /// 1.0, results in no change; multiplying by black, 0.0, results in black).
  ///
  /// Since the alpha channel is also multiplied, a fully-transparent pixel
  /// (opacity 0.0) in one image results in a fully transparent pixel in the
  /// output. This is similar to [dstIn], but with the colors combined.
  ///
  /// For a variant that multiplies the colors but does not multiply the alpha
  /// channel, consider [modulate].
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_multiply.png)
  multiply, // The last separable mode.

  /// Take the hue of the source image, and the saturation and luminosity of the
  /// destination image.
  ///
  /// The effect is to tint the destination image with the source image.
  ///
  /// The opacity of the output image is computed in the same way as for
  /// [srcOver]. Regions that are entirely transparent in the source image take
  /// their hue from the destination.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_hue.png)
  ///
  /// See also:
  ///
  ///  * [color], which is a similar but stronger effect as it also applies the
  ///    saturation of the source image.
  ///  * [HSVColor], which allows colors to be expressed using Hue rather than
  ///    the red/green/blue channels of [Color].
  hue,

  /// Take the saturation of the source image, and the hue and luminosity of the
  /// destination image.
  ///
  /// The opacity of the output image is computed in the same way as for
  /// [srcOver]. Regions that are entirely transparent in the source image take
  /// their saturation from the destination.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_hue.png)
  ///
  /// See also:
  ///
  ///  * [color], which also applies the hue of the source image.
  ///  * [luminosity], which applies the luminosity of the source image to the
  ///    destination.
  saturation,

  /// Take the hue and saturation of the source image, and the luminosity of the
  /// destination image.
  ///
  /// The effect is to tint the destination image with the source image.
  ///
  /// The opacity of the output image is computed in the same way as for
  /// [srcOver]. Regions that are entirely transparent in the source image take
  /// their hue and saturation from the destination.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_color.png)
  ///
  /// See also:
  ///
  ///  * [hue], which is a similar but weaker effect.
  ///  * [softLight], which is a similar tinting effect but also tints white.
  ///  * [saturation], which only applies the saturation of the source image.
  color,

  /// Take the luminosity of the source image, and the hue and saturation of the
  /// destination image.
  ///
  /// The opacity of the output image is computed in the same way as for
  /// [srcOver]. Regions that are entirely transparent in the source image take
  /// their luminosity from the destination.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_luminosity.png)
  ///
  /// See also:
  ///
  ///  * [saturation], which applies the saturation of the source image to the
  ///    destination.
  ///  * [ImageFilter.blur], which can be used with [BackdropFilter] for a
  ///    related effect.
  luminosity,
}

/// Different ways to clip a widget's content.
enum Clip {
  /// No clip at all.
  ///
  /// This is the default option for most widgets: if the content does not
  /// overflow the widget boundary, don't pay any performance cost for clipping.
  ///
  /// If the content does overflow, please explicitly specify the following
  /// [Clip] options:
  ///  * [hardEdge], which is the fastest clipping, but with lower fidelity.
  ///  * [antiAlias], which is a little slower than [hardEdge], but with smoothed edges.
  ///  * [antiAliasWithSaveLayer], which is much slower than [antiAlias], and should
  ///    rarely be used.
  none,

  /// Clip, but do not apply anti-aliasing.
  ///
  /// This mode enables clipping, but curves and non-axis-aligned straight lines will be
  /// jagged as no effort is made to anti-alias.
  ///
  /// Faster than other clipping modes, but slower than [none].
  ///
  /// This is a reasonable choice when clipping is needed, if the container is an axis-
  /// aligned rectangle or an axis-aligned rounded rectangle with very small corner radii.
  ///
  /// See also:
  ///
  ///  * [antiAlias], which is more reasonable when clipping is needed and the shape is not
  ///    an axis-aligned rectangle.
  hardEdge,

  /// Clip with anti-aliasing.
  ///
  /// This mode has anti-aliased clipping edges to achieve a smoother look.
  ///
  /// It' s much faster than [antiAliasWithSaveLayer], but slower than [hardEdge].
  ///
  /// This will be the common case when dealing with circles and arcs.
  ///
  /// Different from [hardEdge] and [antiAliasWithSaveLayer], this clipping may have
  /// bleeding edge artifacts.
  /// (See https://fiddle.skia.org/c/21cb4c2b2515996b537f36e7819288ae for an example.)
  ///
  /// See also:
  ///
  ///  * [hardEdge], which is a little faster, but with lower fidelity.
  ///  * [antiAliasWithSaveLayer], which is much slower, but can avoid the
  ///    bleeding edges if there's no other way.
  ///  * [Paint.isAntiAlias], which is the anti-aliasing switch for general draw operations.
  antiAlias,

  /// Clip with anti-aliasing and saveLayer immediately following the clip.
  ///
  /// This mode not only clips with anti-aliasing, but also allocates an offscreen
  /// buffer. All subsequent paints are carried out on that buffer before finally
  /// being clipped and composited back.
  ///
  /// This is very slow. It has no bleeding edge artifacts (that [antiAlias] has)
  /// but it changes the semantics as an offscreen buffer is now introduced.
  /// (See https://github.com/flutter/flutter/issues/18057#issuecomment-394197336
  /// for a difference between paint without saveLayer and paint with saveLayer.)
  ///
  /// This will be only rarely needed. One case where you might need this is if
  /// you have an image overlaid on a very different background color. In these
  /// cases, consider whether you can avoid overlaying multiple colors in one
  /// spot (e.g. by having the background color only present where the image is
  /// absent). If you can, [antiAlias] would be fine and much faster.
  ///
  /// See also:
  ///
  ///  * [antiAlias], which is much faster, and has similar clipping results.
  antiAliasWithSaveLayer,
}

/// A description of the style to use when drawing on a [Canvas].
///
/// Most APIs on [Canvas] take a [Paint] object to describe the style
/// to use for that operation.
abstract class Paint {
  /// Constructs an empty [Paint] object with all fields initialized to
  /// their defaults.
  factory Paint() =>
      engine.experimentalUseSkia ? engine.CkPaint() : engine.SurfacePaint();

  /// Whether to dither the output when drawing images.
  ///
  /// If false, the default value, dithering will be enabled when the input
  /// color depth is higher than the output color depth. For example,
  /// drawing an RGB8 image onto an RGB565 canvas.
  ///
  /// This value also controls dithering of [shader]s, which can make
  /// gradients appear smoother.
  ///
  /// Whether or not dithering affects the output is implementation defined.
  /// Some implementations may choose to ignore this completely, if they're
  /// unable to control dithering.
  ///
  /// To ensure that dithering is consistently enabled for your entire
  /// application, set this to true before invoking any drawing related code.
  static bool enableDithering = false;

  /// A blend mode to apply when a shape is drawn or a layer is composited.
  ///
  /// The source colors are from the shape being drawn (e.g. from
  /// [Canvas.drawPath]) or layer being composited (the graphics that were drawn
  /// between the [Canvas.saveLayer] and [Canvas.restore] calls), after applying
  /// the [colorFilter], if any.
  ///
  /// The destination colors are from the background onto which the shape or
  /// layer is being composited.
  ///
  /// Defaults to [BlendMode.srcOver].
  ///
  /// See also:
  ///
  ///  * [Canvas.saveLayer], which uses its [Paint]'s [blendMode] to composite
  ///    the layer when [restore] is called.
  ///  * [BlendMode], which discusses the user of [saveLayer] with [blendMode].
  BlendMode get blendMode;
  set blendMode(BlendMode value);

  /// Whether to paint inside shapes, the edges of shapes, or both.
  ///
  /// If null, defaults to [PaintingStyle.fill].
  PaintingStyle get style;
  set style(PaintingStyle value);

  /// How wide to make edges drawn when [style] is set to
  /// [PaintingStyle.stroke] or [PaintingStyle.strokeAndFill]. The
  /// width is given in logical pixels measured in the direction
  /// orthogonal to the direction of the path.
  ///
  /// The values null and 0.0 correspond to a hairline width.
  double get strokeWidth;
  set strokeWidth(double value);

  /// The kind of finish to place on the end of lines drawn when
  /// [style] is set to [PaintingStyle.stroke] or
  /// [PaintingStyle.strokeAndFill].
  ///
  /// If null, defaults to [StrokeCap.butt], i.e. no caps.
  StrokeCap get strokeCap;
  set strokeCap(StrokeCap value);

  /// The kind of finish to use for line segment joins.
  /// [style] is set to [PaintingStyle.stroke] or
  /// [PaintingStyle.strokeAndFill]. Only applies to drawPath not drawPoints.
  ///
  /// If null, defaults to [StrokeCap.butt], i.e. no caps.
  StrokeJoin get strokeJoin;
  set strokeJoin(StrokeJoin value);

  /// Whether to apply anti-aliasing to lines and images drawn on the
  /// canvas.
  ///
  /// Defaults to true. The value null is treated as false.
  bool get isAntiAlias;
  set isAntiAlias(bool value);

  Color get color;
  set color(Color value);

  /// Whether the colors of the image are inverted when drawn.
  ///
  /// Inverting the colors of an image applies a new color filter that will
  /// be composed with any user provided color filters. This is primarily
  /// used for implementing smart invert on iOS.
  bool get invertColors;

  set invertColors(bool value);

  /// The shader to use when stroking or filling a shape.
  ///
  /// When this is null, the [color] is used instead.
  ///
  /// See also:
  ///
  ///  * [Gradient], a shader that paints a color gradient.
  ///  * [ImageShader], a shader that tiles an [Image].
  ///  * [colorFilter], which overrides [shader].
  ///  * [color], which is used if [shader] and [colorFilter] are null.
  Shader? get shader;
  set shader(Shader? value);

  /// A mask filter (for example, a blur) to apply to a shape after it has been
  /// drawn but before it has been composited into the image.
  ///
  /// See [MaskFilter] for details.
  MaskFilter? get maskFilter;
  set maskFilter(MaskFilter? value);

  /// Controls the performance vs quality trade-off to use when applying
  /// filters, such as [maskFilter], or when drawing images, as with
  /// [Canvas.drawImageRect] or [Canvas.drawImageNine].
  ///
  /// Defaults to [FilterQuality.none].
  // TODO(ianh): verify that the image drawing methods actually respect this
  FilterQuality get filterQuality;
  set filterQuality(FilterQuality value);

  /// A color filter to apply when a shape is drawn or when a layer is
  /// composited.
  ///
  /// See [ColorFilter] for details.
  ///
  /// When a shape is being drawn, [colorFilter] overrides [color] and [shader].
  ColorFilter? get colorFilter;
  set colorFilter(ColorFilter? value);

  double get strokeMiterLimit;
  set strokeMiterLimit(double value);

  /// The [ImageFilter] to use when drawing raster images.
  ///
  /// For example, to blur an image using [Canvas.drawImage], apply an
  /// [ImageFilter.blur]:
  ///
  /// ```dart
  /// import 'dart:ui' as ui;
  ///
  /// ui.Image image;
  ///
  /// void paint(Canvas canvas, Size size) {
  ///   canvas.drawImage(
  ///     image,
  ///     Offset.zero,
  ///     Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: .5, sigmaY: .5),
  ///   );
  /// }
  /// ```
  ///
  /// See also:
  ///
  ///  * [MaskFilter], which is used for drawing geometry.
  ImageFilter? get imageFilter;
  set imageFilter(ImageFilter? value);
}

/// Base class for objects such as [Gradient] and [ImageShader] which
/// correspond to shaders as used by [Paint.shader].
abstract class Shader {
  /// This class is created by the engine, and should not be instantiated
  /// or extended directly.
  Shader._();
}

/// A shader (as used by [Paint.shader]) that renders a color gradient.
///
/// There are several types of gradients, represented by the various
/// constructors on this class.
abstract class Gradient extends Shader {
  /// Creates a linear gradient from `from` to `to`.
  ///
  /// If `colorStops` is provided, `colorStops[i]` is a number from 0.0 to 1.0
  /// that specifies where `color[i]` begins in the gradient. If `colorStops` is
  /// not provided, then only two stops, at 0.0 and 1.0, are implied (and
  /// `color` must therefore only have two entries).
  ///
  /// The behavior before `from` and after `to` is described by the `tileMode`
  /// argument. For details, see the [TileMode] enum.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_clamp_linear.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_mirror_linear.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_repeated_linear.png)
  ///
  /// If `from`, `to`, `colors`, or `tileMode` are null, or if `colors` or
  /// `colorStops` contain null values, this constructor will throw a
  /// [NoSuchMethodError].
  factory Gradient.linear(
    Offset from,
    Offset to,
    List<Color> colors, [
    List<double>? colorStops,
    TileMode tileMode = TileMode.clamp,
    Float64List? matrix4,
  ]) => engine.experimentalUseSkia
    ? engine.CkGradientLinear(from, to, colors, colorStops, tileMode, matrix4)
    : engine.GradientLinear(from, to, colors, colorStops, tileMode, matrix4);

  /// Creates a radial gradient centered at `center` that ends at `radius`
  /// distance from the center.
  ///
  /// If `colorStops` is provided, `colorStops[i]` is a number from 0.0 to 1.0
  /// that specifies where `color[i]` begins in the gradient. If `colorStops` is
  /// not provided, then only two stops, at 0.0 and 1.0, are implied (and
  /// `color` must therefore only have two entries).
  ///
  /// The behavior before and after the radius is described by the `tileMode`
  /// argument. For details, see the [TileMode] enum.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_clamp_radial.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_mirror_radial.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_repeated_radial.png)
  ///
  /// If `center`, `radius`, `colors`, or `tileMode` are null, or if `colors` or
  /// `colorStops` contain null values, this constructor will throw a
  /// [NoSuchMethodError].
  ///
  /// If `matrix4` is provided, the gradient fill will be transformed by the
  /// specified 4x4 matrix relative to the local coordinate system. `matrix4`
  /// must be a column-major matrix packed into a list of 16 values.
  ///
  /// If `focal` is provided and not equal to `center` and `focalRadius` is
  /// provided and not equal to 0.0, the generated shader will be a two point
  /// conical radial gradient, with `focal` being the center of the focal
  /// circle and `focalRadius` being the radius of that circle. If `focal` is
  /// provided and not equal to `center`, at least one of the two offsets must
  /// not be equal to [Offset.zero].
  factory Gradient.radial(
    Offset center,
    double radius,
    List<Color> colors, [
    List<double>? colorStops,
    TileMode tileMode = TileMode.clamp,
    Float64List? matrix4,
    Offset? focal,
    double focalRadius = 0.0,
  ]) {
    _validateColorStops(colors, colorStops);
    // If focal is null or focal radius is null, this should be treated as a regular radial gradient
    // If focal == center and the focal radius is 0.0, it's still a regular radial gradient
    final Float32List? matrix32 =
        matrix4 != null ? engine.toMatrix32(matrix4) : null;
    if (focal == null || (focal == center && focalRadius == 0.0)) {
      return engine.experimentalUseSkia
        ? engine.CkGradientRadial(
          center, radius, colors, colorStops, tileMode, matrix32)
        : engine.GradientRadial(
          center, radius, colors, colorStops, tileMode, matrix32);
    } else {
      assert(center != Offset.zero ||
          focal != Offset.zero); // will result in exception(s) in Skia side
      return engine.experimentalUseSkia
        ? engine.CkGradientConical(focal, focalRadius, center, radius, colors,
          colorStops, tileMode, matrix32)
        : engine.GradientConical(focal, focalRadius, center, radius, colors,
          colorStops, tileMode, matrix32);
    }
  }

  /// Creates a sweep gradient centered at `center` that starts at `startAngle`
  /// and ends at `endAngle`.
  ///
  /// `startAngle` and `endAngle` should be provided in radians, with zero
  /// radians being the horizontal line to the right of the `center` and with
  /// positive angles going clockwise around the `center`.
  ///
  /// If `colorStops` is provided, `colorStops[i]` is a number from 0.0 to 1.0
  /// that specifies where `color[i]` begins in the gradient. If `colorStops` is
  /// not provided, then only two stops, at 0.0 and 1.0, are implied (and
  /// `color` must therefore only have two entries).
  ///
  /// The behavior before `startAngle` and after `endAngle` is described by the
  /// `tileMode` argument. For details, see the [TileMode] enum.
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_clamp_sweep.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_mirror_sweep.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_repeated_sweep.png)
  ///
  /// If `center`, `colors`, `tileMode`, `startAngle`, or `endAngle` are null,
  /// or if `colors` or `colorStops` contain null values, this constructor will
  /// throw a [NoSuchMethodError].
  ///
  /// If `matrix4` is provided, the gradient fill will be transformed by the
  /// specified 4x4 matrix relative to the local coordinate system. `matrix4`
  /// must be a column-major matrix packed into a list of 16 values.
  factory Gradient.sweep(
    Offset center,
    List<Color> colors, [
    List<double>? colorStops,
    TileMode tileMode = TileMode.clamp,
    double startAngle = 0.0,
    double endAngle = math.pi * 2,
    Float64List? matrix4,
  ]) => engine.experimentalUseSkia
    ? engine.CkGradientSweep(center, colors, colorStops, tileMode, startAngle,
          endAngle, matrix4 != null ? engine.toMatrix32(matrix4) : null)
    : engine.GradientSweep(center, colors, colorStops, tileMode, startAngle,
          endAngle, matrix4 != null ? engine.toMatrix32(matrix4) : null);
}

/// Opaque handle to raw decoded image data (pixels).
///
/// To obtain an [Image] object, use [instantiateImageCodec].
///
/// To draw an [Image], use one of the methods on the [Canvas] class, such as
/// [Canvas.drawImage].
abstract class Image {
  /// The number of image pixels along the image's horizontal axis.
  int get width;

  /// The number of image pixels along the image's vertical axis.
  int get height;

  /// Converts the [Image] object into a byte array.
  ///
  /// The [format] argument specifies the format in which the bytes will be
  /// returned.
  ///
  /// Returns a future that completes with the binary image data or an error
  /// if encoding fails.
  Future<ByteData?> toByteData(
      {ImageByteFormat format = ImageByteFormat.rawRgba});

  /// Release the resources used by this object. The object is no longer usable
  /// after this method is called.
  void dispose();

  @override
  String toString() => '[$width\u00D7$height]';
}

/// A description of a color filter to apply when drawing a shape or compositing
/// a layer with a particular [Paint]. A color filter is a function that takes
/// two colors, and outputs one color. When applied during compositing, it is
/// independently applied to each pixel of the layer being drawn before the
/// entire layer is merged with the destination.
///
/// Instances of this class are used with [Paint.colorFilter] on [Paint]
/// objects.
abstract class ColorFilter {
  /// Creates a color filter that applies the blend mode given as the second
  /// argument. The source color is the one given as the first argument, and the
  /// destination color is the one from the layer being composited.
  ///
  /// The output of this filter is then composited into the background according
  /// to the [Paint.blendMode], using the output of this filter as the source
  /// and the background as the destination.
  const factory ColorFilter.mode(Color color, BlendMode blendMode) =
      engine.EngineColorFilter.mode;

  /// Construct a color filter that transforms a color by a 4x5 matrix.
  ///
  /// Every pixel's color value, repsented as an `[R, G, B, A]`, is matrix
  /// multiplied to create a new color:
  ///
  /// ```
  /// | R' |   | a00 a01 a02 a03 a04 |   | R |
  /// | G' | = | a10 a11 a22 a33 a44 | * | G |
  /// | B' |   | a20 a21 a22 a33 a44 |   | B |
  /// | A' |   | a30 a31 a22 a33 a44 |   | A |
  /// ```
  ///
  /// The matrix is in row-major order and the translation column is specified
  /// in unnormalized, 0...255, space. For example, the identity matrix is:
  ///
  /// ```
  /// const ColorMatrix identity = ColorFilter.matrix(<double>[
  ///   1, 0, 0, 0, 0,
  ///   0, 1, 0, 0, 0,
  ///   0, 0, 1, 0, 0,
  ///   0, 0, 0, 1, 0,
  /// ]);
  /// ```
  ///
  /// ## Examples
  ///
  /// An inversion color matrix:
  ///
  /// ```
  /// const ColorFilter invert = ColorFilter.matrix(<double>[
  ///   -1,  0,  0, 0, 255,
  ///    0, -1,  0, 0, 255,
  ///    0,  0, -1, 0, 255,
  ///    0,  0,  0, 1,   0,
  /// ]);
  /// ```
  ///
  /// A sepia-toned color matrix (values based on the [Filter Effects Spec](https://www.w3.org/TR/filter-effects-1/#sepiaEquivalent)):
  ///
  /// ```
  /// const ColorFilter sepia = ColorFilter.matrix(<double>[
  ///   0.393, 0.769, 0.189, 0, 0,
  ///   0.349, 0.686, 0.168, 0, 0,
  ///   0.272, 0.534, 0.131, 0, 0,
  ///   0,     0,     0,     1, 0,
  /// ]);
  /// ```
  ///
  /// A greyscale color filter (values based on the [Filter Effects Spec](https://www.w3.org/TR/filter-effects-1/#grayscaleEquivalent)):
  ///
  /// ```
  /// const ColorFilter greyscale = ColorFilter.matrix(<double>[
  ///   0.2126, 0.7152, 0.0722, 0, 0,
  ///   0.2126, 0.7152, 0.0722, 0, 0,
  ///   0.2126, 0.7152, 0.0722, 0, 0,
  ///   0,      0,      0,      1, 0,
  /// ]);
  /// ```
  const factory ColorFilter.matrix(List<double> matrix) =
      engine.EngineColorFilter.matrix;

  /// Construct a color filter that applies the sRGB gamma curve to the RGB
  /// channels.
  const factory ColorFilter.linearToSrgbGamma() =
      engine.EngineColorFilter.linearToSrgbGamma;

  /// Creates a color filter that applies the inverse of the sRGB gamma curve
  /// to the RGB channels.
  const factory ColorFilter.srgbToLinearGamma() =
      engine.EngineColorFilter.srgbToLinearGamma;
}

/// Styles to use for blurs in [MaskFilter] objects.
// These enum values must be kept in sync with SkBlurStyle.
enum BlurStyle {
  // These mirror SkBlurStyle and must be kept in sync.

  /// Fuzzy inside and outside. This is useful for painting shadows that are
  /// offset from the shape that ostensibly is casting the shadow.
  normal,

  /// Solid inside, fuzzy outside. This corresponds to drawing the shape, and
  /// additionally drawing the blur. This can make objects appear brighter,
  /// maybe even as if they were fluorescent.
  solid,

  /// Nothing inside, fuzzy outside. This is useful for painting shadows for
  /// partially transparent shapes, when they are painted separately but without
  /// an offset, so that the shadow doesn't paint below the shape.
  outer,

  /// Fuzzy inside, nothing outside. This can make shapes appear to be lit from
  /// within.
  inner,
}

/// A mask filter to apply to shapes as they are painted. A mask filter is a
/// function that takes a bitmap of color pixels, and returns another bitmap of
/// color pixels.
///
/// Instances of this class are used with [Paint.maskFilter] on [Paint] objects.
class MaskFilter {
  /// Creates a mask filter that takes the shape being drawn and blurs it.
  ///
  /// This is commonly used to approximate shadows.
  ///
  /// The `style` argument controls the kind of effect to draw; see [BlurStyle].
  ///
  /// The `sigma` argument controls the size of the effect. It is the standard
  /// deviation of the Gaussian blur to apply. The value must be greater than
  /// zero. The sigma corresponds to very roughly half the radius of the effect
  /// in pixels.
  ///
  /// A blur is an expensive operation and should therefore be used sparingly.
  ///
  /// The arguments must not be null.
  ///
  /// See also:
  ///
  ///  * [Canvas.drawShadow], which is a more efficient way to draw shadows.
  const MaskFilter.blur(
    this._style,
    this._sigma,
  )   : assert(_style != null), // ignore: unnecessary_null_comparison
        assert(_sigma != null); // ignore: unnecessary_null_comparison

  final BlurStyle _style;
  final double _sigma;

  /// On the web returns the value of sigma passed to [MaskFilter.blur].
  double get webOnlySigma => _sigma;

  /// On the web returns the value of `style` passed to [MaskFilter.blur].
  BlurStyle get webOnlyBlurStyle => _style;

  @override
  bool operator ==(Object other) {
    return other is MaskFilter &&
        other._style == _style &&
        other._sigma == _sigma;
  }

  @override
  int get hashCode => hashValues(_style, _sigma);

  @override
  String toString() => 'MaskFilter.blur($_style, ${_sigma.toStringAsFixed(1)})';
}

/// Quality levels for image filters.
///
/// See [Paint.filterQuality].
enum FilterQuality {
  // This list comes from Skia's SkFilterQuality.h and the values (order) should
  // be kept in sync.

  /// Fastest possible filtering, albeit also the lowest quality.
  ///
  /// Typically this implies nearest-neighbour filtering.
  none,

  /// Better quality than [none], faster than [medium].
  ///
  /// Typically this implies bilinear interpolation.
  low,

  /// Better quality than [low], faster than [high].
  ///
  /// Typically this implies a combination of bilinear interpolation and
  /// pyramidal parametric prefiltering (mipmaps).
  medium,

  /// Best possible quality filtering, albeit also the slowest.
  ///
  /// Typically this implies bicubic interpolation or better.
  high,
}

/// A filter operation to apply to a raster image.
///
/// See also:
///
///  * [BackdropFilter], a widget that applies [ImageFilter] to its rendering.
///  * [SceneBuilder.pushBackdropFilter], which is the low-level API for using
///    this class.
class ImageFilter {
  /// Creates an image filter that applies a Gaussian blur.
  factory ImageFilter.blur({double sigmaX = 0.0, double sigmaY = 0.0}) {
    if (engine.experimentalUseSkia) {
      return engine.CkImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY);
    }
    return engine.EngineImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY);
  }

  ImageFilter.matrix(Float64List matrix4,
      {FilterQuality filterQuality = FilterQuality.low}) {
    // TODO(flutter_web): add implementation.
    throw UnimplementedError(
        'ImageFilter.matrix not implemented for web platform.');
    //    if (matrix4.length != 16)
    //      throw ArgumentError('"matrix4" must have 16 entries.');
  }
}

/// The format in which image bytes should be returned when using
/// [Image.toByteData].
enum ImageByteFormat {
  /// Raw RGBA format.
  ///
  /// Unencoded bytes, in RGBA row-primary form, 8 bits per channel.
  rawRgba,

  /// Raw unmodified format.
  ///
  /// Unencoded bytes, in the image's existing format. For example, a grayscale
  /// image may use a single 8-bit channel for each pixel.
  rawUnmodified,

  /// PNG format.
  ///
  /// A loss-less compression format for images. This format is well suited for
  /// images with hard edges, such as screenshots or sprites, and images with
  /// text. Transparency is supported. The PNG format supports images up to
  /// 2,147,483,647 pixels in either dimension, though in practice available
  /// memory provides a more immediate limitation on maximum image size.
  ///
  /// PNG images normally use the `.png` file extension and the `image/png` MIME
  /// type.
  ///
  /// See also:
  ///
  ///  * <https://en.wikipedia.org/wiki/Portable_Network_Graphics>, the Wikipedia page on PNG.
  ///  * <https://tools.ietf.org/rfc/rfc2083.txt>, the PNG standard.
  png,
}

/// The format of pixel data given to [decodeImageFromPixels].
enum PixelFormat {
  /// Each pixel is 32 bits, with the highest 8 bits encoding red, the next 8
  /// bits encoding green, the next 8 bits encoding blue, and the lowest 8 bits
  /// encoding alpha.
  rgba8888,

  /// Each pixel is 32 bits, with the highest 8 bits encoding blue, the next 8
  /// bits encoding green, the next 8 bits encoding red, and the lowest 8 bits
  /// encoding alpha.
  bgra8888,
}

/// Callback signature for [decodeImageFromList].
typedef ImageDecoderCallback = void Function(Image result);

/// Information for a single frame of an animation.
///
/// To obtain an instance of the [FrameInfo] interface, see
/// [Codec.getNextFrame].
abstract class FrameInfo {
  /// This class is created by the engine, and should not be instantiated
  /// or extended directly.
  ///
  /// To obtain an instance of the [FrameInfo] interface, see
  /// [Codec.getNextFrame].
  FrameInfo._();

  /// The duration this frame should be shown.
  Duration get duration => Duration(milliseconds: _durationMillis);
  int get _durationMillis => 0;

  /// The [Image] object for this frame.
  Image get image;
}

/// A handle to an image codec.
class Codec {
  /// This class is created by the engine, and should not be instantiated
  /// or extended directly.
  ///
  /// To obtain an instance of the [Codec] interface, see
  /// [instantiateImageCodec].
  Codec._();

  /// Number of frames in this image.
  int get frameCount => 0;

  /// Number of times to repeat the animation.
  ///
  /// * 0 when the animation should be played once.
  /// * -1 for infinity repetitions.
  int get repetitionCount => 0;

  /// Fetches the next animation frame.
  ///
  /// Wraps back to the first frame after returning the last frame.
  ///
  /// The returned future can complete with an error if the decoding has failed.
  Future<FrameInfo> getNextFrame() {
    return engine.futurize<FrameInfo>(_getNextFrame);
  }

  /// Returns an error message on failure, null on success.
  String? _getNextFrame(engine.Callback<FrameInfo> callback) => null;

  /// Release the resources used by this object. The object is no longer usable
  /// after this method is called.
  void dispose() {}
}

/// Instantiates an image codec [Codec] object.
///
/// [list] is the binary image data (e.g a PNG or GIF binary data).
/// The data can be for either static or animated images.
///
/// The following image formats are supported: {@macro flutter.dart:ui.imageFormats}
///
/// The returned future can complete with an error if the image decoding has
/// failed.
Future<Codec> instantiateImageCodec(
  Uint8List list, {
  int? targetWidth,
  int? targetHeight,
  bool allowUpscaling = true,
}) {
  return _futurize<Codec>((engine.Callback<Codec> callback) =>
      // TODO: Implement targetWidth and targetHeight support.
      _instantiateImageCodec(list, callback));
}

/// Instantiates a [Codec] object for an image binary data.
///
/// Returns an error message if the instantiation has failed, null otherwise.
String? _instantiateImageCodec(
  Uint8List list,
  engine.Callback<Codec> callback, {
  int? width,
  int? height,
  int? rowBytes,
  PixelFormat? format,
}) {
  if (engine.experimentalUseSkia) {
    if (width == null) {
      engine.skiaInstantiateImageCodec(list, callback);
    } else {
      assert(height != null);
      assert(format != null);
      engine.skiaInstantiateImageCodec(
          list, callback, width, height, format!.index, rowBytes);
    }
    return null;
  }
  final html.Blob blob = html.Blob(<dynamic>[list.buffer]);
  callback(engine.HtmlBlobCodec(blob));
  return null;
}

Future<Codec?> webOnlyInstantiateImageCodecFromUrl(Uri uri,
    {engine.WebOnlyImageCodecChunkCallback? chunkCallback}) {
  return _futurize<Codec?>((engine.Callback<Codec> callback) =>
      _instantiateImageCodecFromUrl(uri, chunkCallback, callback));
}

String? _instantiateImageCodecFromUrl(
    Uri uri,
    engine.WebOnlyImageCodecChunkCallback? chunkCallback,
    engine.Callback<Codec> callback) {
  if (engine.experimentalUseSkia) {
    engine.skiaInstantiateWebImageCodec(
        uri.toString(), callback, chunkCallback);
    return null;
  } else {
    callback(engine.HtmlCodec(uri.toString(), chunkCallback: chunkCallback));
    return null;
  }
}

/// Loads a single image frame from a byte array into an [Image] object.
///
/// This is a convenience wrapper around [instantiateImageCodec].
/// Prefer using [instantiateImageCodec] which also supports multi frame images.
void decodeImageFromList(Uint8List list, ImageDecoderCallback callback) {
  _decodeImageFromListAsync(list, callback);
}

Future<void> _decodeImageFromListAsync(
    Uint8List list, ImageDecoderCallback callback) async {
  final Codec codec = await instantiateImageCodec(list);
  final FrameInfo frameInfo = await codec.getNextFrame();
  callback(frameInfo.image);
}

/// Convert an array of pixel values into an [Image] object.
///
/// [pixels] is the pixel data in the encoding described by [format].
///
/// [rowBytes] is the number of bytes consumed by each row of pixels in the
/// data buffer.  If unspecified, it defaults to [width] multipled by the
/// number of bytes per pixel in the provided [format].
void decodeImageFromPixels(
  Uint8List pixels,
  int width,
  int height,
  PixelFormat format,
  ImageDecoderCallback callback, {
  int? rowBytes,
  int? targetWidth,
  int? targetHeight,
  bool allowUpscaling = true,
}) {
  final Future<Codec> codecFuture =
      _futurize((engine.Callback<Codec> callback) {
    return _instantiateImageCodec(
      pixels,
      callback,
      width: width,
      height: height,
      format: format,
      rowBytes: rowBytes,
    );
  });
  codecFuture
      .then((Codec codec) => codec.getNextFrame())
      .then((FrameInfo frameInfo) => callback(frameInfo.image));
}

/// A single shadow.
///
/// Multiple shadows are stacked together in a [TextStyle].
class Shadow {
  /// Construct a shadow.
  ///
  /// The default shadow is a black shadow with zero offset and zero blur.
  /// Default shadows should be completely covered by the casting element,
  /// and not be visble.
  ///
  /// Transparency should be adjusted through the [color] alpha.
  ///
  /// Shadow order matters due to compositing multiple translucent objects not
  /// being commutative.
  const Shadow({
    this.color = const Color(_kColorDefault),
    this.offset = Offset.zero,
    this.blurRadius = 0.0,
  })  : assert(color != null,
            'Text shadow color was null.'), // ignore: unnecessary_null_comparison
        assert(offset != null,
            'Text shadow offset was null.'), // ignore: unnecessary_null_comparison
        assert(blurRadius >= 0.0,
            'Text shadow blur radius should be non-negative.');

  static const int _kColorDefault = 0xFF000000;

  /// Color that the shadow will be drawn with.
  ///
  /// The shadows are shapes composited directly over the base canvas, and do not
  /// represent optical occlusion.
  final Color color;

  /// The displacement of the shadow from the casting element.
  ///
  /// Positive x/y offsets will shift the shadow to the right and down, while
  /// negative offsets shift the shadow to the left and up. The offsets are
  /// relative to the position of the element that is casting it.
  final Offset offset;

  /// The standard deviation of the Gaussian to convolve with the shadow's shape.
  final double blurRadius;

  /// Converts a blur radius in pixels to sigmas.
  ///
  /// See the sigma argument to [MaskFilter.blur].
  ///
  // See SkBlurMask::ConvertRadiusToSigma().
  // <https://github.com/google/skia/blob/bb5b77db51d2e149ee66db284903572a5aac09be/src/effects/SkBlurMask.cpp#L23>
  static double convertRadiusToSigma(double radius) {
    return radius * 0.57735 + 0.5;
  }

  /// The [blurRadius] in sigmas instead of logical pixels.
  ///
  /// See the sigma argument to [MaskFilter.blur].
  double get blurSigma => convertRadiusToSigma(blurRadius);

  /// Create the [Paint] object that corresponds to this shadow description.
  ///
  /// The [offset] is not represented in the [Paint] object.
  /// To honor this as well, the shape should be translated by [offset] before
  /// being filled using this [Paint].
  ///
  /// This class does not provide a way to disable shadows to avoid inconsistencies
  /// in shadow blur rendering, primarily as a method of reducing test flakiness.
  /// [toPaint] should be overriden in subclasses to provide this functionality.
  Paint toPaint() {
    return Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
  }

  /// Returns a new shadow with its [offset] and [blurRadius] scaled by the given
  /// factor.
  Shadow scale(double factor) {
    return Shadow(
      color: color,
      offset: offset * factor,
      blurRadius: blurRadius * factor,
    );
  }

  /// Linearly interpolate between two shadows.
  ///
  /// If either shadow is null, this function linearly interpolates from a
  /// a shadow that matches the other shadow in color but has a zero
  /// offset and a zero blurRadius.
  ///
  /// {@template dart.ui.shadow.lerp}
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
  /// {@endtemplate}
  static Shadow? lerp(Shadow? a, Shadow? b, double t) {
    assert(t != null); // ignore: unnecessary_null_comparison
    if (b == null) {
      if (a == null) {
        return null;
      } else {
        return a.scale(1.0 - t);
      }
    } else {
      if (a == null) {
        return b.scale(t);
      } else {
        return Shadow(
          color: Color.lerp(a.color, b.color, t)!,
          offset: Offset.lerp(a.offset, b.offset, t)!,
          blurRadius: _lerpDouble(a.blurRadius, b.blurRadius, t),
        );
      }
    }
  }

  /// Linearly interpolate between two lists of shadows.
  ///
  /// If the lists differ in length, excess items are lerped with null.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static List<Shadow>? lerpList(List<Shadow>? a, List<Shadow>? b, double t) {
    assert(t != null); // ignore: unnecessary_null_comparison
    if (a == null && b == null) {
      return null;
    }
    a ??= <Shadow>[];
    b ??= <Shadow>[];
    final List<Shadow> result = <Shadow>[];
    final int commonLength = math.min(a.length, b.length);
    for (int i = 0; i < commonLength; i += 1)
      result.add(Shadow.lerp(a[i], b[i], t)!);
    for (int i = commonLength; i < a.length; i += 1)
      result.add(a[i].scale(1.0 - t));
    for (int i = commonLength; i < b.length; i += 1) {
      result.add(b[i].scale(t));
    }
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Shadow &&
        other.color == color &&
        other.offset == offset &&
        other.blurRadius == blurRadius;
  }

  @override
  int get hashCode => hashValues(color, offset, blurRadius);

  @override
  String toString() => 'TextShadow($color, $offset, $blurRadius)';
}

/// A shader (as used by [Paint.shader]) that tiles an image.
class ImageShader extends Shader {
  /// Creates an image-tiling shader. The first argument specifies the image to
  /// tile. The second and third arguments specify the [TileMode] for the x
  /// direction and y direction respectively. The fourth argument gives the
  /// matrix to apply to the effect. All the arguments are required and must not
  /// be null.
  factory ImageShader(
      Image image, TileMode tmx, TileMode tmy, Float64List matrix4) {
    if (engine.experimentalUseSkia) {
      return engine.CkImageShader(image, tmx, tmy, matrix4);
    }
    throw UnsupportedError('ImageShader not implemented for web platform.');
  }
}

/// A handle to a read-only byte buffer that is managed by the engine.
class ImmutableBuffer {
  ImmutableBuffer._(this.length);

  /// Creates a copy of the data from a [Uint8List] suitable for internal use
  /// in the engine.
  static Future<ImmutableBuffer> fromUint8List(Uint8List list) async {
    final ImmutableBuffer instance = ImmutableBuffer._(list.length);
    instance._list = list;
    return instance;
  }

  Uint8List? _list;

  /// The length, in bytes, of the underlying data.
  final int length;

  /// Release the resources used by this object. The object is no longer usable
  /// after this method is called.
  void dispose() => _list = null;
}

/// A descriptor of data that can be turned into an [Image] via a [Codec].
///
/// Use this class to determine the height, width, and byte size of image data
/// before decoding it.
class ImageDescriptor {
  ImageDescriptor._()
      : _width = null,
        _height = null,
        _rowBytes = null,
        _format = null;

  /// Creates an image descriptor from encoded data in a supported format.
  static Future<ImageDescriptor> encoded(ImmutableBuffer buffer) async {
    final ImageDescriptor descriptor = ImageDescriptor._();
    descriptor._data = buffer._list;
    return descriptor;
  }

  /// Creates an image descriptor from raw image pixels.
  ///
  /// The `pixels` parameter is the pixel data in the encoding described by
  /// `format`.
  ///
  /// The `rowBytes` parameter is the number of bytes consumed by each row of
  /// pixels in the data buffer. If unspecified, it defaults to `width` multiplied
  /// by the number of bytes per pixel in the provided `format`.
  // Not async because there's no expensive work to do here.
  ImageDescriptor.raw(
    ImmutableBuffer buffer, {
    required int width,
    required int height,
    int? rowBytes,
    required PixelFormat pixelFormat,
  })   : _width = width,
        _height = height,
        _rowBytes = rowBytes,
        _format = pixelFormat {
    _data = buffer._list;
  }

  Uint8List? _data;
  final int? _width;
  final int? _height;
  final int? _rowBytes;
  final PixelFormat? _format;

  Never _throw(String parameter) {
    throw UnsupportedError(
        'ImageDescriptor.$parameter is not supported on web.');
  }

  /// The width, in pixels, of the image.
  int get width => _width ?? _throw('width');

  /// The height, in pixels, of the image.
  int get height => _height ?? _throw('height');

  /// The number of bytes per pixel in the image.
  int get bytesPerPixel => throw UnsupportedError(
      'ImageDescriptor.bytesPerPixel is not supported on web.');

  /// Release the resources used by this object. The object is no longer usable
  /// after this method is called.
  void dispose() => _data = null;

  /// Creates a [Codec] object which is suitable for decoding the data in the
  /// buffer to an [Image].
  Future<Codec> instantiateCodec({int? targetWidth, int? targetHeight}) {
    if (_data == null) {
      throw StateError('Object is disposed');
    }
    if (_width == null) {
      return instantiateImageCodec(
        _data!,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        allowUpscaling: false,
      );
    }
    return _futurize((engine.Callback<Codec> callback) {
      return _instantiateImageCodec(
        _data!,
        callback,
        width: _width,
        height: _height,
        format: _format,
        rowBytes: _rowBytes,
      );
    });
  }
}

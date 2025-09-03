// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'color_scheme.dart';
/// @docImport 'range_slider.dart';
/// @docImport 'text_theme.dart';
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'slider.dart';
import 'slider_theme.dart';
import 'slider_value_indicator_shape.dart';

/// Base class for [RangeSlider] thumb shapes.
///
/// See also:
///
///  * [RoundRangeSliderThumbShape] for the default [RangeSlider]'s thumb shape
///    that paints a solid circle.
///  * [RangeSliderTickMarkShape], which can be used to create custom shapes for
///    the [RangeSlider]'s tick marks.
///  * [RangeSliderTrackShape], which can be used to create custom shapes for
///    the [RangeSlider]'s track.
///  * [RangeSliderValueIndicatorShape], which can be used to create custom
///    shapes for the [RangeSlider]'s value indicator.
///  * [SliderComponentShape], which can be used to create custom shapes for
///    the [Slider]'s thumb, overlay, and value indicator and the
///    [RangeSlider]'s overlay.
abstract class RangeSliderThumbShape {
  /// This abstract const constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const RangeSliderThumbShape();

  /// Returns the preferred size of the shape, based on the given conditions.
  ///
  /// {@template flutter.material.RangeSliderThumbShape.getPreferredSize.isDiscrete}
  /// The `isDiscrete` argument is true if [RangeSlider.divisions] is non-null.
  /// When true, the slider will render tick marks on top of the track.
  /// {@endtemplate}
  ///
  /// {@template flutter.material.RangeSliderThumbShape.getPreferredSize.isEnabled}
  /// The `isEnabled` argument is false when [RangeSlider.onChanged] is null and
  /// true otherwise. When true, the slider will respond to input.
  /// {@endtemplate}
  Size getPreferredSize(bool isEnabled, bool isDiscrete);

  /// Paints the thumb shape based on the state passed to it.
  ///
  /// {@template flutter.material.RangeSliderThumbShape.paint.context}
  /// The `context` argument represents the [RangeSlider]'s render box.
  /// {@endtemplate}
  ///
  /// {@macro flutter.material.SliderComponentShape.paint.center}
  ///
  /// {@template flutter.material.RangeSliderThumbShape.paint.activationAnimation}
  /// The `activationAnimation` argument is an animation triggered when the user
  /// begins to interact with the [RangeSlider]. It reverses when the user stops
  /// interacting with the slider.
  /// {@endtemplate}
  ///
  /// {@template flutter.material.RangeSliderThumbShape.paint.enableAnimation}
  /// The `enableAnimation` argument is an animation triggered when the
  /// [RangeSlider] is enabled, and it reverses when the slider is disabled. The
  /// [RangeSlider] is enabled when [RangeSlider.onChanged] is not null. Use
  /// this to paint intermediate frames for this shape when the slider changes
  /// enabled state.
  /// {@endtemplate}
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.getPreferredSize.isDiscrete}
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.getPreferredSize.isEnabled}
  ///
  /// If the `isOnTop` argument is true, this thumb is painted on top of the
  /// other slider thumb because this thumb is the one that was most recently
  /// selected.
  ///
  /// {@template flutter.material.RangeSliderThumbShape.paint.sliderTheme}
  /// The `sliderTheme` argument is the theme assigned to the [RangeSlider] that
  /// this shape belongs to.
  /// {@endtemplate}
  ///
  /// The `textDirection` argument can be used to determine how the orientation
  /// of either slider thumb should be changed, such as drawing different
  /// shapes for the left and right thumb.
  ///
  /// {@template flutter.material.RangeSliderThumbShape.paint.thumb}
  /// The `thumb` argument is the specifier for which of the two thumbs this
  /// method should paint (start or end).
  /// {@endtemplate}
  ///
  /// The `isPressed` argument can be used to give the selected thumb
  /// additional selected or pressed state visual feedback, such as a larger
  /// shadow.
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete,
    bool isEnabled,
    bool isOnTop,
    TextDirection textDirection,
    required SliderThemeData sliderTheme,
    Thumb thumb,
    bool isPressed,
  });
}

/// Base class for [RangeSlider] value indicator shapes.
///
/// See also:
///
///  * [PaddleRangeSliderValueIndicatorShape] for the default [RangeSlider]'s
///    value indicator shape that paints a custom path with text in it.
///  * [RangeSliderTickMarkShape], which can be used to create custom shapes for
///    the [RangeSlider]'s tick marks.
///  * [RangeSliderThumbShape], which can be used to create custom shapes for
///    the [RangeSlider]'s thumb.
///  * [RangeSliderTrackShape], which can be used to create custom shapes for
///    the [RangeSlider]'s track.
///  * [SliderComponentShape], which can be used to create custom shapes for
///    the [Slider]'s thumb, overlay, and value indicator and the
///    [RangeSlider]'s overlay.
abstract class RangeSliderValueIndicatorShape {
  /// This abstract const constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const RangeSliderValueIndicatorShape();

  /// Returns the preferred size of the shape, based on the given conditions.
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.getPreferredSize.isEnabled}
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.getPreferredSize.isDiscrete}
  ///
  /// The `labelPainter` argument helps determine the width of the shape. It is
  /// variable width because it is derived from a formatted string.
  ///
  /// {@macro flutter.material.SliderComponentShape.paint.textScaleFactor}
  Size getPreferredSize(
    bool isEnabled,
    bool isDiscrete, {
    required TextPainter labelPainter,
    required double textScaleFactor,
  });

  /// Determines the best offset to keep this shape on the screen.
  ///
  /// Override this method when the center of the value indicator should be
  /// shifted from the vertical center of the thumb.
  double getHorizontalShift({
    RenderBox? parentBox,
    Offset? center,
    TextPainter? labelPainter,
    Animation<double>? activationAnimation,
    double? textScaleFactor,
    Size? sizeWithOverflow,
  }) {
    return 0;
  }

  /// Paints the value indicator shape based on the state passed to it.
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.paint.context}
  ///
  /// {@macro flutter.material.SliderComponentShape.paint.center}
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.paint.activationAnimation}
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.paint.enableAnimation}
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.getPreferredSize.isDiscrete}
  ///
  /// The `isOnTop` argument is the top-most value indicator between the two value
  /// indicators, which is always the indicator for the most recently selected thumb. In
  /// the default case, this is used to paint a stroke around the top indicator
  /// for better visibility between the two indicators.
  ///
  /// {@macro flutter.material.SliderComponentShape.paint.textScaleFactor}
  ///
  /// {@macro flutter.material.SliderComponentShape.paint.sizeWithOverflow}
  ///
  /// {@template flutter.material.RangeSliderValueIndicatorShape.paint.parentBox}
  /// The `parentBox` argument is the [RenderBox] of the [RangeSlider]. Its
  /// attributes, such as size, can be used to assist in painting this shape.
  /// {@endtemplate}
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.paint.sliderTheme}
  ///
  /// The `textDirection` argument can be used to determine how any extra text
  /// or graphics, besides the text painted by the [labelPainter] should be
  /// positioned. The `labelPainter` argument already has the `textDirection`
  /// set.
  ///
  /// The `value` argument is the current parametric value (from 0.0 to 1.0) of
  /// the slider.
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.paint.thumb}
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete,
    bool isOnTop,
    required TextPainter labelPainter,
    double textScaleFactor,
    Size sizeWithOverflow,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    TextDirection textDirection,
    double value,
    Thumb thumb,
  });
}

/// Base class for [RangeSlider] tick mark shapes.
///
/// This is a simplified version of [SliderComponentShape] with a
/// [SliderThemeData] passed when getting the preferred size.
///
/// See also:
///
///  * [RoundRangeSliderTickMarkShape] for the default [RangeSlider]'s tick mark
///    shape that paints a solid circle.
///  * [RangeSliderThumbShape], which can be used to create custom shapes for
///    the [RangeSlider]'s thumb.
///  * [RangeSliderTrackShape], which can be used to create custom shapes for
///    the [RangeSlider]'s track.
///  * [RangeSliderValueIndicatorShape], which can be used to create custom
///    shapes for the [RangeSlider]'s value indicator.
///  * [SliderComponentShape], which can be used to create custom shapes for
///    the [Slider]'s thumb, overlay, and value indicator and the
///    [RangeSlider]'s overlay.
abstract class RangeSliderTickMarkShape {
  /// This abstract const constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const RangeSliderTickMarkShape();

  /// Returns the preferred size of the shape.
  ///
  /// It is used to help position the tick marks within the slider.
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.paint.sliderTheme}
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.getPreferredSize.isEnabled}
  Size getPreferredSize({required SliderThemeData sliderTheme, bool isEnabled});

  /// Paints the slider track.
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.paint.context}
  ///
  /// {@macro flutter.material.SliderComponentShape.paint.center}
  ///
  /// {@macro flutter.material.RangeSliderValueIndicatorShape.paint.parentBox}
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.paint.sliderTheme}
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.paint.enableAnimation}
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.getPreferredSize.isEnabled}
  ///
  /// The `textDirection` argument can be used to determine how the tick marks
  /// are painted depending on whether they are on an active track segment or not.
  ///
  /// {@template flutter.material.RangeSliderTickMarkShape.paint.trackSegment}
  /// The track segment between the two thumbs is the active track segment. The
  /// track segments between the thumb and each end of the slider are the inactive
  /// track segments. In [TextDirection.ltr], the start of the slider is on the
  /// left, and in [TextDirection.rtl], the start of the slider is on the right.
  /// {@endtemplate}
  void paint(
    PaintingContext context,
    Offset center, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled,
    required TextDirection textDirection,
  });
}

/// Base class for [RangeSlider] track shapes.
///
/// The slider's thumbs move along the track. A discrete slider's tick marks
/// are drawn after the track, but before the thumb, and are aligned with the
/// track.
///
/// The [getPreferredRect] helps position the slider thumbs and tick marks
/// relative to the track.
///
/// See also:
///
///  * [RoundedRectRangeSliderTrackShape] for the default [RangeSlider]'s track
///    shape that paints a stadium-like track.
///  * [RangeSliderTickMarkShape], which can be used to create custom shapes for
///    the [RangeSlider]'s tick marks.
///  * [RangeSliderThumbShape], which can be used to create custom shapes for
///    the [RangeSlider]'s thumb.
///  * [RangeSliderValueIndicatorShape], which can be used to create custom
///    shapes for the [RangeSlider]'s value indicator.
///  * [SliderComponentShape], which can be used to create custom shapes for
///    the [Slider]'s thumb, overlay, and value indicator and the
///    [RangeSlider]'s overlay.
abstract class RangeSliderTrackShape {
  /// This abstract const constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const RangeSliderTrackShape();

  /// Returns the preferred bounds of the shape.
  ///
  /// It is used to provide horizontal boundaries for the position of the
  /// thumbs, and to help position the slider thumbs and tick marks relative to
  /// the track.
  ///
  /// The `parentBox` argument can be used to help determine the preferredRect
  /// relative to attributes of the render box of the slider itself, such as
  /// size.
  ///
  /// The `offset` argument is relative to the caller's bounding box. It can be
  /// used to convert gesture coordinates from global to slider-relative
  /// coordinates.
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.paint.sliderTheme}
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.getPreferredSize.isEnabled}
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.getPreferredSize.isDiscrete}
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled,
    bool isDiscrete,
  });

  /// Paints the track shape based on the state passed to it.
  ///
  /// {@macro flutter.material.SliderComponentShape.paint.context}
  ///
  /// The `offset` argument is the offset of the origin of the `parentBox` to
  /// the origin of its `context` canvas. This shape must be painted relative
  /// to this offset. See [PaintingContextCallback].
  ///
  /// {@macro flutter.material.RangeSliderValueIndicatorShape.paint.parentBox}
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.paint.sliderTheme}
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.paint.enableAnimation}
  ///
  /// The `startThumbCenter` argument is the offset of the center of the start
  /// thumb relative to the origin of the [PaintingContext.canvas]. It can be
  /// used as one point that divides the track between inactive and active.
  ///
  /// The `endThumbCenter` argument is the offset of the center of the end
  /// thumb relative to the origin of the [PaintingContext.canvas]. It can be
  /// used as one point that divides the track between inactive and active.
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.getPreferredSize.isEnabled}
  ///
  /// {@macro flutter.material.RangeSliderThumbShape.getPreferredSize.isDiscrete}
  ///
  /// The `textDirection` argument can be used to determine how the track
  /// segments are painted depending on whether they are on an active track
  /// segment or not.
  ///
  /// {@macro flutter.material.RangeSliderTickMarkShape.paint.trackSegment}
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  });

  /// Whether the track shape is rounded. This is used to determine the correct
  /// position of the thumbs in relation to the track. Defaults to false.
  bool get isRounded => false;
}

/// Base range slider track shape that provides an implementation of [getPreferredRect] for
/// default sizing.
///
/// The height is set from [SliderThemeData.trackHeight] and the width of the
/// parent box less the larger of the widths of [SliderThemeData.rangeThumbShape] and
/// [SliderThemeData.overlayShape].
///
/// See also:
///
///  * [RectangularRangeSliderTrackShape], which is a track shape with sharp
///    rectangular edges
mixin BaseRangeSliderTrackShape {
  /// Returns a rect that represents the track bounds that fits within the
  /// [Slider].
  ///
  /// The width is the width of the [RangeSlider], but padded by the max
  /// of the overlay and thumb radius. The height is defined by the  [SliderThemeData.trackHeight].
  ///
  /// The [Rect] is centered both horizontally and vertically within the slider
  /// bounds.
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    assert(sliderTheme.rangeThumbShape != null);
    assert(sliderTheme.overlayShape != null);
    assert(sliderTheme.trackHeight != null);
    final Size thumbSize = sliderTheme.rangeThumbShape!.getPreferredSize(isEnabled, isDiscrete);
    final double overlayWidth = sliderTheme.overlayShape!
        .getPreferredSize(isEnabled, isDiscrete)
        .width;
    double trackHeight = sliderTheme.trackHeight!;
    assert(overlayWidth >= 0);
    assert(trackHeight >= 0);

    // If the track colors are transparent, then override only the track height
    // to maintain overall Slider width.
    if (sliderTheme.activeTrackColor == Colors.transparent &&
        sliderTheme.inactiveTrackColor == Colors.transparent) {
      trackHeight = 0;
    }

    final double trackLeft =
        offset.dx +
        (sliderTheme.padding == null
            ? math.max(overlayWidth / 2, thumbSize.width / 2)
            : (thumbSize.width / 2));
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackRight =
        trackLeft +
        parentBox.size.width -
        (sliderTheme.padding == null ? math.max(thumbSize.width, overlayWidth) : thumbSize.width);
    final double trackBottom = trackTop + trackHeight;
    // If the parentBox's size less than slider's size the trackRight will be less than trackLeft, so switch them.
    return Rect.fromLTRB(
      math.min(trackLeft, trackRight),
      trackTop,
      math.max(trackLeft, trackRight),
      trackBottom,
    );
  }
}

/// A [RangeSlider] track that's a simple rectangle.
///
/// It paints a solid colored rectangle, vertically centered in the
/// `parentBox`. The track rectangle extends to the bounds of the `parentBox`,
/// but is padded by the [RoundSliderOverlayShape] radius. The height is
/// defined by the [SliderThemeData.trackHeight]. The color is determined by the
/// [Slider]'s enabled state and the track segment's active state which are
/// defined by:
///   [SliderThemeData.activeTrackColor],
///   [SliderThemeData.inactiveTrackColor],
///   [SliderThemeData.disabledActiveTrackColor],
///   [SliderThemeData.disabledInactiveTrackColor].
///
/// {@macro flutter.material.RangeSliderTickMarkShape.paint.trackSegment}
///
/// ![A range slider widget, consisting of 5 divisions and showing the rectangular range slider track shape.](https://flutter.github.io/assets-for-api-docs/assets/material/rectangular_range_slider_track_shape.png)
///
/// See also:
///
///  * [RangeSlider], for the component that is meant to display this shape.
///  * [SliderThemeData], where an instance of this class is set to inform the
///    slider of the visual details of the its track.
///  * [RangeSliderTrackShape], which can be used to create custom shapes for
///    the [RangeSlider]'s track.
///  * [RoundedRectRangeSliderTrackShape], for a similar track with rounded
///    edges.
class RectangularRangeSliderTrackShape extends RangeSliderTrackShape
    with BaseRangeSliderTrackShape {
  /// Create a slider track with rectangular outer edges.
  ///
  /// The middle track segment is the selected range and is active, and the two
  /// outer track segments are inactive.
  const RectangularRangeSliderTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double>? enableAnimation,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    assert(sliderTheme.disabledActiveTrackColor != null);
    assert(sliderTheme.disabledInactiveTrackColor != null);
    assert(sliderTheme.activeTrackColor != null);
    assert(sliderTheme.inactiveTrackColor != null);
    assert(sliderTheme.rangeThumbShape != null);
    assert(enableAnimation != null);
    // Assign the track segment paints, which are left: active, right: inactive,
    // but reversed for right to left text.
    final ColorTween activeTrackColorTween = ColorTween(
      begin: sliderTheme.disabledActiveTrackColor,
      end: sliderTheme.activeTrackColor,
    );
    final ColorTween inactiveTrackColorTween = ColorTween(
      begin: sliderTheme.disabledInactiveTrackColor,
      end: sliderTheme.inactiveTrackColor,
    );
    final Paint activePaint = Paint()..color = activeTrackColorTween.evaluate(enableAnimation!)!;
    final Paint inactivePaint = Paint()..color = inactiveTrackColorTween.evaluate(enableAnimation)!;

    final (Offset leftThumbOffset, Offset rightThumbOffset) = switch (textDirection) {
      TextDirection.ltr => (startThumbCenter, endThumbCenter),
      TextDirection.rtl => (endThumbCenter, startThumbCenter),
    };

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final Rect leftTrackSegment = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      leftThumbOffset.dx,
      trackRect.bottom,
    );
    if (!leftTrackSegment.isEmpty) {
      context.canvas.drawRect(leftTrackSegment, inactivePaint);
    }
    final Rect middleTrackSegment = Rect.fromLTRB(
      leftThumbOffset.dx,
      trackRect.top,
      rightThumbOffset.dx,
      trackRect.bottom,
    );
    if (!middleTrackSegment.isEmpty) {
      context.canvas.drawRect(middleTrackSegment, activePaint);
    }
    final Rect rightTrackSegment = Rect.fromLTRB(
      rightThumbOffset.dx,
      trackRect.top,
      trackRect.right,
      trackRect.bottom,
    );
    if (!rightTrackSegment.isEmpty) {
      context.canvas.drawRect(rightTrackSegment, inactivePaint);
    }
  }
}

/// The default shape of a [RangeSlider]'s track.
///
/// It paints a solid colored rectangle with rounded edges, vertically centered
/// in the `parentBox`. The track rectangle extends to the bounds of the
/// `parentBox`, but is padded by the larger of [RoundSliderOverlayShape]'s
/// radius and [RoundRangeSliderThumbShape]'s radius. The height is defined by
/// the [SliderThemeData.trackHeight]. The color is determined by the
/// [RangeSlider]'s enabled state and the track segment's active state which are
/// defined by:
///   [SliderThemeData.activeTrackColor],
///   [SliderThemeData.inactiveTrackColor],
///   [SliderThemeData.disabledActiveTrackColor],
///   [SliderThemeData.disabledInactiveTrackColor].
///
/// {@macro flutter.material.RangeSliderTickMarkShape.paint.trackSegment}
///
/// ![A range slider widget, consisting of 5 divisions and showing the rounded rect range slider track shape.](https://flutter.github.io/assets-for-api-docs/assets/material/rounded_rect_range_slider_track_shape.png)
///
/// See also:
///
///  * [RangeSlider], for the component that is meant to display this shape.
///  * [SliderThemeData], where an instance of this class is set to inform the
///    slider of the visual details of the its track.
///  * [RangeSliderTrackShape], which can be used to create custom shapes for
///    the [RangeSlider]'s track.
///  * [RectangularRangeSliderTrackShape], for a similar track with sharp edges.
class RoundedRectRangeSliderTrackShape extends RangeSliderTrackShape
    with BaseRangeSliderTrackShape {
  /// Create a slider track with rounded outer edges.
  ///
  /// The middle track segment is the selected range and is active, and the two
  /// outer track segments are inactive.
  const RoundedRectRangeSliderTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
    double additionalActiveTrackHeight = 2,
  }) {
    assert(sliderTheme.disabledActiveTrackColor != null);
    assert(sliderTheme.disabledInactiveTrackColor != null);
    assert(sliderTheme.activeTrackColor != null);
    assert(sliderTheme.inactiveTrackColor != null);
    assert(sliderTheme.rangeThumbShape != null);

    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) {
      return;
    }

    // Assign the track segment paints, which are left: active, right: inactive,
    // but reversed for right to left text.
    final ColorTween activeTrackColorTween = ColorTween(
      begin: sliderTheme.disabledActiveTrackColor,
      end: sliderTheme.activeTrackColor,
    );
    final ColorTween inactiveTrackColorTween = ColorTween(
      begin: sliderTheme.disabledInactiveTrackColor,
      end: sliderTheme.inactiveTrackColor,
    );
    final Paint activePaint = Paint()..color = activeTrackColorTween.evaluate(enableAnimation)!;
    final Paint inactivePaint = Paint()..color = inactiveTrackColorTween.evaluate(enableAnimation)!;

    final (Offset leftThumbOffset, Offset rightThumbOffset) = switch (textDirection) {
      TextDirection.ltr => (startThumbCenter, endThumbCenter),
      TextDirection.rtl => (endThumbCenter, startThumbCenter),
    };
    final Size thumbSize = sliderTheme.rangeThumbShape!.getPreferredSize(isEnabled, isDiscrete);
    final double thumbRadius = thumbSize.width / 2;
    assert(thumbRadius > 0);

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Radius trackRadius = Radius.circular(trackRect.height / 2);

    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        trackRect.left,
        trackRect.top,
        leftThumbOffset.dx,
        trackRect.bottom,
        topLeft: trackRadius,
        bottomLeft: trackRadius,
      ),
      inactivePaint,
    );
    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        rightThumbOffset.dx,
        trackRect.top,
        trackRect.right,
        trackRect.bottom,
        topRight: trackRadius,
        bottomRight: trackRadius,
      ),
      inactivePaint,
    );
    context.canvas.drawRRect(
      RRect.fromLTRBR(
        leftThumbOffset.dx - (sliderTheme.trackHeight! / 2),
        trackRect.top - (additionalActiveTrackHeight / 2),
        rightThumbOffset.dx + (sliderTheme.trackHeight! / 2),
        trackRect.bottom + (additionalActiveTrackHeight / 2),
        trackRadius,
      ),
      activePaint,
    );
  }

  @override
  bool get isRounded => true;
}

/// The default shape of each [RangeSlider] tick mark.
///
/// Tick marks are only displayed if the slider is discrete, which can be done
/// by setting the [RangeSlider.divisions] to an integer value.
///
/// It paints a solid circle, centered on the track.
/// The color is determined by the [Slider]'s enabled state and track's active
/// states. These colors are defined in:
///   [SliderThemeData.activeTrackColor],
///   [SliderThemeData.inactiveTrackColor],
///   [SliderThemeData.disabledActiveTrackColor],
///   [SliderThemeData.disabledInactiveTrackColor].
///
/// ![A slider widget, consisting of 5 divisions and showing the round range slider tick mark shape.](https://flutter.github.io/assets-for-api-docs/assets/material/round_range_slider_tick_mark_shape.png)
///
/// See also:
///
///  * [RangeSlider], which includes tick marks defined by this shape.
///  * [SliderTheme], which can be used to configure the tick mark shape of all
///    sliders in a widget subtree.
class RoundRangeSliderTickMarkShape extends RangeSliderTickMarkShape {
  /// Create a range slider tick mark that draws a circle.
  const RoundRangeSliderTickMarkShape({this.tickMarkRadius});

  /// The preferred radius of the round tick mark.
  ///
  /// If it is not provided, then 1/4 of the [SliderThemeData.trackHeight] is used.
  final double? tickMarkRadius;

  @override
  Size getPreferredSize({required SliderThemeData sliderTheme, bool isEnabled = false}) {
    assert(sliderTheme.trackHeight != null);
    return Size.fromRadius(tickMarkRadius ?? sliderTheme.trackHeight! / 4);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    required TextDirection textDirection,
  }) {
    assert(sliderTheme.disabledActiveTickMarkColor != null);
    assert(sliderTheme.disabledInactiveTickMarkColor != null);
    assert(sliderTheme.activeTickMarkColor != null);
    assert(sliderTheme.inactiveTickMarkColor != null);

    final bool hasGap = sliderTheme.trackGap != null && sliderTheme.trackGap! > 0;
    final bool underThumb = startThumbCenter.dx == center.dx || endThumbCenter.dx == center.dx;
    if (hasGap && underThumb) {
      return;
    }
    final bool isBetweenThumbs = switch (textDirection) {
      TextDirection.ltr => startThumbCenter.dx < center.dx && center.dx < endThumbCenter.dx,
      TextDirection.rtl => endThumbCenter.dx < center.dx && center.dx < startThumbCenter.dx,
    };
    final Color? begin = isBetweenThumbs
        ? sliderTheme.disabledActiveTickMarkColor
        : sliderTheme.disabledInactiveTickMarkColor;
    final Color? end = isBetweenThumbs
        ? sliderTheme.activeTickMarkColor
        : sliderTheme.inactiveTickMarkColor;
    final Paint paint = Paint()
      ..color = ColorTween(begin: begin, end: end).evaluate(enableAnimation)!;

    // The tick marks are tiny circles that are the same height as the track.
    final double tickMarkRadius =
        getPreferredSize(isEnabled: isEnabled, sliderTheme: sliderTheme).width / 2;
    if (tickMarkRadius > 0) {
      context.canvas.drawCircle(center, tickMarkRadius, paint);
    }
  }
}

/// The default shape of a [RangeSlider]'s thumbs.
///
/// There is a shadow for the resting and pressed state.
///
/// ![A slider widget, consisting of 5 divisions and showing the round range slider thumb shape.](https://flutter.github.io/assets-for-api-docs/assets/material/round_range_slider_thumb_shape.png)
///
/// See also:
///
///  * [RangeSlider], which includes thumbs defined by this shape.
///  * [SliderTheme], which can be used to configure the thumb shapes of all
///    range sliders in a widget subtree.
class RoundRangeSliderThumbShape extends RangeSliderThumbShape {
  /// Create a slider thumb that draws a circle.
  const RoundRangeSliderThumbShape({
    this.enabledThumbRadius = 10.0,
    this.disabledThumbRadius,
    this.elevation = 1.0,
    this.pressedElevation = 6.0,
  });

  /// The preferred radius of the round thumb shape when the slider is enabled.
  ///
  /// If it is not provided, then the Material Design default of 10 is used.
  final double enabledThumbRadius;

  /// The preferred radius of the round thumb shape when the slider is disabled.
  ///
  /// If no disabledRadius is provided, then it is equal to the
  /// [enabledThumbRadius].
  final double? disabledThumbRadius;
  double get _disabledThumbRadius => disabledThumbRadius ?? enabledThumbRadius;

  /// The resting elevation adds shadow to the unpressed thumb.
  ///
  /// The default is 1.
  final double elevation;

  /// The pressed elevation adds shadow to the pressed thumb.
  ///
  /// The default is 6.
  final double pressedElevation;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(isEnabled ? enabledThumbRadius : _disabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb? thumb,
    bool? isPressed,
  }) {
    assert(sliderTheme.showValueIndicator != null);
    assert(sliderTheme.overlappingShapeStrokeColor != null);
    final Canvas canvas = context.canvas;
    final Tween<double> radiusTween = Tween<double>(
      begin: _disabledThumbRadius,
      end: enabledThumbRadius,
    );
    final ColorTween colorTween = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    );
    final double radius = radiusTween.evaluate(enableAnimation);
    final Tween<double> elevationTween = Tween<double>(begin: elevation, end: pressedElevation);

    // Add a stroke of 1dp around the circle if this thumb would overlap
    // the other thumb.
    if (isOnTop ?? false) {
      final Paint strokePaint = Paint()
        ..color = sliderTheme.overlappingShapeStrokeColor!
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius, strokePaint);
    }

    final Color color = colorTween.evaluate(enableAnimation)!;

    final double evaluatedElevation = isPressed!
        ? elevationTween.evaluate(activationAnimation)
        : elevation;
    final Path shadowPath = Path()
      ..addArc(
        Rect.fromCenter(center: center, width: 2 * radius, height: 2 * radius),
        0,
        math.pi * 2,
      );

    bool paintShadows = true;
    assert(() {
      if (debugDisableShadows) {
        _debugDrawShadow(canvas, shadowPath, evaluatedElevation);
        paintShadows = false;
      }
      return true;
    }());

    if (paintShadows) {
      canvas.drawShadow(shadowPath, Colors.black, evaluatedElevation, true);
    }

    canvas.drawCircle(center, radius, Paint()..color = color);
  }
}

/// Decides which thumbs (if any) should be selected.
///
/// The default finds the closest thumb, but if the thumbs are close to each
/// other, it waits for movement defined by [dx] to determine the selected
/// thumb.
///
/// Override [SliderThemeData.thumbSelector] for custom thumb selection.
typedef RangeThumbSelector =
    Thumb? Function(
      TextDirection textDirection,
      RangeValues values,
      double tapValue,
      Size thumbSize,
      Size trackSize,
      double dx,
    );

/// Object for representing range slider thumb values.
///
/// This object is passed into [RangeSlider.values] to set its values, and it
/// is emitted in [RangeSlider.onChanged], [RangeSlider.onChangeStart], and
/// [RangeSlider.onChangeEnd] when the values change.
@immutable
class RangeValues {
  /// Creates pair of start and end values.
  const RangeValues(this.start, this.end);

  /// The value of the start thumb.
  ///
  /// For LTR text direction, the start is the left thumb, and for RTL text
  /// direction, the start is the right thumb.
  final double start;

  /// The value of the end thumb.
  ///
  /// For LTR text direction, the end is the right thumb, and for RTL text
  /// direction, the end is the left thumb.
  final double end;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is RangeValues && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() {
    return '${objectRuntimeType(this, 'RangeValues')}($start, $end)';
  }
}

/// Object for setting range slider label values that appear in the value
/// indicator for each thumb.
///
/// Used in combination with [SliderThemeData.showValueIndicator] to display
/// labels above the thumbs.
@immutable
class RangeLabels {
  /// Creates pair of start and end labels.
  const RangeLabels(this.start, this.end);

  /// The label of the start thumb.
  ///
  /// For LTR text direction, the start is the left thumb, and for RTL text
  /// direction, the start is the right thumb.
  final String start;

  /// The label of the end thumb.
  ///
  /// For LTR text direction, the end is the right thumb, and for RTL text
  /// direction, the end is the left thumb.
  final String end;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is RangeLabels && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() {
    return '${objectRuntimeType(this, 'RangeLabels')}($start, $end)';
  }
}

void _debugDrawShadow(Canvas canvas, Path path, double elevation) {
  if (elevation > 0.0) {
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = elevation * 2.0,
    );
  }
}

// The gapped shape of a [RangeSlider]'s track.
///
/// The [GappedRangeSliderTrackShape] consists of active and inactive
/// tracks. The active track uses the [SliderThemeData.activeTrackColor] and the
/// inactive tracks uses the [SliderThemeData.inactiveTrackColor].
///
/// The track shape uses circular corner radius for the edge corners and a corner radius
/// of 2 pixels for the inside corners.
///
/// Between the active and inactive tracks there are gaps of size [SliderThemeData.trackGap].
/// If the [SliderThemeData.thumbShape] is [HandleRangeSliderThumbShape] and the thumb is pressed,
/// the thumb's width is reduced; as a result, the track gaps size in [GappedRangeSliderTrackShape]
/// is also reduced.
///
/// If [SliderThemeData.trackGap] is null, then the track gaps size defaults to 6 pixels.
///
/// If [ThemeData.useMaterial3] is true and [RangeSlider.year2023] is false, then the [RangeSlider]
/// will use [GappedRangeSliderTrackShape] as the default track shape.
///
/// See also:
///
///  * [RangeSlider], which includes a track defined by this shape.
///  * [SliderTheme], which can be used to configure the track shape of all
///    range sliders in a widget subtree.
class GappedRangeSliderTrackShape extends RangeSliderTrackShape with BaseRangeSliderTrackShape {
  /// Create a range slider track that draws 3 rounded rectangles with rounded outer edges.
  const GappedRangeSliderTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
    double additionalActiveTrackHeight = 2,
  }) {
    assert(sliderTheme.disabledActiveTrackColor != null);
    assert(sliderTheme.disabledInactiveTrackColor != null);
    assert(sliderTheme.activeTrackColor != null);
    assert(sliderTheme.inactiveTrackColor != null);
    assert(sliderTheme.rangeThumbShape != null);

    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) {
      return;
    }

    final ColorTween activeTrackColorTween = ColorTween(
      begin: sliderTheme.disabledActiveTrackColor,
      end: sliderTheme.activeTrackColor,
    );
    final ColorTween inactiveTrackColorTween = ColorTween(
      begin: sliderTheme.disabledInactiveTrackColor,
      end: sliderTheme.inactiveTrackColor,
    );

    final Paint activePaint = Paint()..color = activeTrackColorTween.evaluate(enableAnimation)!;
    final Paint inactivePaint = Paint()..color = inactiveTrackColorTween.evaluate(enableAnimation)!;

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Radius trackCornerRadius = Radius.circular(trackRect.shortestSide / 2);
    const Radius trackInsideCornerRadius = Radius.circular(2.0);

    final (Offset leftThumbOffset, Offset rightThumbOffset) = switch (textDirection) {
      TextDirection.ltr => (startThumbCenter, endThumbCenter),
      TextDirection.rtl => (endThumbCenter, startThumbCenter),
    };

    final Size thumbSize = sliderTheme.rangeThumbShape!.getPreferredSize(isEnabled, isDiscrete);
    final double thumbRadius = thumbSize.width / 2;
    assert(thumbRadius > 0);
    final double trackGap = sliderTheme.trackGap!;

    final RRect trackRRect = RRect.fromRectAndCorners(
      trackRect,
      topLeft: trackCornerRadius,
      bottomLeft: trackCornerRadius,
      topRight: trackCornerRadius,
      bottomRight: trackCornerRadius,
    );

    final RRect leftRRect = RRect.fromLTRBAndCorners(
      trackRect.left,
      trackRect.top,
      leftThumbOffset.dx - trackGap,
      trackRect.bottom,
      topLeft: trackCornerRadius,
      bottomLeft: trackCornerRadius,
      topRight: trackInsideCornerRadius,
      bottomRight: trackInsideCornerRadius,
    );

    final RRect rightRRect = RRect.fromLTRBAndCorners(
      rightThumbOffset.dx + trackGap,
      trackRect.top,
      trackRect.right,
      trackRect.bottom,
      topLeft: trackInsideCornerRadius,
      bottomLeft: trackInsideCornerRadius,
      topRight: trackCornerRadius,
      bottomRight: trackCornerRadius,
    );

    context.canvas
      ..save()
      ..clipRRect(trackRRect);
    final bool drawLeftTrack =
        startThumbCenter.dx > (leftRRect.left + (sliderTheme.trackHeight! / 2));
    final bool drawRightTrack =
        endThumbCenter.dx < (rightRRect.right - (sliderTheme.trackHeight! / 2));

    if (drawLeftTrack) {
      context.canvas.drawRRect(leftRRect, inactivePaint);
    }
    if (drawRightTrack) {
      context.canvas.drawRRect(rightRRect, inactivePaint);
    }

    if (leftThumbOffset.dx + trackGap < rightThumbOffset.dx - trackGap) {
      context.canvas.drawRRect(
        RRect.fromLTRBR(
          leftThumbOffset.dx + trackGap,
          trackRect.top,
          rightThumbOffset.dx - trackGap,
          trackRect.bottom,
          trackInsideCornerRadius,
        ),
        activePaint,
      );
    }

    context.canvas.restore();

    const double stopIndicatorRadius = 2.0;
    final double stopIndicatorTrailingSpace = sliderTheme.trackHeight! / 2;
    final Offset startStopIndicatorOffset = Offset(
      trackRect.centerLeft.dx + stopIndicatorTrailingSpace,
      trackRect.center.dy,
    );
    final Offset endStopIndicatorOffset = Offset(
      trackRect.centerRight.dx - stopIndicatorTrailingSpace,
      trackRect.center.dy,
    );

    final bool showStartStopIndicator = startThumbCenter.dx > startStopIndicatorOffset.dx;
    if (showStartStopIndicator && !isDiscrete) {
      final Rect stopIndicatorRect = Rect.fromCircle(
        center: startStopIndicatorOffset,
        radius: stopIndicatorRadius,
      );
      context.canvas.drawCircle(stopIndicatorRect.center, stopIndicatorRadius, activePaint);
    }

    final bool showEndStopIndicator = endThumbCenter.dx < endStopIndicatorOffset.dx;
    if (showEndStopIndicator && !isDiscrete) {
      final Rect stopIndicatorRect = Rect.fromCircle(
        center: endStopIndicatorOffset,
        radius: stopIndicatorRadius,
      );
      context.canvas.drawCircle(stopIndicatorRect.center, stopIndicatorRadius, activePaint);
    }
  }

  @override
  bool get isRounded => true;
}

/// The bar shape of [RangeSlider]'s thumbs.
///
/// When the range slider is enabled, the [ColorScheme.primary] color is used for the
/// thumb. When the slider is disabled, the [ColorScheme.onSurface] color with an
/// opacity of 0.38 is used for the thumb.
///
/// The thumb bar shape width is reduced when the thumb is pressed.
///
/// If [SliderThemeData.thumbSize] is null, then the thumb size is 4 pixels for the width
/// and 44 pixels for the height.
///
/// If [ThemeData.useMaterial3] is true and [RangeSlider.year2023] is false, then the [RangeSlider]
/// will use [HandleRangeSliderThumbShape] as the default track shape.
///
/// See also:
///
///  * [RangeSlider], which includes thumbs defined by this shape.
///  * [SliderTheme], which can be used to configure the thumbs shape of all
///    range sliders in a widget subtree.
class HandleRangeSliderThumbShape extends RangeSliderThumbShape {
  /// Create a range slider thumb that draws a bar.
  const HandleRangeSliderThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(4.0, 44.0);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb? thumb,
    bool? isPressed,
  }) {
    assert(sliderTheme.showValueIndicator != null);
    assert(sliderTheme.overlappingShapeStrokeColor != null);
    assert(sliderTheme.disabledThumbColor != null);
    assert(sliderTheme.thumbColor != null);
    assert(sliderTheme.thumbSize != null);

    final ColorTween colorTween = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    );
    final Color color = colorTween.evaluate(enableAnimation)!;
    final Canvas canvas = context.canvas;

    final Size thumbSize = sliderTheme.thumbSize!.resolve(
      <WidgetState>{},
    )!; // This is resolved in the paint method.
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: thumbSize.width, height: thumbSize.height),
      Radius.circular(thumbSize.shortestSide / 2),
    );

    canvas.drawRRect(rrect, Paint()..color = color);
  }
}

/// The rounded rectangle shape of a [RangeSlider]'s value indicators.
///
/// If the [SliderThemeData.valueIndicatorColor] is null, then the shape uses the [ColorScheme.inverseSurface]
/// color to draw the value indicator.
///
/// If the [SliderThemeData.valueIndicatorTextStyle] is null, then the indicator label text style
/// defaults to [TextTheme.labelMedium] with the color set to [ColorScheme.onInverseSurface]. If the
/// [ThemeData.useMaterial3] is set to false, then the indicator label text style defaults to
/// [TextTheme.bodyLarge] with the color set to [ColorScheme.onInverseSurface].
///
/// If the [SliderThemeData.valueIndicatorStrokeColor] is provided, then the value indicator is drawn with a
/// stroke border with the color provided.
///
/// If [ThemeData.useMaterial3] is true and [RangeSlider.year2023] is false, then the [RangeSlider]
/// will use [RoundedRectRangeSliderValueIndicatorShape] as the default value indicators shape.
///
/// See also:
///
///  * [RangeSlider], which includes value indicators defined by this shape.
///  * [SliderTheme], which can be used to configure the range slider value indicators
///    of all range sliders in a widget subtree.
class RoundedRectRangeSliderValueIndicatorShape extends RangeSliderValueIndicatorShape {
  /// Create range slider value indicators that resembles a rounded rectangle.
  const RoundedRectRangeSliderValueIndicatorShape();

  static const _RoundedRectSliderValueIndicatorPathPainter _pathPainter =
      _RoundedRectSliderValueIndicatorPathPainter();

  @override
  Size getPreferredSize(
    bool isEnabled,
    bool isDiscrete, {
    TextPainter? labelPainter,
    double? textScaleFactor,
  }) {
    assert(labelPainter != null);
    assert(textScaleFactor != null && textScaleFactor >= 0);
    return _pathPainter.getPreferredSize(labelPainter!, textScaleFactor!);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool? isDiscrete,
    bool? isOnTop,
    required TextPainter labelPainter,
    double? textScaleFactor,
    Size? sizeWithOverflow,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    double? value,
    Thumb? thumb,
  }) {
    assert(textScaleFactor != null);
    assert(sizeWithOverflow != null);
    assert(sliderTheme.valueIndicatorColor != null);

    final Canvas canvas = context.canvas;
    final double scale = activationAnimation.value;
    _pathPainter.paint(
      parentBox: parentBox,
      canvas: canvas,
      center: center,
      scale: scale,
      labelPainter: labelPainter,
      textScaleFactor: textScaleFactor!,
      sizeWithOverflow: sizeWithOverflow!,
      backgroundPaintColor: sliderTheme.valueIndicatorColor!,
      strokePaintColor: isOnTop!
          ? sliderTheme.overlappingShapeStrokeColor
          : sliderTheme.valueIndicatorStrokeColor,
    );
  }
}

/// The shape of a Material 3 [RangeSlider]'s value indicators.
///
/// If the [SliderThemeData.valueIndicatorColor] is null, then the shape uses the [ColorScheme.primary]
/// color to draw the value indicator.
///
/// If the [SliderThemeData.valueIndicatorTextStyle] is null, then the indicator label text style
/// defaults to [TextTheme.labelMedium] with the color set to [ColorScheme.onPrimary]. If the
/// [ThemeData.useMaterial3] is set to false, then the indicator label text style defaults to
/// [TextTheme.bodyLarge] with the color set to [ColorScheme.onInverseSurface].
///
/// If the [SliderThemeData.valueIndicatorStrokeColor] is provided, then the value indicator is drawn with a
/// stroke border with the color provided.
///
/// See also:
///
///  * [RangeSlider], which includes value indicators defined by this shape.
///  * [SliderTheme], which can be used to configure the range slider value indicators
///    of all range sliders in a widget subtree.
class DropRangeSliderValueIndicatorShape extends RangeSliderValueIndicatorShape {
  /// Create a range slider value indicator that resembles a drop shape.
  const DropRangeSliderValueIndicatorShape();

  static const _DropSliderValueIndicatorPathPainter _pathPainter =
      _DropSliderValueIndicatorPathPainter();

  @override
  Size getPreferredSize(
    bool isEnabled,
    bool isDiscrete, {
    TextPainter? labelPainter,
    double? textScaleFactor,
  }) {
    assert(labelPainter != null);
    assert(textScaleFactor != null && textScaleFactor >= 0);
    return _pathPainter.getPreferredSize(labelPainter!, textScaleFactor!);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool? isDiscrete,
    bool? isOnTop,
    required TextPainter labelPainter,
    double? textScaleFactor,
    Size? sizeWithOverflow,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    double? value,
    Thumb? thumb,
  }) {
    final Canvas canvas = context.canvas;
    final double scale = activationAnimation.value;
    _pathPainter.paint(
      parentBox: parentBox,
      canvas: canvas,
      center: center,
      scale: scale,
      labelPainter: labelPainter,
      textScaleFactor: textScaleFactor!,
      sizeWithOverflow: sizeWithOverflow!,
      backgroundPaintColor: sliderTheme.valueIndicatorColor!,
      strokePaintColor: isOnTop!
          ? sliderTheme.overlappingShapeStrokeColor
          : sliderTheme.valueIndicatorStrokeColor,
    );
  }
}

class _RoundedRectSliderValueIndicatorPathPainter {
  const _RoundedRectSliderValueIndicatorPathPainter();

  static const double _labelPadding = 10.0;
  static const double _preferredHeight = 32.0;
  static const double _minLabelWidth = 16.0;
  static const double _rectYOffset = 10.0;
  static const double _bottomTipYOffset = 16.0;
  static const double _preferredHalfHeight = _preferredHeight / 2;

  Size getPreferredSize(TextPainter labelPainter, double textScaleFactor) {
    final double width =
        math.max(_minLabelWidth, labelPainter.width) + (_labelPadding * 2) * textScaleFactor;
    return Size(width, _preferredHeight * textScaleFactor);
  }

  double getHorizontalShift({
    required RenderBox parentBox,
    required Offset center,
    required TextPainter labelPainter,
    required double textScaleFactor,
    required Size sizeWithOverflow,
    required double scale,
  }) {
    assert(!sizeWithOverflow.isEmpty);

    const double edgePadding = 8.0;
    final double rectangleWidth = _upperRectangleWidth(labelPainter, scale);

    /// Value indicator draws on the Overlay and by using the global Offset
    /// we are making sure we use the bounds of the Overlay instead of the Slider.
    final Offset globalCenter = parentBox.localToGlobal(center);

    // The rectangle must be shifted towards the center so that it minimizes the
    // chance of it rendering outside the bounds of the render box. If the shift
    // is negative, then the lobe is shifted from right to left, and if it is
    // positive, then the lobe is shifted from left to right.
    final double overflowLeft = math.max(0, rectangleWidth / 2 - globalCenter.dx + edgePadding);
    final double overflowRight = math.max(
      0,
      rectangleWidth / 2 - (sizeWithOverflow.width - globalCenter.dx - edgePadding),
    );

    if (rectangleWidth < sizeWithOverflow.width) {
      return overflowLeft - overflowRight;
    } else if (overflowLeft - overflowRight > 0) {
      return overflowLeft - (edgePadding * textScaleFactor);
    } else {
      return -overflowRight + (edgePadding * textScaleFactor);
    }
  }

  double _upperRectangleWidth(TextPainter labelPainter, double scale) {
    final double unscaledWidth = math.max(_minLabelWidth, labelPainter.width) + (_labelPadding * 2);
    return unscaledWidth * scale;
  }

  void paint({
    required RenderBox parentBox,
    required Canvas canvas,
    required Offset center,
    required double scale,
    required TextPainter labelPainter,
    required double textScaleFactor,
    required Size sizeWithOverflow,
    required Color backgroundPaintColor,
    Color? strokePaintColor,
  }) {
    if (scale == 0.0) {
      // Zero scale essentially means "do not draw anything", so it's safe to just return.
      return;
    }
    assert(!sizeWithOverflow.isEmpty);

    final double rectangleWidth = _upperRectangleWidth(labelPainter, scale);
    final double horizontalShift = getHorizontalShift(
      parentBox: parentBox,
      center: center,
      labelPainter: labelPainter,
      textScaleFactor: textScaleFactor,
      sizeWithOverflow: sizeWithOverflow,
      scale: scale,
    );

    final Rect upperRect = Rect.fromLTWH(
      -rectangleWidth / 2 + horizontalShift,
      -_rectYOffset - _preferredHeight,
      rectangleWidth,
      _preferredHeight,
    );

    final Paint fillPaint = Paint()..color = backgroundPaintColor;

    canvas.save();
    // Prepare the canvas for the base of the tooltip, which is relative to the
    // center of the thumb.
    canvas.translate(center.dx, center.dy - _bottomTipYOffset);
    canvas.scale(scale, scale);

    final RRect rrect = RRect.fromRectAndRadius(upperRect, Radius.circular(upperRect.height / 2));
    if (strokePaintColor != null) {
      final Paint strokePaint = Paint()
        ..color = strokePaintColor
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(rrect, strokePaint);
    }

    canvas.drawRRect(rrect, fillPaint);

    // The label text is centered within the value indicator.
    final double bottomTipToUpperRectTranslateY = -_preferredHalfHeight / 2 - upperRect.height;
    canvas.translate(0, bottomTipToUpperRectTranslateY);
    final Offset boxCenter = Offset(horizontalShift, upperRect.height / 2.3);
    final Offset halfLabelPainterOffset = Offset(labelPainter.width / 2, labelPainter.height / 2);
    final Offset labelOffset = boxCenter - halfLabelPainterOffset;
    labelPainter.paint(canvas, labelOffset);
    canvas.restore();
  }
}

class _DropSliderValueIndicatorPathPainter {
  const _DropSliderValueIndicatorPathPainter();

  static const double _triangleHeight = 10.0;
  static const double _labelPadding = 8.0;
  static const double _preferredHeight = 32.0;
  static const double _minLabelWidth = 20.0;
  static const double _minRectHeight = 28.0;
  static const double _rectYOffset = 6.0;
  static const double _bottomTipYOffset = 16.0;
  static const double _preferredHalfHeight = _preferredHeight / 2;
  static const double _upperRectRadius = 4;

  Size getPreferredSize(TextPainter labelPainter, double textScaleFactor) {
    final double width =
        math.max(_minLabelWidth, labelPainter.width) + _labelPadding * 2 * textScaleFactor;
    return Size(width, _preferredHeight * textScaleFactor);
  }

  double getHorizontalShift({
    required RenderBox parentBox,
    required Offset center,
    required TextPainter labelPainter,
    required double textScaleFactor,
    required Size sizeWithOverflow,
    required double scale,
  }) {
    assert(!sizeWithOverflow.isEmpty);

    const double edgePadding = 8.0;
    final double rectangleWidth = _upperRectangleWidth(labelPainter, scale);

    /// Value indicator draws on the Overlay and by using the global Offset
    /// we are making sure we use the bounds of the Overlay instead of the Slider.
    final Offset globalCenter = parentBox.localToGlobal(center);

    // The rectangle must be shifted towards the center so that it minimizes the
    // chance of it rendering outside the bounds of the render box. If the shift
    // is negative, then the lobe is shifted from right to left, and if it is
    // positive, then the lobe is shifted from left to right.
    final double overflowLeft = math.max(0, rectangleWidth / 2 - globalCenter.dx + edgePadding);
    final double overflowRight = math.max(
      0,
      rectangleWidth / 2 - (sizeWithOverflow.width - globalCenter.dx - edgePadding),
    );

    if (rectangleWidth < sizeWithOverflow.width) {
      return overflowLeft - overflowRight;
    } else if (overflowLeft - overflowRight > 0) {
      return overflowLeft - (edgePadding * textScaleFactor);
    } else {
      return -overflowRight + (edgePadding * textScaleFactor);
    }
  }

  double _upperRectangleWidth(TextPainter labelPainter, double scale) {
    final double unscaledWidth = math.max(_minLabelWidth, labelPainter.width) + _labelPadding;
    return unscaledWidth * scale;
  }

  BorderRadius _adjustBorderRadius(Rect rect) {
    const double rectness = 0.0;
    return BorderRadius.lerp(
      BorderRadius.circular(_upperRectRadius),
      BorderRadius.all(Radius.circular(rect.shortestSide / 2.0)),
      1.0 - rectness,
    )!;
  }

  void paint({
    required RenderBox parentBox,
    required Canvas canvas,
    required Offset center,
    required double scale,
    required TextPainter labelPainter,
    required double textScaleFactor,
    required Size sizeWithOverflow,
    required Color backgroundPaintColor,
    Color? strokePaintColor,
  }) {
    if (scale == 0.0) {
      // Zero scale essentially means "do not draw anything", so it's safe to just return.
      return;
    }
    assert(!sizeWithOverflow.isEmpty);
    final double rectangleWidth = _upperRectangleWidth(labelPainter, scale);
    final double horizontalShift = getHorizontalShift(
      parentBox: parentBox,
      center: center,
      labelPainter: labelPainter,
      textScaleFactor: textScaleFactor,
      sizeWithOverflow: sizeWithOverflow,
      scale: scale,
    );
    final Rect upperRect = Rect.fromLTWH(
      -rectangleWidth / 2 + horizontalShift,
      -_rectYOffset - _minRectHeight,
      rectangleWidth,
      _minRectHeight,
    );

    final Paint fillPaint = Paint()..color = backgroundPaintColor;

    canvas.save();
    canvas.translate(center.dx, center.dy - _bottomTipYOffset);
    canvas.scale(scale, scale);

    final BorderRadius adjustedBorderRadius = _adjustBorderRadius(upperRect);
    final RRect borderRect = adjustedBorderRadius
        .resolve(labelPainter.textDirection)
        .toRRect(upperRect);
    final Path trianglePath = Path()
      ..lineTo(-_triangleHeight, -_triangleHeight)
      ..lineTo(_triangleHeight, -_triangleHeight)
      ..close();
    trianglePath.addRRect(borderRect);

    if (strokePaintColor != null) {
      final Paint strokePaint = Paint()
        ..color = strokePaintColor
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(trianglePath, strokePaint);
    }

    canvas.drawPath(trianglePath, fillPaint);

    // The label text is centered within the value indicator.
    final double bottomTipToUpperRectTranslateY = -_preferredHalfHeight / 2 - upperRect.height;
    canvas.translate(0, bottomTipToUpperRectTranslateY);
    final Offset boxCenter = Offset(horizontalShift, upperRect.height / 1.75);
    final Offset halfLabelPainterOffset = Offset(labelPainter.width / 2, labelPainter.height / 2);
    final Offset labelOffset = boxCenter - halfLabelPainterOffset;
    labelPainter.paint(canvas, labelOffset);
    canvas.restore();
  }
}

import 'dart:math';
import 'dart:ui' as ui show lerpDouble;

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/src/painters/customizable_painter.dart';
import 'package:smooth_page_indicator/src/painters/indicator_painter.dart';

import 'indicator_effect.dart';

/// Signature for a function that returns color
/// for each [index]
typedef ColorBuilder = Color Function(int index);

/// Holds painting configuration to be used by [CustomizablePainter]
class CustomizableEffect extends IndicatorEffect {
  /// Holds painting decoration for inactive dots
  final DotDecoration dotDecoration;

  /// Holds painting decoration for active dots
  final DotDecoration activeDotDecoration;

  /// Builds dynamic colors for active dot
  final ColorBuilder? activeColorOverride;

  /// Builds dynamic colors for inactive dots
  final ColorBuilder? inActiveColorOverride;

  /// The space between two dots
  final double spacing;

  /// Default constructor
  const CustomizableEffect({
    required this.dotDecoration,
    required this.activeDotDecoration,
    this.activeColorOverride,
    this.spacing = 8,
    this.inActiveColorOverride,
  });

  @override
  Size calculateSize(int count) {
    final activeDotWidth =
        activeDotDecoration.width + activeDotDecoration.dotBorder.neededSpace;
    final dotWidth = dotDecoration.width + dotDecoration.dotBorder.neededSpace;

    final maxWidth =
        dotWidth * (count - 1) + (spacing * count) + activeDotWidth;

    final offsetSpace =
        (dotDecoration.verticalOffset - activeDotDecoration.verticalOffset)
            .abs();
    final maxHeight = max(
      dotDecoration.height + offsetSpace + dotDecoration.dotBorder.neededSpace,
      activeDotDecoration.height +
          offsetSpace +
          activeDotDecoration.dotBorder.neededSpace,
    );
    return Size(maxWidth, maxHeight);
  }

  @override
  IndicatorPainter buildPainter(int count, double offset) {
    return CustomizablePainter(count: count, offset: offset, effect: this);
  }

  @override
  int hitTestDots(double dx, int count, double current) {
    var anchor = -spacing / 2;
    for (var index = 0; index < count; index++) {
      var dotWidth = dotDecoration.width + dotDecoration.dotBorder.neededSpace;
      if (index == current) {
        dotWidth = activeDotDecoration.width +
            activeDotDecoration.dotBorder.neededSpace;
      }

      var widthBound = dotWidth + spacing;
      if (dx <= (anchor += widthBound)) {
        return index;
      }
    }
    return -1;
  }
}

/// Holds dot painting specs
class DotDecoration {
  /// The border radius of the dot
  final BorderRadius borderRadius;

  /// The color of the dot
  final Color color;

  /// The dotBorder configuration of the dot
  final DotBorder dotBorder;

  /// The vertical offset of the dot
  final double verticalOffset;

  /// The rotation angle of the dot
  final double rotationAngle;

  /// The width of the dot
  final double width;

  /// the height of the dot
  final double height;

  /// Default constructor
  const DotDecoration(
      {this.borderRadius = BorderRadius.zero,
      this.color = Colors.white,
      this.dotBorder = DotBorder.none,
      this.verticalOffset = 0.0,
      this.rotationAngle = 0.0,
      this.width = 8,
      this.height = 8});

  /// Lerps the value between active dot and prev-active dot
  static DotDecoration lerp(DotDecoration a, DotDecoration b, double t) {
    return DotDecoration(
        borderRadius: BorderRadius.lerp(a.borderRadius, b.borderRadius, t)!,
        width: ui.lerpDouble(a.width, b.width, t) ?? 0.0,
        height: ui.lerpDouble(a.height, b.height, t) ?? 0.0,
        color: Color.lerp(a.color, b.color, t)!,
        dotBorder: DotBorder.lerp(a.dotBorder, b.dotBorder, t),
        verticalOffset:
            ui.lerpDouble(a.verticalOffset, b.verticalOffset, t) ?? 0.0,
        rotationAngle:
            ui.lerpDouble(a.rotationAngle, b.rotationAngle, t) ?? 0.0);
  }

  /// Builds a new instance with the given
  /// override values
  DotDecoration copyWith({
    BorderRadius? borderRadius,
    double? width,
    double? height,
    Color? color,
    DotBorder? dotBorder,
    double? verticalOffset,
    double? rotationAngle,
  }) {
    return DotDecoration(
      borderRadius: borderRadius ?? this.borderRadius,
      width: width ?? this.width,
      height: height ?? this.height,
      color: color ?? this.color,
      dotBorder: dotBorder ?? this.dotBorder,
      verticalOffset: verticalOffset ?? this.verticalOffset,
      rotationAngle: rotationAngle ?? this.rotationAngle,
    );
  }
}

/// The variants of dot borders
enum DotBorderType {
  /// Draw a sold border
  solid,

  /// Draw nothing
  none
}

/// Holds dot-border painting specs
class DotBorder {
  /// The thinness of the border line
  final double width;

  /// The color of the border
  final Color color;

  /// The padding between the dot and the border
  final double padding;

  /// The border variant
  final DotBorderType type;

  /// Default constructor
  const DotBorder({
    this.width = 1.0,
    this.color = Colors.black87,
    this.padding = 0.0,
    this.type = DotBorderType.solid,
  });

  /// Calculates the needed gap based on [type]
  double get neededSpace =>
      type == DotBorderType.none ? 0.0 : (width / 2 + (padding * 2));

  /// Builds an instance with type [DotBorderType.none]
  static const none = DotBorder._none();

  const DotBorder._none()
      : width = 0.0,
        color = Colors.transparent,
        padding = 0.0,
        type = DotBorderType.none;

  /// Lerps the value between active dot border and prev-active dot's border
  static DotBorder lerp(DotBorder a, DotBorder b, double t) {
    if (t == 0.0) {
      return a;
    }
    if (t == 1.0) {
      return b;
    }
    return DotBorder(
        color: Color.lerp(a.color, b.color, t)!,
        width: ui.lerpDouble(a.width, b.width, t)!,
        padding: ui.lerpDouble(a.padding, b.padding, t)!);
  }
}

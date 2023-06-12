import 'dart:math';
import 'dart:ui' as ui show lerpDouble;

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/src/painters/customizable_painter.dart';
import 'package:smooth_page_indicator/src/painters/indicator_painter.dart';

import 'indicator_effect.dart';

typedef ColorBuilder = Color Function(int index);

class CustomizableEffect extends IndicatorEffect {
  final DotDecoration dotDecoration;
  final DotDecoration activeDotDecoration;
  final ColorBuilder? activeColorOverride, inActiveColorOverride;
  final double spacing;

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

class DotDecoration {
  final BorderRadius borderRadius;
  final Color color;
  final DotBorder dotBorder;
  final double verticalOffset, rotationAngle, width, height;

  const DotDecoration(
      {this.borderRadius = BorderRadius.zero,
      this.color = Colors.white,
      this.dotBorder = DotBorder.none,
      this.verticalOffset = 0.0,
      this.rotationAngle = 0.0,
      this.width = 8,
      this.height = 8});

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

enum DotBorderType { solid, none }

class DotBorder {
  final double width;
  final Color color;
  final double padding;
  final DotBorderType type;

  const DotBorder({
    this.width = 1.0,
    this.color = Colors.black87,
    this.padding = 0.0,
    this.type = DotBorderType.solid,
  });

  double get neededSpace =>
      type == DotBorderType.none ? 0.0 : (width / 2 + (padding * 2));
  static const none = DotBorder._none();

  const DotBorder._none()
      : width = 0.0,
        color = Colors.transparent,
        padding = 0.0,
        type = DotBorderType.none;

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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/src/effects/customizable_effect.dart';

import 'indicator_painter.dart';

class CustomizablePainter extends IndicatorPainter {
  final CustomizableEffect effect;
  final int count;

  CustomizablePainter({
    required double offset,
    required this.effect,
    required this.count,
  }) : super(offset);

  @override
  void paint(Canvas canvas, Size size) {
    var activeDotDecoration = effect.activeDotDecoration;
    var dotDecoration = effect.dotDecoration;
    final current = offset.floor();

    final dotOffset = offset - current;
    final maxVerticalOffset = max(
      activeDotDecoration.verticalOffset,
      dotDecoration.verticalOffset,
    );

    var yTranslation = 0.0;
    if (activeDotDecoration.verticalOffset >= dotDecoration.verticalOffset) {
      yTranslation =
          activeDotDecoration.verticalOffset - dotDecoration.verticalOffset;
    } else {
      yTranslation =
          dotDecoration.verticalOffset - activeDotDecoration.verticalOffset;
    }
    canvas.translate(0, -maxVerticalOffset + yTranslation / 2);

    var drawingOffset = effect.spacing / 2;

    for (var i = 0; i < count; i++) {
      if (effect.inActiveColorOverride != null) {
        dotDecoration = dotDecoration.copyWith(
            color: effect.inActiveColorOverride!.call(i));
      }
      if (effect.activeColorOverride != null) {
        activeDotDecoration = activeDotDecoration.copyWith(
            color: effect.activeColorOverride!.call(i));
      }
      var decoration = dotDecoration;
      if (i == current) {
        decoration =
            DotDecoration.lerp(activeDotDecoration, dotDecoration, dotOffset);
      } else if (i - 1 == current || (i == 0 && offset > count - 1)) {
        decoration =
            DotDecoration.lerp(dotDecoration, activeDotDecoration, dotOffset);
      }

      final xPos = drawingOffset + decoration.dotBorder.neededSpace / 2;
      final yPos = (size.height / 2) + decoration.verticalOffset;

      final rRect = RRect.fromLTRBAndCorners(
        xPos,
        yPos - decoration.height / 2,
        xPos + decoration.width,
        yPos + decoration.height / 2,
        topLeft: decoration.borderRadius.topLeft,
        topRight: decoration.borderRadius.topRight,
        bottomLeft: decoration.borderRadius.bottomLeft,
        bottomRight: decoration.borderRadius.bottomRight,
      );

      var scaledRect = rRect.outerRect.inflate(decoration.dotBorder.padding);
      final scaleRatioX = scaledRect.width / rRect.width;
      final scaleRatioY = scaledRect.height / rRect.height;

      final scaledRRect = RRect.fromRectAndCorners(
        scaledRect,
        topLeft: Radius.elliptical(
            rRect.tlRadiusX * scaleRatioX, rRect.tlRadiusY * scaleRatioY),
        topRight: Radius.elliptical(
            rRect.trRadiusX * scaleRatioX, rRect.trRadiusY * scaleRatioY),
        bottomRight: Radius.elliptical(
            rRect.brRadiusX * scaleRatioX, rRect.brRadiusY * scaleRatioY),
        bottomLeft: Radius.elliptical(
            rRect.blRadiusX * scaleRatioX, rRect.blRadiusY * scaleRatioY),
      );

      drawingOffset = scaledRRect.right + effect.spacing;

      var path = Path()..addRRect(rRect);

      final matrix4 = Matrix4.identity();
      if (decoration.rotationAngle != 0) {
        matrix4.rotateAngle(
          decoration.rotationAngle,
          origin: Offset(rRect.right - (rRect.width / 2), yPos),
        );
      }

      canvas.drawPath(
        path.transform(matrix4.storage),
        Paint()..color = decoration.color,
      );

      final borerPaint = Paint()
        ..strokeWidth = decoration.dotBorder.width
        ..style = PaintingStyle.stroke
        ..color = decoration.dotBorder.color;

      final borderPath = Path()..addRRect(scaledRRect);

      canvas.drawPath(
        borderPath.transform(matrix4.storage),
        borerPaint,
      );
    }
  }
}

extension Matrix4X on Matrix4 {
  Matrix4 rotateAngle(double angle, {Offset? origin}) {
    final angleRadians = angle * pi / 180;

    if (angleRadians == 0.0) {
      return this;
    } else if ((origin == null) || (origin.dx == 0.0 && origin.dy == 0.0)) {
      return this..rotateZ(angleRadians);
    } else {
      return this
        ..translate(origin.dx, origin.dy)
        ..multiply(Matrix4.rotationZ(angleRadians))
        ..translate(-origin.dx, -origin.dy);
    }
  }
}

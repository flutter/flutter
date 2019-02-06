import 'dart:ui' show Canvas, Offset, Paint, PaintingStyle, Path, PictureRecorder, RRect, Rect;

import 'package:flutter/src/material/colors.dart';

/// Trigger common draw operations to warm up Skia shader compilation cache.
///
/// When Skia first sees a certain type of draw operation, it needs to compile
/// the corresponding shader. The compilation can be slow (20ms-200ms). Having
/// that time as a startup latency is much better than having a jank in the
/// middle of an animation.
///
/// Therefore we use this (by default) in [SchedulerBinding.scheduleWarmUpFrame]
/// to move common shader compilations from animation time to startup time.
/// Alternatively, [customShaderWarmUp] can be provided to [runApp] to replace
/// this default warm up function.
void defaultShaderWarmUp(Canvas canvas) {
  final Path path = Path();
  path.moveTo(20, 60);
  path.quadraticBezierTo(60, 20, 60, 60);
  path.close();
  path.moveTo(60, 20);
  path.quadraticBezierTo(60, 60, 20, 60);

  final RRect rrect = RRect.fromLTRBXY(20, 20, 60, 60, 10, 10);
  final Path rrectPath = Path()..addRRect(rrect);

  final Path circlePath = Path()..addOval(Rect.fromCircle(center: const Offset(40, 40), radius: 20));

  final List<Path> paths = <Path>[path, rrectPath, circlePath];

  final PictureRecorder recorder = PictureRecorder();
  final Canvas canvas = Canvas(recorder);

  final Paint paint = Paint();
  paint.strokeWidth = 10;
  paint.isAntiAlias = true;

  for (Path path in paths) {
    canvas.save();
    for (PaintingStyle paintingStyle in PaintingStyle.values) {
      paint.style = paintingStyle;
      canvas.drawPath(path, paint);
      canvas.translate(80, 0);
    }
    canvas.restore();
    canvas.translate(0, 80);
  }

  canvas.drawShadow(rrectPath, Colors.black, 10.0, true);
  canvas.translate(80, 0);
  canvas.drawShadow(rrectPath, Colors.black, 10.0, false);
}


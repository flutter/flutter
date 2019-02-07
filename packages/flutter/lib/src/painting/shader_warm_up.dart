import 'dart:ui';

import 'package:flutter/src/material/colors.dart';

/// Signature to warm up GPU shader compilation cache.
///
/// To warm up shaders for a specific draw function, call it with the provided
/// [canvas]. For example, to warm up path rendering shaders, call
/// `canvas.drawPath` with desired paths. Assume that [canvas] has a size of
/// 1000x1000. Drawing outside the range may be clipped.
///
/// See also [defaultShaderWarmUp].
typedef ShaderWarmUp = void Function(Canvas canvas);

/// Trigger common draw operations to warm up GPU shader compilation cache.
///
/// When Skia first sees a certain type of draw operations on GPU, it needs to
/// compile the corresponding shader. The compilation can be slow (20ms-200ms).
/// Having that time as a startup latency is much better than having a jank in
/// the middle of an animation.
///
/// Therefore we use this (by default) in [SchedulerBinding.scheduleWarmUpFrame]
/// to move common shader compilations from animation time to startup time.
/// Alternatively, [customShaderWarmUp] can be provided to [runApp] to replace
/// this default warm up function.
ShaderWarmUp defaultShaderWarmUp = (Canvas canvas) {
  // The following path is copied from
  // https://skia.org/user/api/SkCanvas_Reference#SkCanvas_drawPath
  final Path path = Path();
  path.moveTo(20, 60);
  path.quadraticBezierTo(60, 20, 60, 60);
  path.close();
  path.moveTo(60, 20);
  path.quadraticBezierTo(60, 60, 20, 60);

  final RRect rrect = RRect.fromLTRBXY(20, 20, 60, 60, 10, 10);
  final Path rrectPath = Path()..addRRect(rrect);

  final Path circlePath = Path()..addOval(
    Rect.fromCircle(center: const Offset(40, 40), radius: 20)
  );

  final List<Path> paths = <Path>[path, rrectPath, circlePath];

  final Paint paint = Paint();
  paint.strokeWidth = 10;
  paint.isAntiAlias = true;

  // Warm up path stroke and fill shaders.
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

  // Warm up shadow shaders.
  canvas.save();
  canvas.drawShadow(rrectPath, Colors.black, 10.0, true);
  canvas.translate(80, 0);
  canvas.drawShadow(rrectPath, Colors.black, 10.0, false);
  canvas.restore();

  // Warm up text shaders.
  canvas.translate(0, 80);
  final ParagraphBuilder paragraphBuilder = ParagraphBuilder(
    ParagraphStyle(textDirection: TextDirection.ltr),
  )..pushStyle(TextStyle(color: Colors.black))..addText('Hello, world.');
  final Paragraph paragraph = paragraphBuilder.build()
    ..layout(const ParagraphConstraints(width: 1000));
  canvas.drawParagraph(paragraph, const Offset(20, 20));
};


import 'dart:ui';

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
/// Therefore we use this as the default [ShaderWarmUp] in
/// [SchedulerBinding.scheduleWarmUpFrame] to move common shader compilations
/// from animation time to startup time. Alternatively, [customShaderWarmUp]
/// can be provided to [runApp] to replace this default warm up function.
void defaultShaderWarmUp(Canvas canvas) {
  final RRect rrect = RRect.fromLTRBXY(20, 20, 60, 60, 10, 10);
  final Path rrectPath = Path()..addRRect(rrect);

  final Path circlePath = Path()..addOval(
    Rect.fromCircle(center: const Offset(40, 40), radius: 20)
  );

  // The following path is copied from
  // https://skia.org/user/api/SkCanvas_Reference#SkCanvas_drawPath
  final Path path = Path();
  path.moveTo(20, 60);
  path.quadraticBezierTo(60, 20, 60, 60);
  path.close();
  path.moveTo(60, 20);
  path.quadraticBezierTo(60, 60, 20, 60);

  final List<Path> paths = <Path>[rrectPath, circlePath, path];

  final List<Paint> paints = <Paint>[
    Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill,
    Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10,
    Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.1  // hairline
  ];

  // Warm up path stroke and fill shaders.
  for (int i = 0; i < paths.length; i++) {
    canvas.save();
    for (Paint paint in paints) {
      canvas.drawPath(paths[i], paint);
      canvas.translate(80, 0);
    }
    canvas.restore();
    canvas.translate(0, 80);
  }

  // Warm up shadow shaders.
  const Color black = Color(0xFF000000);  // foundation can't access material/colors
  canvas.save();
  canvas.drawShadow(rrectPath, black, 10.0, true);
  canvas.translate(80, 0);
  canvas.drawShadow(rrectPath, black, 10.0, false);
  canvas.restore();

  // Warm up text shaders.
  canvas.translate(0, 80);
  final ParagraphBuilder paragraphBuilder = ParagraphBuilder(
    ParagraphStyle(textDirection: TextDirection.ltr),
  )..pushStyle(TextStyle(color: black))..addText('Hello, world.');
  final Paragraph paragraph = paragraphBuilder.build()
    ..layout(const ParagraphConstraints(width: 60));
  canvas.drawParagraph(paragraph, const Offset(20, 20));
};

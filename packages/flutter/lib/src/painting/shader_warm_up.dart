import 'dart:developer';
import 'dart:ui';

/// Interface for drawing an image to warm up Skia shader compilations.
///
/// When Skia first sees a certain type of draw operations on GPU, it needs to
/// compile the corresponding shader. The compilation can be slow (20ms-200ms).
/// Having that time as a startup latency is much better than having a jank in
/// the middle of an animation.
///
/// Therefore we use this during the [runApp] call to move common shader
/// compilations from animation time to startup time. By default, a
/// [DefaultShaderWarmUp] is used. Create a custom [ShaderWarmUp] subclass to
/// replace it if needed.
///
/// This warm up needs to be run on each individual device because the shader
/// compilation depends on the specific GPU hardware and driver a device has. It
/// can't be pre-computed during the Flutter engine compilation as the engine is
/// device agnostic.
abstract class ShaderWarmUp {
  /// Allow const constructors for subclasses.
  const ShaderWarmUp();

  /// Width of the image to be drawn.
  int get width;

  /// Height of the image to be drawn.
  int get height;

  /// Trigger draw operations on a given canvas to warm up GPU shader
  /// compilation cache.
  void warmUpOnCanvas(Canvas canvas);

  /// Construct an offscreen image of size [width]x[height], and execute
  /// [warmUpOnCanvas] on a canvas associated with that image.
  void execute() {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    warmUpOnCanvas(canvas);

    final Picture picture = recorder.endRecording();
    final TimelineTask shaderWarmUpTask = TimelineTask();
    shaderWarmUpTask.start('Warm-up shader');
    picture.toImage(width, height).then((Image image) {
      shaderWarmUpTask.finish();
    });
  }
}

/// Default way of warming up Skia shader compilations.
///
/// The draw operations being warmed up here are decided according to Flutter
/// engineers' observation and experience based on the apps and the performance
/// issues seen so far.
///
/// To decide which draw operations to be added to your custom warm up process,
/// try capture an skp using `flutter screenshot --observatory- port=<port>
/// --type=skia` and analyze it with https://debugger.skia.org. Alternatively,
/// one may run the app with `flutter run --trace-skia` and then examine the GPU
/// thread in the observatory timeline to see which Skia draw operations are
/// commonly used, and which shader compilations are causing janks.
///
/// The size of [width]=[height]=1000 here are picked arbitrarily. The only goal
/// is to have them not too far away from the actual resolution (very few mobile
/// devices seem to have a resolution that is 10x larger or 10x smaller than
/// 1000x1000). The size should have little effect on the shader warm-up. A
/// custom shader warm up can pick another arbitrary number that's close to the
/// targeted devices.
class DefaultShaderWarmUp extends ShaderWarmUp {
  /// Allow [DefaultShaderWarmUp] to be used as the default value of parameters.
  const DefaultShaderWarmUp();

  @override
  int get width => 1000;

  @override
  int get height => 1000;

  /// Trigger common draw operations on a canvas to warm up GPU shader
  /// compilation cache.
  @override
  void warmUpOnCanvas(Canvas canvas) {
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
  }
}

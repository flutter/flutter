// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// Interface for drawing an image to warm up Skia shader compilations.
///
/// When Skia first sees a certain type of draw operation on the GPU, it needs
/// to compile the corresponding shader. The compilation can be slow (20ms-
/// 200ms). Having that time as startup latency is often better than having
/// jank in the middle of an animation.
///
/// Therefore, we use this during the [PaintingBinding.initInstances] call to
/// move common shader compilations from animation time to startup time. By
/// default, a [DefaultShaderWarmUp] is used. If needed, app developers can
/// create a custom [ShaderWarmUp] subclass and hand it to
/// [PaintingBinding.shaderWarmUp] (so it replaces [DefaultShaderWarmUp])
/// before [PaintingBinding.initInstances] is called. Usually, that can be
/// done before calling [runApp].
///
/// To determine whether a draw operation is useful for warming up shaders,
/// check whether it improves the slowest frame rasterization time. Also,
/// tracing with `flutter run --profile --trace-skia` may reveal whether there
/// is shader-compilation-related jank. If there is such jank, some long
/// `GrGLProgramBuilder::finalize` calls would appear in the middle of an
/// animation. Their parent calls, which look like `XyzOp` (e.g., `FillRecOp`,
/// `CircularRRectOp`) would suggest Xyz draw operations are causing the shaders
/// to be compiled. A useful shader warm-up draw operation would eliminate such
/// long compilation calls in the animation. To double-check the warm-up, trace
/// with `flutter run --profile --trace-skia --start-paused`. The
/// `GrGLProgramBuilder` with the associated `XyzOp` should appear during
/// startup rather than in the middle of a later animation.
///
/// This warm-up needs to be run on each individual device because the shader
/// compilation depends on the specific GPU hardware and driver a device has. It
/// can't be pre-computed during the Flutter engine compilation as the engine is
/// device-agnostic.
///
/// If no warm-up is desired (e.g., when the startup latency is crucial), set
/// [PaintingBinding.shaderWarmUp] either to a custom ShaderWarmUp with an empty
/// [warmUpOnCanvas] or null.
///
/// See also:
///
///  * [PaintingBinding.shaderWarmUp], the actual instance of [ShaderWarmUp]
///    that's used to warm up the shaders.
///  * <https://flutter.dev/docs/perf/rendering/shader>
abstract class ShaderWarmUp {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const ShaderWarmUp();

  /// The size of the warm up image.
  ///
  /// The exact size shouldn't matter much as long as all draws are onscreen.
  /// 100x100 is an arbitrary small size that's easy to fit significant draw
  /// calls onto.
  ///
  /// A custom shader warm up can override this based on targeted devices.
  ui.Size get size => const ui.Size(100.0, 100.0);

  /// Trigger draw operations on a given canvas to warm up GPU shader
  /// compilation cache.
  ///
  /// To decide which draw operations to be added to your custom warm up
  /// process, consider capturing an skp using `flutter screenshot
  /// --observatory-uri=<uri> --type=skia` and analyzing it with
  /// <https://debugger.skia.org/>. Alternatively, one may run the app with
  /// `flutter run --trace-skia` and then examine the raster thread in the
  /// observatory timeline to see which Skia draw operations are commonly used,
  /// and which shader compilations are causing jank.
  @protected
  Future<void> warmUpOnCanvas(ui.Canvas canvas);

  /// Construct an offscreen image of [size], and execute [warmUpOnCanvas] on a
  /// canvas associated with that image.
  ///
  /// Currently, this has no effect when [kIsWeb] is true.
  Future<void> execute() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    await warmUpOnCanvas(canvas);
    final ui.Picture picture = recorder.endRecording();
    if (!kIsWeb) { // Picture.toImage is not yet implemented on the web.
      final TimelineTask shaderWarmUpTask = TimelineTask();
      shaderWarmUpTask.start('Warm-up shader');
      try {
        await picture.toImage(size.width.ceil(), size.height.ceil());
      } finally {
        shaderWarmUpTask.finish();
      }
    }
  }
}

/// Default way of warming up Skia shader compilations.
///
/// The draw operations being warmed up here are decided according to Flutter
/// engineers' observation and experience based on the apps and the performance
/// issues seen so far.
///
/// This is used for the default value of [PaintingBinding.shaderWarmUp].
/// Consider setting that static property to a different value before the
/// binding is initialized to change the warm-up sequence.
///
/// See also:
///
///  * [ShaderWarmUp], the base class for shader warm-up objects.
///  * <https://flutter.dev/docs/perf/rendering/shader>
class DefaultShaderWarmUp extends ShaderWarmUp {
  /// Create an instance of the default shader warm-up logic.
  ///
  /// Since this constructor is `const`, [DefaultShaderWarmUp] can be used as
  /// the default value of parameters.
  const DefaultShaderWarmUp({
    this.drawCallSpacing = 0.0,
    this.canvasSize = const ui.Size(100.0, 100.0),
  });

  /// Distance to place between draw calls for visualizing the draws for
  /// debugging purposes (e.g. 80.0).
  ///
  /// Defaults to 0.0.
  ///
  /// When changing this value, the [canvasSize] must also be changed to
  /// accomodate the bigger canvas.
  final double drawCallSpacing;

  /// The [size] of the canvas required to paint the shapes in [warmUpOnCanvas].
  ///
  /// When [drawCallSpacing] is 0.0, this should be at least 100.0 by 100.0.
  final ui.Size canvasSize;

  @override
  ui.Size get size => canvasSize;

  /// Trigger common draw operations on a canvas to warm up GPU shader
  /// compilation cache.
  @override
  Future<void> warmUpOnCanvas(ui.Canvas canvas) async {
    const ui.RRect rrect = ui.RRect.fromLTRBXY(20.0, 20.0, 60.0, 60.0, 10.0, 10.0);
    final ui.Path rrectPath = ui.Path()..addRRect(rrect);
    final ui.Path circlePath = ui.Path()..addOval(
      ui.Rect.fromCircle(center: const ui.Offset(40.0, 40.0), radius: 20.0)
    );

    // The following path is based on
    // https://skia.org/user/api/SkCanvas_Reference#SkCanvas_drawPath
    final ui.Path path = ui.Path();
    path.moveTo(20.0, 60.0);
    path.quadraticBezierTo(60.0, 20.0, 60.0, 60.0);
    path.close();
    path.moveTo(60.0, 20.0);
    path.quadraticBezierTo(60.0, 60.0, 20.0, 60.0);

    final ui.Path convexPath = ui.Path();
    convexPath.moveTo(20.0, 30.0);
    convexPath.lineTo(40.0, 20.0);
    convexPath.lineTo(60.0, 30.0);
    convexPath.lineTo(60.0, 60.0);
    convexPath.lineTo(20.0, 60.0);
    convexPath.close();

    // Skia uses different shaders based on the kinds of paths being drawn and
    // the associated paint configurations. According to our experience and
    // tracing, drawing the following paths/paints generates various of
    // shaders that are commonly used.
    final List<ui.Path> paths = <ui.Path>[rrectPath, circlePath, path, convexPath];

    final List<ui.Paint> paints = <ui.Paint>[
      ui.Paint()
        ..isAntiAlias = true
        ..style = ui.PaintingStyle.fill,
      ui.Paint()
        ..isAntiAlias = false
        ..style = ui.PaintingStyle.fill,
      ui.Paint()
        ..isAntiAlias = true
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 10,
      ui.Paint()
        ..isAntiAlias = true
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 0.1,  // hairline
    ];

    // Warm up path stroke and fill shaders.
    for (int i = 0; i < paths.length; i += 1) {
      canvas.save();
      for (final ui.Paint paint in paints) {
        canvas.drawPath(paths[i], paint);
        canvas.translate(drawCallSpacing, 0.0);
      }
      canvas.restore();
      canvas.translate(0.0, drawCallSpacing);
    }

    // Warm up shadow shaders.
    const ui.Color black = ui.Color(0xFF000000);
    canvas.save();
    canvas.drawShadow(rrectPath, black, 10.0, true);
    canvas.translate(drawCallSpacing, 0.0);
    canvas.drawShadow(rrectPath, black, 10.0, false);
    canvas.restore();

    // Warm up text shaders.
    canvas.translate(0.0, drawCallSpacing);
    final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(textDirection: ui.TextDirection.ltr),
    )..pushStyle(ui.TextStyle(color: black))..addText('_');
    final ui.Paragraph paragraph = paragraphBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: 60.0));
    canvas.drawParagraph(paragraph, const ui.Offset(20.0, 20.0));

    // Draw a rect inside a rrect with a non-trivial intersection. If the
    // intersection is trivial (e.g., equals the rrect clip), Skia will optimize
    // the clip out.
    //
    // Add an integral or fractional translation to trigger Skia's non-AA or AA
    // optimizations (as did before in normal FillRectOp in rrect clip cases).
    for (final double fraction in <double>[0.0, 0.5]) {
      canvas
        ..save()
        ..translate(fraction, fraction)
        ..clipRRect(ui.RRect.fromLTRBR(8, 8, 328, 248, const ui.Radius.circular(16)))
        ..drawRect(const ui.Rect.fromLTRB(10, 10, 320, 240), ui.Paint())
        ..restore();
      canvas.translate(drawCallSpacing, 0.0);
    }
    canvas.translate(0.0, drawCallSpacing);
  }
}

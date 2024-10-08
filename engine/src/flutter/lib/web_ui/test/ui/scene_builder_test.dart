// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:web_engine_tester/golden_tester.dart';

import '../common/rendering.dart';
import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(
    withImplicitView: true,
    emulateTesterEnvironment: false,
    setUpTestViewDimensions: false,
  );

  group('${ui.SceneBuilder}', () {
    const ui.Rect region = ui.Rect.fromLTWH(0, 0, 300, 300);
    test('Test offset layer', () async {
      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();
      sceneBuilder.pushOffset(150, 150);
      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawCircle(
            ui.Offset.zero, 50, ui.Paint()..color = const ui.Color(0xFF00FF00));
      }));

      await renderScene(sceneBuilder.build());
      await matchGoldenFile('scene_builder_centered_circle.png',
          region: region);
    });

    test('Test transform layer', () async {
      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();
      final Matrix4 transform = Matrix4.identity();

      // The html renderer expects the top-level transform to just be a scaling
      // matrix for the device pixel ratio, so just push the identity matrix.
      sceneBuilder.pushTransform(transform.toFloat64());
      transform.translate(150, 150);
      transform.rotate(kUnitZ, math.pi / 3);
      sceneBuilder.pushTransform(transform.toFloat64());
      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawRRect(
            ui.RRect.fromRectAndRadius(
                ui.Rect.fromCircle(center: ui.Offset.zero, radius: 50),
                const ui.Radius.circular(10)),
            ui.Paint()..color = const ui.Color(0xFF0000FF));
      }));

      await renderScene(sceneBuilder.build());
      await matchGoldenFile('scene_builder_rotated_rounded_square.png',
          region: region);
    });

    test('Test clipRect layer', () async {
      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();
      sceneBuilder.pushClipRect(const ui.Rect.fromLTRB(0, 0, 150, 150));
      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawCircle(const ui.Offset(150, 150), 50,
            ui.Paint()..color = const ui.Color(0xFFFF0000));
      }));

      await renderScene(sceneBuilder.build());
      await matchGoldenFile('scene_builder_circle_clip_rect.png',
          region: region);
    });

    test('Test clipRRect layer', () async {
      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();
      sceneBuilder.pushClipRRect(
          ui.RRect.fromRectAndRadius(
            const ui.Rect.fromLTRB(0, 0, 150, 150),
            const ui.Radius.circular(25),
          ),
          clipBehavior: ui.Clip.antiAlias);
      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawCircle(const ui.Offset(150, 150), 50,
            ui.Paint()..color = const ui.Color(0xFFFF00FF));
      }));

      await renderScene(sceneBuilder.build());
      await matchGoldenFile('scene_builder_circle_clip_rrect.png',
          region: region);
    });

    test('Test clipPath layer', () async {
      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();
      final ui.Path path = ui.Path();
      path.addOval(
          ui.Rect.fromCircle(center: const ui.Offset(150, 150), radius: 60));
      sceneBuilder.pushClipPath(path);
      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawRect(
            ui.Rect.fromCircle(center: const ui.Offset(150, 150), radius: 50),
            ui.Paint()..color = const ui.Color(0xFF00FFFF));
      }));

      await renderScene(sceneBuilder.build());
      await matchGoldenFile('scene_builder_rectangle_clip_circular_path.png',
          region: region);
    });

    test('Test opacity layer', () async {
      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();
      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawRect(
            ui.Rect.fromCircle(center: const ui.Offset(150, 150), radius: 50),
            ui.Paint()..color = const ui.Color(0xFF00FF00));
      }));

      sceneBuilder.pushOpacity(0x7F, offset: const ui.Offset(150, 150));
      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        final ui.Paint paint = ui.Paint()..color = const ui.Color(0xFFFF0000);
        canvas.drawCircle(const ui.Offset(-25, 0), 50, paint);
        canvas.drawCircle(const ui.Offset(25, 0), 50, paint);
      }));

      await renderScene(sceneBuilder.build());
      await matchGoldenFile('scene_builder_opacity_circles_on_square.png',
          region: region);
    });

    test('shader mask layer', () async {
      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();

      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        final ui.Paint paint = ui.Paint()..color = const ui.Color(0xFFFF0000);
        canvas.drawCircle(const ui.Offset(125, 150), 50, paint);
        canvas.drawCircle(const ui.Offset(175, 150), 50, paint);
      }));

      final ui.Shader shader = ui.Gradient.linear(
          ui.Offset.zero, const ui.Offset(50, 50), <ui.Color>[
        const ui.Color(0xFFFFFFFF),
        const ui.Color(0x00000000),
      ]);
      sceneBuilder.pushShaderMask(shader,
          const ui.Rect.fromLTRB(125, 125, 175, 175), ui.BlendMode.srcATop);

      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawRect(
            ui.Rect.fromCircle(center: const ui.Offset(150, 150), radius: 50),
            ui.Paint()..color = const ui.Color(0xFF00FF00));
      }));

      await renderScene(sceneBuilder.build());
      await matchGoldenFile('scene_builder_shader_mask.png', region: region);
    },
        skip: isFirefox &&
            isHtml); // https://github.com/flutter/flutter/issues/86623

    test('backdrop filter layer', () async {
      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();

      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        // Create a red and blue checkerboard pattern
        final ui.Paint redPaint = ui.Paint()
          ..color = const ui.Color(0xFFFF0000);
        final ui.Paint bluePaint = ui.Paint()
          ..color = const ui.Color(0xFF0000FF);
        for (double y = 0; y < 300; y += 10) {
          for (double x = 0; x < 300; x += 10) {
            final ui.Paint paint = ((x + y) % 20 == 0) ? redPaint : bluePaint;
            canvas.drawRect(ui.Rect.fromLTWH(x, y, 10, 10), paint);
          }
        }
      }));

      sceneBuilder.pushBackdropFilter(ui.ImageFilter.blur(
        sigmaX: 3.0,
        sigmaY: 3.0,
      ));

      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawCircle(const ui.Offset(150, 150), 50,
            ui.Paint()..color = const ui.Color(0xFF00FF00));
      }));

      await renderScene(sceneBuilder.build());
      await matchGoldenFile('scene_builder_backdrop_filter.png',
          region: region);
    });

    test('empty backdrop filter layer with clip', () async {
      // Note that this test does not actually render properly in skwasm due to
      // a Skia bug. See https://g-issues.skia.org/issues/362552959 and
      // https://github.com/flutter/flutter/issues/152026
      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();

      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        // Create a red and blue checkerboard pattern
        final ui.Paint redPaint = ui.Paint()
          ..color = const ui.Color(0xFFFF0000);
        final ui.Paint bluePaint = ui.Paint()
          ..color = const ui.Color(0xFF0000FF);
        for (double y = 0; y < 300; y += 10) {
          for (double x = 0; x < 300; x += 10) {
            final ui.Paint paint = ((x + y) % 20 == 0) ? redPaint : bluePaint;
            canvas.drawRect(ui.Rect.fromLTWH(x, y, 10, 10), paint);
          }
        }
      }));

      sceneBuilder.pushClipRect(const ui.Rect.fromLTRB(100, 100, 200, 200));

      sceneBuilder.pushBackdropFilter(ui.ImageFilter.blur(
        sigmaX: 3.0,
        sigmaY: 3.0,
      ));
      await renderScene(sceneBuilder.build());
      await matchGoldenFile('scene_builder_empty_backdrop_filter_with_clip.png',
          region: region);
    });

    test('image filter layer', () async {
      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();
      sceneBuilder.pushImageFilter(ui.ImageFilter.blur(
        sigmaX: 5.0,
        sigmaY: 5.0,
      ));

      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawCircle(const ui.Offset(150, 150), 50,
            ui.Paint()..color = const ui.Color(0xFF00FF00));
      }));

      await renderScene(sceneBuilder.build());
      await matchGoldenFile('scene_builder_image_filter.png', region: region);
    });

    // Regression test for https://github.com/flutter/flutter/issues/154303
    test('image filter layer with offset', () async {
      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();

      sceneBuilder.pushClipRect(const ui.Rect.fromLTWH(100, 100, 100, 100));
      sceneBuilder.pushImageFilter(
        ui.ImageFilter.blur(
          sigmaX: 5.0,
          sigmaY: 5.0,
        ),
        offset: const ui.Offset(100, 100),
      );

      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawCircle(const ui.Offset(50, 50), 25,
            ui.Paint()..color = const ui.Color(0xFF00FF00));
      }));

      await renderScene(sceneBuilder.build());
      await matchGoldenFile(
        'scene_builder_image_filter_with_offset.png',
        region: region,
      );
    });

    test('color filter layer', () async {
      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();
      const ui.ColorFilter sepia = ui.ColorFilter.matrix(<double>[
        0.393,
        0.769,
        0.189,
        0,
        0,
        0.349,
        0.686,
        0.168,
        0,
        0,
        0.272,
        0.534,
        0.131,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]);
      sceneBuilder.pushColorFilter(sepia);

      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawCircle(const ui.Offset(150, 150), 50,
            ui.Paint()..color = const ui.Color(0xFF00FF00));
      }));

      await renderScene(sceneBuilder.build());
      await matchGoldenFile('scene_builder_color_filter.png', region: region);
    });

    test('overlapping pictures in opacity layer', () async {
      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();
      sceneBuilder.pushOpacity(128);
      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawCircle(const ui.Offset(100, 150), 100,
            ui.Paint()..color = const ui.Color(0xFFFF0000));
      }));
      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawCircle(const ui.Offset(200, 150), 100,
            ui.Paint()..color = const ui.Color(0xFFFF0000));
      }));
      sceneBuilder.pop();

      await renderScene(sceneBuilder.build());
      await matchGoldenFile('scene_builder_overlapping_pictures_in_opacity.png',
          region: region);
    });

    test('picture clipped out in final scene', () async {
      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();
      sceneBuilder.pushClipRect(const ui.Rect.fromLTRB(0, 0, 125, 300));
      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawCircle(const ui.Offset(50, 150), 50,
            ui.Paint()..color = const ui.Color(0xFFFF0000));
      }));
      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawCircle(const ui.Offset(200, 150), 50,
            ui.Paint()..color = const ui.Color(0xFFFF0000));
      }));
      sceneBuilder.pop();

      await renderScene(sceneBuilder.build());
      await matchGoldenFile('scene_builder_picture_clipped_out.png',
          region: region);
    });

    test('picture clipped but scrolls back in', () async {
      // Frame 1: Clip out the right circle
      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();
      sceneBuilder.pushClipRect(const ui.Rect.fromLTRB(0, 0, 125, 300));
      // Save this offsetLayer to add back in so we are using the same
      // picture layers on the next scene.
      final ui.OffsetEngineLayer offsetLayer = sceneBuilder.pushOffset(0, 0);
      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawCircle(const ui.Offset(50, 150), 50,
            ui.Paint()..color = const ui.Color(0xFFFF0000));
      }));
      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawCircle(const ui.Offset(200, 150), 50,
            ui.Paint()..color = const ui.Color(0xFFFF0000));
      }));
      sceneBuilder.pop();
      sceneBuilder.pop();
      await renderScene(sceneBuilder.build());

      // Frame 2: Clip out the left circle
      final ui.SceneBuilder sceneBuilder2 = ui.SceneBuilder();
      sceneBuilder2.pushClipRect(const ui.Rect.fromLTRB(150, 0, 300, 300));
      sceneBuilder2.addRetained(offsetLayer);
      sceneBuilder2.pop();
      await renderScene(sceneBuilder2.build());

      // Frame 3: Clip out the right circle again
      final ui.SceneBuilder sceneBuilder3 = ui.SceneBuilder();
      sceneBuilder3.pushClipRect(const ui.Rect.fromLTRB(0, 0, 125, 300));
      sceneBuilder3.addRetained(offsetLayer);
      sceneBuilder3.pop();
      await renderScene(sceneBuilder3.build());

      await matchGoldenFile(
          'scene_builder_picture_clipped_out_then_clipped_in.png',
          region: region);
    });

    test('shader mask parent of clipped out picture', () async {
      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();
      final ui.Shader shader = ui.Gradient.linear(
          ui.Offset.zero, const ui.Offset(50, 50), <ui.Color>[
        const ui.Color(0xFFFFFFFF),
        const ui.Color(0x00000000),
      ]);
      sceneBuilder.pushClipRect(const ui.Rect.fromLTRB(0, 0, 125, 300));
      sceneBuilder.pushShaderMask(shader,
          const ui.Rect.fromLTRB(25, 125, 75, 175), ui.BlendMode.srcATop);
      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawCircle(const ui.Offset(50, 150), 50,
            ui.Paint()..color = const ui.Color(0xFFFF0000));
      }));
      sceneBuilder.pop();
      sceneBuilder.pushShaderMask(shader,
          const ui.Rect.fromLTRB(175, 125, 225, 175), ui.BlendMode.srcATop);
      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawCircle(const ui.Offset(200, 150), 50,
            ui.Paint()..color = const ui.Color(0xFFFF0000));
      }));
      sceneBuilder.pop();
      sceneBuilder.pop();
      await renderScene(sceneBuilder.build());

      await matchGoldenFile('scene_builder_shader_mask_clipped_out.png',
          region: region);
    },
        skip: isFirefox &&
            isHtml); // https://github.com/flutter/flutter/issues/86623

    test('opacity layer with transformed children', () async {
      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();
      sceneBuilder.pushOffset(0, 0);
      sceneBuilder.pushOpacity(128);
      // Push some complex transforms
      final Float64List transform1 = Float64List.fromList([
        1.00,
        0.00,
        0.00,
        0.00,
        0.06,
        1.00,
        -0.88,
        0.00,
        -0.03,
        0.60,
        0.47,
        -0.00,
        -4.58,
        257.03,
        63.11,
        0.81,
      ]);
      final Float64List transform2 = Float64List.fromList([
        1.00,
        0.00,
        0.00,
        0.00,
        0.07,
        0.90,
        -0.94,
        0.00,
        -0.02,
        0.75,
        0.33,
        -0.00,
        -3.28,
        309.29,
        45.20,
        0.86,
      ]);
      sceneBuilder
          .pushTransform(Matrix4.identity().scaled(0.3, 0.3).toFloat64());
      sceneBuilder.pushTransform(transform1);
      sceneBuilder.pushTransform(transform2);

      sceneBuilder.addPicture(const ui.Offset(20, 20),
          drawPicture((ui.Canvas canvas) {
        canvas.drawCircle(const ui.Offset(25, 75), 25,
            ui.Paint()..color = const ui.Color(0xFFFF0000));
      }));
      sceneBuilder.pop();
      sceneBuilder.pop();
      sceneBuilder.pop();
      sceneBuilder.pop();
      sceneBuilder.pop();
      await renderScene(sceneBuilder.build());

      await matchGoldenFile(
          'scene_builder_opacity_layer_with_transformed_children.png',
          region: region);
    });
  });
}

ui.Picture drawPicture(void Function(ui.Canvas) drawCommands) {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);
  drawCommands(canvas);
  return recorder.endRecording();
}

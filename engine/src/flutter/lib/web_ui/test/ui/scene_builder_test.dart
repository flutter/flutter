// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:web_engine_tester/golden_tester.dart';

import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(
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
          ui.Offset.zero,
          50,
          ui.Paint()..color = const ui.Color(0xFF00FF00)
        );
      }));

      await renderer.renderScene(sceneBuilder.build());
      await matchGoldenFile('scene_builder_centered_circle.png', region: region);
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
            const ui.Radius.circular(10)
          ),
          ui.Paint()..color = const ui.Color(0xFF0000FF)
        );
      }));

      await renderer.renderScene(sceneBuilder.build());
      await matchGoldenFile('scene_builder_rotated_rounded_square.png', region: region);
    });

    test('Test clipRect layer', () async {
      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();
      sceneBuilder.pushClipRect(const ui.Rect.fromLTRB(0, 0, 150, 150));
      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawCircle(
          const ui.Offset(150, 150),
          50,
          ui.Paint()..color = const ui.Color(0xFFFF0000)
        );
      }));

      await renderer.renderScene(sceneBuilder.build());
      await matchGoldenFile('scene_builder_circle_clip_rect.png', region: region);
    });

    test('Test clipRRect layer', () async {
      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();
      sceneBuilder.pushClipRRect(ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTRB(0, 0, 150, 150),
        const ui.Radius.circular(25),
      ), clipBehavior: ui.Clip.antiAlias);
      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawCircle(
          const ui.Offset(150, 150),
          50,
          ui.Paint()..color = const ui.Color(0xFFFF00FF)
        );
      }));

      await renderer.renderScene(sceneBuilder.build());
      await matchGoldenFile('scene_builder_circle_clip_rrect.png', region: region);
    });

    test('Test clipPath layer', () async {
      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();
      final ui.Path path = ui.Path();
      path.addOval(ui.Rect.fromCircle(center: const ui.Offset(150, 150), radius: 60));
      sceneBuilder.pushClipPath(path);
      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawRect(
          ui.Rect.fromCircle(center: const ui.Offset(150, 150), radius: 50),
          ui.Paint()..color = const ui.Color(0xFF00FFFF)
        );
      }));

      await renderer.renderScene(sceneBuilder.build());
      await matchGoldenFile('scene_builder_rectangle_clip_circular_path.png', region: region);
    });

    test('Test opacity layer', () async {
      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();
      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawRect(
          ui.Rect.fromCircle(center: const ui.Offset(150, 150), radius: 50),
          ui.Paint()..color = const ui.Color(0xFF00FF00)
        );
      }));

      sceneBuilder.pushOpacity(0x7F);
      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        final ui.Paint paint = ui.Paint()..color = const ui.Color(0xFFFF0000);
        canvas.drawCircle(
          const ui.Offset(125, 150),
          50,
          paint
        );
        canvas.drawCircle(
          const ui.Offset(175, 150),
          50,
          paint
        );
      }));

      await renderer.renderScene(sceneBuilder.build());
      await matchGoldenFile('scene_builder_opacity_circles_on_square.png', region: region);
    });

    test('shader mask layer', () async {
      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();

      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        final ui.Paint paint = ui.Paint()..color = const ui.Color(0xFFFF0000);
        canvas.drawCircle(
          const ui.Offset(125, 150),
          50,
          paint
        );
        canvas.drawCircle(
          const ui.Offset(175, 150),
          50,
          paint
        );
      }));

      final ui.Shader shader = ui.Gradient.linear(
        ui.Offset.zero,
        const ui.Offset(50, 50), <ui.Color>[
          const ui.Color(0xFFFFFFFF),
          const ui.Color(0x00000000),
        ]);
      sceneBuilder.pushShaderMask(
        shader,
        const ui.Rect.fromLTRB(125, 125, 175, 175),
        ui.BlendMode.srcATop
      );

      sceneBuilder.addPicture(ui.Offset.zero, drawPicture((ui.Canvas canvas) {
        canvas.drawRect(
          ui.Rect.fromCircle(center: const ui.Offset(150, 150), radius: 50),
          ui.Paint()..color = const ui.Color(0xFF00FF00)
        );
      }));

      await renderer.renderScene(sceneBuilder.build());
      await matchGoldenFile('scene_builder_shader_mask.png', region: region);
    }, skip: isFirefox && isHtml); // https://github.com/flutter/flutter/issues/86623
  });
}

ui.Picture drawPicture(void Function(ui.Canvas) drawCommands) {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);
  drawCommands(canvas);
  return recorder.endRecording();
}

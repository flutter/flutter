// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Callback supported by headless tests to inject custom mock image textures.
typedef ImageLoader = Future<ui.Image> Function();

/// Generates a standard 32x32 4-color checkerboard image texture in memory
/// using an offscreen canvas recording pass.
Future<ui.Image> defaultImageLoader() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  canvas.drawRect(const Rect.fromLTWH(0, 0, 16, 16), Paint()..color = Colors.red);
  canvas.drawRect(const Rect.fromLTWH(16, 0, 16, 16), Paint()..color = Colors.green);
  canvas.drawRect(const Rect.fromLTWH(0, 16, 16, 16), Paint()..color = Colors.blue);
  canvas.drawRect(const Rect.fromLTWH(16, 16, 16, 16), Paint()..color = Colors.yellow);

  return recorder.endRecording().toImage(32, 32);
}

/// Dedicated canvas widget to render pre-loaded image textures for 'imageTest'.
class ImageDrawingCanvas extends StatelessWidget {
  const ImageDrawingCanvas({super.key, required this.image});

  final ui.Image? image;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ImageDrawingPainter(image: image));
  }
}

class _ImageDrawingPainter extends CustomPainter {
  const _ImageDrawingPainter({required this.image});

  final ui.Image? image;

  @override
  void paint(Canvas canvas, Size size) {
    final ui.Image? img = image;
    if (img != null) {
      canvas.drawImage(img, Offset.zero, Paint());
    }
  }

  @override
  bool shouldRepaint(covariant _ImageDrawingPainter oldDelegate) {
    return image != oldDelegate.image;
  }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class GpuSdfCanvas extends StatefulWidget {
  const GpuSdfCanvas({super.key, required this.targetFormat});

  final ui.TargetPixelFormat targetFormat;

  @override
  State<GpuSdfCanvas> createState() => _GpuSdfCanvasState();
}

class _GpuSdfCanvasState extends State<GpuSdfCanvas> {
  ui.Image? _image;
  ui.FragmentShader? _circle;
  ui.FragmentShader? _sdfShader;

  @override
  void initState() {
    super.initState();
    _loadCircleShader().then((ui.FragmentShader shader) {
      setState(() {
        _circle = shader;
      });
    });
    _loadSdfShader().then((ui.FragmentShader shader) {
      setState(() {
        _sdfShader = shader;
      });
    });
  }

  Future<ui.FragmentShader> _loadCircleShader() async {
    final ui.FragmentProgram program = await ui.FragmentProgram.fromAsset(
      'shaders/circle_sdf.frag',
    );
    return program.fragmentShader();
  }

  Future<ui.FragmentShader> _loadSdfShader() async {
    final ui.FragmentProgram program = await ui.FragmentProgram.fromAsset('shaders/sdf.frag');
    return program.fragmentShader();
  }

  ui.Image _loadImage(ui.FragmentShader shader) {
    const size = Size(512, 512);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    final paint = Paint()..shader = _circle;
    canvas.drawRect(Offset.zero & size, paint);
    final ui.Picture picture = recorder.endRecording();
    return picture.toImageSync(
      size.width.toInt(),
      size.height.toInt(),
      targetFormat: widget.targetFormat,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_circle == null || _sdfShader == null) {
      return const Center(child: CircularProgressIndicator());
    }
    _image ??= _loadImage(_circle!);
    return SizedBox.expand(child: CustomPaint(painter: GpuSdfPainter(_image!, _sdfShader!)));
  }
}

class GpuSdfPainter extends CustomPainter {
  GpuSdfPainter(this.image, this.shader);

  final ui.Image image;
  final ui.FragmentShader shader;

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setImageSampler(0, image);
    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

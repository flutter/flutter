// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' show sqrt;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class CpuSdfCanvas extends StatefulWidget {
  const CpuSdfCanvas({super.key, required this.targetFormat});

  final ui.TargetPixelFormat targetFormat;

  @override
  State<CpuSdfCanvas> createState() => _CpuSdfCanvasState();
}

class _CpuSdfCanvasState extends State<CpuSdfCanvas> {
  ui.FragmentShader? _shader;
  ui.Image? _sdfImage;

  @override
  void initState() {
    super.initState();
    _loadShader().then((ui.FragmentShader shader) {
      setState(() {
        _shader = shader;
      });
    });
    switch (widget.targetFormat) {
      case ui.TargetPixelFormat.rgbaFloat32:
        _loadRGBA32FloatSdfImage().then((ui.Image image) {
          setState(() {
            _sdfImage = image;
          });
        });
      case ui.TargetPixelFormat.rFloat32:
        _loadR32FloatSdfImage().then((ui.Image image) {
          setState(() {
            _sdfImage = image;
          });
        });
      case ui.TargetPixelFormat.dontCare:
        assert(false);
    }
  }

  Future<ui.FragmentShader> _loadShader() async {
    final ui.FragmentProgram program = await ui.FragmentProgram.fromAsset('shaders/sdf.frag');
    return program.fragmentShader();
  }

  Future<ui.Image> _loadRGBA32FloatSdfImage() async {
    const width = 1024;
    const height = 1024;
    const double radius = width / 4.0;
    final floats = List<double>.filled(width * height * 4, 0.0);
    for (var i = 0; i < height; ++i) {
      for (var j = 0; j < width; ++j) {
        double x = j.toDouble();
        double y = i.toDouble();
        x -= width / 2.0;
        y -= height / 2.0;
        final double length = sqrt(x * x + y * y);
        final int idx = i * width * 4 + j * 4;
        floats[idx + 0] = length - radius;
        floats[idx + 1] = 0.0;
        floats[idx + 2] = 0.0;
        floats[idx + 3] = 1.0;
      }
    }
    final floatList = Float32List.fromList(floats);
    final intList = Uint8List.view(floatList.buffer);
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      intList,
      width,
      height,
      ui.PixelFormat.rgbaFloat32,
      targetFormat: widget.targetFormat,
      (ui.Image image) {
        completer.complete(image);
      },
    );
    return completer.future;
  }

  Future<ui.Image> _loadR32FloatSdfImage() async {
    const width = 1024;
    const height = 1024;
    const double radius = width / 4.0;
    final floats = List<double>.filled(width * height, 0.0);
    for (var i = 0; i < height; ++i) {
      for (var j = 0; j < width; ++j) {
        double x = j.toDouble();
        double y = i.toDouble();
        x -= width / 2.0;
        y -= height / 2.0;
        final double length = sqrt(x * x + y * y);
        final int idx = i * width + j;
        floats[idx] = length - radius;
      }
    }
    final floatList = Float32List.fromList(floats);
    final intList = Uint8List.view(floatList.buffer);
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      intList,
      width,
      height,
      ui.PixelFormat.rFloat32,
      targetFormat: ui.TargetPixelFormat.rFloat32,
      (ui.Image image) {
        completer.complete(image);
      },
    );
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SizedBox.expand(
      child: (_shader != null && _sdfImage != null)
          ? CustomPaint(painter: CpuSdfPainter(_shader!, _sdfImage!))
          : Container(),
    );
  }
}

class CpuSdfPainter extends CustomPainter {
  CpuSdfPainter(this.shader, this.image);

  final ui.FragmentShader shader;
  final ui.Image image;

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

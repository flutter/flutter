// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' show sqrt;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

ui.TargetPixelFormat gTargetPixelFormat = ui.TargetPixelFormat.rFloat32;

enum TestType { sdf, circle }

TestType testToRun = TestType.circle;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDF Demo',
      theme: ThemeData.dark(),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    Widget child;
    switch (testToRun) {
      case TestType.sdf:
        child = const SdfCanvas(key: Key('sdf_canvas'));
        break;
      case TestType.circle:
        child = const PictureCanvas(key: Key('picture_canvas'));
        break;
    }
    return Scaffold(
      body: child,
    );
  }
}

class PictureCanvas extends StatefulWidget {
  const PictureCanvas({super.key});

  @override
  State<PictureCanvas> createState() => _PictureCanvasState();
}

class _PictureCanvasState extends State<PictureCanvas> {
  ui.Image? _image;
  ui.FragmentShader? _circle;

  @override
  void initState() {
    super.initState();
    _loadShader().then((ui.FragmentShader shader) {
      setState(() {
        _circle = shader;
      });
    });
  }

  Future<ui.FragmentShader> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset(
      'shaders/circle_sdf.frag',
    );
    return program.fragmentShader();
  }

  ui.Image _loadImage(ui.FragmentShader shader) {
    const Size size = Size(512, 512);
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    final Paint paint = Paint()..shader = _circle;
    canvas.drawRect(Offset.zero & size, paint);
    final ui.Picture picture = recorder.endRecording();
    return picture.toImageSync(
      size.width.toInt(),
      size.height.toInt(),
      targetFormat: ui.TargetPixelFormat.rgbaFloat32,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_circle == null) {
      return const Center(child: CircularProgressIndicator());
    }
    _image ??= _loadImage(_circle!);
    return SizedBox.expand(
      child: CustomPaint(painter: CirclePainter(_image!)),
    );
  }
}

class CirclePainter extends CustomPainter {
  CirclePainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final Rect dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class SdfCanvas extends StatefulWidget {
  const SdfCanvas({super.key});

  @override
  State<SdfCanvas> createState() => _SdfCanvasState();
}

class _SdfCanvasState extends State<SdfCanvas> {
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
    switch (gTargetPixelFormat) {
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
    final ui.FragmentProgram program = await ui.FragmentProgram.fromAsset(
      'shaders/sdf.frag',
    );
    return program.fragmentShader();
  }

  Future<ui.Image> _loadR32FloatSdfImage() async {
    const int width = 1024;
    const int height = 1024;
    const double radius = width / 4.0;
    final List<double> floats = List<double>.filled(width * height, 0.0);
    for (int i = 0; i < height; ++i) {
      for (int j = 0; j < width; ++j) {
        double x = j.toDouble();
        double y = i.toDouble();
        x -= width / 2.0;
        y -= height / 2.0;
        final double length = sqrt(x * x + y * y) - radius;
        final int idx = i * width + j;
        floats[idx] = length - radius;
      }
    }
    final Float32List floatList = Float32List.fromList(floats);
    final Uint8List intList = Uint8List.view(floatList.buffer);
    final Completer<ui.Image> completer = Completer<ui.Image>();
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

  Future<ui.Image> _loadRGBA32FloatSdfImage() async {
    const int width = 1024;
    const int height = 1024;
    const double radius = width / 4.0;
    final List<double> floats = List<double>.filled(width * height * 4, 0.0);
    for (int i = 0; i < height; ++i) {
      for (int j = 0; j < width; ++j) {
        double x = j.toDouble();
        double y = i.toDouble();
        x -= width / 2.0;
        y -= height / 2.0;
        final double length = sqrt(x * x + y * y) - radius;
        final int idx = i * width * 4 + j * 4;
        floats[idx + 0] = length - radius;
        floats[idx + 1] = 0.0;
        floats[idx + 2] = 0.0;
        floats[idx + 3] = 1.0;
      }
    }
    final Float32List floatList = Float32List.fromList(floats);
    final Uint8List intList = Uint8List.view(floatList.buffer);
    final Completer<ui.Image> completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      intList,
      width,
      height,
      ui.PixelFormat.rgbaFloat32,
      targetFormat: ui.TargetPixelFormat.rgbaFloat32,
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
          ? CustomPaint(painter: SdfPainter(_shader!, _sdfImage!))
          : Container(),
    );
  }
}

class SdfPainter extends CustomPainter {
  SdfPainter(this.shader, this.image);

  final ui.FragmentShader shader;
  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setImageSampler(0, image);
    final Paint paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

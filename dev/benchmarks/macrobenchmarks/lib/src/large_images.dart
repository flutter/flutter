// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class LargeImagesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ImageCache imageCache = PaintingBinding.instance.imageCache;
    imageCache.maximumSize = 30;
    imageCache.maximumSizeBytes = 50 << 20;
    return GridView.builder(
      itemCount: 1000,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemBuilder: (BuildContext context, int index) => DummyImage(500 + index % 500, 1000),
    ).build(context);
  }
}

class DummyImage extends StatefulWidget {
  const DummyImage(this.width, this.height);

  final int width;
  final int height;

  @override
  State<StatefulWidget> createState() {
    return DummyImageState();
  }
}

class DummyImageState extends State<DummyImage> {
  static const int kMaxDimension = 1000;

  static final Uint8List pixels = Uint8List.fromList(List<int>.generate(
    kMaxDimension * kMaxDimension * 4, (int i) => i % 4 < 2 ? 0x00 : 0xFF, // opaque blue
  ));

  @override
  void initState() {
    super.initState();
    ui.decodeImageFromPixels(
        pixels,
        widget.width,
        widget.height,
        ui.PixelFormat.rgba8888,
            (ui.Image image) {
          _completer.complete(image);
        }
    );
  }

  final Completer<void> _completer = Completer<ui.Image>();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
      future: _completer.future,
      builder: (BuildContext context, AsyncSnapshot<ui.Image> snapshot) {
        Widget inner = snapshot.data == null
            ? Container(
          width: widget.width.toDouble(),
          height: widget.height.toDouble(),
        )
            : CustomPaint(
          size: Size(widget.width.toDouble(), widget.height.toDouble()),
          painter: ImagePainter(snapshot.data),
        );
        return Container(
          padding: const EdgeInsets.all(10),
          child: ClipRect(child: inner),
        );
      },
    );
  }
}

class ImagePainter extends CustomPainter {
  ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }

  final ui.Image image;
}

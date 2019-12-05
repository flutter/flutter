// Copyright 2014 The Flutter Authors. All rights reserved.
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
      itemBuilder: (BuildContext context, int index) => DummyImage(index),
    ).build(context);
  }
}

class DummyImage extends StatelessWidget {
  DummyImage(this.index) : super(key: ValueKey<int>(index));

  @override
  Widget build(BuildContext context) {
    final Future<ByteData> pngData = _getPngData(context);

    return FutureBuilder<ByteData>(
      future: pngData,
      builder: (BuildContext context, AsyncSnapshot<ByteData> snapshot) {
        return snapshot.data == null
            ? Container()
            : Image.memory(snapshot.data.buffer.asUint8List());
      },
    );
  }

  final int index;

  Future<ByteData> _getPngData(BuildContext context) async {
    return DefaultAssetBundle.of(context).load('assets/999x1000.png');
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

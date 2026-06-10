// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// A custom widget wrapping a CustomPaint canvas to render text for the
/// 'textTest' scenario, caching the laid-out TextPainter in state.
class TextDrawingCanvas extends StatefulWidget {
  const TextDrawingCanvas({super.key});

  @override
  State<TextDrawingCanvas> createState() => _TextDrawingCanvasState();
}

class _TextDrawingCanvasState extends State<TextDrawingCanvas> {
  late final TextPainter _textPainter;

  @override
  void initState() {
    super.initState();
    _textPainter = TextPainter(
      text: const TextSpan(
        text: 'Flutter Text Rendering Test',
        style: TextStyle(
          color: Colors.red,
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    _textPainter.layout();
  }

  @override
  void dispose() {
    _textPainter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _TextDrawingPainter(textPainter: _textPainter));
  }
}

class _TextDrawingPainter extends CustomPainter {
  const _TextDrawingPainter({required TextPainter textPainter})
    : _textPainter = textPainter;

  final TextPainter _textPainter;

  @override
  void paint(Canvas canvas, Size size) {
    _textPainter.paint(canvas, const Offset(10.0, 50.0));
  }

  @override
  bool shouldRepaint(covariant _TextDrawingPainter oldDelegate) {
    return _textPainter != oldDelegate._textPainter;
  }
}

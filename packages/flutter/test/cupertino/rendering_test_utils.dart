// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// A [CustomPainter] that invokes a callback when it paints.
class TestCallbackPainter extends CustomPainter {
  const TestCallbackPainter({required this.onPaint});

  /// The callback to invoke during [paint].
  final VoidCallback onPaint;

  @override
  void paint(Canvas canvas, Size size) {
    onPaint();
  }

  @override
  bool shouldRepaint(TestCallbackPainter oldPainter) => true;
}

// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';

import '../rendering/mock_canvas.dart';

void main() {
  test('BoxDecoration with BorderRadiusDirectional', () {
    const BoxDecoration decoration = BoxDecoration(
      color: Color(0xFF000000),
      borderRadius: BorderRadiusDirectional.only(topStart: Radius.circular(100.0)),
    );
    final BoxPainter painter = decoration.createBoxPainter();
    const Size size = Size(1000.0, 1000.0);
    expect(
      (Canvas canvas) {
        painter.paint(
          canvas,
          const Offset(0.0, 0.0),
          const ImageConfiguration(size: size, textDirection: TextDirection.rtl),
        );
      },
      paints
        ..rrect(rrect: RRect.fromRectAndCorners(Offset.zero & size, topRight: const Radius.circular(100.0)))
    );
    expect(decoration.hitTest(size, const Offset(10.0, 10.0), textDirection: TextDirection.rtl), isTrue);
    expect(decoration.hitTest(size, const Offset(990.0, 10.0), textDirection: TextDirection.rtl), isFalse);
    expect(
      (Canvas canvas) {
        painter.paint(
          canvas,
          const Offset(0.0, 0.0),
          const ImageConfiguration(size: size, textDirection: TextDirection.ltr),
        );
      },
      paints
        ..rrect(rrect: RRect.fromRectAndCorners(Offset.zero & size, topLeft: const Radius.circular(100.0)))
    );
    expect(decoration.hitTest(size, const Offset(10.0, 10.0), textDirection: TextDirection.ltr), isFalse);
    expect(decoration.hitTest(size, const Offset(990.0, 10.0), textDirection: TextDirection.ltr), isTrue);
  });

  test('BoxDecoration with LinearGradient using AlignmentDirectional', () {
    const BoxDecoration decoration = BoxDecoration(
      color: Color(0xFF000000),
      gradient: LinearGradient(
        begin: AlignmentDirectional.centerStart,
        end: AlignmentDirectional.bottomEnd,
        colors: <Color>[
          Color(0xFF000000),
          Color(0xFFFFFFFF),
        ],
      ),
    );
    final BoxPainter painter = decoration.createBoxPainter();
    const Size size = Size(1000.0, 1000.0);
    expect(
        (Canvas canvas) {
        painter.paint(
          canvas,
          const Offset(0.0, 0.0),
          const ImageConfiguration(size: size, textDirection: TextDirection.rtl),
        );
      },
      paints..rect(rect: Offset.zero & size),
    );
  });
}

// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';

import '../rendering/mock_canvas.dart';

void main() {
  test('BoxDecoration with BorderRadiusDirectional', () {
    const BoxDecoration decoration = const BoxDecoration(
      color: const Color(0xFF000000),
      borderRadius: const BorderRadiusDirectional.only(topStart: const Radius.circular(100.0)),
    );
    final BoxPainter painter = decoration.createBoxPainter();
    const Size size = const Size(1000.0, 1000.0);
    expect(
      (Canvas canvas) {
        painter.paint(
          canvas,
          const Offset(0.0, 0.0),
          const ImageConfiguration(size: size, textDirection: TextDirection.rtl),
        );
      },
      paints
        ..rrect(rrect: new RRect.fromRectAndCorners(Offset.zero & size, topRight: const Radius.circular(100.0)))
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
        ..rrect(rrect: new RRect.fromRectAndCorners(Offset.zero & size, topLeft: const Radius.circular(100.0)))
    );
    expect(decoration.hitTest(size, const Offset(10.0, 10.0), textDirection: TextDirection.ltr), isFalse);
    expect(decoration.hitTest(size, const Offset(990.0, 10.0), textDirection: TextDirection.ltr), isTrue);
  });

  test('BoxDecoration with LinearGradient using AlignmentDirectional', () {
    const BoxDecoration decoration = const BoxDecoration(
      color: const Color(0xFF000000),
      gradient: const LinearGradient(
        begin: AlignmentDirectional.centerStart,
        end: AlignmentDirectional.bottomEnd,
        colors: const<Color>[
          const Color(0xFF000000),
          const Color(0xFFFFFFFF),
        ],
      ),
    );
    final BoxPainter painter = decoration.createBoxPainter();
    const Size size = const Size(1000.0, 1000.0);
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

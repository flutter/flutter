// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../rendering/rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding(); // initializes the imageCache

  test('ShapeDecoration constructor', () {
    const Color colorR = Color(0xffff0000);
    const Color colorG = Color(0xff00ff00);
    const Gradient gradient = LinearGradient(colors: <Color>[colorR, colorG]);
    expect(const ShapeDecoration(shape: Border()), const ShapeDecoration(shape: Border()));
    expect(() => ShapeDecoration(color: colorR, gradient: nonconst(gradient), shape: const Border()), throwsAssertionError);
    expect(() => ShapeDecoration(gradient: nonconst(gradient), shape: null), throwsAssertionError);
    expect(
      ShapeDecoration.fromBoxDecoration(const BoxDecoration(shape: BoxShape.circle)),
      const ShapeDecoration(shape: CircleBorder(side: BorderSide.none)),
    );
    expect(
      ShapeDecoration.fromBoxDecoration(BoxDecoration(shape: BoxShape.rectangle, borderRadius: BorderRadiusDirectional.circular(100.0))),
      ShapeDecoration(shape: RoundedRectangleBorder(borderRadius: BorderRadiusDirectional.circular(100.0))),
    );
    expect(
      ShapeDecoration.fromBoxDecoration(BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colorG))),
      const ShapeDecoration(shape: CircleBorder(side: BorderSide(color: colorG))),
    );
    expect(
      ShapeDecoration.fromBoxDecoration(BoxDecoration(shape: BoxShape.rectangle, border: Border.all(color: colorR))),
      ShapeDecoration(shape: Border.all(color: colorR)),
    );
    expect(
      ShapeDecoration.fromBoxDecoration(const BoxDecoration(shape: BoxShape.rectangle, border: BorderDirectional(start: BorderSide()))),
      const ShapeDecoration(shape: BorderDirectional(start: BorderSide())),
    );
  });

  test('ShapeDecoration.lerp and hit test', () {
    const Decoration a = ShapeDecoration(shape: CircleBorder());
    const Decoration b = ShapeDecoration(shape: RoundedRectangleBorder());
    expect(Decoration.lerp(a, b, 0.0), a);
    expect(Decoration.lerp(a, b, 1.0), b);
    const Size size = Size(200.0, 100.0); // at t=0.5, width will be 150 (x=25 to x=175).
    expect(a.hitTest(size, const Offset(20.0, 50.0)), isFalse);
    expect(Decoration.lerp(a, b, 0.1).hitTest(size, const Offset(20.0, 50.0)), isFalse);
    expect(Decoration.lerp(a, b, 0.5).hitTest(size, const Offset(20.0, 50.0)), isFalse);
    expect(Decoration.lerp(a, b, 0.9).hitTest(size, const Offset(20.0, 50.0)), isTrue);
    expect(b.hitTest(size, const Offset(20.0, 50.0)), isTrue);
  });

  test('ShapeDecoration.image RTL test', () {
    final List<int> log = <int>[];
    final ShapeDecoration decoration = ShapeDecoration(
      shape: const CircleBorder(),
      image: DecorationImage(
        image: TestImageProvider(),
        alignment: AlignmentDirectional.bottomEnd,
      ),
    );
    final BoxPainter painter = decoration.createBoxPainter(() { log.add(0); });
    expect((Canvas canvas) => painter.paint(canvas, Offset.zero, const ImageConfiguration(size: Size(100.0, 100.0))), paintsAssertion);
    expect(
      (Canvas canvas) {
        return painter.paint(
          canvas,
          const Offset(20.0, -40.0),
          const ImageConfiguration(
            size: Size(1000.0, 1000.0),
            textDirection: TextDirection.rtl,
          ),
        );
      },
      paints
        ..drawImageRect(source: Rect.fromLTRB(0.0, 0.0, 100.0, 200.0), destination: Rect.fromLTRB(20.0, 1000.0 - 40.0 - 200.0, 20.0 + 100.0, 1000.0 - 40.0))
    );
    expect(
      (Canvas canvas) {
        return painter.paint(
          canvas,
          Offset.zero,
          const ImageConfiguration(
            size: Size(100.0, 200.0),
            textDirection: TextDirection.ltr,
          ),
        );
      },
      isNot(paints..image()) // we always use drawImageRect
    );
    expect(log, isEmpty);
  });
}

class TestImageProvider extends ImageProvider<TestImageProvider> {
  @override
  Future<TestImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<TestImageProvider>(this);
  }

  @override
  ImageStreamCompleter load(TestImageProvider key) {
    return OneFrameImageStreamCompleter(
      SynchronousFuture<ImageInfo>(ImageInfo(image: TestImage(), scale: 1.0)),
    );
  }
}

class TestImage implements ui.Image {
  @override
  int get width => 100;

  @override
  int get height => 200;

  @override
  void dispose() { }

  @override
  Future<ByteData> toByteData({ui.ImageByteFormat format}) async {
    throw UnsupportedError('Cannot encode test image');
  }
}

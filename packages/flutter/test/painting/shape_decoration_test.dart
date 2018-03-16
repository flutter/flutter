// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../rendering/rendering_tester.dart';

void main() {
  new TestRenderingFlutterBinding(); // initializes the imageCache

  test('ShapeDecoration constructor', () {
    const Color colorR = const Color(0xffff0000);
    const Color colorG = const Color(0xff00ff00);
    const Gradient gradient = const LinearGradient(colors: const <Color>[colorR, colorG]);
    expect(const ShapeDecoration(shape: const Border()), const ShapeDecoration(shape: const Border()));
    expect(() => new ShapeDecoration(color: colorR, gradient: nonconst(gradient), shape: const Border()), throwsAssertionError);
    expect(() => new ShapeDecoration(gradient: nonconst(gradient), shape: null), throwsAssertionError);
    expect(
      new ShapeDecoration.fromBoxDecoration(const BoxDecoration(shape: BoxShape.circle)),
      const ShapeDecoration(shape: const CircleBorder(side: BorderSide.none)),
    );
    expect(
      new ShapeDecoration.fromBoxDecoration(new BoxDecoration(shape: BoxShape.rectangle, borderRadius: new BorderRadiusDirectional.circular(100.0))),
      new ShapeDecoration(shape: new RoundedRectangleBorder(borderRadius: new BorderRadiusDirectional.circular(100.0))),
    );
    expect(
      new ShapeDecoration.fromBoxDecoration(new BoxDecoration(shape: BoxShape.circle, border: new Border.all(color: colorG))),
      const ShapeDecoration(shape: const CircleBorder(side: const BorderSide(color: colorG))),
    );
    expect(
      new ShapeDecoration.fromBoxDecoration(new BoxDecoration(shape: BoxShape.rectangle, border: new Border.all(color: colorR))),
      new ShapeDecoration(shape: new Border.all(color: colorR)),
    );
    expect(
      new ShapeDecoration.fromBoxDecoration(const BoxDecoration(shape: BoxShape.rectangle, border: const BorderDirectional(start: const BorderSide()))),
      const ShapeDecoration(shape: const BorderDirectional(start: const BorderSide())),
    );
  });

  test('ShapeDecoration.lerp and hit test', () {
    const Decoration a = const ShapeDecoration(shape: const CircleBorder());
    const Decoration b = const ShapeDecoration(shape: const RoundedRectangleBorder());
    expect(Decoration.lerp(a, b, 0.0), a);
    expect(Decoration.lerp(a, b, 1.0), b);
    const Size size = const Size(200.0, 100.0); // at t=0.5, width will be 150 (x=25 to x=175).
    expect(a.hitTest(size, const Offset(20.0, 50.0)), isFalse);
    expect(Decoration.lerp(a, b, 0.1).hitTest(size, const Offset(20.0, 50.0)), isFalse);
    expect(Decoration.lerp(a, b, 0.5).hitTest(size, const Offset(20.0, 50.0)), isFalse);
    expect(Decoration.lerp(a, b, 0.9).hitTest(size, const Offset(20.0, 50.0)), isTrue);
    expect(b.hitTest(size, const Offset(20.0, 50.0)), isTrue);
  });

  test('ShapeDecoration.image RTL test', () {
    final List<int> log = <int>[];
    final ShapeDecoration decoration = new ShapeDecoration(
      shape: const CircleBorder(),
      image: new DecorationImage(
        image: new TestImageProvider(),
        alignment: AlignmentDirectional.bottomEnd,
      ),
    );
    final BoxPainter painter = decoration.createBoxPainter(() { log.add(0); });
    expect((Canvas canvas) => painter.paint(canvas, Offset.zero, const ImageConfiguration(size: const Size(100.0, 100.0))), paintsAssertion);
    expect(
      (Canvas canvas) {
        return painter.paint(
          canvas,
          const Offset(20.0, -40.0),
          const ImageConfiguration(
            size: const Size(1000.0, 1000.0),
            textDirection: TextDirection.rtl,
          ),
        );
      },
      paints
        ..drawImageRect(source: new Rect.fromLTRB(0.0, 0.0, 100.0, 200.0), destination: new Rect.fromLTRB(20.0, 1000.0 - 40.0 - 200.0, 20.0 + 100.0, 1000.0 - 40.0))
    );
    expect(
      (Canvas canvas) {
        return painter.paint(
          canvas,
          Offset.zero,
          const ImageConfiguration(
            size: const Size(100.0, 200.0),
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
    return new SynchronousFuture<TestImageProvider>(this);
  }

  @override
  ImageStreamCompleter load(TestImageProvider key) {
    return new OneFrameImageStreamCompleter(
      new SynchronousFuture<ImageInfo>(new ImageInfo(image: new TestImage(), scale: 1.0)),
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
}

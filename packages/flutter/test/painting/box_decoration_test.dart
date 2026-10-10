// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestBoxBorder extends BoxBorder {
  const _TestBoxBorder(this.width);

  final double width;

  @override
  BorderSide get bottom => BorderSide(width: width);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  bool get isUniform => true;

  @override
  BorderSide get top => BorderSide(width: width);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {}

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is _TestBoxBorder) {
      return _TestBoxBorder(lerpDouble(a.width, width, t)!);
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is _TestBoxBorder) {
      return _TestBoxBorder(lerpDouble(width, b.width, t)!);
    }
    return super.lerpTo(b, t);
  }

  @override
  ShapeBorder scale(double t) => _TestBoxBorder(width * t);

  @override
  bool operator ==(Object other) => other is _TestBoxBorder && other.width == width;

  @override
  int get hashCode => width.hashCode;
}

void main() {
  test('BoxDecoration.lerp identical a,b', () {
    expect(BoxDecoration.lerp(null, null, 0), null);
    const decoration = BoxDecoration();
    expect(identical(BoxDecoration.lerp(decoration, decoration, 0.5), decoration), true);
  });

  test('BoxDecoration.lerp supports custom BoxBorder subclasses', () {
    final BoxDecoration? decoration = BoxDecoration.lerp(
      const BoxDecoration(border: _TestBoxBorder(2.0)),
      const BoxDecoration(border: _TestBoxBorder(6.0)),
      0.25,
    );

    expect(decoration!.border, const _TestBoxBorder(3.0));
  });

  test('BoxDecoration.scale supports custom BoxBorder subclasses', () {
    final BoxDecoration decoration = const BoxDecoration(border: _TestBoxBorder(8.0)).scale(0.25);

    expect(decoration.border, const _TestBoxBorder(2.0));
  });

  test('BoxDecoration with BorderRadiusDirectional', () {
    const decoration = BoxDecoration(
      color: Color(0xFF000000),
      borderRadius: BorderRadiusDirectional.only(topStart: Radius.circular(100.0)),
    );
    final BoxPainter painter = decoration.createBoxPainter();
    const size = Size(1000.0, 1000.0);
    expect(
      (Canvas canvas) {
        painter.paint(
          canvas,
          Offset.zero,
          const ImageConfiguration(size: size, textDirection: TextDirection.rtl),
        );
      },
      paints..rrect(
        rrect: RRect.fromRectAndCorners(Offset.zero & size, topRight: const Radius.circular(100.0)),
      ),
    );
    expect(
      decoration.hitTest(size, const Offset(10.0, 10.0), textDirection: TextDirection.rtl),
      isTrue,
    );
    expect(
      decoration.hitTest(size, const Offset(990.0, 10.0), textDirection: TextDirection.rtl),
      isFalse,
    );
    expect(
      (Canvas canvas) {
        painter.paint(
          canvas,
          Offset.zero,
          const ImageConfiguration(size: size, textDirection: TextDirection.ltr),
        );
      },
      paints..rrect(
        rrect: RRect.fromRectAndCorners(Offset.zero & size, topLeft: const Radius.circular(100.0)),
      ),
    );
    expect(
      decoration.hitTest(size, const Offset(10.0, 10.0), textDirection: TextDirection.ltr),
      isFalse,
    );
    expect(
      decoration.hitTest(size, const Offset(990.0, 10.0), textDirection: TextDirection.ltr),
      isTrue,
    );
  });

  test('BoxDecoration with LinearGradient using AlignmentDirectional', () {
    const decoration = BoxDecoration(
      color: Color(0xFF000000),
      gradient: LinearGradient(
        begin: AlignmentDirectional.centerStart,
        end: AlignmentDirectional.bottomEnd,
        colors: <Color>[Color(0xFF000000), Color(0xFFFFFFFF)],
      ),
    );
    final BoxPainter painter = decoration.createBoxPainter();
    const size = Size(1000.0, 1000.0);
    expect((Canvas canvas) {
      painter.paint(
        canvas,
        Offset.zero,
        const ImageConfiguration(size: size, textDirection: TextDirection.rtl),
      );
    }, paints..rect(rect: Offset.zero & size));
  });

  test('BoxDecoration.getClipPath with borderRadius', () {
    const double radius = 10;
    const decoration = BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(radius)));
    const rect = Rect.fromLTWH(0.0, 0.0, 100.0, 20.0);
    final Path clipPath = decoration.getClipPath(rect, TextDirection.ltr);
    final Matcher isLookLikeExpectedPath = isPathThat(
      includes: const <Offset>[Offset(30.0, 10.0), Offset(50.0, 10.0)],
      excludes: const <Offset>[Offset(1.0, 1.0), Offset(99.0, 19.0)],
    );
    expect(clipPath, isLookLikeExpectedPath);
  });

  test('BoxDecoration.getClipPath with shape BoxShape.circle', () {
    const decoration = BoxDecoration(shape: BoxShape.circle);
    const rect = Rect.fromLTWH(0.0, 0.0, 100.0, 20.0);
    final Path clipPath = decoration.getClipPath(rect, TextDirection.ltr);
    final Matcher isLookLikeExpectedPath = isPathThat(
      includes: const <Offset>[Offset(50.0, 0.0), Offset(40.0, 10.0)],
      excludes: const <Offset>[Offset(40.0, 0.0), Offset(10.0, 10.0)],
    );
    expect(clipPath, isLookLikeExpectedPath);
  });

  test('BoxDecoration.hitTest with shape BoxShape.circle', () {
    const decoration = BoxDecoration(shape: BoxShape.circle);
    const size = Size(100.0, 20.0);

    expect(decoration.hitTest(size, const Offset(50.0, 0.0)), isTrue);
    expect(decoration.hitTest(size, const Offset(40.0, 10.0)), isTrue);
    expect(decoration.hitTest(size, const Offset(40.0, 0.0)), isFalse);
    expect(decoration.hitTest(size, const Offset(10.0, 10.0)), isFalse);
  });

  test('BoxDecorations with different blendModes are not equal', () {
    // Regression test for https://github.com/flutter/flutter/issues/100754.
    const one = BoxDecoration(color: Color(0x00000000), backgroundBlendMode: BlendMode.color);
    const two = BoxDecoration(color: Color(0x00000000), backgroundBlendMode: BlendMode.difference);
    expect(one == two, isFalse);
  });

  test(
    'BoxDecoration inset shadow paints above the background and below where a child would paint',
    () {
      const decoration = BoxDecoration(
        color: Color(0xFF00FF00),
        border: Border.fromBorderSide(BorderSide(color: Color(0xFF0000FF), width: 2)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Color(0xFFFF0000), blurRadius: 0, spreadRadius: 10, inset: true),
        ],
      );
      final List<Symbol> calls = _paintCalls(decoration, const Size(100, 80));
      expect(calls.indexOf(#drawRect), lessThan(calls.indexOf(#clipRRect)));
      expect(calls.indexOf(#clipRRect), lessThan(calls.indexOf(#drawPath)));
      expect(calls.indexOf(#drawPath), lessThan(calls.lastIndexOf(#drawRect)));
      final Path shadow = _drawnPath(decoration, const Size(100, 80));
      expect(shadow.contains(const Offset(50, 40)), isFalse);
      expect(shadow.contains(const Offset(2, 40)), isTrue);
    },
  );

  test('BoxDecoration inset shadow honors spread, offset, and directional corners', () {
    const decoration = BoxDecoration(
      borderRadius: BorderRadiusDirectional.only(topStart: Radius.circular(12)),
      boxShadow: <BoxShadow>[
        BoxShadow(blurRadius: 0, spreadRadius: 10, offset: Offset(20, 0), inset: true),
      ],
    );
    final TestRecordingCanvas canvas = TestRecordingCanvas();
    decoration.createBoxPainter().paint(
      canvas,
      Offset.zero,
      const ImageConfiguration(size: Size(100, 100), textDirection: TextDirection.rtl),
    );
    final RRect clip =
        canvas.invocations
                .firstWhere((RecordedInvocation call) => call.invocation.memberName == #clipRRect)
                .invocation
                .positionalArguments
                .first
            as RRect;
    expect(clip.trRadius, const Radius.circular(12));
    expect(clip.tlRadius, Radius.zero);
    final Path shadow =
        canvas.invocations
                .firstWhere((RecordedInvocation call) => call.invocation.memberName == #drawPath)
                .invocation
                .positionalArguments
                .first
            as Path;
    // The hole is shifted toward the end edge and shrunk by the spread.
    expect(shadow.contains(const Offset(5, 50)), isTrue);
    expect(shadow.contains(const Offset(95, 50)), isFalse);
  });

  test('BoxDecoration ordinary inset shadow uses a rounded rectangle mask', () {
    debugDisableShadows = false;
    addTearDown(() {
      debugDisableShadows = true;
    });
    const decoration = BoxDecoration(boxShadow: <BoxShadow>[BoxShadow(blurRadius: 4, inset: true)]);
    final List<Symbol> calls = _paintCalls(decoration, const Size(100, 80));
    expect(calls, contains(#saveLayer));
    expect(calls, contains(#drawRRect));
    expect(calls, isNot(contains(#drawPath)));
  });

  test('BoxDecoration wide inset shadow keeps the inverse path', () {
    debugDisableShadows = false;
    addTearDown(() {
      debugDisableShadows = true;
    });
    const decoration = BoxDecoration(
      boxShadow: <BoxShadow>[BoxShadow(blurRadius: 80, inset: true)],
    );
    final List<Symbol> calls = _paintCalls(decoration, const Size(20, 20));
    expect(calls, contains(#drawPath));
    expect(calls, isNot(contains(#saveLayer)));
  });

  test('BoxDecoration outer shadows stay behind the background', () {
    const decoration = BoxDecoration(
      color: Color(0xFFFFFFFF),
      boxShadow: <BoxShadow>[BoxShadow(blurRadius: 4), BoxShadow(blurRadius: 0, inset: true)],
    );
    final List<Symbol> calls = _paintCalls(decoration, const Size(40, 40));
    final int outer = calls.indexOf(#drawRect);
    final int background = calls.indexOf(#drawRect, outer + 1);
    final int clip = calls.indexOf(#clipRRect);
    expect(outer, lessThan(background));
    expect(background, lessThan(clip));
  });
}

List<Symbol> _paintCalls(BoxDecoration decoration, Size size) {
  final TestRecordingCanvas canvas = TestRecordingCanvas();
  decoration.createBoxPainter().paint(
    canvas,
    Offset.zero,
    ImageConfiguration(size: size, textDirection: TextDirection.ltr),
  );
  return canvas.invocations.map((RecordedInvocation call) => call.invocation.memberName).toList();
}

Path _drawnPath(BoxDecoration decoration, Size size) {
  final TestRecordingCanvas canvas = TestRecordingCanvas();
  decoration.createBoxPainter().paint(
    canvas,
    Offset.zero,
    ImageConfiguration(size: size, textDirection: TextDirection.ltr),
  );
  return canvas.invocations
          .firstWhere((RecordedInvocation call) => call.invocation.memberName == #drawPath)
          .invocation
          .positionalArguments
          .first
      as Path;
}

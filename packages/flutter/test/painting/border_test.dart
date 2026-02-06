// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class TestCanvas implements Canvas {
  final List<Invocation> invocations = <Invocation>[];

  @override
  void noSuchMethod(Invocation invocation) {
    invocations.add(invocation);
  }
}

void main() {
  test('Border.fromBorderSide constructor', () {
    const side = BorderSide();
    const border = Border.fromBorderSide(side);
    expect(border.left, same(side));
    expect(border.top, same(side));
    expect(border.right, same(side));
    expect(border.bottom, same(side));
  });

  test('Border.symmetric constructor', () {
    const side1 = BorderSide(color: Color(0xFFFFFFFF));
    const side2 = BorderSide();
    const border = Border.symmetric(vertical: side1, horizontal: side2);
    expect(border.left, same(side1));
    expect(border.top, same(side2));
    expect(border.right, same(side1));
    expect(border.bottom, same(side2));
  });

  test('Border.merge', () {
    const magenta3 = BorderSide(color: Color(0xFFFF00FF), width: 3.0);
    const magenta6 = BorderSide(color: Color(0xFFFF00FF), width: 6.0);
    const yellow2 = BorderSide(color: Color(0xFFFFFF00), width: 2.0);
    const yellowNone0 = BorderSide(color: Color(0xFFFFFF00), width: 0.0, style: BorderStyle.none);
    expect(
      Border.merge(const Border(top: yellow2), const Border(right: magenta3)),
      const Border(top: yellow2, right: magenta3),
    );
    expect(
      Border.merge(const Border(bottom: magenta3), const Border(bottom: magenta3)),
      const Border(bottom: magenta6),
    );
    expect(
      Border.merge(const Border(left: magenta3, right: yellowNone0), const Border(right: yellow2)),
      const Border(left: magenta3, right: yellow2),
    );
    expect(Border.merge(const Border(), const Border()), const Border());
    expect(
      () => Border.merge(const Border(left: magenta3), const Border(left: yellow2)),
      throwsAssertionError,
    );
  });

  test('Border.add', () {
    const magenta3 = BorderSide(color: Color(0xFFFF00FF), width: 3.0);
    const magenta6 = BorderSide(color: Color(0xFFFF00FF), width: 6.0);
    const yellow2 = BorderSide(color: Color(0xFFFFFF00), width: 2.0);
    const yellowNone0 = BorderSide(color: Color(0xFFFFFF00), width: 0.0, style: BorderStyle.none);
    expect(
      const Border(top: yellow2) + const Border(right: magenta3),
      const Border(top: yellow2, right: magenta3),
    );
    expect(
      const Border(bottom: magenta3) + const Border(bottom: magenta3),
      const Border(bottom: magenta6),
    );
    expect(
      const Border(left: magenta3, right: yellowNone0) + const Border(right: yellow2),
      const Border(left: magenta3, right: yellow2),
    );
    expect(const Border() + const Border(), const Border());
    expect(
      const Border(left: magenta3) + const Border(left: yellow2),
      isNot(isA<Border>()), // see shape_border_test.dart for better tests of this case
    );
    const b3 = Border(top: magenta3);
    const b6 = Border(top: magenta6);
    expect(b3 + b3, b6);
    const b0 = Border(top: yellowNone0);
    const bZ = Border();
    expect(b0 + b0, bZ);
    expect(bZ + bZ, bZ);
    expect(b0 + bZ, bZ);
    expect(bZ + b0, bZ);
  });

  test('Border.scale', () {
    const magenta3 = BorderSide(color: Color(0xFFFF00FF), width: 3.0);
    const magenta6 = BorderSide(color: Color(0xFFFF00FF), width: 6.0);
    const yellow2 = BorderSide(color: Color(0xFFFFFF00), width: 2.0);
    const yellowNone0 = BorderSide(color: Color(0xFFFFFF00), width: 0.0, style: BorderStyle.none);
    const b3 = Border(left: magenta3);
    const b6 = Border(left: magenta6);
    expect(b3.scale(2.0), b6);
    const bY0 = Border(top: yellowNone0);
    expect(bY0.scale(3.0), bY0);
    const bY2 = Border(top: yellow2);
    expect(bY2.scale(0.0), bY0);
  });

  test('Border.dimensions', () {
    expect(
      const Border(
        left: BorderSide(width: 2.0),
        top: BorderSide(width: 3.0),
        bottom: BorderSide(width: 5.0),
        right: BorderSide(width: 7.0),
      ).dimensions,
      const EdgeInsets.fromLTRB(2.0, 3.0, 7.0, 5.0),
    );
  });

  test('Border.isUniform', () {
    expect(
      const Border(
        left: BorderSide(width: 3.0),
        top: BorderSide(width: 3.0),
        right: BorderSide(width: 3.0),
        bottom: BorderSide(width: 3.1),
      ).isUniform,
      false,
    );
    expect(
      const Border(
        left: BorderSide(width: 3.0),
        top: BorderSide(width: 3.0),
        right: BorderSide(width: 3.0),
        bottom: BorderSide(width: 3.0),
      ).isUniform,
      true,
    );
    expect(
      const Border(
        left: BorderSide(color: Color(0xFFFFFFFE)),
        top: BorderSide(color: Color(0xFFFFFFFF)),
        right: BorderSide(color: Color(0xFFFFFFFF)),
        bottom: BorderSide(color: Color(0xFFFFFFFF)),
      ).isUniform,
      false,
    );
    expect(
      const Border(
        left: BorderSide(color: Color(0xFFFFFFFF)),
        top: BorderSide(color: Color(0xFFFFFFFF)),
        right: BorderSide(color: Color(0xFFFFFFFF)),
        bottom: BorderSide(color: Color(0xFFFFFFFF)),
      ).isUniform,
      true,
    );
    expect(
      const Border(
        left: BorderSide(style: BorderStyle.none),
        top: BorderSide(style: BorderStyle.none),
        right: BorderSide(style: BorderStyle.none),
        bottom: BorderSide(width: 0.0),
      ).isUniform,
      false,
    );
    expect(
      const Border(
        left: BorderSide(style: BorderStyle.none),
        top: BorderSide(style: BorderStyle.none),
        right: BorderSide(style: BorderStyle.none),
        bottom: BorderSide(width: 0.0),
      ).isUniform,
      false,
    );
    expect(
      const Border(
        left: BorderSide(style: BorderStyle.none),
        top: BorderSide(style: BorderStyle.none),
        right: BorderSide(style: BorderStyle.none),
      ).isUniform,
      false,
    );
    expect(
      const Border(
        left: BorderSide(),
        top: BorderSide(strokeAlign: BorderSide.strokeAlignCenter),
        right: BorderSide(strokeAlign: BorderSide.strokeAlignOutside),
      ).isUniform,
      false,
    );
    expect(const Border().isUniform, true);
    expect(const Border().isUniform, true);
  });

  test('Border.lerp', () {
    const visualWithTop10 = Border(top: BorderSide(width: 10.0));
    const atMinus100 = Border(left: BorderSide(width: 0.0), right: BorderSide(width: 300.0));
    const at0 = Border(left: BorderSide(width: 100.0), right: BorderSide(width: 200.0));
    const at25 = Border(left: BorderSide(width: 125.0), right: BorderSide(width: 175.0));
    const at75 = Border(left: BorderSide(width: 175.0), right: BorderSide(width: 125.0));
    const at100 = Border(left: BorderSide(width: 200.0), right: BorderSide(width: 100.0));
    const at200 = Border(left: BorderSide(width: 300.0), right: BorderSide(width: 0.0));

    expect(Border.lerp(null, null, -1.0), null);
    expect(Border.lerp(visualWithTop10, null, -1.0), const Border(top: BorderSide(width: 20.0)));
    expect(Border.lerp(null, visualWithTop10, -1.0), const Border());
    expect(Border.lerp(at0, at100, -1.0), atMinus100);

    expect(Border.lerp(null, null, 0.0), null);
    expect(Border.lerp(visualWithTop10, null, 0.0), const Border(top: BorderSide(width: 10.0)));
    expect(Border.lerp(null, visualWithTop10, 0.0), const Border());
    expect(Border.lerp(at0, at100, 0.0), at0);

    expect(Border.lerp(null, null, 0.25), null);
    expect(Border.lerp(visualWithTop10, null, 0.25), const Border(top: BorderSide(width: 7.5)));
    expect(Border.lerp(null, visualWithTop10, 0.25), const Border(top: BorderSide(width: 2.5)));
    expect(Border.lerp(at0, at100, 0.25), at25);

    expect(Border.lerp(null, null, 0.75), null);
    expect(Border.lerp(visualWithTop10, null, 0.75), const Border(top: BorderSide(width: 2.5)));
    expect(Border.lerp(null, visualWithTop10, 0.75), const Border(top: BorderSide(width: 7.5)));
    expect(Border.lerp(at0, at100, 0.75), at75);

    expect(Border.lerp(null, null, 1.0), null);
    expect(Border.lerp(visualWithTop10, null, 1.0), const Border());
    expect(Border.lerp(null, visualWithTop10, 1.0), const Border(top: BorderSide(width: 10.0)));
    expect(Border.lerp(at0, at100, 1.0), at100);

    expect(Border.lerp(null, null, 2.0), null);
    expect(Border.lerp(visualWithTop10, null, 2.0), const Border());
    expect(Border.lerp(null, visualWithTop10, 2.0), const Border(top: BorderSide(width: 20.0)));
    expect(Border.lerp(at0, at100, 2.0), at200);
  });

  test('Border - throws correct exception with strokeAlign', () {
    late FlutterError error;
    try {
      final canvas = TestCanvas();
      // Border.all supports all StrokeAlign values.
      // Border() supports [BorderSide.strokeAlignInside] only.
      const Border(
        left: BorderSide(strokeAlign: BorderSide.strokeAlignCenter, color: Color(0xff000001)),
        right: BorderSide(strokeAlign: BorderSide.strokeAlignOutside, color: Color(0xff000002)),
      ).paint(canvas, const Rect.fromLTWH(10.0, 20.0, 30.0, 40.0));
    } on FlutterError catch (e) {
      error = e;
    }
    expect(error, isNotNull);
    expect(error.diagnostics.length, 1);
    expect(
      error.diagnostics[0].toStringDeep(),
      'A Border can only draw strokeAlign different than\nBorderSide.strokeAlignInside on borders with uniform colors.\n',
    );
  });

  test('Border.dimension', () {
    final insideBorder = Border.all(width: 10);
    expect(insideBorder.dimensions, const EdgeInsets.all(10));

    final centerBorder = Border.all(width: 10, strokeAlign: BorderSide.strokeAlignCenter);
    expect(centerBorder.dimensions, const EdgeInsets.all(5));

    final outsideBorder = Border.all(width: 10, strokeAlign: BorderSide.strokeAlignOutside);
    expect(outsideBorder.dimensions, EdgeInsets.zero);

    const insideSide = BorderSide(width: 10);
    const insideBorderDirectional = BorderDirectional(
      top: insideSide,
      bottom: insideSide,
      start: insideSide,
      end: insideSide,
    );
    expect(insideBorderDirectional.dimensions, const EdgeInsetsDirectional.all(10));

    const centerSide = BorderSide(width: 10, strokeAlign: BorderSide.strokeAlignCenter);
    const centerBorderDirectional = BorderDirectional(
      top: centerSide,
      bottom: centerSide,
      start: centerSide,
      end: centerSide,
    );
    expect(centerBorderDirectional.dimensions, const EdgeInsetsDirectional.all(5));

    const outsideSide = BorderSide(width: 10, strokeAlign: BorderSide.strokeAlignOutside);
    const outsideBorderDirectional = BorderDirectional(
      top: outsideSide,
      bottom: outsideSide,
      start: outsideSide,
      end: outsideSide,
    );
    expect(outsideBorderDirectional.dimensions, EdgeInsetsDirectional.zero);

    const nonUniformBorder = Border(
      left: BorderSide(width: 5),
      top: BorderSide(width: 10, strokeAlign: BorderSide.strokeAlignCenter),
      right: BorderSide(width: 15, strokeAlign: BorderSide.strokeAlignOutside),
      bottom: BorderSide(width: 20),
    );
    expect(nonUniformBorder.dimensions, const EdgeInsets.fromLTRB(5, 5, 0, 20));

    const nonUniformBorderDirectional = BorderDirectional(
      start: BorderSide(width: 5),
      top: BorderSide(width: 10, strokeAlign: BorderSide.strokeAlignCenter),
      end: BorderSide(width: 15, strokeAlign: BorderSide.strokeAlignOutside),
      bottom: BorderSide(width: 20),
    );
    expect(
      nonUniformBorderDirectional.dimensions,
      const EdgeInsetsDirectional.fromSTEB(5, 5, 0, 20),
    );

    const uniformWidthNonUniformStrokeAlignBorder = Border(
      left: BorderSide(width: 10),
      top: BorderSide(width: 10, strokeAlign: BorderSide.strokeAlignCenter),
      right: BorderSide(width: 10, strokeAlign: BorderSide.strokeAlignOutside),
      bottom: BorderSide(width: 10),
    );
    expect(
      uniformWidthNonUniformStrokeAlignBorder.dimensions,
      const EdgeInsets.fromLTRB(10, 5, 0, 10),
    );

    const uniformWidthNonUniformStrokeAlignBorderDirectional = BorderDirectional(
      start: BorderSide(width: 10),
      top: BorderSide(width: 10, strokeAlign: BorderSide.strokeAlignCenter),
      end: BorderSide(width: 10, strokeAlign: BorderSide.strokeAlignOutside),
      bottom: BorderSide(width: 10),
    );
    expect(
      uniformWidthNonUniformStrokeAlignBorderDirectional.dimensions,
      const EdgeInsetsDirectional.fromSTEB(10, 5, 0, 10),
    );
  });

  testWidgets('Non-Uniform Border variations', (WidgetTester tester) async {
    Widget buildWidget({
      required BoxBorder border,
      BorderRadius? borderRadius,
      BoxShape boxShape = BoxShape.rectangle,
    }) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: DecoratedBox(
          decoration: BoxDecoration(shape: boxShape, border: border, borderRadius: borderRadius),
        ),
      );
    }

    // This is used to test every allowed non-uniform border combination.
    const allowedBorderVariations = Border(
      left: BorderSide(width: 5),
      top: BorderSide(width: 10, strokeAlign: BorderSide.strokeAlignCenter),
      right: BorderSide(width: 15, strokeAlign: BorderSide.strokeAlignOutside),
      bottom: BorderSide(width: 20),
    );

    // This falls into non-uniform border because of strokeAlign.
    await tester.pumpWidget(buildWidget(border: allowedBorderVariations));
    expect(
      tester.takeException(),
      isAssertionError,
      reason: 'Border with non-uniform strokeAlign should fail.',
    );

    await tester.pumpWidget(
      buildWidget(border: allowedBorderVariations, borderRadius: BorderRadius.circular(25)),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      buildWidget(border: allowedBorderVariations, boxShape: BoxShape.circle),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      buildWidget(
        border: const Border(
          left: BorderSide(width: 5, style: BorderStyle.none),
          top: BorderSide(width: 10),
          right: BorderSide(width: 15),
          bottom: BorderSide(width: 20),
        ),
        borderRadius: BorderRadius.circular(25),
      ),
    );
    expect(
      tester.takeException(),
      isNull,
      reason: 'Border with non-uniform styles should work with borderRadius.',
    );

    await tester.pumpWidget(
      buildWidget(
        border: const Border(
          left: BorderSide(width: 5, color: Color(0xff123456)),
          top: BorderSide(width: 10),
          right: BorderSide(width: 15),
          bottom: BorderSide(width: 20),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
    );
    expect(
      tester.takeException(),
      isAssertionError,
      reason: 'Border with non-uniform colors should fail with borderRadius.',
    );

    await tester.pumpWidget(
      buildWidget(
        border: const Border(bottom: BorderSide(width: 0)),
        borderRadius: BorderRadius.zero,
      ),
    );
    expect(
      tester.takeException(),
      isNull,
      reason: 'Border with a side.width == 0 should work without borderRadius (hairline border).',
    );

    await tester.pumpWidget(
      buildWidget(
        border: const Border(bottom: BorderSide(width: 0)),
        borderRadius: BorderRadius.circular(40),
      ),
    );
    expect(
      tester.takeException(),
      isAssertionError,
      reason: 'Border with width == 0 and borderRadius should fail (hairline border).',
    );

    // Tests for BorderDirectional.
    const allowedBorderDirectionalVariations = BorderDirectional(
      start: BorderSide(width: 5),
      top: BorderSide(width: 10, strokeAlign: BorderSide.strokeAlignCenter),
      end: BorderSide(width: 15, strokeAlign: BorderSide.strokeAlignOutside),
      bottom: BorderSide(width: 20),
    );

    await tester.pumpWidget(buildWidget(border: allowedBorderDirectionalVariations));
    expect(tester.takeException(), isAssertionError);

    await tester.pumpWidget(
      buildWidget(
        border: allowedBorderDirectionalVariations,
        borderRadius: BorderRadius.circular(25),
      ),
    );
    expect(
      tester.takeException(),
      isNull,
      reason: 'BorderDirectional should not fail with uniform styles and colors.',
    );

    await tester.pumpWidget(
      buildWidget(border: allowedBorderDirectionalVariations, boxShape: BoxShape.circle),
    );
    expect(tester.takeException(), isNull);
  });

  test('Compound borders with differing preferPaintInteriors', () {
    expect(ShapeWithInterior().preferPaintInterior, isTrue);
    expect(ShapeWithoutInterior().preferPaintInterior, isFalse);
    expect((ShapeWithInterior() + ShapeWithInterior()).preferPaintInterior, isTrue);
    expect((ShapeWithInterior() + ShapeWithoutInterior()).preferPaintInterior, isFalse);
    expect((ShapeWithoutInterior() + ShapeWithInterior()).preferPaintInterior, isFalse);
    expect((ShapeWithoutInterior() + ShapeWithoutInterior()).preferPaintInterior, isFalse);
  });

  test('BoxBorder factories', () {
    const side1 = BorderSide();
    const side2 = BorderSide(width: 2);
    const side3 = BorderSide(width: 3);
    const side4 = BorderSide(width: 4);
    expect(
      BoxBorder.fromLTRB(left: side1, top: side2, right: side3, bottom: side4),
      const Border(left: side1, top: side2, right: side3, bottom: side4),
    );
    expect(BoxBorder.all(width: 4), Border.all(width: 4));
    expect(const BoxBorder.fromBorderSide(side3), const Border.fromBorderSide(side3));
    expect(
      const BoxBorder.symmetric(horizontal: side2, vertical: side3),
      const Border.symmetric(horizontal: side2, vertical: side3),
    );
    expect(
      BoxBorder.fromSTEB(start: side1, top: side2, end: side3, bottom: side4),
      const BorderDirectional(start: side1, top: side2, end: side3, bottom: side4),
    );
  });
}

class ShapeWithInterior extends ShapeBorder {
  @override
  bool get preferPaintInterior => true;

  @override
  ShapeBorder scale(double t) {
    return this;
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path();
  }

  @override
  void paintInterior(Canvas canvas, Rect rect, Paint paint, {TextDirection? textDirection}) {}

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}
}

class ShapeWithoutInterior extends ShapeBorder {
  @override
  bool get preferPaintInterior => false;

  @override
  ShapeBorder scale(double t) {
    return this;
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path();
  }

  @override
  void paintInterior(Canvas canvas, Rect rect, Paint paint, {TextDirection? textDirection}) {}

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}
}

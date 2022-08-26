// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  test('Compound borders', () {
    final Border b1 = Border.all(color: const Color(0xFF00FF00));
    final Border b2 = Border.all(color: const Color(0xFF0000FF));
    expect(
      (b1 + b2).toString(),
      'Border.all(BorderSide(color: Color(0xff00ff00))) + '
      'Border.all(BorderSide(color: Color(0xff0000ff)))',
    );
    expect(
      (b1 + (b2 + b2)).toString(),
      'Border.all(BorderSide(color: Color(0xff00ff00))) + '
      'Border.all(BorderSide(color: Color(0xff0000ff), width: 2.0))',
    );
    expect(
      ((b1 + b2) + b2).toString(),
      'Border.all(BorderSide(color: Color(0xff00ff00))) + '
      'Border.all(BorderSide(color: Color(0xff0000ff), width: 2.0))',
    );
    expect((b1 + b2) + b2, b1 + (b2 + b2));
    expect(
      (b1 + b2).scale(3.0).toString(),
      'Border.all(BorderSide(color: Color(0xff00ff00), width: 3.0)) + '
      'Border.all(BorderSide(color: Color(0xff0000ff), width: 3.0))',
    );
    expect(
      (b1 + b2).scale(0.0).toString(),
      'Border.all(BorderSide(color: Color(0xff00ff00), width: 0.0, style: none)) + '
      'Border.all(BorderSide(color: Color(0xff0000ff), width: 0.0, style: none))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 0.0).toString(),
      'Border.all(BorderSide(color: Color(0xff0000ff))) + '
      'Border.all(BorderSide(color: Color(0xff00ff00)))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 0.25).toString(),
      'Border.all(BorderSide(color: Color(0xff003fbf))) + '
      'Border.all(BorderSide(color: Color(0xff00bf3f)))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 0.5).toString(),
      'Border.all(BorderSide(color: Color(0xff007f7f))) + '
      'Border.all(BorderSide(color: Color(0xff007f7f)))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 1.0).toString(),
      'Border.all(BorderSide(color: Color(0xff00ff00))) + '
      'Border.all(BorderSide(color: Color(0xff0000ff)))',
    );
    expect((b1 + b2).dimensions, const EdgeInsets.all(2.0));
    const Rect rect = Rect.fromLTRB(11.0, 15.0, 299.0, 175.0);
    expect((Canvas canvas) => (b1 + b2).paint(canvas, rect), paints
      ..rect(rect: rect.deflate(0.5), color: b2.top.color)
      ..rect(rect: rect.deflate(1.5), color: b1.top.color),
    );
    expect((b1 + b2 + b1).dimensions, const EdgeInsets.all(3.0));
    expect((Canvas canvas) => (b1 + b2 + b1).paint(canvas, rect), paints
      ..rect(rect: rect.deflate(0.5), color: b1.top.color)
      ..rect(rect: rect.deflate(1.5), color: b2.top.color)
      ..rect(rect: rect.deflate(2.5), color: b1.top.color),
    );
  });

  test('Compound borders', () {
    const BorderSide side1 = BorderSide(color: Color(0xFF00FF00));
    const BorderSide side2 = BorderSide(color: Color(0xFF0000FF));
    const BorderDirectional b1 = BorderDirectional(top: side1, start: side1, end: side1, bottom: side1);
    const BorderDirectional b2 = BorderDirectional(top: side2, start: side2, end: side2, bottom: side2);
    expect(
      (b1 + b2).toString(),
      'BorderDirectional(top: BorderSide(color: Color(0xff00ff00)), start: BorderSide(color: Color(0xff00ff00)), end: BorderSide(color: Color(0xff00ff00)), bottom: BorderSide(color: Color(0xff00ff00))) + '
      'BorderDirectional(top: BorderSide(color: Color(0xff0000ff)), start: BorderSide(color: Color(0xff0000ff)), end: BorderSide(color: Color(0xff0000ff)), bottom: BorderSide(color: Color(0xff0000ff)))',
    );
    expect(
      (b1 + (b2 + b2)).toString(),
      'BorderDirectional(top: BorderSide(color: Color(0xff00ff00)), start: BorderSide(color: Color(0xff00ff00)), end: BorderSide(color: Color(0xff00ff00)), bottom: BorderSide(color: Color(0xff00ff00))) + '
      'BorderDirectional(top: BorderSide(color: Color(0xff0000ff), width: 2.0), start: BorderSide(color: Color(0xff0000ff), width: 2.0), end: BorderSide(color: Color(0xff0000ff), width: 2.0), bottom: BorderSide(color: Color(0xff0000ff), width: 2.0))',
    );
    expect(
      ((b1 + b2) + b2).toString(),
      'BorderDirectional(top: BorderSide(color: Color(0xff00ff00)), start: BorderSide(color: Color(0xff00ff00)), end: BorderSide(color: Color(0xff00ff00)), bottom: BorderSide(color: Color(0xff00ff00))) + '
      'BorderDirectional(top: BorderSide(color: Color(0xff0000ff), width: 2.0), start: BorderSide(color: Color(0xff0000ff), width: 2.0), end: BorderSide(color: Color(0xff0000ff), width: 2.0), bottom: BorderSide(color: Color(0xff0000ff), width: 2.0))',
    );
    expect((b1 + b2) + b2, b1 + (b2 + b2));
    expect(
      (b1 + b2).scale(3.0).toString(),
      'BorderDirectional(top: BorderSide(color: Color(0xff00ff00), width: 3.0), start: BorderSide(color: Color(0xff00ff00), width: 3.0), end: BorderSide(color: Color(0xff00ff00), width: 3.0), bottom: BorderSide(color: Color(0xff00ff00), width: 3.0)) + '
      'BorderDirectional(top: BorderSide(color: Color(0xff0000ff), width: 3.0), start: BorderSide(color: Color(0xff0000ff), width: 3.0), end: BorderSide(color: Color(0xff0000ff), width: 3.0), bottom: BorderSide(color: Color(0xff0000ff), width: 3.0))',
    );
    expect(
      (b1 + b2).scale(0.0).toString(),
      'BorderDirectional(top: BorderSide(color: Color(0xff00ff00), width: 0.0, style: none), start: BorderSide(color: Color(0xff00ff00), width: 0.0, style: none), end: BorderSide(color: Color(0xff00ff00), width: 0.0, style: none), bottom: BorderSide(color: Color(0xff00ff00), width: 0.0, style: none)) + '
      'BorderDirectional(top: BorderSide(color: Color(0xff0000ff), width: 0.0, style: none), start: BorderSide(color: Color(0xff0000ff), width: 0.0, style: none), end: BorderSide(color: Color(0xff0000ff), width: 0.0, style: none), bottom: BorderSide(color: Color(0xff0000ff), width: 0.0, style: none))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 0.0).toString(),
      'BorderDirectional(top: BorderSide(color: Color(0xff0000ff)), start: BorderSide(color: Color(0xff0000ff)), end: BorderSide(color: Color(0xff0000ff)), bottom: BorderSide(color: Color(0xff0000ff))) + '
      'BorderDirectional(top: BorderSide(color: Color(0xff00ff00)), start: BorderSide(color: Color(0xff00ff00)), end: BorderSide(color: Color(0xff00ff00)), bottom: BorderSide(color: Color(0xff00ff00)))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 0.25).toString(),
      'BorderDirectional(top: BorderSide(color: Color(0xff003fbf)), start: BorderSide(color: Color(0xff003fbf)), end: BorderSide(color: Color(0xff003fbf)), bottom: BorderSide(color: Color(0xff003fbf))) + '
      'BorderDirectional(top: BorderSide(color: Color(0xff00bf3f)), start: BorderSide(color: Color(0xff00bf3f)), end: BorderSide(color: Color(0xff00bf3f)), bottom: BorderSide(color: Color(0xff00bf3f)))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 0.5).toString(),
      'BorderDirectional(top: BorderSide(color: Color(0xff007f7f)), start: BorderSide(color: Color(0xff007f7f)), end: BorderSide(color: Color(0xff007f7f)), bottom: BorderSide(color: Color(0xff007f7f))) + '
      'BorderDirectional(top: BorderSide(color: Color(0xff007f7f)), start: BorderSide(color: Color(0xff007f7f)), end: BorderSide(color: Color(0xff007f7f)), bottom: BorderSide(color: Color(0xff007f7f)))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 1.0).toString(),
      'BorderDirectional(top: BorderSide(color: Color(0xff00ff00)), start: BorderSide(color: Color(0xff00ff00)), end: BorderSide(color: Color(0xff00ff00)), bottom: BorderSide(color: Color(0xff00ff00))) + '
      'BorderDirectional(top: BorderSide(color: Color(0xff0000ff)), start: BorderSide(color: Color(0xff0000ff)), end: BorderSide(color: Color(0xff0000ff)), bottom: BorderSide(color: Color(0xff0000ff)))',
    );
    expect((b1 + b2).dimensions, const EdgeInsetsDirectional.fromSTEB(2.0, 2.0, 2.0, 2.0));
    const Rect rect = Rect.fromLTRB(11.0, 15.0, 299.0, 175.0);
    expect((Canvas canvas) => (b1 + b2).paint(canvas, rect, textDirection: TextDirection.rtl), paints
      ..rect(rect: rect.deflate(0.5), color: b2.top.color)
      ..rect(rect: rect.deflate(1.5), color: b1.top.color),
    );
    expect((b1 + b2 + b1).dimensions, const EdgeInsetsDirectional.fromSTEB(3.0, 3.0, 3.0, 3.0));
    expect((Canvas canvas) => (b1 + b2 + b1).paint(canvas, rect, textDirection: TextDirection.rtl), paints
      ..rect(rect: rect.deflate(0.5), color: b1.top.color)
      ..rect(rect: rect.deflate(1.5), color: b2.top.color)
      ..rect(rect: rect.deflate(2.5), color: b1.top.color),
    );
  });
}

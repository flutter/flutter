// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  test('Compound borders', () {
    final Border b1 = Border.all(color: const Color(0xFF00FF00));
    final Border b2 = Border.all(color: const Color(0xFF0000FF));
    expect(
      (b1 + b2).toString(),
      'Border.all(BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid)) + '
      'Border.all(BorderSide(Color(0xff0000ff), 1.0, BorderStyle.solid))',
    );
    expect(
      (b1 + (b2 + b2)).toString(),
      'Border.all(BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid)) + '
      'Border.all(BorderSide(Color(0xff0000ff), 2.0, BorderStyle.solid))',
    );
    expect(
      ((b1 + b2) + b2).toString(),
      'Border.all(BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid)) + '
      'Border.all(BorderSide(Color(0xff0000ff), 2.0, BorderStyle.solid))',
    );
    expect((b1 + b2) + b2, b1 + (b2 + b2));
    expect(
      (b1 + b2).scale(3.0).toString(),
      'Border.all(BorderSide(Color(0xff00ff00), 3.0, BorderStyle.solid)) + '
      'Border.all(BorderSide(Color(0xff0000ff), 3.0, BorderStyle.solid))',
    );
    expect(
      (b1 + b2).scale(0.0).toString(),
      'Border.all(BorderSide(Color(0xff00ff00), 0.0, BorderStyle.none)) + '
      'Border.all(BorderSide(Color(0xff0000ff), 0.0, BorderStyle.none))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 0.0).toString(),
      'Border.all(BorderSide(Color(0xff0000ff), 1.0, BorderStyle.solid)) + '
      'Border.all(BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 0.25).toString(),
      'Border.all(BorderSide(Color(0xff003fbf), 1.0, BorderStyle.solid)) + '
      'Border.all(BorderSide(Color(0xff00bf3f), 1.0, BorderStyle.solid))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 0.5).toString(),
      'Border.all(BorderSide(Color(0xff007f7f), 1.0, BorderStyle.solid)) + '
      'Border.all(BorderSide(Color(0xff007f7f), 1.0, BorderStyle.solid))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 1.0).toString(),
      'Border.all(BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid)) + '
      'Border.all(BorderSide(Color(0xff0000ff), 1.0, BorderStyle.solid))',
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
      'BorderDirectional(top: BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid), start: BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid), end: BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid), bottom: BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid)) + '
      'BorderDirectional(top: BorderSide(Color(0xff0000ff), 1.0, BorderStyle.solid), start: BorderSide(Color(0xff0000ff), 1.0, BorderStyle.solid), end: BorderSide(Color(0xff0000ff), 1.0, BorderStyle.solid), bottom: BorderSide(Color(0xff0000ff), 1.0, BorderStyle.solid))',
    );
    expect(
      (b1 + (b2 + b2)).toString(),
      'BorderDirectional(top: BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid), start: BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid), end: BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid), bottom: BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid)) + '
      'BorderDirectional(top: BorderSide(Color(0xff0000ff), 2.0, BorderStyle.solid), start: BorderSide(Color(0xff0000ff), 2.0, BorderStyle.solid), end: BorderSide(Color(0xff0000ff), 2.0, BorderStyle.solid), bottom: BorderSide(Color(0xff0000ff), 2.0, BorderStyle.solid))',
    );
    expect(
      ((b1 + b2) + b2).toString(),
      'BorderDirectional(top: BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid), start: BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid), end: BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid), bottom: BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid)) + '
      'BorderDirectional(top: BorderSide(Color(0xff0000ff), 2.0, BorderStyle.solid), start: BorderSide(Color(0xff0000ff), 2.0, BorderStyle.solid), end: BorderSide(Color(0xff0000ff), 2.0, BorderStyle.solid), bottom: BorderSide(Color(0xff0000ff), 2.0, BorderStyle.solid))',
    );
    expect((b1 + b2) + b2, b1 + (b2 + b2));
    expect(
      (b1 + b2).scale(3.0).toString(),
      'BorderDirectional(top: BorderSide(Color(0xff00ff00), 3.0, BorderStyle.solid), start: BorderSide(Color(0xff00ff00), 3.0, BorderStyle.solid), end: BorderSide(Color(0xff00ff00), 3.0, BorderStyle.solid), bottom: BorderSide(Color(0xff00ff00), 3.0, BorderStyle.solid)) + '
      'BorderDirectional(top: BorderSide(Color(0xff0000ff), 3.0, BorderStyle.solid), start: BorderSide(Color(0xff0000ff), 3.0, BorderStyle.solid), end: BorderSide(Color(0xff0000ff), 3.0, BorderStyle.solid), bottom: BorderSide(Color(0xff0000ff), 3.0, BorderStyle.solid))',
    );
    expect(
      (b1 + b2).scale(0.0).toString(),
      'BorderDirectional(top: BorderSide(Color(0xff00ff00), 0.0, BorderStyle.none), start: BorderSide(Color(0xff00ff00), 0.0, BorderStyle.none), end: BorderSide(Color(0xff00ff00), 0.0, BorderStyle.none), bottom: BorderSide(Color(0xff00ff00), 0.0, BorderStyle.none)) + '
      'BorderDirectional(top: BorderSide(Color(0xff0000ff), 0.0, BorderStyle.none), start: BorderSide(Color(0xff0000ff), 0.0, BorderStyle.none), end: BorderSide(Color(0xff0000ff), 0.0, BorderStyle.none), bottom: BorderSide(Color(0xff0000ff), 0.0, BorderStyle.none))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 0.0).toString(),
      'BorderDirectional(top: BorderSide(Color(0xff0000ff), 1.0, BorderStyle.solid), start: BorderSide(Color(0xff0000ff), 1.0, BorderStyle.solid), end: BorderSide(Color(0xff0000ff), 1.0, BorderStyle.solid), bottom: BorderSide(Color(0xff0000ff), 1.0, BorderStyle.solid)) + '
      'BorderDirectional(top: BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid), start: BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid), end: BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid), bottom: BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 0.25).toString(),
      'BorderDirectional(top: BorderSide(Color(0xff003fbf), 1.0, BorderStyle.solid), start: BorderSide(Color(0xff003fbf), 1.0, BorderStyle.solid), end: BorderSide(Color(0xff003fbf), 1.0, BorderStyle.solid), bottom: BorderSide(Color(0xff003fbf), 1.0, BorderStyle.solid)) + '
      'BorderDirectional(top: BorderSide(Color(0xff00bf3f), 1.0, BorderStyle.solid), start: BorderSide(Color(0xff00bf3f), 1.0, BorderStyle.solid), end: BorderSide(Color(0xff00bf3f), 1.0, BorderStyle.solid), bottom: BorderSide(Color(0xff00bf3f), 1.0, BorderStyle.solid))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 0.5).toString(),
      'BorderDirectional(top: BorderSide(Color(0xff007f7f), 1.0, BorderStyle.solid), start: BorderSide(Color(0xff007f7f), 1.0, BorderStyle.solid), end: BorderSide(Color(0xff007f7f), 1.0, BorderStyle.solid), bottom: BorderSide(Color(0xff007f7f), 1.0, BorderStyle.solid)) + '
      'BorderDirectional(top: BorderSide(Color(0xff007f7f), 1.0, BorderStyle.solid), start: BorderSide(Color(0xff007f7f), 1.0, BorderStyle.solid), end: BorderSide(Color(0xff007f7f), 1.0, BorderStyle.solid), bottom: BorderSide(Color(0xff007f7f), 1.0, BorderStyle.solid))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 1.0).toString(),
      'BorderDirectional(top: BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid), start: BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid), end: BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid), bottom: BorderSide(Color(0xff00ff00), 1.0, BorderStyle.solid)) + '
      'BorderDirectional(top: BorderSide(Color(0xff0000ff), 1.0, BorderStyle.solid), start: BorderSide(Color(0xff0000ff), 1.0, BorderStyle.solid), end: BorderSide(Color(0xff0000ff), 1.0, BorderStyle.solid), bottom: BorderSide(Color(0xff0000ff), 1.0, BorderStyle.solid))',
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

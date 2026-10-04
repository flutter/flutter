// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Border.lerp identical a,b', () {
    expect(Border.lerp(null, null, 0), null);
    const border = Border();
    expect(identical(Border.lerp(border, border, 0.5), border), true);
  });

  test('BoxBorder.lerp identical a,b', () {
    expect(BoxBorder.lerp(null, null, 0), null);
    const BoxBorder border = Border();
    expect(identical(BoxBorder.lerp(border, border, 0.5), border), true);
  });

  test('BorderDirectional.lep identical a,b', () {
    expect(BorderDirectional.lerp(null, null, 0), null);
    const border = BorderDirectional();
    expect(identical(ShapeBorder.lerp(border, border, 0.5), border), true);
  });

  test('OutlinedBorder.lep identical a,b', () {
    expect(OutlinedBorder.lerp(null, null, 0), null);
    const OutlinedBorder border = RoundedRectangleBorder();
    expect(identical(OutlinedBorder.lerp(border, border, 0.5), border), true);
  });

  test('ShapeBorder.lep identical a,b', () {
    expect(ShapeBorder.lerp(null, null, 0), null);
    const ShapeBorder border = CircleBorder();
    expect(identical(ShapeBorder.lerp(border, border, 0.5), border), true);
  });

  test('ShapeBorder.lerp tries equivalent reverse interpolation', () {
    expect(
      ShapeBorder.lerp(const _LerpBorder(), const _ReverseLerpToBorder(), 0.25),
      const _LerpBorder(0.75),
    );
    expect(
      ShapeBorder.lerp(const _ReverseLerpFromBorder(), const _LerpBorder(), 0.25),
      const _LerpBorder(0.75),
    );
  });

  test('OutlinedBorder.lerp tries equivalent reverse interpolation', () {
    expect(
      OutlinedBorder.lerp(const _LerpBorder(), const _ReverseLerpToBorder(), 0.25),
      const _LerpBorder(0.75),
    );
    expect(
      OutlinedBorder.lerp(const _ReverseLerpFromBorder(), const _LerpBorder(), 0.25),
      const _LerpBorder(0.75),
    );
  });

  test('Outlined shape borders interpolate symmetrically', () {
    const borders = <OutlinedBorder>[
      RoundedRectangleBorder(),
      StadiumBorder(),
      CircleBorder(),
      OvalBorder(),
      StarBorder(),
    ];

    for (final a in borders) {
      for (final b in borders) {
        expect(
          ShapeBorder.lerp(a, b, 0.25).runtimeType,
          ShapeBorder.lerp(b, a, 0.75).runtimeType,
          reason: 'ShapeBorder.lerp($a, $b, 0.25)',
        );
        expect(
          OutlinedBorder.lerp(a, b, 0.25).runtimeType,
          OutlinedBorder.lerp(b, a, 0.75).runtimeType,
          reason: 'OutlinedBorder.lerp($a, $b, 0.25)',
        );
      }
    }
  });

  test('Compound borders', () {
    final b1 = Border.all(color: const Color(0xFF00FF00));
    final b2 = Border.all(color: const Color(0xFF0000FF));
    expect(
      (b1 + b2).toString(),
      'Border.all(BorderSide(color: ${const Color(0xff00ff00)})) + '
      'Border.all(BorderSide(color: ${const Color(0xff0000ff)}))',
    );
    expect(
      (b1 + (b2 + b2)).toString(),
      'Border.all(BorderSide(color: ${const Color(0xff00ff00)})) + '
      'Border.all(BorderSide(color: ${const Color(0xff0000ff)}, width: 2.0))',
    );
    expect(
      ((b1 + b2) + b2).toString(),
      'Border.all(BorderSide(color: ${const Color(0xff00ff00)})) + '
      'Border.all(BorderSide(color: ${const Color(0xff0000ff)}, width: 2.0))',
    );
    expect((b1 + b2) + b2, b1 + (b2 + b2));
    expect(
      (b1 + b2).scale(3.0).toString(),
      'Border.all(BorderSide(color: ${const Color(0xff00ff00)}, width: 3.0)) + '
      'Border.all(BorderSide(color: ${const Color(0xff0000ff)}, width: 3.0))',
    );
    expect(
      (b1 + b2).scale(0.0).toString(),
      'Border.all(BorderSide(color: ${const Color(0xff00ff00)}, width: 0.0, style: none)) + '
      'Border.all(BorderSide(color: ${const Color(0xff0000ff)}, width: 0.0, style: none))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 0.0).toString(),
      'Border.all(BorderSide(color: ${const Color(0xff0000ff)})) + '
      'Border.all(BorderSide(color: ${const Color(0xff00ff00)}))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 0.20).toString(),
      'Border.all(BorderSide(color: ${const Color(0xff0033cc)})) + '
      'Border.all(BorderSide(color: ${const Color(0xff00cc33)}))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 1 / 3).toString(),
      'Border.all(BorderSide(color: ${const Color(0xff0055aa)})) + '
      'Border.all(BorderSide(color: ${const Color(0xff00aa55)}))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 1.0).toString(),
      'Border.all(BorderSide(color: ${const Color(0xff00ff00)})) + '
      'Border.all(BorderSide(color: ${const Color(0xff0000ff)}))',
    );
    expect((b1 + b2).dimensions, const EdgeInsets.all(2.0));
    const rect = Rect.fromLTRB(11.0, 15.0, 299.0, 175.0);
    expect(
      (Canvas canvas) => (b1 + b2).paint(canvas, rect),
      paints
        ..rect(rect: rect.deflate(0.5), color: b2.top.color)
        ..rect(rect: rect.deflate(1.5), color: b1.top.color),
    );
    expect((b1 + b2 + b1).dimensions, const EdgeInsets.all(3.0));
    expect(
      (Canvas canvas) => (b1 + b2 + b1).paint(canvas, rect),
      paints
        ..rect(rect: rect.deflate(0.5), color: b1.top.color)
        ..rect(rect: rect.deflate(1.5), color: b2.top.color)
        ..rect(rect: rect.deflate(2.5), color: b1.top.color),
    );
  });

  test('Compound borders', () {
    const side1 = BorderSide(color: Color(0xFF00FF00));
    const side2 = BorderSide(color: Color(0xFF0000FF));
    const b1 = BorderDirectional(top: side1, start: side1, end: side1, bottom: side1);
    const b2 = BorderDirectional(top: side2, start: side2, end: side2, bottom: side2);
    expect(
      (b1 + b2).toString(),
      'BorderDirectional(top: BorderSide(color: ${const Color(0xff00ff00)}), start: BorderSide(color: ${const Color(0xff00ff00)}), end: BorderSide(color: ${const Color(0xff00ff00)}), bottom: BorderSide(color: ${const Color(0xff00ff00)})) + '
      'BorderDirectional(top: BorderSide(color: ${const Color(0xff0000ff)}), start: BorderSide(color: ${const Color(0xff0000ff)}), end: BorderSide(color: ${const Color(0xff0000ff)}), bottom: BorderSide(color: ${const Color(0xff0000ff)}))',
    );
    expect(
      (b1 + (b2 + b2)).toString(),
      'BorderDirectional(top: BorderSide(color: ${const Color(0xff00ff00)}), start: BorderSide(color: ${const Color(0xff00ff00)}), end: BorderSide(color: ${const Color(0xff00ff00)}), bottom: BorderSide(color: ${const Color(0xff00ff00)})) + '
      'BorderDirectional(top: BorderSide(color: ${const Color(0xff0000ff)}, width: 2.0), start: BorderSide(color: ${const Color(0xff0000ff)}, width: 2.0), end: BorderSide(color: ${const Color(0xff0000ff)}, width: 2.0), bottom: BorderSide(color: ${const Color(0xff0000ff)}, width: 2.0))',
    );
    expect(
      ((b1 + b2) + b2).toString(),
      'BorderDirectional(top: BorderSide(color: ${const Color(0xff00ff00)}), start: BorderSide(color: ${const Color(0xff00ff00)}), end: BorderSide(color: ${const Color(0xff00ff00)}), bottom: BorderSide(color: ${const Color(0xff00ff00)})) + '
      'BorderDirectional(top: BorderSide(color: ${const Color(0xff0000ff)}, width: 2.0), start: BorderSide(color: ${const Color(0xff0000ff)}, width: 2.0), end: BorderSide(color: ${const Color(0xff0000ff)}, width: 2.0), bottom: BorderSide(color: ${const Color(0xff0000ff)}, width: 2.0))',
    );
    expect((b1 + b2) + b2, b1 + (b2 + b2));
    expect(
      (b1 + b2).scale(3.0).toString(),
      'BorderDirectional(top: BorderSide(color: ${const Color(0xff00ff00)}, width: 3.0), start: BorderSide(color: ${const Color(0xff00ff00)}, width: 3.0), end: BorderSide(color: ${const Color(0xff00ff00)}, width: 3.0), bottom: BorderSide(color: ${const Color(0xff00ff00)}, width: 3.0)) + '
      'BorderDirectional(top: BorderSide(color: ${const Color(0xff0000ff)}, width: 3.0), start: BorderSide(color: ${const Color(0xff0000ff)}, width: 3.0), end: BorderSide(color: ${const Color(0xff0000ff)}, width: 3.0), bottom: BorderSide(color: ${const Color(0xff0000ff)}, width: 3.0))',
    );
    expect(
      (b1 + b2).scale(0.0).toString(),
      'BorderDirectional(top: BorderSide(color: ${const Color(0xff00ff00)}, width: 0.0, style: none), start: BorderSide(color: ${const Color(0xff00ff00)}, width: 0.0, style: none), end: BorderSide(color: ${const Color(0xff00ff00)}, width: 0.0, style: none), bottom: BorderSide(color: ${const Color(0xff00ff00)}, width: 0.0, style: none)) + '
      'BorderDirectional(top: BorderSide(color: ${const Color(0xff0000ff)}, width: 0.0, style: none), start: BorderSide(color: ${const Color(0xff0000ff)}, width: 0.0, style: none), end: BorderSide(color: ${const Color(0xff0000ff)}, width: 0.0, style: none), bottom: BorderSide(color: ${const Color(0xff0000ff)}, width: 0.0, style: none))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 0.0).toString(),
      'BorderDirectional(top: BorderSide(color: ${const Color(0xff0000ff)}), start: BorderSide(color: ${const Color(0xff0000ff)}), end: BorderSide(color: ${const Color(0xff0000ff)}), bottom: BorderSide(color: ${const Color(0xff0000ff)})) + '
      'BorderDirectional(top: BorderSide(color: ${const Color(0xff00ff00)}), start: BorderSide(color: ${const Color(0xff00ff00)}), end: BorderSide(color: ${const Color(0xff00ff00)}), bottom: BorderSide(color: ${const Color(0xff00ff00)}))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 0.20).toString(),
      'BorderDirectional(top: BorderSide(color: ${const Color(0xff0033cc)}), start: BorderSide(color: ${const Color(0xff0033cc)}), end: BorderSide(color: ${const Color(0xff0033cc)}), bottom: BorderSide(color: ${const Color(0xff0033cc)})) + '
      'BorderDirectional(top: BorderSide(color: ${const Color(0xff00cc33)}), start: BorderSide(color: ${const Color(0xff00cc33)}), end: BorderSide(color: ${const Color(0xff00cc33)}), bottom: BorderSide(color: ${const Color(0xff00cc33)}))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 1 / 3).toString(),
      'BorderDirectional(top: BorderSide(color: ${const Color(0xff0055aa)}), start: BorderSide(color: ${const Color(0xff0055aa)}), end: BorderSide(color: ${const Color(0xff0055aa)}), bottom: BorderSide(color: ${const Color(0xff0055aa)})) + '
      'BorderDirectional(top: BorderSide(color: ${const Color(0xff00aa55)}), start: BorderSide(color: ${const Color(0xff00aa55)}), end: BorderSide(color: ${const Color(0xff00aa55)}), bottom: BorderSide(color: ${const Color(0xff00aa55)}))',
    );
    expect(
      ShapeBorder.lerp(b2 + b1, b1 + b2, 1.0).toString(),
      'BorderDirectional(top: BorderSide(color: ${const Color(0xff00ff00)}), start: BorderSide(color: ${const Color(0xff00ff00)}), end: BorderSide(color: ${const Color(0xff00ff00)}), bottom: BorderSide(color: ${const Color(0xff00ff00)})) + '
      'BorderDirectional(top: BorderSide(color: ${const Color(0xff0000ff)}), start: BorderSide(color: ${const Color(0xff0000ff)}), end: BorderSide(color: ${const Color(0xff0000ff)}), bottom: BorderSide(color: ${const Color(0xff0000ff)}))',
    );
    expect((b1 + b2).dimensions, const EdgeInsetsDirectional.fromSTEB(2.0, 2.0, 2.0, 2.0));
    const rect = Rect.fromLTRB(11.0, 15.0, 299.0, 175.0);
    expect(
      (Canvas canvas) => (b1 + b2).paint(canvas, rect, textDirection: TextDirection.rtl),
      paints
        ..rect(rect: rect.deflate(0.5), color: b2.top.color)
        ..rect(rect: rect.deflate(1.5), color: b1.top.color),
    );
    expect((b1 + b2 + b1).dimensions, const EdgeInsetsDirectional.fromSTEB(3.0, 3.0, 3.0, 3.0));
    expect(
      (Canvas canvas) => (b1 + b2 + b1).paint(canvas, rect, textDirection: TextDirection.rtl),
      paints
        ..rect(rect: rect.deflate(0.5), color: b1.top.color)
        ..rect(rect: rect.deflate(1.5), color: b2.top.color)
        ..rect(rect: rect.deflate(2.5), color: b1.top.color),
    );
  });
}

// A border that does not know how to interpolate with any other class, used
// both as the lerp partner of the borders below and as their result, recording
// through value equality the `t` value that the lerp method received.
class _LerpBorder extends OutlinedBorder {
  const _LerpBorder([this.t, BorderSide side = BorderSide.none]) : super(side: side);

  final double? t;

  @override
  _LerpBorder copyWith({BorderSide? side}) => _LerpBorder(t, side ?? this.side);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()..addRect(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path()..addRect(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => _LerpBorder(t, side.scale(t));

  @override
  bool operator ==(Object other) {
    return other is _LerpBorder &&
        other.runtimeType == runtimeType &&
        other.t == t &&
        other.side == side;
  }

  @override
  int get hashCode => Object.hash(runtimeType, t, side);

  @override
  String toString() => '_LerpBorder(t: $t)';
}

// A border that can interpolate with [_LerpBorder] only through its own
// [lerpTo], so that lerping it with a [_LerpBorder] succeeds only through the
// reversed `b.lerpTo(a, 1.0 - t)` call.
class _ReverseLerpToBorder extends _LerpBorder {
  const _ReverseLerpToBorder();

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    return b is _LerpBorder ? _LerpBorder(t) : super.lerpTo(b, t);
  }
}

// Same as [_ReverseLerpToBorder], but exercising the reversed
// `a.lerpFrom(b, 1.0 - t)` call instead.
class _ReverseLerpFromBorder extends _LerpBorder {
  const _ReverseLerpFromBorder();

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    return a is _LerpBorder ? _LerpBorder(t) : super.lerpFrom(a, t);
  }
}

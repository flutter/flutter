// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';

void main() {
  test('BorderSide control test', () {
    const BorderSide side1 = BorderSide();
    final BorderSide side2 = side1.copyWith(
      color: const Color(0xFF00FFFF),
      width: 2.0,
      style: BorderStyle.solid,
    );

    expect(side1, hasOneLineDescription);
    expect(side1.hashCode, isNot(equals(side2.hashCode)));

    expect(side2.color, equals(const Color(0xFF00FFFF)));
    expect(side2.width, equals(2.0));
    expect(side2.style, equals(BorderStyle.solid));

    expect(BorderSide.lerp(side1, side2, 0.0), equals(side1));
    expect(BorderSide.lerp(side1, side2, 1.0), equals(side2));
    expect(BorderSide.lerp(side1, side2, 0.5), equals(BorderSide(
      color: Color.lerp(const Color(0xFF000000), const Color(0xFF00FFFF), 0.5),
      width: 1.5,
      style: BorderStyle.solid,
    )));

    final BorderSide side3 = side2.copyWith(style: BorderStyle.none);
    BorderSide interpolated = BorderSide.lerp(side2, side3, 0.2);
    expect(interpolated.style, equals(BorderStyle.solid));
    expect(interpolated.color, equals(side2.color.withOpacity(0.8)));

    interpolated = BorderSide.lerp(side3, side2, 0.2);
    expect(interpolated.style, equals(BorderStyle.solid));
    expect(interpolated.color, equals(side2.color.withOpacity(0.2)));
  });

  test('BorderSide toString test', () {
    const BorderSide side1 = BorderSide();
    final BorderSide side2 = side1.copyWith(
      color: const Color(0xFF00FFFF),
      width: 2.0,
      style: BorderStyle.solid,
    );

    expect(side1.toString(), equals('BorderSide(Color(0xff000000), 1.0, BorderStyle.solid)'));
    expect(side2.toString(), equals('BorderSide(Color(0xff00ffff), 2.0, BorderStyle.solid)'));
  });

  test('Border control test', () {
    final Border border1 = Border.all(width: 4.0);
    final Border border2 = Border.lerp(null, border1, 0.25);
    final Border border3 = Border.lerp(border1, null, 0.25);

    expect(border1, hasOneLineDescription);
    expect(border1.hashCode, isNot(equals(border2.hashCode)));

    expect(border2.top.width, equals(1.0));
    expect(border3.bottom.width, equals(3.0));

    final Border border4 = Border.lerp(border2, border3, 0.5);
    expect(border4.left.width, equals(2.0));
  });

  test('Border toString test', () {
    expect(
      Border.all(width: 4.0).toString(),
      equals(
        'Border.all(BorderSide(Color(0xff000000), 4.0, BorderStyle.solid))',
      ),
    );
    expect(
      const Border(
        top: BorderSide(width: 3.0),
        right: BorderSide(width: 3.0),
        bottom: BorderSide(width: 3.0),
        left: BorderSide(width: 3.0),
      ).toString(),
      equals(
        'Border.all(BorderSide(Color(0xff000000), 3.0, BorderStyle.solid))',
      ),
    );
  });

  test('BoxShadow control test', () {
    const BoxShadow shadow1 = BoxShadow(blurRadius: 4.0);
    final BoxShadow shadow2 = BoxShadow.lerp(null, shadow1, 0.25);
    final BoxShadow shadow3 = BoxShadow.lerp(shadow1, null, 0.25);

    expect(shadow1, hasOneLineDescription);
    expect(shadow1.hashCode, isNot(equals(shadow2.hashCode)));
    expect(shadow1, equals(const BoxShadow(blurRadius: 4.0)));

    expect(shadow2.blurRadius, equals(1.0));
    expect(shadow3.blurRadius, equals(3.0));

    final BoxShadow shadow4 = BoxShadow.lerp(shadow2, shadow3, 0.5);
    expect(shadow4.blurRadius, equals(2.0));

    List<BoxShadow> shadowList = BoxShadow.lerpList(
        <BoxShadow>[shadow2, shadow1], <BoxShadow>[shadow3], 0.5);
    expect(shadowList, equals(<BoxShadow>[shadow4, shadow1.scale(0.5)]));
    shadowList = BoxShadow.lerpList(
        <BoxShadow>[shadow2], <BoxShadow>[shadow3, shadow1], 0.5);
    expect(shadowList, equals(<BoxShadow>[shadow4, shadow1.scale(0.5)]));
  });

  test('BoxShadow toString test', () {
    expect(const BoxShadow(blurRadius: 4.0).toString(), equals('BoxShadow(Color(0xff000000), Offset(0.0, 0.0), 4.0, 0.0)'));
  });
}

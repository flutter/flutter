// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';

void main() {
  // Here and below, see: https://github.com/dart-lang/sdk/issues/26980
  final FlutterLogoDecoration start = FlutterLogoDecoration(
    lightColor: const Color(0xFF000000),
    darkColor: const Color(0xFFFFFFFF),
    textColor: const Color(0xFFD4F144),
    style: FlutterLogoStyle.stacked,
    margin: const EdgeInsets.all(10.0),
  );

  final FlutterLogoDecoration end = FlutterLogoDecoration(
    lightColor: const Color(0xFFFFFFFF),
    darkColor: const Color(0xFF000000),
    textColor: const Color(0xFF81D4FA),
    style: FlutterLogoStyle.stacked,
    margin: const EdgeInsets.all(10.0),
  );

  test('FlutterLogoDecoration lerp from null to null is null', () {
    final FlutterLogoDecoration logo = FlutterLogoDecoration.lerp(null, null, 0.5);
    expect(logo, isNull);
  });

  test('FlutterLogoDecoration lerp from non-null to null lerps margin', () {
    final FlutterLogoDecoration logo = FlutterLogoDecoration.lerp(start, null, 0.4);
    expect(logo.lightColor, start.lightColor);
    expect(logo.darkColor, start.darkColor);
    expect(logo.textColor, start.textColor);
    expect(logo.style, start.style);
    expect(logo.margin, start.margin * 0.4);
  });

  test('FlutterLogoDecoration lerp from null to non-null lerps margin', () {
    final FlutterLogoDecoration logo = FlutterLogoDecoration.lerp(null, end, 0.6);
    expect(logo.lightColor, end.lightColor);
    expect(logo.darkColor, end.darkColor);
    expect(logo.textColor, end.textColor);
    expect(logo.style, end.style);
    expect(logo.margin, end.margin * 0.6);
  });

  test('FlutterLogoDecoration lerps colors and margins', () {
    final FlutterLogoDecoration logo = FlutterLogoDecoration.lerp(start, end, 0.5);
    expect(logo.lightColor, Color.lerp(start.lightColor, end.lightColor, 0.5));
    expect(logo.darkColor, Color.lerp(start.darkColor, end.darkColor, 0.5));
    expect(logo.textColor, Color.lerp(start.textColor, end.textColor, 0.5));
    expect(logo.margin, EdgeInsets.lerp(start.margin, end.margin, 0.5));
  });

  test('FlutterLogoDecorationl.lerpFrom and FlutterLogoDecorationl.lerpTo', () {
    expect(Decoration.lerp(start, const BoxDecoration(), 0.0), start);
    expect(Decoration.lerp(start, const BoxDecoration(), 1.0), const BoxDecoration());
    expect(Decoration.lerp(const BoxDecoration(), end, 0.0), const BoxDecoration());
    expect(Decoration.lerp(const BoxDecoration(), end, 1.0), end);
  });

  test('FlutterLogoDecoration lerp changes styles at 0.5', () {
    FlutterLogoDecoration logo = FlutterLogoDecoration.lerp(start, end, 0.4);
    expect(logo.style, start.style);

    logo = FlutterLogoDecoration.lerp(start, end, 0.5);
    expect(logo.style, end.style);
  });

  test('FlutterLogoDecoration toString', () {
    expect(
      start.toString(),
      equals(
        'FlutterLogoDecoration(Color(0xff000000)/Color(0xffffffff) on Color(0xffd4f144), style: stacked)'
      ),
    );
    expect(
      FlutterLogoDecoration.lerp(null, end, 0.5).toString(),
      equals(
        'FlutterLogoDecoration(Color(0xffffffff)/Color(0xff000000) on Color(0xff81d4fa), style: stacked, transition -1.0:0.5)',
      ),
    );
  });
}

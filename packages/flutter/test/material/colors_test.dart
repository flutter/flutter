// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../flutter_test_alternative.dart';

const List<int> primaryKeys = <int>[50, 100, 200, 300, 400, 500, 600, 700, 800, 900];
const List<int> accentKeys = <int>[100, 200, 400, 700];

void main() {
  test('MaterialColor basic functionality', () {
    const MaterialColor color = MaterialColor(
      500,
      <int, Color>{
         50: Color(50),
        100: Color(100),
        200: Color(200),
        300: Color(300),
        400: Color(400),
        500: Color(500),
        600: Color(600),
        700: Color(700),
        800: Color(800),
        900: Color(900),
      },
    );

    expect(color.value, 500);

    expect(color[50].value, 50);
    expect(color[100].value, 100);
    expect(color[200].value, 200);
    expect(color[300].value, 300);
    expect(color[400].value, 400);
    expect(color[500].value, 500);
    expect(color[600].value, 600);
    expect(color[700].value, 700);
    expect(color[800].value, 800);
    expect(color[900].value, 900);

    expect(color.shade50.value, 50);
    expect(color.shade100.value, 100);
    expect(color.shade200.value, 200);
    expect(color.shade300.value, 300);
    expect(color.shade400.value, 400);
    expect(color.shade500.value, 500);
    expect(color.shade600.value, 600);
    expect(color.shade700.value, 700);
    expect(color.shade800.value, 800);
    expect(color.shade900.value, 900);
  });

  test('Colors swatches do not contain duplicates', () {
    for (MaterialColor color in Colors.primaries)
      expect(primaryKeys.map<Color>((int key) => color[key]).toSet().length, primaryKeys.length);

    expect(primaryKeys.map<Color>((int key) => Colors.grey[key]).toSet().length, primaryKeys.length);

    for (MaterialAccentColor color in Colors.accents)
      expect(accentKeys.map<Color>((int key) => color[key]).toSet().length, accentKeys.length);
  });

  test('All color swatch colors are opaque and equal their primary color', () {
    for (MaterialColor color in Colors.primaries) {
      expect(color.value, color.shade500.value);
      for (int key in primaryKeys) {
        expect(color[key].alpha, 0xFF);
      }
    }

    expect(Colors.grey.value, Colors.grey.shade500.value);
    for (int key in primaryKeys) {
      expect(Colors.grey[key].alpha, 0xFF);
    }

    for (MaterialAccentColor color in Colors.accents) {
      expect(color.value, color.shade200.value);
      for (int key in accentKeys) {
        expect(color[key].alpha, 0xFF);
      }
    }
  });

}

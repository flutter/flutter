// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_gallery/demo/material/menu_demo.dart';
import 'package:flutter_gallery/gallery/themes.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/rendering.dart';

void main() {
  testWidgets('Menu icon satisfies accessibility contrast ratio guidelines, light mode', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: kLightGalleryTheme,
      home: const MenuDemo(),
    ));

    await expectLater(tester, meetsGuideline(textContrastGuideline));

    final List<Element> icons = find.byWidgetPredicate((Widget widget) => widget is Icon).evaluate().toList();

    await expectLater(tester, meetsGuideline(CustomContrastGuideline(elements: icons)));
  });

  testWidgets('Menu icon satisfies accessibility contrast ratio guidelines, dark mode', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: kDarkGalleryTheme,
      home: const MenuDemo(),
    ));

    await expectLater(tester, meetsGuideline(textContrastGuideline));

    final List<Element> icons = find.byWidgetPredicate((Widget widget) => widget is Icon).evaluate().toList();

    await expectLater(tester, meetsGuideline(CustomContrastGuideline(elements: icons)));
  });
}

// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

final Key _painterKey = UniqueKey();

void main() {
  testWidgets('BAB theme overrides color', (WidgetTester tester) async {
    const Color labelColor = Colors.black;
    const TabBarTheme tabBarTheme = TabBarTheme(labelColor: labelColor);

    await tester.pumpWidget(_withTheme(tabBarTheme));

    final RenderParagraph textRenderObject = tester.renderObject<RenderParagraph>(find.text(_tab1Text));
    expect(textRenderObject.text.style.color, equals(labelColor));
    final RenderParagraph iconRenderObject = _iconRenderObject(tester, Icons.looks_one);
    expect(iconRenderObject.text.style.color, equals(labelColor));
  });

  testWidgets('Theme BottomAppBarColor supersedes BAB theme color', (WidgetTester tester) async {
    const Color labelColor = Colors.black;
    const TabBarTheme tabBarTheme = TabBarTheme(labelColor: labelColor);

    await tester.pumpWidget(_withTheme(tabBarTheme));

    final RenderParagraph textRenderObject = tester.renderObject<RenderParagraph>(find.text(_tab1Text));
    expect(textRenderObject.text.style.color, equals(labelColor));
    final RenderParagraph iconRenderObject = _iconRenderObject(tester, Icons.looks_one);
    expect(iconRenderObject.text.style.color, equals(labelColor));
  });

  testWidgets('BAB theme customizes shape and notch margin', (WidgetTester tester) async {
    const Color labelColor = Colors.black;
    const TabBarTheme tabBarTheme = TabBarTheme(labelColor: labelColor);

    await tester.pumpWidget(_withTheme(tabBarTheme));

    final RenderParagraph textRenderObject = tester.renderObject<RenderParagraph>(find.text(_tab1Text));
    expect(textRenderObject.text.style.color, equals(labelColor));
    final RenderParagraph iconRenderObject = _iconRenderObject(tester, Icons.looks_one);
    expect(iconRenderObject.text.style.color, equals(labelColor));
  });
}

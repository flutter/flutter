// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MaterialBannerThemeData copyWith, ==, hashCode basics', () {
    expect(const MaterialBannerThemeData(), const MaterialBannerThemeData().copyWith());
    expect(const MaterialBannerThemeData().hashCode, const MaterialBannerThemeData().copyWith().hashCode);
  });

  test('MaterialBannerThemeData null fields by default', () {
    const MaterialBannerThemeData bannerTheme = MaterialBannerThemeData();
    expect(bannerTheme.backgroundColor, null);
    expect(bannerTheme.contentTextStyle, null);
  });

  testWidgets('Default MaterialBannerThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const MaterialBannerThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[]);
  });

  testWidgets('MaterialBannerThemeData implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const MaterialBannerThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      contentTextStyle: TextStyle(color: Color(0xFFFFFFFF)),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      'backgroundColor: Color(0xffffffff)',
      'contentTextStyle: TextStyle(inherit: true, color: Color(0xffffffff))',
    ]);
  });

  testWidgets('Passing no MaterialBannerThemeData returns defaults', (WidgetTester tester) async {
    const String contentText = 'Content';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MaterialBanner(
          content: const Text(contentText),
          actions: <Widget>[
            FlatButton(
              child: const Text('Action'),
              onPressed: () { },
            ),
          ],
        ),
      ),
    ));

    final Container container = _getContainerFromBanner(tester);
    final RenderParagraph content = _getTextRenderObjectFromDialog(tester, contentText);
    expect(container.decoration, const BoxDecoration(color: const Color(0xfffafafa)));
    expect(content.text.style, Typography().englishLike.body1.merge(Typography().black.body1));
  });

  testWidgets('MaterialBanner uses values from MaterialBannerThemeData', (WidgetTester tester) async {
    final MaterialBannerThemeData bannerTheme = _bannerTheme();
    const String contentText = 'Content';
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(bannerTheme: bannerTheme),
      home: Scaffold(
        body: MaterialBanner(
          content: const Text(contentText),
          actions: <Widget>[
            FlatButton(
              child: const Text('Action'),
              onPressed: () { },
            ),
          ],
        ),
      ),
    ));

    final Container container = _getContainerFromBanner(tester);
    final RenderParagraph content = _getTextRenderObjectFromDialog(tester, contentText);
    expect(container.decoration, BoxDecoration(color: bannerTheme.backgroundColor));
    expect(content.text.style, bannerTheme.contentTextStyle);
  });

  testWidgets('MaterialBanner widget properties take priority over theme', (WidgetTester tester) async {
    const Color backgroundColor = Colors.purple;
    const TextStyle textStyle = TextStyle(color: Colors.green);
    final MaterialBannerThemeData bannerTheme = _bannerTheme();
    const String contentText = 'Content';
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(bannerTheme: bannerTheme),
      home: Scaffold(
        body: MaterialBanner(
          backgroundColor: backgroundColor,
          contentTextStyle: textStyle,
          content: const Text(contentText),
          actions: <Widget>[
            FlatButton(
              child: const Text('Action'),
              onPressed: () { },
            ),
          ],
        ),
      ),
    ));

    final Container container = _getContainerFromBanner(tester);
    final RenderParagraph content = _getTextRenderObjectFromDialog(tester, contentText);
    expect(container.decoration, const BoxDecoration(color: backgroundColor));
    expect(content.text.style, textStyle);
  });
}

MaterialBannerThemeData _bannerTheme() {
  return const MaterialBannerThemeData(
    backgroundColor: Colors.orange,
    contentTextStyle: TextStyle(color: Colors.pink),
  );
}

Container _getContainerFromBanner(WidgetTester tester) {
  return tester.widget<Container>(find.descendant(of: find.byType(MaterialBanner), matching: find.byType(Container)).first);
}

RenderParagraph _getTextRenderObjectFromDialog(WidgetTester tester, String text) {
  return tester.element<StatelessElement>(find.descendant(of: find.byType(MaterialBanner), matching: find.text(text))).renderObject;
}

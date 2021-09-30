// Copyright 2014 The Flutter Authors. All rights reserved.
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
            TextButton(
              child: const Text('Action'),
              onPressed: () { },
            ),
          ],
        ),
      ),
    ));

    final Material material = _getMaterialFromText(tester, contentText);
    final RenderParagraph content = _getTextRenderObjectFromDialog(tester, contentText);
    expect(material.color, const Color(0xffffffff));
    // Default value for ThemeData.typography is Typography.material2014()
    expect(content.text.style, Typography.material2014().englishLike.bodyText2!.merge(Typography.material2014().black.bodyText2));
  });

  testWidgets('Passing no MaterialBannerThemeData returns defaults when presented by ScaffoldMessenger', (WidgetTester tester) async {
    const String contentText = 'Content';
    const Key tapTarget = Key('tap-target');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              key: tapTarget,
              onTap: () {
                ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
                  content: const Text(contentText),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Action'),
                      onPressed: () { },
                    ),
                  ],
                ));
              },
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                height: 100.0,
                width: 100.0,
              ),
            );
          },
        ),
      ),
    ));
    await tester.tap(find.byKey(tapTarget));
    await tester.pumpAndSettle();

    final Material material = _getMaterialFromText(tester, contentText);
    final RenderParagraph content = _getTextRenderObjectFromDialog(tester, contentText);
    expect(material.color, const Color(0xffffffff));
    // Default value for ThemeData.typography is Typography.material2014()
    expect(content.text.style, Typography.material2014().englishLike.bodyText2!.merge(Typography.material2014().black.bodyText2));
  });

  testWidgets('MaterialBanner uses values from MaterialBannerThemeData', (WidgetTester tester) async {
    final MaterialBannerThemeData bannerTheme = _bannerTheme();
    const String contentText = 'Content';
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(bannerTheme: bannerTheme),
      home: Scaffold(
        body: MaterialBanner(
          leading: const Icon(Icons.ac_unit),
          content: const Text(contentText),
          actions: <Widget>[
            TextButton(
              child: const Text('Action'),
              onPressed: () { },
            ),
          ],
        ),
      ),
    ));

    final Material material = _getMaterialFromText(tester, contentText);
    final RenderParagraph content = _getTextRenderObjectFromDialog(tester, contentText);
    expect(material.color, bannerTheme.backgroundColor);
    expect(content.text.style, bannerTheme.contentTextStyle);

    final Offset contentTopLeft = tester.getTopLeft(_textFinder(contentText));
    final Offset materialTopLeft = tester.getTopLeft(_materialFinder());
    final Offset leadingTopLeft = tester.getTopLeft(find.byIcon(Icons.ac_unit));
    expect(contentTopLeft.dy - materialTopLeft.dy, 24);
    expect(contentTopLeft.dx - materialTopLeft.dx, 41);
    expect(leadingTopLeft.dy - materialTopLeft.dy, 19);
    expect(leadingTopLeft.dx - materialTopLeft.dx, 11);
  });

  testWidgets('MaterialBanner uses values from MaterialBannerThemeData when presented by ScaffoldMessenger', (WidgetTester tester) async {
    final MaterialBannerThemeData bannerTheme = _bannerTheme();
    const String contentText = 'Content';
    const Key tapTarget = Key('tap-target');
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(bannerTheme: bannerTheme),
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              key: tapTarget,
              onTap: () {
                ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
                  leading: const Icon(Icons.ac_unit),
                  content: const Text(contentText),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Action'),
                      onPressed: () { },
                    ),
                  ],
                ));
              },
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                height: 100.0,
                width: 100.0,
              ),
            );
          },
        ),
      ),
    ));
    await tester.tap(find.byKey(tapTarget));
    await tester.pumpAndSettle();

    final Material material = _getMaterialFromText(tester, contentText);
    final RenderParagraph content = _getTextRenderObjectFromDialog(tester, contentText);
    expect(material.color, bannerTheme.backgroundColor);
    expect(content.text.style, bannerTheme.contentTextStyle);

    final Offset contentTopLeft = tester.getTopLeft(_textFinder(contentText));
    final Offset materialTopLeft = tester.getTopLeft(_materialFinder());
    final Offset leadingTopLeft = tester.getTopLeft(find.byIcon(Icons.ac_unit));
    expect(contentTopLeft.dy - materialTopLeft.dy, 24);
    expect(contentTopLeft.dx - materialTopLeft.dx, 41);
    expect(leadingTopLeft.dy - materialTopLeft.dy, 19);
    expect(leadingTopLeft.dx - materialTopLeft.dx, 11);
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
          leading: const Icon(Icons.ac_unit),
          contentTextStyle: textStyle,
          content: const Text(contentText),
          padding: const EdgeInsets.all(10),
          leadingPadding: const EdgeInsets.all(12),
          actions: <Widget>[
            TextButton(
              child: const Text('Action'),
              onPressed: () { },
            ),
          ],
        ),
      ),
    ));

    final Material material = _getMaterialFromText(tester, contentText);
    final RenderParagraph content = _getTextRenderObjectFromDialog(tester, contentText);
    expect(material.color, backgroundColor);
    expect(content.text.style, textStyle);

    final Offset contentTopLeft = tester.getTopLeft(_textFinder(contentText));
    final Offset materialTopLeft = tester.getTopLeft(_materialFinder());
    final Offset leadingTopLeft = tester.getTopLeft(find.byIcon(Icons.ac_unit));
    expect(contentTopLeft.dy - materialTopLeft.dy, 29);
    expect(contentTopLeft.dx - materialTopLeft.dx, 58);
    expect(leadingTopLeft.dy - materialTopLeft.dy, 24);
    expect(leadingTopLeft.dx - materialTopLeft.dx, 22);
  });

  testWidgets('MaterialBanner widget properties take priority over theme when presented by ScaffoldMessenger', (WidgetTester tester) async {
    const Color backgroundColor = Colors.purple;
    const TextStyle textStyle = TextStyle(color: Colors.green);
    final MaterialBannerThemeData bannerTheme = _bannerTheme();
    const String contentText = 'Content';
    const Key tapTarget = Key('tap-target');
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(bannerTheme: bannerTheme),
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              key: tapTarget,
              onTap: () {
                ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
                  backgroundColor: backgroundColor,
                  leading: const Icon(Icons.ac_unit),
                  contentTextStyle: textStyle,
                  content: const Text(contentText),
                  padding: const EdgeInsets.all(10),
                  leadingPadding: const EdgeInsets.all(12),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Action'),
                      onPressed: () { },
                    ),
                  ],
                ));
              },
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                height: 100.0,
                width: 100.0,
              ),
            );
          },
        ),
      ),
    ));
    await tester.tap(find.byKey(tapTarget));
    await tester.pumpAndSettle();

    final Material material = _getMaterialFromText(tester, contentText);
    final RenderParagraph content = _getTextRenderObjectFromDialog(tester, contentText);
    expect(material.color, backgroundColor);
    expect(content.text.style, textStyle);

    final Offset contentTopLeft = tester.getTopLeft(_textFinder(contentText));
    final Offset materialTopLeft = tester.getTopLeft(_materialFinder());
    final Offset leadingTopLeft = tester.getTopLeft(find.byIcon(Icons.ac_unit));
    expect(contentTopLeft.dy - materialTopLeft.dy, 29);
    expect(contentTopLeft.dx - materialTopLeft.dx, 58);
    expect(leadingTopLeft.dy - materialTopLeft.dy, 24);
    expect(leadingTopLeft.dx - materialTopLeft.dx, 22);
  });

  testWidgets('MaterialBanner uses color scheme when necessary', (WidgetTester tester) async {
    final ColorScheme colorScheme = const ColorScheme.light().copyWith(surface: Colors.purple);
    const String contentText = 'Content';
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(colorScheme: colorScheme),
      home: Scaffold(
        body: MaterialBanner(
          content: const Text(contentText),
          actions: <Widget>[
            TextButton(
              child: const Text('Action'),
              onPressed: () { },
            ),
          ],
        ),
      ),
    ));

    final Material material = _getMaterialFromText(tester, contentText);
    expect(material.color, colorScheme.surface);
  });

  testWidgets('MaterialBanner uses color scheme when necessary when presented by ScaffoldMessenger', (WidgetTester tester) async {
    final ColorScheme colorScheme = const ColorScheme.light().copyWith(surface: Colors.purple);
    const String contentText = 'Content';
    const Key tapTarget = Key('tap-target');
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(colorScheme: colorScheme),
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              key: tapTarget,
              onTap: () {
                ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
                  content: const Text(contentText),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Action'),
                      onPressed: () { },
                    ),
                  ],
                ));
              },
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                height: 100.0,
                width: 100.0,
              ),
            );
          },
        ),
      ),
    ));
    await tester.tap(find.byKey(tapTarget));
    await tester.pumpAndSettle();

    final Material material = _getMaterialFromText(tester, contentText);
    expect(material.color, colorScheme.surface);
  });
}

MaterialBannerThemeData _bannerTheme() {
  return const MaterialBannerThemeData(
    backgroundColor: Colors.orange,
    contentTextStyle: TextStyle(color: Colors.pink),
    padding: EdgeInsets.all(5),
    leadingPadding: EdgeInsets.all(6),
  );
}

Material _getMaterialFromText(WidgetTester tester, String text) {
  return tester.widget<Material>(find.widgetWithText(Material, text).first);
}

Finder _materialFinder() {
  return find.descendant(of: find.byType(MaterialBanner), matching: find.byType(Material)).first;
}

RenderParagraph _getTextRenderObjectFromDialog(WidgetTester tester, String text) {
  return tester.element<StatelessElement>(_textFinder(text)).renderObject! as RenderParagraph;
}

Finder _textFinder(String text) {
  return find.descendant(of: find.byType(MaterialBanner), matching: find.text(text));
}

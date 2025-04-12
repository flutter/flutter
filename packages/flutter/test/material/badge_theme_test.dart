// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BadgeThemeData copyWith, ==, hashCode basics', () {
    expect(const BadgeThemeData(), const BadgeThemeData().copyWith());
    expect(const BadgeThemeData().hashCode, const BadgeThemeData().copyWith().hashCode);
  });

  test('BadgeThemeData lerp special cases', () {
    expect(BadgeThemeData.lerp(null, null, 0), const BadgeThemeData());
    const BadgeThemeData data = BadgeThemeData();
    expect(identical(BadgeThemeData.lerp(data, data, 0.5), data), true);
  });

  test('BadgeThemeData defaults', () {
    const BadgeThemeData themeData = BadgeThemeData();
    expect(themeData.backgroundColor, null);
    expect(themeData.textColor, null);
    expect(themeData.smallSize, null);
    expect(themeData.largeSize, null);
    expect(themeData.textStyle, null);
    expect(themeData.padding, null);
    expect(themeData.alignment, null);
    expect(themeData.offset, null);
  });

  testWidgets('Default BadgeThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const BadgeThemeData().debugFillProperties(builder);

    final List<String> description =
        builder.properties
            .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
            .map((DiagnosticsNode node) => node.toString())
            .toList();

    expect(description, <String>[]);
  });

  testWidgets('BadgeThemeData implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const BadgeThemeData(
      backgroundColor: Color(0xfffffff0),
      textColor: Color(0xfffffff1),
      smallSize: 1,
      largeSize: 2,
      textStyle: TextStyle(fontSize: 4),
      padding: EdgeInsets.all(5),
      alignment: AlignmentDirectional(6, 7),
      offset: Offset.zero,
    ).debugFillProperties(builder);

    final List<String> description =
        builder.properties
            .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
            .map((DiagnosticsNode node) => node.toString())
            .toList();

    expect(description, <String>[
      'backgroundColor: ${const Color(0xfffffff0)}',
      'textColor: ${const Color(0xfffffff1)}',
      'smallSize: 1.0',
      'largeSize: 2.0',
      'textStyle: TextStyle(inherit: true, size: 4.0)',
      'padding: EdgeInsets.all(5.0)',
      'alignment: AlignmentDirectional(6.0, 7.0)',
      'offset: Offset(0.0, 0.0)',
    ]);
  });

  testWidgets('Badge uses ThemeData badge theme', (WidgetTester tester) async {
    const Color green = Color(0xff00ff00);
    const Color black = Color(0xff000000);
    const BadgeThemeData badgeTheme = BadgeThemeData(
      backgroundColor: green,
      textColor: black,
      smallSize: 5,
      largeSize: 20,
      textStyle: TextStyle(fontSize: 12),
      padding: EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.topRight,
      offset: Offset(24, 0),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(badgeTheme: badgeTheme),
        home: const Scaffold(body: Badge(label: Text('1234'), child: Icon(Icons.add))),
      ),
    );

    // text width = 48 = fontSize * 4, text height = fontSize
    expect(tester.getSize(find.text('1234')), const Size(48, 12));

    expect(tester.getTopLeft(find.text('1234')), const Offset(33, 2));

    expect(tester.getSize(find.byType(Badge)), const Size(24, 24)); // default Icon size
    expect(tester.getTopLeft(find.byType(Badge)), Offset.zero);

    final TextStyle textStyle = tester.renderObject<RenderParagraph>(find.text('1234')).text.style!;
    expect(textStyle.fontSize, 12);
    expect(textStyle.color, black);

    final RenderBox box = tester.renderObject(find.byType(Badge));
    expect(
      box,
      paints
        ..rrect(rrect: RRect.fromLTRBR(28, -2, 86, 18, const Radius.circular(10)), color: green),
    );
  });

  // This test is essentially the same as 'Badge uses ThemeData badge theme'. In
  // this case the theme is introduced with the BadgeTheme widget instead of
  // ThemeData.badgeTheme.
  testWidgets('Badge uses BadgeTheme', (WidgetTester tester) async {
    const Color green = Color(0xff00ff00);
    const Color black = Color(0xff000000);
    const BadgeThemeData badgeTheme = BadgeThemeData(
      backgroundColor: green,
      textColor: black,
      smallSize: 5,
      largeSize: 20,
      textStyle: TextStyle(fontSize: 12),
      padding: EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.topRight,
      offset: Offset(24, 0),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: BadgeTheme(
          data: badgeTheme,
          child: Scaffold(body: Badge(label: Text('1234'), child: Icon(Icons.add))),
        ),
      ),
    );

    expect(tester.getSize(find.text('1234')), const Size(48, 12));
    expect(tester.getTopLeft(find.text('1234')), const Offset(33, 2));
    expect(tester.getSize(find.byType(Badge)), const Size(24, 24)); // default Icon size
    expect(tester.getTopLeft(find.byType(Badge)), Offset.zero);
    final TextStyle textStyle = tester.renderObject<RenderParagraph>(find.text('1234')).text.style!;
    expect(textStyle.fontSize, 12);
    expect(textStyle.color, black);
    final RenderBox box = tester.renderObject(find.byType(Badge));
    expect(
      box,
      paints
        ..rrect(rrect: RRect.fromLTRBR(28, -2, 86, 18, const Radius.circular(10)), color: green),
    );
  });

  testWidgets('BadgeTheme.select only rebuilds when the selected property changes', (
    WidgetTester tester,
  ) async {
    int buildCount = 0;
    late Color? backgroundColor;

    // Define two distinct colors to test changes.
    const Color color1 = Colors.red;
    const Color color2 = Colors.blue;

    final Widget singletonThemeSubtree = Builder(
      builder: (BuildContext context) {
        buildCount++;
        // Select the backgroundColor property.
        backgroundColor = BadgeTheme.select(
          context,
          (BadgeThemeData theme) => theme.backgroundColor,
        );
        return const Placeholder();
      },
    );

    // Initial build with color1.
    await tester.pumpWidget(
      MaterialApp(
        home: BadgeTheme(
          data: const BadgeThemeData(backgroundColor: color1),
          child: singletonThemeSubtree,
        ),
      ),
    );

    expect(buildCount, 1);
    expect(backgroundColor, color1);

    // Rebuild with a change to a non-selected property (textColor).
    await tester.pumpWidget(
      MaterialApp(
        home: BadgeTheme(
          data: const BadgeThemeData(
            backgroundColor: color1, // Selected property unchanged
            textColor: color2, // Non-selected property changed
          ),
          child: singletonThemeSubtree,
        ),
      ),
    );

    // Expect no rebuild because the selected property didn't change.
    expect(buildCount, 1);
    expect(backgroundColor, color1);

    // Rebuild with a change to the selected property (backgroundColor).
    await tester.pumpWidget(
      MaterialApp(
        home: BadgeTheme(
          data: const BadgeThemeData(
            backgroundColor: color2, // Selected property changed
            textColor: color2,
          ),
          child: singletonThemeSubtree,
        ),
      ),
    );

    // Expect rebuild because the selected property changed.
    expect(buildCount, 2);
    expect(backgroundColor, color2);
  });
}

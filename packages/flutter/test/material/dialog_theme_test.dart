// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

MaterialApp _appWithDialog(WidgetTester tester, Widget dialog, { ThemeData? theme }) {
  return MaterialApp(
    theme: theme,
    home: Material(
      child: Builder(
        builder: (BuildContext context) {
          return Center(
            child: ElevatedButton(
              child: const Text('X'),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return RepaintBoundary(key: _painterKey, child: dialog);
                  },
                );
              },
            ),
          );
        },
      ),
    ),
  );
}

final Key _painterKey = UniqueKey();

Material _getMaterialFromDialog(WidgetTester tester) {
  return tester.widget<Material>(find.descendant(of: find.byType(AlertDialog), matching: find.byType(Material)));
}

RenderParagraph _getTextRenderObject(WidgetTester tester, String text) {
  return tester.element<StatelessElement>(find.text(text)).renderObject! as RenderParagraph;
}

void main() {
  testWidgets('Dialog Theme implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const DialogTheme(
      backgroundColor: Color(0xff123456),
      elevation: 8.0,
      alignment: Alignment.bottomLeft,
      titleTextStyle: TextStyle(color: Color(0xffffffff)),
      contentTextStyle: TextStyle(color: Color(0xff000000)),
    ).debugFillProperties(builder);
    final List<String> description = builder.properties
        .where((DiagnosticsNode n) => !n.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode n) => n.toString()).toList();
    expect(description, <String>[
      'backgroundColor: Color(0xff123456)',
      'elevation: 8.0',
      'alignment: Alignment.bottomLeft',
      'titleTextStyle: TextStyle(inherit: true, color: Color(0xffffffff))',
      'contentTextStyle: TextStyle(inherit: true, color: Color(0xff000000))',
    ]);
  });

  testWidgets('Dialog background color', (WidgetTester tester) async {
    const Color customColor = Colors.pink;
    const AlertDialog dialog = AlertDialog(
      title: Text('Title'),
      actions: <Widget>[ ],
    );
    final ThemeData theme = ThemeData(dialogTheme: const DialogTheme(backgroundColor: customColor));

    await tester.pumpWidget(_appWithDialog(tester, dialog, theme: theme));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Material materialWidget = _getMaterialFromDialog(tester);
    expect(materialWidget.color, customColor);
  });

  testWidgets('Custom dialog elevation', (WidgetTester tester) async {
    const double customElevation = 12.0;
    const AlertDialog dialog = AlertDialog(
      title: Text('Title'),
      actions: <Widget>[ ],
    );
    final ThemeData theme = ThemeData(dialogTheme: const DialogTheme(elevation: customElevation));

    await tester.pumpWidget(
      _appWithDialog(tester, dialog, theme: theme),
    );
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Material materialWidget = _getMaterialFromDialog(tester);
    expect(materialWidget.elevation, customElevation);
  });

  testWidgets('Custom dialog shape', (WidgetTester tester) async {
    const RoundedRectangleBorder customBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0)));
    const AlertDialog dialog = AlertDialog(
      title: Text('Title'),
      actions: <Widget>[ ],
    );
    final ThemeData theme = ThemeData(dialogTheme: const DialogTheme(shape: customBorder));

    await tester.pumpWidget(
      _appWithDialog(tester, dialog, theme: theme),
    );
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Material materialWidget = _getMaterialFromDialog(tester);
    expect(materialWidget.shape, customBorder);
  });

  testWidgets('Custom dialog alignment', (WidgetTester tester) async {
    const AlertDialog dialog = AlertDialog(
      title: Text('Title'),
      actions: <Widget>[ ],
    );
    final ThemeData theme = ThemeData(dialogTheme: const DialogTheme(alignment: Alignment.bottomLeft));

    await tester.pumpWidget(
      _appWithDialog(tester, dialog, theme: theme),
    );
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Offset bottomLeft = tester.getBottomLeft(
      find.descendant(of: find.byType(Dialog), matching: find.byType(Material)),
    );
    expect(bottomLeft.dx, 40.0);
    expect(bottomLeft.dy, 576.0);
  });

  testWidgets('Dialog alignment takes priority over theme', (WidgetTester tester) async {
    const AlertDialog dialog = AlertDialog(
      title: Text('Title'),
      actions: <Widget>[ ],
      alignment: Alignment.topRight,
    );
    final ThemeData theme = ThemeData(dialogTheme: const DialogTheme(alignment: Alignment.bottomLeft));

    await tester.pumpWidget(
      _appWithDialog(tester, dialog, theme: theme),
    );
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Offset bottomLeft = tester.getBottomLeft(
      find.descendant(of: find.byType(Dialog), matching: find.byType(Material)),
    );
    expect(bottomLeft.dx, 480.0);
    expect(bottomLeft.dy, 104.0);
  });

  testWidgets('Custom dialog shape matches golden', (WidgetTester tester) async {
    const RoundedRectangleBorder customBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0)));
    const AlertDialog dialog = AlertDialog(
      title: Text('Title'),
      actions: <Widget>[ ],
    );
    final ThemeData theme = ThemeData(dialogTheme: const DialogTheme(shape: customBorder));

    await tester.pumpWidget(_appWithDialog(tester, dialog, theme: theme));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(_painterKey),
      matchesGoldenFile('dialog_theme.dialog_with_custom_border.png'),
    );
  });

  testWidgets('Custom Title Text Style - Constructor Param', (WidgetTester tester) async {
    const String titleText = 'Title';
    const TextStyle titleTextStyle = TextStyle(color: Colors.pink);
    const AlertDialog dialog = AlertDialog(
      title: Text(titleText),
      titleTextStyle: titleTextStyle,
      actions: <Widget>[ ],
    );

    await tester.pumpWidget(_appWithDialog(tester, dialog));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final RenderParagraph title = _getTextRenderObject(tester, titleText);
    expect(title.text.style, titleTextStyle);
  });

  testWidgets('Custom Title Text Style - Dialog Theme', (WidgetTester tester) async {
    const String titleText = 'Title';
    const TextStyle titleTextStyle = TextStyle(color: Colors.pink);
    const AlertDialog dialog = AlertDialog(
      title: Text(titleText),
      actions: <Widget>[ ],
    );
    final ThemeData theme = ThemeData(dialogTheme: const DialogTheme(titleTextStyle: titleTextStyle));

    await tester.pumpWidget(_appWithDialog(tester, dialog, theme: theme));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final RenderParagraph title = _getTextRenderObject(tester, titleText);
    expect(title.text.style, titleTextStyle);
  });

  testWidgets('Custom Title Text Style - Theme', (WidgetTester tester) async {
    const String titleText = 'Title';
    const TextStyle titleTextStyle = TextStyle(color: Colors.pink);
    const AlertDialog dialog = AlertDialog(
      title: Text(titleText),
      actions: <Widget>[ ],
    );
    final ThemeData theme = ThemeData(textTheme: const TextTheme(headline6: titleTextStyle));

    await tester.pumpWidget(_appWithDialog(tester, dialog, theme: theme));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final RenderParagraph title = _getTextRenderObject(tester, titleText);
    expect(title.text.style!.color, titleTextStyle.color);
  });

  testWidgets('Simple Dialog - Custom Title Text Style - Constructor Param', (WidgetTester tester) async {
    const String titleText = 'Title';
    const TextStyle titleTextStyle = TextStyle(color: Colors.pink);
    const SimpleDialog dialog = SimpleDialog(
      title: Text(titleText),
      titleTextStyle: titleTextStyle,
    );

    await tester.pumpWidget(_appWithDialog(tester, dialog));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final RenderParagraph title = _getTextRenderObject(tester, titleText);
    expect(title.text.style, titleTextStyle);
  });

  testWidgets('Simple Dialog - Custom Title Text Style - Dialog Theme', (WidgetTester tester) async {
    const String titleText = 'Title';
    const TextStyle titleTextStyle = TextStyle(color: Colors.pink);
    const SimpleDialog dialog = SimpleDialog(
      title: Text(titleText),
    );
    final ThemeData theme = ThemeData(dialogTheme: const DialogTheme(titleTextStyle: titleTextStyle));

    await tester.pumpWidget(_appWithDialog(tester, dialog, theme: theme));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final RenderParagraph title = _getTextRenderObject(tester, titleText);
    expect(title.text.style, titleTextStyle);
  });

  testWidgets('Simple Dialog - Custom Title Text Style - Theme', (WidgetTester tester) async {
    const String titleText = 'Title';
    const TextStyle titleTextStyle = TextStyle(color: Colors.pink);
    const SimpleDialog dialog = SimpleDialog(
      title: Text(titleText),
    );
    final ThemeData theme = ThemeData(textTheme: const TextTheme(headline6: titleTextStyle));

    await tester.pumpWidget(_appWithDialog(tester, dialog, theme: theme));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final RenderParagraph title = _getTextRenderObject(tester, titleText);
    expect(title.text.style!.color, titleTextStyle.color);
  });

  testWidgets('Custom Content Text Style - Constructor Param', (WidgetTester tester) async {
    const String contentText = 'Content';
    const TextStyle contentTextStyle = TextStyle(color: Colors.pink);
    const AlertDialog dialog = AlertDialog(
      content: Text(contentText),
      contentTextStyle: contentTextStyle,
      actions: <Widget>[ ],
    );

    await tester.pumpWidget(_appWithDialog(tester, dialog));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final RenderParagraph content = _getTextRenderObject(tester, contentText);
    expect(content.text.style, contentTextStyle);
  });

  testWidgets('Custom Content Text Style - Dialog Theme', (WidgetTester tester) async {
    const String contentText = 'Content';
    const TextStyle contentTextStyle = TextStyle(color: Colors.pink);
    const AlertDialog dialog = AlertDialog(
      content: Text(contentText),
      actions: <Widget>[ ],
    );
    final ThemeData theme = ThemeData(dialogTheme: const DialogTheme(contentTextStyle: contentTextStyle));

    await tester.pumpWidget(_appWithDialog(tester, dialog, theme: theme));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final RenderParagraph content = _getTextRenderObject(tester, contentText);
    expect(content.text.style, contentTextStyle);
  });

  testWidgets('Custom Content Text Style - Theme', (WidgetTester tester) async {
    const String contentText = 'Content';
    const TextStyle contentTextStyle = TextStyle(color: Colors.pink);
    const AlertDialog dialog = AlertDialog(
      content: Text(contentText),
      actions: <Widget>[ ],
    );
    final ThemeData theme = ThemeData(textTheme: const TextTheme(subtitle1: contentTextStyle));

    await tester.pumpWidget(_appWithDialog(tester, dialog, theme: theme));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final RenderParagraph content = _getTextRenderObject(tester, contentText);
    expect(content.text.style!.color, contentTextStyle.color);
  });
}

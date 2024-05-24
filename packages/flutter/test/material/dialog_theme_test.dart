// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/foundation.dart';
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
  test('DialogTheme copyWith, ==, hashCode basics', () {
    expect(const DialogTheme(), const DialogTheme().copyWith());
    expect(const DialogTheme().hashCode, const DialogTheme().copyWith().hashCode);
  });

  test('DialogTheme lerp special cases', () {
    expect(DialogTheme.lerp(null, null, 0), const DialogTheme());
    const DialogTheme theme = DialogTheme();
    expect(identical(DialogTheme.lerp(theme, theme, 0.5), theme), true);
  });

  testWidgets('Dialog Theme implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const DialogTheme(
      backgroundColor: Color(0xff123456),
      elevation: 8.0,
      shadowColor: Color(0xff000001),
      surfaceTintColor: Color(0xff000002),
      alignment: Alignment.bottomLeft,
      iconColor: Color(0xff654321),
      titleTextStyle: TextStyle(color: Color(0xffffffff)),
      contentTextStyle: TextStyle(color: Color(0xff000000)),
      actionsPadding: EdgeInsets.all(8.0),
      barrierColor: Color(0xff000005),
      insetPadding: EdgeInsets.all(20.0),
    ).debugFillProperties(builder);
    final List<String> description = builder.properties
        .where((DiagnosticsNode n) => !n.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode n) => n.toString()).toList();
    expect(description, <String>[
      'backgroundColor: Color(0xff123456)',
      'elevation: 8.0',
      'shadowColor: Color(0xff000001)',
      'surfaceTintColor: Color(0xff000002)',
      'alignment: Alignment.bottomLeft',
      'iconColor: Color(0xff654321)',
      'titleTextStyle: TextStyle(inherit: true, color: Color(0xffffffff))',
      'contentTextStyle: TextStyle(inherit: true, color: Color(0xff000000))',
      'actionsPadding: EdgeInsets.all(8.0)',
      'barrierColor: Color(0xff000005)',
      'insetPadding: EdgeInsets.all(20.0)',
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
    const Color shadowColor = Color(0xFF000001);
    const Color surfaceTintColor = Color(0xFF000002);
    const AlertDialog dialog = AlertDialog(
      title: Text('Title'),
      actions: <Widget>[ ],
    );
    final ThemeData theme = ThemeData(
      dialogTheme: const DialogTheme(
        elevation: customElevation,
        shadowColor: shadowColor,
        surfaceTintColor: surfaceTintColor,
      ),
    );

    await tester.pumpWidget(
      _appWithDialog(tester, dialog, theme: theme),
    );
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Material materialWidget = _getMaterialFromDialog(tester);
    expect(materialWidget.elevation, customElevation);
    expect(materialWidget.shadowColor, shadowColor);
    expect(materialWidget.surfaceTintColor, surfaceTintColor);
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

  testWidgets('Material3 - Dialog alignment takes priority over theme', (WidgetTester tester) async {
    const AlertDialog dialog = AlertDialog(
      title: Text('Title'),
      actions: <Widget>[ ],
      alignment: Alignment.topRight,
    );
    final ThemeData theme = ThemeData(
      useMaterial3: true,
      dialogTheme: const DialogTheme(alignment: Alignment.bottomLeft),
    );

    await tester.pumpWidget(
      _appWithDialog(tester, dialog, theme: theme),
    );
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Offset bottomLeft = tester.getBottomLeft(
      find.descendant(of: find.byType(Dialog), matching: find.byType(Material)),
    );
    expect(bottomLeft.dx, 480.0);
    if (!kIsWeb || isCanvasKit) { // https://github.com/flutter/flutter/issues/99933
      expect(bottomLeft.dy, 124.0);
    }
  });

  testWidgets('Material2 - Dialog alignment takes priority over theme', (WidgetTester tester) async {
    const AlertDialog dialog = AlertDialog(
      title: Text('Title'),
      actions: <Widget>[ ],
      alignment: Alignment.topRight,
    );
    final ThemeData theme = ThemeData(useMaterial3: false, dialogTheme: const DialogTheme(alignment: Alignment.bottomLeft));

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

  testWidgets('Material3 - Custom dialog shape matches golden', (WidgetTester tester) async {
    const RoundedRectangleBorder customBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0)));
    const AlertDialog dialog = AlertDialog(
      title: Text('Title'),
      actions: <Widget>[ ],
    );
    final ThemeData theme = ThemeData(
      useMaterial3: true,
      dialogTheme: const DialogTheme(shape: customBorder),
    );

    await tester.pumpWidget(_appWithDialog(tester, dialog, theme: theme));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(_painterKey),
      matchesGoldenFile('m3_dialog_theme.dialog_with_custom_border.png'),
    );
  });

  testWidgets('Material2 - Custom dialog shape matches golden', (WidgetTester tester) async {
    const RoundedRectangleBorder customBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0)));
    const AlertDialog dialog = AlertDialog(
      title: Text('Title'),
      actions: <Widget>[ ],
    );
    final ThemeData theme = ThemeData(useMaterial3: false, dialogTheme: const DialogTheme(shape: customBorder));

    await tester.pumpWidget(_appWithDialog(tester, dialog, theme: theme));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(_painterKey),
      matchesGoldenFile('m2_dialog_theme.dialog_with_custom_border.png'),
    );
  });

  testWidgets('Custom Icon Color - Constructor Param - highest preference', (WidgetTester tester) async {
    const Color iconColor = Colors.pink, dialogThemeColor = Colors.green, iconThemeColor = Colors.yellow;
    final ThemeData theme = ThemeData(
      iconTheme: const IconThemeData(color: iconThemeColor),
      dialogTheme: const DialogTheme(iconColor: dialogThemeColor),
    );
    const AlertDialog dialog = AlertDialog(
      icon: Icon(Icons.ac_unit),
      iconColor: iconColor,
      actions: <Widget>[ ],
    );

    await tester.pumpWidget(_appWithDialog(tester, dialog, theme: theme));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    // first is Text('X')
    final RichText text = tester.widget(find.byType(RichText).last);
    expect(text.text.style!.color, iconColor);
  });

  testWidgets('Custom Icon Color - Dialog Theme - preference over Theme', (WidgetTester tester) async {
    const Color dialogThemeColor = Colors.green, iconThemeColor = Colors.yellow;
    final ThemeData theme = ThemeData(
      iconTheme: const IconThemeData(color: iconThemeColor),
      dialogTheme: const DialogTheme(iconColor: dialogThemeColor),
    );
    const AlertDialog dialog = AlertDialog(
      icon: Icon(Icons.ac_unit),
      actions: <Widget>[ ],
    );

    await tester.pumpWidget(_appWithDialog(tester, dialog, theme: theme));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    // first is Text('X')
    final RichText text = tester.widget(find.byType(RichText).last);
    expect(text.text.style!.color, dialogThemeColor);
  });

  testWidgets('Material3 - Custom Icon Color - Theme - lowest preference', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(useMaterial3: true);
    const AlertDialog dialog = AlertDialog(
      icon: Icon(Icons.ac_unit),
      actions: <Widget>[ ],
    );

    await tester.pumpWidget(_appWithDialog(tester, dialog, theme: theme));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    // first is Text('X')
    final RichText text = tester.widget(find.byType(RichText).last);
    expect(text.text.style!.color, theme.colorScheme.secondary);
  });

  testWidgets('Material2 - Custom Icon Color - Theme - lowest preference', (WidgetTester tester) async {
    const Color iconThemeColor = Colors.yellow;
    final ThemeData theme = ThemeData(useMaterial3: false, iconTheme: const IconThemeData(color: iconThemeColor));
    const AlertDialog dialog = AlertDialog(
      icon: Icon(Icons.ac_unit),
      actions: <Widget>[ ],
    );

    await tester.pumpWidget(_appWithDialog(tester, dialog, theme: theme));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    // first is Text('X')
    final RichText text = tester.widget(find.byType(RichText).last);
    expect(text.text.style!.color, iconThemeColor);
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

  testWidgets('Material3 - Custom Title Text Style - Theme', (WidgetTester tester) async {
    const String titleText = 'Title';
    const TextStyle titleTextStyle = TextStyle(color: Colors.pink);
    const AlertDialog dialog = AlertDialog(title: Text(titleText));
    final ThemeData theme = ThemeData(useMaterial3: true, textTheme: const TextTheme(headlineSmall: titleTextStyle));

    await tester.pumpWidget(_appWithDialog(tester, dialog, theme: theme));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final RenderParagraph title = _getTextRenderObject(tester, titleText);
    expect(title.text.style!.color, titleTextStyle.color);
  });

  testWidgets('Material2 - Custom Title Text Style - Theme', (WidgetTester tester) async {
    const String titleText = 'Title';
    const TextStyle titleTextStyle = TextStyle(color: Colors.pink);
    const AlertDialog dialog = AlertDialog(title: Text(titleText));
    final ThemeData theme = ThemeData(useMaterial3: false, textTheme: const TextTheme(titleLarge: titleTextStyle));

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
    final ThemeData theme = ThemeData(textTheme: const TextTheme(titleLarge: titleTextStyle));

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

  testWidgets('Material3 - Custom Content Text Style - Theme', (WidgetTester tester) async {
    const String contentText = 'Content';
    const TextStyle contentTextStyle = TextStyle(color: Colors.pink);
    const AlertDialog dialog = AlertDialog(content: Text(contentText),);
    final ThemeData theme = ThemeData(useMaterial3: true, textTheme: const TextTheme(bodyMedium: contentTextStyle));

    await tester.pumpWidget(_appWithDialog(tester, dialog, theme: theme));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final RenderParagraph content = _getTextRenderObject(tester, contentText);
    expect(content.text.style!.color, contentTextStyle.color);
  });

  testWidgets('Material2 - Custom Content Text Style - Theme', (WidgetTester tester) async {
    const String contentText = 'Content';
    const TextStyle contentTextStyle = TextStyle(color: Colors.pink);
    const AlertDialog dialog = AlertDialog(content: Text(contentText));
    final ThemeData theme = ThemeData(useMaterial3: false, textTheme: const TextTheme(titleMedium: contentTextStyle));

    await tester.pumpWidget(_appWithDialog(tester, dialog, theme: theme));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final RenderParagraph content = _getTextRenderObject(tester, contentText);
    expect(content.text.style!.color, contentTextStyle.color);
  });

  testWidgets('Custom barrierColor - Theme', (WidgetTester tester) async {
    const Color barrierColor = Colors.blue;
    const SimpleDialog dialog = SimpleDialog();
    final ThemeData theme = ThemeData(dialogTheme: const DialogTheme(barrierColor: barrierColor));

    await tester.pumpWidget(_appWithDialog(tester, dialog, theme: theme));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final ModalBarrier modalBarrier = tester.widget(find.byType(ModalBarrier).last);
    expect(modalBarrier.color, barrierColor);
  });

  testWidgets('DialogTheme.insetPadding updates Dialog insetPadding', (WidgetTester tester) async {
    // The default testing screen (800, 600)
    const Rect screenRect = Rect.fromLTRB(0.0, 0.0, 800.0, 600.0);
    const DialogTheme dialogTheme = DialogTheme(
      insetPadding: EdgeInsets.fromLTRB(10, 15, 20, 25)
    );
    const Dialog dialog = Dialog(child: Placeholder());

    await tester.pumpWidget(_appWithDialog(
      tester,
      dialog,
      theme: ThemeData(dialogTheme: dialogTheme),
    ));
    await tester.tap(find.text('X'));
    await tester.pump();

    expect(
      tester.getRect(find.byType(Placeholder)),
      Rect.fromLTRB(
        screenRect.left + dialogTheme.insetPadding!.left,
        screenRect.top + dialogTheme.insetPadding!.top,
        screenRect.right - dialogTheme.insetPadding!.right,
        screenRect.bottom - dialogTheme.insetPadding!.bottom,
      ),
    );
  });
}

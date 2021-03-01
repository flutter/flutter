// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../rendering/mock_canvas.dart';

Widget wrap({ required Widget child }) {
  return MediaQuery(
    data: const MediaQueryData(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Material(child: child),
    ),
  );
}

void main() {
  testWidgets('CheckboxListTile control test', (WidgetTester tester) async {
    final List<dynamic> log = <dynamic>[];
    await tester.pumpWidget(wrap(
      child: CheckboxListTile(
        value: true,
        onChanged: (bool? value) { log.add(value); },
        title: const Text('Hello'),
      ),
    ));
    await tester.tap(find.text('Hello'));
    log.add('-');
    await tester.tap(find.byType(Checkbox));
    expect(log, equals(<dynamic>[false, '-', false]));
  });

  testWidgets('CheckboxListTile checkColor test', (WidgetTester tester) async {
    const Color checkBoxBorderColor = Color(0xff1e88e5);
    Color checkBoxCheckColor = const Color(0xffFFFFFF);

    Widget buildFrame(Color? color) {
      return wrap(
        child: CheckboxListTile(
          value: true,
          checkColor: color,
          onChanged: (bool? value) {},
        ),
      );
    }

    RenderBox getCheckboxListTileRenderer() {
      return tester.renderObject<RenderBox>(find.byType(CheckboxListTile));
    }

    await tester.pumpWidget(buildFrame(null));
    await tester.pumpAndSettle();
    expect(getCheckboxListTileRenderer(), paints..path(color: checkBoxBorderColor)..path(color: checkBoxCheckColor));

    checkBoxCheckColor = const Color(0xFF000000);

    await tester.pumpWidget(buildFrame(checkBoxCheckColor));
    await tester.pumpAndSettle();
    expect(getCheckboxListTileRenderer(), paints..path(color: checkBoxBorderColor)..path(color: checkBoxCheckColor));
  });

  testWidgets('CheckboxListTile activeColor test', (WidgetTester tester) async {
    Widget buildFrame(Color? themeColor, Color? activeColor) {
      return wrap(
        child: Theme(
          data: ThemeData(toggleableActiveColor: themeColor),
          child: CheckboxListTile(
            value: true,
            activeColor: activeColor,
            onChanged: (bool? value) {},
          ),
        ),
      );
    }
    RenderBox getCheckboxListTileRenderer() {
      return tester.renderObject<RenderBox>(find.byType(CheckboxListTile));
    }

    await tester.pumpWidget(buildFrame(const Color(0xFF000000), null));
    await tester.pumpAndSettle();
    expect(getCheckboxListTileRenderer(), paints..path(color: const Color(0xFF000000)));

    await tester.pumpWidget(buildFrame(const Color(0xFF000000), const Color(0xFFFFFFFF)));
    await tester.pumpAndSettle();
    expect(getCheckboxListTileRenderer(), paints..path(color: const Color(0xFFFFFFFF)));
  });

  testWidgets('CheckboxListTile can autofocus unless disabled.', (WidgetTester tester) async {
    final GlobalKey childKey = GlobalKey();

    await tester.pumpWidget(
      wrap(
        child: CheckboxListTile(
          value: true,
          onChanged: (_) {},
          title: Text('Hello', key: childKey),
          autofocus: true,
        ),
      ),
    );

    await tester.pump();
    expect(Focus.maybeOf(childKey.currentContext!)!.hasPrimaryFocus, isTrue);

    await tester.pumpWidget(
      wrap(
        child: CheckboxListTile(
          value: true,
          onChanged: null,
          title: Text('Hello', key: childKey),
          autofocus: true,
        ),
      ),
    );

    await tester.pump();
    expect(Focus.maybeOf(childKey.currentContext!)!.hasPrimaryFocus, isFalse);
  });

  testWidgets('CheckboxListTile contentPadding test', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: const Center(
          child: CheckboxListTile(
            value: false,
            onChanged: null,
            title: Text('Title'),
            contentPadding: EdgeInsets.fromLTRB(10, 18, 4, 2),
          ),
        ),
      )
    );

    final Rect paddingRect = tester.getRect(find.byType(SafeArea));
    final Rect checkboxRect = tester.getRect(find.byType(Checkbox));
    final Rect titleRect = tester.getRect(find.text('Title'));

    final Rect tallerWidget = checkboxRect.height > titleRect.height ? checkboxRect : titleRect;

    // Check the offsets of CheckBox and title after padding is applied.
    expect(paddingRect.right, checkboxRect.right + 4);
    expect(paddingRect.left, titleRect.left - 10);

    // Calculate the remaining height from the default ListTile height.
    final double remainingHeight = 56 - tallerWidget.height;
    expect(paddingRect.top, tallerWidget.top - remainingHeight / 2 - 18);
    expect(paddingRect.bottom, tallerWidget.bottom + remainingHeight / 2 + 2);
  });

  testWidgets('CheckboxListTile tristate test', (WidgetTester tester) async {
    bool? _value = false;
    bool _tristate = false;

    await tester.pumpWidget(
      Material(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return wrap(
              child: CheckboxListTile(
                title: const Text('Title'),
                tristate: _tristate,
                value: _value,
                onChanged: (bool? value) {
                  setState(() {
                    _value = value;
                  });
                },
              ),
            );
          },
        ),
      ),
    );

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, false);

    // Tap the checkbox when tristate is disabled.
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(_value, true);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(_value, false);

    // Tap the listTile when tristate is disabled.
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(_value, true);

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(_value, false);

    // Enable tristate
    _tristate = true;
    await tester.pumpAndSettle();

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, false);

    // Tap the checkbox when tristate is enabled.
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(_value, true);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(_value, null);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(_value, false);

    // Tap the listTile when tristate is enabled.
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(_value, true);

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(_value, null);

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(_value, false);
  });

  testWidgets('CheckboxListTile respects shape', (WidgetTester tester) async {
    const ShapeBorder shapeBorder = RoundedRectangleBorder(
      borderRadius: BorderRadius.horizontal(right: Radius.circular(100))
    );

    await tester.pumpWidget(wrap(
      child: const CheckboxListTile(
        value: false,
        onChanged: null,
        title: Text('Title'),
        shape: shapeBorder,
      ),
    ));

    expect(tester.widget<InkWell>(find.byType(InkWell)).customBorder, shapeBorder);
  });

  testWidgets('CheckboxListTile respects tileColor', (WidgetTester tester) async {
    final Color tileColor = Colors.red.shade500;

    await tester.pumpWidget(
      wrap(
        child: Center(
          child: CheckboxListTile(
            value: false,
            onChanged: null,
            title: const Text('Title'),
            tileColor: tileColor,
          ),
        ),
      ),
    );

    expect(find.byType(Material), paints..path(color: tileColor));
  });

  testWidgets('CheckboxListTile respects selectedTileColor', (WidgetTester tester) async {
    final Color selectedTileColor = Colors.green.shade500;

    await tester.pumpWidget(
      wrap(
        child: Center(
          child: CheckboxListTile(
            value: false,
            onChanged: null,
            title: const Text('Title'),
            selected: true,
            selectedTileColor: selectedTileColor,
          ),
        ),
      ),
    );

    expect(find.byType(Material), paints..path(color: selectedTileColor));
  });

  testWidgets('CheckboxListTile selected item text Color', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/pull/76908

    const Color activeColor = Color(0xff00ff00);

    Widget buildFrame({ Color? activeColor, Color? toggleableActiveColor }) {
      return MaterialApp(
        theme: ThemeData.light().copyWith(
          toggleableActiveColor: toggleableActiveColor,
        ),
        home: Scaffold(
          body: Center(
            child: CheckboxListTile(
              activeColor: activeColor,
              selected: true,
              title: const Text('title'),
              value: true,
              onChanged: (bool? value) { },
            ),
          ),
        ),
      );
    }

    Color? textColor(String text) {
      return tester.renderObject<RenderParagraph>(find.text(text)).text.style?.color;
    }

    await tester.pumpWidget(buildFrame(toggleableActiveColor: activeColor));
    expect(textColor('title'), activeColor);

    await tester.pumpWidget(buildFrame(activeColor: activeColor));
    expect(textColor('title'), activeColor);
  });
}

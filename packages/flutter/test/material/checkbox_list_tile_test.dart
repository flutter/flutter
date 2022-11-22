// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import 'feedback_tester.dart';

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
    const Color checkBoxBorderColor = Color(0xff2196f3);
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
          data: ThemeData(
            checkboxTheme: CheckboxThemeData(
              fillColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                return states.contains(MaterialState.selected) ? themeColor : null;
              }),
            ),
          ),
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
      ),
    );

    final Rect paddingRect = tester.getRect(find.byType(SafeArea));
    final Rect checkboxRect = tester.getRect(find.byType(Checkbox));
    final Rect titleRect = tester.getRect(find.text('Title'));

    final Rect tallerWidget = checkboxRect.height > titleRect.height ? checkboxRect : titleRect;

    // Check the offsets of Checkbox and title after padding is applied.
    expect(paddingRect.right, checkboxRect.right + 4);
    expect(paddingRect.left, titleRect.left - 10);

    // Calculate the remaining height from the default ListTile height.
    final double remainingHeight = 56 - tallerWidget.height;
    expect(paddingRect.top, tallerWidget.top - remainingHeight / 2 - 18);
    expect(paddingRect.bottom, tallerWidget.bottom + remainingHeight / 2 + 2);
  });

  testWidgets('CheckboxListTile tristate test', (WidgetTester tester) async {
    bool? value = false;
    bool tristate = false;

    await tester.pumpWidget(
      Material(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return wrap(
              child: CheckboxListTile(
                title: const Text('Title'),
                tristate: tristate,
                value: value,
                onChanged: (bool? v) {
                  setState(() {
                    value = v;
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
    expect(value, true);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(value, false);

    // Tap the listTile when tristate is disabled.
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(value, true);

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(value, false);

    // Enable tristate
    tristate = true;
    await tester.pumpAndSettle();

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, false);

    // Tap the checkbox when tristate is enabled.
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(value, true);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(value, null);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(value, false);

    // Tap the listTile when tristate is enabled.
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(value, true);

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(value, null);

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(value, false);
  });

  testWidgets('CheckboxListTile respects shape', (WidgetTester tester) async {
    const ShapeBorder shapeBorder = RoundedRectangleBorder(
      borderRadius: BorderRadius.horizontal(right: Radius.circular(100)),
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

    expect(find.byType(Material), paints..rect(color: tileColor));
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

    expect(find.byType(Material), paints..rect(color: selectedTileColor));
  });

  testWidgets('CheckboxListTile selected item text Color', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/pull/76908

    const Color activeColor = Color(0xff00ff00);

    Widget buildFrame({ Color? activeColor, Color? fillColor }) {
      return MaterialApp(
        theme: ThemeData.light().copyWith(
          checkboxTheme: CheckboxThemeData(
            fillColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
              return states.contains(MaterialState.selected) ? fillColor : null;
            }),
          ),
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

    await tester.pumpWidget(buildFrame(fillColor: activeColor));
    expect(textColor('title'), activeColor);

    await tester.pumpWidget(buildFrame(activeColor: activeColor));
    expect(textColor('title'), activeColor);
  });

  testWidgets('CheckboxListTile respects checkbox shape and side', (WidgetTester tester) async {
    Widget buildApp(BorderSide side, OutlinedBorder shape) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return CheckboxListTile(
                value: false,
                onChanged: (bool? newValue) {},
                side: side,
                checkboxShape: shape,
              );
            }),
          ),
        ),
      );
    }
    const RoundedRectangleBorder border1 = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5)));
    const BorderSide side1 = BorderSide(
      color: Color(0xfff44336),
    );
    await tester.pumpWidget(buildApp(side1, border1));
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).side, side1);
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).checkboxShape, border1);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).side, side1);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).shape, border1);
    expect(
      Material.of(tester.element(find.byType(Checkbox))),
      paints
        ..drrect(
          color: const Color(0xfff44336),
          outer: RRect.fromLTRBR(11.0, 11.0, 29.0, 29.0, const Radius.circular(5)),
          inner: RRect.fromLTRBR(12.0, 12.0, 28.0, 28.0, const Radius.circular(4)),
        ),
    );
    const RoundedRectangleBorder border2 = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5)));
    const BorderSide side2 = BorderSide(
      width: 4.0,
      color: Color(0xff424242),
    );
    await tester.pumpWidget(buildApp(side2, border2));
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).side, side2);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).shape, border2);
    expect(
      Material.of(tester.element(find.byType(Checkbox))),
      paints
        ..drrect(
          color: const Color(0xff424242),
          outer: RRect.fromLTRBR(11.0, 11.0, 29.0, 29.0, const Radius.circular(5)),
          inner: RRect.fromLTRBR(15.0, 15.0, 25.0, 25.0, const Radius.circular(1)),
        ),
    );
  });

  testWidgets('CheckboxListTile respects visualDensity', (WidgetTester tester) async {
    const Key key = Key('test');
    Future<void> buildTest(VisualDensity visualDensity) async {
      return tester.pumpWidget(
        wrap(
          child: Center(
            child: CheckboxListTile(
              key: key,
              value: false,
              onChanged: (bool? value) {},
              autofocus: true,
              visualDensity: visualDensity,
            ),
          ),
        ),
      );
    }

    await buildTest(VisualDensity.standard);
    final RenderBox box = tester.renderObject(find.byKey(key));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(800, 56)));
  });

  testWidgets('CheckboxListTile respects focusNode', (WidgetTester tester) async {
    final GlobalKey childKey = GlobalKey();
    await tester.pumpWidget(
      wrap(
        child: Center(
          child: CheckboxListTile(
            value: false,
            title: Text('A', key: childKey),
            onChanged: (bool? value) {},
          ),
        ),
      ),
    );

    await tester.pump();
    final FocusNode tileNode = Focus.of(childKey.currentContext!);
    tileNode.requestFocus();
    await tester.pump(); // Let the focus take effect.
    expect(Focus.of(childKey.currentContext!).hasPrimaryFocus, isTrue);
    expect(tileNode.hasPrimaryFocus, isTrue);
  });

  testWidgets('CheckboxListTile onFocusChange callback', (WidgetTester tester) async {
    final FocusNode node = FocusNode(debugLabel: 'CheckboxListTile onFocusChange');
    bool gotFocus = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: CheckboxListTile(
            value: true,
            focusNode: node,
            onFocusChange: (bool focused) {
              gotFocus = focused;
            },
            onChanged: (bool? value) {},
          ),
        ),
      ),
    );

    node.requestFocus();
    await tester.pump();
    expect(gotFocus, isTrue);
    expect(node.hasFocus, isTrue);

    node.unfocus();
    await tester.pump();
    expect(gotFocus, isFalse);
    expect(node.hasFocus, isFalse);
  });

    testWidgets('CheckboxListTile can be disabled', (WidgetTester tester) async {
      bool? value = false;
      bool enabled = true;

      await tester.pumpWidget(
        Material(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return wrap(
                child: CheckboxListTile(
                  title: const Text('Title'),
                  enabled: enabled,
                  value: value,
                  onChanged: (bool? v) {
                    setState(() {
                      value = v;
                      enabled = !enabled;
                    });
                  },
                ),
              );
            },
          ),
        ),
      );

      final Finder checkbox = find.byType(Checkbox);
      // verify initial values
      expect(tester.widget<Checkbox>(checkbox).value, false);
      expect(enabled, true);

      // Tap the checkbox to disable CheckboxListTile
      await tester.tap(checkbox);
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(checkbox).value, true);
      expect(enabled, false);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(checkbox).value, true);
    });

  group('feedback', () {
    late FeedbackTester feedback;

    setUp(() {
      feedback = FeedbackTester();
    });

    tearDown(() {
      feedback.dispose();
    });

    testWidgets('CheckboxListTile respects enableFeedback', (WidgetTester tester) async {
      Future<void> buildTest(bool enableFeedback) async {
        return tester.pumpWidget(
          wrap(
            child: Center(
              child: CheckboxListTile(
                value: false,
                onChanged: (bool? value) {},
                enableFeedback: enableFeedback,
              ),
            ),
          ),
        );
      }

      await buildTest(false);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 0);
      expect(feedback.hapticCount, 0);

      await buildTest(true);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 1);
      expect(feedback.hapticCount, 0);
    });
  });
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ButtonThemeData defaults', () {
    const ButtonThemeData theme = ButtonThemeData();
    expect(theme.textTheme, ButtonTextTheme.normal);
    expect(theme.constraints, const BoxConstraints(minWidth: 88.0, minHeight: 36.0));
    expect(theme.padding, const EdgeInsets.symmetric(horizontal: 16.0));
    expect(theme.shape, const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(2.0)),
    ));
    expect(theme.alignedDropdown, false);
    expect(theme.layoutBehavior, ButtonBarLayoutBehavior.padded);
  });

  test('ButtonThemeData default overrides', () {
    const ButtonThemeData theme = ButtonThemeData(
      textTheme: ButtonTextTheme.primary,
      minWidth: 100.0,
      height: 200.0,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(),
      alignedDropdown: true,
    );
    expect(theme.textTheme, ButtonTextTheme.primary);
    expect(theme.constraints, const BoxConstraints(minWidth: 100.0, minHeight: 200.0));
    expect(theme.padding, EdgeInsets.zero);
    expect(theme.shape, const RoundedRectangleBorder());
    expect(theme.alignedDropdown, true);
  });

  testWidgets('ButtonTheme defaults', (WidgetTester tester) async {
    ButtonTextTheme textTheme;
    ButtonBarLayoutBehavior layoutBehavior;
    BoxConstraints constraints;
    EdgeInsets padding;
    ShapeBorder shape;
    bool alignedDropdown;
    ColorScheme colorScheme;

    await tester.pumpWidget(
      ButtonTheme(
        child: Builder(
          builder: (BuildContext context) {
            final ButtonThemeData theme = ButtonTheme.of(context);
            textTheme = theme.textTheme;
            constraints = theme.constraints;
            padding = theme.padding as EdgeInsets;
            shape = theme.shape;
            layoutBehavior = theme.layoutBehavior;
            colorScheme = theme.colorScheme;
            alignedDropdown = theme.alignedDropdown;
            return Container(
              alignment: Alignment.topLeft,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: FlatButton(
                  onPressed: () { },
                  child: const Text('b'), // intrinsic width < minimum width
                ),
              ),
            );
          },
        ),
      ),
    );

    expect(textTheme, ButtonTextTheme.normal);
    expect(layoutBehavior, ButtonBarLayoutBehavior.padded);
    expect(constraints, const BoxConstraints(minWidth: 88.0, minHeight: 36.0));
    expect(padding, const EdgeInsets.symmetric(horizontal: 16.0));
    expect(shape, const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(2.0)),
    ));
    expect(alignedDropdown, false);
    expect(colorScheme, ThemeData.light().colorScheme);
    expect(tester.widget<Material>(find.byType(Material)).shape, shape);
    expect(tester.getSize(find.byType(Material)), const Size(88.0, 36.0));
  });

  test('ButtonThemeData.copyWith', () {
    ButtonThemeData theme = const ButtonThemeData().copyWith();
    expect(theme.textTheme, ButtonTextTheme.normal);
    expect(theme.layoutBehavior, ButtonBarLayoutBehavior.padded);
    expect(theme.constraints, const BoxConstraints(minWidth: 88.0, minHeight: 36.0));
    expect(theme.padding, const EdgeInsets.symmetric(horizontal: 16.0));
    expect(theme.shape, const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(2.0)),
    ));
    expect(theme.alignedDropdown, false);
    expect(theme.colorScheme, null);

    theme = const ButtonThemeData().copyWith(
      textTheme: ButtonTextTheme.primary,
      layoutBehavior: ButtonBarLayoutBehavior.constrained,
      minWidth: 100.0,
      height: 200.0,
      padding: EdgeInsets.zero,
      shape: const StadiumBorder(),
      alignedDropdown: true,
      colorScheme: const ColorScheme.dark(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    expect(theme.textTheme, ButtonTextTheme.primary);
    expect(theme.layoutBehavior, ButtonBarLayoutBehavior.constrained);
    expect(theme.constraints, const BoxConstraints(minWidth: 100.0, minHeight: 200.0));
    expect(theme.padding, EdgeInsets.zero);
    expect(theme.shape, const StadiumBorder());
    expect(theme.alignedDropdown, true);
    expect(theme.colorScheme, const ColorScheme.dark());
  });

  testWidgets('Theme buttonTheme defaults', (WidgetTester tester) async {
    final ThemeData lightTheme = ThemeData.light();
    ButtonTextTheme textTheme;
    BoxConstraints constraints;
    EdgeInsets padding;
    ShapeBorder shape;

    const Color disabledColor = Color(0xFF00FF00);
    await tester.pumpWidget(
      Theme(
        data: lightTheme.copyWith(
          disabledColor: disabledColor, // disabled RaisedButton fill color
          buttonTheme: const ButtonThemeData(disabledColor: disabledColor),
          textTheme: lightTheme.textTheme.copyWith(
            button: lightTheme.textTheme.button.copyWith(
              // The button's height will match because there's no
              // vertical padding by default
              fontSize: 48.0,
            ),
          ),
        ),
        child: Builder(
          builder: (BuildContext context) {
            final ButtonThemeData theme = ButtonTheme.of(context);
            textTheme = theme.textTheme;
            constraints = theme.constraints;
            padding = theme.padding as EdgeInsets;
            shape = theme.shape;
            return Container(
              alignment: Alignment.topLeft,
              child: const Directionality(
                textDirection: TextDirection.ltr,
                child: RaisedButton(
                  onPressed: null,
                  child: Text('b'), // intrinsic width < minimum width
                ),
              ),
            );
          },
        ),
      ),
    );

    expect(textTheme, ButtonTextTheme.normal);
    expect(constraints, const BoxConstraints(minWidth: 88.0, minHeight: 36.0));
    expect(padding, const EdgeInsets.symmetric(horizontal: 16.0));
    expect(shape, const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(2.0)),
    ));

    expect(tester.widget<Material>(find.byType(Material)).shape, shape);
    expect(tester.widget<Material>(find.byType(Material)).color, disabledColor);
    expect(tester.getSize(find.byType(Material)), const Size(88.0, 48.0));
  });

  testWidgets('Theme buttonTheme ButtonTheme overrides', (WidgetTester tester) async {
    ButtonTextTheme textTheme;
    BoxConstraints constraints;
    EdgeInsets padding;
    ShapeBorder shape;

    await tester.pumpWidget(
      Theme(
        data: ThemeData.light().copyWith(
          buttonColor: const Color(0xFF00FF00), // enabled RaisedButton fill color
        ),
        child: ButtonTheme(
          textTheme: ButtonTextTheme.primary,
          minWidth: 100.0,
          height: 200.0,
          padding: EdgeInsets.zero,
          buttonColor: const Color(0xFF00FF00), // enabled RaisedButton fill color
          shape: const RoundedRectangleBorder(),
          child: Builder(
            builder: (BuildContext context) {
              final ButtonThemeData theme = ButtonTheme.of(context);
              textTheme = theme.textTheme;
              constraints = theme.constraints;
              padding = theme.padding as EdgeInsets;
              shape = theme.shape;
              return Container(
                alignment: Alignment.topLeft,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: RaisedButton(
                    onPressed: () { },
                    child: const Text('b'), // intrinsic width < minimum width
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(textTheme, ButtonTextTheme.primary);
    expect(constraints, const BoxConstraints(minWidth: 100.0, minHeight: 200.0));
    expect(padding, EdgeInsets.zero);
    expect(shape, const RoundedRectangleBorder());

    expect(tester.widget<Material>(find.byType(Material)).shape, shape);
    expect(tester.widget<Material>(find.byType(Material)).color, const Color(0xFF00FF00));
    expect(tester.getSize(find.byType(Material)), const Size(100.0, 200.0));
  });

  testWidgets('ButtonTheme alignedDropdown', (WidgetTester tester) async {
    final Key dropdownKey = UniqueKey();

    Widget buildFrame({ bool alignedDropdown, TextDirection textDirection }) {
      return MaterialApp(
        builder: (BuildContext context, Widget child) {
          return Directionality(
            textDirection: textDirection,
            child: child,
          );
        },
        home: ButtonTheme(
          alignedDropdown: alignedDropdown,
          child: Material(
            child: Builder(
              builder: (BuildContext context) {
                return Container(
                  alignment: Alignment.center,
                  child: DropdownButtonHideUnderline(
                    child: Container(
                      width: 200.0,
                      child: DropdownButton<String>(
                        key: dropdownKey,
                        onChanged: (String value) { },
                        value: 'foo',
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem<String>(
                            value: 'foo',
                            child: Text('foo'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'bar',
                            child: Text('bar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    final Finder button = find.byKey(dropdownKey);
    final Finder menu = find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_DropdownMenu<String>');

    await tester.pumpWidget(
      buildFrame(
        alignedDropdown: false,
        textDirection: TextDirection.ltr,
      ),
    );
    await tester.tap(button);
    await tester.pumpAndSettle();

    // 240 = 200.0 (button width) + _kUnalignedMenuMargin (20.0 left and right)
    expect(tester.getSize(button).width, 200.0);
    expect(tester.getSize(menu).width, 240.0);

    // Dismiss the menu.
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    expect(menu, findsNothing);

    await tester.pumpWidget(
      buildFrame(
        alignedDropdown: true,
        textDirection: TextDirection.ltr,
      ),
    );
    await tester.tap(button);
    await tester.pumpAndSettle();

    // Aligneddropdown: true means the button and menu widths match
    expect(tester.getSize(button).width, 200.0);
    expect(tester.getSize(menu).width, 200.0);

    // There are two 'foo' widgets: the selected menu item's label and the drop
    // down button's label. The should both appear at the same location.
    final Finder fooText = find.text('foo');
    expect(fooText, findsNWidgets(2));
    expect(tester.getRect(fooText.at(0)), tester.getRect(fooText.at(1)));

    // Dismiss the menu.
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    expect(menu, findsNothing);

    // Same test as above except RTL
    await tester.pumpWidget(
      buildFrame(
        alignedDropdown: true,
        textDirection: TextDirection.rtl,
      ),
    );
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(fooText, findsNWidgets(2));
    expect(tester.getRect(fooText.at(0)), tester.getRect(fooText.at(1)));
  });

  testWidgets('button theme with stateful color changes color in states', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    const Color pressedColor = Color(0x00000001);
    const Color hoverColor = Color(0x00000002);
    const Color focusedColor = Color(0x00000003);
    const Color defaultColor = Color(0x00000004);

    Color getTextColor(Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed)) {
        return pressedColor;
      }
      if (states.contains(MaterialState.hovered)) {
        return hoverColor;
      }
      if (states.contains(MaterialState.focused)) {
        return focusedColor;
      }
      return defaultColor;
    }

    const ColorScheme colorScheme = ColorScheme.light();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ButtonTheme(
              colorScheme: colorScheme.copyWith(
                primary: MaterialStateColor.resolveWith(getTextColor),
              ),
              textTheme: ButtonTextTheme.primary,
              child: FlatButton(
                child: const Text('FlatButton'),
                onPressed: () {},
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      ),
    );

    Color textColor() {
      return tester.renderObject<RenderParagraph>(find.text('FlatButton')).text.style.color;
    }

    // Default, not disabled.
    expect(textColor(), equals(defaultColor));

    // Focused.
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(textColor(), focusedColor);

    // Hovered.
    final Offset center = tester.getCenter(find.byType(FlatButton));
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(center);
    await tester.pumpAndSettle();
    expect(textColor(), hoverColor);

    // Highlighted (pressed).
    await gesture.down(center);
    await tester.pump(); // Start the splash and highlight animations.
    await tester.pump(const Duration(milliseconds: 800)); // Wait for splash and highlight to be well under way.
    expect(textColor(), pressedColor);
  },
    semanticsEnabled: true,
  );
}

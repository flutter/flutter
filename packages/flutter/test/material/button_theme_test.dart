// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ButtonThemeData defaults', () {
    const ButtonThemeData theme = const ButtonThemeData();
    expect(theme.textTheme, ButtonTextTheme.normal);
    expect(theme.constraints, const BoxConstraints(minWidth: 88.0, minHeight: 36.0));
    expect(theme.padding, const EdgeInsets.symmetric(horizontal: 16.0));
    expect(theme.shape, const RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(const Radius.circular(2.0)),
    ));
    expect(theme.alignedDropdown, false);
  });

  test('ButtonThemeData default overrides', () {
    const ButtonThemeData theme = const ButtonThemeData(
      textTheme: ButtonTextTheme.primary,
      minWidth: 100.0,
      height: 200.0,
      padding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(),
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
    BoxConstraints constraints;
    EdgeInsets padding;
    ShapeBorder shape;

    await tester.pumpWidget(
      new ButtonTheme(
        child: new Builder(
          builder: (BuildContext context) {
            final ButtonThemeData theme = ButtonTheme.of(context);
            textTheme = theme.textTheme;
            constraints = theme.constraints;
            padding = theme.padding;
            shape = theme.shape;
            return new Container(
              alignment: Alignment.topLeft,
              child: const Directionality(
                textDirection: TextDirection.ltr,
                child: const FlatButton(
                  onPressed: null,
                  child: const Text('b'), // intrinsic width < minimum width
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
      borderRadius: const BorderRadius.all(const Radius.circular(2.0)),
    ));

    expect(tester.widget<Material>(find.byType(Material)).shape, shape);
    expect(tester.getSize(find.byType(Material)), const Size(88.0, 36.0));
  });

  testWidgets('Theme buttonTheme defaults', (WidgetTester tester) async {
    final ThemeData lightTheme = new ThemeData.light();
    ButtonTextTheme textTheme;
    BoxConstraints constraints;
    EdgeInsets padding;
    ShapeBorder shape;

    await tester.pumpWidget(
      new Theme(
        data: lightTheme.copyWith(
          disabledColor: const Color(0xFF00FF00), // disabled RaisedButton fill color
          textTheme: lightTheme.textTheme.copyWith(
            button: lightTheme.textTheme.button.copyWith(
              // The button's height will match because there's no
              // vertical padding by default
              fontSize: 48.0,
            ),
          ),
        ),
        child: new Builder(
          builder: (BuildContext context) {
            final ButtonThemeData theme = ButtonTheme.of(context);
            textTheme = theme.textTheme;
            constraints = theme.constraints;
            padding = theme.padding;
            shape = theme.shape;
            return new Container(
              alignment: Alignment.topLeft,
              child: const Directionality(
                textDirection: TextDirection.ltr,
                child: const RaisedButton(
                  onPressed: null,
                  child: const Text('b'), // intrinsic width < minimum width
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
      borderRadius: const BorderRadius.all(const Radius.circular(2.0)),
    ));

    expect(tester.widget<Material>(find.byType(Material)).shape, shape);
    expect(tester.widget<Material>(find.byType(Material)).color, const Color(0xFF00FF00));
    expect(tester.getSize(find.byType(Material)), const Size(88.0, 48.0));
  });

  testWidgets('Theme buttonTheme ButtonTheme overrides', (WidgetTester tester) async {
    ButtonTextTheme textTheme;
    BoxConstraints constraints;
    EdgeInsets padding;
    ShapeBorder shape;

    await tester.pumpWidget(
      new Theme(
        data: new ThemeData.light().copyWith(
          buttonColor: const Color(0xFF00FF00), // enabled RaisedButton fill color
        ),
        child: new ButtonTheme(
          textTheme: ButtonTextTheme.primary,
          minWidth: 100.0,
          height: 200.0,
          padding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(),
          child: new Builder(
            builder: (BuildContext context) {
              final ButtonThemeData theme = ButtonTheme.of(context);
              textTheme = theme.textTheme;
              constraints = theme.constraints;
              padding = theme.padding;
              shape = theme.shape;
              return new Container(
                alignment: Alignment.topLeft,
                child: new Directionality(
                  textDirection: TextDirection.ltr,
                  child: new RaisedButton(
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
    final Key dropdownKey = new UniqueKey();

    Widget buildFrame({ bool alignedDropdown, TextDirection textDirection }) {
      return new MaterialApp(
        builder: (BuildContext context, Widget child) {
          return new Directionality(
            textDirection: textDirection,
            child: child,
          );
        },
        home: new ButtonTheme(
          alignedDropdown: alignedDropdown,
          child: new Material(
            child: new Builder(
              builder: (BuildContext context) {
                return new Container(
                  alignment: Alignment.center,
                  child: new DropdownButtonHideUnderline(
                    child: new Container(
                      width: 200.0,
                      child: new DropdownButton<String>(
                        key: dropdownKey,
                        onChanged: (String value) { },
                        value: 'foo',
                        items: const <DropdownMenuItem<String>>[
                          const DropdownMenuItem<String>(
                            value: 'foo',
                            child: const Text('foo'),
                          ),
                          const DropdownMenuItem<String>(
                            value: 'bar',
                            child: const Text('bar'),
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

    // Same test as above execpt RTL
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
}

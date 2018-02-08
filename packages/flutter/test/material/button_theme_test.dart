// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ButtonThemeData defaults', () {
    final ButtonThemeData theme = const ButtonThemeData();
    expect(theme.textTheme, ButtonTextTheme.normal);
    expect(theme.constraints, const BoxConstraints(minWidth: 88.0, minHeight: 36.0));
    expect(theme.padding, const EdgeInsets.symmetric(horizontal: 16.0));
    expect(theme.shape, const RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(const Radius.circular(2.0)),
    ));
  });

  test('ButtonThemeData default overrides', () {
    final ButtonThemeData theme = const ButtonThemeData(
      textTheme: ButtonTextTheme.primary,
      minWidth: 100.0,
      height: 200.0,
      padding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(),
    );
    expect(theme.textTheme, ButtonTextTheme.primary);
    expect(theme.constraints, const BoxConstraints(minWidth: 100.0, minHeight: 200.0));
    expect(theme.padding, EdgeInsets.zero);
    expect(theme.shape, const RoundedRectangleBorder());
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
}

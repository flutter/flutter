// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ButtonBar default control smoketest', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: ButtonBar(),
      ),
    );
  });

  group('alignment', () {

    testWidgets('default alignment is MainAxisAlignment.end', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ButtonBar(
            children: <Widget>[
              SizedBox(width: 10.0, height: 10.0),
            ],
          ),
        )
      );

      final Finder child = find.byType(SizedBox);
      // Should be positioned to the right of the bar,
      expect(tester.getRect(child).left, 782.0);  // bar width - default padding - 10
      expect(tester.getRect(child).right, 792.0); // bar width - default padding
    });

    testWidgets('ButtonBarTheme.alignment overrides default', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ButtonBarTheme(
            data: ButtonBarThemeData(
              alignment: MainAxisAlignment.center,
            ),
            child: ButtonBar(
              children: <Widget>[
                SizedBox(width: 10.0, height: 10.0),
              ],
            ),
          ),
        )
      );

      final Finder child = find.byType(SizedBox);
      // Should be positioned in the center
      expect(tester.getRect(child).left, 395.0);  // (bar width - padding) / 2 - 10 / 2
      expect(tester.getRect(child).right, 405.0); // (bar width - padding) / 2 - 10 / 2 + 10
    });

    testWidgets('ButtonBar.alignment overrides ButtonBarTheme.alignment and default', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ButtonBarTheme(
            data: ButtonBarThemeData(
              alignment: MainAxisAlignment.center,
            ),
            child: ButtonBar(
              alignment: MainAxisAlignment.start,
              children: <Widget>[
                SizedBox(width: 10.0, height: 10.0),
              ],
            ),
          ),
        )
      );

      final Finder child = find.byType(SizedBox);
      // Should be positioned on the left
      expect(tester.getRect(child).left, 8.0);   // padding
      expect(tester.getRect(child).right, 18.0); // padding + 10
    });

  });

  group('mainAxisSize', () {

    testWidgets('default mainAxisSize is MainAxisSize.max', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ButtonBar(
            children: <Widget>[
              Container(),
            ],
          ),
        )
      );

      // ButtonBar uses a Row internally to implement this
      final Row row = tester.widget(find.byType(Row));
      expect(row.mainAxisSize, equals(MainAxisSize.max));
    });

    testWidgets('ButtonBarTheme.mainAxisSize overrides default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ButtonBarTheme(
            data: const ButtonBarThemeData(
              mainAxisSize: MainAxisSize.min,
            ),
            child: ButtonBar(
              children: <Widget>[
                Container(),
              ],
            ),
          ),
        )
      );

      // ButtonBar uses a Row internally to implement this
      final Row row = tester.widget(find.byType(Row));
      expect(row.mainAxisSize, equals(MainAxisSize.min));
    });

    testWidgets('ButtonBar.mainAxisSize overrides ButtonBarTheme.mainAxisSize and default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ButtonBarTheme(
            data: const ButtonBarThemeData(
              mainAxisSize: MainAxisSize.min,
            ),
            child: ButtonBar(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Container(),
              ],
            ),
          ),
        )
      );

      // ButtonBar uses a Row internally to implement this
      final Row row = tester.widget(find.byType(Row));
      expect(row.mainAxisSize, equals(MainAxisSize.max));
    });

  });

  group('button properies override ButtonTheme', () {

    testWidgets('default button properties override ButtonTheme properties', (WidgetTester tester) async {
      BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: ButtonBar(
            children: <Widget>[
              Builder(builder: (BuildContext context) {
                capturedContext = context;
                return Container();
              })
            ],
          ),
        )
      );
      final ButtonThemeData buttonTheme = ButtonTheme.of(capturedContext);
      expect(buttonTheme.textTheme, equals(ButtonTextTheme.primary));
      expect(buttonTheme.minWidth, equals(64.0));
      expect(buttonTheme.height, equals(36.0));
      expect(buttonTheme.padding, equals(const EdgeInsets.symmetric(horizontal: 8.0)));
      expect(buttonTheme.alignedDropdown, equals(false));
      expect(buttonTheme.layoutBehavior, equals(ButtonBarLayoutBehavior.padded));
    });

    testWidgets('ButtonBarTheme button properties override defaults and ButtonTheme properties', (WidgetTester tester) async {
      BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: ButtonBarTheme(
            data: const ButtonBarThemeData(
              buttonTextTheme: ButtonTextTheme.primary,
              buttonMinWidth: 42.0,
              buttonHeight: 84.0,
              buttonPadding: EdgeInsets.fromLTRB(10, 20, 30, 40),
              buttonAlignedDropdown: true,
              layoutBehavior: ButtonBarLayoutBehavior.constrained,
            ),
            child: ButtonBar(
              children: <Widget>[
                Builder(builder: (BuildContext context) {
                  capturedContext = context;
                  return Container();
                })
              ],
            ),
          ),
        )
      );
      final ButtonThemeData buttonTheme = ButtonTheme.of(capturedContext);
      expect(buttonTheme.textTheme, equals(ButtonTextTheme.primary));
      expect(buttonTheme.minWidth, equals(42.0));
      expect(buttonTheme.height, equals(84.0));
      expect(buttonTheme.padding, equals(const EdgeInsets.fromLTRB(10, 20, 30, 40)));
      expect(buttonTheme.alignedDropdown, equals(true));
      expect(buttonTheme.layoutBehavior, equals(ButtonBarLayoutBehavior.constrained));
    });

    testWidgets('ButtonBar button properties override ButtonBarTheme, defaults and ButtonTheme properties', (WidgetTester tester) async {
      BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: ButtonBarTheme(
            data: const ButtonBarThemeData(
              buttonTextTheme: ButtonTextTheme.accent,
              buttonMinWidth: 4242.0,
              buttonHeight: 8484.0,
              buttonPadding: EdgeInsets.fromLTRB(50, 60, 70, 80),
              buttonAlignedDropdown: false,
              layoutBehavior: ButtonBarLayoutBehavior.padded,
            ),
            child: ButtonBar(
              buttonTextTheme: ButtonTextTheme.primary,
              buttonMinWidth: 42.0,
              buttonHeight: 84.0,
              buttonPadding: const EdgeInsets.fromLTRB(10, 20, 30, 40),
              buttonAlignedDropdown: true,
              layoutBehavior: ButtonBarLayoutBehavior.constrained,
              children: <Widget>[
                Builder(builder: (BuildContext context) {
                  capturedContext = context;
                  return Container();
                })
              ],
            ),
          ),
        )
      );
      final ButtonThemeData buttonTheme = ButtonTheme.of(capturedContext);
      expect(buttonTheme.textTheme, equals(ButtonTextTheme.primary));
      expect(buttonTheme.minWidth, equals(42.0));
      expect(buttonTheme.height, equals(84.0));
      expect(buttonTheme.padding, equals(const EdgeInsets.fromLTRB(10, 20, 30, 40)));
      expect(buttonTheme.alignedDropdown, equals(true));
      expect(buttonTheme.layoutBehavior, equals(ButtonBarLayoutBehavior.constrained));
    });

  });

  group('layoutBehavior', () {

    testWidgets('ButtonBar has a min height of 52 when using ButtonBarLayoutBehavior.constrained', (WidgetTester tester) async {
      await tester.pumpWidget(
        SingleChildScrollView(
          child: ListBody(
            children: const <Widget>[
              Directionality(
                textDirection: TextDirection.ltr,
                child: ButtonBar(
                  layoutBehavior: ButtonBarLayoutBehavior.constrained,
                  children: <Widget>[
                    SizedBox(width: 10.0, height: 10.0),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      final Finder buttonBar = find.byType(ButtonBar);
      expect(tester.getBottomRight(buttonBar).dy - tester.getTopRight(buttonBar).dy, 52.0);
    });

    testWidgets('ButtonBar has padding applied when using ButtonBarLayoutBehavior.padded', (WidgetTester tester) async {
      await tester.pumpWidget(
        SingleChildScrollView(
          child: ListBody(
            children: const <Widget>[
              Directionality(
                textDirection: TextDirection.ltr,
                child: ButtonBar(
                  layoutBehavior: ButtonBarLayoutBehavior.padded,
                  children: <Widget>[
                    SizedBox(width: 10.0, height: 10.0),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      final Finder buttonBar = find.byType(ButtonBar);
      expect(tester.getBottomRight(buttonBar).dy - tester.getTopRight(buttonBar).dy, 26.0);
    });

  });

}

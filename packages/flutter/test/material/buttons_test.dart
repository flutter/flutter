// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Does FlatButton contribute semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Material(
          child: new Center(
            child: new FlatButton(
              onPressed: () { },
              child: const Text('ABC')
            ),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            actions: SemanticsAction.tap.index,
            label: 'ABC',
            rect: new Rect.fromLTRB(0.0, 0.0, 88.0, 36.0),
            transform: new Matrix4.translationValues(356.0, 282.0, 0.0)
          )
        ]
      )
    ));

    semantics.dispose();
  });

  testWidgets('Does FlatButton scale with font scale changes', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Material(
          child: new MediaQuery(
            data: const MediaQueryData(textScaleFactor: 1.0),
            child: new Center(
              child: new FlatButton(
                onPressed: () { },
                child: const Text('ABC'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(FlatButton)), equals(const Size(88.0, 36.0)));

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Material(
          child: new MediaQuery(
            data: const MediaQueryData(textScaleFactor: 1.3),
            child: new Center(
              child: new FlatButton(
                onPressed: () { },
                child: const Text('ABC'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(FlatButton)), equals(const Size(88.0, 36.0)));
  });

  // This test is very similar to the '...explicit splashColor and highlightColor' test
  // in icon_button_test.dart. If you change this one, you may want to also change that one.
  testWidgets('MaterialButton with explicit splashColor and highlightColor', (WidgetTester tester) async {
    final Color directSplashColor = const Color(0xFF000011);
    final Color directHighlightColor = const Color(0xFF000011);

    Widget buttonWidget = new Material(
      child: new Center(
        child: new MaterialButton(
          splashColor: directSplashColor,
          highlightColor: directHighlightColor,
          onPressed: () { /* to make sure the button is enabled */ },
        ),
      ),
    );

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Theme(
          data: new ThemeData(),
          child: buttonWidget,
        ),
      ),
    );

    final Offset center = tester.getCenter(find.byType(MaterialButton));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(); // start gesture
    await tester.pump(const Duration(milliseconds: 200)); // wait for splash to be well under way

    expect(
      Material.of(tester.element(find.byType(MaterialButton))),
      paints
        ..circle(color: directSplashColor)
        ..rrect(color: directHighlightColor)
    );

    final Color themeSplashColor1 = const Color(0xFF001100);
    final Color themeHighlightColor1 = const Color(0xFF001100);

    buttonWidget = new Material(
      child: new Center(
        child: new MaterialButton(
          onPressed: () { /* to make sure the button is enabled */ },
        ),
      ),
    );

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Theme(
          data: new ThemeData(
            highlightColor: themeHighlightColor1,
            splashColor: themeSplashColor1,
          ),
          child: buttonWidget,
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byType(MaterialButton))),
      paints
        ..circle(color: themeSplashColor1)
        ..rrect(color: themeHighlightColor1)
    );

    final Color themeSplashColor2 = const Color(0xFF002200);
    final Color themeHighlightColor2 = const Color(0xFF002200);

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Theme(
          data: new ThemeData(
            highlightColor: themeHighlightColor2,
            splashColor: themeSplashColor2,
          ),
          child: buttonWidget, // same widget, so does not get updated because of us
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byType(MaterialButton))),
      paints
        ..circle(color: themeSplashColor2)
        ..rrect(color: themeHighlightColor2)
    );

    await gesture.up();
  });

}

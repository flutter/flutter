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
      new Material(
        child: new Center(
          child: new FlatButton(
            onPressed: () { },
            child: const Text('ABC')
          )
        )
      )
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

  testWidgets('Does button highlight + splash colors work if set directly', (WidgetTester tester) async {
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
      new Theme(
        data: new ThemeData(),
        child: buttonWidget,
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
      new Theme(
        data: new ThemeData(
          highlightColor: themeHighlightColor1,
          splashColor: themeSplashColor1,
        ),
        child: buttonWidget,
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
      new Theme(
        data: new ThemeData(
          highlightColor: themeHighlightColor2,
          splashColor: themeSplashColor2,
        ),
        child: buttonWidget, // same widget, so does not get updated because of us
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

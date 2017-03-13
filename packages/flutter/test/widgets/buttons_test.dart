// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('Does FlatButton contribute semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new FlatButton(
            onPressed: () { },
            child: new Text('ABC')
          )
        )
      )
    );

    expect(semantics, hasSemantics(
      new TestSemantics(
        id: 0,
        children: <TestSemantics>[
          new TestSemantics(
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


  Widget _buttonWidget({
    Key buttonKey,
    Key materialKey,
    Color color, Color
    highlightColor,
    Color splashColor,
    double minWidth = 150.0,
    double height = 60.0,
    bool useTheme = false
  }) {

    final Key definedMaterialKey = materialKey ?? new UniqueKey();
    final Key definedButtonKey = buttonKey ?? new UniqueKey();

    Widget buttonWidget = new Material(
      key: definedMaterialKey,
      child: new Center(
        child: new MaterialButton(
          key: definedButtonKey,
          color: color,
          highlightColor: !useTheme ? highlightColor : null,
          splashColor: !useTheme ? splashColor : null,
          minWidth: minWidth,
          height: height,
          onPressed: () { },
        ),
      ),
    );
    if (useTheme) {
      final ThemeData themeData = new ThemeData(
        accentColor: color,
        highlightColor: highlightColor,
        splashColor: splashColor,
      );
      buttonWidget = new Theme(
        data: themeData,
        child: buttonWidget,
      );
    }
    return buttonWidget;
  }

  testWidgets('Does button highlight + splash colors work if set directly', (WidgetTester tester) async {
    final Color buttonColor = new Color(0xFFFFFF00);
    final Color highlightColor = new Color(0xDD0000FF);
    final Color splashColor = new Color(0xAA0000FF);

    final Key materialKey = new UniqueKey();
    final Key buttonKey = new UniqueKey();

    await tester.pumpWidget(
      _buttonWidget(
        materialKey: materialKey,
        buttonKey: buttonKey,
        color: buttonColor,
        highlightColor: highlightColor,
        splashColor: splashColor,
      ),
    );

    final Point center = tester.getCenter(find.byKey(buttonKey));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(new Duration(milliseconds: 200));

    // TODO(lukef) - the object returned by renderObject does not contain splash or highlights (??)
//    final RRect buttonRRect = new RRect.fromLTRBR(0.0, 0.0, 150.0, 60.0, new Radius.circular(2.0));
//    expect(tester.renderObject(find.byKey(buttonKey)), paints
//        ..rrect(rrect: buttonRRect, color: buttonColor)
//    );
    await gesture.up();
  });

  testWidgets('Does button highlight color work if set via theme', (WidgetTester tester) async {
    final Color buttonColor = new Color(0xFFFFFF00);
    final Color highlightColor = new Color(0xDD0000FF);
    final Color splashColor = new Color(0xAA0000FF);

    final Key materialKey = new UniqueKey();
    final Key buttonKey = new UniqueKey();

    await tester.pumpWidget(
      _buttonWidget(
        useTheme: true, // use a theme wrapper
        materialKey: materialKey,
        buttonKey: buttonKey,
        color: buttonColor,
        highlightColor: highlightColor,
        splashColor: splashColor,
      ),
    );

    final Point center = tester.getCenter(find.byKey(buttonKey));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(new Duration(milliseconds: 200));

    // TODO(lukef) - the object returned by renderObject does not contain splash or highlights (??)
//    final RRect buttonRRect = new RRect.fromLTRBR(0.0, 0.0, 150.0, 60.0, new Radius.circular(2.0));
//    expect(find.byKey(buttonKey), paints
//        ..rrect(rrect: buttonRRect, color: buttonColor)
//    );
    await gesture.up();
  });

}

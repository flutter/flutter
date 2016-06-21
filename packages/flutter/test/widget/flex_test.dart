// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Can hit test flex children of stacks', (WidgetTester tester) async {
    bool didReceiveTap = false;
    await tester.pumpWidget(
      new Container(
        decoration: const BoxDecoration(
          backgroundColor: const Color(0xFF00FF00)
        ),
        child: new Stack(
          children: <Widget>[
            new Positioned(
              top: 10.0,
              left: 10.0,
              child: new Column(
                children: <Widget>[
                  new GestureDetector(
                    onTap: () {
                      didReceiveTap = true;
                    },
                    child: new Container(
                      decoration: const BoxDecoration(
                        backgroundColor: const Color(0xFF0000FF)
                      ),
                      width: 100.0,
                      height: 100.0,
                      child: new Center(
                        child: new Text('X')
                      )
                    )
                  )
                ]
              )
            )
          ]
        )
      )
    );

    await tester.tap(find.text('X'));
    expect(didReceiveTap, isTrue);
  });

  testWidgets('Row and MainAxisSize.min', (WidgetTester tester) async {
    final Key flexKey = new Key('flexKey');

    // Default is MainAxisSize.max so the Row should be as wide as the test: 800.
    await tester.pumpWidget(new Center(
      child: new Row(
        children: <Widget>[
          new Container(width: 10.0, height: 100.0),
          new Container(width: 30.0, height: 100.0)
        ],
        key: flexKey
      )
    ));
    RenderBox renderBox = tester.renderObject(find.byKey(flexKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(100.0));

    // Row with MainAxisSize.min without flexible children shrink wraps.
    await tester.pumpWidget(new Center(
      child: new Row(
        children: <Widget>[
          new Container(width: 10.0, height: 100.0),
          new Container(width: 30.0, height: 100.0)
        ],
        key: flexKey,
        mainAxisSize: MainAxisSize.min
      )
    ));
    renderBox = tester.renderObject(find.byKey(flexKey));
    expect(renderBox.size.width, equals(40.0));
    expect(renderBox.size.height, equals(100.0));
  });

  testWidgets('Column and MainAxisSize.min', (WidgetTester tester) async {
    final Key flexKey = new Key('flexKey');

    // Default is MainAxisSize.max so the Column should be as high as the test: 600.
    await tester.pumpWidget(new Center(
      child: new Column(
        children: <Widget>[
          new Container(width: 100.0, height: 100.0),
          new Container(width: 100.0, height: 150.0)
        ],
        key: flexKey
      )
    ));
    RenderBox renderBox = tester.renderObject(find.byKey(flexKey));
    expect(renderBox.size.width, equals(100.0));
    expect(renderBox.size.height, equals(600.0));

    // Column with MainAxisSize.min without flexible children shrink wraps.
    await tester.pumpWidget(new Center(
      child: new Column(
        children: <Widget>[
          new Container(width: 100.0, height: 100.0),
          new Container(width: 100.0, height: 150.0)
        ],
        key: flexKey,
        mainAxisSize: MainAxisSize.min
      )
    ));
    renderBox = tester.renderObject(find.byKey(flexKey));
    expect(renderBox.size.width, equals(100.0));
    expect(renderBox.size.height, equals(250.0));
  });

  testWidgets('Can layout at zero size', (WidgetTester tester) async {
    final Key childKey = new Key('childKey');

    await tester.pumpWidget(new Center(
      child: new Container(
        width: 0.0,
        height: 0.0,
        child:  new Column(
          children: <Widget>[
            new Container(
              key: childKey,
              width: 100.0,
              height: 100.0
            )
          ],
          mainAxisSize: MainAxisSize.min
        )
      )
    ));

    RenderBox renderBox = tester.renderObject(find.byKey(childKey));
    expect(renderBox.size.width, equals(0.0));
    expect(renderBox.size.height, equals(100.0));

    await tester.pumpWidget(new Center(
      child: new Container(
        width: 0.0,
        height: 0.0,
        child:  new Row(
          children: <Widget>[
            new Container(
              key: childKey,
              width: 100.0,
              height: 100.0
            )
          ],
          mainAxisSize: MainAxisSize.min
        )
      )
    ));

    renderBox = tester.renderObject(find.byKey(childKey));
    expect(renderBox.size.width, equals(100.0));
    expect(renderBox.size.height, equals(0.0));
  });
}

// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('test default icon buttons are sized up to 48', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new IconButton(
            onPressed: () {},
            icon: new Icon(Icons.link),
          )
        )
      )
    );

    RenderBox iconButton = tester.renderObject(find.byType(IconButton));
    expect(iconButton.size, new Size(48.0, 48.0));
  });

  testWidgets('test small icons are sized up to 48dp', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new IconButton(
            iconSize: 10.0,
            onPressed: () {},
            icon: new Icon(Icons.link),
          )
        )
      )
    );

    RenderBox iconButton = tester.renderObject(find.byType(IconButton));
    expect(iconButton.size, new Size(48.0, 48.0));
  });

  testWidgets('test icons can be small when total size is >48dp', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new IconButton(
            iconSize: 10.0,
            padding: new EdgeInsets.all(30.0),
            onPressed: () {},
            icon: new Icon(Icons.link),
          )
        )
      )
    );

    RenderBox iconButton = tester.renderObject(find.byType(IconButton));
    expect(iconButton.size, new Size(70.0, 70.0));
  });

  testWidgets('test default icon buttons are constrained', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {},
            icon: new Icon(Icons.ac_unit),
            iconSize: 80.0,
          )
        )
      )
    );

    RenderBox box = tester.renderObject(find.byType(IconButton));
    expect(box.size, new Size(80.0, 80.0));
  });

  testWidgets(
    'test default icon buttons can be stretched if specified',
    (WidgetTester tester) async {
    await tester.pumpWidget(
      new Material(
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget> [
            new IconButton(
              onPressed: () {},
              icon: new Icon(Icons.ac_unit),
            ),
          ],
        ),
      ),
    );

    RenderBox box = tester.renderObject(find.byType(IconButton));
    expect(box.size, new Size(48.0, 600.0));
  });

  testWidgets('test default padding', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new IconButton(
            onPressed: () {},
            icon: new Icon(Icons.ac_unit),
            iconSize: 80.0,
          )
        )
      )
    );

    RenderBox box = tester.renderObject(find.byType(IconButton));
    expect(box.size, new Size(96.0, 96.0));
  });

  testWidgets('IconButton AppBar size', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Scaffold(
        appBar: new AppBar(
          actions: <Widget>[
            new IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {},
              icon: new Icon(Icons.ac_unit),
            )
          ]
        )
      )
    );

    RenderBox barBox = tester.renderObject(find.byType(AppBar));
    RenderBox iconBox = tester.renderObject(find.byType(IconButton));
    expect(iconBox.size.height, equals(barBox.size.height));
  });
}

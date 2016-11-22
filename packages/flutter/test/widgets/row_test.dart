// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Row with one Flexible child', (WidgetTester tester) async {
    final Key rowKey = new Key('row');
    final Key child0Key = new Key('child0');
    final Key child1Key = new Key('child1');
    final Key child2Key = new Key('child2');

    // Default is MainAxisSize.max so the Row should be as wide as the test: 800.
    // Default is MainAxisAlignment.start so children so the children's
    // left edges should be at 0, 100, 700, child2's width should be 600
    await tester.pumpWidget(new Center(
      child: new Row(
        key: rowKey,
        children: <Widget>[
          new Container(key: child0Key, width: 100.0, height: 100.0),
          new Expanded(child: new Container(key: child1Key, width: 100.0, height: 100.0)),
          new Container(key: child2Key, width: 100.0, height: 100.0),
        ]
      )
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(rowKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(100.0));

    renderBox = tester.renderObject(find.byKey(child0Key));
    expect(renderBox.size.width, equals(100.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(0.0));

    renderBox = tester.renderObject(find.byKey(child1Key));
    expect(renderBox.size.width, equals(600.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(100.0));

    renderBox = tester.renderObject(find.byKey(child2Key));
    expect(renderBox.size.width, equals(100.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(700.0));
  });

  testWidgets('Row with default main axis parameters', (WidgetTester tester) async {
    final Key rowKey = new Key('row');
    final Key child0Key = new Key('child0');
    final Key child1Key = new Key('child1');
    final Key child2Key = new Key('child2');

    // Default is MainAxisSize.max so the Row should be as wide as the test: 800.
    // Default is MainAxisAlignment.start so children so the children's
    // left edges should be at 0, 100, 200
    await tester.pumpWidget(new Center(
      child: new Row(
        key: rowKey,
        children: <Widget>[
          new Container(key: child0Key, width: 100.0, height: 100.0),
          new Container(key: child1Key, width: 100.0, height: 100.0),
          new Container(key: child2Key, width: 100.0, height: 100.0),
        ]
      )
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(rowKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(100.0));

    renderBox = tester.renderObject(find.byKey(child0Key));
    expect(renderBox.size.width, equals(100.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(0.0));

    renderBox = tester.renderObject(find.byKey(child1Key));
    expect(renderBox.size.width, equals(100.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(100.0));

    renderBox = tester.renderObject(find.byKey(child2Key));
    expect(renderBox.size.width, equals(100.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(200.0));
  });

  testWidgets('Row with MainAxisAlignment.center', (WidgetTester tester) async {
    final Key rowKey = new Key('row');
    final Key child0Key = new Key('child0');
    final Key child1Key = new Key('child1');

    // Default is MainAxisSize.max so the Row should be as wide as the test: 800.
    // The 100x100 children's left edges should be at 300, 400
    await tester.pumpWidget(new Center(
      child: new Row(
        key: rowKey,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Container(key: child0Key, width: 100.0, height: 100.0),
          new Container(key: child1Key, width: 100.0, height: 100.0),
        ]
      )
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(rowKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(100.0));

    renderBox = tester.renderObject(find.byKey(child0Key));
    expect(renderBox.size.width, equals(100.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(300.0));

    renderBox = tester.renderObject(find.byKey(child1Key));
    expect(renderBox.size.width, equals(100.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(400.0));
  });

  testWidgets('Row with MainAxisAlignment.end', (WidgetTester tester) async {
    final Key rowKey = new Key('row');
    final Key child0Key = new Key('child0');
    final Key child1Key = new Key('child1');
    final Key child2Key = new Key('child2');

    // Default is MainAxisSize.max so the Row should be as wide as the test: 800.
    // The 100x100 children's left edges should be at 500, 600, 700.
    await tester.pumpWidget(new Center(
      child: new Row(
        key: rowKey,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          new Container(key: child0Key, width: 100.0, height: 100.0),
          new Container(key: child1Key, width: 100.0, height: 100.0),
          new Container(key: child2Key, width: 100.0, height: 100.0),
        ]
      )
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(rowKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(100.0));

    renderBox = tester.renderObject(find.byKey(child0Key));
    expect(renderBox.size.width, equals(100.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(500.0));

    renderBox = tester.renderObject(find.byKey(child1Key));
    expect(renderBox.size.width, equals(100.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(600.0));

    renderBox = tester.renderObject(find.byKey(child2Key));
    expect(renderBox.size.width, equals(100.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(700.0));
  });

  testWidgets('Row with MainAxisAlignment.spaceBetween', (WidgetTester tester) async {
    final Key rowKey = new Key('row');
    final Key child0Key = new Key('child0');
    final Key child1Key = new Key('child1');
    final Key child2Key = new Key('child2');

    // Default is MainAxisSize.max so the Row should be as wide as the test: 800.
    // The 100x100 children's left edges should be at 0, 350, 700
    await tester.pumpWidget(new Center(
      child: new Row(
        key: rowKey,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          new Container(key: child0Key, width: 100.0, height: 100.0),
          new Container(key: child1Key, width: 100.0, height: 100.0),
          new Container(key: child2Key, width: 100.0, height: 100.0),
        ]
      )
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(rowKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(100.0));

    renderBox = tester.renderObject(find.byKey(child0Key));
    expect(renderBox.size.width, equals(100.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(0.0));

    renderBox = tester.renderObject(find.byKey(child1Key));
    expect(renderBox.size.width, equals(100.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(350.0));

    renderBox = tester.renderObject(find.byKey(child2Key));
    expect(renderBox.size.width, equals(100.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(700.0));
  });

  testWidgets('Row with MainAxisAlignment.spaceAround', (WidgetTester tester) async {
    final Key rowKey = new Key('row');
    final Key child0Key = new Key('child0');
    final Key child1Key = new Key('child1');
    final Key child2Key = new Key('child2');
    final Key child3Key = new Key('child3');

    // Default is MainAxisSize.max so the Row should be as wide as the test: 800.
    // The 100x100 children's left edges should be at 50, 250, 450, 650
    await tester.pumpWidget(new Center(
      child: new Row(
        key: rowKey,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          new Container(key: child0Key, width: 100.0, height: 100.0),
          new Container(key: child1Key, width: 100.0, height: 100.0),
          new Container(key: child2Key, width: 100.0, height: 100.0),
          new Container(key: child3Key, width: 100.0, height: 100.0),
        ]
      )
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(rowKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(100.0));

    renderBox = tester.renderObject(find.byKey(child0Key));
    expect(renderBox.size.width, equals(100.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(50.0));

    renderBox = tester.renderObject(find.byKey(child1Key));
    expect(renderBox.size.width, equals(100.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(250.0));

    renderBox = tester.renderObject(find.byKey(child2Key));
    expect(renderBox.size.width, equals(100.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(450.0));

    renderBox = tester.renderObject(find.byKey(child3Key));
    expect(renderBox.size.width, equals(100.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(650.0));
  });

  testWidgets('Row with MainAxisAlignment.spaceEvenly', (WidgetTester tester) async {
    final Key rowKey = new Key('row');
    final Key child0Key = new Key('child0');
    final Key child1Key = new Key('child1');
    final Key child2Key = new Key('child2');

    // Default is MainAxisSize.max so the Row should be as wide as the test: 800.
    // The 200x100 children's left edges should be at 50, 300, 550
    await tester.pumpWidget(new Center(
      child: new Row(
        key: rowKey,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          new Container(key: child0Key, width: 200.0, height: 100.0),
          new Container(key: child1Key, width: 200.0, height: 100.0),
          new Container(key: child2Key, width: 200.0, height: 100.0),
        ]
      )
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(rowKey));
    expect(renderBox.size.width, equals(800.0));
    expect(renderBox.size.height, equals(100.0));

    renderBox = tester.renderObject(find.byKey(child0Key));
    expect(renderBox.size.width, equals(200.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(50.0));

    renderBox = tester.renderObject(find.byKey(child1Key));
    expect(renderBox.size.width, equals(200.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(300.0));

    renderBox = tester.renderObject(find.byKey(child2Key));
    expect(renderBox.size.width, equals(200.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(550.0));
  });

  testWidgets('Row and MainAxisSize.min', (WidgetTester tester) async {
    final Key rowKey = new Key('rowKey');
    final Key child0Key = new Key('child0');
    final Key child1Key = new Key('child1');

    // Row with MainAxisSize.min without flexible children shrink wraps.
    // Row's width should be 250, children should be at 0, 100.
    await tester.pumpWidget(new Center(
      child: new Row(
        key: rowKey,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new Container(key: child0Key, width: 100.0, height: 100.0),
          new Container(key: child1Key, width: 150.0, height: 100.0)
        ]
      )
    ));

    RenderBox renderBox;
    BoxParentData boxParentData;

    renderBox = tester.renderObject(find.byKey(rowKey));
    expect(renderBox.size.width, equals(250.0));
    expect(renderBox.size.height, equals(100.0));

    renderBox = tester.renderObject(find.byKey(child0Key));
    expect(renderBox.size.width, equals(100.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(0.0));

    renderBox = tester.renderObject(find.byKey(child1Key));
    expect(renderBox.size.width, equals(150.0));
    expect(renderBox.size.height, equals(100.0));
    boxParentData = renderBox.parentData;
    expect(boxParentData.offset.dx, equals(100.0));
  });

  testWidgets('Row MainAxisSize.min layout at zero size', (WidgetTester tester) async {
    final Key childKey = new Key('childKey');

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

    RenderBox renderBox = tester.renderObject(find.byKey(childKey));
    expect(renderBox.size.width, equals(100.0));
    expect(renderBox.size.height, equals(0.0));
  });
}

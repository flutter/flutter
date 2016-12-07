// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'test_widgets.dart';

void main() {
  testWidgets('LazyBlockViewport mount/dismount smoke test', (WidgetTester tester) async {
    List<int> callbackTracker = <int>[];

    // the root view is 800x600 in the test environment
    // so if our widget is 100 pixels tall, it should fit exactly 6 times.

    Widget builder() {
      return new FlipWidget(
        left: new LazyBlockViewport(
          delegate: new LazyBlockBuilder(builder: (BuildContext context, int i) {
            callbackTracker.add(i);
            return new Container(
              key: new ValueKey<int>(i),
              height: 100.0,
              child: new Text("$i")
            );
          }),
          startOffset: 0.0
        ),
        right: new Text('Not Today')
      );
    }

    await tester.pumpWidget(builder());

    FlipWidgetState testWidget = tester.state(find.byType(FlipWidget));

    expect(callbackTracker, equals(<int>[0, 1, 2, 3, 4, 5]));

    callbackTracker.clear();
    testWidget.flip();
    await tester.pump();

    expect(callbackTracker, equals(<int>[]));

    callbackTracker.clear();
    testWidget.flip();
    await tester.pump();

    expect(callbackTracker, equals(<int>[0, 1, 2, 3, 4, 5]));
  });

  testWidgets('LazyBlockViewport vertical', (WidgetTester tester) async {
    List<int> callbackTracker = <int>[];

    // the root view is 800x600 in the test environment
    // so if our widget is 200 pixels tall, it should fit exactly 3 times.
    // but if we are offset by 300 pixels, there will be 4, numbered 1-4.

    double offset = 300.0;

    IndexedWidgetBuilder itemBuilder = (BuildContext context, int i) {
      callbackTracker.add(i);
      return new Container(
        key: new ValueKey<int>(i),
        width: 500.0, // this should be ignored
        height: 200.0,
        child: new Text("$i")
      );
    };

    Widget builder() {
      return new FlipWidget(
        left: new LazyBlockViewport(
          delegate: new LazyBlockBuilder(builder: itemBuilder),
          startOffset: offset
        ),
        right: new Text('Not Today')
      );
    }

    await tester.pumpWidget(builder());

    // 0 is built to find its height
    expect(callbackTracker, equals(<int>[0, 1, 2, 3, 4]));
    callbackTracker.clear();

    offset = 400.0; // now only 3 should fit, numbered 2-4.

    await tester.pumpWidget(builder());

    // We build all the children to find their new size.
    expect(callbackTracker, equals(<int>[0, 1, 2, 3, 4]));
    callbackTracker.clear();

    await tester.pumpWidget(builder());

    // 0 isn't built because they're not visible.
    expect(callbackTracker, equals(<int>[1, 2, 3, 4]));
    callbackTracker.clear();
  });

  testWidgets('LazyBlockViewport horizontal', (WidgetTester tester) async {
    List<int> callbackTracker = <int>[];

    // the root view is 800x600 in the test environment
    // so if our widget is 200 pixels wide, it should fit exactly 4 times.
    // but if we are offset by 300 pixels, there will be 5, numbered 1-5.

    double offset = 300.0;

    IndexedWidgetBuilder itemBuilder = (BuildContext context, int i) {
      callbackTracker.add(i);
      return new Container(
        key: new ValueKey<int>(i),
        height: 500.0, // this should be ignored
        width: 200.0,
        child: new Text("$i")
      );
    };

    Widget builder() {
      return new FlipWidget(
        left: new LazyBlockViewport(
          delegate: new LazyBlockBuilder(builder: itemBuilder),
          startOffset: offset,
          mainAxis: Axis.horizontal
        ),
        right: new Text('Not Today')
      );
    }

    await tester.pumpWidget(builder());

    // 0 is built to find its width
    expect(callbackTracker, equals(<int>[0, 1, 2, 3, 4, 5]));

    callbackTracker.clear();

    offset = 400.0; // now only 4 should fit, numbered 2-5.

    await tester.pumpWidget(builder());

    // We build all the children to find their new size.
    expect(callbackTracker, equals(<int>[0, 1, 2, 3, 4, 5]));
    callbackTracker.clear();

    await tester.pumpWidget(builder());

    // 0 isn't built because they're not visible.
    expect(callbackTracker, equals(<int>[1, 2, 3, 4, 5]));
    callbackTracker.clear();
  });

  testWidgets('LazyBlockViewport reinvoke builders', (WidgetTester tester) async {
    List<int> callbackTracker = <int>[];
    List<String> text = <String>[];

    IndexedWidgetBuilder itemBuilder = (BuildContext context, int i) {
      callbackTracker.add(i);
      return new Container(
        key: new ValueKey<int>(i),
        width: 500.0, // this should be ignored
        height: 220.0,
        child: new Text("$i")
      );
    };

    void collectText(Widget widget) {
      if (widget is Text)
        text.add(widget.data);
    }

    Widget builder() {
      return new LazyBlockViewport(
        delegate: new LazyBlockBuilder(builder: itemBuilder),
        startOffset: 0.0
      );
    }

    await tester.pumpWidget(builder());

    expect(callbackTracker, equals(<int>[0, 1, 2]));
    callbackTracker.clear();
    tester.allWidgets.forEach(collectText);
    expect(text, equals(<String>['0', '1', '2']));
    text.clear();

    await tester.pumpWidget(builder());

    expect(callbackTracker, equals(<int>[0, 1, 2]));
    callbackTracker.clear();
    tester.allWidgets.forEach(collectText);
    expect(text, equals(<String>['0', '1', '2']));
    text.clear();
  });

  testWidgets('LazyBlockViewport reinvoke builders', (WidgetTester tester) async {
    StateSetter setState;
    ThemeData themeData = new ThemeData.light();

    IndexedWidgetBuilder itemBuilder = (BuildContext context, int i) {
      return new Container(
        key: new ValueKey<int>(i),
        width: 500.0, // this should be ignored
        height: 220.0,
        decoration: new BoxDecoration(
          backgroundColor: Theme.of(context).primaryColor
        ),
        child: new Text("$i")
      );
    };

    Widget viewport = new LazyBlockViewport(
      delegate: new LazyBlockBuilder(builder: itemBuilder)
    );

    await tester.pumpWidget(
      new StatefulBuilder(
        builder: (BuildContext context, StateSetter setter) {
          setState = setter;
          return new Theme(data: themeData, child: viewport);
        }
      )
    );

    DecoratedBox widget = tester.firstWidget(find.byType(DecoratedBox));
    BoxDecoration decoraton = widget.decoration;
    expect(decoraton.backgroundColor, equals(Colors.blue[500]));

    setState(() {
      themeData = new ThemeData(primarySwatch: Colors.green);
    });

    await tester.pump();

    widget = tester.firstWidget(find.byType(DecoratedBox));
    decoraton = widget.decoration;
    expect(decoraton.backgroundColor, equals(Colors.green[500]));
  });

  testWidgets('LazyBlockViewport padding', (WidgetTester tester) async {
    IndexedWidgetBuilder itemBuilder = (BuildContext context, int i) {
      return new Container(
        key: new ValueKey<int>(i),
        width: 500.0, // this should be ignored
        height: 220.0,
        decoration: new BoxDecoration(
          backgroundColor: Colors.green[500]
        ),
        child: new Text("$i")
      );
    };

    await tester.pumpWidget(
      new LazyBlockViewport(
        padding: const EdgeInsets.fromLTRB(7.0, 3.0, 5.0, 11.0),
        delegate: new LazyBlockBuilder(builder: itemBuilder)
      )
    );

    RenderBox firstBox = tester.renderObject(find.text('0'));
    Point upperLeft = firstBox.localToGlobal(Point.origin);
    expect(upperLeft, equals(const Point(7.0, 3.0)));
    expect(firstBox.size.width, equals(800.0 - 12.0));
  });

  testWidgets('Underflow extents', (WidgetTester tester) async {
    int lastFirstIndex;
    int lastLastIndex;
    double lastFirstStartOffset;
    double lastLastEndOffset;
    double lastMinScrollOffset;
    double lastContainerExtent;
    void handleExtendsChanged(int firstIndex, int lastIndex, double firstStartOffset, double lastEndOffset, double minScrollOffset, double containerExtent) {
      lastFirstIndex = firstIndex;
      lastLastIndex = lastIndex;
      lastFirstStartOffset = firstStartOffset;
      lastLastEndOffset = lastEndOffset;
      lastMinScrollOffset = minScrollOffset;
      lastContainerExtent = containerExtent;
    }

    await tester.pumpWidget(new LazyBlockViewport(
      onExtentsChanged: handleExtendsChanged,
      delegate: new LazyBlockChildren(
        children: <Widget>[
          new Container(height: 100.0),
          new Container(height: 100.0),
          new Container(height: 100.0),
        ]
      )
    ));

    expect(lastFirstIndex, 0);
    expect(lastLastIndex, 2);
    expect(lastFirstStartOffset, 0.0);
    expect(lastLastEndOffset, 300.0);
    expect(lastContainerExtent, 600.0);
    expect(lastMinScrollOffset, 0.0);
  });
}

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'test_widgets.dart';

void main() {
  testWidgets('ListView mount/dismount smoke test', (WidgetTester tester) async {
    final List<int> callbackTracker = <int>[];

    // the root view is 800x600 in the test environment
    // so if our widget is 100 pixels tall, it should fit exactly 6 times.

    Widget builder() {
      return new FlipWidget(
        left: new ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            callbackTracker.add(index);
            return new Container(
              key: new ValueKey<int>(index),
              height: 100.0,
              child: new Text("$index"),
            );
          },
        ),
        right: const Text('Not Today'),
      );
    }

    await tester.pumpWidget(builder());

    final FlipWidgetState testWidget = tester.state(find.byType(FlipWidget));

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

  testWidgets('ListView vertical', (WidgetTester tester) async {
    final List<int> callbackTracker = <int>[];

    // the root view is 800x600 in the test environment
    // so if our widget is 200 pixels tall, it should fit exactly 3 times.
    // but if we are offset by 300 pixels, there will be 4, numbered 1-4.

    final IndexedWidgetBuilder itemBuilder = (BuildContext context, int index) {
      callbackTracker.add(index);
      return new Container(
        key: new ValueKey<int>(index),
        width: 500.0, // this should be ignored
        height: 200.0,
        child: new Text('$index'),
      );
    };

    Widget builder() {
      return new FlipWidget(
        left: new ListView.builder(
          controller: new ScrollController(initialScrollOffset: 300.0),
          itemBuilder: itemBuilder,
        ),
        right: const Text('Not Today'),
      );
    }

    await tester.pumpWidget(builder());

    // 0 is built to find its height
    expect(callbackTracker, equals(<int>[0, 1, 2, 3, 4]));
    callbackTracker.clear();

    final ScrollableState scrollable = tester.state(find.byType(Scrollable));
    scrollable.position.jumpTo(400.0); // now only 3 should fit, numbered 2-4.

    await tester.pumpWidget(builder());

    // We build the visible children to find their new size.
    expect(callbackTracker, equals(<int>[1, 2, 3, 4]));
    callbackTracker.clear();

    await tester.pumpWidget(builder());

    // 0 isn't built because they're not visible.
    expect(callbackTracker, equals(<int>[1, 2, 3, 4]));
    callbackTracker.clear();
  });

  testWidgets('ListView horizontal', (WidgetTester tester) async {
    final List<int> callbackTracker = <int>[];

    // the root view is 800x600 in the test environment
    // so if our widget is 200 pixels wide, it should fit exactly 4 times.
    // but if we are offset by 300 pixels, there will be 5, numbered 1-5.

    final IndexedWidgetBuilder itemBuilder = (BuildContext context, int index) {
      callbackTracker.add(index);
      return new Container(
        key: new ValueKey<int>(index),
        height: 500.0, // this should be ignored
        width: 200.0,
        child: new Text('$index'),
      );
    };

    Widget builder() {
      return new FlipWidget(
        left: new ListView.builder(
          scrollDirection: Axis.horizontal,
          controller: new ScrollController(initialScrollOffset: 300.0),
          itemBuilder: itemBuilder,
        ),
        right: const Text('Not Today'),
      );
    }

    await tester.pumpWidget(builder());

    // 0 is built to find its width
    expect(callbackTracker, equals(<int>[0, 1, 2, 3, 4, 5]));

    callbackTracker.clear();

    final ScrollableState scrollable = tester.state(find.byType(Scrollable));
    scrollable.position.jumpTo(400.0); // now only 4 should fit, numbered 2-5.

    await tester.pumpWidget(builder());

    // We build the visible children to find their new size.
    expect(callbackTracker, equals(<int>[1, 2, 3, 4, 5]));
    callbackTracker.clear();

    await tester.pumpWidget(builder());

    // 0 isn't built because they're not visible.
    expect(callbackTracker, equals(<int>[1, 2, 3, 4, 5]));
    callbackTracker.clear();
  });

  testWidgets('ListView reinvoke builders', (WidgetTester tester) async {
    final List<int> callbackTracker = <int>[];
    final List<String> text = <String>[];

    final IndexedWidgetBuilder itemBuilder = (BuildContext context, int index) {
      callbackTracker.add(index);
      return new Container(
        key: new ValueKey<int>(index),
        width: 500.0, // this should be ignored
        height: 220.0,
        child: new Text('$index')
      );
    };

    void collectText(Widget widget) {
      if (widget is Text)
        text.add(widget.data);
    }

    Widget builder() {
      return new ListView.builder(
        itemBuilder: itemBuilder,
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

  testWidgets('ListView reinvoke builders', (WidgetTester tester) async {
    StateSetter setState;
    ThemeData themeData = new ThemeData.light();

    final IndexedWidgetBuilder itemBuilder = (BuildContext context, int index) {
      return new Container(
        key: new ValueKey<int>(index),
        width: 500.0, // this should be ignored
        height: 220.0,
        color: Theme.of(context).primaryColor,
        child: new Text('$index'),
      );
    };

    final Widget viewport = new ListView.builder(
      itemBuilder: itemBuilder,
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
    expect(decoraton.color, equals(Colors.blue[500]));

    setState(() {
      themeData = new ThemeData(primarySwatch: Colors.green);
    });

    await tester.pump();

    widget = tester.firstWidget(find.byType(DecoratedBox));
    decoraton = widget.decoration;
    expect(decoraton.color, equals(Colors.green[500]));
  });

  testWidgets('ListView padding', (WidgetTester tester) async {
    final IndexedWidgetBuilder itemBuilder = (BuildContext context, int index) {
      return new Container(
        key: new ValueKey<int>(index),
        width: 500.0, // this should be ignored
        height: 220.0,
        color: Colors.green[500],
        child: new Text('$index'),
      );
    };

    await tester.pumpWidget(
      new ListView.builder(
        padding: const EdgeInsets.fromLTRB(7.0, 3.0, 5.0, 11.0),
        itemBuilder: itemBuilder,
      ),
    );

    final RenderBox firstBox = tester.renderObject(find.text('0'));
    final Offset upperLeft = firstBox.localToGlobal(Offset.zero);
    expect(upperLeft, equals(const Offset(7.0, 3.0)));
    expect(firstBox.size.width, equals(800.0 - 12.0));
  });

  testWidgets('ListView underflow extents', (WidgetTester tester) async {
    await tester.pumpWidget(new ListView(
      children: <Widget>[
        new Container(height: 100.0),
        new Container(height: 100.0),
        new Container(height: 100.0),
      ],
    ));

    final RenderSliverList list = tester.renderObject(find.byType(SliverList));

    expect(list.indexOf(list.firstChild), equals(0));
    expect(list.indexOf(list.lastChild), equals(2));
    expect(list.childScrollOffset(list.firstChild), equals(0.0));
    expect(list.geometry.scrollExtent, equals(300.0));

    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;

    expect(position.viewportDimension, equals(600.0));
    expect(position.minScrollExtent, equals(0.0));
  });
}

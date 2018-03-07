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
      return new Directionality(
        textDirection: TextDirection.ltr,
        child: new FlipWidget(
          left: new ListView.builder(
            itemBuilder: (BuildContext context, int index) {
              callbackTracker.add(index);
              return new Container(
                key: new ValueKey<int>(index),
                height: 100.0,
                child: new Text('$index'),
              );
            },
          ),
          right: const Text('Not Today'),
        ),
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
        child: new Text('$index', textDirection: TextDirection.ltr),
      );
    };

    Widget builder() {
      return new Directionality(
        textDirection: TextDirection.ltr,
        child: new FlipWidget(
          left: new ListView.builder(
            controller: new ScrollController(initialScrollOffset: 300.0),
            itemBuilder: itemBuilder,
          ),
          right: const Text('Not Today'),
        ),
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
        child: new Text('$index', textDirection: TextDirection.ltr),
      );
    };

    Widget builder() {
      return new Directionality(
        textDirection: TextDirection.ltr,
        child: new FlipWidget(
          left: new ListView.builder(
            scrollDirection: Axis.horizontal,
            controller: new ScrollController(initialScrollOffset: 300.0),
            itemBuilder: itemBuilder,
          ),
          right: const Text('Not Today'),
        ),
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
        child: new Text('$index', textDirection: TextDirection.ltr)
      );
    };

    void collectText(Widget widget) {
      if (widget is Text)
        text.add(widget.data);
    }

    Widget builder() {
      return new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView.builder(
          itemBuilder: itemBuilder,
        ),
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
        child: new Text('$index', textDirection: TextDirection.ltr),
      );
    };

    final Widget viewport = new ListView.builder(
      itemBuilder: itemBuilder,
    );

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new StatefulBuilder(
          builder: (BuildContext context, StateSetter setter) {
            setState = setter;
            return new Theme(data: themeData, child: viewport);
          },
        ),
      ),
    );

    DecoratedBox widget = tester.firstWidget(find.byType(DecoratedBox));
    BoxDecoration decoration = widget.decoration;
    expect(decoration.color, equals(Colors.blue));

    setState(() {
      themeData = new ThemeData(primarySwatch: Colors.green);
    });

    await tester.pump();

    widget = tester.firstWidget(find.byType(DecoratedBox));
    decoration = widget.decoration;
    expect(decoration.color, equals(Colors.green));
  });

  testWidgets('ListView padding', (WidgetTester tester) async {
    final IndexedWidgetBuilder itemBuilder = (BuildContext context, int index) {
      return new Container(
        key: new ValueKey<int>(index),
        width: 500.0, // this should be ignored
        height: 220.0,
        color: Colors.green[500],
        child: new Text('$index', textDirection: TextDirection.ltr),
      );
    };

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView.builder(
          padding: const EdgeInsets.fromLTRB(7.0, 3.0, 5.0, 11.0),
          itemBuilder: itemBuilder,
        ),
      ),
    );

    final RenderBox firstBox = tester.renderObject(find.text('0'));
    final Offset upperLeft = firstBox.localToGlobal(Offset.zero);
    expect(upperLeft, equals(const Offset(7.0, 3.0)));
    expect(firstBox.size.width, equals(800.0 - 12.0));
  });

  testWidgets('ListView underflow extents', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          addAutomaticKeepAlives: false,
          children: <Widget>[
            new Container(height: 100.0),
            new Container(height: 100.0),
            new Container(height: 100.0),
          ],
        ),
      ),
    );

    final RenderSliverList list = tester.renderObject(find.byType(SliverList));

    expect(list.indexOf(list.firstChild), equals(0));
    expect(list.indexOf(list.lastChild), equals(2));
    expect(list.childScrollOffset(list.firstChild), equals(0.0));
    expect(list.geometry.scrollExtent, equals(300.0));

    expect(list, hasAGoodToStringDeep);
    expect(
      list.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        'RenderSliverList#00000 relayoutBoundary=up1\n'
        ' │ parentData: paintOffset=Offset(0.0, 0.0) (can use size)\n'
        ' │ constraints: SliverConstraints(AxisDirection.down,\n'
        ' │   GrowthDirection.forward, ScrollDirection.idle, scrollOffset:\n'
        ' │   0.0, remainingPaintExtent: 600.0, crossAxisExtent: 800.0,\n'
        ' │   crossAxisDirection: AxisDirection.right,\n'
        ' │   viewportMainAxisExtent: 600.0)\n'
        ' │ geometry: SliverGeometry(scrollExtent: 300.0, paintExtent: 300.0,\n'
        ' │   maxPaintExtent: 300.0)\n'
        ' │ currently live children: 0 to 2\n'
        ' │\n'
        ' ├─child with index 0: RenderRepaintBoundary#00000 relayoutBoundary=up2\n'
        ' │ │ parentData: index=0; layoutOffset=0.0 (can use size)\n'
        ' │ │ constraints: BoxConstraints(w=800.0, 0.0<=h<=Infinity)\n'
        ' │ │ layer: OffsetLayer#00000\n'
        ' │ │ size: Size(800.0, 100.0)\n'
        ' │ │ metrics: 0.0% useful (1 bad vs 0 good)\n'
        ' │ │ diagnosis: insufficient data to draw conclusion (less than five\n'
        ' │ │   repaints)\n'
        ' │ │\n'
        ' │ └─child: RenderConstrainedBox#00000 relayoutBoundary=up3\n'
        ' │   │ parentData: <none> (can use size)\n'
        ' │   │ constraints: BoxConstraints(w=800.0, 0.0<=h<=Infinity)\n'
        ' │   │ size: Size(800.0, 100.0)\n'
        ' │   │ additionalConstraints: BoxConstraints(0.0<=w<=Infinity, h=100.0)\n'
        ' │   │\n'
        ' │   └─child: RenderLimitedBox#00000\n'
        ' │     │ parentData: <none> (can use size)\n'
        ' │     │ constraints: BoxConstraints(w=800.0, h=100.0)\n'
        ' │     │ size: Size(800.0, 100.0)\n'
        ' │     │ maxWidth: 0.0\n'
        ' │     │ maxHeight: 0.0\n'
        ' │     │\n'
        ' │     └─child: RenderConstrainedBox#00000\n'
        ' │         parentData: <none> (can use size)\n'
        ' │         constraints: BoxConstraints(w=800.0, h=100.0)\n'
        ' │         size: Size(800.0, 100.0)\n'
        ' │         additionalConstraints: BoxConstraints(biggest)\n'
        ' │\n'
        ' ├─child with index 1: RenderRepaintBoundary#00000 relayoutBoundary=up2\n'
        ' │ │ parentData: index=1; layoutOffset=100.0 (can use size)\n'
        ' │ │ constraints: BoxConstraints(w=800.0, 0.0<=h<=Infinity)\n'
        ' │ │ layer: OffsetLayer#00000\n'
        ' │ │ size: Size(800.0, 100.0)\n'
        ' │ │ metrics: 0.0% useful (1 bad vs 0 good)\n'
        ' │ │ diagnosis: insufficient data to draw conclusion (less than five\n'
        ' │ │   repaints)\n'
        ' │ │\n'
        ' │ └─child: RenderConstrainedBox#00000 relayoutBoundary=up3\n'
        ' │   │ parentData: <none> (can use size)\n'
        ' │   │ constraints: BoxConstraints(w=800.0, 0.0<=h<=Infinity)\n'
        ' │   │ size: Size(800.0, 100.0)\n'
        ' │   │ additionalConstraints: BoxConstraints(0.0<=w<=Infinity, h=100.0)\n'
        ' │   │\n'
        ' │   └─child: RenderLimitedBox#00000\n'
        ' │     │ parentData: <none> (can use size)\n'
        ' │     │ constraints: BoxConstraints(w=800.0, h=100.0)\n'
        ' │     │ size: Size(800.0, 100.0)\n'
        ' │     │ maxWidth: 0.0\n'
        ' │     │ maxHeight: 0.0\n'
        ' │     │\n'
        ' │     └─child: RenderConstrainedBox#00000\n'
        ' │         parentData: <none> (can use size)\n'
        ' │         constraints: BoxConstraints(w=800.0, h=100.0)\n'
        ' │         size: Size(800.0, 100.0)\n'
        ' │         additionalConstraints: BoxConstraints(biggest)\n'
        ' │\n'
        ' └─child with index 2: RenderRepaintBoundary#00000 relayoutBoundary=up2\n'
        '   │ parentData: index=2; layoutOffset=200.0 (can use size)\n'
        '   │ constraints: BoxConstraints(w=800.0, 0.0<=h<=Infinity)\n'
        '   │ layer: OffsetLayer#00000\n'
        '   │ size: Size(800.0, 100.0)\n'
        '   │ metrics: 0.0% useful (1 bad vs 0 good)\n'
        '   │ diagnosis: insufficient data to draw conclusion (less than five\n'
        '   │   repaints)\n'
        '   │\n'
        '   └─child: RenderConstrainedBox#00000 relayoutBoundary=up3\n'
        '     │ parentData: <none> (can use size)\n'
        '     │ constraints: BoxConstraints(w=800.0, 0.0<=h<=Infinity)\n'
        '     │ size: Size(800.0, 100.0)\n'
        '     │ additionalConstraints: BoxConstraints(0.0<=w<=Infinity, h=100.0)\n'
        '     │\n'
        '     └─child: RenderLimitedBox#00000\n'
        '       │ parentData: <none> (can use size)\n'
        '       │ constraints: BoxConstraints(w=800.0, h=100.0)\n'
        '       │ size: Size(800.0, 100.0)\n'
        '       │ maxWidth: 0.0\n'
        '       │ maxHeight: 0.0\n'
        '       │\n'
        '       └─child: RenderConstrainedBox#00000\n'
        '           parentData: <none> (can use size)\n'
        '           constraints: BoxConstraints(w=800.0, h=100.0)\n'
        '           size: Size(800.0, 100.0)\n'
        '           additionalConstraints: BoxConstraints(biggest)\n'
      ),
    );

    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;

    expect(position.viewportDimension, equals(600.0));
    expect(position.minScrollExtent, equals(0.0));
  });
}

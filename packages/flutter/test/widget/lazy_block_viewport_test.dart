// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

import 'test_widgets.dart';

void main() {
  test('LazyBlockViewport mount/dismount smoke test', () {
    testWidgets((WidgetTester tester) {
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

      tester.pumpWidget(builder());

      StatefulElement element = tester.findElement((Element element) => element.widget is FlipWidget);
      FlipWidgetState testWidget = element.state;

      expect(callbackTracker, equals([0, 1, 2, 3, 4, 5]));

      callbackTracker.clear();
      testWidget.flip();
      tester.pump();

      expect(callbackTracker, equals([]));

      callbackTracker.clear();
      testWidget.flip();
      tester.pump();

      expect(callbackTracker, equals([0, 1, 2, 3, 4, 5]));
    });
  });

  test('LazyBlockViewport vertical', () {
    testWidgets((WidgetTester tester) {
      List<int> callbackTracker = <int>[];

      // the root view is 800x600 in the test environment
      // so if our widget is 200 pixels tall, it should fit exactly 3 times.
      // but if we are offset by 300 pixels, there will be 4, numbered 1-4.

      double offset = 300.0;

      IndexedBuilder itemBuilder = (BuildContext context, int i) {
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

      tester.pumpWidget(builder());

      // 0 is built to find its height
      expect(callbackTracker, equals([0, 1, 2, 3, 4]));
      callbackTracker.clear();

      offset = 400.0; // now only 3 should fit, numbered 2-4.

      tester.pumpWidget(builder());

      // We build all the children to find their new size.
      expect(callbackTracker, equals([0, 1, 2, 3, 4]));
      callbackTracker.clear();

      tester.pumpWidget(builder());

      // 0 isn't built because they're not visible.
      expect(callbackTracker, equals([1, 2, 3, 4]));
      callbackTracker.clear();
    });
  });

  test('LazyBlockViewport horizontal', () {
    testWidgets((WidgetTester tester) {
      List<int> callbackTracker = <int>[];

      // the root view is 800x600 in the test environment
      // so if our widget is 200 pixels wide, it should fit exactly 4 times.
      // but if we are offset by 300 pixels, there will be 5, numbered 1-5.

      double offset = 300.0;

      IndexedBuilder itemBuilder = (BuildContext context, int i) {
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

      tester.pumpWidget(builder());

      // 0 is built to find its width
      expect(callbackTracker, equals([0, 1, 2, 3, 4, 5]));

      callbackTracker.clear();

      offset = 400.0; // now only 4 should fit, numbered 2-5.

      tester.pumpWidget(builder());

      // We build all the children to find their new size.
      expect(callbackTracker, equals([0, 1, 2, 3, 4, 5]));
      callbackTracker.clear();

      tester.pumpWidget(builder());

      // 0 isn't built because they're not visible.
      expect(callbackTracker, equals([1, 2, 3, 4, 5]));
      callbackTracker.clear();
    });
  });

  test('LazyBlockViewport reinvoke builders', () {
    testWidgets((WidgetTester tester) {
      List<int> callbackTracker = <int>[];
      List<String> text = <String>[];

      IndexedBuilder itemBuilder = (BuildContext context, int i) {
        callbackTracker.add(i);
        return new Container(
          key: new ValueKey<int>(i),
          width: 500.0, // this should be ignored
          height: 220.0,
          child: new Text("$i")
        );
      };

      ElementVisitor collectText = (Element element) {
        final Widget widget = element.widget;
        if (widget is Text)
          text.add(widget.data);
      };

      Widget builder() {
        return new LazyBlockViewport(
          delegate: new LazyBlockBuilder(builder: itemBuilder),
          startOffset: 0.0
        );
      }

      tester.pumpWidget(builder());

      expect(callbackTracker, equals([0, 1, 2]));
      callbackTracker.clear();
      tester.walkElements(collectText);
      expect(text, equals(['0', '1', '2']));
      text.clear();

      tester.pumpWidget(builder());

      expect(callbackTracker, equals([0, 1, 2]));
      callbackTracker.clear();
      tester.walkElements(collectText);
      expect(text, equals(['0', '1', '2']));
      text.clear();
    });
  });

  test('LazyBlockViewport reinvoke builders', () {
    testWidgets((WidgetTester tester) {
      StateSetter setState;
      ThemeData themeData = new ThemeData.light();

      IndexedBuilder itemBuilder = (BuildContext context, int i) {
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

      tester.pumpWidget(
        new StatefulBuilder(
          builder: (BuildContext context, StateSetter setter) {
            setState = setter;
            return new Theme(data: themeData, child: viewport);
          }
        )
      );

      DecoratedBox widget = tester.findWidgetOfType(DecoratedBox);
      BoxDecoration decoraton = widget.decoration;
      expect(decoraton.backgroundColor, equals(Colors.blue[500]));

      setState(() {
        themeData = new ThemeData(primarySwatch: Colors.green);
      });

      tester.pump();

      widget = tester.findWidgetOfType(DecoratedBox);
      decoraton = widget.decoration;
      expect(decoraton.backgroundColor, equals(Colors.green[500]));
    });
  });
}

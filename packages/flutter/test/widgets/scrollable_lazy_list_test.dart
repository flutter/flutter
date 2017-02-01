// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'test_widgets.dart';

void main() {
  testWidgets('HomogeneousViewport mount/dismount smoke test', (WidgetTester tester) async {
    List<int> callbackTracker = <int>[];

    // the root view is 800x600 in the test environment
    // so if our widget is 100 pixels tall, it should fit exactly 6 times.

    Widget builder() {
      return new FlipWidget(
        left: new ScrollableLazyList(
          itemBuilder: (BuildContext context, int start, int count) {
            List<Widget> result = <Widget>[];
            for (int index = start; index < start + count; index += 1) {
              callbackTracker.add(index);
              result.add(new Container(
                key: new ValueKey<int>(index),
                height: 100.0,
                child: new Text("$index")
              ));
            }
            return result;
          },
          itemExtent: 100.0
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

  testWidgets('HomogeneousViewport vertical', (WidgetTester tester) async {
    List<int> callbackTracker = <int>[];

    // the root view is 800x600 in the test environment
    // so if our widget is 200 pixels tall, it should fit exactly 3 times.
    // but if we are offset by 300 pixels, there will be 4, numbered 1-4.

    ItemListBuilder itemBuilder = (BuildContext context, int start, int count) {
      List<Widget> result = <Widget>[];
      for (int index = start; index < start + count; index += 1) {
        callbackTracker.add(index);
        result.add(new Container(
          key: new ValueKey<int>(index),
          width: 500.0, // this should be ignored
          height: 400.0, // should be overridden by itemExtent
          child: new Text("$index")
        ));
      }
      return result;
    };

    FlipWidget testWidget = new FlipWidget(
      left: new ScrollableLazyList(
        itemBuilder: itemBuilder,
        itemExtent: 200.0,
        initialScrollOffset: 300.0
      ),
      right: new Text('Not Today')
    );
    Completer<Null> scrollTo(double newScrollOffset) {
      Completer<Null> completer = new Completer<Null>();
      final ScrollableState scrollable = tester.state(find.byType(Scrollable));
      scrollable.scrollTo(newScrollOffset).whenComplete(completer.complete);
      return completer;
    }

    await tester.pumpWidget(testWidget);

    expect(callbackTracker, equals(<int>[1, 2, 3, 4]));

    callbackTracker.clear();

    Completer<Null> completer = scrollTo(400.0);
    expect(completer.isCompleted, isFalse);
    // now only 3 should fit, numbered 2-4.

    await tester.pumpWidget(testWidget);

    expect(callbackTracker, equals(<int>[2, 3, 4]));
    expect(completer.isCompleted, isTrue);

    callbackTracker.clear();
  });

  testWidgets('HomogeneousViewport horizontal', (WidgetTester tester) async {
    List<int> callbackTracker = <int>[];

    // the root view is 800x600 in the test environment
    // so if our widget is 200 pixels wide, it should fit exactly 4 times.
    // but if we are offset by 300 pixels, there will be 5, numbered 1-5.

    ItemListBuilder itemBuilder = (BuildContext context, int start, int count) {
      List<Widget> result = <Widget>[];
      for (int index = start; index < start + count; index += 1) {
        callbackTracker.add(index);
        result.add(new Container(
          key: new ValueKey<int>(index),
          width: 400.0, // this should be overridden by itemExtent
          height: 500.0, // this should be ignored
          child: new Text("$index")
        ));
      }
      return result;
    };

    FlipWidget testWidget = new FlipWidget(
      left: new ScrollableLazyList(
        itemBuilder: itemBuilder,
        itemExtent: 200.0,
        initialScrollOffset: 300.0,
        scrollDirection: Axis.horizontal
      ),
      right: new Text('Not Today')
    );
    Completer<Null> scrollTo(double newScrollOffset) {
      Completer<Null> completer = new Completer<Null>();
      final ScrollableState scrollable = tester.state(find.byType(Scrollable));
      scrollable.scrollTo(newScrollOffset).whenComplete(completer.complete);
      return completer;
    }

    await tester.pumpWidget(testWidget);

    expect(callbackTracker, equals(<int>[1, 2, 3, 4, 5]));

    callbackTracker.clear();

    Completer<Null> completer = scrollTo(400.0);
    expect(completer.isCompleted, isFalse);
    // now only 4 should fit, numbered 2-5.

    await tester.pumpWidget(testWidget);

    expect(callbackTracker, equals(<int>[2, 3, 4, 5]));
    expect(completer.isCompleted, isTrue);

    callbackTracker.clear();
  });

  testWidgets('ScrollableLazyList 10 items, 2-3 items visible', (WidgetTester tester) async {
    List<int> callbackTracker = <int>[];

    // The root view is 800x600 in the test environment and our list
    // items are 300 tall. Scrolling should cause two or three items
    // to be built.

    ItemListBuilder itemBuilder = (BuildContext context, int start, int count) {
      List<Widget> result = <Widget>[];
      for (int index = start; index < start + count; index += 1) {
        callbackTracker.add(index);
        result.add(new Text('$index', key: new ValueKey<int>(index)));
      }
      return result;
    };

    Widget testWidget = new ScrollableLazyList(
      itemBuilder: itemBuilder,
      itemExtent: 300.0,
      itemCount: 10
    );
    Completer<Null> scrollTo(double newScrollOffset) {
      Completer<Null> completer = new Completer<Null>();
      ScrollableState scrollable = tester.state(find.byType(Scrollable));
      scrollable.scrollTo(newScrollOffset).whenComplete(completer.complete);
      return completer;
    }

    await tester.pumpWidget(testWidget);
    expect(callbackTracker, equals(<int>[0, 1]));
    callbackTracker.clear();

    Completer<Null> completer = scrollTo(150.0);
    expect(completer.isCompleted, isFalse);
    await tester.pumpWidget(testWidget);
    expect(callbackTracker, equals(<int>[0, 1, 2]));
    expect(completer.isCompleted, isTrue);
    callbackTracker.clear();

    completer = scrollTo(600.0);
    expect(completer.isCompleted, isFalse);
    await tester.pumpWidget(testWidget);
    expect(callbackTracker, equals(<int>[2, 3]));
    expect(completer.isCompleted, isTrue);
    callbackTracker.clear();

    completer = scrollTo(750.0);
    expect(completer.isCompleted, isFalse);
    await tester.pumpWidget(testWidget);
    expect(callbackTracker, equals(<int>[2, 3, 4]));
    expect(completer.isCompleted, isTrue);
    callbackTracker.clear();
  });

}

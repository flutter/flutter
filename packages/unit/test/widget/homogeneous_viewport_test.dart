// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

import 'test_widgets.dart';

void main() {
  test('HomogeneousViewport mount/dismount smoke test', () {
    testWidgets((WidgetTester tester) {
      List<int> callbackTracker = <int>[];

      // the root view is 800x600 in the test environment
      // so if our widget is 100 pixels tall, it should fit exactly 6 times.

      Widget builder() {
        return new FlipComponent(
          left: new HomogeneousViewport(
            builder: (BuildContext context, int start, int count) {
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
            startOffset: 0.0,
            itemExtent: 100.0
          ),
          right: new Text('Not Today')
        );
      }

      tester.pumpWidget(builder());

      StatefulComponentElement element = tester.findElement((Element element) => element.widget is FlipComponent);
      FlipComponentState testComponent = element.state;

      expect(callbackTracker, equals([0, 1, 2, 3, 4, 5]));

      callbackTracker.clear();
      testComponent.flip();
      tester.pump();

      expect(callbackTracker, equals([]));

      callbackTracker.clear();
      testComponent.flip();
      tester.pump();

      expect(callbackTracker, equals([0, 1, 2, 3, 4, 5]));
    });
  });

  test('HomogeneousViewport vertical', () {
    testWidgets((WidgetTester tester) {
      List<int> callbackTracker = <int>[];

      // the root view is 800x600 in the test environment
      // so if our widget is 200 pixels tall, it should fit exactly 3 times.
      // but if we are offset by 300 pixels, there will be 4, numbered 1-4.

      double offset = 300.0;

      ListBuilder itemBuilder = (BuildContext context, int start, int count) {
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

      FlipComponent testComponent;
      Widget builder() {
        testComponent = new FlipComponent(
          left: new HomogeneousViewport(
            builder: itemBuilder,
            startOffset: offset,
            itemExtent: 200.0
          ),
          right: new Text('Not Today')
        );
        return testComponent;
      }

      tester.pumpWidget(builder());

      expect(callbackTracker, equals([1, 2, 3, 4]));

      callbackTracker.clear();

      offset = 400.0; // now only 3 should fit, numbered 2-4.

      tester.pumpWidget(builder());

      expect(callbackTracker, equals([2, 3, 4]));

      callbackTracker.clear();
    });
  });

  test('HomogeneousViewport horizontal', () {
    testWidgets((WidgetTester tester) {
      List<int> callbackTracker = <int>[];

      // the root view is 800x600 in the test environment
      // so if our widget is 200 pixels wide, it should fit exactly 4 times.
      // but if we are offset by 300 pixels, there will be 5, numbered 1-5.

      double offset = 300.0;

      ListBuilder itemBuilder = (BuildContext context, int start, int count) {
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

      FlipComponent testComponent;
      Widget builder() {
        testComponent = new FlipComponent(
          left: new HomogeneousViewport(
            builder: itemBuilder,
            startOffset: offset,
            itemExtent: 200.0,
            direction: ScrollDirection.horizontal
          ),
          right: new Text('Not Today')
        );
        return testComponent;
      }

      tester.pumpWidget(builder());

      expect(callbackTracker, equals([1, 2, 3, 4, 5]));

      callbackTracker.clear();

      offset = 400.0; // now only 4 should fit, numbered 2-5.

      tester.pumpWidget(builder());

      expect(callbackTracker, equals([2, 3, 4, 5]));

      callbackTracker.clear();
    });
  });
}

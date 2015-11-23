// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

import 'test_widgets.dart';

void main() {
  test('MixedViewport mount/dismount smoke test', () {
    testWidgets((WidgetTester tester) {
      List<int> callbackTracker = <int>[];

      // the root view is 800x600 in the test environment
      // so if our widget is 100 pixels tall, it should fit exactly 6 times.

      Widget builder() {
        return new FlipComponent(
          left: new MixedViewport(
            builder: (BuildContext context, int i) {
              callbackTracker.add(i);
              return new Container(
                key: new ValueKey<int>(i),
                height: 100.0,
                child: new Text("$i")
              );
            },
            startOffset: 0.0
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

  test('MixedViewport vertical', () {
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
        return new FlipComponent(
          left: new MixedViewport(
            builder: itemBuilder,
            startOffset: offset
          ),
          right: new Text('Not Today')
        );
      }

      tester.pumpWidget(builder());

      // 0 is built to find its width
      expect(callbackTracker, equals([0, 1, 2, 3, 4]));

      callbackTracker.clear();

      offset = 400.0; // now only 3 should fit, numbered 2-4.

      tester.pumpWidget(builder());

      // 0 and 1 aren't built, we know their size and nothing else changed
      expect(callbackTracker, equals([2, 3, 4]));

      callbackTracker.clear();
    });
  });

  test('MixedViewport horizontal', () {
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
        return new FlipComponent(
          left: new MixedViewport(
            builder: itemBuilder,
            startOffset: offset,
            direction: ScrollDirection.horizontal
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

      // 0 and 1 aren't built, we know their size and nothing else changed
      expect(callbackTracker, equals([2, 3, 4, 5]));

      callbackTracker.clear();
    });
  });
}

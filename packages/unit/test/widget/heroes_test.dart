// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

import 'test_matchers.dart';

Key firstKey = new Key('first');
Key secondKey = new Key('second');
Key thirdKey = new Key('third');

final Map<String, RouteBuilder> routes = <String, RouteBuilder>{
  '/': (RouteArguments args) => new Material(
    child: new Block([
      new Container(height: 100.0, width: 100.0),
      new Card(child: new Hero(tag: 'a', child: new Container(height: 100.0, width: 100.0, key: firstKey))),
      new Container(height: 100.0, width: 100.0),
      new FlatButton(child: new Text('two'), onPressed: () => Navigator.pushNamed(args.context, '/two')),
    ])
  ),
  '/two': (RouteArguments args) => new Material(
    child: new Block([
      new Container(height: 150.0, width: 150.0),
      new Card(child: new Hero(tag: 'a', child: new Container(height: 150.0, width: 150.0, key: secondKey))),
      new Container(height: 150.0, width: 150.0),
      new FlatButton(child: new Text('three'), onPressed: () => Navigator.push(args.context, new ThreeRoute())),
    ])
  ),
};

class ThreeRoute extends MaterialPageRoute {
  ThreeRoute() : super(builder: (BuildContext context) {
    return new Material(
      child: new Block([
        new Container(height: 200.0, width: 200.0),
        new Card(child: new Hero(tag: 'a', child: new Container(height: 200.0, width: 200.0, key: thirdKey))),
        new Container(height: 200.0, width: 200.0),
      ])
    );
  });
}

void main() {
  test('Heroes animate', () {
    testWidgets((WidgetTester tester) {

      tester.pumpWidget(new MaterialApp(routes: routes));

      // the initial setup.

      expect(tester.findElementByKey(firstKey), isOnStage);
      expect(tester.findElementByKey(firstKey), isInCard);
      expect(tester.findElementByKey(secondKey), isNull);

      tester.tap(tester.findText('two'));
      tester.pump(); // begin navigation

      // at this stage, the second route is off-stage, so that we can form the
      // hero party.

      expect(tester.findElementByKey(firstKey), isOnStage);
      expect(tester.findElementByKey(firstKey), isInCard);
      expect(tester.findElementByKey(secondKey), isOffStage);
      expect(tester.findElementByKey(secondKey), isInCard);

      tester.pump();

      // at this stage, the heroes have just gone on their journey, we are
      // seeing them at t=16ms. The original page no longer contains the hero.

      expect(tester.findElementByKey(firstKey), isNull);
      expect(tester.findElementByKey(secondKey), isOnStage);
      expect(tester.findElementByKey(secondKey), isNotInCard);

      tester.pump();

      // t=32ms for the journey. Surely they are still at it.

      expect(tester.findElementByKey(firstKey), isNull);
      expect(tester.findElementByKey(secondKey), isOnStage);
      expect(tester.findElementByKey(secondKey), isNotInCard);

      tester.pump(new Duration(seconds: 1));

      // t=1.032s for the journey. The journey has ended (it ends this frame, in
      // fact). The hero should now be in the new page, on-stage.

      expect(tester.findElementByKey(firstKey), isNull);
      expect(tester.findElementByKey(secondKey), isOnStage);
      expect(tester.findElementByKey(secondKey), isInCard);

      tester.pump();

      // Should not change anything.

      expect(tester.findElementByKey(firstKey), isNull);
      expect(tester.findElementByKey(secondKey), isOnStage);
      expect(tester.findElementByKey(secondKey), isInCard);

      // Now move on to view 3

      tester.tap(tester.findText('three'));
      tester.pump(); // begin navigation

      // at this stage, the second route is off-stage, so that we can form the
      // hero party.

      expect(tester.findElementByKey(secondKey), isOnStage);
      expect(tester.findElementByKey(secondKey), isInCard);
      expect(tester.findElementByKey(thirdKey), isOffStage);
      expect(tester.findElementByKey(thirdKey), isInCard);

      tester.pump();

      // at this stage, the heroes have just gone on their journey, we are
      // seeing them at t=16ms. The original page no longer contains the hero.

      expect(tester.findElementByKey(secondKey), isNull);
      expect(tester.findElementByKey(thirdKey), isOnStage);
      expect(tester.findElementByKey(thirdKey), isNotInCard);

      tester.pump();

      // t=32ms for the journey. Surely they are still at it.

      expect(tester.findElementByKey(secondKey), isNull);
      expect(tester.findElementByKey(thirdKey), isOnStage);
      expect(tester.findElementByKey(thirdKey), isNotInCard);

      tester.pump(new Duration(seconds: 1));

      // t=1.032s for the journey. The journey has ended (it ends this frame, in
      // fact). The hero should now be in the new page, on-stage.

      expect(tester.findElementByKey(secondKey), isNull);
      expect(tester.findElementByKey(thirdKey), isOnStage);
      expect(tester.findElementByKey(thirdKey), isInCard);

      tester.pump();

      // Should not change anything.

      expect(tester.findElementByKey(secondKey), isNull);
      expect(tester.findElementByKey(thirdKey), isOnStage);
      expect(tester.findElementByKey(thirdKey), isInCard);
    });
  });
}

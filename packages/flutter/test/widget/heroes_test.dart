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

final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
  '/': (BuildContext context) => new Material(
    child: new Block(children: <Widget>[
      new Container(height: 100.0, width: 100.0),
      new Card(child: new Hero(tag: 'a', child: new Container(height: 100.0, width: 100.0, key: firstKey))),
      new Container(height: 100.0, width: 100.0),
      new FlatButton(child: new Text('two'), onPressed: () => Navigator.pushNamed(context, '/two')),
    ])
  ),
  '/two': (BuildContext context) => new Material(
    child: new Block(children: <Widget>[
      new Container(height: 150.0, width: 150.0),
      new Card(child: new Hero(tag: 'a', child: new Container(height: 150.0, width: 150.0, key: secondKey))),
      new Container(height: 150.0, width: 150.0),
      new FlatButton(child: new Text('three'), onPressed: () => Navigator.push(context, new ThreeRoute())),
    ])
  ),
};

class ThreeRoute extends MaterialPageRoute<Null> {
  ThreeRoute() : super(builder: (BuildContext context) {
    return new Material(
      child: new Block(children: <Widget>[
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

      expect(find.byKey(firstKey), isOnStage(tester));
      expect(find.byKey(firstKey), isInCard(tester));
      expect(tester, doesNotHaveWidget(find.byKey(secondKey)));

      tester.tap(find.text('two'));
      tester.pump(); // begin navigation

      // at this stage, the second route is off-stage, so that we can form the
      // hero party.

      expect(find.byKey(firstKey), isOnStage(tester));
      expect(find.byKey(firstKey), isInCard(tester));
      expect(find.byKey(secondKey), isOffStage(tester));
      expect(find.byKey(secondKey), isInCard(tester));

      tester.pump();

      // at this stage, the heroes have just gone on their journey, we are
      // seeing them at t=16ms. The original page no longer contains the hero.

      expect(tester, doesNotHaveWidget(find.byKey(firstKey)));
      expect(find.byKey(secondKey), isOnStage(tester));
      expect(find.byKey(secondKey), isNotInCard(tester));

      tester.pump();

      // t=32ms for the journey. Surely they are still at it.

      expect(tester, doesNotHaveWidget(find.byKey(firstKey)));
      expect(find.byKey(secondKey), isOnStage(tester));
      expect(find.byKey(secondKey), isNotInCard(tester));

      tester.pump(new Duration(seconds: 1));

      // t=1.032s for the journey. The journey has ended (it ends this frame, in
      // fact). The hero should now be in the new page, on-stage.

      expect(tester, doesNotHaveWidget(find.byKey(firstKey)));
      expect(find.byKey(secondKey), isOnStage(tester));
      expect(find.byKey(secondKey), isInCard(tester));

      tester.pump();

      // Should not change anything.

      expect(tester, doesNotHaveWidget(find.byKey(firstKey)));
      expect(find.byKey(secondKey), isOnStage(tester));
      expect(find.byKey(secondKey), isInCard(tester));

      // Now move on to view 3

      tester.tap(find.text('three'));
      tester.pump(); // begin navigation

      // at this stage, the second route is off-stage, so that we can form the
      // hero party.

      expect(find.byKey(secondKey), isOnStage(tester));
      expect(find.byKey(secondKey), isInCard(tester));
      expect(find.byKey(thirdKey), isOffStage(tester));
      expect(find.byKey(thirdKey), isInCard(tester));

      tester.pump();

      // at this stage, the heroes have just gone on their journey, we are
      // seeing them at t=16ms. The original page no longer contains the hero.

      expect(tester, doesNotHaveWidget(find.byKey(secondKey)));
      expect(find.byKey(thirdKey), isOnStage(tester));
      expect(find.byKey(thirdKey), isNotInCard(tester));

      tester.pump();

      // t=32ms for the journey. Surely they are still at it.

      expect(tester, doesNotHaveWidget(find.byKey(secondKey)));
      expect(find.byKey(thirdKey), isOnStage(tester));
      expect(find.byKey(thirdKey), isNotInCard(tester));

      tester.pump(new Duration(seconds: 1));

      // t=1.032s for the journey. The journey has ended (it ends this frame, in
      // fact). The hero should now be in the new page, on-stage.

      expect(tester, doesNotHaveWidget(find.byKey(secondKey)));
      expect(find.byKey(thirdKey), isOnStage(tester));
      expect(find.byKey(thirdKey), isInCard(tester));

      tester.pump();

      // Should not change anything.

      expect(tester, doesNotHaveWidget(find.byKey(secondKey)));
      expect(find.byKey(thirdKey), isOnStage(tester));
      expect(find.byKey(thirdKey), isInCard(tester));
    });
  });
}

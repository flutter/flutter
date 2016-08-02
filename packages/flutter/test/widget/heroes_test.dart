// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

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

class MutatingRoute extends MaterialPageRoute<Null> {
  MutatingRoute() : super(builder: (BuildContext context) {
    return new Hero(tag: 'a', child: new Text('MutatingRoute'), key: new UniqueKey());
  });

  void markNeedsBuild() {
    setState(() {
      // Trigger a rebuild
    });
  }
}

void main() {
  testWidgets('Heroes animate', (WidgetTester tester) async {

    await tester.pumpWidget(new MaterialApp(routes: routes));

    // the initial setup.

    expect(find.byKey(firstKey), isOnStage);
    expect(find.byKey(firstKey), isInCard);
    expect(find.byKey(secondKey), findsNothing);

    await tester.tap(find.text('two'));
    await tester.pump(); // begin navigation

    // at this stage, the second route is off-stage, so that we can form the
    // hero party.

    expect(find.byKey(firstKey), isOnStage);
    expect(find.byKey(firstKey), isInCard);
    expect(find.byKey(secondKey), isOffStage);
    expect(find.byKey(secondKey), isInCard);

    await tester.pump();

    // at this stage, the heroes have just gone on their journey, we are
    // seeing them at t=16ms. The original page no longer contains the hero.

    expect(find.byKey(firstKey), findsNothing);
    expect(find.byKey(secondKey), isOnStage);
    expect(find.byKey(secondKey), isNotInCard);

    await tester.pump();

    // t=32ms for the journey. Surely they are still at it.

    expect(find.byKey(firstKey), findsNothing);
    expect(find.byKey(secondKey), isOnStage);
    expect(find.byKey(secondKey), isNotInCard);

    await tester.pump(new Duration(seconds: 1));

    // t=1.032s for the journey. The journey has ended (it ends this frame, in
    // fact). The hero should now be in the new page, on-stage.

    expect(find.byKey(firstKey), findsNothing);
    expect(find.byKey(secondKey), isOnStage);
    expect(find.byKey(secondKey), isInCard);

    await tester.pump();

    // Should not change anything.

    expect(find.byKey(firstKey), findsNothing);
    expect(find.byKey(secondKey), isOnStage);
    expect(find.byKey(secondKey), isInCard);

    // Now move on to view 3

    await tester.tap(find.text('three'));
    await tester.pump(); // begin navigation

    // at this stage, the second route is off-stage, so that we can form the
    // hero party.

    expect(find.byKey(secondKey), isOnStage);
    expect(find.byKey(secondKey), isInCard);
    expect(find.byKey(thirdKey), isOffStage);
    expect(find.byKey(thirdKey), isInCard);

    await tester.pump();

    // at this stage, the heroes have just gone on their journey, we are
    // seeing them at t=16ms. The original page no longer contains the hero.

    expect(find.byKey(secondKey), findsNothing);
    expect(find.byKey(thirdKey), isOnStage);
    expect(find.byKey(thirdKey), isNotInCard);

    await tester.pump();

    // t=32ms for the journey. Surely they are still at it.

    expect(find.byKey(secondKey), findsNothing);
    expect(find.byKey(thirdKey), isOnStage);
    expect(find.byKey(thirdKey), isNotInCard);

    await tester.pump(new Duration(seconds: 1));

    // t=1.032s for the journey. The journey has ended (it ends this frame, in
    // fact). The hero should now be in the new page, on-stage.

    expect(find.byKey(secondKey), findsNothing);
    expect(find.byKey(thirdKey), isOnStage);
    expect(find.byKey(thirdKey), isInCard);

    await tester.pump();

    // Should not change anything.

    expect(find.byKey(secondKey), findsNothing);
    expect(find.byKey(thirdKey), isOnStage);
    expect(find.byKey(thirdKey), isInCard);
  });

  testWidgets('Heroes animate', (WidgetTester tester) async {
    MutatingRoute route = new MutatingRoute();

    await tester.pumpWidget(new MaterialApp(
      home: new Material(child: new Block(children: <Widget>[
        new Hero(tag: 'a', child: new Text('foo')),
        new Builder(builder: (BuildContext context) {
          return new FlatButton(child: new Text('two'), onPressed: () => Navigator.push(context, route));
        })
      ]))
    ));

    await tester.tap(find.text('two'));
    await tester.pump(new Duration(milliseconds: 10));

    route.markNeedsBuild();

    await tester.pump(new Duration(milliseconds: 10));
    await tester.pump(new Duration(seconds: 1));
  });
}

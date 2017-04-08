// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

Key firstKey = const Key('first');
Key secondKey = const Key('second');
Key thirdKey = const Key('third');

Key homeRouteKey = const Key('homeRoute');
Key routeTwoKey = const Key('routeTwo');
Key routeThreeKey = const Key('routeThree');

final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
  '/': (BuildContext context) => new Material(
    child: new ListView(
      key: homeRouteKey,
      children: <Widget>[
        new Container(height: 100.0, width: 100.0),
        new Card(child: new Hero(tag: 'a', child: new Container(height: 100.0, width: 100.0, key: firstKey))),
        new Container(height: 100.0, width: 100.0),
        new FlatButton(
          child: const Text('two'),
          onPressed: () { Navigator.pushNamed(context, '/two'); }
        ),
      ]
    )
  ),
  '/two': (BuildContext context) => new Material(
    child: new ListView(
      key: routeTwoKey,
      children: <Widget>[
        new FlatButton(
          child: const Text('pop'),
          onPressed: () { Navigator.pop(context); }
        ),
        new Container(height: 150.0, width: 150.0),
        new Card(child: new Hero(tag: 'a', child: new Container(height: 150.0, width: 150.0, key: secondKey))),
        new Container(height: 150.0, width: 150.0),
        new FlatButton(
          child: const Text('three'),
          onPressed: () { Navigator.push(context, new ThreeRoute()); },
        ),
      ]
    )
  ),
};

class ThreeRoute extends MaterialPageRoute<Null> {
  ThreeRoute() : super(builder: (BuildContext context) {
    return new Material(
      key: routeThreeKey,
      child: new ListView(
        children: <Widget>[
          new Container(height: 200.0, width: 200.0),
          new Card(child: new Hero(tag: 'a', child: new Container(height: 200.0, width: 200.0, key: thirdKey))),
          new Container(height: 200.0, width: 200.0),
        ]
      )
    );
  });
}

class MutatingRoute extends MaterialPageRoute<Null> {
  MutatingRoute() : super(builder: (BuildContext context) {
    return new Hero(tag: 'a', child: const Text('MutatingRoute'), key: new UniqueKey());
  });

  void markNeedsBuild() {
    setState(() {
      // Trigger a rebuild
    });
  }
}

class MyStatefulWidget extends StatefulWidget {
  MyStatefulWidget({ Key key, this.value: '123' }) : super(key: key);
  final String value;
  @override
  MyStatefulWidgetState createState() => new MyStatefulWidgetState();
}

class MyStatefulWidgetState extends State<MyStatefulWidget> {
  @override
  Widget build(BuildContext context) => new Text(widget.value);
}

void main() {
  testWidgets('Heroes animate', (WidgetTester tester) async {

    await tester.pumpWidget(new MaterialApp(routes: routes));

    // the initial setup.

    expect(find.byKey(firstKey), isOnstage);
    expect(find.byKey(firstKey), isInCard);
    expect(find.byKey(secondKey), findsNothing);

    await tester.tap(find.text('two'));
    await tester.pump(); // begin navigation

    // at this stage, the second route is offstage, so that we can form the
    // hero party.

    expect(find.byKey(firstKey), isOnstage);
    expect(find.byKey(firstKey), isInCard);
    expect(find.byKey(secondKey, skipOffstage: false), isOffstage);
    expect(find.byKey(secondKey, skipOffstage: false), isInCard);

    await tester.pump();

    // at this stage, the heroes have just gone on their journey, we are
    // seeing them at t=16ms. The original page no longer contains the hero.

    expect(find.byKey(firstKey), findsNothing);
    expect(find.byKey(secondKey), isOnstage);
    expect(find.byKey(secondKey), isNotInCard);

    await tester.pump();

    // t=32ms for the journey. Surely they are still at it.

    expect(find.byKey(firstKey), findsNothing);
    expect(find.byKey(secondKey), isOnstage);
    expect(find.byKey(secondKey), isNotInCard);

    await tester.pump(const Duration(seconds: 1));

    // t=1.032s for the journey. The journey has ended (it ends this frame, in
    // fact). The hero should now be in the new page, onstage. The original
    // widget will be back as well now (though not visible).

    expect(find.byKey(firstKey), findsNothing);
    expect(find.byKey(secondKey), isOnstage);
    expect(find.byKey(secondKey), isInCard);

    await tester.pump();

    // Should not change anything.

    expect(find.byKey(firstKey), findsNothing);
    expect(find.byKey(secondKey), isOnstage);
    expect(find.byKey(secondKey), isInCard);

    // Now move on to view 3

    await tester.tap(find.text('three'));
    await tester.pump(); // begin navigation

    // at this stage, the second route is offstage, so that we can form the
    // hero party.

    expect(find.byKey(secondKey), isOnstage);
    expect(find.byKey(secondKey), isInCard);
    expect(find.byKey(thirdKey, skipOffstage: false), isOffstage);
    expect(find.byKey(thirdKey, skipOffstage: false), isInCard);

    await tester.pump();

    // at this stage, the heroes have just gone on their journey, we are
    // seeing them at t=16ms. The original page no longer contains the hero.

    expect(find.byKey(secondKey), findsNothing);
    expect(find.byKey(thirdKey), isOnstage);
    expect(find.byKey(thirdKey), isNotInCard);

    await tester.pump();

    // t=32ms for the journey. Surely they are still at it.

    expect(find.byKey(secondKey), findsNothing);
    expect(find.byKey(thirdKey), isOnstage);
    expect(find.byKey(thirdKey), isNotInCard);

    await tester.pump(const Duration(seconds: 1));

    // t=1.032s for the journey. The journey has ended (it ends this frame, in
    // fact). The hero should now be in the new page, onstage.

    expect(find.byKey(secondKey), findsNothing);
    expect(find.byKey(thirdKey), isOnstage);
    expect(find.byKey(thirdKey), isInCard);

    await tester.pump();

    // Should not change anything.

    expect(find.byKey(secondKey), findsNothing);
    expect(find.byKey(thirdKey), isOnstage);
    expect(find.byKey(thirdKey), isInCard);
  });

  testWidgets('Destination hero is rebuilt midflight', (WidgetTester tester) async {
    final MutatingRoute route = new MutatingRoute();

    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new ListView(
          children: <Widget>[
            new Hero(tag: 'a', child: const Text('foo')),
            new Builder(builder: (BuildContext context) {
              return new FlatButton(child: const Text('two'), onPressed: () => Navigator.push(context, route));
            })
          ]
        )
      )
    ));

    await tester.tap(find.text('two'));
    await tester.pump(const Duration(milliseconds: 10));

    route.markNeedsBuild();

    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Heroes animation is fastOutSlowIn', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(routes: routes));
    await tester.tap(find.text('two'));
    await tester.pump(); // begin navigation

    // Expect the height of the secondKey Hero to vary from 100 to 150
    // over duration and according to curve.

    final Duration duration = const Duration(milliseconds: 300);
    final Curve curve = Curves.fastOutSlowIn;
    final double initialHeight = tester.getSize(find.byKey(firstKey, skipOffstage: false)).height;
    final double finalHeight = tester.getSize(find.byKey(secondKey, skipOffstage: false)).height;
    final double deltaHeight = finalHeight - initialHeight;
    final double epsilon = 0.001;

    await tester.pump(duration * 0.25);
    expect(
      tester.getSize(find.byKey(secondKey)).height,
      closeTo(curve.transform(0.25) * deltaHeight + initialHeight, epsilon)
    );

    await tester.pump(duration * 0.25);
    expect(
      tester.getSize(find.byKey(secondKey)).height,
      closeTo(curve.transform(0.50) * deltaHeight + initialHeight, epsilon)
    );

    await tester.pump(duration * 0.25);
    expect(
      tester.getSize(find.byKey(secondKey)).height,
      closeTo(curve.transform(0.75) * deltaHeight + initialHeight, epsilon)
    );

    await tester.pump(duration * 0.25);
    expect(
      tester.getSize(find.byKey(secondKey)).height,
      closeTo(curve.transform(1.0) * deltaHeight + initialHeight, epsilon)
    );
  });

  testWidgets('Heroes are not interactive', (WidgetTester tester) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(new MaterialApp(
      home: new Center(
        child: new Hero(
          tag: 'foo',
          child: new GestureDetector(
            onTap: () {
              log.add('foo');
            },
            child: new Container(
              width: 100.0,
              height: 100.0,
              child: const Text('foo')
            )
          )
        )
      ),
      routes: <String, WidgetBuilder>{
        '/next': (BuildContext context) {
          return new Align(
            alignment: FractionalOffset.topLeft,
            child: new Hero(
              tag: 'foo',
              child: new GestureDetector(
                onTap: () {
                  log.add('bar');
                },
                child: new Container(
                  width: 100.0,
                  height: 150.0,
                  child: const Text('bar')
                )
              )
            )
          );
        }
      }
    ));

    expect(log, isEmpty);
    await tester.tap(find.text('foo'));
    expect(log, equals(<String>['foo']));
    log.clear();

    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pushNamed('/next');

    expect(log, isEmpty);
    await tester.tap(find.text('foo', skipOffstage: false));
    expect(log, isEmpty);

    await tester.pump(const Duration(milliseconds: 10));
    await tester.tap(find.text('foo', skipOffstage: false));
    expect(log, isEmpty);
    await tester.tap(find.text('bar', skipOffstage: false));
    expect(log, isEmpty);

    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('foo'), findsNothing);
    await tester.tap(find.text('bar', skipOffstage: false));
    expect(log, isEmpty);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('foo'), findsNothing);
    await tester.tap(find.text('bar'));
    expect(log, equals(<String>['bar']));
  });

  testWidgets('Popping on first frame does not cause hero observer to crash', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(
      onGenerateRoute: (RouteSettings settings) {
        return new MaterialPageRoute<Null>(
          settings: settings,
          builder: (BuildContext context) => new Hero(tag: 'test', child: new Container()),
        );
      },
    ));
    await tester.pump();

    final Finder heroes = find.byType(Hero);
    expect(heroes, findsOneWidget);

    Navigator.pushNamed(heroes.evaluate().first, 'test');
    await tester.pump(); // adds the new page to the tree...

    Navigator.pop(heroes.evaluate().first);
    await tester.pump(); // ...and removes it straight away (since it's already at 0.0)

    // this is verifying that there's no crash

    // TODO(ianh): once https://github.com/flutter/flutter/issues/5631 is fixed, remove this line:
    await tester.pump(const Duration(hours: 1));
  });

  testWidgets('Overlapping starting and ending a hero transition works ok', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(
      onGenerateRoute: (RouteSettings settings) {
        return new MaterialPageRoute<Null>(
          settings: settings,
          builder: (BuildContext context) => new Hero(tag: 'test', child: new Container()),
        );
      },
    ));
    await tester.pump();

    final Finder heroes = find.byType(Hero);
    expect(heroes, findsOneWidget);

    Navigator.pushNamed(heroes.evaluate().first, 'test');
    await tester.pump();
    await tester.pump(const Duration(hours: 1));

    Navigator.pushNamed(heroes.evaluate().first, 'test');
    await tester.pump();
    await tester.pump(const Duration(hours: 1));

    Navigator.pop(heroes.evaluate().first);
    await tester.pump();
    Navigator.pop(heroes.evaluate().first);
    await tester.pump(const Duration(hours: 1)); // so the first transition is finished, but the second hasn't started
    await tester.pump();

    // this is verifying that there's no crash

    // TODO(ianh): once https://github.com/flutter/flutter/issues/5631 is fixed, remove this line:
    await tester.pump(const Duration(hours: 1));
  });

  testWidgets('One route, two heroes, same tag, throws', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new ListView(
          children: <Widget>[
            new Hero(tag: 'a', child: const Text('a')),
            new Hero(tag: 'a', child: const Text('a too')),
            new Builder(
              builder: (BuildContext context) {
                return new FlatButton(
                  child: const Text('push'),
                  onPressed: () {
                    Navigator.push(context, new PageRouteBuilder<Null>(
                      pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) {
                        return const Text('fail');
                      },
                    ));
                  },
                );
              },
            ),
          ],
        ),
      ),
    ));

    await tester.tap(find.text('push'));
    await tester.pump();
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('Hero push transition interrupted by a pop', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(
      routes: routes
    ));

    // Initially the firstKey Card on the '/' route is visible
    expect(find.byKey(firstKey), isOnstage);
    expect(find.byKey(firstKey), isInCard);
    expect(find.byKey(secondKey), findsNothing);

    // Pushes MaterialPageRoute '/two'.
    await tester.tap(find.text('two'));

    // Start the flight of Hero 'a' from route '/' to route '/two'. Route '/two'
    // is now offstage.
    await tester.pump();

    final double initialHeight = tester.getSize(find.byKey(firstKey)).height;
    final double finalHeight = tester.getSize(find.byKey(secondKey, skipOffstage: false)).height;
    expect(finalHeight, greaterThan(initialHeight)); // simplify the checks below

    // Build the first hero animation frame in the navigator's overlay.
    await tester.pump();

    // At this point the hero widgets have been replaced by placeholders
    // and the destination hero has been moved to the overlay.
    expect(find.descendant(of: find.byKey(homeRouteKey), matching: find.byKey(firstKey)), findsNothing);
    expect(find.descendant(of: find.byKey(routeTwoKey), matching: find.byKey(secondKey)), findsNothing);
    expect(find.byKey(firstKey), findsNothing);
    expect(find.byKey(secondKey), isOnstage);

    // The duration of a MaterialPageRoute's transition is 300ms.
    // At 150ms Hero 'a' is mid-flight.
    await tester.pump(const Duration(milliseconds: 150));
    final double height150ms = tester.getSize(find.byKey(secondKey)).height;
    expect(height150ms, greaterThan(initialHeight));
    expect(height150ms, lessThan(finalHeight));

    // Pop route '/two' before the push transition to '/two' has finished.
    await tester.tap(find.text('pop'));

    // Restart the flight of Hero 'a'. Now it's flying from route '/two' to
    // route '/'.
    await tester.pump();

    // After flying in the opposite direction for 50ms Hero 'a' will
    // be smaller than it was, but bigger than its initial size.
    await tester.pump(const Duration(milliseconds: 50));
    final double height100ms = tester.getSize(find.byKey(secondKey)).height;
    expect(height100ms, lessThan(height150ms));
    expect(finalHeight, greaterThan(height100ms));

    // Hero a's return flight at 149ms. The outgoing (push) flight took
    // 150ms so we should be just about back to where Hero 'a' started.
    final double epsilon = 0.001;
    await tester.pump(const Duration(milliseconds: 99));
    closeTo(tester.getSize(find.byKey(secondKey)).height - initialHeight, epsilon);

    // The flight is finished. We're back to where we started.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(firstKey), isOnstage);
    expect(find.byKey(firstKey), isInCard);
    expect(find.byKey(secondKey), findsNothing);
  });

  testWidgets('Hero pop transition interrupted by a push', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(routes: routes)
    );

    // Pushes MaterialPageRoute '/two'.
    await tester.tap(find.text('two'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Now the secondKey Card on the '/2' route is visible
    expect(find.byKey(secondKey), isOnstage);
    expect(find.byKey(secondKey), isInCard);
    expect(find.byKey(firstKey), findsNothing);

    // Pop MaterialPageRoute '/two'.
    await tester.tap(find.text('pop'));

    // Start the flight of Hero 'a' from route '/two' to route '/'. Route '/two'
    // is now offstage.
    await tester.pump();

    final double initialHeight = tester.getSize(find.byKey(secondKey)).height;
    final double finalHeight = tester.getSize(find.byKey(firstKey, skipOffstage: false)).height;
    expect(finalHeight, lessThan(initialHeight)); // simplify the checks below

    // Build the first hero animation frame in the navigator's overlay.
    await tester.pump();

    // At this point the hero widgets have been replaced by placeholders
    // and the destination hero has been moved to the overlay.
    expect(find.descendant(of: find.byKey(homeRouteKey), matching: find.byKey(firstKey)), findsNothing);
    expect(find.descendant(of: find.byKey(routeTwoKey), matching: find.byKey(secondKey)), findsNothing);
    expect(find.byKey(firstKey), isOnstage);
    expect(find.byKey(secondKey), findsNothing);

    // The duration of a MaterialPageRoute's transition is 300ms.
    // At 150ms Hero 'a' is mid-flight.
    await tester.pump(const Duration(milliseconds: 150));
    final double height150ms = tester.getSize(find.byKey(firstKey)).height;
    expect(height150ms, lessThan(initialHeight));
    expect(height150ms, greaterThan(finalHeight));

    // Push route '/two' before the pop transition from '/two' has finished.
    await tester.tap(find.text('two'));

    // Restart the flight of Hero 'a'. Now it's flying from route '/' to
    // route '/two'.
    await tester.pump();

    // After flying in the opposite direction for 50ms Hero 'a' will
    // be smaller than it was, but bigger than its initial size.
    await tester.pump(const Duration(milliseconds: 50));
    final double height100ms = tester.getSize(find.byKey(firstKey)).height;
    expect(height100ms, greaterThan(height150ms));
    expect(finalHeight, lessThan(height100ms));

    // Hero a's return flight at 149ms. The outgoing (push) flight took
    // 150ms so we should be just about back to where Hero 'a' started.
    final double epsilon = 0.001;
    await tester.pump(const Duration(milliseconds: 99));
    closeTo(tester.getSize(find.byKey(firstKey)).height - initialHeight, epsilon);

    // The flight is finished. We're back to where we started.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(secondKey), isOnstage);
    expect(find.byKey(secondKey), isInCard);
    expect(find.byKey(firstKey), findsNothing);
  });

  testWidgets('Destination hero disappears mid-flight', (WidgetTester tester) async {
    final Key homeHeroKey = const Key('home hero');
    final Key routeHeroKey = const Key('route hero');
    bool routeIncludesHero = true;
    StateSetter heroCardSetState;

    // Show a 200x200 Hero tagged 'H', with key routeHeroKey
    final MaterialPageRoute<Null> route = new MaterialPageRoute<Null>(
      builder: (BuildContext context) {
        return new Material(
          child: new ListView(
            children: <Widget>[
              new StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  heroCardSetState = setState;
                  return new Card(
                    child: routeIncludesHero
                      ? new Hero(tag: 'H', child: new Container(key: routeHeroKey, height: 200.0, width: 200.0))
                      : new Container(height: 200.0, width: 200.0),
                  );
                },
              ),
              new FlatButton(
                child: const Text('POP'),
                onPressed: () { Navigator.pop(context); }
              ),
            ],
          )
        );
      },
    );

    // Show a 100x100 Hero tagged 'H' with key homeHeroKey
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new Builder(
            builder: (BuildContext context) { // Navigator.push() needs context
              return new ListView(
                children: <Widget> [
                  new Card(
                    child: new Hero(tag: 'H', child: new Container(key: homeHeroKey, height: 100.0, width: 100.0)),
                  ),
                  new FlatButton(
                    child: const Text('PUSH'),
                    onPressed: () { Navigator.push(context, route); }
                  ),
                ],
              );
            },
          ),
        ),
      )
    );

    // Pushes route
    await tester.tap(find.text('PUSH'));
    await tester.pump();
    await tester.pump();
    final double initialHeight = tester.getSize(find.byKey(routeHeroKey)).height;

    await tester.pump(const Duration(milliseconds: 10));
    double midflightHeight = tester.getSize(find.byKey(routeHeroKey)).height;
    expect(midflightHeight, greaterThan(initialHeight));
    expect(midflightHeight, lessThan(200.0));

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    double finalHeight = tester.getSize(find.byKey(routeHeroKey)).height;
    expect(finalHeight, 200.0);

    // Complete the flight
    await tester.pump(const Duration(milliseconds: 100));

    // Rebuild route with its Hero

    heroCardSetState(() {
      routeIncludesHero = true;
    });
    await tester.pump();

    // Pops route
    await tester.tap(find.text('POP'));
    await tester.pump();
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 10));
    midflightHeight = tester.getSize(find.byKey(homeHeroKey)).height;
    expect(midflightHeight, lessThan(finalHeight));
    expect(midflightHeight, greaterThan(100.0));

    // Remove the destination hero midlfight
    heroCardSetState(() {
      routeIncludesHero = false;
    });
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 300));
    finalHeight = tester.getSize(find.byKey(homeHeroKey)).height;
    expect(finalHeight, 100.0);

  });

  testWidgets('Destination hero scrolls mid-flight', (WidgetTester tester) async {
    final Key homeHeroKey = const Key('home hero');
    final Key routeHeroKey = const Key('route hero');
    final Key routeContainerKey = const Key('route hero container');

    // Show a 200x200 Hero tagged 'H', with key routeHeroKey
    final MaterialPageRoute<Null> route = new MaterialPageRoute<Null>(
      builder: (BuildContext context) {
        return new Material(
          child: new ListView(
            children: <Widget>[
              const SizedBox(height: 100.0),
              // This container will appear at Y=100
              new Container(
                key: routeContainerKey,
                child: new Hero(tag: 'H', child: new Container(key: routeHeroKey, height: 200.0, width: 200.0))
              ),
              new FlatButton(
                child: const Text('POP'),
                onPressed: () { Navigator.pop(context); }
              ),
              const SizedBox(height: 600.0),
            ],
          )
        );
      },
    );

    // Show a 100x100 Hero tagged 'H' with key homeHeroKey
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new Builder(
            builder: (BuildContext context) { // Navigator.push() needs context
              return new ListView(
                children: <Widget> [
                  const SizedBox(height: 200.0),
                  // This container will appear at Y=200
                  new Container(
                    child: new Hero(tag: 'H', child: new Container(key: homeHeroKey, height: 100.0, width: 100.0)),
                  ),
                  new FlatButton(
                    child: const Text('PUSH'),
                    onPressed: () { Navigator.push(context, route); }
                  ),
                  const SizedBox(height: 600.0),
                ],
              );
            },
          ),
        ),
      )
    );

    // Pushes route
    await tester.tap(find.text('PUSH'));
    await tester.pump();
    await tester.pump();

    final double initialY = tester.getTopLeft(find.byKey(routeHeroKey)).y;
    expect(initialY, 200.0);

    await tester.pump(const Duration(milliseconds: 100));
    final double yAt100ms = tester.getTopLeft(find.byKey(routeHeroKey)).y;
    expect(yAt100ms, lessThan(200.0));
    expect(yAt100ms, greaterThan(100.0));

    // Scroll the target upwards by 25 pixels. The Hero flight's Y coordinate
    // will be redirected from 100 to 75.
    await(tester.drag(find.byKey(routeContainerKey), const Offset(0.0, -25.0)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    final double yAt110ms = tester.getTopLeft(find.byKey(routeHeroKey)).y;
    expect(yAt110ms, lessThan(yAt100ms));
    expect(yAt110ms, greaterThan(75.0));

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    final double finalHeroY = tester.getTopLeft(find.byKey(routeHeroKey)).y;
    expect(finalHeroY, 75.0); // 100 less 25 for the scroll
  });

  testWidgets('Destination hero scrolls out of view mid-flight', (WidgetTester tester) async {
    final Key homeHeroKey = const Key('home hero');
    final Key routeHeroKey = const Key('route hero');
    final Key routeContainerKey = const Key('route hero container');

    // Show a 200x200 Hero tagged 'H', with key routeHeroKey
    final MaterialPageRoute<Null> route = new MaterialPageRoute<Null>(
      builder: (BuildContext context) {
        return new Material(
          child: new ListView(
            children: <Widget>[
              const SizedBox(height: 100.0),
              // This container will appear at Y=100
              new Container(
                key: routeContainerKey,
                child: new Hero(tag: 'H', child: new Container(key: routeHeroKey, height: 200.0, width: 200.0))
              ),
              const SizedBox(height: 800.0),
            ],
          )
        );
      },
    );

    // Show a 100x100 Hero tagged 'H' with key homeHeroKey
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new Builder(
            builder: (BuildContext context) { // Navigator.push() needs context
              return new ListView(
                children: <Widget> [
                  const SizedBox(height: 200.0),
                  // This container will appear at Y=200
                  new Container(
                    child: new Hero(tag: 'H', child: new Container(key: homeHeroKey, height: 100.0, width: 100.0)),
                  ),
                  new FlatButton(
                    child: const Text('PUSH'),
                    onPressed: () { Navigator.push(context, route); }
                  ),
                ],
              );
            },
          ),
        ),
      )
    );

    // Pushes route
    await tester.tap(find.text('PUSH'));
    await tester.pump();
    await tester.pump();

    final double initialY = tester.getTopLeft(find.byKey(routeHeroKey)).y;
    expect(initialY, 200.0);

    await tester.pump(const Duration(milliseconds: 100));
    final double yAt100ms = tester.getTopLeft(find.byKey(routeHeroKey)).y;
    expect(yAt100ms, lessThan(200.0));
    expect(yAt100ms, greaterThan(100.0));

    await(tester.drag(find.byKey(routeContainerKey), const Offset(0.0, -400.0)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.byKey(routeContainerKey), findsNothing); // Scrolled off the top

    // Flight continues (the hero will fade out) even though the destination
    // no longer exists.
    final double yAt110ms = tester.getTopLeft(find.byKey(routeHeroKey)).y;
    expect(yAt110ms, lessThan(yAt100ms));
    expect(yAt110ms, greaterThan(100.0));

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.byKey(routeHeroKey), findsNothing);
  });

  testWidgets('Aborted flight', (WidgetTester tester) async {
    // See https://github.com/flutter/flutter/issues/5798
    final Key heroABKey = const Key('AB hero');
    final Key heroBCKey = const Key('BC hero');

    // Show a 150x150 Hero tagged 'BC'
    final MaterialPageRoute<Null> routeC = new MaterialPageRoute<Null>(
      builder: (BuildContext context) {
        return new Material(
          child: new ListView(
            children: <Widget>[
              // This container will appear at Y=0
              new Container(
                child: new Hero(tag: 'BC', child: new Container(key: heroBCKey, height: 150.0))
              ),
              const SizedBox(height: 800.0),
            ],
          )
        );
      },
    );

    // Show a height=200 Hero tagged 'AB' and a height=50 Hero tagged 'BC'
    final MaterialPageRoute<Null> routeB = new MaterialPageRoute<Null>(
      builder: (BuildContext context) {
        return new Material(
          child: new ListView(
            children: <Widget>[
              const SizedBox(height: 100.0),
              // This container will appear at Y=100
              new Container(
                child: new Hero(tag: 'AB', child: new Container(key: heroABKey, height: 200.0))
              ),
              new FlatButton(
                child: const Text('PUSH C'),
                onPressed: () { Navigator.push(context, routeC); }
              ),
              new Container(
                child: new Hero(tag: 'BC', child: new Container(height: 150.0))
              ),
              const SizedBox(height: 800.0),
            ],
          )
        );
      },
    );

    // Show a 100x100 Hero tagged 'AB' with key heroABKey
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new Builder(
            builder: (BuildContext context) { // Navigator.push() needs context
              return new ListView(
                children: <Widget> [
                  const SizedBox(height: 200.0),
                  // This container will appear at Y=200
                  new Container(
                    child: new Hero(tag: 'AB', child: new Container(height: 100.0, width: 100.0)),
                  ),
                  new FlatButton(
                    child: const Text('PUSH B'),
                    onPressed: () { Navigator.push(context, routeB); }
                  ),
                ],
              );
            },
          ),
        ),
      )
    );

    // Pushes routeB
    await tester.tap(find.text('PUSH B'));
    await tester.pump();
    await tester.pump();

    final double initialY = tester.getTopLeft(find.byKey(heroABKey)).y;
    expect(initialY, 200.0);

    await tester.pump(const Duration(milliseconds: 200));
    final double yAt200ms = tester.getTopLeft(find.byKey(heroABKey)).y;
    // Hero AB is mid flight.
    expect(yAt200ms, lessThan(200.0));
    expect(yAt200ms, greaterThan(100.0));

    // Pushes route C, causes hero AB's flight to abort, hero BC's flight to start
    await tester.tap(find.text('PUSH C'));
    await tester.pump();
    await tester.pump();

    // Hero AB's aborted flight finishes where it was expected although
    // it's been faded out.
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(find.byKey(heroABKey)).y, 100.0);

    // One Opacity widget per Hero, only one now has opacity 0.0
    final Iterable<RenderOpacity> renderers = tester.renderObjectList(find.byType(Opacity));
    final Iterable<double> opacities = renderers.map((RenderOpacity r) => r.opacity);
    expect(opacities.singleWhere((double opacity) => opacity == 0.0), 0.0);

    // Hero BC's flight finishes normally.
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getTopLeft(find.byKey(heroBCKey)).y, 0.0);
  });

  testWidgets('Stateful hero child state survives flight', (WidgetTester tester) async {
    final MaterialPageRoute<Null> route = new MaterialPageRoute<Null>(
      builder: (BuildContext context) {
        return new Material(
          child: new ListView(
            children: <Widget>[
              new Card(
                child: new Hero(
                  tag: 'H',
                  child: new SizedBox(
                    height: 200.0,
                    child: new MyStatefulWidget(value: '456'),
                  ),
                ),
              ),
              new FlatButton(
                child: const Text('POP'),
                onPressed: () { Navigator.pop(context); }
              ),
            ],
          )
        );
      },
    );

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new Builder(
            builder: (BuildContext context) { // Navigator.push() needs context
              return new ListView(
                children: <Widget> [
                  new Card(
                    child: new Hero(
                      tag: 'H',
                      child: new SizedBox(
                        height: 100.0,
                        child: new MyStatefulWidget(value: '456'),
                      ),
                    ),
                  ),
                  new FlatButton(
                    child: const Text('PUSH'),
                    onPressed: () { Navigator.push(context, route); }
                  ),
                ],
              );
            },
          ),
        ),
      )
    );

    expect(find.text('456'), findsOneWidget);

    // Push route.
    await tester.tap(find.text('PUSH'));
    await tester.pump();
    await tester.pump();

    // Push flight underway.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('456'), findsOneWidget);

    // Push flight finished.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('456'), findsOneWidget);

    // Pop route.
    await tester.tap(find.text('POP'));
    await tester.pump();
    await tester.pump();

    // Pop flight underway.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('456'), findsOneWidget);

    // Pop flight finished
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('456'), findsOneWidget);

  });
}

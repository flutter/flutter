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

bool transitionFromUserGestures = false;

final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
  '/': (BuildContext context) => Material(
    child: ListView(
      key: homeRouteKey,
      children: <Widget>[
        Container(height: 100.0, width: 100.0),
        Card(child: Hero(
          tag: 'a',
          transitionOnUserGestures: transitionFromUserGestures,
          child: Container(height: 100.0, width: 100.0, key: firstKey),
        )),
        Container(height: 100.0, width: 100.0),
        FlatButton(
          child: const Text('two'),
          onPressed: () { Navigator.pushNamed(context, '/two'); },
        ),
        FlatButton(
          child: const Text('twoInset'),
          onPressed: () { Navigator.pushNamed(context, '/twoInset'); },
        ),
      ],
    ),
  ),
  '/two': (BuildContext context) => Material(
    child: ListView(
      key: routeTwoKey,
      children: <Widget>[
        FlatButton(
          child: const Text('pop'),
          onPressed: () { Navigator.pop(context); },
        ),
        Container(height: 150.0, width: 150.0),
        Card(child: Hero(
          tag: 'a',
          transitionOnUserGestures: transitionFromUserGestures,
          child: Container(height: 150.0, width: 150.0, key: secondKey),
        )),
        Container(height: 150.0, width: 150.0),
        FlatButton(
          child: const Text('three'),
          onPressed: () { Navigator.push(context, ThreeRoute()); },
        ),
      ],
    ),
  ),
  // This route is the same as /two except that Hero 'a' is shifted to the right by
  // 50 pixels. When the hero's in-flight bounds between / and /twoInset are animated
  // using MaterialRectArcTween (the default) they'll follow a different path
  // then when the flight starts at /twoInset and returns to /.
  '/twoInset': (BuildContext context) => Material(
    child: ListView(
      key: routeTwoKey,
      children: <Widget>[
        FlatButton(
          child: const Text('pop'),
          onPressed: () { Navigator.pop(context); },
        ),
        Container(height: 150.0, width: 150.0),
        Card(
          child: Padding(
            padding: const EdgeInsets.only(left: 50.0),
            child: Hero(
              tag: 'a',
              transitionOnUserGestures: transitionFromUserGestures,
              child: Container(height: 150.0, width: 150.0, key: secondKey),
            ),
          ),
        ),
        Container(height: 150.0, width: 150.0),
        FlatButton(
          child: const Text('three'),
          onPressed: () { Navigator.push(context, ThreeRoute()); },
        ),
      ],
    ),
  ),
};

class ThreeRoute extends MaterialPageRoute<void> {
  ThreeRoute()
    : super(builder: (BuildContext context) {
        return Material(
          key: routeThreeKey,
          child: ListView(
            children: <Widget>[
              Container(height: 200.0, width: 200.0),
              Card(child: Hero(tag: 'a', child: Container(height: 200.0, width: 200.0, key: thirdKey))),
              Container(height: 200.0, width: 200.0),
            ],
          ),
        );
      });
}

class MutatingRoute extends MaterialPageRoute<void> {
  MutatingRoute()
    : super(builder: (BuildContext context) {
        return Hero(tag: 'a', child: const Text('MutatingRoute'), key: UniqueKey());
      });

  void markNeedsBuild() {
    setState(() {
      // Trigger a rebuild
    });
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({ Key key, this.value = '123' }) : super(key: key);
  final String value;
  @override
  MyStatefulWidgetState createState() => MyStatefulWidgetState();
}

class MyStatefulWidgetState extends State<MyStatefulWidget> {
  @override
  Widget build(BuildContext context) => Text(widget.value);
}

void main() {
  setUp(() {
    transitionFromUserGestures = false;
  });

  testWidgets('Heroes animate', (WidgetTester tester) async {

    await tester.pumpWidget(MaterialApp(routes: routes));

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
    final MutatingRoute route = MutatingRoute();

    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: ListView(
          children: <Widget>[
            const Hero(tag: 'a', child: Text('foo')),
            Builder(builder: (BuildContext context) {
              return FlatButton(child: const Text('two'), onPressed: () => Navigator.push(context, route));
            }),
          ],
        ),
      ),
    ));

    await tester.tap(find.text('two'));
    await tester.pump(const Duration(milliseconds: 10));

    route.markNeedsBuild();

    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Heroes animation is fastOutSlowIn', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(routes: routes));
    await tester.tap(find.text('two'));
    await tester.pump(); // begin navigation

    // Expect the height of the secondKey Hero to vary from 100 to 150
    // over duration and according to curve.

    const Duration duration = Duration(milliseconds: 300);
    const Curve curve = Curves.fastOutSlowIn;
    final double initialHeight = tester.getSize(find.byKey(firstKey, skipOffstage: false)).height;
    final double finalHeight = tester.getSize(find.byKey(secondKey, skipOffstage: false)).height;
    final double deltaHeight = finalHeight - initialHeight;
    const double epsilon = 0.001;

    await tester.pump(duration * 0.25);
    expect(
      tester.getSize(find.byKey(secondKey)).height,
      closeTo(curve.transform(0.25) * deltaHeight + initialHeight, epsilon),
    );

    await tester.pump(duration * 0.25);
    expect(
      tester.getSize(find.byKey(secondKey)).height,
      closeTo(curve.transform(0.50) * deltaHeight + initialHeight, epsilon),
    );

    await tester.pump(duration * 0.25);
    expect(
      tester.getSize(find.byKey(secondKey)).height,
      closeTo(curve.transform(0.75) * deltaHeight + initialHeight, epsilon),
    );

    await tester.pump(duration * 0.25);
    expect(
      tester.getSize(find.byKey(secondKey)).height,
      closeTo(curve.transform(1.0) * deltaHeight + initialHeight, epsilon),
    );
  });

  testWidgets('Heroes are not interactive', (WidgetTester tester) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: Hero(
          tag: 'foo',
          child: GestureDetector(
            onTap: () {
              log.add('foo');
            },
            child: Container(
              width: 100.0,
              height: 100.0,
              child: const Text('foo'),
            ),
          ),
        ),
      ),
      routes: <String, WidgetBuilder>{
        '/next': (BuildContext context) {
          return Align(
            alignment: Alignment.topLeft,
            child: Hero(
              tag: 'foo',
              child: GestureDetector(
                onTap: () {
                  log.add('bar');
                },
                child: Container(
                  width: 100.0,
                  height: 150.0,
                  child: const Text('bar'),
                ),
              ),
            ),
          );
        },
      },
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
    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => Hero(tag: 'test', child: Container()),
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
    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => Hero(tag: 'test', child: Container()),
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
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: ListView(
          children: <Widget>[
            const Hero(tag: 'a', child: Text('a')),
            const Hero(tag: 'a', child: Text('a too')),
            Builder(
              builder: (BuildContext context) {
                return FlatButton(
                  child: const Text('push'),
                  onPressed: () {
                    Navigator.push(context, PageRouteBuilder<void>(
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
    await tester.pumpWidget(MaterialApp(
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
    const double epsilon = 0.001;
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
      MaterialApp(routes: routes)
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
    final double height200ms = tester.getSize(find.byKey(firstKey)).height;
    expect(height200ms, greaterThan(height150ms));
    expect(finalHeight, lessThan(height200ms));

    // Hero a's return flight at 149ms. The outgoing (push) flight took
    // 150ms so we should be just about back to where Hero 'a' started.
    const double epsilon = 0.001;
    await tester.pump(const Duration(milliseconds: 99));
    closeTo(tester.getSize(find.byKey(firstKey)).height - initialHeight, epsilon);

    // The flight is finished. We're back to where we started.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(secondKey), isOnstage);
    expect(find.byKey(secondKey), isInCard);
    expect(find.byKey(firstKey), findsNothing);
  });

  testWidgets('Destination hero disappears mid-flight', (WidgetTester tester) async {
    const Key homeHeroKey = Key('home hero');
    const Key routeHeroKey = Key('route hero');
    bool routeIncludesHero = true;
    StateSetter heroCardSetState;

    // Show a 200x200 Hero tagged 'H', with key routeHeroKey
    final MaterialPageRoute<void> route = MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return Material(
          child: ListView(
            children: <Widget>[
              StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  heroCardSetState = setState;
                  return Card(
                    child: routeIncludesHero
                      ? Hero(tag: 'H', child: Container(key: routeHeroKey, height: 200.0, width: 200.0))
                      : Container(height: 200.0, width: 200.0),
                  );
                },
              ),
              FlatButton(
                child: const Text('POP'),
                onPressed: () { Navigator.pop(context); },
              ),
            ],
          ),
        );
      },
    );

    // Show a 100x100 Hero tagged 'H' with key homeHeroKey
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) { // Navigator.push() needs context
              return ListView(
                children: <Widget> [
                  Card(
                    child: Hero(tag: 'H', child: Container(key: homeHeroKey, height: 100.0, width: 100.0)),
                  ),
                  FlatButton(
                    child: const Text('PUSH'),
                    onPressed: () { Navigator.push(context, route); },
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

    // Remove the destination hero midflight
    heroCardSetState(() {
      routeIncludesHero = false;
    });
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 300));
    finalHeight = tester.getSize(find.byKey(homeHeroKey)).height;
    expect(finalHeight, 100.0);

  });

  testWidgets('Destination hero scrolls mid-flight', (WidgetTester tester) async {
    const Key homeHeroKey = Key('home hero');
    const Key routeHeroKey = Key('route hero');
    const Key routeContainerKey = Key('route hero container');

    // Show a 200x200 Hero tagged 'H', with key routeHeroKey
    final MaterialPageRoute<void> route = MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return Material(
          child: ListView(
            children: <Widget>[
              const SizedBox(height: 100.0),
              // This container will appear at Y=100
              Container(
                key: routeContainerKey,
                child: Hero(tag: 'H', child: Container(key: routeHeroKey, height: 200.0, width: 200.0)),
              ),
              FlatButton(
                child: const Text('POP'),
                onPressed: () { Navigator.pop(context); },
              ),
              const SizedBox(height: 600.0),
            ],
          ),
        );
      },
    );

    // Show a 100x100 Hero tagged 'H' with key homeHeroKey
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) { // Navigator.push() needs context
              return ListView(
                children: <Widget> [
                  const SizedBox(height: 200.0),
                  // This container will appear at Y=200
                  Container(
                    child: Hero(tag: 'H', child: Container(key: homeHeroKey, height: 100.0, width: 100.0)),
                  ),
                  FlatButton(
                    child: const Text('PUSH'),
                    onPressed: () { Navigator.push(context, route); },
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

    final double initialY = tester.getTopLeft(find.byKey(routeHeroKey)).dy;
    expect(initialY, 200.0);

    await tester.pump(const Duration(milliseconds: 100));
    final double yAt100ms = tester.getTopLeft(find.byKey(routeHeroKey)).dy;
    expect(yAt100ms, lessThan(200.0));
    expect(yAt100ms, greaterThan(100.0));

    // Scroll the target upwards by 25 pixels. The Hero flight's Y coordinate
    // will be redirected from 100 to 75.
    await tester.drag(find.byKey(routeContainerKey), const Offset(0.0, -25.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    final double yAt110ms = tester.getTopLeft(find.byKey(routeHeroKey)).dy;
    expect(yAt110ms, lessThan(yAt100ms));
    expect(yAt110ms, greaterThan(75.0));

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    final double finalHeroY = tester.getTopLeft(find.byKey(routeHeroKey)).dy;
    expect(finalHeroY, 75.0); // 100 less 25 for the scroll
  });

  testWidgets('Destination hero scrolls out of view mid-flight', (WidgetTester tester) async {
    const Key homeHeroKey = Key('home hero');
    const Key routeHeroKey = Key('route hero');
    const Key routeContainerKey = Key('route hero container');

    // Show a 200x200 Hero tagged 'H', with key routeHeroKey
    final MaterialPageRoute<void> route = MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return Material(
          child: ListView(
            cacheExtent: 0.0,
            children: <Widget>[
              const SizedBox(height: 100.0),
              // This container will appear at Y=100
              Container(
                key: routeContainerKey,
                child: Hero(tag: 'H', child: Container(key: routeHeroKey, height: 200.0, width: 200.0)),
              ),
              const SizedBox(height: 800.0),
            ],
          ),
        );
      },
    );

    // Show a 100x100 Hero tagged 'H' with key homeHeroKey
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) { // Navigator.push() needs context
              return ListView(
                children: <Widget> [
                  const SizedBox(height: 200.0),
                  // This container will appear at Y=200
                  Container(
                    child: Hero(tag: 'H', child: Container(key: homeHeroKey, height: 100.0, width: 100.0)),
                  ),
                  FlatButton(
                    child: const Text('PUSH'),
                    onPressed: () { Navigator.push(context, route); },
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

    final double initialY = tester.getTopLeft(find.byKey(routeHeroKey)).dy;
    expect(initialY, 200.0);

    await tester.pump(const Duration(milliseconds: 100));
    final double yAt100ms = tester.getTopLeft(find.byKey(routeHeroKey)).dy;
    expect(yAt100ms, lessThan(200.0));
    expect(yAt100ms, greaterThan(100.0));

    await tester.drag(find.byKey(routeContainerKey), const Offset(0.0, -400.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.byKey(routeContainerKey), findsNothing); // Scrolled off the top

    // Flight continues (the hero will fade out) even though the destination
    // no longer exists.
    final double yAt110ms = tester.getTopLeft(find.byKey(routeHeroKey)).dy;
    expect(yAt110ms, lessThan(yAt100ms));
    expect(yAt110ms, greaterThan(100.0));

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.byKey(routeHeroKey), findsNothing);
  });

  testWidgets('Aborted flight', (WidgetTester tester) async {
    // See https://github.com/flutter/flutter/issues/5798
    const Key heroABKey = Key('AB hero');
    const Key heroBCKey = Key('BC hero');

    // Show a 150x150 Hero tagged 'BC'
    final MaterialPageRoute<void> routeC = MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return Material(
          child: ListView(
            children: <Widget>[
              // This container will appear at Y=0
              Container(
                child: Hero(tag: 'BC', child: Container(key: heroBCKey, height: 150.0)),
              ),
              const SizedBox(height: 800.0),
            ],
          ),
        );
      },
    );

    // Show a height=200 Hero tagged 'AB' and a height=50 Hero tagged 'BC'
    final MaterialPageRoute<void> routeB = MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return Material(
          child: ListView(
            children: <Widget>[
              const SizedBox(height: 100.0),
              // This container will appear at Y=100
              Container(
                child: Hero(tag: 'AB', child: Container(key: heroABKey, height: 200.0)),
              ),
              FlatButton(
                child: const Text('PUSH C'),
                onPressed: () { Navigator.push(context, routeC); },
              ),
              Container(
                child: Hero(tag: 'BC', child: Container(height: 150.0)),
              ),
              const SizedBox(height: 800.0),
            ],
          ),
        );
      },
    );

    // Show a 100x100 Hero tagged 'AB' with key heroABKey
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) { // Navigator.push() needs context
              return ListView(
                children: <Widget> [
                  const SizedBox(height: 200.0),
                  // This container will appear at Y=200
                  Container(
                    child: Hero(tag: 'AB', child: Container(height: 100.0, width: 100.0)),
                  ),
                  FlatButton(
                    child: const Text('PUSH B'),
                    onPressed: () { Navigator.push(context, routeB); },
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

    final double initialY = tester.getTopLeft(find.byKey(heroABKey)).dy;
    expect(initialY, 200.0);

    await tester.pump(const Duration(milliseconds: 200));
    final double yAt200ms = tester.getTopLeft(find.byKey(heroABKey)).dy;
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
    expect(tester.getTopLeft(find.byKey(heroABKey)).dy, 100.0);

    // One Opacity widget per Hero, only one now has opacity 0.0
    final Iterable<RenderOpacity> renderers = tester.renderObjectList(find.byType(Opacity));
    final Iterable<double> opacities = renderers.map<double>((RenderOpacity r) => r.opacity);
    expect(opacities.singleWhere((double opacity) => opacity == 0.0), 0.0);

    // Hero BC's flight finishes normally.
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getTopLeft(find.byKey(heroBCKey)).dy, 0.0);
  });

  testWidgets('Stateful hero child state survives flight', (WidgetTester tester) async {
    final MaterialPageRoute<void> route = MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return Material(
          child: ListView(
            children: <Widget>[
              const Card(
                child: Hero(
                  tag: 'H',
                  child: SizedBox(
                    height: 200.0,
                    child: MyStatefulWidget(value: '456'),
                  ),
                ),
              ),
              FlatButton(
                child: const Text('POP'),
                onPressed: () { Navigator.pop(context); },
              ),
            ],
          ),
        );
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) { // Navigator.push() needs context
              return ListView(
                children: <Widget> [
                  const Card(
                    child: Hero(
                      tag: 'H',
                      child: SizedBox(
                        height: 100.0,
                        child: MyStatefulWidget(value: '456'),
                      ),
                    ),
                  ),
                  FlatButton(
                    child: const Text('PUSH'),
                    onPressed: () { Navigator.push(context, route); },
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

  testWidgets('Hero createRectTween', (WidgetTester tester) async {
    RectTween createRectTween(Rect begin, Rect end) {
      return MaterialRectCenterArcTween(begin: begin, end: end);
    }

    final Map<String, WidgetBuilder> createRectTweenHeroRoutes = <String, WidgetBuilder>{
      '/': (BuildContext context) => Material(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Hero(
              tag: 'a',
              createRectTween: createRectTween,
              child: Container(height: 100.0, width: 100.0, key: firstKey),
            ),
            FlatButton(
              child: const Text('two'),
              onPressed: () { Navigator.pushNamed(context, '/two'); },
            ),
          ],
        ),
      ),
      '/two': (BuildContext context) => Material(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 200.0,
              child: FlatButton(
                child: const Text('pop'),
                onPressed: () { Navigator.pop(context); },
              ),
            ),
            Hero(
              tag: 'a',
              createRectTween: createRectTween,
              child: Container(height: 200.0, width: 100.0, key: secondKey),
            ),
          ],
        ),
      ),
    };

    await tester.pumpWidget(MaterialApp(routes: createRectTweenHeroRoutes));
    expect(tester.getCenter(find.byKey(firstKey)), const Offset(50.0, 50.0));

    const double epsilon = 0.001;
    const Duration duration = Duration(milliseconds: 300);
    const Curve curve = Curves.fastOutSlowIn;
    final MaterialPointArcTween pushCenterTween = MaterialPointArcTween(
      begin: const Offset(50.0, 50.0),
      end: const Offset(400.0, 300.0),
    );

    await tester.tap(find.text('two'));
    await tester.pump(); // begin navigation

    // Verify that the center of the secondKey Hero flies along the
    // pushCenterTween arc for the push /two flight.

    await tester.pump();
    expect(tester.getCenter(find.byKey(secondKey)), const Offset(50.0, 50.0));

    await tester.pump(duration * 0.25);
    Offset actualHeroCenter = tester.getCenter(find.byKey(secondKey));
    Offset predictedHeroCenter = pushCenterTween.lerp(curve.transform(0.25));
    expect(actualHeroCenter, within<Offset>(distance: epsilon, from: predictedHeroCenter));

    await tester.pump(duration * 0.25);
    actualHeroCenter = tester.getCenter(find.byKey(secondKey));
    predictedHeroCenter = pushCenterTween.lerp(curve.transform(0.5));
    expect(actualHeroCenter, within<Offset>(distance: epsilon, from: predictedHeroCenter));

    await tester.pump(duration * 0.25);
    actualHeroCenter = tester.getCenter(find.byKey(secondKey));
    predictedHeroCenter = pushCenterTween.lerp(curve.transform(0.75));
    expect(actualHeroCenter, within<Offset>(distance: epsilon, from: predictedHeroCenter));

    await tester.pumpAndSettle();
    expect(tester.getCenter(find.byKey(secondKey)), const Offset(400.0, 300.0));

    // Verify that the center of the firstKey Hero flies along the
    // pushCenterTween arc for the pop /two flight.

    await tester.tap(find.text('pop'));
    await tester.pump(); // begin navigation

    final MaterialPointArcTween popCenterTween = MaterialPointArcTween(
      begin: const Offset(400.0, 300.0),
      end: const Offset(50.0, 50.0),
    );
    await tester.pump();
    expect(tester.getCenter(find.byKey(firstKey)), const Offset(400.0, 300.0));

    await tester.pump(duration * 0.25);
    actualHeroCenter = tester.getCenter(find.byKey(firstKey));
    predictedHeroCenter = popCenterTween.lerp(curve.flipped.transform(0.25));
    expect(actualHeroCenter, within<Offset>(distance: epsilon, from: predictedHeroCenter));

    await tester.pump(duration * 0.25);
    actualHeroCenter = tester.getCenter(find.byKey(firstKey));
    predictedHeroCenter = popCenterTween.lerp(curve.flipped.transform(0.5));
    expect(actualHeroCenter, within<Offset>(distance: epsilon, from: predictedHeroCenter));

    await tester.pump(duration * 0.25);
    actualHeroCenter = tester.getCenter(find.byKey(firstKey));
    predictedHeroCenter = popCenterTween.lerp(curve.flipped.transform(0.75));
    expect(actualHeroCenter, within<Offset>(distance: epsilon, from: predictedHeroCenter));

    await tester.pumpAndSettle();
    expect(tester.getCenter(find.byKey(firstKey)), const Offset(50.0, 50.0));
  });

  testWidgets('Pop interrupts push, reverses flight', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(routes: routes));
    await tester.tap(find.text('twoInset'));
    await tester.pump(); // begin navigation from / to /twoInset.

    const double epsilon = 0.001;
    const Duration duration = Duration(milliseconds: 300);

    await tester.pump();
    final double x0 = tester.getTopLeft(find.byKey(secondKey)).dx;

    // Flight begins with the secondKey Hero widget lined up with the firstKey widget.
    expect(x0, 4.0);

    await tester.pump(duration * 0.1);
    final double x1 = tester.getTopLeft(find.byKey(secondKey)).dx;

    await tester.pump(duration * 0.1);
    final double x2 = tester.getTopLeft(find.byKey(secondKey)).dx;

    await tester.pump(duration * 0.1);
    final double x3 = tester.getTopLeft(find.byKey(secondKey)).dx;

    await tester.pump(duration * 0.1);
    final double x4 = tester.getTopLeft(find.byKey(secondKey)).dx;

    // Pop route /twoInset before the push transition from / to /twoInset has finished.
    await tester.tap(find.text('pop'));


    // We expect the hero to take the same path as it did flying from /
    // to /twoInset as it does now, flying from '/twoInset' back to /. The most
    // important checks below are the first (x4) and last (x0): the hero should
    // not jump from where it was when the push transition was interrupted by a
    // pop, and it should end up where the push started.

    await tester.pump();
    expect(tester.getTopLeft(find.byKey(secondKey)).dx, closeTo(x4, epsilon));

    await tester.pump(duration * 0.1);
    expect(tester.getTopLeft(find.byKey(secondKey)).dx, closeTo(x3, epsilon));

    await tester.pump(duration * 0.1);
    expect(tester.getTopLeft(find.byKey(secondKey)).dx, closeTo(x2, epsilon));

    await tester.pump(duration * 0.1);
    expect(tester.getTopLeft(find.byKey(secondKey)).dx, closeTo(x1, epsilon));

    await tester.pump(duration * 0.1);
    expect(tester.getTopLeft(find.byKey(secondKey)).dx, closeTo(x0, epsilon));

    // Below: show that a different pop Hero path is in fact taken after
    // a completed push transition.

    // Complete the pop transition and we're back to showing /.
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(firstKey)).dx, 4.0); // Card contents are inset by 4.0.

    // Push /twoInset and wait for the transition to finish.
    await tester.tap(find.text('twoInset'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(secondKey)).dx, 54.0);

    // Start the pop transition from /twoInset to /.
    await tester.tap(find.text('pop'));
    await tester.pump();

    // Now the firstKey widget is the flying hero widget and it starts
    // out lined up with the secondKey widget.
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(firstKey)).dx, 54.0);

    // x0-x4 are the top left x coordinates for the beginning 40% of
    // the incoming flight. Advance the outgoing flight to the same
    // place.
    await tester.pump(duration * 0.6);

    await tester.pump(duration * 0.1);
    expect(tester.getTopLeft(find.byKey(firstKey)).dx, isNot(closeTo(x4, epsilon)));

    await tester.pump(duration * 0.1);
    expect(tester.getTopLeft(find.byKey(firstKey)).dx, isNot(closeTo(x3, epsilon)));

    // At this point the flight path arcs do start to get pretty close so
    // there's no point in comparing them.
    await tester.pump(duration * 0.1);

    // After the remaining 40% of the incoming flight is complete, we
    // expect to end up where the outgoing flight started.
    await tester.pump(duration * 0.1);
    expect(tester.getTopLeft(find.byKey(firstKey)).dx, x0);
  });

  testWidgets('Can override flight shuttle', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: ListView(
          children: <Widget>[
            const Hero(tag: 'a', child: Text('foo')),
            Builder(builder: (BuildContext context) {
              return FlatButton(
                child: const Text('two'),
                onPressed: () => Navigator.push<void>(context, MaterialPageRoute<void>(
                  builder: (BuildContext context) {
                    return Material(
                      child: Hero(
                        tag: 'a',
                        child: const Text('bar'),
                        flightShuttleBuilder: (
                          BuildContext flightContext,
                          Animation<double> animation,
                          HeroFlightDirection flightDirection,
                          BuildContext fromHeroContext,
                          BuildContext toHeroContext,
                        ) {
                          return const Text('baz');
                        },
                      ),
                    );
                  },
                )),
              );
            }),
          ],
        ),
      ),
    ));

    await tester.tap(find.text('two'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('foo'), findsNothing);
    expect(find.text('bar'), findsNothing);
    expect(find.text('baz'), findsOneWidget);
  });

  testWidgets('Can override flight launch pads', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: ListView(
          children: <Widget>[
            Hero(
              tag: 'a',
              child: const Text('Batman'),
              placeholderBuilder: (BuildContext context, Widget child) {
                return const Text('Venom');
              },
            ),
            Builder(builder: (BuildContext context) {
              return FlatButton(
                child: const Text('two'),
                onPressed: () => Navigator.push<void>(context, MaterialPageRoute<void>(
                  builder: (BuildContext context) {
                    return Material(
                      child: Hero(
                        tag: 'a',
                        child: const Text('Wolverine'),
                        placeholderBuilder: (BuildContext context, Widget child) {
                          return const Text('Joker');
                        },
                      ),
                    );
                  },
                )),
              );
            }),
          ],
        ),
      ),
    ));

    await tester.tap(find.text('two'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('Batman'), findsNothing);
    // This shows up once but in the Hero because by default, the destination
    // Hero child is the widget in flight.
    expect(find.text('Wolverine'), findsOneWidget);
    expect(find.text('Venom'), findsOneWidget);
    expect(find.text('Joker'), findsOneWidget);
  });

  testWidgets('Heroes do not transition on back gestures by default', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        platform: TargetPlatform.iOS,
      ),
      routes: routes,
    ));

    expect(find.byKey(firstKey), isOnstage);
    expect(find.byKey(firstKey), isInCard);
    expect(find.byKey(secondKey), findsNothing);

    await tester.tap(find.text('two'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(firstKey), findsNothing);
    expect(find.byKey(secondKey), isOnstage);
    expect(find.byKey(secondKey), isInCard);

    final TestGesture  gesture = await tester.startGesture(const Offset(5.0, 200.0));
    await gesture.moveBy(const Offset(20.0, 0.0));
    await gesture.moveBy(const Offset(180.0, 0.0));
    await gesture.up();
    await tester.pump();

    await tester.pump();

    // Both Heroes exist and are seated in their normal parents.
    expect(find.byKey(firstKey), isOnstage);
    expect(find.byKey(firstKey), isInCard);
    expect(find.byKey(secondKey), isOnstage);
    expect(find.byKey(secondKey), isInCard);

    // To make sure the hero had all chances of starting.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(firstKey), isOnstage);
    expect(find.byKey(firstKey), isInCard);
    expect(find.byKey(secondKey), isOnstage);
    expect(find.byKey(secondKey), isInCard);
  });

  testWidgets('Heroes can transition on gesture in one frame', (WidgetTester tester) async {
    transitionFromUserGestures = true;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        platform: TargetPlatform.iOS,
      ),
      routes: routes,
    ));

    await tester.tap(find.text('two'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(firstKey), findsNothing);
    expect(find.byKey(secondKey), isOnstage);
    expect(find.byKey(secondKey), isInCard);

    final TestGesture gesture = await tester.startGesture(const Offset(5.0, 200.0));
    await gesture.moveBy(const Offset(200.0, 0.0));
    await tester.pump();

    // We're going to page 1 so page 1's Hero is lifted into flight.
    expect(find.byKey(firstKey), isOnstage);
    expect(find.byKey(firstKey), isNotInCard);
    expect(find.byKey(secondKey), findsNothing);

    // Move further along.
    await gesture.moveBy(const Offset(500.0, 0.0));
    await tester.pump();

    // Same results.
    expect(find.byKey(firstKey), isOnstage);
    expect(find.byKey(firstKey), isNotInCard);
    expect(find.byKey(secondKey), findsNothing);

    await gesture.up();
    // Finish transition.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Hero A is back in the card.
    expect(find.byKey(firstKey), isOnstage);
    expect(find.byKey(firstKey), isInCard);
    expect(find.byKey(secondKey), findsNothing);
  });

  testWidgets('Handles transitions when a non-default initial route is set', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      routes: routes,
      initialRoute: '/two',
    ));
    expect(find.text('two'), findsOneWidget);
  });

  testWidgets('Can push/pop on outer Navigator if nested Navigator contains Heroes', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/28042.

    const String heroTag = 'You are my hero!';
    final GlobalKey<NavigatorState> rootNavigator = GlobalKey();
    final GlobalKey<NavigatorState> nestedNavigator = GlobalKey();
    final Key nestedRouteHeroBottom = UniqueKey();
    final Key nestedRouteHeroTop = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: rootNavigator,
        home: Navigator(
          key: nestedNavigator,
          onGenerateRoute: (RouteSettings settings) {
            return MaterialPageRoute<void>(
              builder: (BuildContext context) {
                return Hero(
                  tag: heroTag,
                  child: Placeholder(
                    key: nestedRouteHeroBottom,
                  ),
                );
              }
            );
          },
        ),
      )
    );

    nestedNavigator.currentState.push(MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return Hero(
          tag: heroTag,
          child: Placeholder(
            key: nestedRouteHeroTop,
          ),
        );
      },
    ));
    await tester.pumpAndSettle();

    // Both heroes are in the tree, one is offstage
    expect(find.byKey(nestedRouteHeroTop), findsOneWidget);
    expect(find.byKey(nestedRouteHeroBottom), findsNothing);
    expect(find.byKey(nestedRouteHeroBottom, skipOffstage: false), findsOneWidget);

    rootNavigator.currentState.push(MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return const Text('Foo');
      },
    ));
    await tester.pumpAndSettle();

    expect(find.text('Foo'), findsOneWidget);
    // Both heroes are still in the tree, both are offstage.
    expect(find.byKey(nestedRouteHeroBottom), findsNothing);
    expect(find.byKey(nestedRouteHeroTop), findsNothing);
    expect(find.byKey(nestedRouteHeroBottom, skipOffstage: false), findsOneWidget);
    expect(find.byKey(nestedRouteHeroTop, skipOffstage: false), findsOneWidget);

    // Doesn't crash.
    expect(tester.takeException(), isNull);

    rootNavigator.currentState.pop();
    await tester.pumpAndSettle();

    expect(find.text('Foo'), findsNothing);
    // Both heroes are in the tree, one is offstage
    expect(find.byKey(nestedRouteHeroTop), findsOneWidget);
    expect(find.byKey(nestedRouteHeroBottom), findsNothing);
    expect(find.byKey(nestedRouteHeroBottom, skipOffstage: false), findsOneWidget);
  });

  testWidgets('Can hero from route in root Navigator to route in nested Navigator', (WidgetTester tester) async {
    const String heroTag = 'foo';
    final GlobalKey<NavigatorState> rootNavigator = GlobalKey();
    final Key smallContainer = UniqueKey();
    final Key largeContainer = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: rootNavigator,
        home: Center(
          child: Card(
            child: Hero(
              tag: heroTag,
              child: Container(
                key: largeContainer,
                color: Colors.red,
                height: 200.0,
                width: 200.0,
              ),
            ),
          ),
        ),
      ),
    );


    // The initial setup.
    expect(find.byKey(largeContainer), isOnstage);
    expect(find.byKey(largeContainer), isInCard);
    expect(find.byKey(smallContainer, skipOffstage: false), findsNothing);

    rootNavigator.currentState.push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Center(
            child: Card(
              child: Hero(
                tag: heroTag,
                child: Container(
                  key: smallContainer,
                  color: Colors.red,
                  height: 100.0,
                  width: 100.0,
                ),
              ),
            ),
          );
        }
      ),
    );
    await tester.pump();

    // The second route exists offstage.
    expect(find.byKey(largeContainer), isOnstage);
    expect(find.byKey(largeContainer), isInCard);
    expect(find.byKey(smallContainer, skipOffstage: false), isOffstage);
    expect(find.byKey(smallContainer, skipOffstage: false), isInCard);

    await tester.pump();

    // The hero started flying.
    expect(find.byKey(largeContainer), findsNothing);
    expect(find.byKey(smallContainer), isOnstage);
    expect(find.byKey(smallContainer), isNotInCard);

    await tester.pump(const Duration(milliseconds: 100));

    // The hero is in-flight.
    expect(find.byKey(largeContainer), findsNothing);
    expect(find.byKey(smallContainer), isOnstage);
    expect(find.byKey(smallContainer), isNotInCard);
    final Size size = tester.getSize(find.byKey(smallContainer));
    expect(size.height, greaterThan(100));
    expect(size.width, greaterThan(100));
    expect(size.height, lessThan(200));
    expect(size.width, lessThan(200));

    await tester.pumpAndSettle();

    // The transition has ended.
    expect(find.byKey(largeContainer), findsNothing);
    expect(find.byKey(smallContainer), isOnstage);
    expect(find.byKey(smallContainer), isInCard);
    expect(tester.getSize(find.byKey(smallContainer)), const Size(100,100));
  });

  testWidgets('Hero within a Hero, throws', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Hero(
            tag: 'a',
            child: Hero(
              tag: 'b',
              child: Text('Child of a Hero'),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('Hero within a Hero subtree, throws', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Container(
            child: const Hero(
              tag: 'a',
              child: Hero(
                tag: 'b',
                child: Text('Child of a Hero'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('Hero within a Hero subtree with Builder, throws', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Hero(
            tag: 'a',
            child: Builder(
              builder: (BuildContext context) {
                return const Hero(
                  tag: 'b',
                  child: Text('Child of a Hero'),
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(),isAssertionError);
  });

  testWidgets('Hero within a Hero subtree with LayoutBuilder, throws', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Hero(
            tag: 'a',
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return const Hero(
                  tag: 'b',
                  child: Text('Child of a Hero'),
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('Heroes fly on pushReplacement', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/28041.

    const String heroTag = 'foo';
    final GlobalKey<NavigatorState> navigator = GlobalKey();
    final Key smallContainer = UniqueKey();
    final Key largeContainer = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: Center(
          child: Card(
            child: Hero(
              tag: heroTag,
              child: Container(
                key: largeContainer,
                color: Colors.red,
                height: 200.0,
                width: 200.0,
              ),
            ),
          ),
        ),
      ),
    );

    // The initial setup.
    expect(find.byKey(largeContainer), isOnstage);
    expect(find.byKey(largeContainer), isInCard);
    expect(find.byKey(smallContainer, skipOffstage: false), findsNothing);

    navigator.currentState.pushReplacement(
      MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return Center(
              child: Card(
                child: Hero(
                  tag: heroTag,
                  child: Container(
                    key: smallContainer,
                    color: Colors.red,
                    height: 100.0,
                    width: 100.0,
                  ),
                ),
              ),
            );
          }
      ),
    );
    await tester.pump();

    // The second route exists offstage.
    expect(find.byKey(largeContainer), isOnstage);
    expect(find.byKey(largeContainer), isInCard);
    expect(find.byKey(smallContainer, skipOffstage: false), isOffstage);
    expect(find.byKey(smallContainer, skipOffstage: false), isInCard);

    await tester.pump();

    // The hero started flying.
    expect(find.byKey(largeContainer), findsNothing);
    expect(find.byKey(smallContainer), isOnstage);
    expect(find.byKey(smallContainer), isNotInCard);

    await tester.pump(const Duration(milliseconds: 100));

    // The hero is in-flight.
    expect(find.byKey(largeContainer), findsNothing);
    expect(find.byKey(smallContainer), isOnstage);
    expect(find.byKey(smallContainer), isNotInCard);
    final Size size = tester.getSize(find.byKey(smallContainer));
    expect(size.height, greaterThan(100));
    expect(size.width, greaterThan(100));
    expect(size.height, lessThan(200));
    expect(size.width, lessThan(200));

    await tester.pumpAndSettle();

    // The transition has ended.
    expect(find.byKey(largeContainer), findsNothing);
    expect(find.byKey(smallContainer), isOnstage);
    expect(find.byKey(smallContainer), isInCard);
    expect(tester.getSize(find.byKey(smallContainer)), const Size(100,100));
  });
}

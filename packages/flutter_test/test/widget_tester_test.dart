// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/test.dart' as test_package;
import 'package:test/src/frontend/async_matcher.dart' show AsyncMatcher;

const List<Widget> fooBarTexts = const <Text>[
  const Text('foo', textDirection: TextDirection.ltr),
  const Text('bar', textDirection: TextDirection.ltr),
];

void main() {
  group('expectLater', () {
    testWidgets('completes when matcher completes', (WidgetTester tester) async {
      final Completer<void> completer = new Completer<void>();
      final Future<void> future = expectLater(null, new FakeMatcher(completer));
      String value;
      future.then((void _) {
        value = '123';
      });
      test_package.expect(value, isNull);
      completer.complete();
      test_package.expect(value, isNull);
      await future;
      await tester.pump();
      test_package.expect(value, '123');
    });
  });

  group('findsOneWidget', () {
    testWidgets('finds exactly one widget', (WidgetTester tester) async {
      await tester.pumpWidget(const Text('foo', textDirection: TextDirection.ltr));
      expect(find.text('foo'), findsOneWidget);
    });

    testWidgets('fails with a descriptive message', (WidgetTester tester) async {
      TestFailure failure;
      try {
        expect(find.text('foo', skipOffstage: false), findsOneWidget);
      } catch (e) {
        failure = e;
      }

      expect(failure, isNotNull);
      final String message = failure.message;
      expect(message, contains('Expected: exactly one matching node in the widget tree\n'));
      expect(message, contains('Actual: ?:<zero widgets with text "foo">\n'));
      expect(message, contains('Which: means none were found but one was expected\n'));
    });
  });

  group('findsNothing', () {
    testWidgets('finds no widgets', (WidgetTester tester) async {
      expect(find.text('foo'), findsNothing);
    });

    testWidgets('fails with a descriptive message', (WidgetTester tester) async {
      await tester.pumpWidget(const Text('foo', textDirection: TextDirection.ltr));

      TestFailure failure;
      try {
        expect(find.text('foo', skipOffstage: false), findsNothing);
      } catch (e) {
        failure = e;
      }

      expect(failure, isNotNull);
      final String message = failure.message;

      expect(message, contains('Expected: no matching nodes in the widget tree\n'));
      expect(message, contains('Actual: ?:<exactly one widget with text "foo": Text("foo", textDirection: ltr)>\n'));
      expect(message, contains('Which: means one was found but none were expected\n'));
    });

    testWidgets('fails with a descriptive message when skipping', (WidgetTester tester) async {
      await tester.pumpWidget(const Text('foo', textDirection: TextDirection.ltr));

      TestFailure failure;
      try {
        expect(find.text('foo'), findsNothing);
      } catch (e) {
        failure = e;
      }

      expect(failure, isNotNull);
      final String message = failure.message;

      expect(message, contains('Expected: no matching nodes in the widget tree\n'));
      expect(message, contains('Actual: ?:<exactly one widget with text "foo" (ignoring offstage widgets): Text("foo", textDirection: ltr)>\n'));
      expect(message, contains('Which: means one was found but none were expected\n'));
    });

    testWidgets('pumping', (WidgetTester tester) async {
      await tester.pumpWidget(const Text('foo', textDirection: TextDirection.ltr));
      int count;

      final AnimationController test = new AnimationController(
        duration: const Duration(milliseconds: 5100),
        vsync: tester,
      );
      count = await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(count, 1); // it always pumps at least one frame

      test.forward(from: 0.0);
      count = await tester.pumpAndSettle(const Duration(seconds: 1));
      // 1 frame at t=0, starting the animation
      // 1 frame at t=1
      // 1 frame at t=2
      // 1 frame at t=3
      // 1 frame at t=4
      // 1 frame at t=5
      // 1 frame at t=6, ending the animation
      expect(count, 7);

      test.forward(from: 0.0);
      await tester.pump(); // starts the animation
      count = await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(count, 6);

      test.forward(from: 0.0);
      await tester.pump(); // starts the animation
      await tester.pump(); // has no effect
      count = await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(count, 6);
    });
  });

  group('find.byElementPredicate', () {
    testWidgets('fails with a custom description in the message', (WidgetTester tester) async {
      await tester.pumpWidget(const Text('foo', textDirection: TextDirection.ltr));

      const String customDescription = 'custom description';
      TestFailure failure;
      try {
        expect(find.byElementPredicate((_) => false, description: customDescription), findsOneWidget);
      } catch (e) {
        failure = e;
      }

      expect(failure, isNotNull);
      expect(failure.message, contains('Actual: ?:<zero widgets with $customDescription'));
    });
  });

  group('find.byWidgetPredicate', () {
    testWidgets('fails with a custom description in the message', (WidgetTester tester) async {
      await tester.pumpWidget(const Text('foo', textDirection: TextDirection.ltr));

      const String customDescription = 'custom description';
      TestFailure failure;
      try {
        expect(find.byWidgetPredicate((_) => false, description: customDescription), findsOneWidget);
      } catch (e) {
        failure = e;
      }

      expect(failure, isNotNull);
      expect(failure.message, contains('Actual: ?:<zero widgets with $customDescription'));
    });
  });

  group('find.descendant', () {
    testWidgets('finds one descendant', (WidgetTester tester) async {
      await tester.pumpWidget(new Row(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new Column(children: fooBarTexts),
        ],
      ));

      expect(find.descendant(
        of: find.widgetWithText(Row, 'foo'),
        matching: find.text('bar'),
      ), findsOneWidget);
    });

    testWidgets('finds two descendants with different ancestors', (WidgetTester tester) async {
      await tester.pumpWidget(new Row(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new Column(children: fooBarTexts),
          new Column(children: fooBarTexts),
        ],
      ));

      expect(find.descendant(
        of: find.widgetWithText(Column, 'foo'),
        matching: find.text('bar'),
      ), findsNWidgets(2));
    });

    testWidgets('fails with a descriptive message', (WidgetTester tester) async {
      await tester.pumpWidget(new Row(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new Column(children: const <Text>[const Text('foo', textDirection: TextDirection.ltr)]),
          const Text('bar', textDirection: TextDirection.ltr),
        ],
      ));

      TestFailure failure;
      try {
        expect(find.descendant(
          of: find.widgetWithText(Column, 'foo'),
          matching: find.text('bar')
        ), findsOneWidget);
      } catch (e) {
        failure = e;
      }

      expect(failure, isNotNull);
      expect(
        failure.message,
        contains(
          'Actual: ?:<zero widgets with text "bar" that has ancestor(s) with type "Column" which is an ancestor of text "foo"',
        ),
      );
    });
  });

  group('find.ancestor', () {
    testWidgets('finds one ancestor', (WidgetTester tester) async {
      await tester.pumpWidget(new Row(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new Column(children: fooBarTexts),
        ],
      ));

      expect(find.ancestor(
        of: find.text('bar'),
        matching: find.widgetWithText(Row, 'foo'),
      ), findsOneWidget);
    });

    testWidgets('finds two matching ancestors, one descendant', (WidgetTester tester) async {
      await tester.pumpWidget(
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new Row(
            children: <Widget>[
              new Row(children: fooBarTexts),
            ],
          ),
        ),
      );

      expect(find.ancestor(
        of: find.text('bar'),
        matching: find.byType(Row),
      ), findsNWidgets(2));
    });

    testWidgets('fails with a descriptive message', (WidgetTester tester) async {
      await tester.pumpWidget(new Row(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new Column(children: const <Text>[const Text('foo', textDirection: TextDirection.ltr)]),
          const Text('bar', textDirection: TextDirection.ltr),
        ],
      ));

      TestFailure failure;
      try {
        expect(find.ancestor(
          of: find.text('bar'),
          matching: find.widgetWithText(Column, 'foo'),
        ), findsOneWidget);
      } catch (e) {
        failure = e;
      }

      expect(failure, isNotNull);
      expect(
        failure.message,
        contains(
          'Actual: ?:<zero widgets with type "Column" which is an ancestor of text "foo" which is an ancestor of text "bar"',
        ),
      );
    });

    testWidgets('Root not matched by default', (WidgetTester tester) async {
      await tester.pumpWidget(new Row(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new Column(children: fooBarTexts),
        ],
      ));

      expect(find.ancestor(
        of: find.byType(Column),
        matching: find.widgetWithText(Column, 'foo'),
      ), findsNothing);
    });

    testWidgets('Match the root', (WidgetTester tester) async {
      await tester.pumpWidget(new Row(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new Column(children: fooBarTexts),
        ],
      ));

      expect(find.descendant(
        of: find.byType(Column),
        matching: find.widgetWithText(Column, 'foo'),
        matchRoot: true,
      ), findsOneWidget);
    });
  });

  group('pageBack', (){
    testWidgets('fails when there are no back buttons', (WidgetTester tester) async {
      await tester.pumpWidget(new Container());

      expect(
        expectAsync0(tester.pageBack),
        throwsA(const isInstanceOf<TestFailure>()),
      );
    });

    testWidgets('successfully taps material back buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        new MaterialApp(
          home: new Center(
            child: new Builder(
              builder: (BuildContext context) {
                return new RaisedButton(
                  child: const Text('Next'),
                  onPressed: () {
                    Navigator.push<void>(context, new MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return new Scaffold(
                          appBar: new AppBar(
                            title: const Text('Page 2'),
                          ),
                        );
                      },
                    ));
                  },
                );
              } ,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Page 2'), findsNothing);
    });

    testWidgets('successfully taps cupertino back buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        new MaterialApp(
          home: new Center(
            child: new Builder(
              builder: (BuildContext context) {
                return new CupertinoButton(
                  child: const Text('Next'),
                  onPressed: () {
                    Navigator.push<void>(context, new CupertinoPageRoute<void>(
                      builder: (BuildContext context) {
                        return new CupertinoPageScaffold(
                          navigationBar: const CupertinoNavigationBar(
                            middle: const Text('Page 2'),
                          ),
                          child: new Container(),
                        );
                      },
                    ));
                  },
                );
              } ,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Page 2'), findsNothing);
    });
  });

  testWidgets('hasRunningAnimations control test', (WidgetTester tester) async {
    final AnimationController controller = new AnimationController(
      duration: const Duration(seconds: 1),
      vsync: const TestVSync()
    );
    expect(tester.hasRunningAnimations, isFalse);
    controller.forward();
    expect(tester.hasRunningAnimations, isTrue);
    controller.stop();
    expect(tester.hasRunningAnimations, isFalse);
    controller.forward();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('pumpAndSettle control test', (WidgetTester tester) async {
    final AnimationController controller = new AnimationController(
      duration: const Duration(minutes: 525600),
      vsync: const TestVSync()
    );
    expect(await tester.pumpAndSettle(), 1);
    controller.forward();
    try {
      await tester.pumpAndSettle();
      expect(true, isFalse);
    } catch (e) {
      expect(e, isFlutterError);
    }
    controller.stop();
    expect(await tester.pumpAndSettle(), 1);
    controller.duration = const Duration(seconds: 1);
    controller.forward();
    expect(await tester.pumpAndSettle(const Duration(milliseconds: 300)), 5); // 0, 300, 600, 900, 1200ms
  });

  group('runAsync', () {
    testWidgets('works with no async calls', (WidgetTester tester) async {
      String value;
      await tester.runAsync(() async {
        value = '123';
      });
      expect(value, '123');
    });

    testWidgets('works with real async calls', (WidgetTester tester) async {
      final StringBuffer buf = new StringBuffer('1');
      await tester.runAsync(() async {
        buf.write('2');
        await Directory.current.stat();
        buf.write('3');
      });
      buf.write('4');
      expect(buf.toString(), '1234');
    });

    testWidgets('propagates return values', (WidgetTester tester) async {
      final String value = await tester.runAsync<String>(() async {
        return '123';
      });
      expect(value, '123');
    });

    testWidgets('reports errors via framework', (WidgetTester tester) async {
      final String value = await tester.runAsync<String>(() async {
        throw new ArgumentError();
      });
      expect(value, isNull);
      expect(tester.takeException(), isArgumentError);
    });

    testWidgets('disallows re-entry', (WidgetTester tester) async {
      final Completer<void> completer = new Completer<void>();
      tester.runAsync<void>(() => completer.future);
      expect(() => tester.runAsync(() async {}), throwsA(const isInstanceOf<TestFailure>()));
      completer.complete();
    });

    testWidgets('maintains existing zone values', (WidgetTester tester) async {
      final Object key = new Object();
      await runZoned(() {
        expect(Zone.current[key], 'abczed');
        return tester.runAsync<String>(() async {
          expect(Zone.current[key], 'abczed');
        });
      }, zoneValues: <dynamic, dynamic>{
        key: 'abczed',
      });
    });
  });
}

class FakeMatcher extends AsyncMatcher {
  FakeMatcher(this.completer);

  final Completer<void> completer;

  @override
  Future<String> matchAsync(dynamic object) {
    return completer.future.then<String>((void _) {
      return object?.toString();
    });
  }

  @override
  Description describe(Description description) => description.add('--fake--');
}

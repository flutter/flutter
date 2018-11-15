// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_api/test_api.dart' as test_package;
import 'package:test_api/src/frontend/async_matcher.dart' show AsyncMatcher;

const List<Widget> fooBarTexts = <Text>[
  Text('foo', textDirection: TextDirection.ltr),
  Text('bar', textDirection: TextDirection.ltr),
];

void main() {
  group('expectLater', () {
    testWidgets('completes when matcher completes', (WidgetTester tester) async {
      final Completer<void> completer = Completer<void>();
      final Future<void> future = expectLater(null, FakeMatcher(completer));
      String result;
      future.then<void>((void value) {
        result = '123';
      });
      test_package.expect(result, isNull);
      completer.complete();
      test_package.expect(result, isNull);
      await future;
      await tester.pump();
      test_package.expect(result, '123');
    });

    testWidgets('respects the skip flag', (WidgetTester tester) async {
      final Completer<void> completer = Completer<void>();
      final Future<void> future = expectLater(null, FakeMatcher(completer), skip: 'testing skip');
      bool completed = false;
      future.then<void>((_) {
        completed = true;
      });
      test_package.expect(completed, isFalse);
      await future;
      test_package.expect(completed, isTrue);
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

      final AnimationController test = AnimationController(
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
      await tester.pumpWidget(Row(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          Column(children: fooBarTexts),
        ],
      ));

      expect(find.descendant(
        of: find.widgetWithText(Row, 'foo'),
        matching: find.text('bar'),
      ), findsOneWidget);
    });

    testWidgets('finds two descendants with different ancestors', (WidgetTester tester) async {
      await tester.pumpWidget(Row(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          Column(children: fooBarTexts),
          Column(children: fooBarTexts),
        ],
      ));

      expect(find.descendant(
        of: find.widgetWithText(Column, 'foo'),
        matching: find.text('bar'),
      ), findsNWidgets(2));
    });

    testWidgets('fails with a descriptive message', (WidgetTester tester) async {
      await tester.pumpWidget(Row(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          Column(children: const <Text>[Text('foo', textDirection: TextDirection.ltr)]),
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
      await tester.pumpWidget(Row(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          Column(children: fooBarTexts),
        ],
      ));

      expect(find.ancestor(
        of: find.text('bar'),
        matching: find.widgetWithText(Row, 'foo'),
      ), findsOneWidget);
    });

    testWidgets('finds two matching ancestors, one descendant', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: <Widget>[
              Row(children: fooBarTexts),
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
      await tester.pumpWidget(Row(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          Column(children: const <Text>[Text('foo', textDirection: TextDirection.ltr)]),
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
      await tester.pumpWidget(Row(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          Column(children: fooBarTexts),
        ],
      ));

      expect(find.ancestor(
        of: find.byType(Column),
        matching: find.widgetWithText(Column, 'foo'),
      ), findsNothing);
    });

    testWidgets('Match the root', (WidgetTester tester) async {
      await tester.pumpWidget(Row(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          Column(children: fooBarTexts),
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
      await tester.pumpWidget(Container());

      expect(
        expectAsync0(tester.pageBack),
        throwsA(isInstanceOf<TestFailure>()),
      );
    });

    testWidgets('successfully taps material back buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: Builder(
              builder: (BuildContext context) {
                return RaisedButton(
                  child: const Text('Next'),
                  onPressed: () {
                    Navigator.push<void>(context, MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return Scaffold(
                          appBar: AppBar(
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
        MaterialApp(
          home: Center(
            child: Builder(
              builder: (BuildContext context) {
                return CupertinoButton(
                  child: const Text('Next'),
                  onPressed: () {
                    Navigator.push<void>(context, CupertinoPageRoute<void>(
                      builder: (BuildContext context) {
                        return CupertinoPageScaffold(
                          navigationBar: const CupertinoNavigationBar(
                            middle: Text('Page 2'),
                          ),
                          child: Container(),
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
    final AnimationController controller = AnimationController(
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
    final AnimationController controller = AnimationController(
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
      final StringBuffer buf = StringBuffer('1');
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
        throw ArgumentError();
      });
      expect(value, isNull);
      expect(tester.takeException(), isArgumentError);
    });

    testWidgets('disallows re-entry', (WidgetTester tester) async {
      final Completer<void> completer = Completer<void>();
      tester.runAsync<void>(() => completer.future);
      expect(() => tester.runAsync(() async {}), throwsA(isInstanceOf<TestFailure>()));
      completer.complete();
    });

    testWidgets('maintains existing zone values', (WidgetTester tester) async {
      final Object key = Object();
      await runZoned<Future<void>>(() {
        expect(Zone.current[key], 'abczed');
        return tester.runAsync<void>(() async {
          expect(Zone.current[key], 'abczed');
        });
      }, zoneValues: <dynamic, dynamic>{
        key: 'abczed',
      });
    });
  });

  testWidgets('showKeyboard can be called twice', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(),
          ),
        ),
      ),
    );
    await tester.showKeyboard(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.showKeyboard(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.showKeyboard(find.byType(TextField));
    await tester.showKeyboard(find.byType(TextField));
    await tester.pump();
  });

  group('getSemanticsData', () {
    testWidgets('throws when there are no semantics', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('hello'),
          ),
        ),
      );

      expect(() => tester.getSemantics(find.text('hello')),
        throwsA(isInstanceOf<StateError>()));
    });

    testWidgets('throws when there are multiple results from the finder', (WidgetTester tester) async {
      final SemanticsHandle semanticsHandle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: const <Widget>[
                Text('hello'),
                Text('hello'),
              ],
            ),
          ),
        ),
      );

      expect(() => tester.getSemantics(find.text('hello')),
          throwsA(isInstanceOf<StateError>()));
      semanticsHandle.dispose();
    });

    testWidgets('Returns the correct SemanticsData', (WidgetTester tester) async {
      final SemanticsHandle semanticsHandle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              child: OutlineButton(
                  onPressed: () {},
                  child: const Text('hello')
              ),
            ),
          ),
        ),
      );

      final SemanticsNode node = tester.getSemantics(find.text('hello'));
      final SemanticsData semantics = node.getSemanticsData();
      expect(semantics.label, 'hello');
      expect(semantics.hasAction(SemanticsAction.tap), true);
      expect(semantics.hasFlag(SemanticsFlag.isButton), true);
      semanticsHandle.dispose();
    });

    testWidgets('Returns merged SemanticsData', (WidgetTester tester) async {
      final SemanticsHandle semanticsHandle = tester.ensureSemantics();
      const Key key = Key('test');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Semantics(
              label: 'A',
              child: Semantics(
                label: 'B',
                child: Semantics(
                  key: key,
                  label: 'C',
                  child: Container(),
                ),
              ),
            )
          ),
        ),
      );

      final SemanticsNode node = tester.getSemantics(find.byKey(key));
      final SemanticsData semantics = node.getSemanticsData();
      expect(semantics.label, 'A\nB\nC');
      semanticsHandle.dispose();
    });
  });

  group('ensureVisible', () {
    testWidgets('scrolls to make widget visible', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 20,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int i) => ListTile(title: Text('Item $i')),
           ),
         ),
        ),
      );

      // Make sure widget isn't on screen
      expect(find.text('Item 15', skipOffstage: true), findsNothing);

      await tester.ensureVisible(find.text('Item 15', skipOffstage: false));
      await tester.pumpAndSettle();

      expect(find.text('Item 15', skipOffstage: true), findsOneWidget);
    });
  });
}

class FakeMatcher extends AsyncMatcher {
  FakeMatcher(this.completer);

  final Completer<void> completer;

  @override
  Future<String> matchAsync(dynamic object) {
    return completer.future.then<String>((void value) {
      return object?.toString();
    });
  }

  @override
  Description describe(Description description) => description.add('--fake--');
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'navigator_utils.dart';

void main() {
  final List<bool> calls = <bool>[];
  setUp(() {
    // Initialize to false. Because this uses a static boolean internally, it
    // is not reset between tests or calls to pumpWidget. Explicitly setting
    // it to false before each test makes them behave deterministically.
    SystemNavigator.setFrameworkHandlesBack(false);
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'SystemNavigator.setFrameworkHandlesBack') {
          expect(methodCall.arguments, isA<bool>());
          calls.add(methodCall.arguments as bool);
        }
        return;
      });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    SystemNavigator.setFrameworkHandlesBack(true);
  });

  testWidgets('toggling popEnabled on root route allows/prevents backs', (WidgetTester tester) async {
    bool popEnabled = false;
    late StateSetter setState;
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/',
        routes: <String, WidgetBuilder>{
          '/': (BuildContext buildContext) => Scaffold(
            body: StatefulBuilder(
              builder: (BuildContext buildContext, StateSetter stateSetter) {
                context = buildContext;
                setState = stateSetter;
                return PopScope(
                  popEnabled: popEnabled,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('Home/PopScope Page'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        },
      ),
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      expect(calls, hasLength(1));
    }
    final int lastCallsLength = calls.length;
    expect(ModalRoute.of(context)!.popEnabled(), RoutePopDisposition.doNotPop);

    setState(() {
      popEnabled = true;
    });
    await tester.pump();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      expect(calls, hasLength(greaterThan(lastCallsLength)));
      expect(calls.last, isFalse);
    }
    expect(ModalRoute.of(context)!.popEnabled(), RoutePopDisposition.bubble);
  },
    variant: TargetPlatformVariant.all(),
  );

  testWidgets('toggling popEnabled on secondary route allows/prevents backs', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
    bool popEnabled = true;
    late StateSetter setState;
    late BuildContext homeContext;
    late BuildContext oneContext;
    late bool lastPopSuccess;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        initialRoute: '/',
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) {
            homeContext = context;
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text('Home Page'),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/one');
                      },
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ),
            );
          },
          '/one': (BuildContext context) => Scaffold(
            body: StatefulBuilder(
              builder: (BuildContext context, StateSetter stateSetter) {
                oneContext = context;
                setState = stateSetter;
                return PopScope(
                  popEnabled: popEnabled,
                  onPopped: (bool didPop) {
                    lastPopSuccess = didPop;
                  },
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('PopScope Page'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        },
      ),
    );

    expect(find.text('Home Page'), findsOneWidget);
    expect(ModalRoute.of(homeContext)!.popEnabled(), RoutePopDisposition.bubble);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      expect(calls, hasLength(0));
    }
    int lastCallsLength = calls.length;

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('PopScope Page'), findsOneWidget);
    expect(find.text('Home Page'), findsNothing);
    expect(ModalRoute.of(oneContext)!.popEnabled(), RoutePopDisposition.pop);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      expect(calls, hasLength(greaterThan(lastCallsLength)));
      expect(calls.last, isTrue);
    }
    lastCallsLength = calls.length;

    // When popEnabled is true, can use pop to go back.
    nav.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(lastPopSuccess, true);
    expect(find.text('Home Page'), findsOneWidget);
    expect(find.text('PopScope Page'), findsNothing);
    expect(ModalRoute.of(homeContext)!.popEnabled(), RoutePopDisposition.bubble);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      expect(calls, hasLength(greaterThan(lastCallsLength)));
      expect(calls.last, isFalse);
    }
    lastCallsLength = calls.length;

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('PopScope Page'), findsOneWidget);
    expect(find.text('Home Page'), findsNothing);
    expect(ModalRoute.of(oneContext)!.popEnabled(), RoutePopDisposition.pop);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      expect(calls, hasLength(greaterThan(lastCallsLength)));
      expect(calls.last, isTrue);
    }
    lastCallsLength = calls.length;

    // When popEnabled is true, can use system back to go back.
    await simulateSystemBack();
    await tester.pumpAndSettle();
    expect(lastPopSuccess, true);
    expect(find.text('Home Page'), findsOneWidget);
    expect(find.text('PopScope Page'), findsNothing);
    expect(ModalRoute.of(homeContext)!.popEnabled(), RoutePopDisposition.bubble);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      expect(calls, hasLength(greaterThan(lastCallsLength)));
      expect(calls.last, isFalse);
    }
    lastCallsLength = calls.length;

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('PopScope Page'), findsOneWidget);
    expect(find.text('Home Page'), findsNothing);
    expect(ModalRoute.of(oneContext)!.popEnabled(), RoutePopDisposition.pop);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      expect(calls, hasLength(greaterThan(lastCallsLength)));
      expect(calls.last, isTrue);
    }
    lastCallsLength = calls.length;

    setState(() {
      popEnabled = false;
    });
    await tester.pump();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      expect(calls, hasLength(lastCallsLength));
    }

    // When popEnabled is false, can't use pop to go back.
    nav.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(lastPopSuccess, false);
    expect(find.text('PopScope Page'), findsOneWidget);
    expect(find.text('Home Page'), findsNothing);
    expect(ModalRoute.of(oneContext)!.popEnabled(), RoutePopDisposition.doNotPop);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      expect(calls, hasLength(lastCallsLength));
    }

    // When popEnabled is false, can't use system back to go back.
    await simulateSystemBack();
    await tester.pumpAndSettle();
    expect(lastPopSuccess, false);
    expect(find.text('PopScope Page'), findsOneWidget);
    expect(find.text('Home Page'), findsNothing);
    expect(ModalRoute.of(oneContext)!.popEnabled(), RoutePopDisposition.doNotPop);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      expect(calls, hasLength(lastCallsLength));
    }

    // Toggle popEnabled back to true and back works again.
    setState(() {
      popEnabled = true;
    });
    await tester.pump();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      expect(calls, hasLength(lastCallsLength));
    }

    nav.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(lastPopSuccess, true);
    expect(find.text('Home Page'), findsOneWidget);
    expect(find.text('PopScope Page'), findsNothing);
    expect(ModalRoute.of(homeContext)!.popEnabled(), RoutePopDisposition.bubble);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      expect(calls, hasLength(greaterThan(lastCallsLength)));
      expect(calls.last, isFalse);
    }
    lastCallsLength = calls.length;

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('PopScope Page'), findsOneWidget);
    expect(find.text('Home Page'), findsNothing);
    expect(ModalRoute.of(oneContext)!.popEnabled(), RoutePopDisposition.pop);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      expect(calls, hasLength(greaterThan(lastCallsLength)));
      expect(calls.last, isTrue);
    }
    lastCallsLength = calls.length;

    await simulateSystemBack();
    await tester.pumpAndSettle();
    expect(lastPopSuccess, true);
    expect(find.text('Home Page'), findsOneWidget);
    expect(find.text('PopScope Page'), findsNothing);
    expect(ModalRoute.of(homeContext)!.popEnabled(), RoutePopDisposition.bubble);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      expect(calls.last, isFalse);
      expect(calls, hasLength(greaterThan(lastCallsLength)));
    }
  },
    variant: TargetPlatformVariant.all(),
  );

  testWidgets('removing PopScope from the tree removes its effect on navigation', (WidgetTester tester) async {
    bool usePopScope = true;
    late StateSetter setState;
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/',
        routes: <String, WidgetBuilder>{
          '/': (BuildContext buildContext) => Scaffold(
            body: StatefulBuilder(
              builder: (BuildContext buildContext, StateSetter stateSetter) {
                context = buildContext;
                setState = stateSetter;
                const Widget child = Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('Home/PopScope Page'),
                    ],
                  ),
                );
                if (!usePopScope) {
                  return child;
                }
                return const PopScope(
                  popEnabled: false,
                  child: child,
                );
              },
            ),
          ),
        },
      ),
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      expect(calls, hasLength(1));
      expect(calls.last, isTrue);
    }
    final int lastCallsLength = calls.length;
    expect(ModalRoute.of(context)!.popEnabled(), RoutePopDisposition.doNotPop);

    setState(() {
      usePopScope = false;
    });
    await tester.pump();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      expect(calls, hasLength(greaterThan(lastCallsLength)));
      expect(calls.last, isFalse);
    }
    expect(ModalRoute.of(context)!.popEnabled(), RoutePopDisposition.bubble);
  },
    variant: TargetPlatformVariant.all(),
  );
}

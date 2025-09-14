// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CupertinoPageRouteWithDynamicTitle', () {
    testWidgets('creates route with dynamic title', (WidgetTester tester) async {
      final ValueNotifier<String?> titleNotifier = ValueNotifier<String?>('Initial Title');
      addTearDown(titleNotifier.dispose);

      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (BuildContext context) => CupertinoButton(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRouteWithDynamicTitle<void>(
                    builder: (BuildContext context) => const CupertinoPageScaffold(
                      navigationBar: CupertinoNavigationBar(middle: Text('Test Page')),
                      child: Center(child: Text('Page Content')),
                    ),
                    titleListenable: titleNotifier,
                  ),
                );
              },
              child: const Text('Push Route'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Push Route'));
      await tester.pumpAndSettle();

      expect(find.text('Page Content'), findsOneWidget);
      // Check that the navigation bar shows the title
      expect(find.byType(CupertinoNavigationBar), findsOneWidget);
    });

    testWidgets('updates title dynamically', (WidgetTester tester) async {
      final ValueNotifier<String?> titleNotifier = ValueNotifier<String?>('Initial Title');
      addTearDown(titleNotifier.dispose);

      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (BuildContext context) => CupertinoButton(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRouteWithDynamicTitle<void>(
                    builder: (BuildContext context) => const CupertinoPageScaffold(
                      navigationBar: CupertinoNavigationBar(middle: Text('Test Page')),
                      child: Center(child: Text('Page Content')),
                    ),
                    titleListenable: titleNotifier,
                  ),
                );
              },
              child: const Text('Push Route'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Push Route'));
      await tester.pumpAndSettle();

      // Check that the navigation bar is present
      expect(find.byType(CupertinoNavigationBar), findsOneWidget);

      // Update the title
      titleNotifier.value = 'Updated Title';
      await tester.pump();

      // Check that the navigation bar is still present after title update
      expect(find.byType(CupertinoNavigationBar), findsOneWidget);
    });

    testWidgets('notifies neighboring routes when title changes', (WidgetTester tester) async {
      final ValueNotifier<String?> firstTitleNotifier = ValueNotifier<String?>('First Page');
      final ValueNotifier<String?> secondTitleNotifier = ValueNotifier<String?>('Second Page');
      addTearDown(() {
        firstTitleNotifier.dispose();
        secondTitleNotifier.dispose();
      });

      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (BuildContext context) => CupertinoButton(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRouteWithDynamicTitle<void>(
                    builder: (BuildContext context) => CupertinoPageScaffold(
                      navigationBar: const CupertinoNavigationBar(middle: Text('First Page')),
                      child: Center(
                        child: CupertinoButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              CupertinoPageRouteWithDynamicTitle<void>(
                                builder: (BuildContext context) => const CupertinoPageScaffold(
                                  navigationBar: CupertinoNavigationBar(
                                    middle: Text('Second Page'),
                                  ),
                                  child: Center(child: Text('Second Page Content')),
                                ),
                                titleListenable: secondTitleNotifier,
                              ),
                            );
                          },
                          child: const Text('Push Second Route'),
                        ),
                      ),
                    ),
                    titleListenable: firstTitleNotifier,
                  ),
                );
              },
              child: const Text('Push First Route'),
            ),
          ),
        ),
      );

      // Push first route
      await tester.tap(find.text('Push First Route'));
      await tester.pumpAndSettle();

      // Push second route
      await tester.tap(find.text('Push Second Route'));
      await tester.pumpAndSettle();

      // Verify initial state
      final Finder backButton = find.byType(CupertinoNavigationBarBackButton);
      expect(backButton, findsOneWidget);
      expect(find.descendant(of: backButton, matching: find.text('First Page')), findsOneWidget);
      expect(find.text('Second Page'), findsOneWidget);

      // Update first route title (keep it short to avoid "Back" label)
      firstTitleNotifier.value = 'Updated';
      await tester.pumpAndSettle();

      // The second route should now show the updated first page title in its back button.
      expect(find.descendant(of: backButton, matching: find.text('Updated')), findsOneWidget);
      expect(find.descendant(of: backButton, matching: find.text('First Page')), findsNothing);
    });

    testWidgets('disposes listener when route is disposed', (WidgetTester tester) async {
      final ValueNotifier<String?> titleNotifier = ValueNotifier<String?>('Initial Title');
      addTearDown(titleNotifier.dispose);
      int listenerCallCount = 0;

      titleNotifier.addListener(() {
        listenerCallCount++;
      });

      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (BuildContext context) => CupertinoButton(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRouteWithDynamicTitle<void>(
                    builder: (BuildContext context) => const CupertinoPageScaffold(
                      navigationBar: CupertinoNavigationBar(middle: Text('Test Page')),
                      child: Center(child: Text('Page Content')),
                    ),
                    titleListenable: titleNotifier,
                  ),
                );
              },
              child: const Text('Push Route'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Push Route'));
      await tester.pumpAndSettle();

      // Pop the route
      await tester.tap(find.byType(CupertinoNavigationBarBackButton));
      await tester.pumpAndSettle();

      // Update the title - should not trigger the route's listener since it's disposed
      titleNotifier.value = 'Updated Title';
      await tester.pump();

      // The listener should only be called once (from the direct addListener above)
      expect(listenerCallCount, equals(1));
    });
  });

  group('Route.changedInternalState with notifyNeighbors', () {
    testWidgets('notifies neighboring routes when called with notifyNeighbors=true', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<String?> titleNotifier = ValueNotifier<String?>('Initial Title');
      addTearDown(titleNotifier.dispose);
      bool didChangePreviousCalled = false;
      bool didChangeNextCalled = false;

      // Create a custom route that tracks when didChangePrevious/didChangeNext are called
      final _TestRoute customRoute = _TestRoute(
        titleListenable: titleNotifier,
        onDidChangePrevious: () => didChangePreviousCalled = true,
        onDidChangeNext: () => didChangeNextCalled = true,
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (BuildContext context) => CupertinoButton(
              onPressed: () {
                Navigator.push(context, customRoute);
              },
              child: const Text('Push Route'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Push Route'));
      await tester.pumpAndSettle();

      // Reset flags
      didChangePreviousCalled = false;
      didChangeNextCalled = false;

      // Call changedInternalState with notifyNeighbors=true
      customRoute.changedInternalState(notifyNeighbors: true);
      await tester.pump();

      // Since this is the only route, no neighbors should be notified
      expect(didChangePreviousCalled, isFalse);
      expect(didChangeNextCalled, isFalse);
    });

    testWidgets('notifies neighboring routes with actual neighbors', (WidgetTester tester) async {
      final ValueNotifier<String?> firstTitleNotifier = ValueNotifier<String?>('First Page');
      final ValueNotifier<String?> secondTitleNotifier = ValueNotifier<String?>('Second Page');
      final ValueNotifier<String?> thirdTitleNotifier = ValueNotifier<String?>('Third Page');
      addTearDown(() {
        firstTitleNotifier.dispose();
        secondTitleNotifier.dispose();
        thirdTitleNotifier.dispose();
      });

      bool firstDidChangePreviousCalled = false;
      bool firstDidChangeNextCalled = false;
      bool secondDidChangePreviousCalled = false;
      bool secondDidChangeNextCalled = false;
      bool thirdDidChangePreviousCalled = false;
      bool thirdDidChangeNextCalled = false;

      // Create test routes that track when didChangePrevious/didChangeNext are called
      final _TestRoute firstRoute = _TestRoute(
        titleListenable: firstTitleNotifier,
        onDidChangePrevious: () => firstDidChangePreviousCalled = true,
        onDidChangeNext: () => firstDidChangeNextCalled = true,
      );

      final _TestRoute secondRoute = _TestRoute(
        titleListenable: secondTitleNotifier,
        onDidChangePrevious: () => secondDidChangePreviousCalled = true,
        onDidChangeNext: () => secondDidChangeNextCalled = true,
      );

      final _TestRoute thirdRoute = _TestRoute(
        titleListenable: thirdTitleNotifier,
        onDidChangePrevious: () => thirdDidChangePreviousCalled = true,
        onDidChangeNext: () => thirdDidChangeNextCalled = true,
      );

      late NavigatorState navigator;
      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (BuildContext context) {
              navigator = Navigator.of(context);
              return const CupertinoPageScaffold(
                navigationBar: CupertinoNavigationBar(middle: Text('Home')),
                child: Center(child: Text('Home Page')),
              );
            },
          ),
        ),
      );

      // Push all three routes to create a stack: home -> first -> second -> third
      navigator.push(firstRoute);
      await tester.pumpAndSettle();
      navigator.push(secondRoute);
      await tester.pumpAndSettle();
      navigator.push(thirdRoute);
      await tester.pumpAndSettle();

      // Reset all flags
      firstDidChangePreviousCalled = false;
      firstDidChangeNextCalled = false;
      secondDidChangePreviousCalled = false;
      secondDidChangeNextCalled = false;
      thirdDidChangePreviousCalled = false;
      thirdDidChangeNextCalled = false;

      // Call changedInternalState on the middle route (secondRoute) with notifyNeighbors=true
      secondRoute.changedInternalState(notifyNeighbors: true);
      await tester.pump();

      // The first route (previous neighbor) should be notified via didChangeNext
      expect(firstDidChangeNextCalled, isTrue);
      expect(firstDidChangePreviousCalled, isFalse);

      // The third route (next neighbor) should be notified via didChangePrevious
      expect(thirdDidChangePreviousCalled, isTrue);
      expect(thirdDidChangeNextCalled, isFalse);

      // The middle route (secondRoute) should not have its own callbacks called
      expect(secondDidChangePreviousCalled, isFalse);
      expect(secondDidChangeNextCalled, isFalse);
    });

    testWidgets('does not notify neighboring routes when called with notifyNeighbors=false', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<String?> titleNotifier = ValueNotifier<String?>('Initial Title');
      addTearDown(titleNotifier.dispose);
      bool didChangePreviousCalled = false;
      bool didChangeNextCalled = false;

      final _TestRoute customRoute = _TestRoute(
        titleListenable: titleNotifier,
        onDidChangePrevious: () => didChangePreviousCalled = true,
        onDidChangeNext: () => didChangeNextCalled = true,
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (BuildContext context) => CupertinoButton(
              onPressed: () {
                Navigator.push(context, customRoute);
              },
              child: const Text('Push Route'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Push Route'));
      await tester.pumpAndSettle();

      // Reset flags
      didChangePreviousCalled = false;
      didChangeNextCalled = false;

      // Call changedInternalState with notifyNeighbors=false (default)
      customRoute.changedInternalState();
      await tester.pump();

      // No neighbors should be notified
      expect(didChangePreviousCalled, isFalse);
      expect(didChangeNextCalled, isFalse);
    });
  });
}

/// A test route that implements CupertinoRouteTransitionMixin for testing purposes.
class _TestRoute extends PageRoute<void> with CupertinoRouteTransitionMixin<void> {
  _TestRoute({required this.titleListenable, this.onDidChangePrevious, this.onDidChangeNext});

  final ValueListenable<String?> titleListenable;
  final VoidCallback? onDidChangePrevious;
  final VoidCallback? onDidChangeNext;

  @override
  String? get title => titleListenable.value;

  @override
  bool get maintainState => true;

  @override
  Widget buildContent(BuildContext context) => const Text('Test Route');

  @override
  void didChangePrevious(Route<dynamic>? previousRoute) {
    super.didChangePrevious(previousRoute);
    onDidChangePrevious?.call();
  }

  @override
  void didChangeNext(Route<dynamic>? nextRoute) {
    super.didChangeNext(nextRoute);
    onDidChangeNext?.call();
  }
}

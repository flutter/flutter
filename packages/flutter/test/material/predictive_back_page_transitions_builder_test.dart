// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();

  for (final pageTransitionsBuilder in <PageTransitionsBuilder>[
    const PredictiveBackPageTransitionsBuilder(),
    const PredictiveBackFullscreenPageTransitionsBuilder(),
  ]) {
    testWidgets(
      'PredictiveBackPageTransitionsBuilder supports predictive back on Android',
      (WidgetTester tester) async {
        final routes = <String, WidgetBuilder>{
          '/': (BuildContext context) => Material(
            child: TextButton(
              child: const Text('push'),
              onPressed: () {
                Navigator.of(context).pushNamed('/b');
              },
            ),
          ),
          '/b': (BuildContext context) => const Text('page b'),
        };

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              pageTransitionsTheme: PageTransitionsTheme(
                builders: <TargetPlatform, PageTransitionsBuilder>{
                  for (final TargetPlatform platform in TargetPlatform.values)
                    platform: pageTransitionsBuilder,
                },
              ),
            ),
            routes: routes,
          ),
        );

        expect(find.text('push'), findsOneWidget);
        expect(find.text('page b'), findsNothing);
        expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsNothing);
        expect(_findFallbackPageTransition(pageTransitionsBuilder), findsOneWidget);

        await tester.tap(find.text('push'));
        await tester.pumpAndSettle();

        expect(find.text('push'), findsNothing);
        expect(find.text('page b'), findsOneWidget);
        expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsNothing);
        expect(_findFallbackPageTransition(pageTransitionsBuilder), findsOneWidget);

        // Only Android supports backGesture channel methods. Other platforms will
        // do nothing.
        if (defaultTargetPlatform != TargetPlatform.android) {
          return;
        }

        // Start a system pop gesture, which will switch to using
        // _PredictiveBackSharedElementPageTransition for the page transition.
        final ByteData startMessage = const StandardMethodCodec().encodeMethodCall(
          const MethodCall('startBackGesture', <String, dynamic>{
            'touchOffset': <double>[5.0, 300.0],
            'progress': 0.0,
            'swipeEdge': 0, // left
          }),
        );
        await binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/backgesture',
          startMessage,
          (ByteData? _) {},
        );
        await tester.pump();

        expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsOneWidget);
        expect(_findFallbackPageTransition(pageTransitionsBuilder), findsNothing);
        final Offset startPageBOffset = tester.getTopLeft(find.text('page b'));
        expect(startPageBOffset.dx, 0.0);

        // Drag the system back gesture far enough to commit.
        final ByteData updateMessage = const StandardMethodCodec().encodeMethodCall(
          const MethodCall('updateBackGestureProgress', <String, dynamic>{
            'x': 100.0,
            'y': 300.0,
            'progress': 0.35,
            'swipeEdge': 0, // left
          }),
        );
        await binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/backgesture',
          updateMessage,
          (ByteData? _) {},
        );
        await tester.pumpAndSettle();

        expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsNWidgets(2));
        expect(_findFallbackPageTransition(pageTransitionsBuilder), findsNothing);

        final Offset updatePageBOffset = tester.getTopLeft(find.text('page b'));
        expect(updatePageBOffset.dx, greaterThan(startPageBOffset.dx));

        // Commit the system back gesture.
        final ByteData commitMessage = const StandardMethodCodec().encodeMethodCall(
          const MethodCall('commitBackGesture'),
        );
        await binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/backgesture',
          commitMessage,
          (ByteData? _) {},
        );
        await tester.pumpAndSettle();

        expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsNothing);
        expect(_findFallbackPageTransition(pageTransitionsBuilder), findsOneWidget);
        expect(find.text('push'), findsOneWidget);
        expect(find.text('page b'), findsNothing);
      },
      variant: TargetPlatformVariant.all(),
    );

    testWidgets(
      'PredictiveBackPageTransitionsBuilder supports canceling a predictive back gesture',
      (WidgetTester tester) async {
        final routes = <String, WidgetBuilder>{
          '/': (BuildContext context) => Material(
            child: TextButton(
              child: const Text('push'),
              onPressed: () {
                Navigator.of(context).pushNamed('/b');
              },
            ),
          ),
          '/b': (BuildContext context) => const Text('page b'),
        };

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              pageTransitionsTheme: PageTransitionsTheme(
                builders: <TargetPlatform, PageTransitionsBuilder>{
                  for (final TargetPlatform platform in TargetPlatform.values)
                    platform: pageTransitionsBuilder,
                },
              ),
            ),
            routes: routes,
          ),
        );

        expect(find.text('push'), findsOneWidget);
        expect(find.text('page b'), findsNothing);
        expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsNothing);
        expect(_findFallbackPageTransition(pageTransitionsBuilder), findsOneWidget);

        await tester.tap(find.text('push'));
        await tester.pumpAndSettle();

        expect(find.text('push'), findsNothing);
        expect(find.text('page b'), findsOneWidget);
        expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsNothing);
        expect(_findFallbackPageTransition(pageTransitionsBuilder), findsOneWidget);

        // Only Android supports backGesture channel methods. Other platforms will
        // do nothing.
        if (defaultTargetPlatform != TargetPlatform.android) {
          return;
        }

        // Start a system pop gesture, which will switch to using
        // _PredictiveBackSharedElementPageTransition for the page transition.
        final ByteData startMessage = const StandardMethodCodec().encodeMethodCall(
          const MethodCall('startBackGesture', <String, dynamic>{
            'touchOffset': <double>[5.0, 300.0],
            'progress': 0.0,
            'swipeEdge': 0, // left
          }),
        );
        await binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/backgesture',
          startMessage,
          (ByteData? _) {},
        );
        await tester.pump();

        expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsOneWidget);
        expect(_findFallbackPageTransition(pageTransitionsBuilder), findsNothing);
        final Offset startPageBOffset = tester.getTopLeft(find.text('page b'));
        expect(startPageBOffset.dx, 0.0);

        // Drag the system back gesture.
        final ByteData updateMessage = const StandardMethodCodec().encodeMethodCall(
          const MethodCall('updateBackGestureProgress', <String, dynamic>{
            'touchOffset': <double>[100.0, 300.0],
            'progress': 0.35,
            'swipeEdge': 0, // left
          }),
        );
        await binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/backgesture',
          updateMessage,
          (ByteData? _) {},
        );
        await tester.pumpAndSettle();

        expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsNWidgets(2));
        expect(_findFallbackPageTransition(pageTransitionsBuilder), findsNothing);

        final Offset updatePageBOffset = tester.getTopLeft(find.text('page b'));
        expect(updatePageBOffset.dx, greaterThan(startPageBOffset.dx));

        // Cancel the system back gesture.
        final ByteData commitMessage = const StandardMethodCodec().encodeMethodCall(
          const MethodCall('cancelBackGesture'),
        );
        await binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/backgesture',
          commitMessage,
          (ByteData? _) {},
        );
        await tester.pumpAndSettle();

        expect(find.text('push'), findsNothing);
        expect(find.text('page b'), findsOneWidget);
        expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsNothing);
        expect(_findFallbackPageTransition(pageTransitionsBuilder), findsOneWidget);
      },
      variant: TargetPlatformVariant.all(),
    );

    testWidgets(
      'if there are multiple PredictiveBackPageTransitionBuilder observers, only one gets called for a given back gesture',
      (WidgetTester tester) async {
        var includingNestedNavigator = false;
        late StateSetter setState;
        final routes = <String, WidgetBuilder>{
          '/': (BuildContext context) => Material(
            child: TextButton(
              child: const Text('push'),
              onPressed: () {
                Navigator.of(context).pushNamed('/b');
              },
            ),
          ),
          '/b': (BuildContext context) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('page b'),
              StatefulBuilder(
                builder: (BuildContext context, StateSetter localSetState) {
                  setState = localSetState;
                  if (!includingNestedNavigator) {
                    return const SizedBox.shrink();
                  }
                  return Navigator(
                    initialRoute: 'b/nested',
                    onGenerateRoute: (RouteSettings settings) {
                      WidgetBuilder builder;
                      switch (settings.name) {
                        case 'b/nested':
                          builder = (BuildContext context) => Material(
                            child: Theme(
                              data: ThemeData(
                                pageTransitionsTheme: PageTransitionsTheme(
                                  builders: <TargetPlatform, PageTransitionsBuilder>{
                                    for (final TargetPlatform platform in TargetPlatform.values)
                                      platform: pageTransitionsBuilder,
                                  },
                                ),
                              ),
                              child: const Column(
                                children: <Widget>[Text('Nested route inside of page b')],
                              ),
                            ),
                          );
                        default:
                          throw Exception('Invalid route: ${settings.name}');
                      }
                      return MaterialPageRoute<void>(builder: builder, settings: settings);
                    },
                  );
                },
              ),
            ],
          ),
        };

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              pageTransitionsTheme: PageTransitionsTheme(
                builders: <TargetPlatform, PageTransitionsBuilder>{
                  for (final TargetPlatform platform in TargetPlatform.values)
                    platform: pageTransitionsBuilder,
                },
              ),
            ),
            routes: routes,
          ),
        );

        expect(find.text('push'), findsOneWidget);
        expect(find.text('page b'), findsNothing);
        expect(find.text('Nested route inside of page b'), findsNothing);
        expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsNothing);
        expect(_findFallbackPageTransition(pageTransitionsBuilder), findsOneWidget);

        await tester.tap(find.text('push'));
        await tester.pumpAndSettle();

        expect(find.text('push'), findsNothing);
        expect(find.text('page b'), findsOneWidget);
        expect(find.text('Nested route inside of page b'), findsNothing);
        expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsNothing);
        expect(_findFallbackPageTransition(pageTransitionsBuilder), findsOneWidget);

        // Only Android supports backGesture channel methods. Other platforms will
        // do nothing.
        if (defaultTargetPlatform != TargetPlatform.android) {
          return;
        }

        // Start a system pop gesture, which will switch to using
        // _PredictiveBackSharedElementPageTransition for the page transition.
        final ByteData startMessage = const StandardMethodCodec().encodeMethodCall(
          const MethodCall('startBackGesture', <String, dynamic>{
            'touchOffset': <double>[5.0, 300.0],
            'progress': 0.0,
            'swipeEdge': 0, // left
          }),
        );
        await binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/backgesture',
          startMessage,
          (ByteData? _) {},
        );
        await tester.pump();

        expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsOneWidget);
        expect(_findFallbackPageTransition(pageTransitionsBuilder), findsNothing);
        final Offset startPageBOffset = tester.getTopLeft(find.text('page b'));
        expect(startPageBOffset.dx, 0.0);

        // Drag the system back gesture.
        final ByteData updateMessage = const StandardMethodCodec().encodeMethodCall(
          const MethodCall('updateBackGestureProgress', <String, dynamic>{
            'touchOffset': <double>[100.0, 300.0],
            'progress': 0.3,
            'swipeEdge': 0, // left
          }),
        );
        await binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/backgesture',
          updateMessage,
          (ByteData? _) {},
        );
        await tester.pumpAndSettle();

        expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsNWidgets(2));
        expect(_findFallbackPageTransition(pageTransitionsBuilder), findsNothing);

        final Offset updatePageBOffset = tester.getTopLeft(find.text('page b'));
        expect(updatePageBOffset.dx, greaterThan(startPageBOffset.dx));

        // In the middle of the system back gesture here, add a nested Navigator
        // that includes a new predictive back gesture observer.
        setState(() {
          includingNestedNavigator = true;
        });
        await tester.pumpAndSettle();
        expect(find.text('push'), findsOneWidget);
        expect(find.text('page b'), findsOneWidget);
        expect(find.text('Nested route inside of page b'), findsOneWidget);

        // Send another drag gesture, and ensure that the original observer still
        // gets it.
        final ByteData updateMessage2 = const StandardMethodCodec().encodeMethodCall(
          const MethodCall('updateBackGestureProgress', <String, dynamic>{
            'touchOffset': <double>[110.0, 300.0],
            'progress': 0.35,
            'swipeEdge': 0, // left
          }),
        );
        await binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/backgesture',
          updateMessage2,
          (ByteData? _) {},
        );
        await tester.pumpAndSettle();

        expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsNWidgets(2));
        // Despite using a PredictiveBackPageTransitions, the new route has not
        // received a start event, so it is still using the fallback transition.
        expect(_findFallbackPageTransition(pageTransitionsBuilder), findsOneWidget);

        final Offset update2PageBOffset = tester.getTopLeft(find.text('page b'));
        expect(update2PageBOffset.dx, greaterThan(updatePageBOffset.dx));

        // Commit the system back gesture, and the original observer is able to
        // handle the back without interference.
        final ByteData commitMessage = const StandardMethodCodec().encodeMethodCall(
          const MethodCall('commitBackGesture'),
        );
        await binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/backgesture',
          commitMessage,
          (ByteData? _) {},
        );
        await tester.pumpAndSettle();

        expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsNothing);
        expect(_findFallbackPageTransition(pageTransitionsBuilder), findsOneWidget);
        expect(find.text('push'), findsOneWidget);
        expect(find.text('page b'), findsNothing);
        expect(find.text('Nested route inside of page b'), findsNothing);
      },
      variant: TargetPlatformVariant.all(),
    );

    testWidgets('two back gestures back to back dismiss two routes', (WidgetTester tester) async {
      final routes = <String, WidgetBuilder>{
        '/': (BuildContext context) => Material(
          child: TextButton(
            child: const Text('push b'),
            onPressed: () {
              Navigator.of(context).pushNamed('/b');
            },
          ),
        ),
        '/b': (BuildContext context) => Material(
          child: TextButton(
            child: const Text('push c'),
            onPressed: () {
              Navigator.of(context).pushNamed('/c');
            },
          ),
        ),
        '/c': (BuildContext context) => const Text('page c'),
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            pageTransitionsTheme: PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                for (final TargetPlatform platform in TargetPlatform.values)
                  platform: pageTransitionsBuilder,
              },
            ),
          ),
          routes: routes,
        ),
      );

      expect(find.text('push b'), findsOneWidget);
      expect(find.text('push c'), findsNothing);
      expect(find.text('page c'), findsNothing);
      expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsNothing);
      expect(_findFallbackPageTransition(pageTransitionsBuilder), findsOneWidget);

      await tester.tap(find.text('push b'));
      await tester.pumpAndSettle();

      expect(find.text('push'), findsNothing);
      expect(find.text('push c'), findsOneWidget);
      expect(find.text('page c'), findsNothing);
      expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsNothing);
      expect(_findFallbackPageTransition(pageTransitionsBuilder), findsOneWidget);

      await tester.tap(find.text('push c'));
      await tester.pumpAndSettle();

      expect(find.text('push'), findsNothing);
      expect(find.text('push c'), findsNothing);
      expect(find.text('page c'), findsOneWidget);
      expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsNothing);
      expect(_findFallbackPageTransition(pageTransitionsBuilder), findsOneWidget);

      // Only Android supports backGesture channel methods. Other platforms will
      // do nothing.
      if (defaultTargetPlatform != TargetPlatform.android) {
        return;
      }

      // Start a system pop gesture, which will switch to using
      // _PredictiveBackSharedElementPageTransition for the page transition.
      final ByteData startMessage = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('startBackGesture', <String, dynamic>{
          'touchOffset': <double>[5.0, 300.0],
          'progress': 0.0,
          'swipeEdge': 0, // left
        }),
      );
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        startMessage,
        (ByteData? _) {},
      );
      await tester.pump();

      expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsOneWidget);
      expect(_findFallbackPageTransition(pageTransitionsBuilder), findsNothing);

      // Drag the system back gesture far enough to commit.
      final ByteData updateMessage = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('updateBackGestureProgress', <String, dynamic>{
          'x': 100.0,
          'y': 300.0,
          'progress': 0.35,
          'swipeEdge': 0, // left
        }),
      );
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        updateMessage,
        (ByteData? _) {},
      );
      await tester.pump();

      expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsNWidgets(2));
      expect(_findFallbackPageTransition(pageTransitionsBuilder), findsNothing);

      // Commit the system back gesture.
      final ByteData commitMessage = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('commitBackGesture'),
      );
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        commitMessage,
        (ByteData? _) {},
      );
      await tester.pump();

      // The predictive back page transitions still exist because the outgoing
      // animation has not yet finished.
      expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsNWidgets(2));
      expect(_findFallbackPageTransition(pageTransitionsBuilder), findsNothing);

      expect(find.text('push'), findsNothing);
      expect(find.text('push c'), findsOneWidget);
      expect(find.text('page c'), findsOneWidget);

      // Start another system pop gesture, before the first has finished
      // animating out.
      final ByteData startMessage2 = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('startBackGesture', <String, dynamic>{
          'touchOffset': <double>[5.0, 300.0],
          'progress': 0.0,
          'swipeEdge': 0, // left
        }),
      );
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        startMessage2,
        (ByteData? _) {},
      );
      await tester.pump();

      expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsNWidgets(2));
      expect(_findFallbackPageTransition(pageTransitionsBuilder), findsNothing);

      // Drag the system back gesture far enough to commit.
      final ByteData updateMessage2 = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('updateBackGestureProgress', <String, dynamic>{
          'x': 100.0,
          'y': 300.0,
          'progress': 0.35,
          'swipeEdge': 0, // left
        }),
      );
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        updateMessage2,
        (ByteData? _) {},
      );
      await tester.pump();

      expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsNWidgets(3));
      expect(_findFallbackPageTransition(pageTransitionsBuilder), findsNothing);

      // Commit the system back gesture.
      final ByteData commitMessage2 = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('commitBackGesture'),
      );
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        commitMessage2,
        (ByteData? _) {},
      );
      await tester.pumpAndSettle();

      expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsNothing);
      expect(_findFallbackPageTransition(pageTransitionsBuilder), findsOneWidget);

      expect(find.text('push b'), findsOneWidget);
      expect(find.text('push c'), findsNothing);
      expect(find.text('page c'), findsNothing);
    }, variant: TargetPlatformVariant.all());
  }
}

String _getTransitionsString(PageTransitionsBuilder pageTransitionsBuilder) {
  return switch (pageTransitionsBuilder) {
    PredictiveBackPageTransitionsBuilder() => '_PredictiveBackSharedElementPageTransition',
    PredictiveBackFullscreenPageTransitionsBuilder() => '_PredictiveBackFullscreenPageTransition',
    _ => throw UnsupportedError('Unsupported subclass of PageTransitionsBuilder'),
  };
}

Finder _findPredictiveBackPageTransition(PageTransitionsBuilder pageTransitionsBuilder) {
  return find.descendant(
    of: find.byType(MaterialApp),
    matching: find.byWidgetPredicate(
      (Widget w) => '${w.runtimeType}' == _getTransitionsString(pageTransitionsBuilder),
    ),
  );
}

Finder _findFallbackPageTransition(PageTransitionsBuilder pageTransitionsBuilder) {
  final String fallback = switch (pageTransitionsBuilder) {
    final PredictiveBackPageTransitionsBuilder _ => '_FadeForwardsPageTransition',
    final PredictiveBackFullscreenPageTransitionsBuilder _ => '_ZoomPageTransition',
    _ => throw TypeError(),
  };
  return find.descendant(
    of: find.byType(MaterialApp),
    matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == fallback),
  );
}

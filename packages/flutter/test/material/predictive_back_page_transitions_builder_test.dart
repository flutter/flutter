// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();

  Finder findPredictiveBackPageTransition() {
    return find.descendant(
      of: find.byType(MaterialApp),
      matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_PredictiveBackPageTransition'),
    );
  }
  Finder findFallbackPageTransition() {
    return find.descendant(
      of: find.byType(MaterialApp),
      matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_ZoomPageTransition'),
    );
  }

  testWidgets('PredictiveBackPageTransitionsBuilder supports predictive back on Android', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => Material(
        child: TextButton(
          child: const Text('push'),
          onPressed: () { Navigator.of(context).pushNamed('/b'); },
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
                platform: const PredictiveBackPageTransitionsBuilder(),
            },
          ),
        ),
        routes: routes,
      ),
    );

    expect(find.text('push'), findsOneWidget);
    expect(find.text('page b'), findsNothing);
    expect(findPredictiveBackPageTransition(), findsNothing);
    expect(findFallbackPageTransition(), findsOneWidget);

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();

    expect(find.text('push'), findsNothing);
    expect(find.text('page b'), findsOneWidget);
    expect(findPredictiveBackPageTransition(), findsNothing);
    expect(findFallbackPageTransition(), findsOneWidget);

    // Only Android supports backGesture channel methods. Other platforms will
    // do nothing.
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    // Start a system pop gesture, which will switch to using
    // _PredictiveBackPageTransition for the page transition.
    final ByteData? startMessage = const JSONMessageCodec().encodeMessage(<String, dynamic>{
      'method': 'startBackGesture',
      'args': <String, dynamic>{
        'x': 5.0,
        'y': 300.0,
        'progress': 0.0,
        'swipeEdge': 0, // left
      },
    });
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/backgesture',
      startMessage,
      (ByteData? _) {},
    );
    await tester.pump();

    expect(findPredictiveBackPageTransition(), findsOneWidget);
    expect(findFallbackPageTransition(), findsNothing);
    final Offset startPageBOffset = tester.getTopLeft(find.text('page b'));
    expect(startPageBOffset.dx, 0.0);

    // Drag the system back gesture far enough to commit.
    final ByteData? updateMessage = const JSONMessageCodec().encodeMessage(<String, dynamic>{
      'method': 'updateBackGestureProgress',
      'args': <String, dynamic>{
        'x': 100.0,
        'y': 300.0,
        'progress': 0.35,
        'swipeEdge': 0, // left
      },
    });
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/backgesture',
      updateMessage,
      (ByteData? _) {},
    );
    await tester.pumpAndSettle();

    expect(findPredictiveBackPageTransition(), findsNWidgets(2));
    expect(findFallbackPageTransition(), findsNothing);

    final Offset updatePageBOffset = tester.getTopLeft(find.text('page b'));
    expect(updatePageBOffset.dx, greaterThan(startPageBOffset.dx));

    // Commit the system back gesture.
    final ByteData? commitMessage = const JSONMessageCodec().encodeMessage(<String, dynamic>{
      'method': 'commitBackGesture',
    });
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/backgesture',
      commitMessage,
      (ByteData? _) {},
    );
    await tester.pumpAndSettle();

    expect(findPredictiveBackPageTransition(), findsNothing);
    expect(findFallbackPageTransition(), findsOneWidget);
    expect(find.text('push'), findsOneWidget);
    expect(find.text('page b'), findsNothing);
  }, variant: TargetPlatformVariant.all());

  testWidgets('PredictiveBackPageTransitionsBuilder supports canceling a predictive back gesture', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => Material(
        child: TextButton(
          child: const Text('push'),
          onPressed: () { Navigator.of(context).pushNamed('/b'); },
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
                platform: const PredictiveBackPageTransitionsBuilder(),
            },
          ),
        ),
        routes: routes,
      ),
    );

    expect(find.text('push'), findsOneWidget);
    expect(find.text('page b'), findsNothing);
    expect(findPredictiveBackPageTransition(), findsNothing);
    expect(findFallbackPageTransition(), findsOneWidget);

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();

    expect(find.text('push'), findsNothing);
    expect(find.text('page b'), findsOneWidget);
    expect(findPredictiveBackPageTransition(), findsNothing);
    expect(findFallbackPageTransition(), findsOneWidget);

    // Only Android supports backGesture channel methods. Other platforms will
    // do nothing.
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    // Start a system pop gesture, which will switch to using
    // _PredictiveBackPageTransition for the page transition.
    final ByteData? startMessage = const JSONMessageCodec().encodeMessage(<String, dynamic>{
      'method': 'startBackGesture',
      'args': <String, dynamic>{
        'x': 5.0,
        'y': 300.0,
        'progress': 0.0,
        'swipeEdge': 0, // left
      },
    });
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/backgesture',
      startMessage,
      (ByteData? _) {},
    );
    await tester.pump();

    expect(findPredictiveBackPageTransition(), findsOneWidget);
    expect(findFallbackPageTransition(), findsNothing);
    final Offset startPageBOffset = tester.getTopLeft(find.text('page b'));
    expect(startPageBOffset.dx, 0.0);

    // Drag the system back gesture.
    final ByteData? updateMessage = const JSONMessageCodec().encodeMessage(<String, dynamic>{
      'method': 'updateBackGestureProgress',
      'args': <String, dynamic>{
        'x': 100.0,
        'y': 300.0,
        'progress': 0.35,
        'swipeEdge': 0, // left
      },
    });
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/backgesture',
      updateMessage,
      (ByteData? _) {},
    );
    await tester.pumpAndSettle();

    expect(findPredictiveBackPageTransition(), findsNWidgets(2));
    expect(findFallbackPageTransition(), findsNothing);

    final Offset updatePageBOffset = tester.getTopLeft(find.text('page b'));
    expect(updatePageBOffset.dx, greaterThan(startPageBOffset.dx));

    // Cancel the system back gesture.
    final ByteData? commitMessage = const JSONMessageCodec().encodeMessage(<String, dynamic>{
      'method': 'cancelBackGesture',
    });
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/backgesture',
      commitMessage,
      (ByteData? _) {},
    );
    await tester.pumpAndSettle();

    expect(find.text('push'), findsNothing);
    expect(find.text('page b'), findsOneWidget);
    expect(findPredictiveBackPageTransition(), findsNothing);
    expect(findFallbackPageTransition(), findsOneWidget);
  }, variant: TargetPlatformVariant.all());
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'PredictiveBackPageTransitionsBuilder supports SwipeEdge.none (3-button navigation mode)',
    (WidgetTester tester) async {
      // Only Android supports backGesture channel methods. Other platforms will
      // do nothing.
      if (defaultTargetPlatform != TargetPlatform.android) {
        return;
      }

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

      const pageTransitionsBuilder = PredictiveBackPageTransitionsBuilder();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: pageTransitionsBuilder,
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

      // Start a system pop gesture with swipeEdge 2 (none).
      // This will fail with RangeError before SwipeEdge.none is added.
      final ByteData startMessage = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('startBackGesture', <String, dynamic>{
          'touchOffset': null,
          'progress': 0.0,
          'swipeEdge': 2,
        }),
      );
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        startMessage,
        (ByteData? _) {},
      );
      await tester.pump();

      // Verify that the predictive back page transition is active.
      expect(_findPredictiveBackPageTransition(pageTransitionsBuilder), findsOneWidget);
      expect(_findFallbackPageTransition(pageTransitionsBuilder), findsNothing);
    },
  );
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

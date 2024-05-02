// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_api_samples/widgets/shortcuts/logical_key_set.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogicalKeySetExampleApp', () {
    Future<void> sendKeyCombination(
      WidgetTester tester,
      List<LogicalKeyboardKey> keys,
    ) async {
      for (final LogicalKeyboardKey key in keys) {
        await tester.sendKeyDownEvent(key);
      }
      for (final LogicalKeyboardKey key in keys.reversed) {
        await tester.sendKeyUpEvent(key);
      }
    }

    testWidgets('displays correct labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        const example.LogicalKeySetExampleApp(),
      );

      expect(find.text('LogicalKeySet Sample'), findsOneWidget);
      expect(
        find.text('Add to the counter by pressing Ctrl+C'),
        findsOneWidget,
      );
      expect(find.text('count: 0'), findsOneWidget);
    });

    testWidgets(
      'updates counter when LCtrl-C or C-LCtrl combination pressed',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const example.LogicalKeySetExampleApp(),
        );

        for (int counter = 0; counter < 10; counter++) {
          expect(find.text('count: $counter'), findsOneWidget);

          await sendKeyCombination(
            tester,
            counter.isEven
                ? <LogicalKeyboardKey>[
                    LogicalKeyboardKey.controlLeft,
                    LogicalKeyboardKey.keyC,
                  ]
                : <LogicalKeyboardKey>[
                    LogicalKeyboardKey.keyC,
                    LogicalKeyboardKey.controlLeft,
                  ],
          );
          await tester.pump();
        }
      },
    );

    testWidgets(
      'updates counter when RCtrl-C combination pressed',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const example.LogicalKeySetExampleApp(),
        );

        for (int counter = 0; counter < 10; counter++) {
          expect(find.text('count: $counter'), findsOneWidget);

          await sendKeyCombination(
            tester,
            <LogicalKeyboardKey>[
              LogicalKeyboardKey.controlRight,
              LogicalKeyboardKey.keyC,
            ],
          );
          await tester.pump();
        }
      },
    );

    testWidgets(
      'does not update counter when LCtrl-A-C combination pressed',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const example.LogicalKeySetExampleApp(),
        );

        for (int counter = 0; counter < 10; counter++) {
          expect(find.text('count: 0'), findsOneWidget);

          await sendKeyCombination(
            tester,
            <LogicalKeyboardKey>[
              LogicalKeyboardKey.controlLeft,
              LogicalKeyboardKey.keyA,
              LogicalKeyboardKey.keyC,
            ],
          );
          await tester.pump();
        }
      },
    );

    testWidgets(
      'does not update counter when RCtrl-A-C combination pressed',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const example.LogicalKeySetExampleApp(),
        );

        for (int counter = 0; counter < 10; counter++) {
          expect(find.text('count: 0'), findsOneWidget);

          await sendKeyCombination(
            tester,
            <LogicalKeyboardKey>[
              LogicalKeyboardKey.controlRight,
              LogicalKeyboardKey.keyA,
              LogicalKeyboardKey.keyC,
            ],
          );
          await tester.pump();
        }
      },
    );
  });
}

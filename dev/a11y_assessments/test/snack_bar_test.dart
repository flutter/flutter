// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SnackBar Accessibility Tests', () {
    testWidgets('snack bar announces message', (WidgetTester tester) async {
      final List<Map<String, dynamic>> log = <Map<String, dynamic>>[];

      Future<void> handleMessage(Object? mockMessage) async {
        if (mockMessage is Map<Object?, Object?>) {
          final Map<String, dynamic> casted = mockMessage.map(
                (Object? key, Object? value) =>
                MapEntry<String, dynamic>(key.toString(), value),
          );
          log.add(casted);
        }
      }

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, handleMessage);

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(supportsAnnounce: true),
          child: MaterialApp(home: MainWidget()),
        ),
      );

      const String snackBarText = 'Awesome Snackbar!';
      expect(find.text(snackBarText), findsNothing);

      await tester.tap(find.text('Show Snackbar'));
      await tester.pumpAndSettle();

      expect(log, isNotEmpty);
      expect(
        log.firstWhere(
              (Map<String, dynamic> message) {
            final Map<String, dynamic> data = message['data'] as Map<String, dynamic>;
            return message['type'] == 'announce' && data['message'] == snackBarText;
          },
          orElse: () => <String, dynamic>{},
        ),
        isNotNull,
      );
    });
  });
}
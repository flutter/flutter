// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/snack_bar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SnackBar Accessibility Tests', () {
    testWidgets('snack bar announces message', (WidgetTester tester) async {
      final List<Map<String, dynamic>> log = <Map<String, dynamic>>[];

      Future<dynamic> handleMessage(dynamic mockMessage) async {
        final Map<dynamic, dynamic> message = mockMessage as Map<dynamic, dynamic>;
        final Map<String, dynamic> castedMessage = Map<String, dynamic>.from(message);
        log.add(castedMessage);
      }

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, handleMessage);

      await pumpsUseCase(tester, SnackBarUseCase());

      const String snackBarText = 'Awesome Snackbar!';
      expect(find.text(snackBarText), findsNothing);

      await tester.tap(find.text('Show Snackbar'));
      await tester.pumpAndSettle();

      expect(log, isNotEmpty);
      expect(
        log.firstWhere((Map<String, dynamic> message) {
          final Map<String, dynamic> data = message['data'] as Map<String, dynamic>;
          return message['type'] == 'announce' && data['message'] == snackBarText;
        }, orElse: () => <String, dynamic>{}),
        isNotNull,
      );
    });
  });
}

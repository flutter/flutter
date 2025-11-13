// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart' as flutter_driver;
import 'package:flutter_driver/src/common/text_input_action.dart' as command;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SendTextInputAction', () {
    test('serializes and deserializes', () {
      const command.SendTextInputAction action = command.SendTextInputAction(
        flutter_driver.TextInputAction.done,
      );
      final command.SendTextInputAction roundTrip = command.SendTextInputAction.deserialize(
        action.serialize(),
      );
      expect(roundTrip.textInputAction, flutter_driver.TextInputAction.done);
    });

    test('deserialize with missing action', () {
      final Map<String, String> serialized = <String, String>{'command': 'send_text_input_action'};
      expect(
        () => command.SendTextInputAction.deserialize(serialized),
        throwsA(
          isA<ArgumentError>()
              .having((ArgumentError e) => e.message, 'message', 'Must not be null')
              .having((ArgumentError e) => e.name, 'name', 'action'),
        ),
      );
    });
  });

  test('flutter_driver.TextInputAction should be sync with TextInputAction', () {
    final List<String> actual = flutter_driver.TextInputAction.values
        .map((flutter_driver.TextInputAction action) => action.name)
        .toList();
    final List<String> matcher = TextInputAction.values
        .map((TextInputAction action) => action.name)
        .toList();
    expect(actual, matcher);
  });
}

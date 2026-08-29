// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:test/test.dart';

void main() {
  group('Diagnostics Core Models', () {
    test('ValidationMessage serializes and deserializes correctly', () {
      const msg = ValidationMessage('Host tool version OK', contextUrl: 'https://flutter.dev');

      final Map<String, Object?> map = msg.toMap();
      expect(map['type'], 'information');
      expect(map['message'], 'Host tool version OK');
      expect(map['contextUrl'], 'https://flutter.dev');

      final parsed = ValidationMessage.fromJson(map);
      expect(parsed.type, ValidationMessageType.information);
      expect(parsed.message, 'Host tool version OK');
      expect(parsed.contextUrl, 'https://flutter.dev');
    });

    test('ValidationMessage handles unknown types gracefully', () {
      final parsed = ValidationMessage.fromJson(const <String, Object?>{
        'type': 'unsupported_future_type',
        'message': 'Fallback message',
      });
      expect(parsed.type, ValidationMessageType.information);
      expect(parsed.message, 'Fallback message');
    });

    test('ValidationResult serializes and deserializes correctly', () {
      final result = ValidationResult(ValidationType.success, <ValidationMessage>[
        const ValidationMessage('Check passed'),
      ], statusInfo: 'Ready');

      final Map<String, Object?> map = result.toMap();
      expect(map['type'], 'success');
      expect(map['statusInfo'], 'Ready');

      final parsed = ValidationResult.fromJson(map);
      expect(parsed.type, ValidationType.success);
      expect(parsed.statusInfo, 'Ready');
      expect(parsed.messages, hasLength(1));
      expect(parsed.messages.first.message, 'Check passed');
    });

    test('ValidationResult handles unknown types gracefully', () {
      final parsed = ValidationResult.fromJson(const <String, Object?>{
        'type': 'unsupported_future_type',
        'messages': <Map<String, Object?>>[],
      });
      expect(parsed.type, ValidationType.success);
    });
  });
}

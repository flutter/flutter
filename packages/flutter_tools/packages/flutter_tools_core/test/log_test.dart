// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:test/test.dart';

void main() {
  group('ExtensionLogLevel', () {
    test('values are ordered by ascending severity', () {
      expect(ExtensionLogLevel.values, <ExtensionLogLevel>[.trace, .info, .warning, .error]);
    });
  });

  group('ExtensionLogMessage', () {
    test('round-trips via toMap and fromJson and supports equality', () {
      final message = ExtensionLogMessage(
        level: ExtensionLogLevel.warning,
        message: 'SDK path looks unusual',
        timestamp: DateTime.utc(2026, 11, 11, 12, 30),
      );

      final Map<String, Object?> serialized = message.toMap();
      expect(serialized, <String, Object?>{
        ExtensionLogMessage.levelKey: 'warning',
        ExtensionLogMessage.messageKey: 'SDK path looks unusual',
        ExtensionLogMessage.timestampKey: '2026-11-11T12:30:00.000Z',
      });

      final parsed = ExtensionLogMessage.fromJson(serialized);
      expect(parsed, equals(message));
      expect(parsed.hashCode, equals(message.hashCode));
      expect(parsed.toString(), contains('level: warning'));
      expect(parsed.toString(), contains('SDK path looks unusual'));
    });

    test('round-trips local DateTime via UTC and preserves equality and hashCode', () {
      final message = ExtensionLogMessage(
        level: .warning,
        message: 'SDK path looks unusual',
        timestamp: DateTime(2026, 11, 11, 12, 30),
      );

      final parsed = ExtensionLogMessage.fromJson(message.toMap());
      expect(parsed.timestamp?.isUtc, isTrue);
      expect(parsed, equals(message));
      expect(parsed.hashCode, equals(message.hashCode));
    });

    test('round-trips when timestamp is omitted', () {
      const message = ExtensionLogMessage(message: 'Using system CMake');

      final Map<String, Object?> serialized = message.toMap();
      expect(serialized, <String, Object?>{
        ExtensionLogMessage.levelKey: 'info',
        ExtensionLogMessage.messageKey: 'Using system CMake',
      });

      final parsed = ExtensionLogMessage.fromJson(serialized);
      expect(parsed, equals(message));
      expect(parsed.timestamp, isNull);
      expect(parsed.hashCode, equals(message.hashCode));
    });

    test('throws FormatException when required fields are missing or invalid', () {
      expect(
        () => ExtensionLogMessage.fromJson(const <String, Object?>{
          ExtensionLogMessage.messageKey: 'missing level',
          ExtensionLogMessage.timestampKey: '2026-11-11T12:30:00.000Z',
        }),
        throwsFormatException,
      );

      expect(
        () => ExtensionLogMessage.fromJson(const <String, Object?>{
          ExtensionLogMessage.levelKey: 'unknown_level',
          ExtensionLogMessage.messageKey: 'bad level',
          ExtensionLogMessage.timestampKey: '2026-11-11T12:30:00.000Z',
        }),
        throwsFormatException,
      );

      expect(
        () => ExtensionLogMessage.fromJson(const <String, Object?>{
          ExtensionLogMessage.levelKey: 'info',
          ExtensionLogMessage.timestampKey: '2026-11-11T12:30:00.000Z',
        }),
        throwsFormatException,
      );

      expect(
        () => ExtensionLogMessage.fromJson(const <String, Object?>{
          ExtensionLogMessage.levelKey: 'info',
          ExtensionLogMessage.messageKey: 'non-string timestamp',
          ExtensionLogMessage.timestampKey: 123,
        }),
        throwsFormatException,
      );

      expect(
        () => ExtensionLogMessage.fromJson(const <String, Object?>{
          ExtensionLogMessage.levelKey: 'info',
          ExtensionLogMessage.messageKey: 'bad timestamp',
          ExtensionLogMessage.timestampKey: 'not-a-timestamp',
        }),
        throwsFormatException,
      );
    });
  });
}

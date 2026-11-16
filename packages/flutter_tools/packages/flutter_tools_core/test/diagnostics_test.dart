// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:test/test.dart';

Matcher _throwsFormatExceptionContaining(String substring) {
  return throwsA(
    isA<FormatException>().having((FormatException e) => e.message, 'message', contains(substring)),
  );
}

void main() {
  group('Diagnostics Core Models', () {
    group('ValidationMessage', () {
      test('serializes and deserializes information, error, and hint messages', () {
        const infoMsg = ValidationMessage(
          'Host tool at /home/alice/sdk',
          contextUrl: 'https://flutter.dev',
          piiStrippedMessage: 'Host tool at <redacted>',
        );
        final Map<String, Object?> infoMap = infoMsg.toMap();
        expect(infoMap[ValidationMessage.typeKey], 'information');
        expect(infoMap[ValidationMessage.messageKey], 'Host tool at /home/alice/sdk');
        expect(infoMap[ValidationMessage.contextUrlKey], 'https://flutter.dev');
        expect(infoMap[ValidationMessage.piiStrippedMessageKey], 'Host tool at <redacted>');
        expect(ValidationMessage.fromJson(infoMap), equals(infoMsg));
        expect(infoMsg.toString(), 'Host tool at /home/alice/sdk');

        const errorMsg = ValidationMessage.error(
          'Missing /Users/alice/tool',
          piiStrippedMessage: 'Missing <redacted>',
        );
        expect(ValidationMessage.fromJson(errorMsg.toMap()), equals(errorMsg));
        expect(errorMsg.isError, isTrue);

        const hintMsg = ValidationMessage.hint('Run setup');
        expect(hintMsg.piiStrippedMessage, 'Run setup');
        expect(ValidationMessage.fromJson(hintMsg.toMap()), equals(hintMsg));
        expect(hintMsg.isHint, isTrue);
      });

      test(
        'defaults piiStrippedMessage to message at construction and omits contextUrl when null',
        () {
          const constructed = ValidationMessage('Host tool version OK');
          expect(constructed.piiStrippedMessage, 'Host tool version OK');
          expect(constructed.contextUrl, isNull);
          expect(constructed.toMap().containsKey(ValidationMessage.contextUrlKey), isFalse);

          final parsed = ValidationMessage.fromJson(const <String, Object?>{
            ValidationMessage.typeKey: 'information',
            ValidationMessage.messageKey: 'Host tool version OK',
            ValidationMessage.piiStrippedMessageKey: 'Host tool version OK',
          });
          expect(parsed, equals(constructed));
        },
      );

      test('equality and hashCode cover type, message, contextUrl, and piiStrippedMessage', () {
        const baseline = ValidationMessage(
          'Path /home/alice',
          contextUrl: 'https://flutter.dev',
          piiStrippedMessage: 'Path <user>',
        );
        const identicalFields = ValidationMessage(
          'Path /home/alice',
          contextUrl: 'https://flutter.dev',
          piiStrippedMessage: 'Path <user>',
        );
        const differentPii = ValidationMessage(
          'Path /home/alice',
          contextUrl: 'https://flutter.dev',
          piiStrippedMessage: 'Path <other>',
        );
        const defaultPii = ValidationMessage('Path /home/alice', contextUrl: 'https://flutter.dev');
        const differentUrl = ValidationMessage(
          'Path /home/alice',
          contextUrl: 'https://dart.dev',
          piiStrippedMessage: 'Path <user>',
        );
        const differentMessage = ValidationMessage(
          'Path /home/bob',
          contextUrl: 'https://flutter.dev',
          piiStrippedMessage: 'Path <user>',
        );
        const differentType = ValidationMessage.error(
          'Path /home/alice',
          piiStrippedMessage: 'Path <user>',
        );

        expect(baseline, equals(identicalFields));
        expect(baseline.hashCode, equals(identicalFields.hashCode));

        expect(baseline, isNot(equals(differentPii)));
        expect(baseline.hashCode, isNot(equals(differentPii.hashCode)));
        expect(baseline, isNot(equals(defaultPii)));
        expect(baseline, isNot(equals(differentUrl)));
        expect(baseline, isNot(equals(differentMessage)));
        expect(baseline, isNot(equals(differentType)));
      });

      test('fromJson throws FormatException when required fields are missing or invalid', () {
        expect(
          () => ValidationMessage.fromJson(const <String, Object?>{
            ValidationMessage.messageKey: 'ok',
            ValidationMessage.piiStrippedMessageKey: 'ok',
          }),
          _throwsFormatExceptionContaining('Missing required "${ValidationMessage.typeKey}"'),
        );
        expect(
          () => ValidationMessage.fromJson(const <String, Object?>{
            ValidationMessage.typeKey: 42,
            ValidationMessage.messageKey: 'ok',
            ValidationMessage.piiStrippedMessageKey: 'ok',
          }),
          _throwsFormatExceptionContaining('Invalid "${ValidationMessage.typeKey}"'),
        );
        expect(
          () => ValidationMessage.fromJson(const <String, Object?>{
            ValidationMessage.typeKey: 'unsupported_future_type',
            ValidationMessage.messageKey: 'ok',
            ValidationMessage.piiStrippedMessageKey: 'ok',
          }),
          _throwsFormatExceptionContaining('unsupported_future_type'),
        );
        expect(
          () => ValidationMessage.fromJson(const <String, Object?>{
            ValidationMessage.typeKey: 'information',
            ValidationMessage.piiStrippedMessageKey: 'ok',
          }),
          _throwsFormatExceptionContaining('Missing required "${ValidationMessage.messageKey}"'),
        );
        expect(
          () => ValidationMessage.fromJson(const <String, Object?>{
            ValidationMessage.typeKey: 'information',
            ValidationMessage.messageKey: 123,
            ValidationMessage.piiStrippedMessageKey: 'ok',
          }),
          _throwsFormatExceptionContaining('Invalid "${ValidationMessage.messageKey}"'),
        );
        expect(
          () => ValidationMessage.fromJson(const <String, Object?>{
            ValidationMessage.typeKey: 'information',
            ValidationMessage.messageKey: 'ok',
          }),
          _throwsFormatExceptionContaining(
            'Missing required "${ValidationMessage.piiStrippedMessageKey}"',
          ),
        );
        expect(
          () => ValidationMessage.fromJson(const <String, Object?>{
            ValidationMessage.typeKey: 'information',
            ValidationMessage.messageKey: 'ok',
            ValidationMessage.piiStrippedMessageKey: null,
          }),
          _throwsFormatExceptionContaining(
            'Missing required "${ValidationMessage.piiStrippedMessageKey}"',
          ),
        );
        expect(
          () => ValidationMessage.fromJson(const <String, Object?>{
            ValidationMessage.typeKey: 'information',
            ValidationMessage.messageKey: 'ok',
            ValidationMessage.piiStrippedMessageKey: 123,
          }),
          _throwsFormatExceptionContaining('Invalid "${ValidationMessage.piiStrippedMessageKey}"'),
        );
        expect(
          () => ValidationMessage.fromJson(const <String, Object?>{
            ValidationMessage.typeKey: 'information',
            ValidationMessage.messageKey: 'ok',
            ValidationMessage.piiStrippedMessageKey: 'ok',
            ValidationMessage.contextUrlKey: 123,
          }),
          _throwsFormatExceptionContaining('Invalid "${ValidationMessage.contextUrlKey}"'),
        );
        expect(
          () => ValidationMessage.fromJson(const <String, Object?>{
            ValidationMessage.typeKey: 'error',
            ValidationMessage.messageKey: 'ok',
            ValidationMessage.piiStrippedMessageKey: 'ok',
            ValidationMessage.contextUrlKey: 'https://flutter.dev',
          }),
          _throwsFormatExceptionContaining('Invalid "${ValidationMessage.contextUrlKey}"'),
        );
        expect(
          () => ValidationMessage.fromJson(const <String, Object?>{
            ValidationMessage.typeKey: 'hint',
            ValidationMessage.messageKey: 'ok',
            ValidationMessage.piiStrippedMessageKey: 'ok',
            ValidationMessage.contextUrlKey: 'https://flutter.dev',
          }),
          _throwsFormatExceptionContaining('Invalid "${ValidationMessage.contextUrlKey}"'),
        );
      });
    });

    group('ValidationResult', () {
      test('serializes and deserializes correctly', () {
        final result = ValidationResult(ValidationType.success, const <ValidationMessage>[
          ValidationMessage('Check passed', piiStrippedMessage: 'Passed'),
        ], statusInfo: 'Ready');

        final Map<String, Object?> map = result.toMap();
        expect(map[ValidationResult.typeKey], 'success');
        expect(map[ValidationResult.statusInfoKey], 'Ready');

        final parsed = ValidationResult.fromJson(map);
        expect(parsed, equals(result));
      });

      test('stores unmodifiable messages list and omits host executionTime from toMap', () {
        final inputMessages = <ValidationMessage>[const ValidationMessage('Initial')];
        final result = ValidationResult(
          ValidationType.partial,
          inputMessages,
          executionTime: const Duration(milliseconds: 25),
          statusInfo: 'Some warnings',
        );

        inputMessages.add(const ValidationMessage('Mutated caller list'));
        expect(result.messages, const <ValidationMessage>[ValidationMessage('Initial')]);
        expect(
          () => result.messages.add(const ValidationMessage('Mutated result list')),
          throwsUnsupportedError,
        );
        expect(result.executionTime, const Duration(milliseconds: 25));
        expect(result.toMap().containsKey('executionTime'), isFalse);
        expect(
          result.toString(),
          'ValidationResult(type: ValidationType.partial, messages: [Initial], '
          'statusInfo: Some warnings, executionTime: 0:00:00.025000)',
        );
      });

      test('equality and hashCode cover type, messages, statusInfo, and executionTime', () {
        final baseline = ValidationResult(
          ValidationType.success,
          const <ValidationMessage>[
            ValidationMessage('First', piiStrippedMessage: 'First redacted'),
            ValidationMessage.hint('Second'),
          ],
          statusInfo: 'OK',
          executionTime: const Duration(milliseconds: 10),
        );
        final identicalFields = ValidationResult(
          ValidationType.success,
          const <ValidationMessage>[
            ValidationMessage('First', piiStrippedMessage: 'First redacted'),
            ValidationMessage.hint('Second'),
          ],
          statusInfo: 'OK',
          executionTime: const Duration(milliseconds: 10),
        );
        final differentType = ValidationResult(
          ValidationType.partial,
          baseline.messages,
          statusInfo: 'OK',
          executionTime: const Duration(milliseconds: 10),
        );
        final differentMessages = ValidationResult(
          ValidationType.success,
          const <ValidationMessage>[
            ValidationMessage('First', piiStrippedMessage: 'Different redacted'),
            ValidationMessage.hint('Second'),
          ],
          statusInfo: 'OK',
          executionTime: const Duration(milliseconds: 10),
        );
        final reorderedMessages = ValidationResult(
          ValidationType.success,
          const <ValidationMessage>[
            ValidationMessage.hint('Second'),
            ValidationMessage('First', piiStrippedMessage: 'First redacted'),
          ],
          statusInfo: 'OK',
          executionTime: const Duration(milliseconds: 10),
        );
        final differentStatusInfo = ValidationResult(
          ValidationType.success,
          baseline.messages,
          statusInfo: 'Different',
          executionTime: const Duration(milliseconds: 10),
        );
        final differentExecutionTime = ValidationResult(
          ValidationType.success,
          baseline.messages,
          statusInfo: 'OK',
          executionTime: const Duration(milliseconds: 20),
        );

        expect(baseline, equals(identicalFields));
        expect(baseline.hashCode, equals(identicalFields.hashCode));

        expect(baseline, isNot(equals(differentType)));
        expect(baseline, isNot(equals(differentMessages)));
        expect(baseline, isNot(equals(reorderedMessages)));
        expect(baseline, isNot(equals(differentStatusInfo)));
        expect(baseline, isNot(equals(differentExecutionTime)));
        expect(baseline.hashCode, isNot(equals(differentExecutionTime.hashCode)));
      });

      test('fromJson throws FormatException when required fields or elements are invalid', () {
        expect(
          () => ValidationResult.fromJson(const <String, Object?>{
            ValidationResult.messagesKey: <Map<String, Object?>>[],
          }),
          _throwsFormatExceptionContaining('Missing required "${ValidationResult.typeKey}"'),
        );
        expect(
          () => ValidationResult.fromJson(const <String, Object?>{
            ValidationResult.typeKey: 123,
            ValidationResult.messagesKey: <Map<String, Object?>>[],
          }),
          _throwsFormatExceptionContaining('Invalid "${ValidationResult.typeKey}"'),
        );
        expect(
          () => ValidationResult.fromJson(const <String, Object?>{
            ValidationResult.typeKey: 'unsupported_future_type',
            ValidationResult.messagesKey: <Map<String, Object?>>[],
          }),
          _throwsFormatExceptionContaining('unsupported_future_type'),
        );
        expect(
          () => ValidationResult.fromJson(const <String, Object?>{
            ValidationResult.typeKey: 'success',
            ValidationResult.statusInfoKey: false,
            ValidationResult.messagesKey: <Map<String, Object?>>[],
          }),
          _throwsFormatExceptionContaining('Invalid "${ValidationResult.statusInfoKey}"'),
        );
        expect(
          () => ValidationResult.fromJson(const <String, Object?>{
            ValidationResult.typeKey: 'success',
          }),
          _throwsFormatExceptionContaining('Missing required "${ValidationResult.messagesKey}"'),
        );
        expect(
          () => ValidationResult.fromJson(const <String, Object?>{
            ValidationResult.typeKey: 'success',
            ValidationResult.messagesKey: null,
          }),
          _throwsFormatExceptionContaining('Missing required "${ValidationResult.messagesKey}"'),
        );
        expect(
          () => ValidationResult.fromJson(const <String, Object?>{
            ValidationResult.typeKey: 'success',
            ValidationResult.messagesKey: 'not-a-list',
          }),
          _throwsFormatExceptionContaining('Invalid "${ValidationResult.messagesKey}"'),
        );
        expect(
          () => ValidationResult.fromJson(const <String, Object?>{
            ValidationResult.typeKey: 'success',
            ValidationResult.messagesKey: <Object?>['not-a-map'],
          }),
          _throwsFormatExceptionContaining('Invalid "${ValidationResult.messagesKey}" element'),
        );
        expect(
          () => ValidationResult.fromJson(const <String, Object?>{
            ValidationResult.typeKey: 'success',
            ValidationResult.messagesKey: <Object?>[
              <Object?, Object?>{
                ValidationMessage.typeKey: 'information',
                ValidationMessage.messageKey: 'ok',
                ValidationMessage.piiStrippedMessageKey: 'ok',
              },
            ],
          }),
          _throwsFormatExceptionContaining('Invalid "${ValidationResult.messagesKey}" element'),
        );
      });

      test('listFromJson parses valid iterables and throws FormatException on invalid inputs', () {
        final expected = ValidationResult(ValidationType.success, const <ValidationMessage>[
          ValidationMessage('All clear', piiStrippedMessage: 'Clear'),
        ], statusInfo: 'OK');

        expect(ValidationResult.listFromJson(const <Object?>[]), isEmpty);
        expect(ValidationResult.listFromJson(<Object?>[expected.toMap()]), <ValidationResult>[
          expected,
        ]);
        expect(
          ValidationResult.listFromJson(<Object?>[expected.toMap()].where((Object? _) => true)),
          <ValidationResult>[expected],
        );

        expect(
          () => ValidationResult.listFromJson(null),
          _throwsFormatExceptionContaining('Invalid ValidationResult list'),
        );
        expect(
          () => ValidationResult.listFromJson('not-a-list'),
          _throwsFormatExceptionContaining('Invalid ValidationResult list'),
        );
        expect(
          () => ValidationResult.listFromJson(const <Object?>['not-a-map']),
          _throwsFormatExceptionContaining('Invalid ValidationResult entry'),
        );
        expect(
          () => ValidationResult.listFromJson(const <Object?>[
            <Object?, Object?>{
              ValidationResult.typeKey: 'success',
              ValidationResult.messagesKey: <Map<String, Object?>>[],
            },
          ]),
          _throwsFormatExceptionContaining('Invalid ValidationResult entry'),
        );
        expect(
          () => ValidationResult.listFromJson(const <Object?>[
            <String, Object?>{ValidationResult.typeKey: 'success'},
          ]),
          _throwsFormatExceptionContaining('Missing required "${ValidationResult.messagesKey}"'),
        );
      });
    });
  });
}

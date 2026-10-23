// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_tools_core/json.dart';
import 'package:test/test.dart';

void main() {
  const fieldKey = 'field';
  const secretKey = 'secret';
  const secretValue = 'super-sensitive-user-path-or-token';

  Matcher throwsFormatExceptionWith(String message) {
    return throwsA(
      isA<FormatException>().having(
        (FormatException e) => e.message,
        'message',
        allOf(contains(message), isNot(contains(secretValue))),
      ),
    );
  }

  group('ExtensionJsonParsing', () {
    group('requiredField', () {
      test('extracts present field with matching type', () {
        const json = <String, Object?>{fieldKey: 'value'};
        expect(json.requiredField<String>(fieldKey), 'value');
      });

      test('throws FormatException when key is missing or null for non-nullable type', () {
        const emptyJson = <String, Object?>{};
        expect(() => emptyJson.requiredField<String>(fieldKey), throwsFormatException);

        const nullJson = <String, Object?>{fieldKey: null};
        expect(() => nullJson.requiredField<String>(fieldKey), throwsFormatException);
      });

      test('throws FormatException when value has wrong type without leaking map contents', () {
        const json = <String, Object?>{fieldKey: 42, secretKey: secretValue};
        expect(
          () => json.requiredField<String>(fieldKey),
          throwsA(
            isA<FormatException>().having(
              (FormatException e) => e.message,
              'message',
              allOf(
                contains('Invalid "$fieldKey": expected String, got int.'),
                isNot(contains(secretValue)),
              ),
            ),
          ),
        );
      });
    });

    group('optionalField', () {
      test('extracts present field with matching type', () {
        const json = <String, Object?>{fieldKey: 'value'};
        expect(json.optionalField<String>(fieldKey, defaultValue: 'default'), 'value');
      });

      test('returns defaultValue when key is missing or null', () {
        const emptyJson = <String, Object?>{};
        expect(emptyJson.optionalField<String>(fieldKey, defaultValue: 'default'), 'default');
        expect(emptyJson.optionalField<String?>(fieldKey, defaultValue: null), isNull);

        const nullJson = <String, Object?>{fieldKey: null};
        expect(nullJson.optionalField<String>(fieldKey, defaultValue: 'default'), 'default');
        expect(nullJson.optionalField<String?>(fieldKey, defaultValue: 'fallback'), 'fallback');
      });

      test(
        'throws FormatException when non-null value has wrong type without leaking map contents',
        () {
          const json = <String, Object?>{fieldKey: 123, secretKey: secretValue};
          expect(
            () => json.optionalField<String>(fieldKey, defaultValue: 'default'),
            throwsA(
              isA<FormatException>().having(
                (FormatException e) => e.message,
                'message',
                allOf(
                  contains('Invalid "$fieldKey": expected String, got int.'),
                  isNot(contains(secretValue)),
                ),
              ),
            ),
          );
          expect(
            () => json.optionalField<String?>(fieldKey, defaultValue: null),
            throwsFormatException,
          );
        },
      );
    });

    group('nullableField', () {
      test('extracts present field or returns null when missing or null', () {
        const presentJson = <String, Object?>{fieldKey: 'value'};
        expect(presentJson.nullableField<String>(fieldKey), 'value');

        const emptyJson = <String, Object?>{};
        expect(emptyJson.nullableField<String>(fieldKey), isNull);

        const nullJson = <String, Object?>{fieldKey: null};
        expect(nullJson.nullableField<String>(fieldKey), isNull);
      });

      test('throws FormatException when non-null value has wrong type', () {
        const json = <String, Object?>{fieldKey: 123};
        expect(() => json.nullableField<String>(fieldKey), throwsFormatException);
      });
    });

    group('stringIterable', () {
      test('extracts list or set of strings', () {
        const listJson = <String, Object?>{
          fieldKey: <Object?>['a', 'b'],
        };
        expect(listJson.stringIterable(fieldKey), const <String>['a', 'b']);

        const setJson = <String, Object?>{
          fieldKey: <Object?>{'x', 'y'},
        };
        expect(setJson.stringIterable(fieldKey), const <String>['x', 'y']);
      });

      test('returns empty iterable or defaultValue when key is missing or null', () {
        const emptyJson = <String, Object?>{};
        expect(emptyJson.stringIterable(fieldKey), isEmpty);
        expect(
          emptyJson.stringIterable(fieldKey, defaultValue: const <String>['fallback']),
          const <String>['fallback'],
        );

        const nullJson = <String, Object?>{fieldKey: null};
        expect(nullJson.stringIterable(fieldKey), isEmpty);
        expect(
          nullJson.stringIterable(fieldKey, defaultValue: const <String>{'linux'}),
          const <String>{'linux'},
        );
      });

      test('throws FormatException when value is not an Iterable without leaking map contents', () {
        const json = <String, Object?>{fieldKey: 'not-a-list', secretKey: secretValue};
        expect(
          () => json.stringIterable(fieldKey),
          throwsA(
            isA<FormatException>().having(
              (FormatException e) => e.message,
              'message',
              allOf(
                contains('Invalid "$fieldKey": expected Iterable<String>, got String.'),
                isNot(contains(secretValue)),
              ),
            ),
          ),
        );
      });

      test(
        'throws FormatException when an element is not a String without leaking map contents',
        () {
          const json = <String, Object?>{
            fieldKey: <Object?>['valid', 42],
            secretKey: secretValue,
          };
          expect(
            () => json.stringIterable(fieldKey),
            throwsA(
              isA<FormatException>().having(
                (FormatException e) => e.message,
                'message',
                allOf(
                  contains('Invalid "$fieldKey" element: expected String, got int.'),
                  isNot(contains(secretValue)),
                ),
              ),
            ),
          );
        },
      );
    });

    group('stringMap', () {
      test('extracts present map with String keys and values', () {
        const json = <String, Object?>{
          fieldKey: <String, Object?>{'a': '1', 'b': '2'},
        };
        expect(json.stringMap(fieldKey), const <String, String>{'a': '1', 'b': '2'});
      });

      test('throws FormatException when key is missing or null without leaking map contents', () {
        const missingJson = <String, Object?>{secretKey: secretValue};
        expect(
          () => missingJson.stringMap(fieldKey),
          throwsFormatExceptionWith(
            'Missing required "$fieldKey" (expected Map<String, Object?>).',
          ),
        );

        const nullJson = <String, Object?>{fieldKey: null, secretKey: secretValue};
        expect(
          () => nullJson.stringMap(fieldKey),
          throwsFormatExceptionWith(
            'Missing required "$fieldKey" (expected Map<String, Object?>).',
          ),
        );
      });

      test('throws FormatException when value is not a Map without leaking map contents', () {
        const json = <String, Object?>{fieldKey: 'not-a-map', secretKey: secretValue};
        expect(
          () => json.stringMap(fieldKey),
          throwsFormatExceptionWith(
            'Invalid "$fieldKey": expected Map<String, Object?>, got String.',
          ),
        );
      });

      test('throws FormatException when a value is not a String without leaking map contents', () {
        const json = <String, Object?>{
          fieldKey: <String, Object?>{'key': 42},
          secretKey: secretValue,
        };
        expect(
          () => json.stringMap(fieldKey),
          throwsFormatExceptionWith('Invalid "key" value: expected String, got int.'),
        );
      });
    });

    group('directoryUri', () {
      test('extracts present valid trailing-slash-terminated absolute file URI', () {
        const json = <String, Object?>{fieldKey: 'file:///path/to/dir/'};
        expect(json.directoryUri(fieldKey), Uri.parse('file:///path/to/dir/'));
      });

      test('extracts present valid Windows UNC directory file URI', () {
        const json = <String, Object?>{fieldKey: 'file://server/share/dir/'};
        expect(json.directoryUri(fieldKey), Uri.parse('file://server/share/dir/'));
      });

      test('throws FormatException when key is missing or null', () {
        const emptyJson = <String, Object?>{};
        expect(() => emptyJson.directoryUri(fieldKey), throwsFormatException);

        const nullJson = <String, Object?>{fieldKey: null};
        expect(() => nullJson.directoryUri(fieldKey), throwsFormatException);
      });

      test('throws FormatException when value is not a String without leaking map contents', () {
        const json = <String, Object?>{fieldKey: 42, secretKey: secretValue};
        expect(
          () => json.directoryUri(fieldKey),
          throwsFormatExceptionWith('Invalid "$fieldKey": expected String, got int.'),
        );
      });

      test('throws FormatException when URI is relative without leaking map contents', () {
        const json = <String, Object?>{fieldKey: 'relative/dir/', secretKey: secretValue};
        expect(
          () => json.directoryUri(fieldKey),
          throwsFormatExceptionWith(
            'Invalid "$fieldKey": expected trailing-slash-terminated absolute file: URI.',
          ),
        );
      });

      test('throws FormatException when URI does not end with trailing slash without leaking map contents', () {
        const json = <String, Object?>{fieldKey: 'file:///path/to/dir', secretKey: secretValue};
        expect(
          () => json.directoryUri(fieldKey),
          throwsFormatExceptionWith(
            'Invalid "$fieldKey": expected trailing-slash-terminated absolute file: URI.',
          ),
        );
      });

      test('throws FormatException when URI is not a file: URI without leaking map contents', () {
        const json = <String, Object?>{fieldKey: 'http://example.com/dir/', secretKey: secretValue};
        expect(
          () => json.directoryUri(fieldKey),
          throwsFormatExceptionWith(
            'Invalid "$fieldKey": expected trailing-slash-terminated absolute file: URI.',
          ),
        );
      });

      test('throws FormatException when URI has a query without leaking map contents', () {
        const json = <String, Object?>{
          fieldKey: 'file:///path/to/dir/?query=1',
          secretKey: secretValue,
        };
        expect(
          () => json.directoryUri(fieldKey),
          throwsFormatExceptionWith(
            'Invalid "$fieldKey": expected trailing-slash-terminated absolute file: URI.',
          ),
        );
      });

      test('throws FormatException when URI has a fragment without leaking map contents', () {
        const json = <String, Object?>{
          fieldKey: 'file:///path/to/dir/#frag',
          secretKey: secretValue,
        };
        expect(
          () => json.directoryUri(fieldKey),
          throwsFormatExceptionWith(
            'Invalid "$fieldKey": expected trailing-slash-terminated absolute file: URI.',
          ),
        );
      });
    });

    test('parses real jsonDecode map and list structures', () {
      final decoded = jsonDecode(
        '{"name": "ext", "count": 3, "tags": ["one", "two"], '
        '"defines": {"FOO": "bar"}, "dir": "file:///path/to/dir/", "extra": null}',
      ) as Map<String, Object?>;
      expect(decoded.requiredField<String>('name'), 'ext');
      expect(decoded.optionalField<int>('count', defaultValue: 0), 3);
      expect(decoded.nullableField<String>('extra'), isNull);
      expect(decoded.stringIterable('tags'), const <String>['one', 'two']);
      expect(decoded.stringMap('defines'), const <String, String>{'FOO': 'bar'});
      expect(decoded.directoryUri('dir'), Uri.parse('file:///path/to/dir/'));
    });
  });

  group('ExtensionUriValidation', () {
    test('isValidFileUri returns true only for absolute file URIs', () {
      expect(Uri.file('/tmp/app.apk').isValidFileUri, isTrue);
      expect(Uri.directory('/tmp/app.bundle').isValidFileUri, isTrue);
      expect(Uri.parse('relative/app.apk').isValidFileUri, isFalse);
      expect(Uri.parse('/tmp/without_scheme').isValidFileUri, isFalse);
      expect(Uri.parse('https://example.com/app.apk').isValidFileUri, isFalse);
      expect(Uri.parse('').isValidFileUri, isFalse);
    });
  });
}

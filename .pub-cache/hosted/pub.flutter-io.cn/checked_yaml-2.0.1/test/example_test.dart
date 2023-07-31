// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:checked_yaml/checked_yaml.dart';
import 'package:test/test.dart';

import '../example/example.dart' as example;

void main() {
  test('valid input', () {
    expect(
      () => _run('{"name": "bob", "count": 42}'),
      prints('''
Configuration: {name: bob, count: 42}
'''),
    );
  });

  test('empty map', () {
    _expectThrows(
      '{}',
      r'''
line 1, column 1: Required keys are missing: name.
  ╷
1 │ {}
  │ ^^
  ╵''',
    );
  });

  test('missing count', () {
    _expectThrows(
      '{"name":"something"}',
      r'''
line 1, column 1: Missing key "count". type 'Null' is not a subtype of type 'int' in type cast
  ╷
1 │ {"name":"something"}
  │ ^^^^^^^^^^^^^^^^^^^^
  ╵''',
    );
  });

  test('not a map', () {
    _expectThrows(
      '42',
      r'''
line 1, column 1: Not a map
  ╷
1 │ 42
  │ ^^
  ╵''',
    );
  });

  test('invalid yaml', () {
    _expectThrows(
      '{',
      r'''
line 1, column 2: Expected node content.
  ╷
1 │ {
  │  ^
  ╵''',
    );
  });

  test('duplicate keys', () {
    _expectThrows(
      '{"a":null, "a":null}',
      r'''
line 1, column 12: Duplicate mapping key.
  ╷
1 │ {"a":null, "a":null}
  │            ^^^
  ╵''',
    );
  });

  test('unexpected key', () {
    _expectThrows(
      '{"bob": 42}',
      r'''
line 1, column 2: Unrecognized keys: [bob]; supported keys: [name, count]
  ╷
1 │ {"bob": 42}
  │  ^^^^^
  ╵''',
    );
  });

  test('bad name type', () {
    _expectThrows(
      '{"name": 42, "count": 42}',
      r'''
line 1, column 10: Unsupported value for "name". type 'int' is not a subtype of type 'String' in type cast
  ╷
1 │ {"name": 42, "count": 42}
  │          ^^
  ╵''',
    );
  });

  test('bad name contents', () {
    _expectThrows(
      '{"name": "", "count": 42}',
      r'''
line 1, column 10: Unsupported value for "name". Cannot be empty.
  ╷
1 │ {"name": "", "count": 42}
  │          ^^
  ╵''',
    );
  });
}

void _expectThrows(String yamlContent, matcher) => expect(
      () => _run(yamlContent),
      throwsA(
        isA<ParsedYamlException>().having(
          (e) {
            printOnFailure("r'''\n${e.formattedMessage}'''");
            return e.formattedMessage;
          },
          'formattedMessage',
          matcher,
        ),
      ),
    );

void _run(String yamlContent) => example.main([yamlContent]);

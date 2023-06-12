// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

final _examplePath = p.join('example', 'example.dart');

final _readmeContent = File('README.md').readAsStringSync();
final _exampleContent = File(_examplePath).readAsStringSync();

const _memberEnd = '\n}';

void _member(String startToken) {
  final start = _exampleContent.indexOf(startToken);
  expect(start, greaterThanOrEqualTo(0));

  final classEnd = _exampleContent.indexOf(_memberEnd, start);
  expect(classEnd, greaterThan(start));

  final content =
      _exampleContent.substring(start, classEnd + _memberEnd.length).trim();

  expect(_readmeContent, contains('''
```dart
$content
```
'''));
}

void main() {
  test('class test', () {
    _member('\n@JsonSerializable');
  });

  test('main test', () {
    _member('\nvoid main(');
  });

  test('ran example', () async {
    const inputContent = '{"name": "", "count": 1}';
    const errorContent = r'''
Unhandled exception:
ParsedYamlException: line 1, column 10: Unsupported value for "name". Cannot be empty.
  ╷
1 │ {"name": "", "count": 1}
  │          ^^
  ╵''';

    expect(_readmeContent, contains('''
```console
\$ dart example/example.dart '$inputContent'
$errorContent
```'''));

    final proc = await TestProcess.start(
      Platform.resolvedExecutable,
      [_examplePath, inputContent],
    );
    await expectLater(
      proc.stderr,
      emitsInOrder(LineSplitter.split(errorContent)),
    );

    await proc.shouldExit(isNot(0));
  });
}

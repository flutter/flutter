// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:convert';
import 'dart:io';

import 'package:source_helper/source_helper.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main() {
  test('generate and validate', () async {
    final originalList = _decodeJsonStringList(
      File('third_party/blns/big_list_of_naughty_strings.json')
          .readAsStringSync(),
    );

    final dartStringList =
        originalList.map(escapeDartString).map((e) => '$e,').join('\n');

    final dartSource = _template.replaceAll(r'/*values*/', dartStringList);

    await d.file('print_items.dart', dartSource).create();

    final result = Process.runSync(
      'dart',
      ['print_items.dart'],
      workingDirectory: d.sandbox,
    );

    expect(
      result.exitCode,
      0,
      reason: '''
Process did not complete!
Exit code: ${result.exitCode}
${result.stdout}
${result.stderr}''',
    );

    final roundTripList = _decodeJsonStringList(result.stdout as String);

    expect(originalList, roundTripList);
  });
}

List<String> _decodeJsonStringList(String input) =>
    (jsonDecode(input) as List).cast<String>();

const _template = r'''
import 'dart:convert';

void main() {
  print(jsonEncode(_values));
}

const _values = <String>[
  /*values*/
];
''';

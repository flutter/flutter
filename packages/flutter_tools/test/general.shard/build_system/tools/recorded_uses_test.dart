// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_system/tools/recorded_uses.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:record_use/record_use.dart';

import '../../../src/common.dart';

void main() {
  late Directory buildDir;

  setUp(() {
    buildDir = MemoryFileSystem.test().directory('build')..createSync();
  });

  void write(String name, String content) {
    buildDir.childFile(name).writeAsStringSync(content);
  }

  String recordingOf(String argument) => json.encode(<String, Object?>{
    'constants': <Object?>[
      <String, Object?>{'type': 'string', 'value': argument},
    ],
    'definitions': <Object?>[
      <String, Object?>{
        'path': <Object?>[
          <String, Object?>{
            'kind': 'method',
            'name': 'asset',
            'disambiguators': <String>['static'],
          },
        ],
        'uri': 'package:example/assets.dart',
      },
    ],
    'loading_units': <Object?>[
      <String, Object?>{'name': 'main'},
    ],
    'uses': <String, Object?>{
      'static_calls': <Object?>[
        <String, Object?>{
          'definition_index': 0,
          'uses': <Object?>[
            <String, Object?>{
              'loading_unit_index': 0,
              'positional': <int>[0],
              'type': 'with_arguments',
            },
          ],
        },
      ],
    },
  });

  List<String> argumentsOf(Recordings recordings) => <String>[
    for (final CallReference call in recordings.calls.values.expand(
      (List<CallReference> calls) => calls,
    ))
      if (call case CallWithArguments(positionalArguments: [StringConstant(:final String value)]))
        value,
  ];

  testWithoutContext('returns null when no file exists', () {
    expect(readRecordedUses(buildDir), isNull);
  });

  testWithoutContext('returns null when every file is empty', () {
    write('recorded_uses.json', '');
    expect(readRecordedUses(buildDir), isNull);
  });

  testWithoutContext('reads {} as no uses', () {
    write('recorded_uses.json', '{}');

    final Recordings? recordings = readRecordedUses(buildDir);

    expect(recordings, isNotNull);
    expect(recordings!.calls, isEmpty);
    expect(recordings.instances, isEmpty);
  });

  testWithoutContext('merges the JavaScript and WebAssembly recordings', () {
    write('recorded_uses_js.json', recordingOf('from_js'));
    write('recorded_uses_wasm.json', recordingOf('from_wasm'));

    expect(
      argumentsOf(readRecordedUses(buildDir)!),
      unorderedEquals(<String>['from_js', 'from_wasm']),
    );
  });

  testWithoutContext('skips an empty file next to a recorded one', () {
    write('recorded_uses_js.json', '');
    write('recorded_uses_wasm.json', recordingOf('from_wasm'));

    expect(argumentsOf(readRecordedUses(buildDir)!), <String>['from_wasm']);
  });

  testWithoutContext('throws on a file that is not JSON', () {
    write('recorded_uses.json', 'not json');
    expect(() => readRecordedUses(buildDir), throwsFormatException);
  });

  testWithoutContext('throws on a file that is not a JSON object', () {
    write('recorded_uses.json', '[]');
    expect(() => readRecordedUses(buildDir), throwsFormatException);
  });
}

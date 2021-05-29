// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'common.dart';

void main() {
  test('analyze_sample_code', () {
    final ProcessResult process = Process.runSync(
      '../../bin/cache/dart-sdk/bin/dart',
      <String>['analyze_sample_code.dart', 'test/analyze-sample-code-test-input'],
    );
    final List<String> stdoutLines = process.stdout.toString().split('\n');
    final List<String> stderrLines = process.stderr.toString().split('\n')
      ..removeWhere((String line) => line.startsWith('Analyzer output:') || line.startsWith('Building flutter tool...'));
    expect(process.exitCode, isNot(equals(0)));
    expect(stderrLines, <String>[
      'In sample starting at known_broken_documentation.dart:117:bool? _visible = true;',
      '>>> info: Use late for private members with non-nullable type (use_late_for_private_fields_and_variables)',
      'In sample starting at known_broken_documentation.dart:117:      child: Text(title),',
      '>>> error: The final variable \'title\' can\'t be read because it is potentially unassigned at this point (read_potentially_unassigned_final)',
      'known_broken_documentation.dart:30:9: new Opacity(',
      '>>> info: Unnecessary new keyword (unnecessary_new)',
      'known_broken_documentation.dart:62:9: new Opacity(',
      '>>> info: Unnecessary new keyword (unnecessary_new)',
      'known_broken_documentation.dart:95:9: const text0 = Text(\'Poor wandering ones!\');',
      '>>> info: Specify type annotations (always_specify_types)',
      'known_broken_documentation.dart:103:9: const text1 = _Text(\'Poor wandering ones!\');',
      '>>> info: Specify type annotations (always_specify_types)',
      'known_broken_documentation.dart:111:9: final String? bar = \'Hello\';',
      '>>> info: Prefer const over final for declarations (prefer_const_declarations)',
      'known_broken_documentation.dart:111:23: final String? bar = \'Hello\';',
      '>>> info: Use a non-nullable type for a final variable initialized with a non-nullable value (unnecessary_nullable_for_final_variable_declarations)',
      'known_broken_documentation.dart:112:9: final int foo = null;',
      '>>> info: Prefer const over final for declarations (prefer_const_declarations)',
      'known_broken_documentation.dart:112:25: final int foo = null;',
      '>>> error: A value of type \'Null\' can\'t be assigned to a variable of type \'int\' (invalid_assignment)',
      '',
      'Found 2 sample code errors.',
      ''
    ]);
    expect(stdoutLines, <String>[
      'Found 8 snippet code blocks, 0 sample code sections, and 2 dartpad sections.',
      'Starting analysis of code samples.',
      '',
    ]);
  }, skip: Platform.isWindows);
}

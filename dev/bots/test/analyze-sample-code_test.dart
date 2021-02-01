// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'common.dart';

void main() {
  test('analyze-sample-code', () {
    final ProcessResult process = Process.runSync(
      '../../bin/cache/dart-sdk/bin/dart',
      <String>['analyze-sample-code.dart', 'test/analyze-sample-code-test-input'],
    );
    final List<String> stdoutLines = process.stdout.toString().split('\n');
    final List<String> stderrLines = process.stderr.toString().split('\n')
      ..removeWhere((String line) => line.startsWith('Analyzer output:') || line.startsWith('Building flutter tool...'));
    expect(process.exitCode, isNot(equals(0)));
    expect(stderrLines, <String>[
      'In sample starting at known_broken_documentation.dart:117:      child: Text(title),',
      '>>> The final variable \'title\' can\'t be read because it is potentially unassigned at this point (read_potentially_unassigned_final)',
      'known_broken_documentation.dart:30:9: new Opacity(',
      '>>> Unnecessary new keyword (unnecessary_new)',
      'known_broken_documentation.dart:62:9: new Opacity(',
      '>>> Unnecessary new keyword (unnecessary_new)',
      'known_broken_documentation.dart:112:25: final int foo = null;',
      '>>> A value of type \'Null\' can\'t be assigned to a variable of type \'int\' (invalid_assignment)',
      '',
      'Found 2 sample code errors.',
      ''
    ]);
    expect(stdoutLines, <String>[
      'Found 8 sample code sections.',
      'Starting analysis of code samples.',
      '',
    ]);
  }, skip: Platform.isWindows);
}

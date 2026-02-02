// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('unit_coverage_test.');
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  testWithoutContext('Can parse and output summaries for code coverage', () async {
    final File coverageFile = tempDir.childFile('info.lcov')
      ..writeAsStringSync('''
SF:lib/src/artifacts.dart
DA:15,10
DA:17,7
DA:19,7
DA:20,7
DA:22,7
DA:324,10
DA:724,0
DA:727,2
DA:729,3
DA:732,0
DA:737,1
LF:443
LH:292
end_of_record
SF:lib/src/base/common.dart
DA:13,7
DA:14,7
DA:22,7
DA:27,3
DA:28,6
DA:40,7
LF:6
LH:6
end_of_record
''');

    final String dartScript = fileSystem.path.join(getFlutterRoot(), 'bin', 'dart');
    final String coverageScript = fileSystem.path.join(
      getFlutterRoot(),
      'packages',
      'flutter_tools',
      'tool',
      'unit_coverage.dart',
    );
    final ProcessResult result = await const LocalProcessManager().run(<String>[
      dartScript,
      coverageScript,
      coverageFile.path,
    ]);

    // May contain other output if building flutter tool.
    expect(
      result.stdout.toString().split('\n'),
      containsAll(<Matcher>[
        contains('lib/src/artifacts.dart: 81.82%'),
        contains('lib/src/base/common.dart: 100.00%'),
      ]),
    );
  });

  testWithoutContext('Handles empty files (zero lines) without producing NaN', () async {
    final File coverageFile = tempDir.childFile('info.lcov')
      ..writeAsStringSync('''
SF:lib/empty_stub.dart
end_of_record
SF:lib/src/artifacts.dart
DA:15,10
DA:17,7
LF:2
LH:2
end_of_record
''');

    final String dartScript = fileSystem.path.join(getFlutterRoot(), 'bin', 'dart');
    final String coverageScript = fileSystem.path.join(
      getFlutterRoot(),
      'packages',
      'flutter_tools',
      'tool',
      'unit_coverage.dart',
    );
    final ProcessResult result = await const LocalProcessManager().run(<String>[
      dartScript,
      coverageScript,
      coverageFile.path,
    ]);

    final String output = result.stdout.toString();
    // Empty files should show 0.00% not NaN%
    expect(output, contains('lib/empty_stub.dart: 0.00%'));
    // Should not contain NaN anywhere in output
    expect(output, isNot(contains('NaN')));
    // Overall should be a valid percentage, not NaN
    expect(output, contains('OVERALL: 50.00%'));
  });

  testWithoutContext('Handles projects with only empty files', () async {
    final File coverageFile = tempDir.childFile('info.lcov')
      ..writeAsStringSync('''
SF:lib/empty_file.dart
end_of_record
SF:lib/another_empty.dart
end_of_record
''');

    final String dartScript = fileSystem.path.join(getFlutterRoot(), 'bin', 'dart');
    final String coverageScript = fileSystem.path.join(
      getFlutterRoot(),
      'packages',
      'flutter_tools',
      'tool',
      'unit_coverage.dart',
    );
    final ProcessResult result = await const LocalProcessManager().run(<String>[
      dartScript,
      coverageScript,
      coverageFile.path,
    ]);

    final String output = result.stdout.toString();
    // Each empty file should show 0.00%
    expect(output, contains('lib/empty_file.dart: 0.00%'));
    expect(output, contains('lib/another_empty.dart: 0.00%'));
    // Overall should be 0.00%, not NaN
    expect(output, contains('OVERALL: 0.00%'));
    // Should not contain NaN anywhere
    expect(output, isNot(contains('NaN')));
  });

  testWithoutContext('Correctly sorts files with mixed coverage including empty files', () async {
    final File coverageFile = tempDir.childFile('info.lcov')
      ..writeAsStringSync('''
SF:lib/well_tested.dart
DA:1,1
DA:2,1
DA:3,1
DA:4,1
DA:5,0
end_of_record
SF:lib/empty.dart
end_of_record
SF:lib/poor.dart
DA:10,0
DA:11,0
DA:12,1
end_of_record
''');

    final String dartScript = fileSystem.path.join(getFlutterRoot(), 'bin', 'dart');
    final String coverageScript = fileSystem.path.join(
      getFlutterRoot(),
      'packages',
      'flutter_tools',
      'tool',
      'unit_coverage.dart',
    );
    final ProcessResult result = await const LocalProcessManager().run(<String>[
      dartScript,
      coverageScript,
      coverageFile.path,
    ]);

    final String output = result.stdout.toString();
    final List<String> lines = output.split('\n');

    // Find indices of each file in output
    final int emptyIndex = lines.indexWhere((String line) => line.contains('lib/empty.dart'));
    final int poorIndex = lines.indexWhere((String line) => line.contains('lib/poor.dart'));
    final int wellTestedIndex = lines.indexWhere((String line) => line.contains('lib/well_tested.dart'));

    // Verify sorting order: empty (0%) < poor (33.33%) < well_tested (80%)
    expect(emptyIndex, lessThan(poorIndex), reason: 'empty (0%) should come before poor (33%)');
    expect(poorIndex, lessThan(wellTestedIndex), reason: 'poor (33%) should come before well_tested (80%)');

    // Verify percentages
    expect(output, contains('lib/empty.dart: 0.00%'));
    expect(output, contains('lib/poor.dart: 33.33%'));
    expect(output, contains('lib/well_tested.dart: 80.00%'));

    // Overall should be valid
    expect(output, isNot(contains('NaN')));
    expect(output, contains('OVERALL: 37.50%'));
  });
}

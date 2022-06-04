// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'common.dart';

void main() {
  // These tests don't run on Windows because the sample analyzer doesn't
  // support Windows as a platform, since it is only run on Linux in the
  // continuous integration tests.
  if (Platform.isWindows) {
    return;
  }

  test('analyze_snippet_code smoke test', () {
    final ProcessResult process = Process.runSync(
      '../../bin/cache/dart-sdk/bin/dart',
      <String>['analyze_snippet_code.dart', '--no-include-dart-ui', 'test/analyze-snippet-code-test-input'],
    );
    final List<String> stdoutLines = process.stdout.toString().split('\n');
    final List<String> stderrLines = process.stderr.toString().split('\n');
    expect(process.exitCode, isNot(equals(0)));
    expect(stderrLines, containsAll(<Object>[
      'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:138:25:     child: Text(title),',
      matches(RegExp(r">>> error: The final variable 'title' can't be read because (it is|it's) potentially unassigned at this point \(read_potentially_unassigned_final\)")),
      'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:30:9: new Opacity(',
      '>>> info: Unnecessary new keyword (unnecessary_new)',
      'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:62:9: new Opacity(',
      '>>> info: Unnecessary new keyword (unnecessary_new)',
      "dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:111:9: final String? bar = 'Hello';",
      '>>> info: Prefer const over final for declarations (prefer_const_declarations)',
      'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:112:9: final int foo = null;',
      '>>> info: Prefer const over final for declarations (prefer_const_declarations)',
      'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:112:25: final int foo = null;',
      ">>> error: A value of type 'Null' can't be assigned to a variable of type 'int' (invalid_assignment)",
      'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:120:24: const SizedBox(),',
      '>>> error: Unexpected comma at end of snippet code. (missing_identifier)',
      'Found 1 snippet code errors.',
    ]));
    expect(stdoutLines, containsAll(<String>[
      'Found 13 snippet code blocks',
      'Starting analysis of code snippets.',
    ]));
  });
  test('Analyzes dart:ui code', () {
    final ProcessResult process = Process.runSync(
      '../../bin/cache/dart-sdk/bin/dart',
      <String>[
        'analyze_snippet_code.dart',
        '--dart-ui-location=test/analyze-snippet-code-test-dart-ui',
        'test/analyze-snippet-code-test-input',
      ],
    );
    final List<String> stdoutLines = process.stdout.toString().split('\n');
    final List<String> stderrLines = process.stderr.toString().split('\n');
    expect(process.exitCode, isNot(equals(0)));
    expect(stderrLines, containsAll(<String>[
      'dev/bots/test/analyze-snippet-code-test-dart-ui/ui.dart:19:11:   error;',
      ">>> error: Variables must be declared using the keywords 'const', 'final', 'var' or a type name (missing_const_final_var_or_type)",
      'dev/bots/test/analyze-snippet-code-test-dart-ui/ui.dart:23:11:   @keepToString',
      ">>> error: Undefined name 'keepToString' used as an annotation (undefined_annotation)",
    ]));
    expect(stdoutLines, containsAll(<String>[
      // There is one snippet code section in the test's dummy dart:ui code.
      'Found 14 snippet code blocks',
      'Starting analysis of code snippets.',
    ]));
  });
}

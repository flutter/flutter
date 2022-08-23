// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// we ignore these so that the format of the strings below matches what package:test prints, to make maintenance easier
// ignore_for_file: avoid_escaping_inner_quotes
// ignore_for_file: use_raw_strings

import 'dart:io';

import 'common.dart';

const List<String> expectedMainErrors = <String>[
  'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:30:5: Unnecessary new keyword (expression) (unnecessary_new)',
  'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:103:5: Specify type annotations (statement) (always_specify_types)',
  'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:111:5: Prefer const over final for declarations (top-level declaration) (prefer_const_declarations)',
  'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:111:19: Use a non-nullable type for a final variable initialized with a non-nullable value (top-level declaration) (unnecessary_nullable_for_final_variable_declarations)',
  'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:112:5: Prefer const over final for declarations (top-level declaration) (prefer_const_declarations)',
  'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:112:21: A value of type \'Null\' can\'t be assigned to a variable of type \'int\' (top-level declaration) (invalid_assignment)',
  'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:134:14: The argument type \'dynamic\' can\'t be assigned to the parameter type \'Key?\' (top-level declaration) (argument_type_not_assignable)',
  'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:134:14: Undefined name \'globalKey\' (top-level declaration) (undefined_identifier)',
  'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:136:21: The final variable \'title\' can\'t be read because it\'s potentially unassigned at this point (top-level declaration) (read_potentially_unassigned_final)',
  'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:147:12: Unused import: \'dart:io\' (self-contained program) (unused_import)',
  'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:148:11: Undefined class \'Widget\' (self-contained program) (undefined_class)',
  'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:148:22: Avoid method calls or property accesses on a "dynamic" target (self-contained program) (avoid_dynamic_calls)',
  'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:148:22: The function \'Placeholder\' isn\'t defined (self-contained program) (undefined_function)',
  'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:153:10: Annotate overridden members (stateful widget) (annotate_overrides)',
  'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:153:10: This method overrides a method annotated as \'@mustCallSuper\' in \'State\', but doesn\'t invoke the overridden method (stateful widget) (must_call_super)',
  'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:161:7: Undefined name \'widget\' (top-level declaration) (undefined_identifier)',
  'dev/bots/test/analyze-snippet-code-test-input/known_broken_documentation.dart:165: Found "```" in code but it did not match RegExp: pattern=^ */// *```dart\$ flags= so something is wrong. Line was: "/// ```"',
  'dev/bots/test/analyze-snippet-code-test-input/short_but_still_broken.dart:9:12: A value of type \'String\' can\'t be assigned to a variable of type \'int\' (statement) (invalid_assignment)',
  'dev/bots/test/analyze-snippet-code-test-input/short_but_still_broken.dart:17:4: Empty ```dart block in snippet code.',
];

const List<String> expectedUiErrors = <String>[
  'dev/bots/test/analyze-snippet-code-test-dart-ui/ui.dart:15:7: Prefer typing uninitialized variables and fields (top-level declaration) (prefer_typing_uninitialized_variables)',
  'dev/bots/test/analyze-snippet-code-test-dart-ui/ui.dart:15:7: Variables must be declared using the keywords \'const\', \'final\', \'var\' or a type name (top-level declaration) (missing_const_final_var_or_type)',
  'dev/bots/test/analyze-snippet-code-test-dart-ui/ui.dart:17:20: Private field could be final (top-level declaration) (prefer_final_fields)',
  'dev/bots/test/analyze-snippet-code-test-dart-ui/ui.dart:17:20: The value of the field \'_buffer\' isn\'t used (top-level declaration) (unused_field)',
];

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
      <String>[
        '--enable-asserts',
        'analyze_snippet_code.dart',
        '--no-include-dart-ui',
        'test/analyze-snippet-code-test-input',
      ],
    );
    expect(process.stdout, isEmpty);
    final List<String> stderrLines = process.stderr.toString().split('\n');
    expect(stderrLines.length, stderrLines.toSet().length, reason: 'found duplicates in $stderrLines');
    expect(stderrLines, <String>[
      ...expectedMainErrors,
      'Found 19 snippet code errors.',
      'See the documentation at the top of dev/bots/analyze_snippet_code.dart for details.',
      '', // because we end with a newline, split gives us an extra blank line
    ]);
    expect(process.exitCode, 1);
  });

  test('Analyzes dart:ui code', () {
    final ProcessResult process = Process.runSync(
      '../../bin/cache/dart-sdk/bin/dart',
      <String>[
        '--enable-asserts',
        'analyze_snippet_code.dart',
        '--dart-ui-location=test/analyze-snippet-code-test-dart-ui',
        'test/analyze-snippet-code-test-input',
      ],
    );
    expect(process.stdout, isEmpty);
    final List<String> stderrLines = process.stderr.toString().split('\n');
    expect(stderrLines.length, stderrLines.toSet().length, reason: 'found duplicates in $stderrLines');
    expect(stderrLines, <String>[
      ...expectedUiErrors,
      ...expectedMainErrors,
      'Found 23 snippet code errors.',
      'See the documentation at the top of dev/bots/analyze_snippet_code.dart for details.',
      '', // because we end with a newline, split gives us an extra blank line
    ]);
    expect(process.exitCode, 1);
  });
}

// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'common.dart';

void main() {
  test('analyze-sample-code', () async {
    final Process process = await Process.start(
      '../../bin/cache/dart-sdk/bin/dart',
      <String>['analyze-sample-code.dart', 'test/analyze-sample-code-test-input'],
    );
    final List<String> stdout = await process.stdout.transform(utf8.decoder).transform(const LineSplitter()).toList();
    final List<String> stderr = await process.stderr.transform(utf8.decoder).transform(const LineSplitter()).toList();
    final Match line = new RegExp(r'^(.+)/main\.dart:[0-9]+:[0-9]+: .+$').matchAsPrefix(stdout[1]);
    expect(line, isNot(isNull));
    final String directory = line.group(1);
    new Directory(directory).deleteSync(recursive: true);
    expect(await process.exitCode, 1);
    expect(stderr, isEmpty);
    expect(stdout, <String>[
      'Found 2 sample code sections.',
      "$directory/main.dart:1:8: Unused import: 'dart:async'",
      "$directory/main.dart:2:8: Unused import: 'dart:convert'",
      "$directory/main.dart:3:8: Unused import: 'dart:math'",
      "$directory/main.dart:4:8: Unused import: 'dart:typed_data'",
      "$directory/main.dart:5:8: Unused import: 'dart:ui'",
      "$directory/main.dart:6:8: Unused import: 'package:flutter_test/flutter_test.dart'",
      "$directory/main.dart:9:8: Target of URI doesn't exist: 'package:flutter/known_broken_documentation.dart'",
      "test/analyze-sample-code-test-input/known_broken_documentation.dart:27:9: Undefined class 'Opacity' (undefined_class)",
      "test/analyze-sample-code-test-input/known_broken_documentation.dart:29:20: Undefined class 'Text' (undefined_class)",
      "test/analyze-sample-code-test-input/known_broken_documentation.dart:39:9: Undefined class 'Opacity' (undefined_class)",
      "test/analyze-sample-code-test-input/known_broken_documentation.dart:41:20: Undefined class 'Text' (undefined_class)",
      'test/analyze-sample-code-test-input/known_broken_documentation.dart:42:5: unexpected comma at end of sample code',
      'Kept $directory because it had errors (see above).',
      '-------8<-------',
      '     1: // generated code',
      "     2: import 'dart:async';",
      "     3: import 'dart:convert';",
      "     4: import 'dart:math' as math;",
      "     5: import 'dart:typed_data';",
      "     6: import 'dart:ui' as ui;",
      "     7: import 'package:flutter_test/flutter_test.dart';",
      '     8: ',
      '     9: // test/analyze-sample-code-test-input/known_broken_documentation.dart',
      "    10: import 'package:flutter/known_broken_documentation.dart';",
      '    11: ',
      '    12: bool _visible = true;',
      '    13: dynamic expression1 = ',
      '    14: new Opacity(',
      '    15:   opacity: _visible ? 1.0 : 0.0,',
      "    16:   child: const Text('Poor wandering ones!'),",
      '    17: )',
      '    18: ;',
      '    19: dynamic expression2 = ',
      '    20: new Opacity(',
      '    21:   opacity: _visible ? 1.0 : 0.0,',
      "    22:   child: const Text('Poor wandering ones!'),",
      '    23: ),',
      '    24: ;',
      '-------8<-------',
    ]);
  }, skip: !Platform.isLinux);
}

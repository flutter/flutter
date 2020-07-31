// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:process/process.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../src/common.dart';

void main() {
  test('--analyze-size flag produces expected output on hello_world', () async {
    final String flutterBin = globals.fs.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await const LocalProcessManager().run(<String>[
      flutterBin,
      'build',
      'apk',
      '--analyze-size',
    ], workingDirectory: globals.fs.path.join(getFlutterRoot(), 'examples', 'hello_world'));

    print(result.stdout);
    print(result.stderr);
    expect(result.stdout.toString(), contains('app-release.apk (total compressed)'));
    expect(globals.fs.file(globals.fs.path.join(
      getFlutterRoot(), 'examples', 'hello_world', 'apk-analysis.json')).existsSync(), true);
    expect(result.exitCode, 0);
  });
}

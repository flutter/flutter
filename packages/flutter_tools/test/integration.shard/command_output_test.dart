// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:process/process.dart';

import '../src/common.dart';

void main() {
  test('All development tools and deprecated commands are hidden and help text is not verbose', () async {
    final String flutterBin = globals.fs.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await const LocalProcessManager().run(<String>[
      flutterBin,
      '-h',
      '-v',
    ]);

    // Development tools.
    expect(result.stdout, isNot(contains('ide-config')));
    expect(result.stdout, isNot(contains('update-packages')));
    expect(result.stdout, isNot(contains('inject-plugins')));

    // Deprecated.
    expect(result.stdout, isNot(contains('make-host-app-editable')));

    // Only printed by verbose tool.
    expect(result.stdout, isNot(contains('exiting with code 0')));
  });

  test('flutter doctor is not verbose', () async {
    final String flutterBin = globals.fs.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await const LocalProcessManager().run(<String>[
      flutterBin,
      'doctor',
      '-v',
    ]);

    // Only printed by verbose tool.
    expect(result.stdout, isNot(contains('exiting with code 0')));
  });

  test('flutter run --machine uses NotifyingLogger', () async {
    final String flutterBin = globals.fs.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await const LocalProcessManager().run(<String>[
      flutterBin,
      'run',
      '--machine',
    ]);

    expect(result.stdout, isEmpty);
  });

  test('flutter attach --machine uses NotifyingLogger', () async {
    final String flutterBin = globals.fs.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await const LocalProcessManager().run(<String>[
      flutterBin,
      'attach',
      '--machine',
    ]);

    expect(result.stdout, isEmpty);
  });

  test('flutter build aot is deprecated', () async {
    final String flutterBin = globals.fs.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await const LocalProcessManager().run(<String>[
      flutterBin,
      'build',
      '-h',
      '-v',
    ]);

    // Deprecated.
    expect(result.stdout, isNot(contains('aot')));

    // Only printed by verbose tool.
    expect(result.stdout, isNot(contains('exiting with code 0')));
  });
}

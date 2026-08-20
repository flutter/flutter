// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  testUsingContext(
    'flutter command can receive `!`, avoiding expansion by cmd.exe',
    () async {
      final String flutterBin = globals.fs.path.join(getFlutterRoot(), 'bin', 'flutter.bat');

      final ProcessResult exec = await Process.run(flutterBin, <String>[
        '!',
      ], workingDirectory: Cache.flutterRoot);
      // If ENABLEDELAYEDEXPANSION is enabled, the argument `!` is removed,
      // and flutter runs without any arguments.
      expect(exec.exitCode, 64);
      expect(exec.stderr, contains('Could not find a command named "!"'));
    },
    skip: !Platform.isWindows, // [intended] relies on Windows's cmd.exe
  );

  testUsingContext(
    r'flutter command can receive regex lookahead `^(?!Golden).+`, avoiding expansion by cmd.exe',
    () async {
      final String flutterBin = globals.fs.path.join(getFlutterRoot(), 'bin', 'flutter.bat');

      final ProcessResult exec = await Process.run(flutterBin, <String>[
        'test',
        '--name',
        r'^(?!Golden).+',
        '--help',
      ], workingDirectory: Cache.flutterRoot);
      expect(exec.exitCode, 0);
    },
    skip: !Platform.isWindows, // [intended] relies on Windows's cmd.exe
  );

  testUsingContext('windows entrypoint batch scripts do not enable delayed expansion', () {
    final String flutterRoot = getFlutterRoot();
    final File flutterBat = globals.fs.file(
      globals.fs.path.join(flutterRoot, 'bin', 'flutter.bat'),
    );
    final File dartBat = globals.fs.file(globals.fs.path.join(flutterRoot, 'bin', 'dart.bat'));
    final File sharedBat = globals.fs.file(
      globals.fs.path.join(flutterRoot, 'bin', 'internal', 'shared.bat'),
    );

    expect(flutterBat.existsSync(), isTrue);
    expect(dartBat.existsSync(), isTrue);
    expect(sharedBat.existsSync(), isTrue);

    expect(flutterBat.readAsStringSync(), isNot(contains('ENABLEDELAYEDEXPANSION')));
    expect(dartBat.readAsStringSync(), isNot(contains('ENABLEDELAYEDEXPANSION')));
    expect(sharedBat.readAsStringSync(), isNot(contains('ENABLEDELAYEDEXPANSION')));
  });
}

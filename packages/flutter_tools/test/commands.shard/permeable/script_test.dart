// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform, Process, ProcessResult;

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/cache.dart';

import '../../src/common.dart';

void main() {
  final fs = LocalFileSystem.test(signals: Signals.test());

  setUpAll(() {
    Cache.disableLocking();
  });

  tearDownAll(() async {
    await fs.dispose();
  });

  testWithoutContext(
    'flutter command can receive `!`, avoiding expansion by cmd.exe',
    () async {
      final String flutterBin = fs.path.join(getFlutterRoot(), 'bin', 'flutter.bat');

      final ProcessResult exec = await Process.run(flutterBin, <String>[
        '!',
      ], workingDirectory: getFlutterRoot());
      // If ENABLEDELAYEDEXPANSION is enabled, the argument `!` is removed,
      // and flutter runs without any arguments.
      expect(exec.exitCode, 64);
      expect(exec.stderr, contains('Could not find a command named "!"'));
    },
    skip: !Platform.isWindows, // [intended] relies on Windows's cmd.exe
  );

  testWithoutContext('windows entrypoint batch scripts do not enable delayed expansion', () {
    final String flutterRoot = getFlutterRoot();
    final File flutterBat = fs.file(fs.path.join(flutterRoot, 'bin', 'flutter.bat'));
    final File dartBat = fs.file(fs.path.join(flutterRoot, 'bin', 'dart.bat'));
    final File sharedBat = fs.file(fs.path.join(flutterRoot, 'bin', 'internal', 'shared.bat'));

    expect(flutterBat.existsSync(), isTrue);
    expect(dartBat.existsSync(), isTrue);
    expect(sharedBat.existsSync(), isTrue);

    final delayedExpansionPattern = RegExp(r'ENABLEDELAYEDEXPANSION', caseSensitive: false);
    expect(flutterBat.readAsStringSync(), isNot(contains(delayedExpansionPattern)));
    expect(dartBat.readAsStringSync(), isNot(contains(delayedExpansionPattern)));
    expect(sharedBat.readAsStringSync(), isNot(contains(delayedExpansionPattern)));
  });
}

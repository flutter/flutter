// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../src/common.dart';

/// Attempt to wait N tries with a one second delay between tries for a PID to
/// disappear.
///
/// This is racy and should generally be avoided wherever possible. It is used
/// for invocations of the `flutter` script that launch a Dart VM as a child
/// process. The Dart VM may take slightly longer after the exit code is
/// returned from the shell script. This is a problem on Windows in particular,
/// where the Dart process will hold exclusive locks on file system objects we
/// want to clean up at the end of a test.
// TODO(dnfield): This is racy. If dart-lang/sdk#40759 can be resolved, we
// should remove this.
Future<void> tryWaitForPidDeath(int pid, { int tries = 10 }) {
  if (globals.platform.isWindows) {
    return _tryWaitForWindowsPidDeath(pid, tries);
  }
  return _tryWaitForPosixPidDeath(pid, tries);
}

Future<void> _tryWaitForPosixPidDeath(int pid, int tries) async {
  for (int i = 0; i < tries; i+= 1) {
    final ProcessResult result = await globals.processManager.run(<String>[
      'kill',
      '-0',
      pid.toString(),
    ]);
    if (result.exitCode != 0) {
      return;
    }
  }
}

Future<void> _tryWaitForWindowsPidDeath(int pid, int tries) async {
  for (int i = 0; i < tries; i += 1) {
    final ProcessResult result = await globals.processManager.run(<String>[
      'tasklist',
      '/fi',
      'PID eq $pid',
    ]);
    if ((result.stdout as String).contains('INFO: No tasks are running which match the specified criteria.')) {
      return;
    }
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}


/// Creates a temporary directory but resolves any symlinks to return the real
/// underlying path to avoid issues with breakpoints/hot reload.
/// https://github.com/flutter/flutter/pull/21741
Directory createResolvedTempDirectorySync(String prefix) {
  assert(prefix.endsWith('.'));
  final Directory tempDirectory = globals.fs.systemTempDirectory.createTempSync('flutter_$prefix');
  return globals.fs.directory(tempDirectory.resolveSymbolicLinksSync());
}

void writeFile(String path, String content) {
  globals.fs.file(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(content)
    ..setLastModifiedSync(DateTime.now().add(const Duration(seconds: 10)));
}

void writePackages(String folder) {
  writeFile(globals.fs.path.join(folder, '.packages'), '''
test:${globals.fs.path.join(globals.fs.currentDirectory.path, 'lib')}/
''');
}

void writePubspec(String folder) {
  writeFile(globals.fs.path.join(folder, 'pubspec.yaml'), '''
name: test
dependencies:
  flutter:
    sdk: flutter
''');
}

Future<void> getPackages(String folder) async {
  final List<String> command = <String>[
    globals.fs.path.join(getFlutterRoot(), 'bin', 'flutter'),
    'pub',
    'get',
  ];
  final ProcessResult result = await globals.processManager.run(command, workingDirectory: folder);
  if (result.exitCode != 0) {
    throw Exception('flutter pub get failed: ${result.stderr}\n${result.stdout}');
  }
}

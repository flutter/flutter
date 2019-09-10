// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:path/path.dart' as pathlib;

import 'environment.dart';
import 'test_runner.dart';

// A "shard" is a named subset of tasks this script runs. If not specified,
// it runs all shards. That's what we do on CI.
const Map<String, Function> _kShardNameToCode = <String, Function>{
  'licenses': _checkLicenseHeaders,
  'tests': runTests,
};

void main(List<String> args) async {
  Environment.commandLineArguments = args;
  if (io.Directory.current.absolute.path != environment.webUiRootDir.absolute.path) {
    io.stderr.writeln('Current directory is not the root of the web_ui package directory.');
    io.stderr.writeln('web_ui directory is: ${environment.webUiRootDir.absolute.path}');
    io.stderr.writeln('current directory is: ${io.Directory.current.absolute.path}');
    io.exit(1);
  }

  _copyAhemFontIntoWebUi();

  final List<String> shardsToRun = environment.requestedShards.isNotEmpty
    ? environment.requestedShards
    : _kShardNameToCode.keys.toList();

  for (String shard in shardsToRun) {
    print('Running shard $shard');
    if (!_kShardNameToCode.containsKey(shard)) {
      io.stderr.writeln('''
ERROR:
  Unsupported test shard: $shard.
  Supported test shards: ${_kShardNameToCode.keys.join(', ')}
TESTS FAILED
'''.trim());
      io.exit(1);
    }
    await _kShardNameToCode[shard]();
  }
  // Sometimes the Dart VM refuses to quit.
  io.exit(io.exitCode);
}

void _checkLicenseHeaders() {
  final List<io.File> allSourceFiles = _flatListSourceFiles(environment.webUiRootDir);
  _expect(allSourceFiles.isNotEmpty, 'Dart source listing of ${environment.webUiRootDir.path} must not be empty.');

  final List<String> allDartPaths = allSourceFiles.map((f) => f.path).toList();

  for (String expectedDirectory in const <String>['lib', 'test', 'dev', 'tool']) {
    final String expectedAbsoluteDirectory = pathlib.join(environment.webUiRootDir.path, expectedDirectory);
    _expect(
      allDartPaths.where((p) => p.startsWith(expectedAbsoluteDirectory)).isNotEmpty,
      'Must include the $expectedDirectory/ directory',
    );
  }

  allSourceFiles.forEach(_expectLicenseHeader);
  print('License headers OK!');
}

final _copyRegex = RegExp(r'// Copyright 2013 The Flutter Authors\. All rights reserved\.');

void _expectLicenseHeader(io.File file) {
  List<String> head = file.readAsStringSync().split('\n').take(3).toList();

  _expect(head.length >= 3, 'File too short: ${file.path}');
  _expect(
    _copyRegex.firstMatch(head[0]) != null,
    'Invalid first line of license header in file ${file.path}',
  );
  _expect(
    head[1] == '// Use of this source code is governed by a BSD-style license that can be',
    'Invalid second line of license header in file ${file.path}',
  );
  _expect(
    head[2] == '// found in the LICENSE file.',
    'Invalid second line of license header in file ${file.path}',
  );
}

void _expect(bool value, String requirement) {
  if (!value) {
    throw Exception('Test failed: ${requirement}');
  }
}

List<io.File> _flatListSourceFiles(io.Directory directory) {
  return directory
      .listSync(recursive: true)
      .whereType<io.File>()
      .where((f) {
        if (!f.path.endsWith('.dart') && !f.path.endsWith('.js')) {
          // Not a source file we're checking.
          return false;
        }
        if (pathlib.isWithin(environment.webUiBuildDir.path, f.path) ||
            pathlib.isWithin(environment.webUiDartToolDir.path, f.path)) {
          // Generated files.
          return false;
        }
        return true;
      })
      .toList();
}

void _copyAhemFontIntoWebUi() {
  final io.File sourceAhemTtf = io.File(pathlib.join(
    environment.flutterDirectory.path, 'third_party', 'txt', 'third_party', 'fonts', 'ahem.ttf'
  ));
  final String destinationAhemTtfPath = pathlib.join(
    environment.webUiRootDir.path, 'lib', 'assets', 'ahem.ttf'
  );
  sourceAhemTtf.copySync(destinationAhemTtfPath);
}

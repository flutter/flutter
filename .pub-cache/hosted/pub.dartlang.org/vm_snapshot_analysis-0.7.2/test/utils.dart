// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

final dartCompile = () {
  final sdkBin = path.dirname(Platform.executable);
  final dartCmd = path.join(sdkBin, Platform.isWindows ? 'dart.exe' : 'dart');

  if (!File(dartCmd).existsSync()) {
    throw 'Failed to locate `dart` in the SDK';
  }

  return path.canonicalize(dartCmd);
}();

class AotSnapshot {
  final String outputBinary;
  final String sizesJson;

  AotSnapshot({required this.outputBinary, required this.sizesJson});
}

Future withFlag(
    Map<String, String> source, String flag, Future Function(String) f) {
  return withFlagImpl(source, flag, (info) => f(info.sizesJson));
}

Future withFlagImpl(
    Map<String, String> source, String? flag, Future Function(AotSnapshot) f) {
  return withTempDir((dir) async {
    final snapshot = AotSnapshot(
      outputBinary: path.join(dir, 'output.exe'),
      sizesJson: path.join(dir, 'sizes.json'),
    );
    final packages = path.join(dir, '.packages');
    final mainDart = path.join(dir, 'main.dart');

    // Create test input.
    for (var file in source.entries) {
      await File(path.join(dir, file.key)).writeAsString(file.value);
    }
    await File(packages).writeAsString('''
input:./
''');
    await File(mainDart).writeAsString('''
import 'package:input/input.dart' as input;

void main(List<String> args) => input.main(args);
''');

    final extraGenSnapshotOptions = [
      '--dwarf-stack-traces',
      if (flag != null) '$flag=${snapshot.sizesJson}',
    ];

    final args = [
      'compile',
      'exe',
      '-o',
      snapshot.outputBinary,
      '--packages=$packages',
      '--extra-gen-snapshot-options=${extraGenSnapshotOptions.join(',')}',
      mainDart,
    ];

    // Compile input.dart to native and output instruction sizes.
    final result = await Process.run(dartCompile, args);

    expect(result.exitCode, equals(0), reason: '''
Compilation completed with exit code ${result.exitCode}.

Command line: $dartCompile ${args.join(' ')}

stdout: ${result.stdout}
stderr: ${result.stderr}
''');
    expect(File(snapshot.outputBinary).existsSync(), isTrue,
        reason: 'Output binary exists');
    if (flag != null) {
      expect(File(snapshot.sizesJson).existsSync(), isTrue,
          reason: 'Instruction sizes output exists');
    }

    await f(snapshot);
  });
}

final shouldKeepTemporaryDirectories =
    Platform.environment['KEEP_TEMPORARY_DIRECTORIES']?.isNotEmpty == true;

Future withTempDir(Future Function(String dir) f) async {
  final tempDir =
      Directory.systemTemp.createTempSync('instruction-sizes-test-');
  try {
    await f(tempDir.path);
  } finally {
    if (shouldKeepTemporaryDirectories) {
      tempDir.deleteSync(recursive: true);
    }
  }
}

Future<Object> loadJson(File input) async {
  return (await input
      .openRead()
      .transform(utf8.decoder)
      .transform(json.decoder)
      .first)!;
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:path/path.dart' as path;

String get cacheDirectory {
  final String flutterRepoRoot = path.normalize(path.join(path.dirname(Platform.script.path), '..', '..'));
  return path.normalize(path.join(flutterRepoRoot, 'bin', 'cache'));
}

bool isBinary(String filePath) {
  final ProcessResult result = Process.runSync(
    'file',
    <String>[
      '--mime-type',
      '-b', // is binary
      filePath,
    ],
  );
  return (result.stdout as String).contains('application/x-mach-binary');
}

List<String> findBinaryPaths() {
  final ProcessResult result = Process.runSync(
    'find',
    <String>[
      cacheDirectory,
      '-type',
      'f',
      '-perm',
      '+111', // is executable
    ],
  );
  final List<String> allFiles = (result.stdout as String).split('\n').where((String s) => s.isNotEmpty).toList();
  return allFiles.where(isBinary).toList();
}

void main() {
  final List<String> failures = <String>[];

  for (final String binaryPath in findBinaryPaths()) {
    print('Verifying the code signature of $binaryPath');
    final ProcessResult result = Process.runSync(
      'codesign',
      <String>[
        '-vvv',
        binaryPath,
      ],
    );
    if (result.exitCode != 0) {
      failures.add(binaryPath);
      print('File "$binaryPath" does not appear to be codesigned.\n'
            'The `codesign` command failed with exit code ${result.exitCode}:\n'
            '${result.stderr}\n');
    }
  }

  if (failures.isNotEmpty) {
    print('Found ${failures.length} unsigned binaries.');
    failures.forEach(print);
    exit(1);
  }

  print('Verified that binaries are codesigned.');
}

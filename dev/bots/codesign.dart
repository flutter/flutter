// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:path/path.dart' as path;

String get repoRoot => path.normalize(path.join(path.dirname(Platform.script.toFilePath()), '..', '..'));
String get cacheDirectory => path.normalize(path.join(repoRoot, 'bin', 'cache'));

/// Check mime-type of file at [filePath] to determine if it is binary
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

/// Find every binary file in the given [rootDirectory]
List<String> findBinaryPaths([String rootDirectory]) {
  rootDirectory ??= cacheDirectory;
  final ProcessResult result = Process.runSync(
    'find',
    <String>[
      rootDirectory,
      '-type',
      'f',
      '-perm',
      '+111', // is executable
    ],
  );
  final List<String> allFiles = (result.stdout as String).split('\n').where((String s) => s.isNotEmpty).toList();
  return allFiles.where(isBinary).toList();
}

/// Given the path to a stamp file, read the contents.
///
/// Will throw if the file doesn't exist.
String readStamp(String filePath) {
  final File file = File(filePath);
  if (!file.existsSync()) {
    throw 'Error! Stamp file $filePath does not exist!';
  }
  return file.readAsStringSync().trim();
}

/// Return whether or not the flutter cache is up to date.
bool checkCacheIsCurrent() {
  try {
    final String dartSdkStamp = readStamp(path.join(cacheDirectory, 'engine-dart-sdk.stamp'));
    final String engineVersion = readStamp(path.join(repoRoot, 'bin', 'internal', 'engine.version'));
    return dartSdkStamp == engineVersion;
  } catch (e) {
    print(e);
    return false;
  }
}

void main() {
  final List<String> failures = <String>[];

  if (!Platform.isMacOS) {
    print('Error! Expected operating system "macos", actual operating system '
      'is: "${Platform.operatingSystem}"');
    exit(1);
  }

  if (!checkCacheIsCurrent()) {
    print(
      'Warning! Your cache is either not present or not matching your flutter\n'
      'version. Run a `flutter` command to update your cache, and re-try this\n'
      'test.');
    exit(1);
  }

  for (final String binaryPath in findBinaryPaths(cacheDirectory)) {
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

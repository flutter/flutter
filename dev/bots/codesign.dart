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

List<String> get binariesWithEntitlements => List<String>.unmodifiable(<String>[
  'ideviceinfo',
  'idevicename',
  'idevicescreenshot',
  'idevicesyslog',
  'libimobiledevice.6.dylib',
  'libplist.3.dylib',
  'iproxy',
  'libusbmuxd.4.dylib',
  'libssl.1.0.0.dylib',
  'libcrypto.1.0.0.dylib',
  'libzip.5.0.dylib',
  'libzip.5.dylib',
  'gen_snapshot',
  'dart',
  'flutter_tester',
  'gen_snapshot_arm64',
  'gen_snapshot_armv7',
]);

List<String> get expectedEntitlements => List<String>.unmodifiable(<String>[
  'com.apple.security.cs.allow-jit',
  'com.apple.security.cs.allow-unsigned-executable-memory',
  'com.apple.security.cs.allow-dyld-environment-variables',
  'com.apple.security.network.client',
  'com.apple.security.network.server',
  'com.apple.security.cs.disable-library-validation',
]);


/// Check if the binary has the expected entitlements.
bool hasExpectedEntitlements(String binaryPath) {
  try {
    final ProcessResult entitlementResult = Process.runSync(
      'codesign',
      <String>[
        '--display',
        '--entitlements',
        ':-',
        binaryPath,
      ],
    );

    if (entitlementResult.exitCode != 0) {
      print('The `codesign --entitlements` command failed with exit code ${entitlementResult.exitCode}:\n'
        '${entitlementResult.stderr}\n');
      return false;
    }

    bool passes = true;
    final String output = entitlementResult.stdout as String;
    for (final String entitlement in expectedEntitlements) {
      final bool entitlementExpected = binariesWithEntitlements.contains(path.basename(binaryPath));
      if (output.contains(entitlement) != entitlementExpected) {
        print('File "$binaryPath" ${entitlementExpected ? 'does not have expected' : 'has unexpected'} entitlement $entitlement.');
        passes = false;
      }
    }
    return passes;
  } catch (e) {
    print(e);
    return false;
  }
}

void main() {
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

  final List<String> unsignedBinaries = <String>[];
  final List<String> wrongEntitlementBinaries = <String>[];
  for (final String binaryPath in findBinaryPaths(cacheDirectory)) {
    print('Verifying the code signature of $binaryPath');
    final ProcessResult codeSignResult = Process.runSync(
      'codesign',
      <String>[
        '-vvv',
        binaryPath,
      ],
    );
    if (codeSignResult.exitCode != 0) {
      unsignedBinaries.add(binaryPath);
      print('File "$binaryPath" does not appear to be codesigned.\n'
            'The `codesign` command failed with exit code ${codeSignResult.exitCode}:\n'
            '${codeSignResult.stderr}\n');
      continue;
    } else {
      print('Verifying entitlements of $binaryPath');
      if (!hasExpectedEntitlements(binaryPath)) {
        wrongEntitlementBinaries.add(binaryPath);
      }
    }
  }

  if (unsignedBinaries.isNotEmpty) {
    print('Found ${unsignedBinaries.length} unsigned binaries:');
    unsignedBinaries.forEach(print);
  }

  if (wrongEntitlementBinaries.isNotEmpty) {
    print('Found ${wrongEntitlementBinaries.length} binaries with unexpected entitlements:');
    wrongEntitlementBinaries.forEach(print);
  }

  if (unsignedBinaries.isNotEmpty) {
    // TODO(jmagman): Also exit if `wrongEntitlementBinaries.isNotEmpty` after https://github.com/flutter/flutter/issues/46704 is done.
    exit(1);
  }

  print('Verified that binaries are codesigned and have expected entitlements.');
}

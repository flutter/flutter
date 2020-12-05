// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import './repository.dart';
import './stdio.dart';

const List<String> binariesWithEntitlements = <String>[
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
  'dartaotruntime',
  'flutter_tester',
  'gen_snapshot_arm64',
  'gen_snapshot_armv7',
];

const List<String> expectedEntitlements = <String>[
  'com.apple.security.cs.allow-jit',
  'com.apple.security.cs.allow-unsigned-executable-memory',
  'com.apple.security.cs.allow-dyld-environment-variables',
  'com.apple.security.network.client',
  'com.apple.security.network.server',
  'com.apple.security.cs.disable-library-validation',
];

const String kVerify = 'verify';
const String kSignatures = 'signatures';
const String kRevision = 'revision';

class CodesignCommand extends Command<void> {
  CodesignCommand({
    @required this.checkouts,
  })  : fileSystem = checkouts.fileSystem,
        platform = checkouts.platform,
        stdio = checkouts.stdio,
        processManager = checkouts.processManager {
    argParser.addFlag(
      kVerify,
      help:
          'Only verify expected binaries exist and are codesigned with entitlements.',
    );
    argParser.addFlag(
      kSignatures,
      defaultsTo: true,
      help:
          'When off, this command will only verify the existence of binaries, and not their\n'
          'signatures or entitlements. Must be used with --verify flag.',
    );
    argParser.addOption(
      kRevision,
      help: 'The Flutter FRAMEWORK revision to use.',
    );
  }

  final Checkouts checkouts;
  final FileSystem fileSystem;
  final Platform platform;
  final ProcessManager processManager;
  final Stdio stdio;

  FrameworkRepository _framework;
  FrameworkRepository get framework =>
      _framework ??= FrameworkRepository(checkouts, useExistingCheckout: true);

  @visibleForTesting
  set framework(FrameworkRepository framework) => _framework = framework;

  @override
  String get name => 'codesign';

  @override
  String get description =>
      'For codesigning and verifying the signatures of engine binaries.';

  @override
  void run() {
    if (!platform.isMacOS) {
      throw Exception(
          'Error! Expected operating system "macos", actual operating system is: '
          '"${platform.operatingSystem}"');
    }

    if (argResults['verify'] as bool != true) {
      throw Exception(
          'Sorry, but codesigning is not implemented yet. Please pass the '
          '--$kVerify flag to verify signatures.');
    }

    String revision;
    if (argResults.wasParsed(kRevision)) {
      revision = argResults[kRevision] as String;
    } else {
      revision = (processManager.runSync(
        <String>['git', 'rev-parse', 'HEAD'],
        workingDirectory: framework.checkoutDirectory.path,
      ).stdout as String).trim();
    }
    verify(revision, argResults[kSignatures] as bool);
  }

  @visibleForTesting
  void verify(String revision, bool signatures) {
    final List<String> unsignedBinaries = <String>[];
    final List<String> wrongEntitlementBinaries = <String>[];

    framework.checkout(revision);

    // Ensure artifacts present
    framework.runFlutter(<String>['precache', '--ios', '--macos']);

    for (final String binaryPath in findBinaryPaths(framework.cacheDirectory)) {
      stdio.printTrace('Verifying the code signature of $binaryPath');
      final io.ProcessResult codeSignResult = processManager.runSync(
        <String>[
          'codesign',
          '-vvv',
          binaryPath,
        ],
      );
      if (codeSignResult.exitCode != 0) {
        unsignedBinaries.add(binaryPath);
        stdio.printError(
            'File "$binaryPath" does not appear to be codesigned.\n'
            'The `codesign` command failed with exit code ${codeSignResult.exitCode}:\n'
            '${codeSignResult.stderr}\n');
        continue;
      } else {
        stdio.printTrace('Verifying entitlements of $binaryPath');
        if (!hasExpectedEntitlements(binaryPath)) {
          wrongEntitlementBinaries.add(binaryPath);
        }
      }
    }

    if (unsignedBinaries.isNotEmpty) {
      stdio.printError('Found ${unsignedBinaries.length} unsigned binaries:');
      unsignedBinaries.forEach(print);
    }

    if (wrongEntitlementBinaries.isNotEmpty) {
      stdio.printError(
          'Found ${wrongEntitlementBinaries.length} binaries with unexpected entitlements:');
      wrongEntitlementBinaries.forEach(print);
    }

    if (unsignedBinaries.isNotEmpty || wrongEntitlementBinaries.isNotEmpty) {
      throw Exception('Test failed because unsigned binaries detected.');
    }

    stdio.printStatus(
        'Verified that binaries for commit $revision are codesigned and have '
        'expected entitlements.');
  }

  /// Find every binary file in the given [rootDirectory]
  List<String> findBinaryPaths(String rootDirectory) {
    final io.ProcessResult result = processManager.runSync(
      <String>[
        'find',
        rootDirectory,
        '-type',
        'f',
        '-perm',
        '+111', // is executable
      ],
    );
    final List<String> allFiles = (result.stdout as String)
        .split('\n')
        .where((String s) => s.isNotEmpty)
        .toList();
    return allFiles.where(isBinary).toList();
  }

  /// Check mime-type of file at [filePath] to determine if it is binary
  bool isBinary(String filePath) {
    final io.ProcessResult result = processManager.runSync(
      <String>[
        'file',
        '--mime-type',
        '-b', // is binary
        filePath,
      ],
    );
    return (result.stdout as String).contains('application/x-mach-binary');
  }

  /// Check if the binary has the expected entitlements.
  bool hasExpectedEntitlements(String binaryPath) {
    try {
      final io.ProcessResult entitlementResult = processManager.runSync(
        <String>[
          'codesign',
          '--display',
          '--entitlements',
          ':-',
          binaryPath,
        ],
      );

      if (entitlementResult.exitCode != 0) {
        stdio.printError(
            'The `codesign --entitlements` command failed with exit code ${entitlementResult.exitCode}:\n'
            '${entitlementResult.stderr}\n');
        return false;
      }

      bool passes = true;
      final String output = entitlementResult.stdout as String;
      for (final String entitlement in expectedEntitlements) {
        final bool entitlementExpected = binariesWithEntitlements
            .contains(fileSystem.path.basename(binaryPath));
        if (output.contains(entitlement) != entitlementExpected) {
          stdio.printError(
              'File "$binaryPath" ${entitlementExpected ? 'does not have expected' : 'has unexpected'} entitlement $entitlement.');
          passes = false;
        }
      }
      return passes;
    } catch (e) {
      stdio.printError((e as Exception).toString());
      return false;
    }
  }
}

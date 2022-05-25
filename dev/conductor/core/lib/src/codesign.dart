// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import './globals.dart';
import './repository.dart';
import './stdio.dart';

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
const String kUpstream = 'upstream';


/// Command to codesign and verify the signatures of cached binaries.
class CodesignCommand extends Command<void> {
  CodesignCommand({
    required this.checkouts,
    required this.flutterRoot,
    FrameworkRepository? framework,
  })  : fileSystem = checkouts.fileSystem,
        platform = checkouts.platform,
        stdio = checkouts.stdio,
        processManager = checkouts.processManager {
    if (framework != null) {
      _framework = framework;
    }
    argParser.addFlag(
      kVerify,
      help: 'Only verify expected binaries exist and are codesigned with entitlements.',
    );
    argParser.addFlag(
      kSignatures,
      defaultsTo: true,
      help: 'When off, this command will only verify the existence of binaries, and not their\n'
            'signatures or entitlements. Must be used with --verify flag.',
    );
    argParser.addOption(
      kUpstream,
      defaultsTo: FrameworkRepository.defaultUpstream,
      help: "The git remote URL to use as the Flutter framework's upstream.",
    );
    argParser.addOption(
      kRevision,
      help: 'The Flutter framework revision to use.',
    );
  }

  final Checkouts checkouts;
  final FileSystem fileSystem;
  final Platform platform;
  final ProcessManager processManager;
  final Stdio stdio;

  /// Root directory of the Flutter repository.
  final Directory flutterRoot;

  FrameworkRepository? _framework;
  FrameworkRepository get framework {
    return _framework ??= FrameworkRepository(
      checkouts,
      upstreamRemote: Remote(
        name: RemoteName.upstream,
        url: argResults![kUpstream] as String,
      ),
    );
  }

  @override
  String get name => 'codesign';

  @override
  String get description =>
      'For codesigning and verifying the signatures of engine binaries.';

  @override
  Future<void> run() async {
    if (!platform.isMacOS) {
      throw ConductorException(
        'Error! Expected operating system "macos", actual operating system is: '
        '"${platform.operatingSystem}"',
      );
    }

    if (argResults!['verify'] as bool != true) {
      throw ConductorException(
        'Sorry, but codesigning is not implemented yet. Please pass the '
        '--$kVerify flag to verify signatures.',
      );
    }

    String revision;
    if (argResults!.wasParsed(kRevision)) {
      stdio.printWarning(
        'Warning! When providing an arbitrary revision, the contents of the cache may not '
        'match the expected binaries in the conductor tool. It is preferred to check out '
        'the desired revision and run that version of the conductor.\n',
      );
      revision = argResults![kRevision] as String;
    } else {
      revision = ((await processManager.run(
        <String>['git', 'rev-parse', 'HEAD'],
        workingDirectory: flutterRoot.path,
      )).stdout as String).trim();
      assert(revision.isNotEmpty);
    }

    await framework.checkout(revision);

    // Ensure artifacts present
    await framework.runFlutter(<String>['precache', '--android', '--ios', '--macos']);

    await verifyExist();
    if (argResults![kSignatures] as bool) {
      await verifySignatures();
    }
  }

  /// Binaries that are expected to be codesigned and have entitlements.
  ///
  /// This list should be kept in sync with the actual contents of Flutter's
  /// cache.
  Future<List<String>> get binariesWithEntitlements async {
    final String frameworkCacheDirectory = await framework.cacheDirectory;
    return <String>[
      'artifacts/engine/android-arm-profile/darwin-x64/gen_snapshot',
      'artifacts/engine/android-arm-release/darwin-x64/gen_snapshot',
      'artifacts/engine/android-arm64-profile/darwin-x64/gen_snapshot',
      'artifacts/engine/android-arm64-release/darwin-x64/gen_snapshot',
      'artifacts/engine/android-x64-profile/darwin-x64/gen_snapshot',
      'artifacts/engine/android-x64-release/darwin-x64/gen_snapshot',
      'artifacts/engine/darwin-x64-profile/gen_snapshot',
      'artifacts/engine/darwin-x64-profile/gen_snapshot_arm64',
      'artifacts/engine/darwin-x64-profile/gen_snapshot_x64',
      'artifacts/engine/darwin-x64-release/gen_snapshot',
      'artifacts/engine/darwin-x64-release/gen_snapshot_arm64',
      'artifacts/engine/darwin-x64-release/gen_snapshot_x64',
      'artifacts/engine/darwin-x64/flutter_tester',
      'artifacts/engine/darwin-x64/gen_snapshot',
      'artifacts/engine/darwin-x64/gen_snapshot_arm64',
      'artifacts/engine/darwin-x64/gen_snapshot_x64',
      'artifacts/engine/ios-profile/gen_snapshot_arm64',
      'artifacts/engine/ios-release/gen_snapshot_arm64',
      'artifacts/engine/ios/gen_snapshot_arm64',
      'artifacts/libimobiledevice/idevicescreenshot',
      'artifacts/libimobiledevice/idevicesyslog',
      'artifacts/libimobiledevice/libimobiledevice-1.0.6.dylib',
      'artifacts/libplist/libplist-2.0.3.dylib',
      'artifacts/openssl/libcrypto.1.1.dylib',
      'artifacts/openssl/libssl.1.1.dylib',
      'artifacts/usbmuxd/iproxy',
      'artifacts/usbmuxd/libusbmuxd-2.0.6.dylib',
      'dart-sdk/bin/dart',
      'dart-sdk/bin/dartaotruntime',
      'dart-sdk/bin/utils/gen_snapshot',
    ]
        .map((String relativePath) =>
            fileSystem.path.join(frameworkCacheDirectory, relativePath))
        .toList();
  }

  /// Binaries that are only expected to be codesigned.
  ///
  /// This list should be kept in sync with the actual contents of Flutter's
  /// cache.
  Future<List<String>> get binariesWithoutEntitlements async {
    final String frameworkCacheDirectory = await framework.cacheDirectory;
    return <String>[
      'artifacts/engine/darwin-x64-profile/FlutterMacOS.framework/Versions/A/FlutterMacOS',
      'artifacts/engine/darwin-x64-release/FlutterMacOS.framework/Versions/A/FlutterMacOS',
      'artifacts/engine/darwin-x64/FlutterMacOS.framework/Versions/A/FlutterMacOS',
      'artifacts/engine/darwin-x64/font-subset',
      'artifacts/engine/darwin-x64/impellerc',
      'artifacts/engine/darwin-x64/libtessellator.dylib',
      'artifacts/engine/ios-profile/Flutter.xcframework/ios-arm64/Flutter.framework/Flutter',
      'artifacts/engine/ios-profile/Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework/Flutter',
      'artifacts/engine/ios-release/Flutter.xcframework/ios-arm64/Flutter.framework/Flutter',
      'artifacts/engine/ios-release/Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework/Flutter',
      'artifacts/engine/ios/Flutter.xcframework/ios-arm64/Flutter.framework/Flutter',
      'artifacts/engine/ios/Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework/Flutter',
      'artifacts/ios-deploy/ios-deploy',
    ]
        .map((String relativePath) =>
            fileSystem.path.join(frameworkCacheDirectory, relativePath))
        .toList();
  }

  /// Verify the existence of all expected binaries in cache.
  ///
  /// This function ignores code signatures and entitlements, and is intended to
  /// be run on every commit. It should throw if either new binaries are added
  /// to the cache or expected binaries removed. In either case, this class'
  /// [binariesWithEntitlements] or [binariesWithoutEntitlements] lists should
  /// be updated accordingly.
  @visibleForTesting
  Future<void> verifyExist() async {
    final Set<String> foundFiles = <String>{};
    for (final String binaryPath
        in await findBinaryPaths(await framework.cacheDirectory)) {
      if ((await binariesWithEntitlements).contains(binaryPath)) {
        foundFiles.add(binaryPath);
      } else if ((await binariesWithoutEntitlements).contains(binaryPath)) {
        foundFiles.add(binaryPath);
      } else {
        throw ConductorException(
            'Found unexpected binary in cache: $binaryPath');
      }
    }

    final List<String> allExpectedFiles =
        (await binariesWithEntitlements) + (await binariesWithoutEntitlements);
    if (foundFiles.length < allExpectedFiles.length) {
      final List<String> unfoundFiles = allExpectedFiles
          .where(
            (String file) => !foundFiles.contains(file),
          )
          .toList();
      stdio.printError(
        'Expected binaries not found in cache:\n\n${unfoundFiles.join('\n')}\n\n'
        'If this commit is removing binaries from the cache, this test should be fixed by\n'
        'removing the relevant entry from either the "binariesWithEntitlements" or\n'
        '"binariesWithoutEntitlements" getters in dev/tools/lib/codesign.dart.',
      );
      throw ConductorException('Did not find all expected binaries!');
    }

    stdio.printStatus('All expected binaries present.');
  }

  /// Verify code signatures and entitlements of all binaries in the cache.
  @visibleForTesting
  Future<void> verifySignatures() async {
    final List<String> unsignedBinaries = <String>[];
    final List<String> wrongEntitlementBinaries = <String>[];
    final List<String> unexpectedBinaries = <String>[];
    for (final String binaryPath
        in await findBinaryPaths(await framework.cacheDirectory)) {
      bool verifySignature = false;
      bool verifyEntitlements = false;
      if ((await binariesWithEntitlements).contains(binaryPath)) {
        verifySignature = true;
        verifyEntitlements = true;
      }
      if ((await binariesWithoutEntitlements).contains(binaryPath)) {
        verifySignature = true;
      }
      if (!verifySignature && !verifyEntitlements) {
        unexpectedBinaries.add(binaryPath);
        stdio.printError('Unexpected binary $binaryPath found in cache!');
        continue;
      }
      stdio.printTrace('Verifying the code signature of $binaryPath');
      final io.ProcessResult codeSignResult = await processManager.run(
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
          '${codeSignResult.stderr}\n',
        );
        continue;
      }
      if (verifyEntitlements) {
        stdio.printTrace('Verifying entitlements of $binaryPath');
        if (!(await hasExpectedEntitlements(binaryPath))) {
          wrongEntitlementBinaries.add(binaryPath);
        }
      }
    }

    // First print all deviations from expectations
    if (unsignedBinaries.isNotEmpty) {
      stdio.printError('Found ${unsignedBinaries.length} unsigned binaries:');
      unsignedBinaries.forEach(stdio.printError);
    }

    if (wrongEntitlementBinaries.isNotEmpty) {
      stdio.printError('Found ${wrongEntitlementBinaries.length} binaries with unexpected entitlements:');
      wrongEntitlementBinaries.forEach(stdio.printError);
    }

    if (unexpectedBinaries.isNotEmpty) {
      stdio.printError('Found ${unexpectedBinaries.length} unexpected binaries in the cache:');
      unexpectedBinaries.forEach(print);
    }

    // Finally, exit on any invalid state
    if (unsignedBinaries.isNotEmpty) {
      throw ConductorException('Test failed because unsigned binaries detected.');
    }

    if (wrongEntitlementBinaries.isNotEmpty) {
      throw ConductorException(
        'Test failed because files found with the wrong entitlements:\n'
        '${wrongEntitlementBinaries.join('\n')}',
      );
    }

    if (unexpectedBinaries.isNotEmpty) {
      throw ConductorException('Test failed because unexpected binaries found in the cache.');
    }

    final String? desiredRevision = argResults![kRevision] as String?;
    if (desiredRevision == null) {
      stdio.printStatus('Verified that binaries are codesigned and have expected entitlements.');
    } else {
      stdio.printStatus(
        'Verified that binaries for commit $desiredRevision are codesigned and have '
        'expected entitlements.',
      );
    }
  }

  List<String>? _allBinaryPaths;

  /// Find every binary file in the given [rootDirectory].
  Future<List<String>> findBinaryPaths(String rootDirectory) async {
    if (_allBinaryPaths != null) {
      return _allBinaryPaths!;
    }
    final List<String> allBinaryPaths = <String>[];
    final io.ProcessResult result = await processManager.run(
      <String>[
        'find',
        rootDirectory,
        '-type',
        'f',
      ],
    );
    final List<String> allFiles = (result.stdout as String)
        .split('\n')
        .where((String s) => s.isNotEmpty)
        .toList();

    await Future.forEach(allFiles, (String filePath) async {
      if (await isBinary(filePath)) {
        allBinaryPaths.add(filePath);
      }
    });
    _allBinaryPaths = allBinaryPaths;
    return _allBinaryPaths!;
  }

  /// Check mime-type of file at [filePath] to determine if it is binary.
  Future<bool> isBinary(String filePath) async {
    final io.ProcessResult result = await processManager.run(
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
  Future<bool> hasExpectedEntitlements(String binaryPath) async {
    final io.ProcessResult entitlementResult = await processManager.run(
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
        '${entitlementResult.stderr}\n',
      );
      return false;
    }

    bool passes = true;
    final String output = entitlementResult.stdout as String;
    for (final String entitlement in expectedEntitlements) {
      final bool entitlementExpected =
          (await binariesWithEntitlements).contains(binaryPath);
      if (output.contains(entitlement) != entitlementExpected) {
        stdio.printError(
          'File "$binaryPath" ${entitlementExpected ? 'does not have expected' : 'has unexpected'} '
          'entitlement $entitlement.',
        );
        passes = false;
      }
    }
    return passes;
  }
}

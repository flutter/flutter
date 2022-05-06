// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive_io.dart' as package_arch;
import 'package:args/command_runner.dart';
import 'package:crypto/crypto.dart';
import 'package:file/file.dart';
import 'package:http/io_client.dart';
import 'package:meta/meta.dart';
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
const String kCodesignCertName = 'codesign-cert-name';
const String kCodesignPrimaryBundleId = 'codesign-primary-bundle-id';
const String kCodesignUserName = 'codesign-username';
const String kAppSpecificPassword = 'app-specific-password';
const String kCodesignAppStoreId = 'codesign-appstore-id';
const String kCodesignTeamId = 'codesign-team-id';

/// Command to codesign and verify the signatures of cached binaries.
class CodesignCommand extends Command<void> {
  CodesignCommand({
    required this.checkouts,
    required this.flutterRoot,
    this.overrideFramework,
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
      kUpstream,
      defaultsTo: FrameworkRepository.defaultUpstream,
      help: "The git remote URL to use as the Flutter framework's upstream.",
    );
    argParser.addOption(
      kRevision,
      help: 'The Flutter framework revision to use.',
    );
    argParser.addOption(
      kCodesignCertName,
      help: 'The name of the codesign certificate to be used when codesigning.',
    );
    argParser.addOption(
      kCodesignPrimaryBundleId,
      help: 'Identifier for the application you are codesigning. This is only used '
        'for disambiguating codesign jobs in the notary service logging.',
      defaultsTo: 'dev.flutter.sdk'
    );
    argParser.addOption(
      kCodesignUserName,
      help: 'Apple developer account email used for authentication with notary service.',
    );
    argParser.addOption(
      kAppSpecificPassword,
      help: 'Unique password specifically for codesigning the given application.',
    );
    argParser.addOption(
      kCodesignAppStoreId,
      help: 'Apple-id for connecting to app store. Used by notary service for xcode version 13+.',
    );
    argParser.addOption(
      kCodesignTeamId,
      help: 'Team-id is used by notary service for xcode version 13+.',
    );
  }

  final Checkouts checkouts;
  final FileSystem fileSystem;
  final Platform platform;
  final ProcessManager processManager;
  final Stdio stdio;

  /// Root directory of the Flutter repository used by the conductor tool.
  final Directory flutterRoot;

  @visibleForTesting
  final FrameworkRepository? overrideFramework;

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

    final FrameworkRepository framework;
    if (overrideFramework != null) {
      framework = overrideFramework!;
    } else if (argResults!.wasParsed(kRevision)) {
      framework = FrameworkRepository.localRepoAsUpstream(
          checkouts,
          upstreamPath: flutterRoot.path,
          initialRef: argResults![kRevision] as String,
        );
    } else {
      framework = FrameworkRepository.localRepoAsUpstream(
          checkouts,
          upstreamPath: flutterRoot.path,
        );
    }

    if (argResults!['verify'] as bool == true) {
      return CodesignVerifyContext(
        framework: framework,
        checkouts: checkouts,
        shouldVerifySignatures: argResults![kSignatures] as bool,
        binariesWithEntitlements: binariesWithEntitlements(await framework.cacheDirectory),
        binariesWithoutEntitlements: binariesWithoutEntitlements(await framework.cacheDirectory),
      ).run();
    }

    final String codesignCertName = getValueFromEnvOrArgs(kCodesignCertName, argResults!, platform.environment)!;
    final String codesignPrimaryBundleId = getValueFromEnvOrArgs(kCodesignPrimaryBundleId, argResults!, platform.environment)!;
    final String codesignUserName = getValueFromEnvOrArgs(kCodesignUserName, argResults!, platform.environment)!;
    final String appSpecificPassword = getValueFromEnvOrArgs(kAppSpecificPassword, argResults!, platform.environment)!;
    final String codesignAppstoreId = getValueFromEnvOrArgs(kCodesignAppStoreId, argResults!, platform.environment)!;
    final String codesignTeamId = getValueFromEnvOrArgs(kCodesignTeamId, argResults!, platform.environment)!;

    return CodesignContext(
      framework: framework,
      checkouts: checkouts,
      localFlutterRoot: flutterRoot,
      binariesWithEntitlements: binariesWithEntitlements(await framework.cacheDirectory),
      binariesWithoutEntitlements: binariesWithoutEntitlements(await framework.cacheDirectory),
      codesignCertName: codesignCertName,
      codesignPrimaryBundleId: codesignPrimaryBundleId,
      codesignUserName: codesignUserName,
      appSpecificPassword: appSpecificPassword,
      codesignAppstoreId: codesignAppstoreId,
      codesignTeamId: codesignTeamId,
    ).run();
  }

  /// Binaries that are expected to be codesigned and have entitlements.
  ///
  /// This list should be kept in sync with the actual contents of Flutter's
  /// cache.
  List<String> binariesWithEntitlements(String cacheDirectoryPath) {
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
            fileSystem.path.join(cacheDirectoryPath, relativePath))
        .toList();
  }

  /// Binaries that are only expected to be codesigned.
  ///
  /// This list should be kept in sync with the actual contents of Flutter's
  /// cache.
  List<String> binariesWithoutEntitlements(String cacheDirectoryPath) {
    return <String>[
      'artifacts/engine/darwin-x64-profile/FlutterMacOS.framework/Versions/A/FlutterMacOS',
      'artifacts/engine/darwin-x64-release/FlutterMacOS.framework/Versions/A/FlutterMacOS',
      'artifacts/engine/darwin-x64/FlutterMacOS.framework/Versions/A/FlutterMacOS',
      'artifacts/engine/darwin-x64/font-subset',
      'artifacts/engine/ios-profile/Flutter.xcframework/ios-arm64/Flutter.framework/Flutter',
      'artifacts/engine/ios-profile/Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework/Flutter',
      'artifacts/engine/ios-release/Flutter.xcframework/ios-arm64/Flutter.framework/Flutter',
      'artifacts/engine/ios-release/Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework/Flutter',
      'artifacts/engine/ios/Flutter.xcframework/ios-arm64/Flutter.framework/Flutter',
      'artifacts/engine/ios/Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework/Flutter',
      'artifacts/ios-deploy/ios-deploy',
    ]
        .map((String relativePath) =>
            fileSystem.path.join(cacheDirectoryPath, relativePath))
        .toList();
  }
}

/// Logic shared between codesigning and verifying code signatures.
abstract class _Context {
  _Context({
    required this.framework,
    required this.checkouts,
    required this.binariesWithEntitlements,
    required this.binariesWithoutEntitlements,
    this.initialRevision,
  });

  final FrameworkRepository framework;
  final Checkouts checkouts;
  final String? initialRevision;
  final List<String> binariesWithEntitlements;
  final List<String> binariesWithoutEntitlements;

  FileSystem get fileSystem => checkouts.fileSystem;
  Platform get platform => checkouts.platform;
  ProcessManager get processManager => checkouts.processManager;
  Stdio get stdio => checkouts.stdio;

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
          binariesWithEntitlements.contains(binaryPath);
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

  /// Every binary file in framework's cache.
  late final Future<List<String>> _allBinaryPaths = (() async {
    final List<String> allBinaryPaths = <String>[];
    final io.ProcessResult result = processManager.runSync(
      <String>[
        'find',
        await framework.cacheDirectory,
        '-type',
        'f',
      ],
    );

    final List<String> allFiles = (result.stdout as String)
        .split('\n')
        .where((String s) => s.isNotEmpty)
        .toList();

    for (final String filePath in allFiles) {
      if (isBinary(filePath, processManager)) {
        allBinaryPaths.add(filePath);
      }
    }

    return allBinaryPaths;
  })();

  /// Verify code signatures and entitlements of all binaries in the cache.
  @visibleForTesting
  Future<void> verifySignatures() async {
    final List<String> unsignedBinaries = <String>[];
    final List<String> wrongEntitlementBinaries = <String>[];
    final List<String> unexpectedBinaries = <String>[];
    for (final String binaryPath in await _allBinaryPaths) {
      bool verifySignature = false;
      bool verifyEntitlements = false;
      if (binariesWithEntitlements.contains(binaryPath)) {
        verifySignature = true;
        verifyEntitlements = true;
      }
      if (binariesWithoutEntitlements.contains(binaryPath)) {
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
      stdio.printError(
          'Found ${wrongEntitlementBinaries.length} binaries with unexpected entitlements:');
      wrongEntitlementBinaries.forEach(stdio.printError);
    }

    if (unexpectedBinaries.isNotEmpty) {
      stdio.printError(
          'Found ${unexpectedBinaries.length} unexpected binaries in the cache:');
      unexpectedBinaries.forEach(print);
    }

    // Finally, exit on any invalid state
    if (unsignedBinaries.isNotEmpty) {
      throw ConductorException(
          'Test failed because unsigned binaries detected.');
    }

    if (wrongEntitlementBinaries.isNotEmpty) {
      throw ConductorException(
        'Test failed because files found with the wrong entitlements:\n'
        '${wrongEntitlementBinaries.join('\n')}',
      );
    }

    if (unexpectedBinaries.isNotEmpty) {
      throw ConductorException(
          'Test failed because unexpected binaries found in the cache.');
    }

    if (initialRevision == null) {
      stdio.printStatus(
          'Verified that binaries are codesigned and have expected entitlements.');
    } else {
      stdio.printStatus(
        'Verified that binaries for commit $initialRevision are codesigned and have '
        'expected entitlements.',
      );
    }
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
    for (final String binaryPath in await _allBinaryPaths) {
      if (binariesWithEntitlements.contains(binaryPath)) {
        foundFiles.add(binaryPath);
      } else if (binariesWithoutEntitlements.contains(binaryPath)) {
        foundFiles.add(binaryPath);
      } else {
        throw ConductorException(
            'Found unexpected binary in cache: $binaryPath');
      }
    }

    final List<String> allExpectedFiles = binariesWithEntitlements + binariesWithoutEntitlements;
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
}

/// A zip file that contains files that must be codesigned.
abstract class ZipArchive extends ArchiveFile {
  const ZipArchive({
    required this.files,
    required String path,
  }) : super(path: path);

  final List<ArchiveFile> files;
}

/// A zip file that must be downloaded then extracted.
class RemoteZip extends ZipArchive {
  const RemoteZip({
    required List<ArchiveFile> files,
    required String path,
  }) : super(path: path, files: files);

  @override
  Future<void> visit(FileVisitor visitor, Directory parent) {
    return visitor.visitRemoteZip(this, parent);
  }

  /// The [List] of all archives on cloud storage that contain binaries that
  /// must be codesigned.
  static List<RemoteZip> archives = <RemoteZip>[
    // Android artifacts
    // for (final String arch in <String>['arm', 'arm64', 'x64'])
    //   for (final String buildMode in <String>['release', 'profile'])
    //     RemoteZip(
    //       path: 'android-$arch-$buildMode/darwin-x64.zip',
    //       files: const <BinaryFile>[
    //         BinaryFile(path: 'gen_snapshot', entitlements: true),
    //       ],
    //     ),
    // // macOS Dart SDK
    // for (final String arch in <String>['arm64', 'x64'])
    //   RemoteZip(
    //     path: 'dart-sdk-darwin-$arch.zip',
    //     files: const <BinaryFile>[
    //       BinaryFile(path: 'dart-sdk/bin/dart', entitlements: true),
    //       BinaryFile(path: 'dart-sdk/bin/dartaotruntime', entitlements: true),
    //       BinaryFile(path: 'dart-sdk/bin/utils/gen_snapshot', entitlements: true),
    //     ],
    //   ),
    // // macOS host debug artifacts
    // const RemoteZip(
    //   path: 'darwin-x64/artifacts.zip',
    //   files: <BinaryFile>[
    //     BinaryFile(path: 'flutter_tester', entitlements: true),
    //     BinaryFile(path: 'gen_snapshot', entitlements: true),
    //   ],
    // ),
    // // macOS host profile and release artifacts
    // for (final String buildMode in <String>['profile', 'release'])
    //   RemoteZip(
    //     path: 'darwin-x64-$buildMode/artifacts.zip',
    //     files: const <BinaryFile>[
    //       BinaryFile(path: 'gen_snapshot', entitlements: true),
    //     ],
    //   ),
    // const RemoteZip(
    //   path: 'darwin-x64/font-subset.zip',
    //   files: <BinaryFile>[BinaryFile(path: 'font-subset')],
    // ),

    // // macOS desktop Framework
    // for (final String buildModeSuffix in <String>['', '-profile', '-release'])
    //   RemoteZip(
    //     path: 'darwin-x64$buildModeSuffix/FlutterMacOS.framework.zip',
    //     files: const <ArchiveFile>[
    //       EmbeddedZip(
    //         path: 'FlutterMacOS.framework.zip',
    //         files: <BinaryFile>[BinaryFile(path: 'Versions/A/FlutterMacOS')]
    //       ),
    //     ],
    //   ),

    // ios artifacts
    for (final String buildModeSuffix in <String>['']) //, '-profile', '-release'])
      RemoteZip(
        path: 'ios$buildModeSuffix/artifacts.zip',
        files: const <ArchiveFile>[
          BinaryFile(path: 'gen_snapshot_arm64', entitlements: true),
          BinaryFile(path: 'Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework/Flutter'),
          BinaryFile(path: 'Flutter.xcframework/ios-arm64/Flutter.framework/Flutter'),
        ],
      ),
  ];
}

/// Interface for classes that interact with files nested inside of [RemoteZip]s.
abstract class FileVisitor {
  const FileVisitor();

  Future<void> visitEmbeddedZip(EmbeddedZip file, Directory parent);
  Future<void> visitRemoteZip(RemoteZip file, Directory parent);
  Future<void> visitBinaryFile(BinaryFile file, Directory parent);
}

enum NotaryStatus {
  pending,
  failed,
  succeeded,
}

/// Codesign and notarize all files within a [RemoteArchive].
class FileCodesignVisitor extends FileVisitor {
  FileCodesignVisitor({
    required this.tempDir,
    required this.engineHash,
    required this.processManager,
    required this.codesignCertName,
    required this.codesignPrimaryBundleId,
    required this.codesignUserName,
    required this.appSpecificPassword,
    required this.codesignAppstoreId,
    required this.codesignTeamId,
    required this.stdio,
    required this.isNotaryTool,
  });

  /// Temp [Directory] to download/extract files to.
  ///
  /// This file will be deleted if [validateAll] completes successfully.
  final Directory tempDir;

  final String engineHash;
  final ProcessManager processManager;
  final String codesignCertName;
  final String codesignPrimaryBundleId;
  final String codesignUserName;
  final String appSpecificPassword;
  final String codesignAppstoreId;
  final String codesignTeamId;
  final Stdio stdio;
  final bool isNotaryTool;

  final IOClient httpClient = IOClient();

  late final File entitlementsFile = tempDir.childFile('Entitlements.plist')
      ..writeAsStringSync(_entitlementsFileContents);

  late final Directory remoteDownloadsDir = tempDir.childDirectory('downloads')..createSync();
  late final Directory codesignedZipsDir = tempDir.childDirectory('codesigned_zips')..createSync();

  int _remoteDownloadIndex = 0;
  int get remoteDownloadIndex => _remoteDownloadIndex++;

  static const String _entitlementsFileContents = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>com.apple.security.cs.allow-jit</key>
        <true/>
        <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
        <true/>
        <key>com.apple.security.cs.allow-dyld-environment-variables</key>
        <true/>
        <key>com.apple.security.network.client</key>
        <true/>
        <key>com.apple.security.network.server</key>
        <true/>
        <key>com.apple.security.cs.disable-library-validation</key>
        <true/>
    </dict>
</plist>
''';

  /// A [Map] from SHA1 hash of file contents to file pathname from expected
  /// files to codesign.
  ///
  /// These will be cross-referenced with all binary files unzipped.
  final Map<String, String> expectedFileHashes = <String, String>{};

  /// A [Map] from SHA1 hash of file contents to file pathname of codesigned
  /// binary files.
  ///
  /// This will be used to cross reference the remote files listed in
  /// [RemoteZip.archives] with the results of calling `flutter precache`.
  final Map<String, String> codesignedFileHashes = <String, String>{};

  /// A [Map] from SHA1 hash of file contents to file pathname of actual
  /// downloaded binary files.
  final Map<String, String> actualFileHashes = <String, String>{};

  int _nextId = 0;
  int get nextId {
    final int currentKey = _nextId;
    _nextId += 1;
    return currentKey;
  }

  Future<void> validateAll(Iterable<RemoteZip> archives) async {
    final Iterable<Future<void>> futures = archives.map<Future<void>>((RemoteZip archive) {
      final Directory outDir = tempDir.childDirectory('remote_zip_$nextId');
      return archive.visit(this, outDir);
    });
    await Future.wait(
      futures,
      eagerError: true,
    );
    _validateFileHashes();
    // TODO messaging?
  }

  /// Unzip an [EmbeddedZip] and visit its children.
  ///
  /// The [parent] directory is scoped to the parent zip file.
  @override
  Future<void> visitEmbeddedZip(EmbeddedZip file, Directory parent) async {
    print(' ');
    print('entered into embedded file');
    print(' ');
    final File localFile = await _validateFileExists(file, parent);
    final Directory newDir = tempDir.childDirectory('embedded_zip_$nextId');
    final package_arch.Archive? archive = await _unzip(localFile, newDir);
    if (archive != null) {
      await _hashActualFiles(archive, newDir);
    }
    final Iterable<Future<void>> childFutures = file.files.map<Future<void>>((ArchiveFile childFile) {
      return childFile.visit(this, newDir);
    });
    await Future.wait(childFutures);
    await localFile.delete();
    final package_arch.Archive? codesignedArchive = await _zip(newDir, localFile);
    if (codesignedArchive != null && archive != null) {
      _ensureArchivesAreEquivalent(
        archive.files,
        codesignedArchive.files,
      );
    }

    //newDir.deleteSync(recursive: true); // TODO do we need to delete this?
  }

  /// Download and unzip a [RemoteZip] file, and visit its children.
  ///
  /// The [parent] directory is scoped to this particular [RemoteZip].
  @override
  Future<void> visitRemoteZip(RemoteZip file, Directory parent) async {
    print(' ');
    print('entered into remote zip');
    print(' ');
    final FileSystem fs = tempDir.fileSystem;

    // namespace by index otherwise there will be collisions
    final String localFilePath = '${remoteDownloadIndex}_${fs.path.basename(file.path)}';
    // download the zip file

    print(' ');
    print('remote path is ${file.path}');
    print('local path is ${remoteDownloadsDir.childFile(localFilePath).path}');
    final File originalFile = await download(
      file.path,
      remoteDownloadsDir.childFile(localFilePath).path,
    );

    final package_arch.Archive? archive = await _unzip(originalFile, parent);

    if (archive != null) {
      await _hashActualFiles(archive, parent);
    }

    final Iterable<Future<void>> childFutures = file.files.map<Future<void>>((ArchiveFile childFile) {
      return childFile.visit(this, parent);
    });
    await Future.wait(childFutures);

    final File codesignedFile = codesignedZipsDir.childFile(localFilePath);

    final package_arch.Archive? codesignedArchive = await _zip(parent, codesignedFile);
    if (archive != null && codesignedArchive != null) {
      _ensureArchivesAreEquivalent(
        archive.files,
        codesignedArchive.files,
      );
    }

    // notarize
    await notarize(codesignedFile);

    await upload(
      codesignedFile.path,
      file.path,
    );
  }

  /// Codesign a binary file.
  ///
  /// The [parent] directory is scoped to the parent zip file.
  @override
  Future<void> visitBinaryFile(BinaryFile file, Directory parent) async {
    final File localFile = await _validateFileExists(file, parent);

    final String preSignDigest = sha1.convert(await localFile.readAsBytes()).toString(); // TODO delete
    expectedFileHashes[preSignDigest] = file.path;
    await codesign(localFile, file);

    final String hexDigest = sha1.convert(await localFile.readAsBytes()).toString();
    codesignedFileHashes[hexDigest] = file.path;
  }

  @visibleForTesting
  Future<void> codesign(File file, BinaryFile binaryFile) async {
    final List<String> args = <String>[
        'codesign',
        '-f', // force
        '-s', // use the cert provided by next argument
        codesignCertName,
        file.absolute.path,
        '--timestamp', // add a secure timestamp
        '--options=runtime', // hardened runtime
        if (binaryFile.entitlements)
          ...<String>['--entitlements', entitlementsFile.absolute.path],
    ];
    final io.ProcessResult result = await processManager.run(args);
    if (result.exitCode != 0) {
      throw Exception(
        'Failed to codesign ${file.absolute.path} with args: ${args.join(' ')}\n'
        'stdout:\n${(result.stdout as String).trim()}\n'
        'stderr:\n${(result.stderr as String).trim()}',
      );
    }
  }

  void _ensureArchivesAreEquivalent(List<package_arch.ArchiveFile> first, List<package_arch.ArchiveFile> second) {
    final Set<String> firstStrings = first.map<String>((package_arch.ArchiveFile file) {
      return file.name;
    }).toSet();
    final Set<String> secondStrings = first.map<String>((package_arch.ArchiveFile file) {
      return file.name;
    }).toSet();

    for (final String archiveName in firstStrings) {
      if (!secondStrings.contains(archiveName)) {
        throw Exception('first has $archiveName but second does not');
      }
    }
    for (final String archiveName in secondStrings) {
      if (!firstStrings.contains(archiveName)) {
        throw Exception('second has $archiveName but first does not');
      }
    }
  }

  static const Duration _notarizationTimerDuration = Duration(seconds: 45);

  /// Upload a zip archive to the notary service and verify the build succeeded.
  ///
  /// Only [RemoteArchive] zip files need to be uploaded to the notary service,
  /// as the service will unzip it, validate all binaries are codesigning, and
  /// notarize the entire archive.
  ///
  /// 
  Future<void> notarize(File file) async {
    final Completer<void> completer = Completer<void>();
    final String uuid = _uploadZipToNotary(file);

    Future<void> callback(Timer timer) async {
      final bool notaryFinished = checkNotaryJobFinished(uuid);
      if (notaryFinished) {
        timer.cancel();
        stdio.printStatus('successfully notarized ${file.path}');
        completer.complete();
      }
    }

    // check on results
    Timer.periodic(
      _notarizationTimerDuration,
      callback,
    );
    await completer.future;
  }

  static final RegExp _altoolStatusCheckPattern = RegExp(r'[ ]*Status: ([a-z ]+)');
  static final RegExp _notarytoolStatusCheckPattern = RegExp(r'[ ]*status: ([a-zA-z ]+)');

  /// Make a request to the notary service to see if the notary job is finished.
  ///
  /// A return value of true means that notarization finished successfully,
  /// false means that the job is still pending. If the notarization fails, this
  /// function will throw a [ConductorException].
  @visibleForTesting
  bool checkNotaryJobFinished(String uuid) {
    List<String> args;
    if(isNotaryTool){
      args = <String>[
        'xcrun',
        'notarytool',
        'info',
        uuid,
        '--password',
        appSpecificPassword,
        '--apple-id',
        codesignAppstoreId,
        '--team-id',
        codesignTeamId,
      ];
    }else{
      args = <String>[
        'xcrun',
        'altool',
        '--notarization-info',
        uuid,
        '-u',
        codesignUserName,
        '--password',
        appSpecificPassword,
      ];
    }

    stdio.printStatus('checking notary status with ${args.join(' ')}');
    final io.ProcessResult result = processManager.runSync(args);
    // Note that this tool outputs to STDOUT on Xcode 11, STDERR on earlier
    final String combinedOutput = (result.stdout as String) + (result.stderr as String);

    RegExpMatch? match;
    if(isNotaryTool){
      match = _notarytoolStatusCheckPattern.firstMatch(combinedOutput);
    }else{
      match = _altoolStatusCheckPattern.firstMatch(combinedOutput);
    }

    if (match == null) {
      throw ConductorException(
        'Malformed output from "${args.join(' ')}"\n${combinedOutput.trim()}',
      );
    }

    final String status = match.group(1)!;
    if(isNotaryTool){
      if (status == 'Accepted') {
        return true;
      }
      if (status == 'In Progress') {
        stdio.printStatus('job $uuid still pending');
        return false;
      }
      throw ConductorException('Notarization failed with: $status\n$combinedOutput');
    }else{
      if (status == 'success') {
        return true;
      }
      if (status == 'in progress') {
        stdio.printStatus('job $uuid still pending');
        return false;
      }
      throw ConductorException('Notarization failed with: $status\n$combinedOutput');
    }
  }

  static final RegExp _altoolRequestPattern = RegExp(r'RequestUUID = ([a-z0-9-]+)');
  static final RegExp _notarytoolRequestPattern = RegExp(r'id: ([a-z0-9-]+)');

  String _uploadZipToNotary(File localFile, [int retryCount = 3]) {
    while (retryCount > 0) {
      List<String> args;
      if(isNotaryTool){
        args = <String>[
          'xcrun',
          'notarytool',
          'submit',
          localFile.absolute.path,
          '--apple-id',
          codesignAppstoreId,
          '--password',
          appSpecificPassword,
          '--team-id',
          codesignTeamId,
        ];
      }
      else{
        args = <String>[
          'xcrun',
          'altool',
          '--notarize-app',
          '--primary-bundle-id',
          codesignPrimaryBundleId,
          '--username',
          codesignUserName,
          '--password',
          appSpecificPassword,
          '--file',
          localFile.absolute.path,
        ];
      }

      stdio.printStatus('uploading ${args.join(' ')}');
      // altool utilizes file locks, so run this synchronously
      final io.ProcessResult result = processManager.runSync(args);

      // Note that this tool outputs to STDOUT on Xcode 11, STDERR on earlier
      final String combinedOutput = (result.stdout as String) + (result.stderr as String);
      final RegExpMatch? match;
      if(isNotaryTool){
        match =  _notarytoolRequestPattern.firstMatch(combinedOutput);
      }else{
        match =  _altoolRequestPattern.firstMatch(combinedOutput);
      }
      if (match == null) {
        print('Failed to upload to the notary service with args: ${args.join(' ')}\n\n${combinedOutput.trim()}\n');
        retryCount -= 1;
        print('Trying again $retryCount more time${retryCount > 1 ? 's' : ''}...');
        io.sleep(const Duration(seconds: 1));
        continue;
      }

      final String requestUuid = match.group(1)!;
      print('RequestUUID for ${localFile.path} is: $requestUuid');

      return requestUuid;
    }
    throw ConductorException('Failed to upload ${localFile.path} to the notary service');
  }

  Future<void> _hashActualFiles(package_arch.Archive archive, Directory parent) async {
    final FileSystem fs = tempDir.fileSystem;
    for (final package_arch.ArchiveFile file in archive.files) {
      final String fileOrDirPath = fs.path.join(
        parent.path,
        file.name,
      );
      if (isBinary(fileOrDirPath, processManager)) {
        print('parent path is ${parent.path}');
        print('file name is ${file.name}');
        final String hexDigest = sha1.convert(await fs.file(fileOrDirPath).readAsBytes()).toString();
        actualFileHashes[hexDigest] = fileOrDirPath;
      }
    }
  }

  static const String gsCloudBaseUrl = r'gs://flutter_infra_release';

  @visibleForOverriding
  Future<File> download(String remotePath, String localPath) async {
    final String source = '$gsCloudBaseUrl/flutter/$engineHash/$remotePath';
    print('');
    print('source is $source');
    print('localPath is $localPath');
    print('');
    final io.ProcessResult result = await processManager.run(
      <String>['gsutil', 'cp', source, localPath],
    );
    if (result.exitCode != 0) {
      throw Exception('Failed to download $source');
    }
    return tempDir.fileSystem.file(localPath);
  }

  @visibleForOverriding
  Future<void> upload(String localPath, String remotePath) async {
    final String fullRemotePath = '$gsCloudBaseUrl/flutter/$engineHash/$remotePath';
    final io.ProcessResult result = await processManager.run(
      <String>['gsutil', 'cp', localPath, fullRemotePath],
    );
    if (result.exitCode != 0) {
      throw Exception('Failed to upload $localPath to $fullRemotePath');
    }
  }

  Future<package_arch.Archive?> _unzip(File inputZip, Directory outDir) async {
    // unzip is faster, commenting it out to pass hash check
    // if (processManager.canRun('unzip')) {
    //   await processManager.run(
    //     <String>[
    //       'unzip',
    //       inputZip.absolute.path,
    //       '-d',
    //       outDir.absolute.path,
    //     ],
    //   );
    //   return null;
    // } else {
    //  stdio.printError('unzip binary not found on path, falling back to package:archive implementation');
      final Uint8List bytes = await inputZip.readAsBytes();
      final package_arch.Archive archive = package_arch.ZipDecoder().decodeBytes(bytes);
      package_arch.extractArchiveToDisk(archive, outDir.path);
      print('');
      print('this is unzipped to ${outDir.path}');
      print('');
      return archive;
    //}
  }

  Future<package_arch.Archive?> _zip(Directory inDir, File outputZip) async {
    // zip is faster
    if (processManager.canRun('zip')) {
      await processManager.run(
        <String>[
          'zip',
          '--symlinks',
          '--recurse-paths',
          outputZip.absolute.path,
          // use '.' so that the full absolute path is not encoded into the zip file
          '.',
          '--include',
          '*',
        ],
        workingDirectory: inDir.absolute.path,
      );
      return null;
    } else {
      stdio.printError('zip binary not found on path, falling back to package:archive implementation');
      final package_arch.Archive archive = package_arch.createArchiveFromDirectory(inDir);
      package_arch.ZipFileEncoder().zipDirectory(
          inDir,
          filename: outputZip.absolute.path,
      );
      return archive;
    }
  }

  /// Ensure that the expected binaries equal exactly the number of binary files
  /// that were downloaded and extracted.
  void _validateFileHashes() {
    int diffs = 0;
    for (final MapEntry<String, String> entry in expectedFileHashes.entries) {
      if (!actualFileHashes.keys.contains(entry.key)) {
        diffs += 1;
        stdio.printError('The value ${entry.value} was expected but not actually found.');
      }
    }
    for (final MapEntry<String, String> entry in actualFileHashes.entries) {
      if (!expectedFileHashes.keys.contains(entry.key)) {
        diffs += 1;
        stdio.printError('The value ${entry.value} was found but not expected.');
      }
    }
    if (diffs > 0) {
      throw '$diffs diffs found!\nExpected length: ${expectedFileHashes.length}\nActual length: ${actualFileHashes.length}';
    }
  }

  Future<File> _validateFileExists(ArchiveFile archiveFile, Directory parent) async {
    final FileSystem fileSystem = parent.fileSystem;
    final String filePath = fileSystem.path.join(
        parent.absolute.path,
        archiveFile.path,
    );
    final File file = fileSystem.file(filePath);
    if (!(await file.exists())) {
      throw Exception('${file.absolute.path} was expected to exist but does not!');
    }
    return file;
  }
}

class EmbeddedZip extends ZipArchive {
  const EmbeddedZip({
    required super.files,
    required super.path,
  });

  @override
  Future<void> visit(FileVisitor visitor, Directory parent) {
    return visitor.visitEmbeddedZip(this, parent);
  }
}

abstract class ArchiveFile {
  const ArchiveFile({
    required this.path,
  });

  final String path;

  Future<void> visit(FileVisitor visitor, Directory parent);
}

class BinaryFile extends ArchiveFile {
  const BinaryFile({
    this.entitlements = false,
    required super.path,
  });

  final bool entitlements;

  @override
  Future<void> visit(FileVisitor visitor, Directory parent) {
    return visitor.visitBinaryFile(this, parent);
  }
}

class CodesignContext extends _Context {
  CodesignContext({
    required super.framework,
    required super.checkouts,
    required super.binariesWithEntitlements,
    required super.binariesWithoutEntitlements,
    required this.localFlutterRoot,
    required this.codesignCertName,
    required this.codesignPrimaryBundleId,
    required this.codesignUserName,
    required this.appSpecificPassword,
    required this.codesignAppstoreId,
    required this.codesignTeamId,
  });

  final Directory localFlutterRoot;
  final String codesignCertName;
  final String codesignPrimaryBundleId;
  final String codesignUserName;
  final String appSpecificPassword;
  final String codesignAppstoreId;
  final String codesignTeamId;

  bool checkXcodeVersion(){
    bool isNotaryTool = true;
    print('checking Xcode version...');
    final io.ProcessResult result = processManager.runSync(
      <String>[
        'xcodebuild',
        '-version',
      ],
    );
    final List<String> outArray = (result.stdout as String).split('\n');
    final int xcodeVersion = int.parse(outArray[0].split(' ')[1].split('.')[0]);
    if(xcodeVersion <= 12){
      isNotaryTool = false;
    }
        
    print('based on your xcode major version of $xcodeVersion, the decision to use notarytool is $isNotaryTool');
    return isNotaryTool;
  }

  Future<void> run() async {
    if (initialRevision != null) {
      throw 'unimplemented'; // TODO
    }

    final String revision = ((await processManager.run(
      <String>['git', 'rev-parse', 'HEAD'],
      workingDirectory: localFlutterRoot.path,
    ))
        .stdout as String)
        .trim();

    final String engineHash = (await localFlutterRoot
        .childDirectory('bin')
        .childDirectory('internal')
        .childFile('engine.version')
        .readAsString())
        .trim();

    final bool isNotaryTool = checkXcodeVersion();
    final Directory tempDir = fileSystem.systemTempDirectory.createTempSync('conductor_codesign');
    final FileCodesignVisitor codesignVisitor = FileCodesignVisitor(
      tempDir: tempDir,
      engineHash: engineHash,
      processManager: processManager,
      codesignCertName: codesignCertName,
      codesignPrimaryBundleId: codesignPrimaryBundleId,
      codesignUserName: codesignUserName,
      appSpecificPassword: appSpecificPassword,
      stdio: stdio,
      codesignAppstoreId: codesignAppstoreId,
      codesignTeamId: codesignTeamId,
      isNotaryTool: isNotaryTool,
    );

    await codesignVisitor.validateAll(RemoteZip.archives);

    stdio.printStatus('Codesigned all binaries in ${tempDir.path}');
  }
}

class CodesignVerifyContext extends _Context {
  CodesignVerifyContext({
    required FrameworkRepository framework,
    required Checkouts checkouts,
    required this.shouldVerifySignatures,
    required List<String> binariesWithEntitlements,
    required List<String> binariesWithoutEntitlements,
    String? initialRevision,
  }) : super(
    framework: framework,
    checkouts: checkouts,
    initialRevision: initialRevision,
    binariesWithEntitlements: binariesWithEntitlements,
    binariesWithoutEntitlements: binariesWithoutEntitlements,
  );

  final bool shouldVerifySignatures;

  Future<void> run() async {
    final String revision;
    if (initialRevision != null) {
      stdio.printWarning(
        'Warning! When providing an arbitrary revision, the contents of the cache may not '
        'match the expected binaries in the conductor tool. It is preferred to check out '
        'the desired revision and run that version of the conductor.\n',
      );
      revision = initialRevision!;
    } else {
      revision = ((await processManager.run(
        <String>['git', 'rev-parse', 'HEAD'],
        workingDirectory: (await framework.checkoutDirectory).path,
      ))
              .stdout as String)
          .trim();
      assert(revision.isNotEmpty);
    }

    await framework.checkout(revision);

    // Ensure artifacts present
    await _precacheArtifacts(framework);

    await verifyExist();
    if (shouldVerifySignatures) {
      await verifySignatures();
    }
  }
}

/// Check mime-type of file at [filePath] to determine if it is binary.
@visibleForTesting
bool isBinary(String filePath, ProcessManager processManager) {
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

Future<io.ProcessResult> _precacheArtifacts(FrameworkRepository framework) {
  return framework
      .runFlutter(<String>['precache', '--android', '--ios', '--macos']);
}

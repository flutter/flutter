// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This test clones the framework and downloads pre-built binaries; it sometimes
// times out with the default 5 minutes: https://github.com/flutter/flutter/issues/100937
@Timeout(Duration(minutes: 50)) // should be 10

import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:conductor_core/src/codesign.dart';
import 'package:conductor_core/src/globals.dart';
import 'package:conductor_core/src/repository.dart'
    show Checkouts, FrameworkRepository;
import 'package:conductor_core/src/stdio.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:http/http.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import './common.dart';

/// Verify all binaries in the Flutter cache are expected by Conductor.
void main() {
  const FileSystem fileSystem = LocalFileSystem();
  const Platform platform = LocalPlatform();
  const ProcessManager processManager = LocalProcessManager();

  final Directory flutterRoot = _flutterRootFromDartBinary(
    fileSystem.file(platform.executable),
  );

  final String engineHash = flutterRoot
      .childDirectory('bin')
      .childDirectory('internal')
      .childFile('engine.version')
      .readAsStringSync()
      .trim();

  group('codesigning', () {
    late Directory tempDir;

    setUp(() {
      tempDir = fileSystem.directory('/Users/fujino/git/tmp/workspace'); // TODO
      tempDir.deleteSync(recursive: true);
      tempDir.createSync(recursive: true);
      //tempDir = fileSystem.systemTempDirectory
      //    .createTempSync('codesign_integration_test')
      //    .absolute;
    });

    tearDown(() {
      // TODO catch failure?
      //tempDir.deleteSync();
    });

    test('validate remote artifacts all exist', () async {
      final _FileValidationVisitor validator = _FileValidationVisitor(
        engineHash: engineHash,
        processManager: processManager,
        tempDir: tempDir,
      );

      await validator.validateAll(RemoteZip.archives);
    });

    test('notarize these bad boys', () async { // TODO remove
      final FileCodesignVisitor validator = TODOFileCodesignVisitor(
        engineHash: engineHash,
        processManager: processManager,
        tempDir: tempDir,
        codesignCertName: 'flutter',
        stdio: VerboseStdio.local(),
      );

      await validator.validateAll(RemoteZip.archives);
    });
  }, onPlatform: <String, dynamic>{
    'windows': const Skip('codesign command is only supported on macos'),
    'linux': const Skip('codesign command is only supported on macos'),
  });

  test(
      'validate the expected binaries from the conductor codesign --verify command are present in the cache',
      () async {
    final Directory tempDir = fileSystem.systemTempDirectory
        .createTempSync('flutter_conductor_integration_test.');
    final TestStdio stdio = TestStdio(verbose: true);
    final Checkouts checkouts = Checkouts(
      fileSystem: fileSystem,
      parentDirectory: tempDir,
      platform: platform,
      processManager: processManager,
      stdio: stdio,
    );

    final String currentHead = (processManager.runSync(
      <String>['git', 'rev-parse', 'HEAD'],
      workingDirectory: flutterRoot.path,
    ).stdout as String)
        .trim();

    final FrameworkRepository framework =
        FrameworkRepository.localRepoAsUpstream(
      checkouts,
      upstreamPath: flutterRoot.path,
      initialRef: currentHead,
    );
    final CommandRunner<void> runner = CommandRunner<void>('codesign-test', '');
    runner.addCommand(
      CodesignCommand(
        checkouts: checkouts,
        overrideFramework: framework,
        flutterRoot: flutterRoot,
      ),
    );

    try {
      await runner.run(<String>[
        'codesign',
        '--verify',
        // Only verify if the correct binaries are in the cache
        '--no-signatures',
      ]);
    } on ConductorException catch (e) {
      print(stdio.error);
      print(_fixItInstructions);
      fail(e.message);
    } on Exception {
      print('stdout:\n${stdio.stdout}');
      print('stderr:\n${stdio.error}');
      rethrow;
    }
  }, onPlatform: <String, dynamic>{
    'windows': const Skip('codesign command is only supported on macos'),
    'linux': const Skip('codesign command is only supported on macos'),
  });
}

class TODOFileCodesignVisitor extends FileCodesignVisitor {
  TODOFileCodesignVisitor({
    required super.tempDir,
    required super.engineHash,
    required super.processManager,
    required super.codesignCertName,
    required super.stdio,
  }) : super(
    appSpecificPassword: appSpecificPasswordEnv,
    codesignUserName: codesignUserNameEnv,
    codesignPrimaryBundleId: 'dev.flutter.sdk',
    codesignAppstoreId: codesignAppstoreIdEnv,
    codesignTeamId: codesignTeamIdEnv,
    isNotaryTool: true,
  );

  static final String appSpecificPasswordEnv = io.Platform.environment['APP_SPECIFIC_PASSWORD']!;
  static final String codesignUserNameEnv = io.Platform.environment['CODESIGN_USERNAME']!;
  static final String codesignAppstoreIdEnv = io.Platform.environment['CODESIGN_APPSTORE_ID']!;
  static final String codesignTeamIdEnv = io.Platform.environment['CODESIGN_TEAM_ID']!;

  late final Directory todoUploadDir = tempDir.childDirectory('uploads')..createSync(); // TODO delete
  late final File todoUploadManifest = todoUploadDir.childFile('manifest.txt')..createSync();
  int _todoUploadManifestIndex = 0;
  int get todoUploadManifestIndex => _todoUploadManifestIndex++; // TODO delete

  @override
  Future<void> upload(String localPath, String remotePath) async {
    print('uploading $localPath to $remotePath');
    final File localFile = tempDir.fileSystem.file(localPath);
    final String remoteFileBase = remotePath.split(r'/').last;
    final int index = todoUploadManifestIndex;
    await todoUploadManifest.writeAsString(
      '$index\t$remotePath\n',
      mode: FileMode.append,
    );
    await localFile.copy(todoUploadDir.childFile('${index}_$remoteFileBase').absolute.path);
  }
}

class _FileValidationVisitor extends FileCodesignVisitor {
  _FileValidationVisitor({
    required super.tempDir,
    required super.engineHash,
    required super.processManager,
  }) : super(
    codesignCertName: 'FLUTTER',
    appSpecificPassword: 'unused',
    codesignUserName: 'unused',
    codesignPrimaryBundleId: 'unused',
    codesignAppstoreId: 'unused',
    codesignTeamId: 'unused',
    stdio: TestStdio(),
    isNotaryTool: true,
  );

  @override
  Future<void> codesign(File file, BinaryFile binaryFile) async {
    // no-op
  }

  @override
  Future<void> notarize(File file) async {
    // no-op
  }

  // An implementation that does not depend on the gcloud tool or write access
  // to cloud storage bucket.
  @override
  Future<File> download(String remotePath, String localPath) async {
    const String cloudHttpBaseUrl = r'https://storage.googleapis.com/flutter_infra_release';

    final String source = '$cloudHttpBaseUrl/flutter/$engineHash/$remotePath';

    // curl is faster
    if (processManager.canRun('curl')) {
      final io.ProcessResult response = await processManager.run(<String>[
        'curl',
        // follow redirects
        '--location',
        // specify output filepath
        '--output',
        localPath,
        source,
      ]);
      final File localFile = tempDir.fileSystem.file(localPath);
      if (response.exitCode != 0) {
        throw Exception('Failed to download $remotePath!');
      }
      if (!(await localFile.exists())) {
        throw Exception('Download of $remotePath succeeded but file $localPath not present on disk!');
      }
      return localFile;
    } else {
      print('curl binary not found on path, falling back to package:http implementation');
      final Response response = await httpClient.get(Uri.parse(source));
      if (response.statusCode != 200) {
        throw ClientException('Got ${response.statusCode} from $source');
      }
      final File localFile = await tempDir.fileSystem.file(localPath).create(recursive: true);
      return localFile.writeAsBytes(response.bodyBytes);
    }
  }

  late final Directory todoUploadDir = tempDir.childDirectory('uploads')..createSync(); // TODO delete
  late final File todoUploadManifest = todoUploadDir.childFile('manifest.txt')..createSync();
  int _todoUploadManifestIndex = 0;
  int get todoUploadManifestIndex => _todoUploadManifestIndex++; // TODO delete

  @override
  Future<void> upload(String localPath, String remotePath) async {
    // no-op
    //return 'no-op';

    // TODO delete
    final File localFile = tempDir.fileSystem.file(localPath);
    final String remoteFileBase = remotePath.split(r'/').last;
    final int index = todoUploadManifestIndex;
    await todoUploadManifest.writeAsString(
      '$index\t$remotePath\n',
      mode: FileMode.append,
    );
    await localFile.copy(todoUploadDir.childFile('${index}_$remoteFileBase').absolute.path);
  }
}

Directory _flutterRootFromDartBinary(File dartBinary) {
  final Directory flutterDartSdkDir = dartBinary.parent.parent;
  final Directory flutterCache = flutterDartSdkDir.parent;
  final Directory flutterSdkDir = flutterCache.parent.parent;
  return flutterSdkDir;
}

const String _fixItInstructions = '''
Codesign integration test failed.

This means that the binary files found in the Flutter cache do not match those
expected by the conductor tool (either an expected file was not found in the
cache or an unexpected file was found in the cache).

This usually happens either during an engine roll or a change to the caching
logic in flutter_tools. If this is a valid change, then the conductor source
code should be updated, specifically either the [binariesWithEntitlements] or
[binariesWithoutEntitlements] lists, depending on if the file should have macOS
entitlements applied during codesigning.
''';

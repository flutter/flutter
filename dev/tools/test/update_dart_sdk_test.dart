// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io' as io;

import 'package:archive/archive.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';
import 'package:test/test.dart';

const String _kInitialEngineVersion = 'engine-version-initial';
const String _kUpdatedEngineVersion = 'engine-version-updated';
const String _kExtraFileName = 'extra_file.txt';
const String _kAnotherFileName = 'another_new_file.txt';
const String _kLicenseFileName = 'LICENSE.dart_sdk_archive.md';

void main() {
  final usePowershellOnPosix = io.Platform.environment['FORCE_POWERSHELL'] == 'true';

  const FileSystem localFs = LocalFileSystem();
  final flutterRoot = _FlutterRootUnderTest.findWithin(forcePowershell: usePowershellOnPosix);

  late Directory tmpDir;
  late _FlutterRootUnderTest testRoot;
  late Map<String, String> environment;
  late io.HttpServer mockStorageServer;
  late Map<String, List<int>> serverFiles;

  void printIfNotEmpty(String prefix, String string) {
    if (string.isNotEmpty) {
      for (final String s in string.split(io.Platform.lineTerminator)) {
        print('$prefix:>$s<');
      }
    }
  }

  Future<io.ProcessResult> run(String executable, List<String> args, {String? workingPath}) async {
    print('Running "$executable ${args.join(" ")}"${workingPath != null ? ' $workingPath' : ''}');
    final io.ProcessResult result = await io.Process.run(
      executable,
      args,
      environment: <String, String>{...io.Platform.environment, ...environment},
      workingDirectory: workingPath ?? testRoot.root.absolute.path,
    );
    if (result.exitCode != 0) {
      fail(
        'Failed running "$executable $args" (exit code = ${result.exitCode}),'
        '\nstdout: ${result.stdout}'
        '\nstderr: ${result.stderr}',
      );
    }
    printIfNotEmpty('stdout', (result.stdout as String).trim());
    printIfNotEmpty('stderr', (result.stderr as String).trim());
    return result;
  }

  setUpAll(() async {
    if (usePowershellOnPosix) {
      final io.ProcessResult result = io.Process.runSync('pwsh', <String>['--version']);
      print('Using Powershell (${result.stdout}) on POSIX for local debugging and testing');
    }
  });

  setUp(() async {
    tmpDir = localFs.systemTempDirectory.createTempSync('update_dart_sdk_test.');
    testRoot = _FlutterRootUnderTest.fromPath(
      tmpDir.childDirectory('flutter').path,
      forcePowershell: usePowershellOnPosix,
    );

    serverFiles = <String, List<int>>{};
    mockStorageServer = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
    mockStorageServer.listen((io.HttpRequest request) async {
      await request.drain<void>();
      final String path = request.uri.path;
      for (final MapEntry(:key, :value) in serverFiles.entries) {
        if (path.contains(key)) {
          request.response.headers.contentType = io.ContentType.binary;
          request.response.headers.contentLength = value.length;
          request.response.add(value);
          await request.response.close();
          return;
        }
      }
      request.response.statusCode = io.HttpStatus.notFound;
      await request.response.close();
    });

    environment = <String, String>{
      'FLUTTER_STORAGE_BASE_URL':
          'http://${mockStorageServer.address.host}:${mockStorageServer.port}',
    };

    flutterRoot.binInternalUpdateDartSdk.copySyncRecursive(testRoot.binInternalUpdateDartSdk.path);

    testRoot.binCacheEngineStamp.parent.createSync(recursive: true);
    testRoot.binCacheEngineRealm.writeAsStringSync('');
  });

  tearDown(() async {
    await mockStorageServer.close(force: true);
    if (tmpDir.existsSync()) {
      tmpDir.deleteSync(recursive: true);
    }
  });

  Future<io.ProcessResult> runUpdateDartSdk() {
    final String executable;
    final List<String> args;
    if (const LocalPlatform().isWindows) {
      executable = 'powershell';
      args = <String>[testRoot.binInternalUpdateDartSdk.path];
    } else if (usePowershellOnPosix) {
      executable = 'pwsh';
      args = <String>[testRoot.binInternalUpdateDartSdk.path];
    } else {
      executable = testRoot.binInternalUpdateDartSdk.path;
      args = <String>[];
    }
    return run(executable, args);
  }

  List<int> createDartSdkZip(Map<String, String> files) {
    final archive = Archive();
    for (final MapEntry(:key, :value) in files.entries) {
      final List<int> data = utf8.encode(value);
      archive.addFile(ArchiveFile(key, data.length, data));
    }
    return ZipEncoder().encode(archive)!;
  }

  test('extracts all archive contents and updates without conflicts', () async {
    testRoot.binCacheEngineStamp.writeAsStringSync(_kInitialEngineVersion);

    final List<int> initialZip = createDartSdkZip(<String, String>{
      'dart-sdk/bin/dart': 'initial dart binary',
      'dart-sdk/version': '3.0.0',
      _kLicenseFileName: 'initial license content',
      _kExtraFileName: 'initial extra content',
      'extra_dir/file.txt': 'initial directory file content',
    });

    serverFiles[_kInitialEngineVersion] = initialZip;
    serverFiles['dart-sdk-'] = initialZip;

    await runUpdateDartSdk();

    expect(testRoot.binCacheEngineDartSdkStamp.existsSync(), isTrue);
    expect(testRoot.binCacheEngineDartSdkStamp.readAsStringSync().trim(), _kInitialEngineVersion);
    expect(testRoot.binCacheDartSdk.childDirectory('bin').childFile('dart').existsSync(), isTrue);
    expect(
      testRoot.binCacheDartSdk.childDirectory('bin').childFile('dart').readAsStringSync(),
      'initial dart binary',
    );
    expect(testRoot.binCache.childFile(_kLicenseFileName).existsSync(), isTrue);
    expect(
      testRoot.binCache.childFile(_kLicenseFileName).readAsStringSync(),
      'initial license content',
    );
    expect(testRoot.binCache.childFile(_kExtraFileName).existsSync(), isTrue);
    expect(
      testRoot.binCache.childFile(_kExtraFileName).readAsStringSync(),
      'initial extra content',
    );
    expect(
      testRoot.binCache.childDirectory('extra_dir').childFile('file.txt').existsSync(),
      isTrue,
    );
    expect(
      testRoot.binCache.childDirectory('extra_dir').childFile('file.txt').readAsStringSync(),
      'initial directory file content',
    );

    // Now simulate an update with a new engine version and updated/additional files.
    testRoot.binCacheEngineStamp.writeAsStringSync(_kUpdatedEngineVersion);

    final List<int> updatedZip = createDartSdkZip(<String, String>{
      'dart-sdk/bin/dart': 'updated dart binary',
      'dart-sdk/version': '3.1.0',
      _kLicenseFileName: 'updated license content',
      _kExtraFileName: 'updated extra content',
      'extra_dir/file.txt': 'updated directory file content',
      _kAnotherFileName: 'another file content',
    });

    serverFiles[_kUpdatedEngineVersion] = updatedZip;
    serverFiles['dart-sdk-'] = updatedZip;

    await runUpdateDartSdk();

    expect(testRoot.binCacheEngineDartSdkStamp.existsSync(), isTrue);
    expect(testRoot.binCacheEngineDartSdkStamp.readAsStringSync().trim(), _kUpdatedEngineVersion);
    expect(testRoot.binCacheDartSdk.childDirectory('bin').childFile('dart').existsSync(), isTrue);
    expect(
      testRoot.binCacheDartSdk.childDirectory('bin').childFile('dart').readAsStringSync(),
      'updated dart binary',
    );
    expect(testRoot.binCache.childFile(_kLicenseFileName).existsSync(), isTrue);
    expect(
      testRoot.binCache.childFile(_kLicenseFileName).readAsStringSync(),
      'updated license content',
    );
    expect(testRoot.binCache.childFile(_kExtraFileName).existsSync(), isTrue);
    expect(
      testRoot.binCache.childFile(_kExtraFileName).readAsStringSync(),
      'updated extra content',
    );
    expect(
      testRoot.binCache.childDirectory('extra_dir').childFile('file.txt').existsSync(),
      isTrue,
    );
    expect(
      testRoot.binCache.childDirectory('extra_dir').childFile('file.txt').readAsStringSync(),
      'updated directory file content',
    );
    expect(testRoot.binCache.childFile(_kAnotherFileName).existsSync(), isTrue);
    expect(
      testRoot.binCache.childFile(_kAnotherFileName).readAsStringSync(),
      'another file content',
    );

    // Ensure no leftover .old files remain in cache
    final List<FileSystemEntity> leftoverOld = testRoot.binCache
        .listSync()
        .where((FileSystemEntity entity) => entity.basename.contains('.old'))
        .toList();
    expect(leftoverOld, isEmpty);
  });
}

final class _FlutterRootUnderTest {
  factory _FlutterRootUnderTest.fromPath(
    String path, {
    FileSystem fileSystem = const LocalFileSystem(),
    Platform platform = const LocalPlatform(),
    bool forcePowershell = false,
  }) {
    final Directory root = fileSystem.directory(path);
    return _FlutterRootUnderTest._(
      root,
      binCache: root.childDirectory(fileSystem.path.join('bin', 'cache')),
      binCacheDartSdk: root.childDirectory(fileSystem.path.join('bin', 'cache', 'dart-sdk')),
      binCacheEngineStamp: root.childFile(fileSystem.path.join('bin', 'cache', 'engine.stamp')),
      binCacheEngineRealm: root.childFile(fileSystem.path.join('bin', 'cache', 'engine.realm')),
      binCacheEngineDartSdkStamp: root.childFile(
        fileSystem.path.join('bin', 'cache', 'engine-dart-sdk.stamp'),
      ),
      binInternalUpdateDartSdk: root.childFile(
        fileSystem.path.join(
          'bin',
          'internal',
          'update_dart_sdk.${platform.isWindows || forcePowershell ? 'ps1' : 'sh'}',
        ),
      ),
    );
  }

  factory _FlutterRootUnderTest.findWithin({
    String? path,
    FileSystem fileSystem = const LocalFileSystem(),
    bool forcePowershell = false,
  }) {
    path ??= fileSystem.currentDirectory.path;
    Directory current = fileSystem.directory(path);
    while (!current.childFile('DEPS').existsSync()) {
      if (current.path == current.parent.path) {
        throw ArgumentError.value(path, 'path', 'Could not resolve flutter root');
      }
      current = current.parent;
    }
    return _FlutterRootUnderTest.fromPath(current.path, forcePowershell: forcePowershell);
  }

  const _FlutterRootUnderTest._(
    this.root, {
    required this.binCache,
    required this.binCacheDartSdk,
    required this.binCacheEngineStamp,
    required this.binCacheEngineRealm,
    required this.binCacheEngineDartSdkStamp,
    required this.binInternalUpdateDartSdk,
  });

  final Directory root;
  final Directory binCache;
  final Directory binCacheDartSdk;
  final File binCacheEngineStamp;
  final File binCacheEngineRealm;
  final File binCacheEngineDartSdkStamp;
  final File binInternalUpdateDartSdk;
}

extension on File {
  void copySyncRecursive(String newPath) {
    fileSystem.directory(fileSystem.path.dirname(newPath)).createSync(recursive: true);
    copySync(newPath);
  }
}

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
const String _kLicenseFileName = 'LICENSE.dart_sdk_archive.md';
const String _kEntitlementsFileName = 'entitlements.txt';
const String _kWithoutEntitlementsFileName = 'without_entitlements.txt';
const String _kDartBinaryPath = 'dart-sdk/bin/dart';
const String _kDartVersionPath = 'dart-sdk/version';
const String _kForcePowershellEnv = 'FORCE_POWERSHELL';
const String _kStorageBaseUrlEnv = 'FLUTTER_STORAGE_BASE_URL';
const String _kHeadMethod = 'HEAD';

Directory _findFlutterRoot(FileSystem fileSystem) {
  Directory current = fileSystem.currentDirectory;
  while (!current.childFile('DEPS').existsSync()) {
    if (current.path == current.parent.path) {
      throw StateError('Could not resolve Flutter root from ${fileSystem.currentDirectory.path}');
    }
    current = current.parent;
  }
  return current;
}

List<int> _createZip(Map<String, String> files) {
  final archive = Archive();
  for (final MapEntry(:key, :value) in files.entries) {
    final List<int> data = utf8.encode(value);
    archive.addFile(ArchiveFile(key, data.length, data));
  }
  return ZipEncoder().encode(archive)!;
}

void main() {
  const FileSystem localFs = LocalFileSystem();
  const Platform platform = LocalPlatform();
  final usePowershellOnPosix = io.Platform.environment[_kForcePowershellEnv] == 'true';
  final bool usePowershell = platform.isWindows || usePowershellOnPosix;
  final scriptName = 'update_dart_sdk.${usePowershell ? 'ps1' : 'sh'}';
  final Directory flutterRoot = _findFlutterRoot(localFs);

  late Directory tmpDir;
  late Directory testRoot;
  late Directory cacheDir;
  late File updateScript;
  late io.HttpServer mockStorageServer;
  late Map<String, List<int>> serverZips;

  setUp(() async {
    tmpDir = localFs.systemTempDirectory.createTempSync('update_dart_sdk_test.');
    testRoot = tmpDir.childDirectory('flutter');
    cacheDir = testRoot.childDirectory(localFs.path.join('bin', 'cache'))
      ..createSync(recursive: true);
    updateScript = testRoot.childFile(localFs.path.join('bin', 'internal', scriptName));
    updateScript.parent.createSync(recursive: true);
    flutterRoot
        .childFile(localFs.path.join('bin', 'internal', scriptName))
        .copySync(updateScript.path);
    cacheDir.childFile('engine.realm').writeAsStringSync('');

    serverZips = <String, List<int>>{};
    mockStorageServer = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
    mockStorageServer.listen((io.HttpRequest request) async {
      await request.drain<void>();
      for (final MapEntry(:key, :value) in serverZips.entries) {
        if (request.uri.pathSegments.contains(key)) {
          request.response.headers.contentType = io.ContentType.binary;
          request.response.headers.contentLength = value.length;
          if (request.method != _kHeadMethod) {
            request.response.add(value);
          }
          await request.response.close();
          return;
        }
      }
      request.response.statusCode = io.HttpStatus.notFound;
      await request.response.close();
    });
  });

  tearDown(() async {
    await mockStorageServer.close(force: true);
    if (tmpDir.existsSync()) {
      tmpDir.deleteSync(recursive: true);
    }
  });

  Future<void> runUpdateDartSdk() async {
    final String executable;
    final List<String> args;
    if (platform.isWindows) {
      executable = 'powershell';
      args = <String>['-ExecutionPolicy', 'Bypass', '-NoProfile', '-File', updateScript.path];
    } else if (usePowershellOnPosix) {
      executable = 'pwsh';
      args = <String>['-ExecutionPolicy', 'Bypass', '-NoProfile', '-File', updateScript.path];
    } else {
      executable = updateScript.path;
      args = <String>[];
    }

    final io.ProcessResult result = await io.Process.run(
      executable,
      args,
      environment: <String, String>{
        ...io.Platform.environment,
        _kStorageBaseUrlEnv: 'http://${mockStorageServer.address.host}:${mockStorageServer.port}',
      },
      workingDirectory: testRoot.absolute.path,
    );
    if (result.exitCode != 0) {
      fail(
        'Failed running "$executable ${args.join(' ')}" (exit code = ${result.exitCode})\n'
        'stdout: ${result.stdout}\n'
        'stderr: ${result.stderr}',
      );
    }
  }

  void expectCacheFiles(Map<String, String> expected) {
    for (final MapEntry(:key, :value) in expected.entries) {
      final File file = cacheDir.childFile(localFs.path.joinAll(key.split('/')));
      expect(file.existsSync(), isTrue, reason: 'Expected $key to exist in bin/cache');
      expect(file.readAsStringSync(), value, reason: 'Unexpected content for $key');
    }
  }

  test('extracts Dart SDK and license without conflicts and drops extra top-level files', () async {
    const initialExpected = <String, String>{
      _kDartBinaryPath: 'initial dart binary',
      _kDartVersionPath: '3.0.0',
      _kLicenseFileName: 'initial license content',
    };
    cacheDir.childFile('engine.stamp').writeAsStringSync(_kInitialEngineVersion);
    serverZips[_kInitialEngineVersion] = _createZip(<String, String>{
      ...initialExpected,
      _kEntitlementsFileName: 'initial entitlements',
      _kWithoutEntitlementsFileName: 'initial without entitlements',
    });

    await runUpdateDartSdk();

    final File dartSdkStamp = cacheDir.childFile('engine-dart-sdk.stamp');
    expect(dartSdkStamp.existsSync(), isTrue);
    expect(dartSdkStamp.readAsStringSync().trim(), _kInitialEngineVersion);
    expectCacheFiles(initialExpected);
    expect(cacheDir.childFile(_kEntitlementsFileName).existsSync(), isFalse);
    expect(cacheDir.childFile(_kWithoutEntitlementsFileName).existsSync(), isFalse);

    // Simulate an update with a new engine version and updated archive contents.
    const updatedExpected = <String, String>{
      _kDartBinaryPath: 'updated dart binary',
      _kDartVersionPath: '3.1.0',
      _kLicenseFileName: 'updated license content',
    };
    cacheDir.childFile('engine.stamp').writeAsStringSync(_kUpdatedEngineVersion);
    serverZips[_kUpdatedEngineVersion] = _createZip(<String, String>{
      ...updatedExpected,
      _kEntitlementsFileName: 'updated entitlements',
      _kWithoutEntitlementsFileName: 'updated without entitlements',
    });

    await runUpdateDartSdk();

    expect(dartSdkStamp.existsSync(), isTrue);
    expect(dartSdkStamp.readAsStringSync().trim(), _kUpdatedEngineVersion);
    expectCacheFiles(updatedExpected);
    expect(cacheDir.childFile(_kEntitlementsFileName).existsSync(), isFalse);
    expect(cacheDir.childFile(_kWithoutEntitlementsFileName).existsSync(), isFalse);

    final List<FileSystemEntity> leftoverArtifacts = cacheDir
        .listSync()
        .where(
          (FileSystemEntity entity) =>
              entity.basename.contains('.old') || entity.basename.endsWith('.tmp'),
        )
        .toList();
    expect(leftoverArtifacts, isEmpty);
  });
}

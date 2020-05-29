// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io'; // ignore: dart_io_import

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/net.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:mockito/mockito.dart';
import 'package:package_config/package_config.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

void main() {
  FileSystem fs;
  String filePath;
  Directory tempDir;
  String basePath;

  setUpAll(() {
    fs = MemoryFileSystem.test();
    filePath = fs.path.join('lib', 'foo.txt');
  });

  group('DevFSContent', () {
    test('bytes', () {
      final DevFSByteContent content = DevFSByteContent(<int>[4, 5, 6]);
      expect(content.bytes, orderedEquals(<int>[4, 5, 6]));
      expect(content.isModified, isTrue);
      expect(content.isModified, isFalse);
      content.bytes = <int>[7, 8, 9, 2];
      expect(content.bytes, orderedEquals(<int>[7, 8, 9, 2]));
      expect(content.isModified, isTrue);
      expect(content.isModified, isFalse);
    });
    test('string', () {
      final DevFSStringContent content = DevFSStringContent('some string');
      expect(content.string, 'some string');
      expect(content.bytes, orderedEquals(utf8.encode('some string')));
      expect(content.isModified, isTrue);
      expect(content.isModified, isFalse);
      content.string = 'another string';
      expect(content.string, 'another string');
      expect(content.bytes, orderedEquals(utf8.encode('another string')));
      expect(content.isModified, isTrue);
      expect(content.isModified, isFalse);
      content.bytes = utf8.encode('foo bar');
      expect(content.string, 'foo bar');
      expect(content.bytes, orderedEquals(utf8.encode('foo bar')));
      expect(content.isModified, isTrue);
      expect(content.isModified, isFalse);
    });
    testUsingContext('file', () async {
      final File file = fs.file(filePath);
      final DevFSFileContent content = DevFSFileContent(file);
      expect(content.isModified, isFalse);
      expect(content.isModified, isFalse);

      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(<int>[1, 2, 3], flush: true);

      final DateTime fiveSecondsAgo = file.statSync().modified.subtract(const Duration(seconds: 5));
      expect(content.isModifiedAfter(fiveSecondsAgo), isTrue);
      expect(content.isModifiedAfter(fiveSecondsAgo), isTrue);
      expect(content.isModifiedAfter(null), isTrue);

      file.writeAsBytesSync(<int>[2, 3, 4], flush: true);
      expect(content.fileDependencies, <String>[filePath]);
      expect(content.isModified, isTrue);
      expect(content.isModified, isFalse);
      expect(await content.contentsAsBytes(), <int>[2, 3, 4]);
      updateFileModificationTime(file.path, fiveSecondsAgo, 0);
      expect(content.isModified, isFalse);
      expect(content.isModified, isFalse);

      file.deleteSync();
      expect(content.isModified, isTrue);
      expect(content.isModified, isFalse);
      expect(content.isModified, isFalse);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    }, skip: Platform.isWindows); // TODO(jonahwilliams): fix or disable this functionality.
  });

  group('mocked http client', () {
    HttpOverrides savedHttpOverrides;
    HttpClient httpClient;
    OperatingSystemUtils osUtils;

    setUpAll(() {
      tempDir = _newTempDir(fs);
      basePath = tempDir.path;
      savedHttpOverrides = HttpOverrides.current;
      httpClient = MockOddlyFailingHttpClient();
      HttpOverrides.global = MyHttpOverrides(httpClient);
      osUtils = MockOperatingSystemUtils();
    });

    tearDownAll(() async {
      HttpOverrides.global = savedHttpOverrides;
    });

    final List<dynamic> exceptions = <dynamic>[
      Exception('Connection resert by peer'),
      const OSError('Connection reset by peer'),
    ];

    for (final dynamic exception in exceptions) {
      testUsingContext('retry uploads when failure: $exception', () async {
        final File file = fs.file(fs.path.join(basePath, filePath));
        await file.parent.create(recursive: true);
        file.writeAsBytesSync(<int>[1, 2, 3]);
        // simulate package
        await _createPackage(fs, 'somepkg', 'somefile.txt');

        final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
          requests: <VmServiceExpectation>[
            FakeVmServiceRequest(
              method: '_createDevFS',
              args: <String, Object>{
                'fsName': 'test',
              },
              jsonResponse: <String, Object>{
                'uri': Uri.parse('test').toString(),
              }
            )
          ],
        );
        setHttpAddress(Uri.parse('http://localhost'), fakeVmServiceHost.vmService);

        reset(httpClient);

        final MockHttpClientRequest httpRequest = MockHttpClientRequest();
        when(httpRequest.headers).thenReturn(MockHttpHeaders());
        when(httpClient.putUrl(any)).thenAnswer((Invocation invocation) {
          return Future<HttpClientRequest>.value(httpRequest);
        });
        final MockHttpClientResponse httpClientResponse = MockHttpClientResponse();
        int nRequest = 0;
        const int kFailedAttempts = 5;
        when(httpRequest.close()).thenAnswer((Invocation invocation) {
          if (nRequest++ < kFailedAttempts) {
            throw exception;
          }
          return Future<HttpClientResponse>.value(httpClientResponse);
        });

        final DevFS devFS = DevFS(
          fakeVmServiceHost.vmService,
          'test',
          tempDir,
          osUtils: osUtils,
        );
        await devFS.create();

        final MockResidentCompiler residentCompiler = MockResidentCompiler();
        final UpdateFSReport report = await devFS.update(
          mainUri: Uri.parse('lib/foo.txt'),
          generator: residentCompiler,
          pathToReload: 'lib/foo.txt.dill',
          trackWidgetCreation: false,
          invalidatedFiles: <Uri>[],
          packageConfig: PackageConfig.empty,
        );

        expect(report.syncedBytes, 22);
        expect(report.success, isTrue);
        verify(httpClient.putUrl(any)).called(kFailedAttempts + 1);
        verify(httpRequest.close()).called(kFailedAttempts + 1);
        verify(osUtils.gzipLevel1Stream(any)).called(kFailedAttempts + 1);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        HttpClientFactory: () => () => httpClient,
        ProcessManager: () => FakeProcessManager.any(),
      });
    }
  });

  group('devfs remote', () {
    DevFS devFS;

    setUpAll(() async {
      tempDir = _newTempDir(fs);
      basePath = tempDir.path;
    });

    setUp(() {
      final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
          FakeVmServiceRequest(
            method: '_createDevFS',
            args: <String, Object>{
              'fsName': 'test',
            },
            jsonResponse: <String, Object>{
              'uri': Uri.parse('test').toString(),
            }
          )
        ],
      );
      setHttpAddress(Uri.parse('http://localhost'), fakeVmServiceHost.vmService);
      devFS = DevFS(
        fakeVmServiceHost.vmService,
        'test',
        tempDir,
        osUtils: FakeOperatingSystemUtils(),
        // TODO(jonahwilliams): remove and prevent usage of http writer.
        disableUpload: true,
      );
    });

    tearDownAll(() async {
      _cleanupTempDirs();
    });

    testUsingContext('reports unsuccessful compile when errors are returned', () async {
      await devFS.create();
      final DateTime previousCompile = devFS.lastCompiled;

      final RealMockResidentCompiler residentCompiler = RealMockResidentCompiler();
      when(residentCompiler.recompile(
        any,
        any,
        outputPath: anyNamed('outputPath'),
        packageConfig: anyNamed('packageConfig'),
      )).thenAnswer((Invocation invocation) {
        return Future<CompilerOutput>.value(const CompilerOutput('example', 2, <Uri>[]));
      });

      final UpdateFSReport report = await devFS.update(
        mainUri: Uri.parse('lib/foo.txt'),
        generator: residentCompiler,
        pathToReload: 'lib/foo.txt.dill',
        trackWidgetCreation: false,
        invalidatedFiles: <Uri>[],
        packageConfig: PackageConfig.empty,
      );

      expect(report.success, false);
      expect(devFS.lastCompiled, previousCompile);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('correctly updates last compiled time when compilation does not fail', () async {
      // simulate package
      final File sourceFile = await _createPackage(fs, 'somepkg', 'main.dart');

      await devFS.create();
      final DateTime previousCompile = devFS.lastCompiled;

      final RealMockResidentCompiler residentCompiler = RealMockResidentCompiler();
      when(residentCompiler.recompile(
        any,
        any,
        outputPath: anyNamed('outputPath'),
        packageConfig: anyNamed('packageConfig'),
      )).thenAnswer((Invocation invocation) {
        fs.file('example').createSync();
        return Future<CompilerOutput>.value(CompilerOutput('example', 0, <Uri>[sourceFile.uri]));
      });

      final UpdateFSReport report = await devFS.update(
        mainUri: Uri.parse('lib/main.dart'),
        generator: residentCompiler,
        pathToReload: 'lib/foo.txt.dill',
        trackWidgetCreation: false,
        invalidatedFiles: <Uri>[],
        packageConfig: PackageConfig.empty,
      );

      expect(report.success, true);
      expect(devFS.lastCompiled, isNot(previousCompile));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      HttpClient: () => () => HttpClient(),
      ProcessManager: () => FakeProcessManager.any(),
    });
  });
}

class RealMockResidentCompiler extends Mock implements ResidentCompiler {}

final List<Directory> _tempDirs = <Directory>[];
final Map <String, Uri> _packages = <String, Uri>{};

Directory _newTempDir(FileSystem fs) {
  final Directory tempDir = fs.systemTempDirectory.createTempSync('flutter_devfs${_tempDirs.length}_test.');
  _tempDirs.add(tempDir);
  return tempDir;
}

void _cleanupTempDirs() {
  while (_tempDirs.isNotEmpty) {
    tryToDelete(_tempDirs.removeLast());
  }
}

Future<File> _createPackage(FileSystem fs, String pkgName, String pkgFileName, { bool doubleSlash = false }) async {
  final Directory pkgTempDir = _newTempDir(fs);
  String pkgFilePath = fs.path.join(pkgTempDir.path, pkgName, 'lib', pkgFileName);
  if (doubleSlash) {
    // Force two separators into the path.
    final String doubleSlash = fs.path.separator + fs.path.separator;
    pkgFilePath = pkgTempDir.path + doubleSlash + fs.path.join(pkgName, 'lib', pkgFileName);
  }
  final File pkgFile = fs.file(pkgFilePath);
  await pkgFile.parent.create(recursive: true);
  pkgFile.writeAsBytesSync(<int>[11, 12, 13]);
  _packages[pkgName] = fs.path.toUri(pkgFile.parent.path);
  final StringBuffer sb = StringBuffer();
  _packages.forEach((String pkgName, Uri pkgUri) {
    sb.writeln('$pkgName:$pkgUri');
  });
  return fs.file(fs.path.join(_tempDirs[0].path, '.packages'))
    ..writeAsStringSync(sb.toString());
}

class MyHttpOverrides extends HttpOverrides {
  MyHttpOverrides(this._httpClient);
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return _httpClient;
  }

  final HttpClient _httpClient;
}

class MockOddlyFailingHttpClient extends Mock implements HttpClient {}
class MockHttpClientRequest extends Mock implements HttpClientRequest {}
class MockHttpHeaders extends Mock implements HttpHeaders {}
class MockHttpClientResponse extends Mock implements HttpClientResponse {}
class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {}
class MockVMService extends Mock implements vm_service.VmService {}

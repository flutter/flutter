// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io'; // ignore: dart_io_import

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

void main() {
  FileSystem fs;
  String filePath;
  Directory tempDir;
  String basePath;
  DevFS devFS;

  setUpAll(() {
    fs = MemoryFileSystem();
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

      final DateTime fiveSecondsAgo = DateTime.now().subtract(const Duration(seconds:5));
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
    }, skip: Platform.isWindows); // TODO(jonahwilliams): fix or disable this functionality.
  });

  group('mocked http client', () {
    HttpOverrides savedHttpOverrides;
    HttpClient httpClient;

    setUpAll(() {
      tempDir = _newTempDir(fs);
      basePath = tempDir.path;
      savedHttpOverrides = HttpOverrides.current;
      httpClient = MockOddlyFailingHttpClient();
      HttpOverrides.global = MyHttpOverrides(httpClient);
    });

    tearDownAll(() async {
      HttpOverrides.global = savedHttpOverrides;
    });

    testUsingContext('retry uploads when failure', () async {
      final File file = fs.file(fs.path.join(basePath, filePath));
      await file.parent.create(recursive: true);
      file.writeAsBytesSync(<int>[1, 2, 3]);
      // simulate package
      await _createPackage(fs, 'somepkg', 'somefile.txt');

      final RealMockVMService vmService = RealMockVMService();
      final RealMockVM vm = RealMockVM();
      final Map<String, dynamic> response =  <String, dynamic>{ 'uri': 'file://abc' };
      when(vm.createDevFS(any)).thenAnswer((Invocation invocation) {
        return Future<Map<String, dynamic>>.value(response);
      });
      when(vmService.vm).thenReturn(vm);

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
          throw 'Connection resert by peer';
        }
        return Future<HttpClientResponse>.value(httpClientResponse);
      });

      devFS = DevFS(vmService, 'test', tempDir);
      await devFS.create();

      final MockResidentCompiler residentCompiler = MockResidentCompiler();
      final UpdateFSReport report = await devFS.update(
        mainPath: 'lib/foo.txt',
        generator: residentCompiler,
        pathToReload: 'lib/foo.txt.dill',
        trackWidgetCreation: false,
        invalidatedFiles: <Uri>[],
      );

      expect(report.syncedBytes, 22);
      expect(report.success, isTrue);
      verify(httpClient.putUrl(any)).called(kFailedAttempts + 1);
      verify(httpRequest.close()).called(kFailedAttempts + 1);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
    });
  });

  group('devfs remote', () {
    MockVMService vmService;
    final MockResidentCompiler residentCompiler = MockResidentCompiler();

    setUpAll(() async {
      tempDir = _newTempDir(fs);
      basePath = tempDir.path;
      vmService = MockVMService();
      await vmService.setUp();
    });

    tearDownAll(() async {
      await vmService.tearDown();
      _cleanupTempDirs();
    });

    testUsingContext('create dev file system', () async {
      // simulate workspace
      final File file = fs.file(fs.path.join(basePath, filePath));
      await file.parent.create(recursive: true);
      file.writeAsBytesSync(<int>[1, 2, 3]);

      // simulate package
      await _createPackage(fs, 'somepkg', 'somefile.txt');

      devFS = DevFS(vmService, 'test', tempDir);
      await devFS.create();
      vmService.expectMessages(<String>['create test']);
      expect(devFS.assetPathsToEvict, isEmpty);

      final UpdateFSReport report = await devFS.update(
        mainPath: 'lib/foo.txt',
        generator: residentCompiler,
        pathToReload: 'lib/foo.txt.dill',
        trackWidgetCreation: false,
        invalidatedFiles: <Uri>[],
      );
      vmService.expectMessages(<String>[
        'writeFile test lib/foo.txt.dill',
      ]);
      expect(devFS.assetPathsToEvict, isEmpty);
      expect(report.syncedBytes, 22);
      expect(report.success, true);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
    });

    testUsingContext('delete dev file system', () async {
      expect(vmService.messages, isEmpty, reason: 'prior test timeout');
      await devFS.destroy();
      vmService.expectMessages(<String>['destroy test']);
      expect(devFS.assetPathsToEvict, isEmpty);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
    });

    testUsingContext('cleanup preexisting file system', () async {
      // simulate workspace
      final File file = fs.file(fs.path.join(basePath, filePath));
      await file.parent.create(recursive: true);
      file.writeAsBytesSync(<int>[1, 2, 3]);

      // simulate package
      await _createPackage(fs, 'somepkg', 'somefile.txt');

      devFS = DevFS(vmService, 'test', tempDir);
      await devFS.create();
      vmService.expectMessages(<String>['create test']);
      expect(devFS.assetPathsToEvict, isEmpty);

      // Try to create again.
      await devFS.create();
      vmService.expectMessages(<String>['create test', 'destroy test', 'create test']);
      expect(devFS.assetPathsToEvict, isEmpty);

      // Really destroy.
      await devFS.destroy();
      vmService.expectMessages(<String>['destroy test']);
      expect(devFS.assetPathsToEvict, isEmpty);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
    });

    testUsingContext('reports unsuccessful compile when errors are returned', () async {
      devFS = DevFS(vmService, 'test', tempDir);
      await devFS.create();

      final RealMockResidentCompiler residentCompiler = RealMockResidentCompiler();
      when(residentCompiler.recompile(
        any,
        any,
        outputPath: anyNamed('outputPath'),
      )).thenAnswer((Invocation invocation) {
        return Future<CompilerOutput>.value(const CompilerOutput('example', 2, <Uri>[]));
      });

      final UpdateFSReport report = await devFS.update(
        mainPath: 'lib/foo.txt',
        generator: residentCompiler,
        pathToReload: 'lib/foo.txt.dill',
        trackWidgetCreation: false,
        invalidatedFiles: <Uri>[],
      );

      expect(report.success, false);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
    });
  });
}

class MockVMService extends BasicMock implements VMService {
  MockVMService() {
    _vm = MockVM(this);
  }

  Uri _httpAddress;
  HttpServer _server;
  MockVM _vm;

  @override
  Uri get httpAddress => _httpAddress;

  @override
  VM get vm => _vm;

  Future<void> setUp() async {
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv6, 0);
      _httpAddress = Uri.parse('http://[::1]:${_server.port}');
    } on SocketException {
      // Fall back to IPv4 if the host doesn't support binding to IPv6 localhost
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _httpAddress = Uri.parse('http://127.0.0.1:${_server.port}');
    }
    _server.listen((HttpRequest request) {
      final String fsName = request.headers.value('dev_fs_name');
      final String devicePath = utf8.decode(base64.decode(request.headers.value('dev_fs_uri_b64')));
      messages.add('writeFile $fsName $devicePath');
      request.drain<List<int>>().then<void>((List<int> value) {
        request.response
          ..write('Got it')
          ..close();
      });
    });
  }

  Future<void> tearDown() async {
    await _server?.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockVM implements VM {
  MockVM(this._service);

  final MockVMService _service;
  final Uri _baseUri = Uri.parse('file:///tmp/devfs/test');
  bool _devFSExists = false;

  static const int kFileSystemAlreadyExists = 1001;

  @override
  Future<Map<String, dynamic>> createDevFS(String fsName) async {
    _service.messages.add('create $fsName');
    if (_devFSExists) {
      throw rpc.RpcException(kFileSystemAlreadyExists, 'File system already exists');
    }
    _devFSExists = true;
    return <String, dynamic>{'uri': '$_baseUri'};
  }

  @override
  Future<Map<String, dynamic>> deleteDevFS(String fsName) async {
    _service.messages.add('destroy $fsName');
    _devFSExists = false;
    return <String, dynamic>{'type': 'Success'};
  }

  @override
  Future<Map<String, dynamic>> invokeRpcRaw(
    String method, {
    Map<String, dynamic> params = const <String, dynamic>{},
    Duration timeout,
    bool timeoutFatal = true,
    bool truncateLogs = true,
  }) async {
    _service.messages.add('$method $params');
    return <String, dynamic>{'success': true};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

Future<void> _createPackage(FileSystem fs, String pkgName, String pkgFileName, { bool doubleSlash = false }) async {
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
  fs.file(fs.path.join(_tempDirs[0].path, '.packages')).writeAsStringSync(sb.toString());
}

class RealMockVM extends Mock implements VM {

}

class RealMockVMService extends Mock implements VMService {

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

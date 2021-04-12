// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:mockito/mockito.dart';
import 'package:package_config/package_config.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fake_http_client.dart';
import '../src/fake_vm_services.dart';

final FakeVmServiceRequest createDevFSRequest = FakeVmServiceRequest(
  method: '_createDevFS',
  args: <String, Object>{
    'fsName': 'test',
  },
  jsonResponse: <String, Object>{
    'uri': Uri.parse('test').toString(),
  }
);

const FakeVmServiceRequest failingCreateDevFSRequest = FakeVmServiceRequest(
  method: '_createDevFS',
  args: <String, Object>{
    'fsName': 'test',
  },
  errorCode: RPCErrorCodes.kServiceDisappeared,
);

const FakeVmServiceRequest failingDeleteDevFSRequest = FakeVmServiceRequest(
  method: '_deleteDevFS',
  args: <String, dynamic>{'fsName': 'test'},
  errorCode: RPCErrorCodes.kServiceDisappeared,
);

void main() {
  testWithoutContext('DevFSByteContent', () {
    final DevFSByteContent content = DevFSByteContent(<int>[4, 5, 6]);

    expect(content.bytes, orderedEquals(<int>[4, 5, 6]));
    expect(content.isModified, isTrue);
    expect(content.isModified, isFalse);
    content.bytes = <int>[7, 8, 9, 2];
    expect(content.bytes, orderedEquals(<int>[7, 8, 9, 2]));
    expect(content.isModified, isTrue);
    expect(content.isModified, isFalse);
  });

  testWithoutContext('DevFSStringContent', () {
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

  testWithoutContext('DevFSFileContent', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('foo.txt');
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

    expect(content.isModified, isTrue);
    expect(content.isModified, isFalse);
    expect(await content.contentsAsBytes(), <int>[2, 3, 4]);

    expect(content.isModified, isFalse);
    expect(content.isModified, isFalse);

    file.deleteSync();
    expect(content.isModified, isTrue);
    expect(content.isModified, isFalse);
    expect(content.isModified, isFalse);
  });

  testWithoutContext('DevFS create throws a DevFSException when vmservice disconnects unexpectedly', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final OperatingSystemUtils osUtils = MockOperatingSystemUtils();
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[failingCreateDevFSRequest],
      httpAddress: Uri.parse('http://localhost'),
    );

    final DevFS devFS = DevFS(
      fakeVmServiceHost.vmService,
      'test',
      fileSystem.currentDirectory,
      osUtils: osUtils,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      httpClient: FakeHttpClient.any(),
    );
    expect(() async => devFS.create(), throwsA(isA<DevFSException>()));
  });

  testWithoutContext('DevFS destroy is resilient to vmservice disconnection', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final OperatingSystemUtils osUtils = MockOperatingSystemUtils();
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        createDevFSRequest,
        failingDeleteDevFSRequest,
      ],
      httpAddress: Uri.parse('http://localhost'),
    );

    final DevFS devFS = DevFS(
      fakeVmServiceHost.vmService,
      'test',
      fileSystem.currentDirectory,
      osUtils: osUtils,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      httpClient: FakeHttpClient.any(),
    );

    expect(await devFS.create(), isNotNull);
    await devFS.destroy();  // Testing that this does not throw.
  });

  testWithoutContext('DevFS retries uploads when connection reset by peer', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final OperatingSystemUtils osUtils = MockOperatingSystemUtils();
    final MockResidentCompiler residentCompiler = MockResidentCompiler();
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[createDevFSRequest],
      httpAddress: Uri.parse('http://localhost'),
    );

    when(residentCompiler.recompile(
      any,
      any,
      outputPath: anyNamed('outputPath'),
      packageConfig: anyNamed('packageConfig'),
    )).thenAnswer((Invocation invocation) async {
      fileSystem.file('lib/foo.dill')
        ..createSync(recursive: true)
        ..writeAsBytesSync(<int>[1, 2, 3, 4, 5]);
      return const CompilerOutput('lib/foo.dill', 0, <Uri>[]);
    });

    final DevFS devFS = DevFS(
      fakeVmServiceHost.vmService,
      'test',
      fileSystem.currentDirectory,
      osUtils: osUtils,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      httpClient: FakeHttpClient.list(<FakeRequest>[
        FakeRequest(Uri.parse('http://localhost'), method: HttpMethod.put, responseError: const OSError('Connection Reset by peer')),
        FakeRequest(Uri.parse('http://localhost'), method: HttpMethod.put, responseError: const OSError('Connection Reset by peer')),
        FakeRequest(Uri.parse('http://localhost'), method: HttpMethod.put, responseError: const OSError('Connection Reset by peer')),
        FakeRequest(Uri.parse('http://localhost'), method: HttpMethod.put, responseError: const OSError('Connection Reset by peer')),
        FakeRequest(Uri.parse('http://localhost'), method: HttpMethod.put, responseError: const OSError('Connection Reset by peer')),
        FakeRequest(Uri.parse('http://localhost'), method: HttpMethod.put)
      ]),
      uploadRetryThrottle: Duration.zero,
    );
    await devFS.create();

    final UpdateFSReport report = await devFS.update(
      mainUri: Uri.parse('lib/foo.txt'),
      dillOutputPath: 'lib/foo.dill',
      generator: residentCompiler,
      pathToReload: 'lib/foo.txt.dill',
      trackWidgetCreation: false,
      invalidatedFiles: <Uri>[],
      packageConfig: PackageConfig.empty,
    );

    expect(report.syncedBytes, 5);
    expect(report.success, isTrue);
    verify(osUtils.gzipLevel1Stream(any)).called(6);
  });

  testWithoutContext('DevFS reports unsuccessful compile when errors are returned', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[createDevFSRequest],
      httpAddress: Uri.parse('http://localhost'),
    );

    final DevFS devFS = DevFS(
      fakeVmServiceHost.vmService,
      'test',
      fileSystem.currentDirectory,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
      httpClient: FakeHttpClient.any(),
    );

    await devFS.create();
    final DateTime previousCompile = devFS.lastCompiled;

    final MockResidentCompiler residentCompiler = MockResidentCompiler();
    when(residentCompiler.recompile(
      any,
      any,
      outputPath: anyNamed('outputPath'),
      packageConfig: anyNamed('packageConfig'),
    )).thenAnswer((Invocation invocation) async {
      return const CompilerOutput('lib/foo.dill', 2, <Uri>[]);
    });

    final UpdateFSReport report = await devFS.update(
      mainUri: Uri.parse('lib/foo.txt'),
      generator: residentCompiler,
      dillOutputPath: 'lib/foo.dill',
      pathToReload: 'lib/foo.txt.dill',
      trackWidgetCreation: false,
      invalidatedFiles: <Uri>[],
      packageConfig: PackageConfig.empty,
    );

    expect(report.success, false);
    expect(devFS.lastCompiled, previousCompile);
  });

  testWithoutContext('DevFS correctly updates last compiled time when compilation does not fail', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[createDevFSRequest],
      httpAddress: Uri.parse('http://localhost'),
    );

    final DevFS devFS = DevFS(
      fakeVmServiceHost.vmService,
      'test',
      fileSystem.currentDirectory,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
      httpClient: FakeHttpClient.any(),
    );

    await devFS.create();
    final DateTime previousCompile = devFS.lastCompiled;

    final MockResidentCompiler residentCompiler = MockResidentCompiler();
    when(residentCompiler.recompile(
      any,
      any,
      outputPath: anyNamed('outputPath'),
      packageConfig: anyNamed('packageConfig'),
    )).thenAnswer((Invocation invocation) async {
      fileSystem.file('example').createSync();
      return const CompilerOutput('lib/foo.txt.dill', 0, <Uri>[]);
    });

    final UpdateFSReport report = await devFS.update(
      mainUri: Uri.parse('lib/main.dart'),
      generator: residentCompiler,
      dillOutputPath: 'lib/foo.dill',
      pathToReload: 'lib/foo.txt.dill',
      trackWidgetCreation: false,
      invalidatedFiles: <Uri>[],
      packageConfig: PackageConfig.empty,
    );

    expect(report.success, true);
    expect(devFS.lastCompiled, isNot(previousCompile));
  });

  testWithoutContext('DevFS can reset compilation time', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[createDevFSRequest],
    );
    final LocalDevFSWriter localDevFSWriter = LocalDevFSWriter(fileSystem: fileSystem);
    fileSystem.directory('test').createSync();

    final DevFS devFS = DevFS(
      fakeVmServiceHost.vmService,
      'test',
      fileSystem.currentDirectory,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
      httpClient: HttpClient(),
    );

    await devFS.create();
    final DateTime previousCompile = devFS.lastCompiled;

    final MockResidentCompiler residentCompiler = MockResidentCompiler();
    when(residentCompiler.recompile(
      any,
      any,
      outputPath: anyNamed('outputPath'),
      packageConfig: anyNamed('packageConfig'),
    )).thenAnswer((Invocation invocation) async {
      fileSystem.file('lib/foo.txt.dill').createSync(recursive: true);
      return const CompilerOutput('lib/foo.txt.dill', 0, <Uri>[]);
    });

    final UpdateFSReport report = await devFS.update(
      mainUri: Uri.parse('lib/main.dart'),
      generator: residentCompiler,
      dillOutputPath: 'lib/foo.dill',
      pathToReload: 'lib/foo.txt.dill',
      trackWidgetCreation: false,
      invalidatedFiles: <Uri>[],
      packageConfig: PackageConfig.empty,
      devFSWriter: localDevFSWriter,
    );

    expect(report.success, true);
    expect(devFS.lastCompiled, isNot(previousCompile));

    devFS.resetLastCompiled();
    expect(devFS.lastCompiled, previousCompile);

    // Does not reset to report compile time.
    devFS.resetLastCompiled();
    expect(devFS.lastCompiled, previousCompile);
  });

  testWithoutContext('DevFS uses provided DevFSWriter instead of default HTTP writer', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final FakeDevFSWriter writer = FakeDevFSWriter();
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[createDevFSRequest],
    );

    final DevFS devFS = DevFS(
      fakeVmServiceHost.vmService,
      'test',
      fileSystem.currentDirectory,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
      httpClient: FakeHttpClient.any(),
    );

    await devFS.create();

    final MockResidentCompiler residentCompiler = MockResidentCompiler();
    when(residentCompiler.recompile(
      any,
      any,
      outputPath: anyNamed('outputPath'),
      packageConfig: anyNamed('packageConfig'),
    )).thenAnswer((Invocation invocation) async {
      fileSystem.file('example').createSync();
      return const CompilerOutput('lib/foo.txt.dill', 0, <Uri>[]);
    });

    expect(writer.written, false);

    final UpdateFSReport report = await devFS.update(
      mainUri: Uri.parse('lib/main.dart'),
      generator: residentCompiler,
      dillOutputPath: 'lib/foo.dill',
      pathToReload: 'lib/foo.txt.dill',
      trackWidgetCreation: false,
      invalidatedFiles: <Uri>[],
      packageConfig: PackageConfig.empty,
      devFSWriter: writer,
    );

    expect(report.success, true);
    expect(writer.written, true);
  });

  testWithoutContext('Local DevFSWriter can copy and write files', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('foo_bar')
      ..writeAsStringSync('goodbye');
    final LocalDevFSWriter writer = LocalDevFSWriter(fileSystem: fileSystem);

    await writer.write(<Uri, DevFSContent>{
      Uri.parse('hello'): DevFSStringContent('hello'),
      Uri.parse('goodbye'): DevFSFileContent(file),
    }, Uri.parse('/foo/bar/devfs/'));

    expect(fileSystem.file('/foo/bar/devfs/hello'), exists);
    expect(fileSystem.file('/foo/bar/devfs/hello').readAsStringSync(), 'hello');
    expect(fileSystem.file('/foo/bar/devfs/goodbye'), exists);
    expect(fileSystem.file('/foo/bar/devfs/goodbye').readAsStringSync(), 'goodbye');
  });

  testWithoutContext('Local DevFSWriter turns FileSystemException into DevFSException', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final LocalDevFSWriter writer = LocalDevFSWriter(fileSystem: fileSystem);
    final File file = MockFile();
    when(file.copySync(any)).thenThrow(const FileSystemException('foo'));

    await expectLater(() async => writer.write(<Uri, DevFSContent>{
      Uri.parse('goodbye'): DevFSFileContent(file),
    }, Uri.parse('/foo/bar/devfs/')), throwsA(isA<DevFSException>()));
  });
}

class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {}
class MockResidentCompiler extends Mock implements ResidentCompiler {}
class MockFile extends Mock implements File {}
class FakeDevFSWriter implements DevFSWriter {
  bool written = false;

  @override
  Future<void> write(Map<Uri, DevFSContent> entries, Uri baseUri, DevFSWriter parent) async {
    written = true;
  }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:mockito/mockito.dart';
import 'package:package_config/package_config.dart';
import 'package:fake_async/fake_async.dart';

import '../src/common.dart';
import '../src/context.dart';

final FakeVmServiceRequest createDevFSRequest = FakeVmServiceRequest(
  method: '_createDevFS',
  args: <String, Object>{
    'fsName': 'test',
  },
  jsonResponse: <String, Object>{
    'uri': Uri.parse('test').toString(),
  }
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

  testWithoutContext('DevFS retries uploads when connection resert by peer', () async {
    final HttpClient httpClient = MockHttpClient();
    final FileSystem fileSystem = MemoryFileSystem.test();
    final OperatingSystemUtils osUtils = MockOperatingSystemUtils();
    final MockResidentCompiler residentCompiler = MockResidentCompiler();
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[createDevFSRequest],
    );
    setHttpAddress(Uri.parse('http://localhost'), fakeVmServiceHost.vmService);

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
        throw const OSError('Connection Reset by peer');
      }
      return Future<HttpClientResponse>.value(httpClientResponse);
    });

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
      httpClient: httpClient,
    );
    await devFS.create();

    await FakeAsync().run((FakeAsync time) async {
      final UpdateFSReport report = await devFS.update(
        mainUri: Uri.parse('lib/foo.txt'),
        dillOutputPath: 'lib/foo.dill',
        generator: residentCompiler,
        pathToReload: 'lib/foo.txt.dill',
        trackWidgetCreation: false,
        invalidatedFiles: <Uri>[],
        packageConfig: PackageConfig.empty,
      );
      time.elapse(const Duration(seconds: 2));

      expect(report.syncedBytes, 5);
      expect(report.success, isTrue);
      verify(httpClient.putUrl(any)).called(kFailedAttempts + 1);
      verify(httpRequest.close()).called(kFailedAttempts + 1);
      verify(osUtils.gzipLevel1Stream(any)).called(kFailedAttempts + 1);
    });
  }, skip: true); // TODO(jonahwilliams): clean up with https://github.com/flutter/flutter/issues/60675

  testWithoutContext('DevFS reports unsuccessful compile when errors are returned', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[createDevFSRequest],
    );
    setHttpAddress(Uri.parse('http://localhost'), fakeVmServiceHost.vmService);
    final DevFS devFS = DevFS(
      fakeVmServiceHost.vmService,
      'test',
      fileSystem.currentDirectory,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
      httpClient: MockHttpClient(),
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
    );
    final HttpClient httpClient = MockHttpClient();
    final MockHttpClientRequest httpRequest = MockHttpClientRequest();
    when(httpRequest.headers).thenReturn(MockHttpHeaders());
    when(httpClient.putUrl(any)).thenAnswer((Invocation invocation) {
      return Future<HttpClientRequest>.value(httpRequest);
    });
    final MockHttpClientResponse httpClientResponse = MockHttpClientResponse();
    when(httpRequest.close()).thenAnswer((Invocation invocation) async {
      return httpClientResponse;
    });

    final DevFS devFS = DevFS(
      fakeVmServiceHost.vmService,
      'test',
      fileSystem.currentDirectory,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
      httpClient: httpClient,
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

  testWithoutContext('test handles request closure hangs', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[createDevFSRequest],
    );
    final HttpClient httpClient = MockHttpClient();
    final MockHttpClientRequest httpRequest = MockHttpClientRequest();
    when(httpRequest.headers).thenReturn(MockHttpHeaders());
    when(httpClient.putUrl(any)).thenAnswer((Invocation invocation) {
      return Future<HttpClientRequest>.value(httpRequest);
    });
    int closeCount = 0;
    final Completer<MockHttpClientResponse> hanger = Completer<MockHttpClientResponse>();
    final Completer<MockHttpClientResponse> succeeder = Completer<MockHttpClientResponse>();
    final List<Completer<MockHttpClientResponse>> closeCompleters =
      <Completer<MockHttpClientResponse>>[hanger, succeeder];
    succeeder.complete(MockHttpClientResponse());

    when(httpRequest.close()).thenAnswer((Invocation invocation) {
      final Completer<MockHttpClientResponse> completer = closeCompleters[closeCount];
      closeCount += 1;
      return completer.future;
    });
    when(httpRequest.abort()).thenAnswer((_) {
      hanger.completeError(const HttpException('aborted'));
    });
    when(httpRequest.done).thenAnswer((_) {
      if (closeCount == 1) {
        return hanger.future;
      } else if (closeCount == 2) {
        return succeeder.future;
      } else {
        // This branch shouldn't happen.
        fail('This branch should not happen');
      }
    });

    final BufferLogger logger = BufferLogger.test();
    final DevFS devFS = DevFS(
      fakeVmServiceHost.vmService,
      'test',
      fileSystem.currentDirectory,
      fileSystem: fileSystem,
      logger: logger,
      osUtils: FakeOperatingSystemUtils(),
      httpClient: httpClient,
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
    expect(closeCount, 2);
    expect(logger.errorText, '');
  });
}

class MockHttpClientRequest extends Mock implements HttpClientRequest {}
class MockHttpHeaders extends Mock implements HttpHeaders {}
class MockHttpClientResponse extends Mock implements HttpClientResponse {}
class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {}
class MockResidentCompiler extends Mock implements ResidentCompiler {}

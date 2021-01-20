// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:file/src/interface/file.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/mocks.dart';

final Platform testPlatform = FakePlatform(environment: const <String, String>{});

void main() {
  testWithoutContext('ArtifactUpdater can download a zip archive', () async {
    final MockOperatingSystemUtils operatingSystemUtils = MockOperatingSystemUtils();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final ArtifactUpdater artifactUpdater = ArtifactUpdater(
      fileSystem: fileSystem,
      logger: logger,
      operatingSystemUtils: operatingSystemUtils,
      platform: testPlatform,
      httpClient: MockHttpClient(),
      tempStorage: fileSystem.currentDirectory.childDirectory('temp')
        ..createSync(),
    );

    await artifactUpdater.downloadZipArchive(
      'test message',
      Uri.parse('http:///test.zip'),
      fileSystem.currentDirectory.childDirectory('out'),
    );
    expect(logger.statusText, contains('test message'));
    expect(fileSystem.file('out/test'), exists);
  });

  testWithoutContext('ArtifactUpdater will not validate the md5 hash if the '
    'x-goog-hash header is present but missing an md5 entry', () async {
    final MockOperatingSystemUtils operatingSystemUtils = MockOperatingSystemUtils();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final MockHttpClient client = MockHttpClient();
    client.testRequest.testResponse.headers = FakeHttpHeaders(<String, List<String>>{
      'x-goog-hash': <String>[],
    });

    final ArtifactUpdater artifactUpdater = ArtifactUpdater(
      fileSystem: fileSystem,
      logger: logger,
      operatingSystemUtils: operatingSystemUtils,
      platform: testPlatform,
      httpClient: client,
      tempStorage: fileSystem.currentDirectory.childDirectory('temp')
        ..createSync(),
    );

    await artifactUpdater.downloadZipArchive(
      'test message',
      Uri.parse('http:///test.zip'),
      fileSystem.currentDirectory.childDirectory('out'),
    );
    expect(logger.statusText, contains('test message'));
    expect(fileSystem.file('out/test'), exists);
  });

  testWithoutContext('ArtifactUpdater will validate the md5 hash if the '
    'x-goog-hash header is present', () async {
    final MockOperatingSystemUtils operatingSystemUtils = MockOperatingSystemUtils();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final MockHttpClient client = MockHttpClient();
    client.testRequest.testResponse.headers = FakeHttpHeaders(<String, List<String>>{
      'x-goog-hash': <String>[
        'foo-bar-baz',
        'md5=k7iFrf4NoInN9jSQT9WfcQ=='
      ],
    });

    final ArtifactUpdater artifactUpdater = ArtifactUpdater(
      fileSystem: fileSystem,
      logger: logger,
      operatingSystemUtils: operatingSystemUtils,
      platform: testPlatform,
      httpClient: client,
      tempStorage: fileSystem.currentDirectory.childDirectory('temp')
        ..createSync(),
    );

    await artifactUpdater.downloadZipArchive(
      'test message',
      Uri.parse('http:///test.zip'),
      fileSystem.currentDirectory.childDirectory('out'),
    );
    expect(logger.statusText, contains('test message'));
    expect(fileSystem.file('out/test'), exists);
  });

  testWithoutContext('ArtifactUpdater will validate the md5 hash if the '
    'x-goog-hash header is present and throw if it does not match', () async {
    final MockOperatingSystemUtils operatingSystemUtils = MockOperatingSystemUtils();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final MockHttpClient client = MockHttpClient();
    client.testRequest.testResponse.headers = FakeHttpHeaders(<String, List<String>>{
      'x-goog-hash': <String>[
        'foo-bar-baz',
        'md5=k7iFrf4SQT9WfcQ=='
      ],
    });

    final ArtifactUpdater artifactUpdater = ArtifactUpdater(
      fileSystem: fileSystem,
      logger: logger,
      operatingSystemUtils: operatingSystemUtils,
      platform: testPlatform,
      httpClient: client,
      tempStorage: fileSystem.currentDirectory.childDirectory('temp')
        ..createSync(),
    );

    await expectLater(() async => await artifactUpdater.downloadZipArchive(
      'test message',
      Uri.parse('http:///test.zip'),
      fileSystem.currentDirectory.childDirectory('out'),
    ), throwsToolExit(message: 'k7iFrf4SQT9WfcQ==')); // validate that the hash mismatch message is included.
  });

  testWithoutContext('ArtifactUpdater will restart the status ticker if it needs to retry the download', () async {
    final MockOperatingSystemUtils operatingSystemUtils = MockOperatingSystemUtils();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final Logger logger = StdoutLogger(
      terminal: Terminal.test(supportsColor: true),
      stdio: MockStdio(),
      outputPreferences: OutputPreferences.test(),
    );
    final ArtifactUpdater artifactUpdater = ArtifactUpdater(
      fileSystem: fileSystem,
      logger: logger,
      operatingSystemUtils: operatingSystemUtils,
      platform: testPlatform,
      httpClient: MockHttpClient()..exceptionOnFirstRun = true,
      tempStorage: fileSystem.currentDirectory.childDirectory('temp')
        ..createSync(),
    );

    await artifactUpdater.downloadZipArchive(
      'test message',
      Uri.parse('http:///test.zip'),
      fileSystem.currentDirectory.childDirectory('out'),
    );

    expect(fileSystem.file('out/test'), exists);
  });

  testWithoutContext('ArtifactUpdater will re-attempt on a non-200 response', () async {
    final MockOperatingSystemUtils operatingSystemUtils = MockOperatingSystemUtils();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final MockHttpClient client = MockHttpClient();
    client.testRequest.testResponse.statusCode = HttpStatus.preconditionFailed;
    final ArtifactUpdater artifactUpdater = ArtifactUpdater(
      fileSystem: fileSystem,
      logger: logger,
      operatingSystemUtils: operatingSystemUtils,
      platform: testPlatform,
      httpClient: client,
      tempStorage: fileSystem.currentDirectory.childDirectory('temp')
        ..createSync(),
    );

    await expectLater(() async => await artifactUpdater.downloadZipArchive(
      'test message',
      Uri.parse('http:///test.zip'),
      fileSystem.currentDirectory.childDirectory('out'),
    ), throwsToolExit());

    expect(client.attempts, 2);
    expect(logger.statusText, contains('test message'));
    expect(fileSystem.file('out/test'), isNot(exists));
  });

  testWithoutContext('ArtifactUpdater will tool exit on an ArgumentError from http client with base url override', () async {
    final MockOperatingSystemUtils operatingSystemUtils = MockOperatingSystemUtils();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final MockHttpClient client = MockHttpClient();
    client.argumentError = true;
    final ArtifactUpdater artifactUpdater = ArtifactUpdater(
      fileSystem: fileSystem,
      logger: logger,
      operatingSystemUtils: operatingSystemUtils,
      platform: FakePlatform(
        environment: <String, String>{
          'FLUTTER_STORAGE_BASE_URL': 'foo-bar'
        },
      ),
      httpClient: client,
      tempStorage: fileSystem.currentDirectory.childDirectory('temp')
        ..createSync(),
    );

    await expectLater(() async => await artifactUpdater.downloadZipArchive(
      'test message',
      Uri.parse('http:///foo-bar/test.zip'),
      fileSystem.currentDirectory.childDirectory('out'),
    ), throwsToolExit());

    expect(client.attempts, 1);
    expect(logger.statusText, contains('test message'));
    expect(fileSystem.file('out/test'), isNot(exists));
  });

  testWithoutContext('ArtifactUpdater will rethrow on an ArgumentError from http client without base url override', () async {
    final MockOperatingSystemUtils operatingSystemUtils = MockOperatingSystemUtils();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final MockHttpClient client = MockHttpClient();
    client.argumentError = true;
    final ArtifactUpdater artifactUpdater = ArtifactUpdater(
      fileSystem: fileSystem,
      logger: logger,
      operatingSystemUtils: operatingSystemUtils,
      platform: testPlatform,
      httpClient: client,
      tempStorage: fileSystem.currentDirectory.childDirectory('temp')
        ..createSync(),
    );

    await expectLater(() async => await artifactUpdater.downloadZipArchive(
      'test message',
      Uri.parse('http:///test.zip'),
      fileSystem.currentDirectory.childDirectory('out'),
    ), throwsA(isA<ArgumentError>()));

    expect(client.attempts, 1);
    expect(logger.statusText, contains('test message'));
    expect(fileSystem.file('out/test'), isNot(exists));
  });

  testWithoutContext('ArtifactUpdater will re-download a file if unzipping fails', () async {
    final MockOperatingSystemUtils operatingSystemUtils = MockOperatingSystemUtils();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final ArtifactUpdater artifactUpdater = ArtifactUpdater(
      fileSystem: fileSystem,
      logger: logger,
      operatingSystemUtils: operatingSystemUtils,
      platform: testPlatform,
      httpClient: MockHttpClient(),
      tempStorage: fileSystem.currentDirectory.childDirectory('temp')
        ..createSync(),
    );
    operatingSystemUtils.failures = 1;

    await artifactUpdater.downloadZipArchive(
      'test message',
      Uri.parse('http:///test.zip'),
      fileSystem.currentDirectory.childDirectory('out'),
    );
    expect(logger.statusText, contains('test message'));
    expect(fileSystem.file('out/test'), exists);
  });

  testWithoutContext('ArtifactUpdater will de-download a file if unzipping fails on windows', () async {
    final MockOperatingSystemUtils operatingSystemUtils = MockOperatingSystemUtils(windows: true);
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final ArtifactUpdater artifactUpdater = ArtifactUpdater(
      fileSystem: fileSystem,
      logger: logger,
      operatingSystemUtils: operatingSystemUtils,
      platform: testPlatform,
      httpClient: MockHttpClient(),
      tempStorage: fileSystem.currentDirectory.childDirectory('temp')
        ..createSync(),
    );
    operatingSystemUtils.failures = 1;

    await artifactUpdater.downloadZipArchive(
      'test message',
      Uri.parse('http:///test.zip'),
      fileSystem.currentDirectory.childDirectory('out'),
    );
    expect(logger.statusText, contains('test message'));
    expect(fileSystem.file('out/test'), exists);
  });

  testWithoutContext('ArtifactUpdater will bail with a tool exit if unzipping fails more than twice', () async {
    final MockOperatingSystemUtils operatingSystemUtils = MockOperatingSystemUtils();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final ArtifactUpdater artifactUpdater = ArtifactUpdater(
      fileSystem: fileSystem,
      logger: logger,
      operatingSystemUtils: operatingSystemUtils,
      platform: testPlatform,
      httpClient: MockHttpClient(),
      tempStorage: fileSystem.currentDirectory.childDirectory('temp')
        ..createSync(),
    );
    operatingSystemUtils.failures = 2;

    expect(artifactUpdater.downloadZipArchive(
      'test message',
      Uri.parse('http:///test.zip'),
      fileSystem.currentDirectory.childDirectory('out'),
    ), throwsA(isA<ToolExit>()));
    expect(fileSystem.file('te,[/test'), isNot(exists));
    expect(fileSystem.file('out/test'), isNot(exists));
  });

  testWithoutContext('ArtifactUpdater will bail if unzipping fails more than twice on Windows', () async {
    final MockOperatingSystemUtils operatingSystemUtils = MockOperatingSystemUtils(windows: true);
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final ArtifactUpdater artifactUpdater = ArtifactUpdater(
      fileSystem: fileSystem,
      logger: logger,
      operatingSystemUtils: operatingSystemUtils,
      platform: testPlatform,
      httpClient: MockHttpClient(),
      tempStorage: fileSystem.currentDirectory.childDirectory('temp')
        ..createSync(),
    );
    operatingSystemUtils.failures = 2;

    expect(artifactUpdater.downloadZipArchive(
      'test message',
      Uri.parse('http:///test.zip'),
      fileSystem.currentDirectory.childDirectory('out'),
    ), throwsA(isA<ToolExit>()));
    expect(fileSystem.file('te,[/test'), isNot(exists));
    expect(fileSystem.file('out/test'), isNot(exists));
  });

  testWithoutContext('ArtifactUpdater can download a tar archive', () async {
    final MockOperatingSystemUtils operatingSystemUtils = MockOperatingSystemUtils();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final ArtifactUpdater artifactUpdater = ArtifactUpdater(
      fileSystem: fileSystem,
      logger: logger,
      operatingSystemUtils: operatingSystemUtils,
      platform: testPlatform,
      httpClient: MockHttpClient(),
      tempStorage: fileSystem.currentDirectory.childDirectory('temp')
        ..createSync(),
    );

    await artifactUpdater.downloadZippedTarball(
      'test message',
      Uri.parse('http:///test.zip'),
      fileSystem.currentDirectory.childDirectory('out'),
    );
    expect(fileSystem.file('out/test'), exists);
  });

  testWithoutContext('ArtifactUpdater will delete downloaded files if they exist.', () async {
    final MockOperatingSystemUtils operatingSystemUtils = MockOperatingSystemUtils();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final ArtifactUpdater artifactUpdater = ArtifactUpdater(
      fileSystem: fileSystem,
      logger: logger,
      operatingSystemUtils: operatingSystemUtils,
      platform: testPlatform,
      httpClient: MockHttpClient(),
      tempStorage: fileSystem.currentDirectory.childDirectory('temp')
        ..createSync(),
    );

    artifactUpdater.downloadedFiles.addAll(<File>[
      fileSystem.file('a/b/c/d')..createSync(recursive: true),
      fileSystem.file('d/e/f'),
    ]);

    artifactUpdater.removeDownloadedFiles();

    expect(fileSystem.file('a/b/c/d'), isNot(exists));
    expect(logger.errorText, isEmpty);
  });
}

class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {
  MockOperatingSystemUtils({this.windows = false});

  int failures = 0;
  final bool windows;

  @override
  void unzip(File file, Directory targetDirectory) {
    if (failures > 0) {
      failures -= 1;
      throw Exception();
    }
    targetDirectory.childFile(file.fileSystem.path.basenameWithoutExtension(file.path))
      .createSync();
  }

  @override
  void unpack(File gzippedTarFile, Directory targetDirectory) {
    if (failures > 0) {
      failures -= 1;
      throw Exception();
    }
    targetDirectory.childFile(gzippedTarFile.fileSystem.path.basenameWithoutExtension(gzippedTarFile.path))
      .createSync();
  }
}

class MockHttpClient extends Mock implements HttpClient {
  int attempts = 0;
  bool argumentError = false;
  bool exceptionOnFirstRun = false;
  final MockHttpClientRequest testRequest = MockHttpClientRequest();

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    if (exceptionOnFirstRun && attempts == 0) {
      attempts += 1;
      throw Exception();
    }
    attempts += 1;
    if (argumentError) {
      throw ArgumentError();
    }
    return testRequest;
  }
}

class MockHttpClientRequest extends Mock implements HttpClientRequest {
  final MockHttpClientResponse testResponse = MockHttpClientResponse();

  @override
  Future<HttpClientResponse> close() async {
    return testResponse;
  }
}

class MockHttpClientResponse extends Mock implements HttpClientResponse {
  @override
  int statusCode = HttpStatus.ok;

  @override
  HttpHeaders headers = FakeHttpHeaders(<String, List<String>>{});

  @override
  Future<void> forEach(void Function(List<int> element) action) async {
    action(<int>[0]);
    return;
  }
}

class FakeHttpHeaders extends Fake implements HttpHeaders {
  FakeHttpHeaders(this.values);

  final Map<String, List<String>> values;

  @override
  List<String> operator [](String key) {
    return values[key];
  }
}

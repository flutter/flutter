// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// See also dev/automated_tests/flutter_test/flutter_gold_test.dart

import 'dart:convert';
import 'dart:io' hide Directory;

import 'package:file/file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_goldens/src/flaky_goldens.dart';
import 'package:flutter_goldens/src/flutter_goldens_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:process/process.dart';

// 1x1 transparent pixel
const List<int> kTestPngBytes = <int>[
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0,
  1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 11, 73, 68, 65, 84,
  120, 1, 99, 97, 0, 2, 0, 0, 25, 0, 5, 144, 240, 54, 245, 0, 0, 0, 0, 73, 69,
  78, 68, 174, 66, 96, 130,
];

@immutable
class RunInvocation {
  const RunInvocation(this.command, this.workingDirectory);

  final List<String> command;
  final String? workingDirectory;

  @override
  int get hashCode => Object.hash(Object.hashAll(command), workingDirectory);

  bool _commandEquals(List<String> other) {
    if (other == command) {
      return true;
    }
    if (other.length != command.length) {
      return false;
    }
    for (int index = 0; index < other.length; index += 1) {
      if (other[index] != command[index]) {
        return false;
      }
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is RunInvocation
        && _commandEquals(other.command)
        && other.workingDirectory == workingDirectory;
  }

  @override
  String toString() => '$command ($workingDirectory)';
}

class FakeProcessManager extends Fake implements ProcessManager {
  Map<RunInvocation, ProcessResult> processResults = <RunInvocation, ProcessResult>{};

  /// Used if [processResults] does not contain a matching invocation.
  ProcessResult? fallbackProcessResult;

  final List<String?> workingDirectories = <String?>[];

  @override
  Future<ProcessResult> run(
      List<Object> command, {
        String? workingDirectory,
        Map<String, String>? environment,
        bool includeParentEnvironment = true,
        bool runInShell = false,
        Encoding? stdoutEncoding = systemEncoding,
        Encoding? stderrEncoding = systemEncoding,
      }) async {
    workingDirectories.add(workingDirectory);
    final ProcessResult? result = processResults[RunInvocation(command.cast<String>(), workingDirectory)];
    if (result == null && fallbackProcessResult == null) {
      printOnFailure('ProcessManager.run was called with $command ($workingDirectory) unexpectedly - $processResults.');
      fail('See above.');
    }
    return result ?? fallbackProcessResult!;
  }
}

// See also dev/automated_tests/flutter_test/flutter_gold_test.dart
class FakeSkiaGoldClient extends Fake implements SkiaGoldClient {
  Map<String, String> expectationForTestValues = <String, String>{};
  Exception? getExpectationForTestThrowable;
  @override
  Future<String> getExpectationForTest(String testName) async {
    if (getExpectationForTestThrowable != null) {
      throw getExpectationForTestThrowable!;
    }
    return expectationForTestValues[testName] ?? '';
  }

  @override
  Future<void> auth() async {}

  final List<String> testNames = <String>[];

  int initCalls = 0;
  int calledWithFlaky = 0;
  @override
  Future<void> imgtestInit({ bool isFlaky = false }) async {
    initCalls += 1;
    if (isFlaky) {
      calledWithFlaky += 1;
    }
  }
  @override
  Future<bool> imgtestAdd(String testName, File goldenFile, { bool isFlaky = false }) async {
    testNames.add(testName);
    if (isFlaky) {
      calledWithFlaky += 1;
    }
    return true;
  }

  int tryInitCalls = 0;
  @override
  Future<void> tryjobInit({ bool isFlaky = false }) async {
    tryInitCalls += 1;
    if (isFlaky) {
      calledWithFlaky += 1;
    }
  }

  @override
  Future<bool> tryjobAdd(String testName, File goldenFile, { bool isFlaky = false }) async {
    if (isFlaky) {
      calledWithFlaky += 1;
    }
    return true;
  }

  Map<String, List<int>> imageBytesValues = <String, List<int>>{};
  @override
  Future<List<int>> getImageBytes(String imageHash) async => imageBytesValues[imageHash]!;

  Map<String, String> cleanTestNameValues = <String, String>{};
  @override
  String cleanTestName(String fileName) => cleanTestNameValues[fileName] ?? '';
}

class FakeFlakyLocalFileComparator extends FakeLocalFileComparator with FlakyGoldenMixin {}

class FakeLocalFileComparator extends Fake implements LocalFileComparator {
  @override
  late Uri basedir;

  @override
  Uri getTestUri(Uri key, int? version) => Uri.parse('fake');

  @override
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async => true;
}

class FakeDirectory extends Fake implements Directory {
  late bool existsSyncValue;
  @override
  bool existsSync() => existsSyncValue;

  @override
  late Uri uri;
}

class FakeHttpClient extends Fake implements HttpClient {
  late Uri lastUri;
  late FakeHttpClientRequest request;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    lastUri = url;
    return request;
  }
}

class FakeHttpClientRequest extends Fake implements HttpClientRequest {
  late FakeHttpImageResponse response;

  @override
  Future<HttpClientResponse> close() async {
    return response;
  }
}

class FakeHttpImageResponse extends Fake implements HttpClientResponse {
  FakeHttpImageResponse(this.response);

  final List<List<int>> response;

  @override
  Future<void> forEach(void Function(List<int> element) action) async {
    response.forEach(action);
  }
}

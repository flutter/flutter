// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

import 'package:flutter_devicelab/framework/cocoon.dart';
import 'package:flutter_devicelab/framework/task_result.dart';

import 'common.dart';

void main() {
  ProcessResult _processResult;
  ProcessResult runSyncStub(String executable, List<String> args,
          {Map<String, String> environment,
          bool includeParentEnvironment,
          bool runInShell,
          Encoding stderrEncoding,
          Encoding stdoutEncoding,
          String workingDirectory}) =>
      _processResult;

  // Expected test values.
  const String commitSha = 'a4952838bf288a81d8ea11edfd4b4cd649fa94cc';
  const String serviceAccountTokenPath = 'test_account_file';
  const String serviceAccountToken = 'test_token';

  group('Cocoon', () {
    Client mockClient;
    Cocoon cocoon;
    FileSystem fs;

    setUp(() {
      fs = MemoryFileSystem();
      mockClient = MockClient((Request request) async => Response('{}', 200));

      final File serviceAccountFile = fs.file(serviceAccountTokenPath)..createSync();
      serviceAccountFile.writeAsStringSync(serviceAccountToken);
    });

    test('returns expected commit sha', () {
      _processResult = ProcessResult(1, 0, commitSha, '');
      cocoon = Cocoon(
        serviceAccountTokenPath: serviceAccountTokenPath,
        fs: fs,
        httpClient: mockClient,
        processRunSync: runSyncStub,
      );

      expect(cocoon.commitSha, commitSha);
    });

    test('throws exception on git cli errors', () {
      _processResult = ProcessResult(1, 1, '', '');
      cocoon = Cocoon(
        serviceAccountTokenPath: serviceAccountTokenPath,
        fs: fs,
        httpClient: mockClient,
        processRunSync: runSyncStub,
      );

      expect(() => cocoon.commitSha, throwsA(isA<CocoonException>()));
    });

    test('writes expected update task json', () async {
      _processResult = ProcessResult(1, 0, commitSha, '');
      final TaskResult result = TaskResult.fromJson(<String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'i': 0,
          'j': 0,
          'not_a_metric': 'something',
        },
        'benchmarkScoreKeys': <String>['i', 'j'],
      });

      cocoon = Cocoon(
        fs: fs,
        processRunSync: runSyncStub,
      );

      const String resultsPath = 'results.json';
      await cocoon.writeTaskResultToFile(
        builderName: 'builderAbc',
        gitBranch: 'master',
        result: result,
        resultsPath: resultsPath,
      );

      final String resultJson = fs.file(resultsPath).readAsStringSync();
      const String expectedJson = '{'
          '"CommitBranch":"master",'
          '"CommitSha":"$commitSha",'
          '"BuilderName":"builderAbc",'
          '"NewStatus":"Succeeded",'
          '"ResultData":{"i":0.0,"j":0.0,"not_a_metric":"something"},'
          '"BenchmarkScoreKeys":["i","j"]}';
      expect(resultJson, expectedJson);
    });

    test('uploads metrics sends expected post body', () async {
      _processResult = ProcessResult(1, 0, commitSha, '');
      const String uploadMetricsRequestWithSpaces = '{"CommitBranch":"master","CommitSha":"a4952838bf288a81d8ea11edfd4b4cd649fa94cc","BuilderName":"builder a b c","NewStatus":"Succeeded","ResultData":{},"BenchmarkScoreKeys":[]}';
      final MockClient client = MockClient((Request request) async {
        if (request.body == uploadMetricsRequestWithSpaces) {
          return Response('{}', 200);
        }

        return Response('Expected: $uploadMetricsRequestWithSpaces\nReceived: ${request.body}', 500);
     });
      cocoon = Cocoon(
        fs: fs,
        httpClient: client,
        processRunSync: runSyncStub,
        serviceAccountTokenPath: serviceAccountTokenPath,
        requestRetryLimit: 0,
      );

      const String resultsPath = 'results.json';
      const String updateTaskJson = '{'
          '"CommitBranch":"master",'
          '"CommitSha":"$commitSha",'
          '"BuilderName":"builder a b c",'  //ignore: missing_whitespace_between_adjacent_strings
          '"NewStatus":"Succeeded",'
          '"ResultData":{},'
          '"BenchmarkScoreKeys":[]}';
      fs.file(resultsPath).writeAsStringSync(updateTaskJson);
      await cocoon.sendResultsPath(resultsPath);
    });

    test('uploads expected update task payload from results file', () async {
      _processResult = ProcessResult(1, 0, commitSha, '');
      cocoon = Cocoon(
        fs: fs,
        httpClient: mockClient,
        processRunSync: runSyncStub,
        serviceAccountTokenPath: serviceAccountTokenPath,
        requestRetryLimit: 0,
      );

      const String resultsPath = 'results.json';
      const String updateTaskJson = '{'
          '"CommitBranch":"master",'
          '"CommitSha":"$commitSha",'
          '"BuilderName":"builderAbc",'
          '"NewStatus":"Succeeded",'
          '"ResultData":{"i":0.0,"j":0.0,"not_a_metric":"something"},'
          '"BenchmarkScoreKeys":["i","j"]}';
      fs.file(resultsPath).writeAsStringSync(updateTaskJson);
      await cocoon.sendResultsPath(resultsPath);
    });

    test('sends expected request from successful task', () async {
      mockClient = MockClient((Request request) async => Response('{}', 200));

      cocoon = Cocoon(
        serviceAccountTokenPath: serviceAccountTokenPath,
        fs: fs,
        httpClient: mockClient,
        requestRetryLimit: 0,
      );

      final TaskResult result = TaskResult.success(<String, dynamic>{});
      // This should not throw an error.
      await cocoon.sendTaskResult(builderName: 'builderAbc', gitBranch: 'branchAbc', result: result);
    });

    test('throws client exception on non-200 responses', () async {
      mockClient = MockClient((Request request) async => Response('', 500));

      cocoon = Cocoon(
        serviceAccountTokenPath: serviceAccountTokenPath,
        fs: fs,
        httpClient: mockClient,
        requestRetryLimit: 0,
      );

      final TaskResult result = TaskResult.success(<String, dynamic>{});
      expect(() => cocoon.sendTaskResult(builderName: 'builderAbc', gitBranch: 'branchAbc', result: result),
          throwsA(isA<ClientException>()));
    });

    test('null git branch throws error', () async {
      mockClient = MockClient((Request request) async => Response('', 500));

      cocoon = Cocoon(
        serviceAccountTokenPath: serviceAccountTokenPath,
        fs: fs,
        httpClient: mockClient,
        requestRetryLimit: 0,
      );

      final TaskResult result = TaskResult.success(<String, dynamic>{});
      expect(() => cocoon.sendTaskResult(builderName: 'builderAbc', gitBranch: null, result: result),
          throwsA(isA<AssertionError>()));
    });
  });

  group('AuthenticatedCocoonClient', () {
    FileSystem fs;

    setUp(() {
      fs = MemoryFileSystem();
      final File serviceAccountFile = fs.file(serviceAccountTokenPath)..createSync();
      serviceAccountFile.writeAsStringSync(serviceAccountToken);
    });

    test('reads token from service account file', () {
      final AuthenticatedCocoonClient client = AuthenticatedCocoonClient(serviceAccountTokenPath, filesystem: fs);
      expect(client.serviceAccountToken, serviceAccountToken);
    });

    test('reads token from service account file with whitespace', () {
      final File serviceAccountFile = fs.file(serviceAccountTokenPath)..createSync();
      serviceAccountFile.writeAsStringSync(serviceAccountToken + ' \n');
      final AuthenticatedCocoonClient client = AuthenticatedCocoonClient(serviceAccountTokenPath, filesystem: fs);
      expect(client.serviceAccountToken, serviceAccountToken);
    });

    test('throws error when service account file not found', () {
      final AuthenticatedCocoonClient client = AuthenticatedCocoonClient('idontexist', filesystem: fs);
      expect(() => client.serviceAccountToken, throwsA(isA<FileSystemException>()));
    });
  });
}

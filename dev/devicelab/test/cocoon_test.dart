// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:http/http.dart';

import 'package:flutter_devicelab/framework/cocoon.dart';
import 'package:mockito/mockito.dart';

import 'common.dart';

void main() {
  group('Cocoon', () {
    Client mockClient;

    Cocoon cocoon;

    const Map<String, dynamic> exampleResponseJson = <String, dynamic>{
      'Name': 'task name abc',
      'Status': 'Succeeded',
    };
    final List<int> exampleResponseBytes = utf8.encode(json.encode(exampleResponseJson));

    setUp(() {
      final FileSystem fs = MemoryFileSystem();
      const String serviceAccountPath = 'test_account_file';
      const String serviceAccountToken = 'test_token';
      final File serviceAccountFile = fs.file(serviceAccountPath)..createSync();
      serviceAccountFile.writeAsStringSync(serviceAccountToken);

      mockClient = MockHttpClient();

      cocoon = Cocoon(
        serviceAccountPath: serviceAccountPath,
        filesystem: fs,
        httpClient: mockClient,
      );
    });

    test('sends expected request from successful task', () async {
      when(mockClient.send(any)).thenAnswer((Invocation realInvocation) async =>
          StreamedResponse(Stream<List<int>>.value(exampleResponseBytes), 200));
      final TaskResult result = TaskResult.success(<String, dynamic>{});
      await cocoon.sendTaskResult('taskKey', result);

    });

    test('retries on ClientException', () async {
      when(mockClient.send(any)).thenThrow(ClientException);

    });
  });

  group('AuthenticatedCocoonClient', () {
    const String serviceAccountPath = 'test_account_file';
    const String serviceAccountToken = 'test_token';

    FileSystem fs;

    setUp(() {
      fs = MemoryFileSystem();
      final File serviceAccountFile = fs.file(serviceAccountPath)..createSync();
      serviceAccountFile.writeAsStringSync(serviceAccountToken);
    });

    test('reads token from service account file', () {
      final AuthenticatedCocoonClient client =
          AuthenticatedCocoonClient(serviceAccountPath, filesystem: fs);
      expect(client.serviceAccountToken, serviceAccountToken);
    });

    test('throws error when service account file not found', () {
      final AuthenticatedCocoonClient client =
          AuthenticatedCocoonClient('idontexist', filesystem: fs);
      expect(() => client.serviceAccountToken, throwsA(isA<FileSystemException>()));
    });
  });
}

class MockHttpClient extends Mock implements Client {}

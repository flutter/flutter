// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

import 'package:flutter_devicelab/framework/cocoon.dart';
import 'package:flutter_devicelab/framework/task_result.dart';

import 'common.dart';

void main() {
  group('Cocoon', () {
    const String serviceAccountPath = 'test_account_file';
    const String serviceAccountToken = 'test_token';

    Client mockClient;
    Cocoon cocoon;
    FileSystem fs;

    setUp(() {
      fs = MemoryFileSystem();

      final File serviceAccountFile = fs.file(serviceAccountPath)..createSync();
      serviceAccountFile.writeAsStringSync(serviceAccountToken);
    });

    test('sends expected request from successful task', () async {
      mockClient = MockClient((Request request) async => Response('{}', 200));

      cocoon = Cocoon(
        serviceAccountPath: serviceAccountPath,
        filesystem: fs,
        httpClient: mockClient,
      );

      final TaskResult result = TaskResult.success(<String, dynamic>{});
      // This should not throw an error.
      await cocoon.sendTaskResult('taskKey', result);
    });

    test('throws client exception on non-200 responses', () async {
      mockClient = MockClient((Request request) async => Response('', 500));

      cocoon = Cocoon(
        serviceAccountPath: serviceAccountPath,
        filesystem: fs,
        httpClient: mockClient,
      );

      final TaskResult result = TaskResult.success(<String, dynamic>{});
      expect(() => cocoon.sendTaskResult('taskKey', result), throwsA(isA<ClientException>()));
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
      final AuthenticatedCocoonClient client = AuthenticatedCocoonClient(serviceAccountPath, filesystem: fs);
      expect(client.serviceAccountToken, serviceAccountToken);
    });

    test('reads token from service account file with whitespace', () {
      final File serviceAccountFile = fs.file(serviceAccountPath)..createSync();
      serviceAccountFile.writeAsStringSync(serviceAccountToken + ' \n');
      final AuthenticatedCocoonClient client = AuthenticatedCocoonClient(serviceAccountPath, filesystem: fs);
      expect(client.serviceAccountToken, serviceAccountToken);
    });

    test('throws error when service account file not found', () {
      final AuthenticatedCocoonClient client = AuthenticatedCocoonClient('idontexist', filesystem: fs);
      expect(() => client.serviceAccountToken, throwsA(isA<FileSystemException>()));
    });
  });
}

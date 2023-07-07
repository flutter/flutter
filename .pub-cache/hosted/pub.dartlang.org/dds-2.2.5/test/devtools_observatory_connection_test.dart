// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dds/dds.dart';

import 'package:test/test.dart';
import 'common/test_helper.dart';

// Regression test for https://github.com/dart-lang/sdk/issues/45933.

void main() {
  Process? process;
  DartDevelopmentService? dds;

  setUp(() async {
    // We don't care what's actually running in the target process for this
    // test, so we're just using an existing one that invokes `debugger()` so
    // we know it won't exit before we can connect.
    process = await spawnDartProcess(
      'get_stream_history_script.dart',
      pauseOnStart: false,
    );
  });

  tearDown(() async {
    await dds?.shutdown();
    process?.kill();
    dds = null;
    process = null;
  });

  defineTest({required bool authCodesEnabled}) {
    test(
        'Ensure Observatory and DevTools assets are available with '
        '${authCodesEnabled ? '' : 'no'} auth codes', () async {
      dds = await DartDevelopmentService.startDartDevelopmentService(
        remoteVmServiceUri,
        devToolsConfiguration: DevToolsConfiguration(
          enable: true,
          customBuildDirectoryPath: devtoolsAppUri(prefix: '../../../'),
        ),
      );
      expect(dds!.isRunning, true);

      final client = HttpClient();

      // Check that Observatory assets are accessible.
      final observatoryRequest = await client.getUrl(dds!.uri!);
      final observatoryResponse = await observatoryRequest.close();
      expect(observatoryResponse.statusCode, 200);
      final observatoryContent =
          await observatoryResponse.transform(utf8.decoder).join();
      expect(observatoryContent, startsWith('<!DOCTYPE html>'));

      // Check that DevTools assets are accessible.
      final devtoolsRequest = await client.getUrl(dds!.devToolsUri!);
      final devtoolsResponse = await devtoolsRequest.close();
      expect(devtoolsResponse.statusCode, 200);
      final devtoolsContent =
          await devtoolsResponse.transform(utf8.decoder).join();
      expect(devtoolsContent, startsWith('<!DOCTYPE html>'));
    });
  }

  defineTest(authCodesEnabled: true);
  defineTest(authCodesEnabled: false);
}

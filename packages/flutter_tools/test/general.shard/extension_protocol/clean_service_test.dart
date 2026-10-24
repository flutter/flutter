// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:test/test.dart';

import '../../src/context.dart';

final class _TestCleanService extends CleanService {
  _TestCleanService(this.onClean);

  final void Function(CleanEnvironment environment) onClean;

  @override
  Future<void> clean(CleanEnvironment environment) async {
    onClean(environment);
  }
}

void main() {
  group('CleanService', () {
    late BufferLogger logger;

    setUp(() {
      logger = BufferLogger.test();
    });

    test('registers clean capability and handles clean RPC', () async {
      final verifyPort = ReceivePort();
      addTearDown(verifyPort.close);
      final SendPort verifySendPort = verifyPort.sendPort;

      void entryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            _TestCleanService((CleanEnvironment env) {
              verifySendPort.send(env.toMap());
            }),
          ],
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);

      expect(conn.capabilities.services, contains(CleanService.serviceNamespace));

      final env = CleanEnvironment(
        buildDir: Uri.directory('/tmp/project/build'),
        projectRoot: Uri.directory('/tmp/project'),
      );
      await conn.sendRequest(
        CleanService.cleanMethod,
        params: <String, Object?>{CleanService.environmentParam: env.toMap()},
      );

      final Object? rawReceived = await verifyPort.first;
      final receivedEnv = CleanEnvironment.fromJson(rawReceived! as Map<String, Object?>);
      expect(receivedEnv, equals(env));
    });

    test(
      'throws INVALID_PARAMS RpcException on missing or invalid environment parameter',
      () async {
        void entryPoint(SendPort sendPort) {
          ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
            _TestCleanService((CleanEnvironment _) {}),
          ]);
        }

        final ExtensionConnection conn = await ExtensionConnection.spawn(
          entryPoint,
          logger: logger,
        );
        addTearDown(conn.dispose);

        await expectLater(
          conn.sendRequest(CleanService.cleanMethod, params: const <String, Object?>{}),
          throwsA(
            isA<json_rpc.RpcException>().having(
              (json_rpc.RpcException e) => e.code,
              'code',
              error_code.INVALID_PARAMS,
            ),
          ),
        );

        await expectLater(
          conn.sendRequest(
            CleanService.cleanMethod,
            params: const <String, Object?>{
              CleanService.environmentParam: <String, Object?>{'projectRoot': 'relative/path'},
            },
          ),
          throwsA(
            isA<json_rpc.RpcException>().having(
              (json_rpc.RpcException e) => e.code,
              'code',
              error_code.INVALID_PARAMS,
            ),
          ),
        );
      },
    );

    test('LinuxCleanService deletes linux build and ephemeral directories over RPC', () async {
      final fs = LocalFileSystem.test(signals: FakeSignals());
      final Directory tempDir = fs.systemTempDirectory.createTempSync('flutter_linux_clean_test.');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final Directory buildDir = tempDir.childDirectory('build')..createSync(recursive: true);
      final Directory linuxBuildDir = buildDir.childDirectory('linux')..createSync(recursive: true);
      linuxBuildDir.childFile('app.so').writeAsStringSync('binary');

      final Directory linuxEphemeralDir =
          tempDir.childDirectory('linux').childDirectory('flutter').childDirectory('ephemeral')
            ..createSync(recursive: true);
      linuxEphemeralDir.childFile('generated_config.cmake').writeAsStringSync('cmake');

      final ExtensionConnection conn = await ExtensionConnection.spawn(
        linuxExtensionEntryPoint,
        logger: logger,
      );
      addTearDown(conn.dispose);

      final env = CleanEnvironment(buildDir: buildDir.uri, projectRoot: tempDir.uri);
      await conn.sendRequest(
        CleanService.cleanMethod,
        params: <String, Object?>{CleanService.environmentParam: env.toMap()},
      );

      expect(linuxBuildDir.existsSync(), isFalse);
      expect(linuxEphemeralDir.existsSync(), isFalse);
      expect(buildDir.existsSync(), isTrue);
    });
  });
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/src/artifact.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:test/test.dart';

final class _TestArtifactService extends ArtifactService {
  @override
  Future<List<ArtifactDependency>> downloadArtifacts({
    required HostPlatform hostPlatform,
    String? targetPlatform,
  }) async {
    return <ArtifactDependency>[
      ArtifactDependency(
        name: 'test-artifact-${hostPlatform.cliName}',
        sha256: 'deadbeef',
        url: Uri.parse('https://example.com/${hostPlatform.cliName}/artifact.zip'),
        hostPlatform: hostPlatform,
        targetPlatform: targetPlatform,
      ),
    ];
  }
}

void main() {
  group('ArtifactService', () {
    late BufferLogger logger;

    setUp(() {
      logger = BufferLogger.test();
    });

    test('registers artifact capability and handles downloadArtifacts RPC', () async {
      void entryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[_TestArtifactService()],
          extensionName: 'test_artifact_ext',
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);

      expect(conn.capabilities.services, contains(ArtifactService.serviceNamespace));
      expect(conn.extensionName, 'test_artifact_ext');

      final Object? response = await conn.sendRequest(
        ArtifactService.downloadArtifactsMethod,
        params: <String, Object?>{
          ArtifactService.hostPlatformParam: HostPlatform.linux_x64.cliName,
          ArtifactService.targetPlatformParam: 'linux-x64',
        },
      );
      final List<ArtifactDependency> deps = ArtifactDependency.listFromJson(response);

      expect(deps, hasLength(1));
      expect(deps.first.name, 'test-artifact-linux-x64');
      expect(deps.first.url, Uri.parse('https://example.com/linux-x64/artifact.zip'));
      expect(deps.first.sha256, 'deadbeef');
      expect(deps.first.hostPlatform, HostPlatform.linux_x64);
      expect(deps.first.targetPlatform, 'linux-x64');
    });

    test('throws RpcException on missing or invalid hostPlatform', () async {
      void entryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_TestArtifactService()]);
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);

      await expectLater(
        conn.sendRequest(
          ArtifactService.downloadArtifactsMethod,
          params: const <String, Object?>{},
        ),
        throwsA(isA<json_rpc.RpcException>()),
      );

      await expectLater(
        conn.sendRequest(
          ArtifactService.downloadArtifactsMethod,
          params: const <String, Object?>{ArtifactService.hostPlatformParam: 'invalid-host'},
        ),
        throwsA(isA<json_rpc.RpcException>()),
      );

      await expectLater(
        conn.sendRequest(
          ArtifactService.downloadArtifactsMethod,
          params: const <String, Object?>{
            ArtifactService.hostPlatformParam: 'linux-x64',
            ArtifactService.targetPlatformParam: 123,
          },
        ),
        throwsA(isA<json_rpc.RpcException>()),
      );
    });

    test('LinuxArtifactService returns expected default Linux artifact over RPC', () async {
      void entryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[LinuxArtifactService()],
          extensionName: 'flutter_tools_extension_linux_prototype',
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);

      final Object? linuxResponse = await conn.sendRequest(
        ArtifactService.downloadArtifactsMethod,
        params: <String, Object?>{
          ArtifactService.hostPlatformParam: HostPlatform.linux_x64.cliName,
          ArtifactService.targetPlatformParam: 'linux-x64',
        },
      );
      final List<ArtifactDependency> linuxDeps = ArtifactDependency.listFromJson(linuxResponse);
      expect(linuxDeps, hasLength(1));
      expect(linuxDeps.first.name, 'linux-x64-custom-artifact');
      expect(linuxDeps.first.hostPlatform, HostPlatform.linux_x64);
      expect(linuxDeps.first.targetPlatform, 'linux-x64');

      final Object? macosResponse = await conn.sendRequest(
        ArtifactService.downloadArtifactsMethod,
        params: <String, Object?>{
          ArtifactService.hostPlatformParam: HostPlatform.darwin_x64.cliName,
        },
      );
      final List<ArtifactDependency> macosDeps = ArtifactDependency.listFromJson(macosResponse);
      expect(macosDeps, isEmpty);
    });
  });
}

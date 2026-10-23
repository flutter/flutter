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
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:test/test.dart';

const String _testEngineVersion = '0123456789abcdef0123456789abcdef01234567';
const String _testSha256 = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

final class _TestArtifactService extends ArtifactService {
  @override
  Future<List<ArtifactDependency>> downloadArtifacts({
    required String engineVersion,
    required HostPlatform hostPlatform,
    Set<String>? targetPlatforms,
  }) async {
    return <ArtifactDependency>[
      for (final String targetPlatform in targetPlatforms ?? const <String>{'default-target'})
        ArtifactDependency(
          name: 'test-artifact-${hostPlatform.cliName}-$targetPlatform',
          sha256: _testSha256,
          url: Uri.parse(
            'https://example.com/$engineVersion/${hostPlatform.cliName}/$targetPlatform.zip',
          ),
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
          ArtifactService.engineVersionParam: _testEngineVersion,
          ArtifactService.hostPlatformParam: HostPlatform.linux_x64.cliName,
          ArtifactService.targetPlatformsParam: const <String>['linux-x64', 'linux-arm64'],
        },
      );
      final List<ArtifactDependency> deps = ArtifactDependency.listFromJson(response);

      expect(deps, hasLength(2));
      expect(deps.first.name, 'test-artifact-linux-x64-linux-x64');
      expect(
        deps.first.url,
        Uri.parse('https://example.com/$_testEngineVersion/linux-x64/linux-x64.zip'),
      );
      expect(deps.first.sha256, _testSha256);
      expect(deps.first.hostPlatform, HostPlatform.linux_x64);
      expect(deps.first.targetPlatform, 'linux-x64');
      expect(deps.last.targetPlatform, 'linux-arm64');
    });

    test('throws RpcException on missing or invalid engineVersion or hostPlatform', () async {
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
          ArtifactService.downloadArtifactsMethod,
          params: const <String, Object?>{
            ArtifactService.engineVersionParam: '   ',
            ArtifactService.hostPlatformParam: 'linux-x64',
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

      await expectLater(
        conn.sendRequest(
          ArtifactService.downloadArtifactsMethod,
          params: const <String, Object?>{
            ArtifactService.engineVersionParam: _testEngineVersion,
            ArtifactService.hostPlatformParam: 'invalid-host',
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

      await expectLater(
        conn.sendRequest(
          ArtifactService.downloadArtifactsMethod,
          params: const <String, Object?>{
            ArtifactService.engineVersionParam: _testEngineVersion,
            ArtifactService.hostPlatformParam: 'linux-x64',
            ArtifactService.targetPlatformsParam: 123,
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
    });

    test('LinuxArtifactService returns configured Linux artifacts over RPC', () async {
      void entryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            LinuxArtifactService(
              artifacts: <ArtifactDependency>[
                ArtifactDependency(
                  name: 'linux-x64-custom-artifact',
                  sha256: _testSha256,
                  url: Uri.parse('https://example.com/linux-x64/artifacts.zip'),
                  hostPlatform: HostPlatform.linux_x64,
                  targetPlatform: 'linux-x64',
                ),
              ],
            ),
          ],
          extensionName: 'flutter_tools_extension_linux_prototype',
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);

      final Object? linuxResponse = await conn.sendRequest(
        ArtifactService.downloadArtifactsMethod,
        params: <String, Object?>{
          ArtifactService.engineVersionParam: _testEngineVersion,
          ArtifactService.hostPlatformParam: HostPlatform.linux_x64.cliName,
          ArtifactService.targetPlatformsParam: const <String>['linux-x64'],
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
          ArtifactService.engineVersionParam: _testEngineVersion,
          ArtifactService.hostPlatformParam: HostPlatform.darwin_x64.cliName,
        },
      );
      final List<ArtifactDependency> macosDeps = ArtifactDependency.listFromJson(macosResponse);
      expect(macosDeps, isEmpty);
    });
  });
}

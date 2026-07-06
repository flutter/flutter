// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools/generic_extension_protocol.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:stream_channel/isolate_channel.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  group('ExtensionDiscoveryHelper', () {
    late ToolExtensionManager manager;
    late BufferLogger logger;

    setUp(() {
      manager = ToolExtensionManager();
      logger = BufferLogger.test();
    });

    tearDown(() async {
      await manager.dispose();
    });

    Future<ToolExtension> connectMockExtension({
      List<String>? services,
      bool throwOnCapabilities = false,
      bool timeoutOnCapabilities = false,
    }) async {
      final managerReceivePort = ReceivePort();
      final Future<ToolExtension> connectFuture = manager.connectExtension(managerReceivePort);

      final mockExtensionReceivePort = ReceivePort();
      managerReceivePort.sendPort.send(mockExtensionReceivePort.sendPort);

      final ToolExtension extension = await connectFuture;

      final mockExtensionChannel = IsolateChannel<Object?>.connectReceive(mockExtensionReceivePort);
      final mockExtensionPeer = rpc.Peer.withoutJson(mockExtensionChannel);

      mockExtensionPeer.registerMethod('extension.getCapabilities', () async {
        if (throwOnCapabilities) {
          throw rpc.RpcException(1, 'Capabilities failed');
        }
        if (timeoutOnCapabilities) {
          await Completer<void>().future;
        }
        return <String, Object?>{'services': services ?? <String>[]};
      });
      unawaited(mockExtensionPeer.listen());
      return extension;
    }

    testUsingContext('getExtensionCapabilities retrieves capabilities successfully', () async {
      final ToolExtension extension = await connectMockExtension(
        services: <String>['device', 'build'],
      );
      final helper = ExtensionDiscoveryHelper(logger: logger, platform: globals.platform);

      final ToolExtensionCapabilities? capabilities = await helper.getExtensionCapabilities(
        extension,
      );
      expect(capabilities, isNotNull);
      expect(capabilities!.services, contains('device'));
      expect(capabilities.services, contains('build'));
    });

    testUsingContext(
      'getExtensionCapabilities returns null and logs trace on failure when throwOnFailure is false',
      () async {
        final ToolExtension extension = await connectMockExtension(throwOnCapabilities: true);
        final helper = ExtensionDiscoveryHelper(logger: logger, platform: globals.platform);

        final ToolExtensionCapabilities? capabilities = await helper.getExtensionCapabilities(
          extension,
        );
        expect(capabilities, isNull);
        expect(logger.traceText, contains('Failed to get capabilities'));
      },
    );

    testUsingContext('isServiceSupported correctly checks service namespace', () async {
      final ToolExtension extension = await connectMockExtension(services: <String>['device']);
      final helper = ExtensionDiscoveryHelper(logger: logger, platform: globals.platform);

      expect(await helper.isServiceSupported(extension, 'device'), isTrue);
      expect(await helper.isServiceSupported(extension, 'template'), isFalse);
    });

    testUsingContext(
      'does not spawn prototype isolates or query extensions when prototype flag is disabled',
      () async {
        final helper = ExtensionDiscoveryHelper(
          extensionManager: manager,
          logger: logger,
          platform: FakePlatform(
            environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'false'},
          ),
        );

        final List<ToolExtension> extensions = await helper.getExtensionsSupporting('device');
        expect(extensions, isEmpty);
        expect(manager.extensions, isEmpty);
      },
    );

    testUsingContext(
      'spawns prototype isolates when FLUTTER_TOOL_EXTENSION_PROTOTYPE is true and manager is empty',
      () async {
        final helper = ExtensionDiscoveryHelper(
          extensionManager: manager,
          logger: logger,
          platform: FakePlatform(
            environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'},
          ),
        );

        expect(manager.extensions, isEmpty);
        final List<ToolExtension> extensions = await helper.getExtensionsSupporting('device');

        expect(manager.extensions, hasLength(1));
        expect(extensions, hasLength(1));
        expect(extensions.first, equals(manager.extensions.first));
      },
      overrides: <Type, Generator>{ProcessManager: () => FakeProcessManager.any()},
    );

    testUsingContext(
      'returns extensions matching the requested service namespace and filters out non-matching ones',
      () async {
        await connectMockExtension(services: <String>['device', 'diagnostics']);
        await connectMockExtension(services: <String>['config']);

        final helper = ExtensionDiscoveryHelper(
          extensionManager: manager,
          logger: logger,
          platform: FakePlatform(
            environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'},
          ),
        );

        final List<ToolExtension> deviceExtensions = await helper.getExtensionsSupporting('device');
        expect(deviceExtensions, hasLength(1));

        final List<ToolExtension> configExtensions = await helper.getExtensionsSupporting('config');
        expect(configExtensions, hasLength(1));
        expect(configExtensions.first, isNot(equals(deviceExtensions.first)));

        final List<ToolExtension> missingExtensions = await helper.getExtensionsSupporting(
          'nonexistent',
        );
        expect(missingExtensions, isEmpty);
      },
    );

    testUsingContext(
      'filters out extensions where getCapabilities throws an error when throwOnFailure is false',
      () async {
        await connectMockExtension(throwOnCapabilities: true);
        await connectMockExtension(services: <String>['device']);

        final helper = ExtensionDiscoveryHelper(
          extensionManager: manager,
          logger: logger,
          platform: FakePlatform(
            environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'},
          ),
        );

        expect(manager.extensions, hasLength(2));
        final List<ToolExtension> extensions = await helper.getExtensionsSupporting('device');

        expect(extensions, hasLength(1));
        expect(logger.traceText, contains('Failed to get capabilities'));
      },
    );

    testUsingContext(
      'filters out extensions where getCapabilities times out when throwOnFailure is false',
      () async {
        await connectMockExtension(timeoutOnCapabilities: true);
        await connectMockExtension(services: <String>['device']);

        final helper = ExtensionDiscoveryHelper(
          capabilitiesTimeout: const Duration(milliseconds: 50),
          extensionManager: manager,
          logger: logger,
          platform: FakePlatform(
            environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'},
          ),
        );

        expect(manager.extensions, hasLength(2));
        final List<ToolExtension> extensions = await helper.getExtensionsSupporting('device');

        expect(extensions, hasLength(1));
        expect(logger.traceText, contains('Failed to get capabilities'));
      },
    );

    testUsingContext('respects throwOnFailure when getCapabilities throws an error', () async {
      await connectMockExtension(throwOnCapabilities: true);

      final helper = ExtensionDiscoveryHelper(
        extensionManager: manager,
        logger: logger,
        platform: FakePlatform(
          environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'},
        ),
      );

      expect(
        () => helper.getExtensionsSupporting('device', throwOnFailure: true),
        throwsA(isA<rpc.RpcException>()),
      );
    });

    testUsingContext('respects throwOnFailure when getCapabilities times out', () async {
      await connectMockExtension(timeoutOnCapabilities: true);

      final helper = ExtensionDiscoveryHelper(
        capabilitiesTimeout: const Duration(milliseconds: 50),
        extensionManager: manager,
        logger: logger,
        platform: FakePlatform(
          environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'},
        ),
      );

      expect(
        () => helper.getExtensionsSupporting('device', throwOnFailure: true),
        throwsA(isA<TimeoutException>()),
      );
    });

    testUsingContext('respects throwOnFailure when startExtension fails', () async {
      final throwingManager = _ThrowingToolExtensionManager();
      final helper = ExtensionDiscoveryHelper(
        extensionManager: throwingManager,
        logger: logger,
        platform: FakePlatform(
          environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'},
        ),
      );

      expect(
        () => helper.getExtensionsSupporting('device', throwOnFailure: true),
        throwsA(isA<Exception>()),
      );

      final List<ToolExtension> extensions = await helper.getExtensionsSupporting('device');
      expect(extensions, isEmpty);
      expect(logger.errorText, contains('Failed to spawn prototype extension'));
    });
  });
}

class _ThrowingToolExtensionManager extends ToolExtensionManager {
  @override
  Future<ToolExtension> startExtension(
    void Function(SendPort) entryPoint, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    throw Exception('Spawning failed intentionally');
  }
}

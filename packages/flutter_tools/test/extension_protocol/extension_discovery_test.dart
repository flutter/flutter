// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools/generic_extension_protocol.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:stream_channel/isolate_channel.dart';
import 'package:test/test.dart';

import '../src/common.dart';
import '../src/context.dart';

class MockToolExtensionManager extends ToolExtensionManager {
  int startExtensionCallCount = 0;
  bool shouldThrowOnStart = false;
  final List<ToolExtension> _mockExtensions = <ToolExtension>[];

  @override
  List<ToolExtension> get extensions => _mockExtensions;

  void addExtension(ToolExtension extension) {
    _mockExtensions.add(extension);
  }

  @override
  Future<ToolExtension> startExtension(
    void Function(SendPort) entryPoint, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    startExtensionCallCount++;
    if (shouldThrowOnStart) {
      throw Exception('Mock spawn failure');
    }
    return _mockExtensions.first;
  }
}

Future<ToolExtension> _connectMockExtension({
  required List<String>? services,
  bool shouldThrow = false,
  bool shouldTimeout = false,
}) async {
  final manager = ToolExtensionManager();
  final extensionReceivePort = ReceivePort();
  final Future<ToolExtension> extensionFuture = manager.connectExtension(extensionReceivePort);

  final hostReceivePort = ReceivePort();
  extensionReceivePort.sendPort.send(hostReceivePort.sendPort);

  final ToolExtension extension = await extensionFuture;

  final testChannel = IsolateChannel<Object?>.connectReceive(hostReceivePort);
  final testPeer = rpc.Peer.withoutJson(testChannel);

  testPeer.registerMethod('extension.getCapabilities', () async {
    if (shouldThrow) {
      throw Exception('Capabilities failure');
    }
    if (shouldTimeout) {
      await Future<void>.delayed(const Duration(seconds: 10));
    }
    return ToolExtensionCapabilities(services: services ?? const <String>[]).toMap();
  });

  unawaited(testPeer.listen());
  return extension;
}

void main() {
  group('ExtensionDiscoveryHelper', () {
    late BufferLogger logger;
    late MockToolExtensionManager mockManager;

    setUp(() {
      logger = BufferLogger.test();
      mockManager = MockToolExtensionManager();
    });

    testUsingContext(
      'spawns prototype isolates when globals.isToolExtensionPrototypeEnabled is true and extensions is empty',
      () async {
        final ToolExtension extension = await _connectMockExtension(services: <String>['device']);

        final emptyManager = MockToolExtensionManager();
        emptyManager.addExtension(extension);
        final List<ToolExtension> mockExtensionsList = emptyManager._mockExtensions.toList();
        emptyManager._mockExtensions.clear();

        final spawningManager = _SpawningMockToolExtensionManager(mockExtensionsList);
        final spawningHelper = ExtensionDiscoveryHelper(
          extensionManager: spawningManager,
          logger: logger,
        );

        final List<ToolExtension> result = await spawningHelper.getExtensionsSupporting('device');
        expect(spawningManager.startExtensionCallCount, 1);
        expect(result, hasLength(1));
        expect(result.first, mockExtensionsList.first);
      },
      overrides: <Type, Generator>{
        Platform: () =>
            FakePlatform(environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'}),
      },
    );

    testUsingContext(
      'returns empty list and does not spawn when globals.isToolExtensionPrototypeEnabled is false',
      () async {
        final helper = ExtensionDiscoveryHelper(extensionManager: mockManager, logger: logger);

        final List<ToolExtension> result = await helper.getExtensionsSupporting('device');
        expect(mockManager.startExtensionCallCount, 0);
        expect(result, isEmpty);
      },
      overrides: <Type, Generator>{
        Platform: () => FakePlatform(
          environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'false'},
        ),
      },
    );

    testUsingContext(
      'respects throwOnFailure when spawn fails',
      () async {
        mockManager.shouldThrowOnStart = true;
        final helper = ExtensionDiscoveryHelper(extensionManager: mockManager, logger: logger);

        expect(
          () => helper.getExtensionsSupporting('device', throwOnFailure: true),
          throwsException,
        );

        final List<ToolExtension> result = await helper.getExtensionsSupporting('device');
        expect(result, isEmpty);
        expect(logger.errorText, contains('Failed to spawn prototype extension'));
      },
      overrides: <Type, Generator>{
        Platform: () =>
            FakePlatform(environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'}),
      },
    );

    testUsingContext(
      'respects throwOnFailure when getCapabilities fails',
      () async {
        final ToolExtension failingExtension = await _connectMockExtension(
          services: null,
          shouldThrow: true,
        );
        mockManager.addExtension(failingExtension);

        final helper = ExtensionDiscoveryHelper(extensionManager: mockManager, logger: logger);

        expect(
          () => helper.getExtensionsSupporting('device', throwOnFailure: true),
          throwsException,
        );

        final List<ToolExtension> result = await helper.getExtensionsSupporting('device');
        expect(result, isEmpty);
        expect(logger.traceText, contains('Failed to get capabilities'));
      },
      overrides: <Type, Generator>{
        Platform: () =>
            FakePlatform(environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'}),
      },
    );

    testUsingContext(
      'filters out extensions where getCapabilities times out or fails',
      () async {
        final ToolExtension validExtension = await _connectMockExtension(
          services: <String>['device'],
        );
        final ToolExtension failingExtension = await _connectMockExtension(
          services: null,
          shouldThrow: true,
        );

        mockManager.addExtension(validExtension);
        mockManager.addExtension(failingExtension);

        final helper = ExtensionDiscoveryHelper(extensionManager: mockManager, logger: logger);

        final List<ToolExtension> result = await helper.getExtensionsSupporting('device');
        expect(result, equals(<ToolExtension>[validExtension]));
      },
      overrides: <Type, Generator>{
        Platform: () =>
            FakePlatform(environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'}),
      },
    );

    testUsingContext(
      'returns extensions matching requested service namespace',
      () async {
        final ToolExtension deviceExtension = await _connectMockExtension(
          services: <String>['device', 'diagnostics'],
        );
        final ToolExtension templateExtension = await _connectMockExtension(
          services: <String>['template'],
        );

        mockManager.addExtension(deviceExtension);
        mockManager.addExtension(templateExtension);

        final helper = ExtensionDiscoveryHelper(extensionManager: mockManager, logger: logger);

        final List<ToolExtension> deviceResults = await helper.getExtensionsSupporting('device');
        expect(deviceResults, equals(<ToolExtension>[deviceExtension]));

        final List<ToolExtension> diagResults = await helper.getExtensionsSupporting('diagnostics');
        expect(diagResults, equals(<ToolExtension>[deviceExtension]));

        final List<ToolExtension> templateResults = await helper.getExtensionsSupporting(
          'template',
        );
        expect(templateResults, equals(<ToolExtension>[templateExtension]));

        final List<ToolExtension> buildResults = await helper.getExtensionsSupporting('build');
        expect(buildResults, isEmpty);
      },
      overrides: <Type, Generator>{
        Platform: () =>
            FakePlatform(environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'}),
      },
    );
  });
}

class _SpawningMockToolExtensionManager extends MockToolExtensionManager {
  _SpawningMockToolExtensionManager(this._toSpawn);

  final List<ToolExtension> _toSpawn;

  @override
  Future<ToolExtension> startExtension(
    void Function(SendPort) entryPoint, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    startExtensionCallCount++;
    _mockExtensions.addAll(_toSpawn);
    return _mockExtensions.first;
  }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/context/tool_dependencies.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';

final class _ShutdownNotifyingService extends ToolExtensionService {
  @override
  String get namespace => 'lifecycle';

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async => <String, ExtensionRpcHandler>{};

  @override
  Future<void> shutdown() async {
    sendNotification('lifecycle.shutdown', const <String, Object?>{'shuttingDown': true});
  }
}

final class _GatedLifecycleService extends ToolExtensionService {
  _GatedLifecycleService({
    this.handlers = const <String, ExtensionRpcHandler>{},
    this.initStartedPort,
    this.namespace = 'lifecycle',
    this.shutdownStartedPort,
  });

  final Map<String, ExtensionRpcHandler> handlers;
  final SendPort? initStartedPort;
  @override
  final String namespace;
  final SendPort? shutdownStartedPort;

  static Future<void> _waitForGate(SendPort? port) async {
    if (port == null) {
      return;
    }
    final gatePort = ReceivePort();
    port.send(gatePort.sendPort);
    await gatePort.first;
    gatePort.close();
  }

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    await _waitForGate(initStartedPort);
    return handlers;
  }

  @override
  Future<void> shutdown() => _waitForGate(shutdownStartedPort);
}

void _shutdownNotifyingEntryPoint(SendPort sendPort) {
  unawaited(
    ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_ShutdownNotifyingService()]),
  );
}

void _dummyExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[]);
}

void _linuxOnlyExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[],
    supportedPlatforms: const <String>{'linux'},
  );
}

void main() {
  group('ExtensionManager Integration', () {
    testWithoutContext('ExtensionManager loads extension compatible with hostPlatform', () async {
      final logger = BufferLogger.test();
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
      );
      await manager.initialize(entryPoints: <ExtensionEntryPoint>[_dummyExtensionEntryPoint]);

      expect(manager.connections, hasLength(1));
      await manager.dispose();
      expect(manager.connections, isEmpty);
    });

    testWithoutContext(
      'ExtensionManager filters out extension incompatible with hostPlatform',
      () async {
        final logger = BufferLogger.test();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.darwin_arm64,
          logger: logger,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        );
        await manager.initialize(entryPoints: <ExtensionEntryPoint>[_linuxOnlyExtensionEntryPoint]);

        expect(manager.connections, isEmpty);
        await manager.dispose();
      },
    );

    testWithoutContext(
      'ensureInitialized skips spawning when tool extensions are disabled',
      () async {
        final logger = BufferLogger.test();
        var spawned = false;

        final disabledManager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          featureFlags: TestFeatureFlags(),
          entryPoints: <ExtensionEntryPoint>[
            (SendPort sendPort) {
              spawned = true;
              _dummyExtensionEntryPoint(sendPort);
            },
          ],
        );

        await disabledManager.ensureInitialized();
        expect(spawned, isFalse);
        expect(disabledManager.connections, isEmpty);
        await disabledManager.dispose();
      },
    );

    testWithoutContext(
      'disable and initialize throw AssertionError when called after initialization has started',
      () async {
        final logger = BufferLogger.test();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        );
        await manager.ensureInitialized();
        expect(() => manager.disable(), throwsA(isA<AssertionError>()));
        await expectLater(
          manager.initialize(entryPoints: <ExtensionEntryPoint>[_dummyExtensionEntryPoint]),
          throwsA(isA<AssertionError>()),
        );
        await manager.dispose();
      },
    );

    testWithoutContext(
      'ToolDependencies.bootstrap registers extensionManager.dispose on shutdownHooks',
      () async {
        final logger = BufferLogger.test();
        final shutdownHooks = ShutdownHooks();
        final fs = MemoryFileSystem.test();
        final ToolDependencies deps = await ToolDependencies.bootstrap(
          analytics: const NoOpAnalytics(),
          botDetector: const FakeBotDetector(true),
          extensionEntryPoints: <ExtensionEntryPoint>[_shutdownNotifyingEntryPoint],
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
          flutterVersion: FakeFlutterVersion(),
          fs: fs,
          logger: logger,
          platform: FakePlatform(),
          processManager: FakeProcessManager.any(),
          shutdownHooks: shutdownHooks,
          stdio: FakeStdio(),
          templateRenderer: const MustacheTemplateRenderer(),
        );

        final ExtensionManager manager = deps.extensionManager!;
        await manager.ensureInitialized();
        expect(manager.connections, hasLength(1));

        final shutdownEvents = <Map<String, Object?>>[];
        final StreamSubscription<Map<String, Object?>> sub = manager.connections.single
            .onNotification('lifecycle.shutdown')
            .listen(shutdownEvents.add);
        addTearDown(sub.cancel);

        await shutdownHooks.runShutdownHooks(logger);
        expect(manager.connections, isEmpty);
        expect(shutdownEvents, <Map<String, Object?>>[
          const <String, Object?>{'shuttingDown': true},
        ]);
      },
    );

    testWithoutContext(
      'hostPlatformName maps built-in and custom darwin/non-darwin host platforms',
      () {
        final logger = BufferLogger.test();
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        expect(
          ExtensionManager(
            hostPlatform: HostPlatform.darwin_arm64,
            logger: logger,
            featureFlags: featureFlags,
          ).hostPlatformName,
          'macos',
        );
        expect(
          ExtensionManager(
            hostPlatform: HostPlatform('darwin', .riscv64),
            logger: logger,
            featureFlags: featureFlags,
          ).hostPlatformName,
          'macos',
        );
        expect(
          ExtensionManager(
            hostPlatform: HostPlatform('freebsd', .x64),
            logger: logger,
            featureFlags: featureFlags,
          ).hostPlatformName,
          'freebsd',
        );
      },
    );

    testWithoutContext('dispose awaits in-flight ensureInitialized, shuts down spawned connection, and skips remaining entrypoints', () async {
      final logger = BufferLogger.test();
      final initStartedPort = ReceivePort();
      final shutdownStartedPort = ReceivePort();
      final secondEntryPointSpawnedPort = ReceivePort();
      addTearDown(initStartedPort.close);
      addTearDown(shutdownStartedPort.close);
      addTearDown(secondEntryPointSpawnedPort.close);

      final SendPort initStartedSendPort = initStartedPort.sendPort;
      final SendPort shutdownStartedSendPort = shutdownStartedPort.sendPort;
      final SendPort secondSpawnedSendPort = secondEntryPointSpawnedPort.sendPort;
      var secondEntryPointSpawned = false;
      secondEntryPointSpawnedPort.listen((Object? _) {
        secondEntryPointSpawned = true;
      });

      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        entryPoints: <ExtensionEntryPoint>[
          (SendPort sendPort) {
            unawaited(
              ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
                _GatedLifecycleService(
                  initStartedPort: initStartedSendPort,
                  shutdownStartedPort: shutdownStartedSendPort,
                ),
              ]),
            );
          },
          (SendPort sendPort) {
            secondSpawnedSendPort.send(null);
            _dummyExtensionEntryPoint(sendPort);
          },
        ],
      );

      final Future<void> initFuture = manager.ensureInitialized();
      final initGateSendPort = await initStartedPort.first as SendPort;

      var disposeCompleted = false;
      final Future<void> disposeFuture = manager.dispose().then((_) {
        disposeCompleted = true;
      });

      expect(disposeCompleted, isFalse);
      expect(manager.diagnosticsExtensions, isEmpty);
      expect(manager.configurationExtensions, isEmpty);
      expect(manager.deviceExtensions, isEmpty);

      // Allow the in-flight entrypoint to finish initializing; dispose() must
      // then run its shutdown() hook before completing.
      initGateSendPort.send(null);
      final shutdownGateSendPort = await shutdownStartedPort.first as SendPort;
      expect(disposeCompleted, isFalse);
      shutdownGateSendPort.send(null);

      await Future.wait<void>(<Future<void>>[initFuture, disposeFuture]);
      expect(disposeCompleted, isTrue);
      expect(secondEntryPointSpawned, isFalse);
      expect(
        'ExtensionConnection spawning extension isolate...'.allMatches(logger.traceText),
        hasLength(1),
      );
      expect(manager.connections, isEmpty);
      expect(manager.isInitialized, isFalse);
    });

    testWithoutContext(
      'ensureInitialized and initialize are no-ops after dispose begins or completes',
      () async {
        final logger = BufferLogger.test();
        final spawnedPort = ReceivePort();
        final shutdownStartedPort = ReceivePort();
        addTearDown(spawnedPort.close);
        addTearDown(shutdownStartedPort.close);
        final SendPort spawnedSendPort = spawnedPort.sendPort;
        final SendPort shutdownStartedSendPort = shutdownStartedPort.sendPort;
        var spawnCount = 0;
        spawnedPort.listen((Object? _) {
          spawnCount++;
        });
        void countingEntryPoint(SendPort sendPort) {
          spawnedSendPort.send(null);
          unawaited(
            ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
              _GatedLifecycleService(shutdownStartedPort: shutdownStartedSendPort),
            ]),
          );
        }

        final preDisposedManager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
          entryPoints: <ExtensionEntryPoint>[countingEntryPoint],
        );

        await preDisposedManager.dispose();
        await preDisposedManager.ensureInitialized();
        await preDisposedManager.initialize(entryPoints: <ExtensionEntryPoint>[countingEntryPoint]);
        expect(spawnCount, 0);
        expect(preDisposedManager.connections, isEmpty);
        expect(preDisposedManager.isInitialized, isFalse);
        expect(preDisposedManager.deviceExtensions, isEmpty);

        final initializedManager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
          entryPoints: <ExtensionEntryPoint>[countingEntryPoint],
        );

        await initializedManager.ensureInitialized();
        expect(spawnCount, 1);
        expect(initializedManager.connections, hasLength(1));
        expect(initializedManager.isInitialized, isTrue);

        final Future<void> disposeFuture = initializedManager.dispose();
        expect(initializedManager.connections, isEmpty);
        expect(initializedManager.isInitialized, isFalse);
        expect(initializedManager.diagnosticsExtensions, isEmpty);
        expect(initializedManager.configurationExtensions, isEmpty);
        expect(initializedManager.deviceExtensions, isEmpty);
        final shutdownGateSendPort = await shutdownStartedPort.first as SendPort;

        // Calling ensureInitialized() or initialize() while dispose() is in flight is a no-op.
        await initializedManager.ensureInitialized();
        await initializedManager.initialize(entryPoints: <ExtensionEntryPoint>[countingEntryPoint]);
        expect(spawnCount, 1);

        shutdownGateSendPort.send(null);
        await disposeFuture;
        expect(initializedManager.connections, isEmpty);
        expect(initializedManager.isInitialized, isFalse);

        // Calling ensureInitialized() or initialize() after dispose() completes is also a no-op.
        await initializedManager.ensureInitialized();
        await initializedManager.initialize(entryPoints: <ExtensionEntryPoint>[countingEntryPoint]);
        expect(spawnCount, 1);
        expect(initializedManager.connections, isEmpty);
        expect(initializedManager.isInitialized, isFalse);
      },
    );

    testWithoutContext('dispose aborts in-flight service title fetching without leaking clients or skipping shutdown', () async {
      final logger = BufferLogger.test();
      final diagnosticsTitleStartedPort = ReceivePort();
      final configTitleCalledPort = ReceivePort();
      final shutdownStartedPort = ReceivePort();
      addTearDown(diagnosticsTitleStartedPort.close);
      addTearDown(configTitleCalledPort.close);
      addTearDown(shutdownStartedPort.close);

      final SendPort diagnosticsTitleStartedSendPort = diagnosticsTitleStartedPort.sendPort;
      final SendPort configTitleCalledSendPort = configTitleCalledPort.sendPort;
      final SendPort shutdownStartedSendPort = shutdownStartedPort.sendPort;
      var configTitleCalled = false;
      configTitleCalledPort.listen((Object? _) {
        configTitleCalled = true;
      });

      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        entryPoints: <ExtensionEntryPoint>[
          (SendPort sendPort) {
            unawaited(
              ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
                _GatedLifecycleService(
                  namespace: DiagnosticsExtension.serviceNamespace,
                  handlers: <String, ExtensionRpcHandler>{
                    'getTitle': (Map<String, Object?> _) async {
                      await _GatedLifecycleService._waitForGate(diagnosticsTitleStartedSendPort);
                      return 'Gated Diagnostics';
                    },
                  },
                  shutdownStartedPort: shutdownStartedSendPort,
                ),
                _GatedLifecycleService(
                  namespace: ConfigurationExtension.serviceNamespace,
                  handlers: <String, ExtensionRpcHandler>{
                    'getTitle': (Map<String, Object?> _) async {
                      configTitleCalledSendPort.send(null);
                      return 'Gated Config';
                    },
                  },
                ),
                _GatedLifecycleService(namespace: DeviceService.serviceNamespace),
              ]),
            );
          },
        ],
      );

      final Future<void> initFuture = manager.ensureInitialized();
      final titleGateSendPort = await diagnosticsTitleStartedPort.first as SendPort;

      final Future<void> disposeFuture = manager.dispose();
      expect(manager.connections, isEmpty);
      expect(manager.diagnosticsExtensions, isEmpty);
      expect(manager.configurationExtensions, isEmpty);
      expect(manager.deviceExtensions, isEmpty);

      titleGateSendPort.send(null);
      final shutdownGateSendPort = await shutdownStartedPort.first as SendPort;
      expect(configTitleCalled, isFalse);
      expect(manager.diagnosticsExtensions, isEmpty);
      expect(manager.configurationExtensions, isEmpty);
      expect(manager.deviceExtensions, isEmpty);

      shutdownGateSendPort.send(null);
      await Future.wait<void>(<Future<void>>[initFuture, disposeFuture]);
      expect(configTitleCalled, isFalse);
      expect(manager.connections, isEmpty);
      expect(manager.diagnosticsExtensions, isEmpty);
      expect(manager.configurationExtensions, isEmpty);
      expect(manager.deviceExtensions, isEmpty);
      expect(manager.isInitialized, isFalse);
    });

    testWithoutContext('dispose completes cleanly when in-flight initialize throws and concurrent dispose calls await cleanup', () async {
      final logger = BufferLogger.test();
      final secondInitStartedPort = ReceivePort();
      final firstShutdownStartedPort = ReceivePort();
      addTearDown(secondInitStartedPort.close);
      addTearDown(firstShutdownStartedPort.close);

      final SendPort secondInitStartedSendPort = secondInitStartedPort.sendPort;
      final SendPort firstShutdownStartedSendPort = firstShutdownStartedPort.sendPort;

      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
      );

      final Future<void> initFuture = manager.initialize(
        entryPoints: <ExtensionEntryPoint>[
          (SendPort sendPort) {
            unawaited(
              ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
                _GatedLifecycleService(shutdownStartedPort: firstShutdownStartedSendPort),
              ]),
            );
          },
          (SendPort _) async {
            await _GatedLifecycleService._waitForGate(secondInitStartedSendPort);
            throw StateError('Simulated extension initialization failure.');
          },
        ],
      );
      final Future<void> initErrorExpectation = expectLater(
        initFuture,
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Simulated extension initialization failure'),
          ),
        ),
      );

      final secondGateSendPort = await secondInitStartedPort.first as SendPort;
      expect(manager.connections, hasLength(1));

      var firstDisposeCompleted = false;
      var secondDisposeCompleted = false;
      final Future<void> firstDispose = manager.dispose().then((_) {
        firstDisposeCompleted = true;
      });
      final Future<void> secondDispose = manager.dispose().then((_) {
        secondDisposeCompleted = true;
      });

      // Unblock the failing second entrypoint so initialize() throws while dispose() is awaiting it.
      secondGateSendPort.send(null);
      await initErrorExpectation;

      // Both concurrent dispose() calls must still await disposal of the first connection.
      final firstShutdownGateSendPort = await firstShutdownStartedPort.first as SendPort;
      expect(firstDisposeCompleted, isFalse);
      expect(secondDisposeCompleted, isFalse);

      firstShutdownGateSendPort.send(null);
      await Future.wait<void>(<Future<void>>[firstDispose, secondDispose]);

      expect(firstDisposeCompleted, isTrue);
      expect(secondDisposeCompleted, isTrue);
      expect(manager.connections, isEmpty);
      expect(manager.isInitialized, isFalse);
    });
  });
}

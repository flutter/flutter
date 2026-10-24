// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/emulator.dart';
import 'package:flutter_tools/src/experimental/extension_device_manager.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart' hide Category;
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:test/test.dart';

import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';

final class _DefaultDeviceService extends DeviceService {
  @override
  Future<List<TargetDevice>> getDevices() async => const <TargetDevice>[];

  @override
  Future<bool> isSupportedForProject({
    required String deviceId,
    required ExtensionFlutterProject project,
  }) async => false;
}

final class _TestEmulatorDeviceService extends DeviceService {
  _TestEmulatorDeviceService({this.emulators = const <TargetEmulator>[], this.onLaunchEmulator});

  final List<TargetEmulator> emulators;
  final FutureOr<bool> Function(String emulatorId, bool coldBoot)? onLaunchEmulator;

  @override
  Future<List<TargetDevice>> getDevices() async => const <TargetDevice>[];

  @override
  Future<bool> isSupportedForProject({
    required String deviceId,
    required ExtensionFlutterProject project,
  }) async => false;

  @override
  Future<List<TargetEmulator>> getEmulators() async => emulators;

  @override
  Future<bool> launchEmulator({required String emulatorId, bool coldBoot = false}) async {
    return await onLaunchEmulator?.call(emulatorId, coldBoot) ?? false;
  }
}

final class _ThrowingEmulatorDeviceService extends DeviceService {
  @override
  Future<List<TargetDevice>> getDevices() async => const <TargetDevice>[];

  @override
  Future<bool> isSupportedForProject({
    required String deviceId,
    required ExtensionFlutterProject project,
  }) async => false;

  @override
  Future<List<TargetEmulator>> getEmulators() async {
    throw StateError('Simulated emulator discovery failure');
  }

  @override
  Future<bool> launchEmulator({required String emulatorId, bool coldBoot = false}) async {
    throw StateError('Simulated emulator launch failure');
  }
}

void main() {
  group('TargetEmulator', () {
    test('serializes and deserializes with all fields and optional fields omitted', () {
      const fullEmulator = TargetEmulator(
        id: 'custom_sim_1',
        name: 'Custom Simulator 1',
        category: Category.mobile,
        manufacturer: 'Custom Corp',
      );
      final Map<String, Object?> fullMap = fullEmulator.toMap();
      expect(fullMap, <String, Object?>{
        TargetEmulator.idKey: 'custom_sim_1',
        TargetEmulator.nameKey: 'Custom Simulator 1',
        TargetEmulator.categoryKey: 'mobile',
        TargetEmulator.manufacturerKey: 'Custom Corp',
      });
      final parsedFull = TargetEmulator.fromJson(fullMap);
      expect(parsedFull, equals(fullEmulator));
      expect(parsedFull.hashCode, equals(fullEmulator.hashCode));
      expect(
        parsedFull.toString(),
        'TargetEmulator(id: custom_sim_1, name: Custom Simulator 1, '
        'category: mobile, manufacturer: Custom Corp)',
      );

      const minimalEmulator = TargetEmulator(id: 'custom_sim_2', name: 'Custom Simulator 2');
      final Map<String, Object?> minimalMap = minimalEmulator.toMap();
      expect(minimalMap, <String, Object?>{
        TargetEmulator.idKey: 'custom_sim_2',
        TargetEmulator.nameKey: 'Custom Simulator 2',
      });
      final parsedMinimal = TargetEmulator.fromJson(minimalMap);
      expect(parsedMinimal, equals(minimalEmulator));
      expect(parsedMinimal.category, isNull);
      expect(parsedMinimal.manufacturer, isNull);
      expect(parsedMinimal, isNot(equals(fullEmulator)));
    });

    test('validates required and optional fields in fromJson', () {
      expect(
        () => TargetEmulator.fromJson(const <String, Object?>{TargetEmulator.nameKey: 'Sim'}),
        throwsFormatException,
      );
      expect(
        () => TargetEmulator.fromJson(const <String, Object?>{
          TargetEmulator.idKey: '',
          TargetEmulator.nameKey: 'Sim',
        }),
        throwsFormatException,
      );
      expect(
        () => TargetEmulator.fromJson(const <String, Object?>{TargetEmulator.idKey: 'sim_1'}),
        throwsFormatException,
      );
      expect(
        () => TargetEmulator.fromJson(const <String, Object?>{
          TargetEmulator.idKey: 'sim_1',
          TargetEmulator.nameKey: '',
        }),
        throwsFormatException,
      );
      expect(
        () => TargetEmulator.fromJson(const <String, Object?>{
          TargetEmulator.idKey: 'sim_1',
          TargetEmulator.nameKey: 'Sim',
          TargetEmulator.categoryKey: 'invalid_category',
        }),
        throwsFormatException,
      );
      expect(
        () => TargetEmulator.fromJson(const <String, Object?>{
          TargetEmulator.idKey: 'sim_1',
          TargetEmulator.nameKey: 'Sim',
          TargetEmulator.categoryKey: 123,
        }),
        throwsFormatException,
      );
      expect(
        () => TargetEmulator.fromJson(const <String, Object?>{
          TargetEmulator.idKey: 'sim_1',
          TargetEmulator.nameKey: 'Sim',
          TargetEmulator.manufacturerKey: 123,
        }),
        throwsFormatException,
      );
    });
  });

  group('DeviceService emulator RPCs', () {
    late BufferLogger logger;

    setUp(() {
      logger = BufferLogger.test();
    });

    test('default DeviceService implementations return empty emulators and false launch', () async {
      void entryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[_DefaultDeviceService()],
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);
      final client = ExtensionDeviceClient(conn, logger: logger);

      expect(await client.getEmulators(), isEmpty);
      expect(await client.launchEmulator(emulatorId: 'any_id', coldBoot: true), isFalse);
    });

    test('getEmulators and launchEmulator round-trip over RPC', () async {
      final verifyPort = ReceivePort();
      addTearDown(verifyPort.close);
      final SendPort verifySendPort = verifyPort.sendPort;

      void entryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            _TestEmulatorDeviceService(
              emulators: const <TargetEmulator>[
                TargetEmulator(
                  id: 'ext_emu_1',
                  name: 'Extension Emulator 1',
                  category: Category.mobile,
                  manufacturer: 'Custom Vendor',
                ),
              ],
              onLaunchEmulator: (String emulatorId, bool coldBoot) {
                verifySendPort.send(<String, Object?>{
                  DeviceService.emulatorIdParam: emulatorId,
                  DeviceService.coldBootParam: coldBoot,
                });
                return emulatorId == 'ext_emu_1';
              },
            ),
          ],
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);
      final client = ExtensionDeviceClient(conn, logger: logger);

      final List<TargetEmulator> emulators = await client.getEmulators();
      expect(emulators, <TargetEmulator>[
        const TargetEmulator(
          id: 'ext_emu_1',
          name: 'Extension Emulator 1',
          category: Category.mobile,
          manufacturer: 'Custom Vendor',
        ),
      ]);

      final bool launched = await client.launchEmulator(emulatorId: 'ext_emu_1', coldBoot: true);
      expect(launched, isTrue);

      final Object? rawReceived = await verifyPort.first;
      expect(rawReceived, <String, Object?>{
        DeviceService.emulatorIdParam: 'ext_emu_1',
        DeviceService.coldBootParam: true,
      });
    });

    test('launchEmulator returns INVALID_PARAMS (-32602) on missing or invalid params', () async {
      void entryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[_DefaultDeviceService()],
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);

      // Missing emulatorId
      await expectLater(
        conn.sendRequest(DeviceService.launchEmulatorMethod, params: const <String, Object?>{}),
        throwsA(
          isA<json_rpc.RpcException>().having(
            (json_rpc.RpcException e) => e.code,
            'code',
            error_code.INVALID_PARAMS,
          ),
        ),
      );

      // Empty emulatorId
      await expectLater(
        conn.sendRequest(
          DeviceService.launchEmulatorMethod,
          params: const <String, Object?>{DeviceService.emulatorIdParam: ''},
        ),
        throwsA(
          isA<json_rpc.RpcException>().having(
            (json_rpc.RpcException e) => e.code,
            'code',
            error_code.INVALID_PARAMS,
          ),
        ),
      );

      // Wrong type for emulatorId
      await expectLater(
        conn.sendRequest(
          DeviceService.launchEmulatorMethod,
          params: const <String, Object?>{DeviceService.emulatorIdParam: 42},
        ),
        throwsA(
          isA<json_rpc.RpcException>().having(
            (json_rpc.RpcException e) => e.code,
            'code',
            error_code.INVALID_PARAMS,
          ),
        ),
      );

      // Wrong type for coldBoot
      await expectLater(
        conn.sendRequest(
          DeviceService.launchEmulatorMethod,
          params: const <String, Object?>{
            DeviceService.emulatorIdParam: 'ext_emu_1',
            DeviceService.coldBootParam: 'true',
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
  });

  group('ExtensionEmulators and ExtensionEmulator', () {
    late BufferLogger logger;

    setUp(() {
      logger = BufferLogger.test();
    });

    test('isolates faults when one extension throws and discovers emulators from others', () async {
      void failingEntryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[_ThrowingEmulatorDeviceService()],
          extensionName: 'failing_device_ext',
          supportedPlatforms: const <String>{'linux'},
        );
      }

      void healthyEntryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            _TestEmulatorDeviceService(
              emulators: const <TargetEmulator>[
                TargetEmulator(
                  id: 'healthy_emu',
                  name: 'Healthy Emulator',
                  category: Category.desktop,
                  manufacturer: 'Acme',
                ),
              ],
            ),
          ],
          extensionName: 'healthy_device_ext',
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        entryPoints: <ExtensionEntryPoint>[failingEntryPoint, healthyEntryPoint],
      );
      addTearDown(manager.dispose);

      final discovery = ExtensionEmulators(extensionManager: manager, logger: logger);
      expect(discovery.supportsPlatform, isTrue);
      expect(discovery.canListAnything, isTrue);
      expect(discovery.canLaunchAnything, isTrue);

      final List<Emulator> emulators = await discovery.emulators;
      expect(emulators, hasLength(1));
      expect(emulators.first.id, 'healthy_emu');
      expect(emulators.first.name, 'Healthy Emulator');
      expect(emulators.first.manufacturer, 'Acme');
      expect(emulators.first.category, Category.desktop);
      expect(emulators.first.platformType, PlatformType.custom);
      expect(logger.warningText, contains('failing_device_ext'));
    });

    test('ExtensionEmulator.launch forwards coldBoot and logs error when launch returns false or throws', () async {
      final launchedCalls = <(String, bool)>[];
      final service = _TestEmulatorDeviceService(
        onLaunchEmulator: (String emulatorId, bool coldBoot) {
          launchedCalls.add((emulatorId, coldBoot));
          return emulatorId == 'ok_emu';
        },
      );

      final okEmulator = ExtensionEmulator(
        deviceService: service,
        logger: logger,
        targetEmulator: const TargetEmulator(id: 'ok_emu', name: 'OK Emulator'),
      );
      expect(okEmulator.category, Category.other);
      expect(okEmulator.platformType, PlatformType.custom);

      await okEmulator.launch(coldBoot: true);
      expect(launchedCalls, <(String, bool)>[('ok_emu', true)]);
      expect(logger.errorText, isEmpty);

      final failingEmulator = ExtensionEmulator(
        deviceService: service,
        logger: logger,
        targetEmulator: const TargetEmulator(id: 'bad_emu', name: 'Bad Emulator'),
      );
      await failingEmulator.launch();
      expect(launchedCalls, <(String, bool)>[('ok_emu', true), ('bad_emu', false)]);
      expect(logger.errorText, contains('Failed to launch emulator "bad_emu".'));

      logger.clear();
      final throwingEmulator = ExtensionEmulator(
        deviceService: _ThrowingEmulatorDeviceService(),
        logger: logger,
        targetEmulator: const TargetEmulator(id: 'throwing_emu', name: 'Throwing Emulator'),
      );
      await throwingEmulator.launch(coldBoot: true);
      expect(logger.errorText, contains('Failed to launch emulator "throwing_emu".'));
    });

    test('EmulatorManager includes ExtensionEmulators when tool extensions are enabled', () async {
      void entryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            _TestEmulatorDeviceService(
              emulators: const <TargetEmulator>[
                TargetEmulator(id: 'ext_emu', name: 'Extension Emulator'),
              ],
            ),
          ],
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
      final extensionManager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: featureFlags,
        entryPoints: <ExtensionEntryPoint>[entryPoint],
      );
      addTearDown(extensionManager.dispose);

      final emulatorManager = EmulatorManager(
        androidWorkflow: AndroidWorkflow(androidSdkBuilder: () => null, featureFlags: featureFlags),
        extensionManager: extensionManager,
        featureFlags: featureFlags,
        fileSystem: MemoryFileSystem.test(),
        javaBuilder: () => null,
        logger: logger,
        processManager: FakeProcessManager.empty(),
      );

      final List<Emulator> matching = await emulatorManager.getEmulatorsMatching('ext_emu');
      expect(matching, hasLength(1));
      expect(matching.single.id, 'ext_emu');
      expect(matching.single.name, 'Extension Emulator');
    });
  });
}

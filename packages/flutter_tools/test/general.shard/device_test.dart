// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../src/common.dart';
import '../src/context.dart';
import '../src/fake_devices.dart';
import '../src/mocks.dart';

void main() {
  MockCache cache;
  BufferLogger logger;

  setUp(() {
    cache = MockCache();
    logger = BufferLogger.test();
    when(cache.dyLdLibEntry).thenReturn(const MapEntry<String, String>('foo', 'bar'));
  });

  group('DeviceManager', () {
    testUsingContext('getDevices', () async {
      final FakeDevice device1 = FakeDevice('Nexus 5', '0553790d0a4e726f');
      final FakeDevice device2 = FakeDevice('Nexus 5X', '01abfc49119c410e');
      final FakeDevice device3 = FakeDevice('iPod touch', '82564b38861a9a5');
      final List<Device> devices = <Device>[device1, device2, device3];
      final DeviceManager deviceManager = TestDeviceManager(devices);
      expect(await deviceManager.getDevices(), devices);
    }, overrides: <Type, Generator>{
      Artifacts: () => Artifacts.test(),
      Cache: () => cache,
    });

    testUsingContext('getDeviceById exact matcher', () async {
      final FakeDevice device1 = FakeDevice('Nexus 5', '0553790d0a4e726f');
      final FakeDevice device2 = FakeDevice('Nexus 5X', '01abfc49119c410e');
      final FakeDevice device3 = FakeDevice('iPod touch', '82564b38861a9a5');
      final List<Device> devices = <Device>[device1, device2, device3];

      // Include different device discoveries:
      // 1. One that never completes to prove the first exact match is
      // returned quickly.
      // 2. One that throws, to prove matches can return when some succeed
      // and others fail.
      // 3. A device discoverer that succeeds.
      final DeviceManager deviceManager = TestDeviceManager(
        devices,
        deviceDiscoveryOverrides: <DeviceDiscovery>[
          ThrowingPollingDeviceDiscovery(),
          LongPollingDeviceDiscovery(),
        ],
      );

      Future<void> expectDevice(String id, List<Device> expected) async {
        expect(await deviceManager.getDevicesById(id), expected);
      }
      await expectDevice('01abfc49119c410e', <Device>[device2]);
      expect(logger.traceText, contains('Ignored error discovering 01abfc49119c410e'));
      await expectDevice('Nexus 5X', <Device>[device2]);
      expect(logger.traceText, contains('Ignored error discovering Nexus 5X'));
      await expectDevice('0553790d0a4e726f', <Device>[device1]);
      expect(logger.traceText, contains('Ignored error discovering 0553790d0a4e726f'));
    }, overrides: <Type, Generator>{
      Artifacts: () => Artifacts.test(),
      Cache: () => cache,
      Logger: () => logger,
    });

    testUsingContext('getDeviceById prefix matcher', () async {
      final FakeDevice device1 = FakeDevice('Nexus 5', '0553790d0a4e726f');
      final FakeDevice device2 = FakeDevice('Nexus 5X', '01abfc49119c410e');
      final FakeDevice device3 = FakeDevice('iPod touch', '82564b38861a9a5');
      final List<Device> devices = <Device>[device1, device2, device3];

      // Include different device discoveries:
      // 1. One that throws, to prove matches can return when some succeed
      // and others fail.
      // 2. A device discoverer that succeeds.
      final DeviceManager deviceManager = TestDeviceManager(
        devices,
        deviceDiscoveryOverrides: <DeviceDiscovery>[
          ThrowingPollingDeviceDiscovery(),
        ],
      );

      Future<void> expectDevice(String id, List<Device> expected) async {
        expect(await deviceManager.getDevicesById(id), expected);
      }
      await expectDevice('Nexus 5', <Device>[device1]);
      expect(logger.traceText, contains('Ignored error discovering Nexus 5'));
      await expectDevice('0553790', <Device>[device1]);
      expect(logger.traceText, contains('Ignored error discovering 0553790'));
      await expectDevice('Nexus', <Device>[device1, device2]);
      expect(logger.traceText, contains('Ignored error discovering Nexus'));
    }, overrides: <Type, Generator>{
      Artifacts: () => Artifacts.test(),
      Cache: () => cache,
      Logger: () => logger,
    });

    testUsingContext('getAllConnectedDevices caches', () async {
      final FakeDevice device1 = FakeDevice('Nexus 5', '0553790d0a4e726f');
      final TestDeviceManager deviceManager = TestDeviceManager(<Device>[device1]);
      expect(await deviceManager.getAllConnectedDevices(), <Device>[device1]);

      final FakeDevice device2 = FakeDevice('Nexus 5X', '01abfc49119c410e');
      deviceManager.resetDevices(<Device>[device2]);
      expect(await deviceManager.getAllConnectedDevices(), <Device>[device1]);
    }, overrides: <Type, Generator>{
      Artifacts: () => Artifacts.test(),
      Cache: () => cache,
    });

    testUsingContext('refreshAllConnectedDevices does not cache', () async {
      final FakeDevice device1 = FakeDevice('Nexus 5', '0553790d0a4e726f');
      final TestDeviceManager deviceManager = TestDeviceManager(<Device>[device1]);
      expect(await deviceManager.refreshAllConnectedDevices(), <Device>[device1]);

      final FakeDevice device2 = FakeDevice('Nexus 5X', '01abfc49119c410e');
      deviceManager.resetDevices(<Device>[device2]);
      expect(await deviceManager.refreshAllConnectedDevices(), <Device>[device2]);
    }, overrides: <Type, Generator>{
      Artifacts: () => Artifacts.test(),
      Cache: () => cache,
    });
  });

  group('PollingDeviceDiscovery', () {
    testUsingContext('startPolling', () async {
      await FakeAsync().run((FakeAsync time) async {
        final FakePollingDeviceDiscovery pollingDeviceDiscovery = FakePollingDeviceDiscovery();
        await pollingDeviceDiscovery.startPolling();
        time.elapse(const Duration(milliseconds: 4001));
        time.flushMicrotasks();
        // First check should use the default polling timeout
        // to quickly populate the list.
        expect(pollingDeviceDiscovery.lastPollingTimeout, isNull);

        time.elapse(const Duration(milliseconds: 4001));
        time.flushMicrotasks();
        // Subsequent polling should be much longer.
        expect(pollingDeviceDiscovery.lastPollingTimeout, const Duration(seconds: 30));
        await pollingDeviceDiscovery.stopPolling();
      });
    }, overrides: <Type, Generator>{
      Artifacts: () => Artifacts.test(),
      Cache: () => cache,
    }, skip: true); // TODO(jonahwilliams): clean up with https://github.com/flutter/flutter/issues/60675
  });

  group('Filter devices', () {
    FakeDevice ephemeralOne;
    FakeDevice ephemeralTwo;
    FakeDevice nonEphemeralOne;
    FakeDevice nonEphemeralTwo;
    FakeDevice unsupported;
    FakeDevice webDevice;
    FakeDevice fuchsiaDevice;
    MockStdio mockStdio;

    setUp(() {
      ephemeralOne = FakeDevice('ephemeralOne', 'ephemeralOne', true);
      ephemeralTwo = FakeDevice('ephemeralTwo', 'ephemeralTwo', true);
      nonEphemeralOne = FakeDevice('nonEphemeralOne', 'nonEphemeralOne', false);
      nonEphemeralTwo = FakeDevice('nonEphemeralTwo', 'nonEphemeralTwo', false);
      unsupported = FakeDevice('unsupported', 'unsupported', true, false);
      webDevice = FakeDevice('webby', 'webby')
        ..targetPlatform = Future<TargetPlatform>.value(TargetPlatform.web_javascript);
      fuchsiaDevice = FakeDevice('fuchsiay', 'fuchsiay')
        ..targetPlatform = Future<TargetPlatform>.value(TargetPlatform.fuchsia_x64);
      mockStdio = MockStdio();
    });

    testUsingContext('chooses ephemeral device', () async {
      final List<Device> devices = <Device>[
        ephemeralOne,
        nonEphemeralOne,
        nonEphemeralTwo,
        unsupported,
      ];

      final DeviceManager deviceManager = TestDeviceManager(devices);
      final List<Device> filtered = await deviceManager.findTargetDevices(FlutterProject.current());

      expect(filtered.single, ephemeralOne);
    }, overrides: <Type, Generator>{
      Artifacts: () => Artifacts.test(),
      Cache: () => cache,
    });

    testUsingContext('choose first non-ephemeral device', () async {
      final List<Device> devices = <Device>[
        nonEphemeralOne,
        nonEphemeralTwo,
      ];

      when(mockStdio.stdinHasTerminal).thenReturn(true);
      when(globals.terminal.promptForCharInput(<String>['0', '1', 'q', 'Q'],
      displayAcceptedCharacters: false,
      logger: globals.logger,
      prompt: globals.userMessages.flutterChooseOne)
      ).thenAnswer((Invocation invocation) async => '0');

      final DeviceManager deviceManager = TestDeviceManager(devices);
      final List<Device> filtered = await deviceManager.findTargetDevices(FlutterProject.current());

      expect(filtered, <Device>[
        nonEphemeralOne
      ]);
    }, overrides: <Type, Generator>{
      Artifacts: () => Artifacts.test(),
      Stdio: () => mockStdio,
      AnsiTerminal: () => MockTerminal(),
    });

    testUsingContext('choose second non-ephemeral device', () async {
      final List<Device> devices = <Device>[
        nonEphemeralOne,
        nonEphemeralTwo,
      ];

      when(mockStdio.stdinHasTerminal).thenReturn(true);
      when(globals.terminal.promptForCharInput(<String>['0', '1', 'q', 'Q'],
          displayAcceptedCharacters: false,
          logger: globals.logger,
      prompt: globals.userMessages.flutterChooseOne)
      ).thenAnswer((Invocation invocation) async => '1');

      final DeviceManager deviceManager = TestDeviceManager(devices);
      final List<Device> filtered = await deviceManager.findTargetDevices(FlutterProject.current());

      expect(filtered, <Device>[
        nonEphemeralTwo
      ]);
    }, overrides: <Type, Generator>{
      Artifacts: () => Artifacts.test(),
      Stdio: () => mockStdio,
      AnsiTerminal: () => MockTerminal(),
    });

    testUsingContext('choose first ephemeral device', () async {
      final List<Device> devices = <Device>[
        ephemeralOne,
        ephemeralTwo,
      ];

      when(mockStdio.stdinHasTerminal).thenReturn(true);
      when(globals.terminal.promptForCharInput(<String>['0', '1', 'q', 'Q'],
          displayAcceptedCharacters: false,
          logger: globals.logger,
        prompt: globals.userMessages.flutterChooseOne)
      ).thenAnswer((Invocation invocation) async => '0');

      final DeviceManager deviceManager = TestDeviceManager(devices);
      final List<Device> filtered = await deviceManager.findTargetDevices(FlutterProject.current());

      expect(filtered, <Device>[
        ephemeralOne
      ]);
    }, overrides: <Type, Generator>{
      Artifacts: () => Artifacts.test(),
      Stdio: () => mockStdio,
      AnsiTerminal: () => MockTerminal(),
    });

    testUsingContext('choose second ephemeral device', () async {
      final List<Device> devices = <Device>[
        ephemeralOne,
        ephemeralTwo,
      ];

      when(mockStdio.stdinHasTerminal).thenReturn(true);
      when(globals.terminal.promptForCharInput(<String>['0', '1', 'q', 'Q'],
          displayAcceptedCharacters: false,
          logger: globals.logger,
        prompt: globals.userMessages.flutterChooseOne)
      ).thenAnswer((Invocation invocation) async => '1');

      final DeviceManager deviceManager = TestDeviceManager(devices);
      final List<Device> filtered = await deviceManager.findTargetDevices(FlutterProject.current());

      expect(filtered, <Device>[
        ephemeralTwo
      ]);
    }, overrides: <Type, Generator>{
      Stdio: () => mockStdio,
      AnsiTerminal: () => MockTerminal(),
      Artifacts: () => Artifacts.test(),
      Cache: () => cache,
    });

    testUsingContext('choose non-ephemeral device', () async {
      final List<Device> devices = <Device>[
        ephemeralOne,
        ephemeralTwo,
        nonEphemeralOne,
        nonEphemeralTwo,
      ];

      when(mockStdio.stdinHasTerminal).thenReturn(true);
      when(globals.terminal.promptForCharInput(<String>['0', '1', '2', '3', 'q', 'Q'],
        displayAcceptedCharacters: false,
        logger: globals.logger,
        prompt: globals.userMessages.flutterChooseOne)
      ).thenAnswer((Invocation invocation) async => '2');

      final DeviceManager deviceManager = TestDeviceManager(devices);
      final List<Device> filtered = await deviceManager.findTargetDevices(FlutterProject.current());

      expect(filtered, <Device>[
        nonEphemeralOne
      ]);
    }, overrides: <Type, Generator>{
      Stdio: () => mockStdio,
      AnsiTerminal: () => MockTerminal(),
      Artifacts: () => Artifacts.test(),
      Cache: () => cache,
    });

    testUsingContext('exit from choose one of available devices', () async {
      final List<Device> devices = <Device>[
        ephemeralOne,
        ephemeralTwo,
      ];

      when(mockStdio.stdinHasTerminal).thenReturn(true);
      when(globals.terminal.promptForCharInput(<String>['0', '1', 'q', 'Q'],
          displayAcceptedCharacters: false,
          logger: globals.logger,
          prompt: globals.userMessages.flutterChooseOne)
      ).thenAnswer((Invocation invocation) async => 'q');

      try {
        final DeviceManager deviceManager = TestDeviceManager(devices);
        await deviceManager.findTargetDevices(FlutterProject.current());
      } on ToolExit catch (e) {
        expect(e.exitCode, null);
        expect(e.message, '');
      }
    }, overrides: <Type, Generator>{
      Stdio: () => mockStdio,
      AnsiTerminal: () => MockTerminal(),
      Artifacts: () => Artifacts.test(),
      Cache: () => cache,
    });

    testUsingContext('Removes a single unsupported device', () async {
      final List<Device> devices = <Device>[
        unsupported,
      ];

      final DeviceManager deviceManager = TestDeviceManager(devices);
      final List<Device> filtered = await deviceManager.findTargetDevices(FlutterProject.current());

      expect(filtered, <Device>[]);
    }, overrides: <Type, Generator>{
      Artifacts: () => Artifacts.test(),
      Cache: () => cache,
    });

    testUsingContext('Removes web and fuchsia from --all', () async {
      final List<Device> devices = <Device>[
        webDevice,
        fuchsiaDevice,
      ];
      final DeviceManager deviceManager = TestDeviceManager(devices);
      deviceManager.specifiedDeviceId = 'all';

      final List<Device> filtered = await deviceManager.findTargetDevices(FlutterProject.current());

      expect(filtered, <Device>[]);
    }, overrides: <Type, Generator>{
      Artifacts: () => Artifacts.test(),
      Cache: () => cache,
    });

    testUsingContext('Removes unsupported devices from --all', () async {
      final List<Device> devices = <Device>[
        nonEphemeralOne,
        nonEphemeralTwo,
        unsupported,
      ];
      final DeviceManager deviceManager = TestDeviceManager(devices);
      deviceManager.specifiedDeviceId = 'all';

      final List<Device> filtered = await deviceManager.findTargetDevices(FlutterProject.current());

      expect(filtered, <Device>[
        nonEphemeralOne,
        nonEphemeralTwo,
      ]);
    }, overrides: <Type, Generator>{
      Artifacts: () => Artifacts.test(),
      Cache: () => cache,
    });

    testUsingContext('uses DeviceManager.isDeviceSupportedForProject instead of device.isSupportedForProject', () async {
      final List<Device> devices = <Device>[
        unsupported,
      ];
      final TestDeviceManager deviceManager = TestDeviceManager(devices);
      deviceManager.isAlwaysSupportedOverride = true;

      final List<Device> filtered = await deviceManager.findTargetDevices(FlutterProject.current());

      expect(filtered, <Device>[
        unsupported,
      ]);
    }, overrides: <Type, Generator>{
      Artifacts: () => Artifacts.test(),
      Cache: () => cache,
    });

    testUsingContext('does not refresh device cache without a timeout', () async {
      final List<Device> devices = <Device>[
        ephemeralOne,
      ];
      final MockDeviceDiscovery mockDeviceDiscovery = MockDeviceDiscovery();
      when(mockDeviceDiscovery.supportsPlatform).thenReturn(true);
      // when(mockDeviceDiscovery.discoverDevices(timeout: timeout)).thenAnswer((_) async => devices);
      when(mockDeviceDiscovery.devices).thenAnswer((_) async => devices);
      // when(mockDeviceDiscovery.discoverDevices(timeout: timeout)).thenAnswer((_) async => devices);

      final DeviceManager deviceManager = TestDeviceManager(<Device>[], deviceDiscoveryOverrides: <DeviceDiscovery>[
        mockDeviceDiscovery
      ]);
      deviceManager.specifiedDeviceId = ephemeralOne.id;
      final List<Device> filtered = await deviceManager.findTargetDevices(
        FlutterProject.current(),
      );

      expect(filtered.single, ephemeralOne);
      verify(mockDeviceDiscovery.devices).called(1);
      verifyNever(mockDeviceDiscovery.discoverDevices(timeout: anyNamed('timeout')));
    }, overrides: <Type, Generator>{
      Artifacts: () => Artifacts.test(),
      Cache: () => cache,
    });

    testUsingContext('refreshes device cache with a timeout', () async {
      final List<Device> devices = <Device>[
        ephemeralOne,
      ];
      const Duration timeout = Duration(seconds: 2);
      final MockDeviceDiscovery mockDeviceDiscovery = MockDeviceDiscovery();
      when(mockDeviceDiscovery.supportsPlatform).thenReturn(true);
      when(mockDeviceDiscovery.discoverDevices(timeout: timeout)).thenAnswer((_) async => devices);
      when(mockDeviceDiscovery.devices).thenAnswer((_) async => devices);
      // when(mockDeviceDiscovery.discoverDevices(timeout: timeout)).thenAnswer((_) async => devices);

      final DeviceManager deviceManager = TestDeviceManager(<Device>[], deviceDiscoveryOverrides: <DeviceDiscovery>[
        mockDeviceDiscovery
      ]);
      deviceManager.specifiedDeviceId = ephemeralOne.id;
      final List<Device> filtered = await deviceManager.findTargetDevices(
        FlutterProject.current(),
        timeout: timeout,
      );

      expect(filtered.single, ephemeralOne);
      verify(mockDeviceDiscovery.devices).called(1);
      verify(mockDeviceDiscovery.discoverDevices(timeout: anyNamed('timeout'))).called(1);
    }, overrides: <Type, Generator>{
      Artifacts: () => Artifacts.test(),
      Cache: () => cache,
    });
  });

  group('ForwardedPort', () {
    group('dispose()', () {
      testUsingContext('does not throw exception if no process is present', () {
        final ForwardedPort forwardedPort = ForwardedPort(123, 456);
        expect(forwardedPort.context, isNull);
        forwardedPort.dispose();
      });

      testUsingContext('kills process if process was available', () {
        final MockProcess mockProcess = MockProcess();
        final ForwardedPort forwardedPort = ForwardedPort.withContext(123, 456, mockProcess);
        forwardedPort.dispose();
        expect(forwardedPort.context, isNotNull);
        verify(mockProcess.kill());
      });
    });
  });

  group('JSON encode devices', () {
    testUsingContext('Consistency of JSON representation', () async {
      expect(
        // This tests that fakeDevices is a list of tuples where "second" is the
        // correct JSON representation of the "first". Actual values are irrelevant
        await Future.wait(fakeDevices.map((FakeDeviceJsonData d) => d.dev.toJson())),
        fakeDevices.map((FakeDeviceJsonData d) => d.json)
      );
    });
  });

  testWithoutContext('computeDartVmFlags handles various combinations of Dart VM flags and null_assertions', () {
    expect(computeDartVmFlags(DebuggingOptions.enabled(BuildInfo.debug, dartFlags: null)), '');
    expect(computeDartVmFlags(DebuggingOptions.enabled(BuildInfo.debug, dartFlags: '--foo')), '--foo');
    expect(computeDartVmFlags(DebuggingOptions.enabled(BuildInfo.debug, dartFlags: '', nullAssertions: true)), '--null_assertions');
    expect(computeDartVmFlags(DebuggingOptions.enabled(BuildInfo.debug, dartFlags: '--foo', nullAssertions: true)), '--foo,--null_assertions');
  });
}

class TestDeviceManager extends DeviceManager {
    TestDeviceManager(List<Device> allDevices, {
    List<DeviceDiscovery> deviceDiscoveryOverrides,
  }) {
    _fakeDeviceDiscoverer = FakePollingDeviceDiscovery();
    _deviceDiscoverers = <DeviceDiscovery>[
      _fakeDeviceDiscoverer,
      if (deviceDiscoveryOverrides != null)
        ...deviceDiscoveryOverrides
    ];
    resetDevices(allDevices);
  }
  @override
  List<DeviceDiscovery> get deviceDiscoverers => _deviceDiscoverers;
  List<DeviceDiscovery> _deviceDiscoverers;
  FakePollingDeviceDiscovery _fakeDeviceDiscoverer;

  void resetDevices(List<Device> allDevices) {
    _fakeDeviceDiscoverer.setDevices(allDevices);
  }

  bool isAlwaysSupportedOverride;

  @override
  bool isDeviceSupportedForProject(Device device, FlutterProject flutterProject) {
    if (isAlwaysSupportedOverride != null) {
      return isAlwaysSupportedOverride;
    }
    return super.isDeviceSupportedForProject(device, flutterProject);
  }
}

class MockProcess extends Mock implements Process {}
class MockTerminal extends Mock implements AnsiTerminal {}
class MockStdio extends Mock implements Stdio {}
class MockCache extends Mock implements Cache {}
class MockDeviceDiscovery extends Mock implements DeviceDiscovery {}

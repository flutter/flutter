// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:meta/meta.dart';
import 'package:test/fake.dart';

import '../src/common.dart';
import '../src/fake_devices.dart';

void main() {
  group('DeviceManager', () {
    testWithoutContext('getDevices', () async {
      final FakeDevice device1 = FakeDevice('Nexus 5', '0553790d0a4e726f');
      final FakeDevice device2 = FakeDevice('Nexus 5X', '01abfc49119c410e');
      final FakeDevice device3 = FakeDevice('iPod touch', '82564b38861a9a5');
      final List<Device> devices = <Device>[device1, device2, device3];

      final DeviceManager deviceManager = TestDeviceManager(
        devices,
        logger: BufferLogger.test(),
        terminal: Terminal.test(),
      );

      expect(await deviceManager.getDevices(), devices);
    });

    testWithoutContext('getDeviceById exact matcher', () async {
      final FakeDevice device1 = FakeDevice('Nexus 5', '0553790d0a4e726f');
      final FakeDevice device2 = FakeDevice('Nexus 5X', '01abfc49119c410e');
      final FakeDevice device3 = FakeDevice('iPod touch', '82564b38861a9a5');
      final List<Device> devices = <Device>[device1, device2, device3];
      final BufferLogger logger = BufferLogger.test();

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
        logger: logger,
        terminal: Terminal.test(),
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
    });

    testWithoutContext('getDeviceById exact matcher with well known ID', () async {
      final FakeDevice device1 = FakeDevice('Windows', 'windows');
      final FakeDevice device2 = FakeDevice('Nexus 5X', '01abfc49119c410e');
      final FakeDevice device3 = FakeDevice('iPod touch', '82564b38861a9a5');
      final List<Device> devices = <Device>[device1, device2, device3];
      final BufferLogger logger = BufferLogger.test();

      // Because the well known ID will match, no other device discovery will run.
      final DeviceManager deviceManager = TestDeviceManager(
        devices,
        deviceDiscoveryOverrides: <DeviceDiscovery>[
          ThrowingPollingDeviceDiscovery(),
          LongPollingDeviceDiscovery(),
        ],
        logger: logger,
        terminal: Terminal.test(),
        wellKnownId: 'windows',
      );

      Future<void> expectDevice(String id, List<Device> expected) async {
        deviceManager.specifiedDeviceId = id;
        expect(await deviceManager.getDevicesById(id), expected);
      }
      await expectDevice('windows', <Device>[device1]);
      expect(logger.traceText, isEmpty);
    });

    testWithoutContext('getDeviceById prefix matcher', () async {
      final FakeDevice device1 = FakeDevice('Nexus 5', '0553790d0a4e726f');
      final FakeDevice device2 = FakeDevice('Nexus 5X', '01abfc49119c410e');
      final FakeDevice device3 = FakeDevice('iPod touch', '82564b38861a9a5');
      final List<Device> devices = <Device>[device1, device2, device3];
      final BufferLogger logger = BufferLogger.test();

      // Include different device discoveries:
      // 1. One that throws, to prove matches can return when some succeed
      // and others fail.
      // 2. A device discoverer that succeeds.
      final DeviceManager deviceManager = TestDeviceManager(
        devices,
        deviceDiscoveryOverrides: <DeviceDiscovery>[
          ThrowingPollingDeviceDiscovery(),
        ],
        logger: logger,
        terminal: Terminal.test(),
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
    });

    testWithoutContext('getAllConnectedDevices caches', () async {
      final FakeDevice device1 = FakeDevice('Nexus 5', '0553790d0a4e726f');
      final TestDeviceManager deviceManager = TestDeviceManager(
        <Device>[device1],
        logger: BufferLogger.test(),
        terminal: Terminal.test(),
      );
      expect(await deviceManager.getAllConnectedDevices(), <Device>[device1]);

      final FakeDevice device2 = FakeDevice('Nexus 5X', '01abfc49119c410e');
      deviceManager.resetDevices(<Device>[device2]);
      expect(await deviceManager.getAllConnectedDevices(), <Device>[device1]);
    });

    testWithoutContext('refreshAllConnectedDevices does not cache', () async {
      final FakeDevice device1 = FakeDevice('Nexus 5', '0553790d0a4e726f');
      final TestDeviceManager deviceManager = TestDeviceManager(
        <Device>[device1],
        logger: BufferLogger.test(),
        terminal: Terminal.test(),
      );
      expect(await deviceManager.refreshAllConnectedDevices(), <Device>[device1]);

      final FakeDevice device2 = FakeDevice('Nexus 5X', '01abfc49119c410e');
      deviceManager.resetDevices(<Device>[device2]);
      expect(await deviceManager.refreshAllConnectedDevices(), <Device>[device2]);
    });
  });

  testWithoutContext('PollingDeviceDiscovery startPolling', () {
    FakeAsync().run((FakeAsync time) {
      final FakePollingDeviceDiscovery pollingDeviceDiscovery = FakePollingDeviceDiscovery();
      pollingDeviceDiscovery.startPolling();
      time.elapse(const Duration(milliseconds: 4001));

      // First check should use the default polling timeout
      // to quickly populate the list.
      expect(pollingDeviceDiscovery.lastPollingTimeout, isNull);

      time.elapse(const Duration(milliseconds: 4001));

      // Subsequent polling should be much longer.
      expect(pollingDeviceDiscovery.lastPollingTimeout, const Duration(seconds: 30));
      pollingDeviceDiscovery.stopPolling();
    });
  });

  group('Filter devices', () {
    final FakeDevice ephemeralOne = FakeDevice('ephemeralOne', 'ephemeralOne');
    final FakeDevice ephemeralTwo = FakeDevice('ephemeralTwo', 'ephemeralTwo');
    final FakeDevice nonEphemeralOne = FakeDevice('nonEphemeralOne', 'nonEphemeralOne', ephemeral: false);
    final FakeDevice nonEphemeralTwo = FakeDevice('nonEphemeralTwo', 'nonEphemeralTwo', ephemeral: false);
    final FakeDevice unsupported = FakeDevice('unsupported', 'unsupported', isSupported: false);
    final FakeDevice webDevice = FakeDevice('webby', 'webby')
      ..targetPlatform = Future<TargetPlatform>.value(TargetPlatform.web_javascript);
    final FakeDevice fuchsiaDevice = FakeDevice('fuchsiay', 'fuchsiay')
      ..targetPlatform = Future<TargetPlatform>.value(TargetPlatform.fuchsia_x64);

    testWithoutContext('chooses ephemeral device', () async {
      final List<Device> devices = <Device>[
        ephemeralOne,
        nonEphemeralOne,
        nonEphemeralTwo,
        unsupported,
      ];

      final DeviceManager deviceManager = TestDeviceManager(
        devices,
        logger: BufferLogger.test(),
        terminal: Terminal.test(),
      );
      final List<Device> filtered = await deviceManager.findTargetDevices(FakeFlutterProject());

      expect(filtered.single, ephemeralOne);
    });

    testWithoutContext('choose first non-ephemeral device', () async {
      final List<Device> devices = <Device>[
        nonEphemeralOne,
        nonEphemeralTwo,
      ];
      final FakeTerminal terminal = FakeTerminal()
        ..setPrompt(<String>['1', '2', 'q', 'Q'], '1');

      final DeviceManager deviceManager = TestDeviceManager(
        devices,
        logger: BufferLogger.test(),
        terminal: terminal,
      );
      final List<Device> filtered = await deviceManager.findTargetDevices(FakeFlutterProject());

      expect(filtered, <Device>[
        nonEphemeralOne
      ]);
    });

    testWithoutContext('choose second non-ephemeral device', () async {
      final List<Device> devices = <Device>[
        nonEphemeralOne,
        nonEphemeralTwo,
      ];
      final FakeTerminal terminal = FakeTerminal()
        ..setPrompt(<String>['1', '2', 'q', 'Q'], '2');

      final DeviceManager deviceManager = TestDeviceManager(
        devices,
        logger: BufferLogger.test(),
        terminal: terminal,
      );
      final List<Device> filtered = await deviceManager.findTargetDevices(FakeFlutterProject());

      expect(filtered, <Device>[
        nonEphemeralTwo
      ]);
    });

    testWithoutContext('choose first ephemeral device', () async {
      final List<Device> devices = <Device>[
        ephemeralOne,
        ephemeralTwo,
      ];

      final FakeTerminal terminal = FakeTerminal()
        ..setPrompt(<String>['1', '2', 'q', 'Q'], '1');

      final DeviceManager deviceManager = TestDeviceManager(
        devices,
        logger: BufferLogger.test(),
        terminal: terminal,
      );
      final List<Device> filtered = await deviceManager.findTargetDevices(FakeFlutterProject());

      expect(filtered, <Device>[
        ephemeralOne
      ]);
    });

    testWithoutContext('choose second ephemeral device', () async {
      final List<Device> devices = <Device>[
        ephemeralOne,
        ephemeralTwo,
      ];
      final FakeTerminal terminal = FakeTerminal()
        ..setPrompt(<String>['1', '2', 'q', 'Q'], '2');

      final DeviceManager deviceManager = TestDeviceManager(
        devices,
        logger: BufferLogger.test(),
        terminal: terminal,
      );
      final List<Device> filtered = await deviceManager.findTargetDevices(FakeFlutterProject());

      expect(filtered, <Device>[
        ephemeralTwo
      ]);
    });

    testWithoutContext('choose non-ephemeral device', () async {
      final List<Device> devices = <Device>[
        ephemeralOne,
        ephemeralTwo,
        nonEphemeralOne,
        nonEphemeralTwo,
      ];

      final FakeTerminal terminal = FakeTerminal()
        ..setPrompt(<String>['1', '2', '3', '4', 'q', 'Q'], '3');

      final DeviceManager deviceManager = TestDeviceManager(
        devices,
        logger: BufferLogger.test(),
        terminal: terminal,
      );

      final List<Device> filtered = await deviceManager.findTargetDevices(FakeFlutterProject());

      expect(filtered, <Device>[
        nonEphemeralOne
      ]);
    });

    testWithoutContext('exit from choose one of available devices', () async {
      final List<Device> devices = <Device>[
        ephemeralOne,
        ephemeralTwo,
      ];

      final FakeTerminal terminal = FakeTerminal()
        ..setPrompt(<String>['1', '2', 'q', 'Q'], 'q');

      final DeviceManager deviceManager = TestDeviceManager(
        devices,
        logger: BufferLogger.test(),
        terminal: terminal,
      );
      await expectLater(
        () async => deviceManager.findTargetDevices(FakeFlutterProject()),
        throwsToolExit(),
      );
    });

    testWithoutContext('Removes a single unsupported device', () async {
      final List<Device> devices = <Device>[
        unsupported,
      ];

      final DeviceManager deviceManager = TestDeviceManager(
        devices,
        logger: BufferLogger.test(),
        terminal: Terminal.test(),
      );
      final List<Device> filtered = await deviceManager.findTargetDevices(FakeFlutterProject());

      expect(filtered, <Device>[]);
    });

    testWithoutContext('Does not remove an unsupported device if FlutterProject is null', () async {
      final List<Device> devices = <Device>[
        unsupported,
      ];

      final DeviceManager deviceManager = TestDeviceManager(
        devices,
        logger: BufferLogger.test(),
        terminal: Terminal.test(),
      );
      final List<Device> filtered = await deviceManager.findTargetDevices(null);

      expect(filtered, <Device>[unsupported]);
    });

    testWithoutContext('Removes web and fuchsia from --all', () async {
      final List<Device> devices = <Device>[
        webDevice,
        fuchsiaDevice,
      ];
      final DeviceManager deviceManager = TestDeviceManager(
        devices,
        logger: BufferLogger.test(),
        terminal: Terminal.test(),
      );
      deviceManager.specifiedDeviceId = 'all';

      final List<Device> filtered = await deviceManager.findTargetDevices(FakeFlutterProject());

      expect(filtered, <Device>[]);
    });

    testWithoutContext('Removes unsupported devices from --all', () async {
      final List<Device> devices = <Device>[
        nonEphemeralOne,
        nonEphemeralTwo,
        unsupported,
      ];
      final DeviceManager deviceManager = TestDeviceManager(
        devices,
        logger: BufferLogger.test(),
        terminal: Terminal.test(),
      );
      deviceManager.specifiedDeviceId = 'all';

      final List<Device> filtered = await deviceManager.findTargetDevices(FakeFlutterProject());

      expect(filtered, <Device>[
        nonEphemeralOne,
        nonEphemeralTwo,
      ]);
    });

    testWithoutContext('uses DeviceManager.isDeviceSupportedForProject instead of device.isSupportedForProject', () async {
      final List<Device> devices = <Device>[
        unsupported,
      ];
      final TestDeviceManager deviceManager = TestDeviceManager(
        devices,
        logger: BufferLogger.test(),
        terminal: Terminal.test(),
      );
      deviceManager.isAlwaysSupportedOverride = true;

      final List<Device> filtered = await deviceManager.findTargetDevices(FakeFlutterProject());

      expect(filtered, <Device>[
        unsupported,
      ]);
    });

    testWithoutContext('does not refresh device cache without a timeout', () async {
      final List<Device> devices = <Device>[
        ephemeralOne,
      ];
      final MockDeviceDiscovery deviceDiscovery = MockDeviceDiscovery()
        ..deviceValues = devices;

      final DeviceManager deviceManager = TestDeviceManager(
        <Device>[],
        deviceDiscoveryOverrides: <DeviceDiscovery>[
          deviceDiscovery
        ],
        logger: BufferLogger.test(),
        terminal: Terminal.test(),
      );
      deviceManager.specifiedDeviceId = ephemeralOne.id;
      final List<Device> filtered = await deviceManager.findTargetDevices(
        FakeFlutterProject(),
      );

      expect(filtered.single, ephemeralOne);
      expect(deviceDiscovery.devicesCalled, 1);
      expect(deviceDiscovery.discoverDevicesCalled, 0);
    });

    testWithoutContext('refreshes device cache with a timeout', () async {
      final List<Device> devices = <Device>[
        ephemeralOne,
      ];
      const Duration timeout = Duration(seconds: 2);
      final MockDeviceDiscovery deviceDiscovery = MockDeviceDiscovery()
        ..deviceValues = devices;

      final DeviceManager deviceManager = TestDeviceManager(
        <Device>[],
        deviceDiscoveryOverrides: <DeviceDiscovery>[
          deviceDiscovery
        ],
        logger: BufferLogger.test(),
        terminal: Terminal.test(),
      );
      deviceManager.specifiedDeviceId = ephemeralOne.id;
      final List<Device> filtered = await deviceManager.findTargetDevices(
        FakeFlutterProject(),
        timeout: timeout,
      );

      expect(filtered.single, ephemeralOne);
      expect(deviceDiscovery.devicesCalled, 1);
      expect(deviceDiscovery.discoverDevicesCalled, 1);
    });
  });

  group('JSON encode devices', () {
    testWithoutContext('Consistency of JSON representation', () async {
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
  TestDeviceManager(
    List<Device> allDevices, {
    List<DeviceDiscovery> deviceDiscoveryOverrides,
    @required Logger logger,
    @required Terminal terminal,
    String wellKnownId,
  }) : super(logger: logger, terminal: terminal, userMessages: UserMessages()) {
    _fakeDeviceDiscoverer = FakePollingDeviceDiscovery();
    if (wellKnownId != null) {
      _fakeDeviceDiscoverer.wellKnownIds.add(wellKnownId);
    }
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

class MockDeviceDiscovery extends Fake implements DeviceDiscovery {
  int devicesCalled = 0;
  int discoverDevicesCalled = 0;

  @override
  bool supportsPlatform = true;

  List<Device> deviceValues = <Device>[];

  @override
  Future<List<Device>> get devices async {
    devicesCalled += 1;
    return deviceValues;
  }

  @override
  Future<List<Device>> discoverDevices({Duration timeout}) async {
    discoverDevicesCalled += 1;
    return deviceValues;
  }

  @override
  List<String> get wellKnownIds => <String>[];
}

class FakeFlutterProject extends Fake implements FlutterProject { }

class LongPollingDeviceDiscovery extends PollingDeviceDiscovery {
  LongPollingDeviceDiscovery() : super('forever');

  final Completer<List<Device>> _completer = Completer<List<Device>>();

  @override
  Future<List<Device>> pollingGetDevices({ Duration timeout }) async {
    return _completer.future;
  }

  @override
  Future<void> stopPolling() async {
    _completer.complete();
  }

  @override
  Future<void> dispose() async {
    _completer.complete();
  }

  @override
  bool get supportsPlatform => true;

  @override
  bool get canListAnything => true;

  @override
  final List<String> wellKnownIds = <String>[];
}

class ThrowingPollingDeviceDiscovery extends PollingDeviceDiscovery {
  ThrowingPollingDeviceDiscovery() : super('throw');

  @override
  Future<List<Device>> pollingGetDevices({ Duration timeout }) async {
    throw const ProcessException('fake-discovery', <String>[]);
  }

  @override
  bool get supportsPlatform => true;

  @override
  bool get canListAnything => true;

  @override
  List<String> get wellKnownIds => <String>[];
}

class FakeTerminal extends Fake implements Terminal {
  @override
  bool stdinHasTerminal = true;

  @override
  bool usesTerminalUi = true;

  void setPrompt(List<String> characters, String result) {
    _nextPrompt = characters;
    _nextResult = result;
  }

  List<String> _nextPrompt;
  String _nextResult;

  @override
  Future<String> promptForCharInput(
    List<String> acceptedCharacters, {
    Logger logger,
    String prompt,
    int defaultChoiceIndex,
    bool displayAcceptedCharacters = true,
  }) async {
    expect(acceptedCharacters, _nextPrompt);
    return _nextResult;
  }
}

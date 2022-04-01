// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/base/utils.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/project.dart';
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
    final FakeDevice unsupportedForProject = FakeDevice('unsupportedForProject', 'unsupportedForProject', isSupportedForProject: false);
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
        unsupportedForProject,
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

    testWithoutContext('Unsupported devices listed in all connected devices', () async {
      final List<Device> devices = <Device>[
        unsupported,
        unsupportedForProject,
      ];

      final DeviceManager deviceManager = TestDeviceManager(
        devices,
        logger: BufferLogger.test(),
        terminal: Terminal.test(),
      );
      final List<Device> filtered = await deviceManager.getAllConnectedDevices();

      expect(filtered, <Device>[
        unsupported,
        unsupportedForProject,
      ]);
    });

    testWithoutContext('Removes a unsupported devices', () async {
      final List<Device> devices = <Device>[
        unsupported,
        unsupportedForProject,
      ];

      final DeviceManager deviceManager = TestDeviceManager(
        devices,
        logger: BufferLogger.test(),
        terminal: Terminal.test(),
      );
      final List<Device> filtered = await deviceManager.findTargetDevices(FakeFlutterProject());

      expect(filtered, <Device>[]);
    });

    testWithoutContext('Retains devices unsupported by the project if FlutterProject is null', () async {
      final List<Device> devices = <Device>[
        unsupported,
        unsupportedForProject,
      ];

      final DeviceManager deviceManager = TestDeviceManager(
        devices,
        logger: BufferLogger.test(),
        terminal: Terminal.test(),
      );
      final List<Device> filtered = await deviceManager.findTargetDevices(null);

      expect(filtered, <Device>[unsupportedForProject]);
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

    testWithoutContext('Removes devices unsupported by the project from --all', () async {
      final List<Device> devices = <Device>[
        nonEphemeralOne,
        nonEphemeralTwo,
        unsupported,
        unsupportedForProject,
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
        unsupportedForProject,
      ];
      final TestDeviceManager deviceManager = TestDeviceManager(
        devices,
        logger: BufferLogger.test(),
        terminal: Terminal.test(),
      );
      deviceManager.isAlwaysSupportedForProjectOverride = true;

      final List<Device> filtered = await deviceManager.findTargetDevices(FakeFlutterProject());

      expect(filtered, <Device>[
        unsupportedForProject,
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
    expect(computeDartVmFlags(DebuggingOptions.enabled(BuildInfo.debug)), '');
    expect(computeDartVmFlags(DebuggingOptions.enabled(BuildInfo.debug, dartFlags: '--foo')), '--foo');
    expect(computeDartVmFlags(DebuggingOptions.enabled(BuildInfo.debug, nullAssertions: true)), '--null_assertions');
    expect(computeDartVmFlags(DebuggingOptions.enabled(BuildInfo.debug, dartFlags: '--foo', nullAssertions: true)), '--foo,--null_assertions');
  });

  group('JSON encode DebuggingOptions', () {
    testWithoutContext('can preserve the original options', () {
      final DebuggingOptions original = DebuggingOptions.enabled(
        BuildInfo.debug,
        startPaused: true,
        disableServiceAuthCodes: true,
        enableDds: false,
        dartEntrypointArgs: <String>['a', 'b'],
        dartFlags: 'c',
        deviceVmServicePort: 1234,
        enableImpeller: true,
      );
      final String jsonString = json.encode(original.toJson());
      final Map<String, dynamic> decoded = castStringKeyedMap(json.decode(jsonString))!;
      final DebuggingOptions deserialized = DebuggingOptions.fromJson(decoded, BuildInfo.debug);
      expect(deserialized.startPaused, original.startPaused);
      expect(deserialized.disableServiceAuthCodes, original.disableServiceAuthCodes);
      expect(deserialized.enableDds, original.enableDds);
      expect(deserialized.dartEntrypointArgs, original.dartEntrypointArgs);
      expect(deserialized.dartFlags, original.dartFlags);
      expect(deserialized.deviceVmServicePort, original.deviceVmServicePort);
      expect(deserialized.enableImpeller, original.enableImpeller);
    });
  });
}

class TestDeviceManager extends DeviceManager {
  TestDeviceManager(
    List<Device> allDevices, {
    List<DeviceDiscovery>? deviceDiscoveryOverrides,
    required super.logger,
    required super.terminal,
    String? wellKnownId,
  }) : _fakeDeviceDiscoverer = FakePollingDeviceDiscovery(),
       _deviceDiscoverers = <DeviceDiscovery>[],
       super(userMessages: UserMessages()) {
    if (wellKnownId != null) {
      _fakeDeviceDiscoverer.wellKnownIds.add(wellKnownId);
    }
    _deviceDiscoverers.add(_fakeDeviceDiscoverer);
    if (deviceDiscoveryOverrides != null) {
      _deviceDiscoverers.addAll(deviceDiscoveryOverrides);
    }
    resetDevices(allDevices);
  }
  @override
  List<DeviceDiscovery> get deviceDiscoverers => _deviceDiscoverers;
  final List<DeviceDiscovery> _deviceDiscoverers;
  final FakePollingDeviceDiscovery _fakeDeviceDiscoverer;

  void resetDevices(List<Device> allDevices) {
    _fakeDeviceDiscoverer.setDevices(allDevices);
  }

  bool? isAlwaysSupportedForProjectOverride;

  @override
  bool isDeviceSupportedForProject(Device device, FlutterProject? flutterProject) {
    if (isAlwaysSupportedForProjectOverride != null) {
      return isAlwaysSupportedForProjectOverride!;
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
  Future<List<Device>> discoverDevices({Duration? timeout}) async {
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
  Future<List<Device>> pollingGetDevices({ Duration? timeout }) async {
    return _completer.future;
  }

  @override
  Future<void> stopPolling() async {
    _completer.complete(<Device>[]);
  }

  @override
  Future<void> dispose() async {
    _completer.complete(<Device>[]);
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
  Future<List<Device>> pollingGetDevices({ Duration? timeout }) async {
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

  List<String>? _nextPrompt;
  late String _nextResult;

  @override
  Future<String> promptForCharInput(
    List<String> acceptedCharacters, {
    Logger? logger,
    String? prompt,
    int? defaultChoiceIndex,
    bool displayAcceptedCharacters = true,
  }) async {
    expect(acceptedCharacters, _nextPrompt);
    return _nextResult;
  }
}

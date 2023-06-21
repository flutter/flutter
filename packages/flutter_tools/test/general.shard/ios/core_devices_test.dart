// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/ios/core_devices.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

void main() {
  late MemoryFileSystem fileSystem;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
  });

  group('Xcode prior to Core Device Control/Xcode 15', () {
    late BufferLogger logger;
    late FakeProcessManager fakeProcessManager;
    late ProcessUtils processUtils;
    late Xcode xcode;
    late IOSCoreDeviceControl deviceControl;

    setUp(() {
      logger = BufferLogger.test();
      fakeProcessManager = FakeProcessManager.empty();
      processUtils = ProcessUtils(processManager: fakeProcessManager, logger: logger);
      final XcodeProjectInterpreter xcodeProjectInterpreter = XcodeProjectInterpreter.test(
        processManager: fakeProcessManager,
        version: Version(14, 0, 0),
      );
      xcode = Xcode.test(
        processManager: FakeProcessManager.any(),
        xcodeProjectInterpreter: xcodeProjectInterpreter,
      );
      deviceControl = IOSCoreDeviceControl(
        logger: logger,
        processUtils: processUtils,
        xcode: xcode,
        fileSystem: fileSystem,
      );
    });

    testWithoutContext('devicectl is not installed', () async {
      final List<IOSCoreDevice> devices = await deviceControl.getCoreDevices();
      expect(devices.isEmpty, isTrue);
      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(logger.traceText, contains('devicectl is not installed.'));
    });
  });

  group('Core Device Control', () {
    late BufferLogger logger;
    late FakeProcessManager fakeProcessManager;
    late ProcessUtils processUtils;
    late Xcode xcode;
    late IOSCoreDeviceControl deviceControl;

    setUp(() {
      logger = BufferLogger.test();
      fakeProcessManager = FakeProcessManager.empty();
      processUtils = ProcessUtils(processManager: fakeProcessManager, logger: logger);
      xcode = Xcode.test(processManager: FakeProcessManager.any());
      deviceControl = IOSCoreDeviceControl(
        logger: logger,
        processUtils: processUtils,
        xcode: xcode,
        fileSystem: fileSystem,
      );
    });

    testWithoutContext('No devices', () async {
      const String deviceControlOutput = '''
{
  "info" : {
    "arguments" : [
      "devicectl",
      "list",
      "devices",
      "--json-output",
      "core_device_list.json"
    ],
    "commandType" : "devicectl.list.devices",
    "environment" : {
      "TERM" : "xterm-256color"
    },
    "outcome" : "success",
    "version" : "325.3"
  },
  "result" : {
    "devices" : [

    ]
  }
}
    ''';

      final File tempFile = fileSystem.systemTempDirectory.childDirectory('core_devices.rand0').childFile('core_device_list.json');
      fakeProcessManager.addCommand(FakeCommand(
        command: <String>[
          'xcrun',
          'devicectl',
          'list',
          'devices',
          '--timeout',
          '5',
          '--json-output',
          tempFile.path,
        ],
        onRun: () {
          expect(tempFile, exists);
          tempFile.writeAsStringSync(deviceControlOutput);
        },
      ));

      final List<IOSCoreDevice> devices = await deviceControl.getCoreDevices();
      expect(devices.isEmpty, isTrue);
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testWithoutContext('All sections parsed', () async {
      const String deviceControlOutput = '''
{
  "info" : {
    "arguments" : [
      "devicectl",
      "list",
      "devices",
      "--json-output",
      "core_device_list.json"
    ],
    "commandType" : "devicectl.list.devices",
    "environment" : {
      "TERM" : "xterm-256color"
    },
    "outcome" : "success",
    "version" : "325.3"
  },
  "result" : {
    "devices" : [
      {
        "capabilities" : [
        ],
        "connectionProperties" : {
        },
        "deviceProperties" : {
        },
        "hardwareProperties" : {
        },
        "identifier" : "123456BB5-AEDE-7A22-B890-1234567890DD",
        "visibilityClass" : "default"
      }
    ]
  }
}
    ''';

    final File tempFile = fileSystem.systemTempDirectory.childDirectory('core_devices.rand0').childFile('core_device_list.json');
      fakeProcessManager.addCommand(FakeCommand(
        command: <String>[
          'xcrun',
          'devicectl',
          'list',
          'devices',
          '--timeout',
          '5',
          '--json-output',
          tempFile.path,
        ],
        onRun: () {
          expect(tempFile, exists);
          tempFile.writeAsStringSync(deviceControlOutput);
        },
      ));

      final List<IOSCoreDevice> devices = await deviceControl.getCoreDevices();
      expect(devices.length, 1);

      expect(devices[0].capabilities, isNotNull);
      expect(devices[0].connectionProperties, isNotNull);
      expect(devices[0].deviceProperties, isNotNull);
      expect(devices[0].hardwareProperties, isNotNull);
      expect(devices[0].coreDeviceIdentifer, '123456BB5-AEDE-7A22-B890-1234567890DD');
      expect(devices[0].visibilityClass, 'default');

      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(tempFile, isNot(exists));
    });

    testWithoutContext('All sections parsed, device missing sections', () async {
      const String deviceControlOutput = '''
{
  "info" : {
    "arguments" : [
      "devicectl",
      "list",
      "devices",
      "--json-output",
      "core_device_list.json"
    ],
    "commandType" : "devicectl.list.devices",
    "environment" : {
      "TERM" : "xterm-256color"
    },
    "outcome" : "success",
    "version" : "325.3"
  },
  "result" : {
    "devices" : [
      {
        "identifier" : "123456BB5-AEDE-7A22-B890-1234567890DD",
        "visibilityClass" : "default"
      }
    ]
  }
}
    ''';

    final File tempFile = fileSystem.systemTempDirectory.childDirectory('core_devices.rand0').childFile('core_device_list.json');
      fakeProcessManager.addCommand(FakeCommand(
        command: <String>[
          'xcrun',
          'devicectl',
          'list',
          'devices',
          '--timeout',
          '5',
          '--json-output',
          tempFile.path,
        ],
        onRun: () {
          expect(tempFile, exists);
          tempFile.writeAsStringSync(deviceControlOutput);
        },
      ));

      final List<IOSCoreDevice> devices = await deviceControl.getCoreDevices();
      expect(devices.length, 1);

      expect(devices[0].capabilities, isEmpty);
      expect(devices[0].connectionProperties, isNull);
      expect(devices[0].deviceProperties, isNull);
      expect(devices[0].hardwareProperties, isNull);


      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(tempFile, isNot(exists));
    });

    testWithoutContext('capabilities parsed', () async {
      const String deviceControlOutput = '''
{
  "result" : {
    "devices" : [
      {
        "capabilities" : [
          {
            "featureIdentifier" : "com.apple.coredevice.feature.spawnexecutable",
            "name" : "Spawn Executable"
          },
          {
            "featureIdentifier" : "com.apple.coredevice.feature.launchapplication",
            "name" : "Launch Application"
          }
        ]
      }
    ]
  }
}
    ''';

    final File tempFile = fileSystem.systemTempDirectory.childDirectory('core_devices.rand0').childFile('core_device_list.json');
      fakeProcessManager.addCommand(FakeCommand(
        command: <String>[
          'xcrun',
          'devicectl',
          'list',
          'devices',
          '--timeout',
          '5',
          '--json-output',
          tempFile.path,
        ],
        onRun: () {
          expect(tempFile, exists);
          tempFile.writeAsStringSync(deviceControlOutput);
        },
      ));

      final List<IOSCoreDevice> devices = await deviceControl.getCoreDevices();
      expect(devices.length, 1);

      expect(devices[0].capabilities.length, 2);
      expect(devices[0].capabilities[0].featureIdentifier, 'com.apple.coredevice.feature.spawnexecutable');
      expect(devices[0].capabilities[0].name, 'Spawn Executable');
      expect(devices[0].capabilities[1].featureIdentifier, 'com.apple.coredevice.feature.launchapplication');
      expect(devices[0].capabilities[1].name, 'Launch Application');

      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(tempFile, isNot(exists));
    });

    testWithoutContext('connectionProperties parsed', () async {
      const String deviceControlOutput = '''
{
  "result" : {
    "devices" : [
      {
        "connectionProperties" : {
          "authenticationType" : "manualPairing",
          "isMobileDeviceOnly" : false,
          "lastConnectionDate" : "2023-06-15T15:29:00.082Z",
          "localHostnames" : [
            "Victorias-iPad.coredevice.local",
            "00001234-0001234A3C03401E.coredevice.local",
            "123456BB5-AEDE-7A22-B890-1234567890DD.coredevice.local"
          ],
          "pairingState" : "paired",
          "potentialHostnames" : [
            "00001234-0001234A3C03401E.coredevice.local",
            "123456BB5-AEDE-7A22-B890-1234567890DD.coredevice.local"
          ],
          "transportType" : "wired",
          "tunnelIPAddress" : "fdf1:23c4:cd56::1",
          "tunnelState" : "connected",
          "tunnelTransportProtocol" : "tcp"
        }
      }
    ]
  }
}
    ''';

    final File tempFile = fileSystem.systemTempDirectory.childDirectory('core_devices.rand0').childFile('core_device_list.json');
      fakeProcessManager.addCommand(FakeCommand(
        command: <String>[
          'xcrun',
          'devicectl',
          'list',
          'devices',
          '--timeout',
          '5',
          '--json-output',
          tempFile.path,
        ],
        onRun: () {
          expect(tempFile, exists);
          tempFile.writeAsStringSync(deviceControlOutput);
        },
      ));

      final List<IOSCoreDevice> devices = await deviceControl.getCoreDevices();
      expect(devices.length, 1);

      expect(devices[0].connectionProperties?.authenticationType, 'manualPairing');
      expect(devices[0].connectionProperties?.isMobileDeviceOnly, false);
      expect(devices[0].connectionProperties?.lastConnectionDate, '2023-06-15T15:29:00.082Z');
      expect(
        devices[0].connectionProperties?.localHostnames,
        <String>[
          'Victorias-iPad.coredevice.local',
          '00001234-0001234A3C03401E.coredevice.local',
          '123456BB5-AEDE-7A22-B890-1234567890DD.coredevice.local',
        ],
      );
      expect(devices[0].connectionProperties?.pairingState, 'paired');
      expect(
        devices[0].connectionProperties?.potentialHostnames,
        <String>[
          '00001234-0001234A3C03401E.coredevice.local',
          '123456BB5-AEDE-7A22-B890-1234567890DD.coredevice.local',
        ]
      );
      expect(devices[0].connectionProperties?.transportType, 'wired');
      expect(devices[0].connectionProperties?.tunnelIPAddress, 'fdf1:23c4:cd56::1');
      expect(devices[0].connectionProperties?.tunnelState, 'connected');
      expect(devices[0].connectionProperties?.tunnelTransportProtocol, 'tcp');

      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(tempFile, isNot(exists));
    });

    testWithoutContext('deviceProperties parsed', () async {
      const String deviceControlOutput = '''
{
  "result" : {
    "devices" : [
      {
        "deviceProperties" : {
          "bootedFromSnapshot" : true,
          "bootedSnapshotName" : "com.apple.os.update-123456",
          "bootState" : "booted",
          "ddiServicesAvailable" : true,
          "developerModeStatus" : "enabled",
          "hasInternalOSBuild" : false,
          "name" : "iPadName",
          "osBuildUpdate" : "21A5248v",
          "osVersionNumber" : "17.0",
          "rootFileSystemIsWritable" : false,
          "screenViewingURL" : "coredevice-devices:/viewDeviceByUUID?uuid=123456BB5-AEDE-7A22-B890-1234567890DD"
        }
      }
    ]
  }
}
    ''';

    final File tempFile = fileSystem.systemTempDirectory.childDirectory('core_devices.rand0').childFile('core_device_list.json');
      fakeProcessManager.addCommand(FakeCommand(
        command: <String>[
          'xcrun',
          'devicectl',
          'list',
          'devices',
          '--timeout',
          '5',
          '--json-output',
          tempFile.path,
        ],
        onRun: () {
          expect(tempFile, exists);
          tempFile.writeAsStringSync(deviceControlOutput);
        },
      ));

      final List<IOSCoreDevice> devices = await deviceControl.getCoreDevices();
      expect(devices.length, 1);

      expect(devices[0].deviceProperties?.bootedFromSnapshot, true);
      expect(devices[0].deviceProperties?.bootedSnapshotName, 'com.apple.os.update-123456');
      expect(devices[0].deviceProperties?.bootState, 'booted');
      expect(devices[0].deviceProperties?.ddiServicesAvailable, true);
      expect(devices[0].deviceProperties?.developerModeStatus, 'enabled');
      expect(devices[0].deviceProperties?.hasInternalOSBuild, false);
      expect(devices[0].deviceProperties?.name, 'iPadName');
      expect(devices[0].deviceProperties?.osBuildUpdate, '21A5248v');
      expect(devices[0].deviceProperties?.osVersionNumber, '17.0');
      expect(devices[0].deviceProperties?.rootFileSystemIsWritable, false);
      expect(devices[0].deviceProperties?.screenViewingURL, 'coredevice-devices:/viewDeviceByUUID?uuid=123456BB5-AEDE-7A22-B890-1234567890DD');

      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(tempFile, isNot(exists));
    });

    testWithoutContext('hardwareProperties parsed', () async {
      const String deviceControlOutput = r'''
{
  "result" : {
    "devices" : [
      {
        "hardwareProperties" : {
          "cpuType" : {
            "name" : "arm64e",
            "subType" : 2,
            "type" : 16777228
          },
          "deviceType" : "iPad",
          "ecid" : 12345678903408542,
          "hardwareModel" : "J617AP",
          "internalStorageCapacity" : 128000000000,
          "marketingName" : "iPad Pro (11-inch) (4th generation)\"",
          "platform" : "iOS",
          "productType" : "iPad14,3",
          "serialNumber" : "HC123DHCQV",
          "supportedCPUTypes" : [
            {
              "name" : "arm64e",
              "subType" : 2,
              "type" : 16777228
            },
            {
              "name" : "arm64",
              "subType" : 0,
              "type" : 16777228
            }
          ],
          "supportedDeviceFamilies" : [
            1,
            2
          ],
          "thinningProductType" : "iPad14,3-A",
          "udid" : "00001234-0001234A3C03401E"
        }
      }
    ]
  }
}
    ''';

    final File tempFile = fileSystem.systemTempDirectory.childDirectory('core_devices.rand0').childFile('core_device_list.json');
      fakeProcessManager.addCommand(FakeCommand(
        command: <String>[
          'xcrun',
          'devicectl',
          'list',
          'devices',
          '--timeout',
          '5',
          '--json-output',
          tempFile.path,
        ],
        onRun: () {
          expect(tempFile, exists);
          tempFile.writeAsStringSync(deviceControlOutput);
        },
      ));

      final List<IOSCoreDevice> devices = await deviceControl.getCoreDevices();
      expect(devices.length, 1);

      expect(devices[0].hardwareProperties?.cpuType, isNotNull);
      expect(devices[0].hardwareProperties?.cpuType?.name, 'arm64e');
      expect(devices[0].hardwareProperties?.cpuType?.subType, 2);
      expect(devices[0].hardwareProperties?.cpuType?.cpuType, 16777228);

      expect(devices[0].hardwareProperties?.deviceType, 'iPad');
      expect(devices[0].hardwareProperties?.ecid, 12345678903408542);
      expect(devices[0].hardwareProperties?.hardwareModel, 'J617AP');
      expect(devices[0].hardwareProperties?.internalStorageCapacity, 128000000000);
      expect(devices[0].hardwareProperties?.marketingName, 'iPad Pro (11-inch) (4th generation)"');
      expect(devices[0].hardwareProperties?.platform, 'iOS');
      expect(devices[0].hardwareProperties?.productType, 'iPad14,3');
      expect(devices[0].hardwareProperties?.serialNumber, 'HC123DHCQV');


      expect(devices[0].hardwareProperties?.supportedCPUTypes?[0].name, 'arm64e');
      expect(devices[0].hardwareProperties?.supportedCPUTypes?[0].subType, 2);
      expect(devices[0].hardwareProperties?.supportedCPUTypes?[0].cpuType, 16777228);
      expect(devices[0].hardwareProperties?.supportedCPUTypes?[1].name, 'arm64');
      expect(devices[0].hardwareProperties?.supportedCPUTypes?[1].subType, 0);
      expect(devices[0].hardwareProperties?.supportedCPUTypes?[1].cpuType, 16777228);
      expect(devices[0].hardwareProperties?.supportedDeviceFamilies, <int>[1, 2]);
      expect(devices[0].hardwareProperties?.thinningProductType, 'iPad14,3-A');

      expect(devices[0].hardwareProperties?.udid, '00001234-0001234A3C03401E');

      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(tempFile, isNot(exists));
    });

    group('Handles errors quietly', () {
      testWithoutContext('invalid json', () async {
        const String deviceControlOutput = '''Invalid JSON''';

        final File tempFile = fileSystem.systemTempDirectory.childDirectory('core_devices.rand0').childFile('core_device_list.json');
        fakeProcessManager.addCommand(FakeCommand(
          command: <String>[
            'xcrun',
            'devicectl',
            'list',
            'devices',
            '--timeout',
            '5',
            '--json-output',
            tempFile.path,
          ],
          onRun: () {
            expect(tempFile, exists);
            tempFile.writeAsStringSync(deviceControlOutput);
          },
        ));

        final List<IOSCoreDevice> devices = await deviceControl.getCoreDevices();
        expect(devices.isEmpty, isTrue);
        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.traceText, contains('devicectl returned non-JSON response: Invalid JSON'));
      });

      testWithoutContext('unexpected json', () async {
        const String deviceControlOutput = '''
{
  "info" : {
    "arguments" : [
      "devicectl",
      "list",
      "devices",
      "--json-output",
      "device_list.json"
    ],
    "commandType" : "devicectl.list.devices",
    "environment" : {
      "TERM" : "xterm-256color"
    },
    "outcome" : "success",
    "version" : "325.3"
  },
  "result" : [

  ]
}
    ''';

        final File tempFile = fileSystem.systemTempDirectory.childDirectory('core_devices.rand0').childFile('core_device_list.json');
        fakeProcessManager.addCommand(FakeCommand(
          command: <String>[
            'xcrun',
            'devicectl',
            'list',
            'devices',
            '--timeout',
            '5',
            '--json-output',
            tempFile.path,
          ],
          onRun: () {
            expect(tempFile, exists);
            tempFile.writeAsStringSync(deviceControlOutput);
          },
        ));

        final List<IOSCoreDevice> devices = await deviceControl.getCoreDevices();
        expect(devices.isEmpty, isTrue);
        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.traceText, contains('devicectl returned unexpected JSON response:'));
      });

      testWithoutContext('When timeout is below minimum, default to minimum', () async {
        const String deviceControlOutput = '''
{
  "info" : {
    "arguments" : [
      "devicectl",
      "list",
      "devices",
      "--json-output",
      "core_device_list.json"
    ],
    "commandType" : "devicectl.list.devices",
    "environment" : {
      "TERM" : "xterm-256color"
    },
    "outcome" : "success",
    "version" : "325.3"
  },
  "result" : {
    "devices" : [
      {
        "identifier" : "123456BB5-AEDE-7A22-B890-1234567890DD",
        "visibilityClass" : "default"
      }
    ]
  }
}
    ''';

        final File tempFile = fileSystem.systemTempDirectory.childDirectory('core_devices.rand0').childFile('core_device_list.json');
        fakeProcessManager.addCommand(FakeCommand(
          command: <String>[
            'xcrun',
            'devicectl',
            'list',
            'devices',
            '--timeout',
            '5',
            '--json-output',
            tempFile.path,
          ],
          onRun: () {
            expect(tempFile, exists);
            tempFile.writeAsStringSync(deviceControlOutput);
          },
        ));

        final List<IOSCoreDevice> devices = await deviceControl.getCoreDevices(timeout: const Duration(seconds: 2));
        expect(devices.isNotEmpty, isTrue);
        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(
          logger.traceText,
          contains(
            'Timeout of 2 seconds is below the minimum timeout value '
            'for devicectl. Changing the timeout to the minimum value of 5.'
          ),
        );
      });

    });


  });

}

class FakeIosProject extends Fake implements IosProject {
  @override
  Future<String> productBundleIdentifier(BuildInfo? buildInfo) async => 'com.example.test';

  @override
  Future<String> hostAppBundleName(BuildInfo? buildInfo) async => 'My Super Awesome App.app';
}

class FakeSimControl extends Fake implements SimControl {
  final List<LaunchRequest> requests = <LaunchRequest>[];

  @override
  Future<RunResult> launch(String deviceId, String appIdentifier, [ List<String>? launchArgs ]) async {
    requests.add(LaunchRequest(deviceId, appIdentifier, launchArgs));
    return RunResult(ProcessResult(0, 0, '', ''), <String>['test']);
  }

  @override
  Future<RunResult> install(String deviceId, String appPath) async {
    return RunResult(ProcessResult(0, 0, '', ''), <String>['test']);
  }
}

class LaunchRequest {
  const LaunchRequest(this.deviceId, this.appIdentifier, this.launchArgs);

  final String deviceId;
  final String appIdentifier;
  final List<String>? launchArgs;
}

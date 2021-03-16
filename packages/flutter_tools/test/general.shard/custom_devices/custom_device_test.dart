// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:file/src/interface/directory.dart';
import 'package:file/src/interface/file.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/custom_devices/custom_device.dart';
import 'package:flutter_tools/src/custom_devices/custom_device_config.dart';
import 'package:flutter_tools/src/custom_devices/custom_devices_config.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/linux/application_package.dart';

import 'package:file/memory.dart';
import 'package:file/file.dart';
import 'package:flutter_tools/src/project.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';


void _writeCustomDevicesConfigFile(Directory dir, List<CustomDeviceConfig> configs) {
  dir.createSync();

  final File file = dir.childFile('.flutter_custom_devices.json');
  file.writeAsStringSync(jsonEncode(
      <String, dynamic>{
        'custom-devices': configs.map<dynamic>((CustomDeviceConfig c) => c.toJson()).toList()
      }
  ));
}

FlutterProject _setUpFlutterProject(Directory directory) {
  final FlutterProjectFactory flutterProjectFactory = FlutterProjectFactory(
    fileSystem: directory.fileSystem,
    logger: BufferLogger.test(),
  );
  return flutterProjectFactory.fromDirectory(directory);
}

void main() {
  testWithoutContext('replacing string interpolation occurrences in custom device commands', () async {
    expect(
      interpolateCommand(
        <String>['scp', r'${localPath}', r'/tmp/${appName}', 'pi@raspberrypi'],
        <String, String>{
          'localPath': 'build/flutter_assets',
          'appName': 'hello_world'
        }
      ),
      <String>[
        'scp', 'build/flutter_assets', '/tmp/hello_world', 'pi@raspberrypi'
      ]
    );

    expect(
      interpolateCommand(
        <String>[r'${test1}', r' ${test2}', r'${test3}'],
        <String, String>{
          'test1': '_test1',
          'test2': '_test2'
        }
      ),
      <String>[
        '_test1', ' _test2', r''
      ]
    );

    expect(
        interpolateCommand(
          <String>[r'${test1}', r' ${test2}', r'${test3}'],
          <String, String>{
            'test1': '_test1',
            'test2': '_test2'
          },
          additionalReplacementValues: <String, String>{
            'test2': '_nottest2',
            'test3': '_test3'
          }
        ),
        <String>[
          '_test1', ' _test2', r'_test3'
        ]
    );
  });

  final CustomDeviceConfig testConfig = CustomDeviceConfig(
    id: 'testid',
    label: 'testlabel',
    sdkNameAndVersion: 'testsdknameandversion',
    disabled: false,
    pingCommand: const <String>['testping'],
    postBuildCommand: const <String>['testpostbuild'],
    installCommand: const <String>['testinstall'],
    uninstallCommand: const <String>['testuninstall'],
    runDebugCommand: const <String>['testrundebug'],
    forwardPortCommand: const <String>['testforwardport'],
    forwardPortSuccessRegex: RegExp('testforwardportsuccess')
  );

  final CustomDeviceConfig disabledTestConfig = testConfig.copyWith(disabled: true);

  final CustomDeviceConfig testConfigNonForwarding = testConfig.copyWith(
    explicitForwardPortCommand: true,
    forwardPortCommand: null,
    explicitForwardPortSuccessRegex: true,
    forwardPortSuccessRegex: null,
  );

  testUsingContext('CustomDevice defaults',
    () async {
      final CustomDevice device = CustomDevice(
        config: testConfig,
        processManager: FakeProcessManager.any(),
        logger: BufferLogger.test()
      );

      final PrebuiltLinuxApp linuxApp = PrebuiltLinuxApp(executable: 'foo');

      expect(device.id, 'testid');
      expect(device.name, 'testlabel');
      expect(await device.sdkNameAndVersion, 'testsdknameandversion');
      expect(await device.targetPlatform, TargetPlatform.linux_arm64);
      expect(await device.installApp(linuxApp), true);
      expect(await device.uninstallApp(linuxApp), true);
      expect(await device.isLatestBuildInstalled(linuxApp), false);
      expect(await device.isAppInstalled(linuxApp), false);
      expect(await device.stopApp(linuxApp), false);
      expect(device.category, Category.mobile);

      expect(device.supportsRuntimeMode(BuildMode.debug), true);
      expect(device.supportsRuntimeMode(BuildMode.profile), false);
      expect(device.supportsRuntimeMode(BuildMode.release), false);
      expect(device.supportsRuntimeMode(BuildMode.jitRelease), false);
    },
    overrides: <Type, dynamic Function()>{
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any()
    }
  );

  testWithoutContext('CustomDevice: no devices listed if only disabled devices configured', () async {
    final MemoryFileSystem fs = MemoryFileSystem.test();
    final Directory dir = fs.directory('custom_devices_config_dir');

    _writeCustomDevicesConfigFile(dir, <CustomDeviceConfig>[disabledTestConfig]);

    expect(await CustomDevices.test(
      featureFlags: TestFeatureFlags(areCustomDevicesEnabled: true),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
      config: CustomDevicesConfig.test(
        fileSystem: fs,
        directory: dir,
        logger: BufferLogger.test()
      )
    ).devices, <Device>[]);

  });

  testWithoutContext('CustomDevice: no devices listed if custom devices feature flag disabled', () async {
    final MemoryFileSystem fs = MemoryFileSystem.test();
    final Directory dir = fs.directory('custom_devices_config_dir');

    _writeCustomDevicesConfigFile(dir, <CustomDeviceConfig>[testConfig]);

    expect(await CustomDevices.test(
      featureFlags: TestFeatureFlags(areCustomDevicesEnabled: false),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
      config: CustomDevicesConfig.test(
        fileSystem: fs,
        directory: dir,
        logger: BufferLogger.test()
      )
    ).devices, <Device>[]);
  });

  testWithoutContext('CustomDevices.devices', () async {
    final MemoryFileSystem fs = MemoryFileSystem.test();
    final Directory dir = fs.directory('custom_devices_config_dir');

    _writeCustomDevicesConfigFile(dir, <CustomDeviceConfig>[testConfig]);

    expect(await CustomDevices.test(
      featureFlags: TestFeatureFlags(areCustomDevicesEnabled: true),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
      config: CustomDevicesConfig.test(
        fileSystem: fs,
        directory: dir,
        logger: BufferLogger.test()
      )
    ).devices, hasLength(1));
  });

  testWithoutContext('CustomDevices.discoverDevices successfully discovers devices and executes ping command', () async {
    final MemoryFileSystem fs = MemoryFileSystem.test();
    final Directory dir = fs.directory('custom_devices_config_dir');

    _writeCustomDevicesConfigFile(dir, <CustomDeviceConfig>[testConfig]);

    bool pingCommandWasExecuted = false;

    final CustomDevices discovery = CustomDevices.test(
      featureFlags: TestFeatureFlags(areCustomDevicesEnabled: true),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        FakeCommand(command: testConfig.pingCommand, onRun: () => pingCommandWasExecuted = true),
      ]),
      config: CustomDevicesConfig.test(
        fileSystem: fs,
        directory: dir,
        logger: BufferLogger.test(),
      ),
    );

    final List<Device> discoveredDevices = await discovery.discoverDevices();

    expect(discoveredDevices, hasLength(1));
    expect(pingCommandWasExecuted, true);
  });
  
  testWithoutContext('CustomDevices.discoverDevices doesnt report any devices when ping command fails', () async {
    final MemoryFileSystem fs = MemoryFileSystem.test();
    final Directory dir = fs.directory('custom_devices_config_dir');

    _writeCustomDevicesConfigFile(dir, <CustomDeviceConfig>[testConfig]);

    final CustomDevices discovery = CustomDevices.test(
      featureFlags: TestFeatureFlags(areCustomDevicesEnabled: true),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        FakeCommand(command: testConfig.pingCommand, exitCode: 1),
      ]),
      config: CustomDevicesConfig.test(
        fileSystem: fs,
        directory: dir,
        logger: BufferLogger.test(),
      ),
    );

    final List<Device> discoveredDevices = await discovery.discoverDevices();

    expect(discoveredDevices, hasLength(0));
  });

  testWithoutContext('CustomDevice.isSupportedForProject is true with editable host app', () async {
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();

    final FlutterProject flutterProject = _setUpFlutterProject(fileSystem.currentDirectory);

    expect(CustomDevice(
      config: testConfig,
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
    ).isSupportedForProject(flutterProject), true);
  });

  testUsingContext('CustomDevice.install invokes uninstall and install command', () async {
    bool bothCommandsWereExecuted = false;

    final CustomDevice device = CustomDevice(
        config: testConfig,
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.list(<FakeCommand>[
          FakeCommand(command: testConfig.uninstallCommand),
          FakeCommand(command: testConfig.installCommand, onRun: () => bothCommandsWereExecuted = true)
        ])
    );

    expect(await device.installApp(PrebuiltLinuxApp(executable: 'exe')), true);
    expect(bothCommandsWereExecuted, true);
  },
    overrides: <Type, dynamic Function()>{
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any()
    }
  );

  testWithoutContext('CustomDevicePortForwarder will run and terminate forwardPort command', () async {
    final Completer<void> forwardPortCommandCompleter = Completer<void>();

    final CustomDevicePortForwarder forwarder = CustomDevicePortForwarder(
      deviceName: 'testdevicename',
      forwardPortCommand: testConfig.forwardPortCommand,
      forwardPortSuccessRegex: RegExp('testforwardportsuccessregex'),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: testConfig.forwardPortCommand,
          stdout: 'testforwardportsuccessregex\n',
          completer: forwardPortCommandCompleter
        )
      ])
    );

    // this should start the command
    expect(await forwarder.forward(12345, hostPort: null), 12345);

    // this should terminate it
    await forwarder.dispose();

    // the termination should have completed our completer
    expect(forwardPortCommandCompleter.isCompleted, true);
  });

  testWithoutContext('CustomDeviceAppSession forwards observatory port correctly when port forwarding is configured', () async {
    final Completer<void> runDebugCompleter = Completer<void>();
    final Completer<void> forwardPortCompleter = Completer<void>();

    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: testConfig.runDebugCommand,
        completer: runDebugCompleter,
        stdout: 'Observatory listening on http://127.0.0.1:12345/abcd/\n',
      ),
      FakeCommand(
        command: testConfig.forwardPortCommand,
        completer: forwardPortCompleter,
        stdout: 'testforwardportsuccessregex\n',
      )
    ]);

    final CustomDeviceAppSession appSession = CustomDeviceAppSession(
      name: 'testname',
      device: CustomDevice(
        config: testConfig,
        logger: BufferLogger.test(),
        processManager: processManager
      ),
      appPackage: PrebuiltLinuxApp(executable: 'testexecutable'),
      logger: BufferLogger.test(),
      processManager: processManager,
    );

    final LaunchResult launchResult = await appSession.start();

    expect(launchResult.started, true);
    expect(launchResult.observatoryUri, Uri.parse('http://127.0.0.1:12345/abcd/'));

    await appSession.stop();
  });

  testWithoutContext('CustomDeviceAppSession forwards observatory port correctly when port forwarding is not configured', () async {
    final Completer<void> runDebugCompleter = Completer<void>();

    final FakeProcessManager processManager = FakeProcessManager.list(
      <FakeCommand>[
        FakeCommand(
          command: testConfigNonForwarding.runDebugCommand,
          completer: runDebugCompleter,
          stdout: 'Observatory listening on http://192.168.178.123:12345/abcd/\n'
        ),
      ]
    );

    final CustomDeviceAppSession appSession = CustomDeviceAppSession(
      name: 'testname',
      device: CustomDevice(
        config: testConfigNonForwarding,
        logger: BufferLogger.test(),
        processManager: processManager
      ),
      appPackage: PrebuiltLinuxApp(executable: 'testexecutable'),
      logger: BufferLogger.test(),
      processManager: processManager
    );

    final LaunchResult launchResult = await appSession.start();

    expect(launchResult.started, true);
    expect(launchResult.observatoryUri, Uri.parse('http://192.168.178.123:12345/abcd/'));

    expect(await appSession.stop(), true);
  });
}
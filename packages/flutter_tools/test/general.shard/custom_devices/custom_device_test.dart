// @dart = 2.8

import 'package:file/src/interface/directory.dart';
import 'package:file/src/interface/file.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/custom_devices/custom_device.dart';
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


final FakePlatform _windows = FakePlatform(
  operatingSystem: 'windows',
);

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

  testUsingContext('CustomDevice defaults',
    () async {
      final CustomDevice device = CustomDevice(
        config: CustomDeviceConfig.example.copyWith(
          id: 'testid',
          label: 'testlabel',
          sdkNameAndVersion: 'testsdknameandversion',
          disabled: false
        ),
        processManager: FakeProcessManager.any(),
        logger: BufferLogger.test(),
        fileSystem: MemoryFileSystem.test(),
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
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any()
    }
  );

  testWithoutContext('CustomDevice: no devices listed if only disabled devices configured', () async {
    final MemoryFileSystem fs = MemoryFileSystem.test();
    final Directory dir = fs.directory('custom_devices_config_dir');

    _writeCustomDevicesConfigFile(
        dir,
        <CustomDeviceConfig>[
          CustomDeviceConfig.example,
          CustomDeviceConfig.example2
        ]
    );

    expect(await CustomDevices.test(
      fileSystem: fs,
      platform: _windows,
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

    _writeCustomDevicesConfigFile(
      dir,
      <CustomDeviceConfig>[
        CustomDeviceConfig.example.copyWith(disabled: false),
        CustomDeviceConfig.example2.copyWith(disabled: false)
      ]
    );

    expect(await CustomDevices.test(
      fileSystem: fs,
      platform: _windows,
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

    _writeCustomDevicesConfigFile(
        dir,
        <CustomDeviceConfig>[
          CustomDeviceConfig.example.copyWith(disabled: false),
          CustomDeviceConfig.example2.copyWith(disabled: false)
        ]
    );

    expect(await CustomDevices.test(
      fileSystem: MemoryFileSystem.test(),
      platform: _windows,
      featureFlags: TestFeatureFlags(areCustomDevicesEnabled: true),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
      config: CustomDevicesConfig.test(
        fileSystem: fs,
        directory: dir,
        logger: BufferLogger.test()
      )
    ).devices, hasLength(2));
  });

  testWithoutContext('CustomDevices.discoverDevices', () async {
    final MemoryFileSystem fs = MemoryFileSystem.test();

    final Directory dir = fs.directory('custom_devices_config_dir');
    _writeCustomDevicesConfigFile(
      dir,
      <CustomDeviceConfig>[
        CustomDeviceConfig.example.copyWith(disabled: false),
        CustomDeviceConfig.example2.copyWith(disabled: false)
      ]
    );

    expect(
      await CustomDevices.test(
        fileSystem: MemoryFileSystem.test(),
        platform: _windows,
        featureFlags: TestFeatureFlags(areCustomDevicesEnabled: true),
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        config: CustomDevicesConfig.test(
          fileSystem: fs,
          directory: dir,
          logger: BufferLogger.test()
        )
      ).discoverDevices(timeout: const Duration(seconds: 10)),
      hasLength(2)
    );
  });

  testWithoutContext('CustomDevice.isSupportedForProject is true with editable host app', () async {
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();

    final FlutterProject flutterProject = _setUpFlutterProject(fileSystem.currentDirectory);

    expect(CustomDevice(
      config: CustomDeviceConfig.example.copyWith(disabled: false),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
      fileSystem: fileSystem,
    ).isSupportedForProject(flutterProject), true);
  });
}
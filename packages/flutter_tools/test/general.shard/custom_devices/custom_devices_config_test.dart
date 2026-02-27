// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/custom_devices/custom_device_config.dart';
import 'package:flutter_tools/src/custom_devices/custom_devices_config.dart';

import '../../src/common.dart';
import '../../src/custom_devices_common.dart';

Map<String, dynamic> copyJsonObjectWith(
  Map<String, dynamic> object,
  Map<String, dynamic> overrides,
) => Map<String, dynamic>.of(object)..addAll(overrides);

void main() {
  testWithoutContext(
    "CustomDevicesConfig logs no error when 'custom-devices' key is missing in config",
    () {
      final logger = BufferLogger.test();
      final fileSystem = MemoryFileSystem.test();
      final Directory directory = fileSystem.directory('custom_devices_config');

      writeCustomDevicesConfigFile(directory);

      final customDevicesConfig = CustomDevicesConfig.test(
        fileSystem: fileSystem,
        directory: directory,
        logger: logger,
      );

      expect(customDevicesConfig.devices, hasLength(0));
      expect(logger.errorText, hasLength(0));
    },
  );

  testWithoutContext(
    "CustomDevicesConfig logs error when 'custom-devices' key is not a JSON array",
    () {
      final logger = BufferLogger.test();
      final fileSystem = MemoryFileSystem.test();
      final Directory directory = fileSystem.directory('custom_devices_config');

      writeCustomDevicesConfigFile(directory, json: <String, dynamic>{'test': 'testvalue'});

      final customDevicesConfig = CustomDevicesConfig.test(
        fileSystem: fileSystem,
        directory: directory,
        logger: logger,
      );

      const msg =
          "Could not load custom devices config. config['custom-devices'] is not a JSON array.";
      expect(() => customDevicesConfig.devices, throwsA(const CustomDeviceRevivalException(msg)));
      expect(logger.errorText, contains(msg));
    },
  );

  testWithoutContext('CustomDeviceRevivalException serialization', () {
    expect(const CustomDeviceRevivalException('testmessage').toString(), equals('testmessage'));
    expect(
      const CustomDeviceRevivalException.fromDescriptions(
        'testfielddescription',
        'testexpectedvaluedescription',
      ).toString(),
      equals('Expected testfielddescription to be testexpectedvaluedescription.'),
    );
  });

  testWithoutContext('CustomDevicesConfig can load test config and logs no errors', () {
    final logger = BufferLogger.test();
    final fileSystem = MemoryFileSystem.test();
    final Directory directory = fileSystem.directory('custom_devices_config');

    writeCustomDevicesConfigFile(directory, json: <dynamic>[testConfigJson]);

    final customDevicesConfig = CustomDevicesConfig.test(
      fileSystem: fileSystem,
      directory: directory,
      logger: logger,
    );

    final List<CustomDeviceConfig> devices = customDevicesConfig.devices;
    expect(logger.errorText, hasLength(0));
    expect(devices, hasLength(1));
    expect(devices.first, equals(testConfig));
  });

  testWithoutContext('CustomDevicesConfig logs error when id is null', () {
    final logger = BufferLogger.test();
    final fileSystem = MemoryFileSystem.test();
    final Directory directory = fileSystem.directory('custom_devices_config');

    writeCustomDevicesConfigFile(
      directory,
      json: <dynamic>[
        copyJsonObjectWith(testConfigJson, <String, dynamic>{'id': null}),
      ],
    );

    final customDevicesConfig = CustomDevicesConfig.test(
      fileSystem: fileSystem,
      directory: directory,
      logger: logger,
    );

    const msg = 'Could not load custom device from config index 0: Expected id to be a string.';
    expect(() => customDevicesConfig.devices, throwsA(const CustomDeviceRevivalException(msg)));
    expect(logger.errorText, contains(msg));
  });

  testWithoutContext('CustomDevicesConfig logs error when id is not a string', () {
    final logger = BufferLogger.test();
    final fileSystem = MemoryFileSystem.test();
    final Directory directory = fileSystem.directory('custom_devices_config');

    writeCustomDevicesConfigFile(
      directory,
      json: <dynamic>[
        copyJsonObjectWith(testConfigJson, <String, dynamic>{'id': 1}),
      ],
    );

    final customDevicesConfig = CustomDevicesConfig.test(
      fileSystem: fileSystem,
      directory: directory,
      logger: logger,
    );

    const msg = 'Could not load custom device from config index 0: Expected id to be a string.';
    expect(() => customDevicesConfig.devices, throwsA(const CustomDeviceRevivalException(msg)));
    expect(logger.errorText, contains(msg));
  });

  testWithoutContext('CustomDevicesConfig logs error when label is not a string', () {
    final logger = BufferLogger.test();
    final fileSystem = MemoryFileSystem.test();
    final Directory directory = fileSystem.directory('custom_devices_config');

    writeCustomDevicesConfigFile(
      directory,
      json: <dynamic>[
        copyJsonObjectWith(testConfigJson, <String, dynamic>{'label': 1}),
      ],
    );

    final customDevicesConfig = CustomDevicesConfig.test(
      fileSystem: fileSystem,
      directory: directory,
      logger: logger,
    );

    const msg = 'Could not load custom device from config index 0: Expected label to be a string.';
    expect(() => customDevicesConfig.devices, throwsA(const CustomDeviceRevivalException(msg)));
    expect(logger.errorText, contains(msg));
  });

  testWithoutContext('CustomDevicesConfig loads config when postBuild is null', () {
    final logger = BufferLogger.test();
    final fileSystem = MemoryFileSystem.test();
    final Directory directory = fileSystem.directory('custom_devices_config');

    writeCustomDevicesConfigFile(
      directory,
      json: <dynamic>[
        copyJsonObjectWith(testConfigJson, <String, dynamic>{'postBuild': null}),
      ],
    );

    final customDevicesConfig = CustomDevicesConfig.test(
      fileSystem: fileSystem,
      directory: directory,
      logger: logger,
    );

    expect(customDevicesConfig.devices, hasLength(1));
  });

  testWithoutContext('CustomDevicesConfig loads config without port forwarding', () {
    final logger = BufferLogger.test();
    final fileSystem = MemoryFileSystem.test();
    final Directory directory = fileSystem.directory('custom_devices_config');

    writeCustomDevicesConfigFile(
      directory,
      json: <dynamic>[
        copyJsonObjectWith(testConfigJson, <String, dynamic>{
          'forwardPort': null,
          'forwardPortSuccessRegex': null,
        }),
      ],
    );

    final customDevicesConfig = CustomDevicesConfig.test(
      fileSystem: fileSystem,
      directory: directory,
      logger: logger,
    );

    final List<CustomDeviceConfig> devices = customDevicesConfig.devices;

    expect(devices, hasLength(1));
    expect(devices.first.usesPortForwarding, false);
  });

  testWithoutContext(
    'CustomDevicesConfig logs error when port forward command is given but not regex',
    () {
      final logger = BufferLogger.test();
      final fileSystem = MemoryFileSystem.test();
      final Directory directory = fileSystem.directory('custom_devices_config');

      writeCustomDevicesConfigFile(
        directory,
        json: <dynamic>[
          copyJsonObjectWith(testConfigJson, <String, dynamic>{'forwardPortSuccessRegex': null}),
        ],
      );

      final customDevicesConfig = CustomDevicesConfig.test(
        fileSystem: fileSystem,
        directory: directory,
        logger: logger,
      );

      const msg =
          'Could not load custom device from config index 0: When forwardPort is given, forwardPortSuccessRegex must be specified too.';
      expect(() => customDevicesConfig.devices, throwsA(const CustomDeviceRevivalException(msg)));
      expect(logger.errorText, contains(msg));
    },
  );
}

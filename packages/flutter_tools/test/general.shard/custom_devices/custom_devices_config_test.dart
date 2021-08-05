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
  Map<String, dynamic> overrides
) => Map<String, dynamic>.of(object)..addAll(overrides);

void main() {
  late BufferLogger logger;
  late MemoryFileSystem fileSystem;
  late Directory directory;
  late CustomDevicesConfig config;

  void loadConfig() {
    config = CustomDevicesConfig.test(
      fileSystem: fileSystem,
      directory: directory,
      logger: logger,
    );
  }

  void writeConfig(dynamic json) {
    return writeCustomDevicesConfigFile(
      directory,
      json: json
    );
  }

  group('custom devices config', () {
    setUp(() {
      logger = BufferLogger.test();
      fileSystem = MemoryFileSystem.test();
      directory = fileSystem.directory('custom_devices_config');
    });

    testWithoutContext("CustomDevicesConfig logs no error when 'custom-devices' key is missing in config", () {
      writeConfig(null);
      loadConfig();

      expect(config.devices, hasLength(0));
      expect(logger.errorText, hasLength(0));
    });

    testWithoutContext("CustomDevicesConfig logs error when 'custom-devices' key is not a JSON array", () {

      writeConfig(<String, dynamic>{
        'test': 'testvalue'
      });
      loadConfig();

      const String msg = "Could not load custom devices config. config['custom-devices'] is not a JSON array.";
      expect(() => config.devices, throwsA(const CustomDeviceRevivalException(msg)));
      expect(logger.errorText, contains(msg));
    });

    testWithoutContext('CustomDeviceRevivalException serialization', () {
      expect(
        const CustomDeviceRevivalException('testmessage').toString(),
        equals('testmessage')
      );
      expect(
        const CustomDeviceRevivalException.fromDescriptions('testfielddescription', 'testexpectedvaluedescription').toString(),
        equals('Expected testfielddescription to be testexpectedvaluedescription.')
      );
    });

    testWithoutContext('CustomDevicesConfig can load test config and logs no errors', () {
      writeConfig(<dynamic>[testConfigJson]);
      loadConfig();

      final List<CustomDeviceConfig> devices = config.devices;
      expect(logger.errorText, hasLength(0));
      expect(devices, hasLength(1));
      expect(devices.first, equals(testConfig));
    });

    testWithoutContext('CustomDevicesConfig logs error when id is null', () {
      writeConfig(<dynamic>[
        copyJsonObjectWith(
          testConfigJson,
          <String, dynamic>{
            'id': null
          },
        ),
      ]);

      loadConfig();

      const String msg = 'Could not load custom device from config index 0: Expected id to be a string.';
      expect(() => config.devices, throwsA(const CustomDeviceRevivalException(msg)));
      expect(logger.errorText, contains(msg));
    });

    testWithoutContext('CustomDevicesConfig logs error when id is not a string', () {
      writeConfig(<dynamic>[
        copyJsonObjectWith(
          testConfigJson,
          <String, dynamic>{
            'id': 1
          },
        ),
      ]);
      loadConfig();

      const String msg = 'Could not load custom device from config index 0: Expected id to be a string.';
      expect(() => config.devices, throwsA(const CustomDeviceRevivalException(msg)));
      expect(logger.errorText, contains(msg));
    });

    testWithoutContext('CustomDevicesConfig logs error when label is not a string', () {
      writeConfig(<dynamic>[
        copyJsonObjectWith(
          testConfigJson,
          <String, dynamic>{
            'label': 1
          },
        ),
      ]);
      loadConfig();

      const String msg = 'Could not load custom device from config index 0: Expected label to be a string.';
      expect(() => config.devices, throwsA(const CustomDeviceRevivalException(msg)));
      expect(logger.errorText, contains(msg));
    });

    testWithoutContext('CustomDevicesConfig loads config when postBuild is null', () {
      writeConfig(<dynamic>[
        copyJsonObjectWith(
          testConfigJson,
          <String, dynamic>{
            'postBuild': null
          },
        ),
      ]);
      loadConfig();
      expect(config.devices, hasLength(1));
    });

    testWithoutContext('CustomDevicesConfig loads config without port forwarding', () {
      writeConfig(<dynamic>[
        copyJsonObjectWith(
          testConfigJson,
          <String, dynamic>{
            'forwardPort': null,
            'forwardPortSuccessRegex': null
          },
        ),
      ]);
      loadConfig();

      final List<CustomDeviceConfig> devices = config.devices;
      expect(devices, hasLength(1));
      expect(devices.first.usesPortForwarding, false);
    });

    testWithoutContext('CustomDevicesConfig logs error when port forward command is given but not regex', () {
      writeConfig(<dynamic>[
        copyJsonObjectWith(
          testConfigJson,
          <String, dynamic>{
            'forwardPortSuccessRegex': null
          },
        ),
      ]);
      loadConfig();

      const String msg = 'Could not load custom device from config index 0: When forwardPort is given, forwardPortSuccessRegex must be specified too.';
      expect(() => config.devices, throwsA(const CustomDeviceRevivalException(msg)));
      expect(logger.errorText, contains(msg));
    });

    testWithoutContext('CustomDevicesConfig logs error when embedder name is neither null or a string', () {
      writeConfig(<dynamic>[
        copyJsonObjectWith(
          testConfigJson,
          <String, dynamic>{
            'embedder': 123
          },
        ),
      ]);
      loadConfig();

      const String msg = 'Could not load custom device from config index 0: Expected embedder to be string or null.';
      expect(() => config.devices, throwsA(const CustomDeviceRevivalException(msg)));
      expect(logger.errorText, contains(msg));
    });

    testWithoutContext('CustomDevicesConfig.supportsPlugins works', () {
      writeConfig(<dynamic>[
        copyJsonObjectWith(testConfigJson, const <String, dynamic>{
          'embedder': 'testembedder',
          'configureNativeProject': <String>['testconfigurenativeproject'],
          'buildNativeProject': <String>['testbuildnativeproject'],
        }),
      ]);
      loadConfig();

      expect(config.devices.single.supportsPlugins, isTrue);
    });

    testWithoutContext('CustomDevicesConfig.supportsPlugins works', () {
      writeConfig(<dynamic>[
        copyJsonObjectWith(testConfigJson, const <String, dynamic>{
          'embedder': null,
          'configureNativeProject': <String>['testconfigurenativeproject'],
          'buildNativeProject': <String>['testbuildnativeproject'],
        }),
      ]);
      loadConfig();

      expect(config.devices.single.supportsPlugins, isFalse);
    });

    testWithoutContext('CustomDevicesConfig.supportsPlugins works', () {
      writeConfig(<dynamic>[
        copyJsonObjectWith(testConfigJson, <String, dynamic>{
          'embedder': 'testembeddername',
          'configureNativeProject': null,
          'buildNativeProject': null,
        }),
      ]);
      loadConfig();

      expect(config.devices.single.supportsPlugins, isFalse);
    });

    testWithoutContext('CustomDevicesConfig.supportsPlugins works', () {
      writeConfig(<dynamic>[
        copyJsonObjectWith(testConfigJson, const <String, dynamic>{
          'embedder': 'testembeddername',
          'configureNativeProject': <String>['testconfigurenativeproject'],
          'buildNativeProject': null,
        }),
      ]);
      loadConfig();

      expect(config.devices.single.supportsPlugins, isTrue);
    });
  });
}

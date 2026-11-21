// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:test/test.dart';

void main() {
  group('Category', () {
    test('serializes and parses from string', () {
      expect(Category.fromString('web'), Category.web);
      expect(Category.fromString('desktop'), Category.desktop);
      expect(Category.fromString('mobile'), Category.mobile);
      expect(Category.fromString('other'), Category.other);
      expect(Category.fromString('unknown'), isNull);
      expect(Category.desktop.toString(), 'desktop');
      expect(Category.other.toString(), 'other');
    });
  });

  group('TargetDevice', () {
    test('serializes and deserializes correctly with all fields', () {
      const device = TargetDevice(
        category: Category.desktop,
        id: 'custom_linux_device',
        name: 'Linux Custom Extension Prototype Device',
        buildTarget: 'custom-linux-build',
        ephemeral: false,
        sdkNameAndVersion: 'Custom Linux 1.0.0',
        targetPlatform: 'linux-x64',
      );

      final Map<String, Object?> map = device.toMap();
      expect(map['id'], 'custom_linux_device');
      expect(map['name'], 'Linux Custom Extension Prototype Device');
      expect(map['category'], 'desktop');
      expect(map['buildTarget'], 'custom-linux-build');
      expect(map['ephemeral'], isFalse);
      expect(map['isSupported'], isTrue);
      expect(map['sdkNameAndVersion'], 'Custom Linux 1.0.0');
      expect(map['targetPlatform'], 'linux-x64');

      final parsed = TargetDevice.fromJson(map);
      expect(parsed, equals(device));
      expect(parsed.hashCode, equals(device.hashCode));
      expect(parsed.toString(), contains('custom_linux_device'));
      expect(parsed.toString(), contains('custom-linux-build'));
    });

    test('deserializes correctly with minimal fields and default values', () {
      final minimalJson = <String, Object?>{
        'id': 'minimal_device',
        'name': 'Minimal Device',
        'category': 'mobile',
      };

      final device = TargetDevice.fromJson(minimalJson);
      expect(device.id, 'minimal_device');
      expect(device.name, 'Minimal Device');
      expect(device.category, Category.mobile);
      expect(device.buildTarget, isNull);
      expect(device.ephemeral, isTrue);
      expect(device.isSupported, isTrue);
      expect(device.sdkNameAndVersion, isNull);
      expect(device.targetPlatform, isNull);

      final Map<String, Object?> map = device.toMap();
      expect(map.containsKey('buildTarget'), isFalse);
      expect(map.containsKey('sdkNameAndVersion'), isFalse);
      expect(map.containsKey('targetPlatform'), isFalse);
    });

    test('listFromJson handles valid and invalid lists', () {
      final validJson = <String, Object?>{
        'id': 'device_1',
        'name': 'Device 1',
        'category': 'desktop',
      };

      final List<TargetDevice> devices = TargetDevice.listFromJson(<Object?>[validJson]);
      expect(devices, hasLength(1));
      expect(devices.first.id, 'device_1');
      expect(devices.first.name, 'Device 1');

      expect(TargetDevice.listFromJson(null), isEmpty);
      expect(TargetDevice.listFromJson('invalid'), isEmpty);
    });

    test('equality and hashCode distinguish different devices', () {
      const device1 = TargetDevice(category: Category.desktop, id: 'device_1', name: 'Device 1');
      const device2 = TargetDevice(category: Category.desktop, id: 'device_2', name: 'Device 2');

      expect(device1, isNot(equals(device2)));
      expect(device1.hashCode, isNot(equals(device2.hashCode)));
    });

    test('fromJson throws FormatException when fields have invalid types', () {
      expect(
        () => TargetDevice.fromJson(const <String, Object?>{TargetDevice.idKey: 123}),
        throwsFormatException,
      );
      expect(
        () => TargetDevice.fromJson(const <String, Object?>{TargetDevice.ephemeralKey: 'true'}),
        throwsFormatException,
      );
      expect(
        () => TargetDevice.fromJson(const <String, Object?>{TargetDevice.buildTargetKey: 123}),
        throwsFormatException,
      );
    });
  });

  group('ExtensionDebuggingOptions', () {
    test('serializes and deserializes correctly with default and optional fields', () {
      const defaultOptions = ExtensionDebuggingOptions(buildMode: .debug, debuggingEnabled: true);
      final Map<String, Object?> defaultMap = defaultOptions.toMap();
      expect(defaultMap[ExtensionDebuggingOptions.buildModeKey], 'debug');
      expect(defaultMap[ExtensionDebuggingOptions.debuggingEnabledKey], isTrue);
      expect(defaultMap.containsKey(ExtensionDebuggingOptions.dartEntrypointArgsKey), isFalse);
      expect(defaultMap.containsKey(ExtensionDebuggingOptions.engineSwitchesKey), isFalse);
      expect(defaultMap.containsKey(ExtensionDebuggingOptions.uninstallFirstKey), isFalse);
      expect(defaultMap.containsKey(ExtensionDebuggingOptions.deviceVmServicePortKey), isFalse);
      expect(defaultMap.containsKey(ExtensionDebuggingOptions.hostVmServicePortKey), isFalse);
      expect(defaultMap.containsKey(ExtensionDebuggingOptions.routeKey), isFalse);

      final parsedDefault = ExtensionDebuggingOptions.fromJson(defaultMap);
      expect(parsedDefault, equals(defaultOptions));
      expect(parsedDefault.hashCode, equals(defaultOptions.hashCode));
      expect(parsedDefault.toString(), contains('buildMode: debug'));
      expect(parsedDefault.toString(), contains('debuggingEnabled: true'));

      const fullOptions = ExtensionDebuggingOptions(
        buildMode: .profile,
        dartEntrypointArgs: <String>['--foo', 'bar'],
        debuggingEnabled: true,
        deviceVmServicePort: 8181,
        engineSwitches: <String>['enable-dart-profiling=true', 'start-paused=true'],
        hostVmServicePort: 8282,
        route: '/home',
        uninstallFirst: true,
      );
      final Map<String, Object?> fullMap = fullOptions.toMap();
      expect(fullMap[ExtensionDebuggingOptions.buildModeKey], 'profile');
      expect(
        fullMap[ExtensionDebuggingOptions.dartEntrypointArgsKey],
        equals(<String>['--foo', 'bar']),
      );
      expect(fullMap[ExtensionDebuggingOptions.debuggingEnabledKey], isTrue);
      expect(fullMap[ExtensionDebuggingOptions.deviceVmServicePortKey], 8181);
      expect(
        fullMap[ExtensionDebuggingOptions.engineSwitchesKey],
        equals(<String>['enable-dart-profiling=true', 'start-paused=true']),
      );
      expect(fullMap[ExtensionDebuggingOptions.hostVmServicePortKey], 8282);
      expect(fullMap[ExtensionDebuggingOptions.routeKey], '/home');
      expect(fullMap[ExtensionDebuggingOptions.uninstallFirstKey], isTrue);

      final parsedFull = ExtensionDebuggingOptions.fromJson(fullMap);
      expect(parsedFull, equals(fullOptions));
      expect(parsedFull.hashCode, equals(fullOptions.hashCode));
      expect(parsedFull, isNot(equals(defaultOptions)));
      expect(parsedFull.toString(), contains('route: /home'));
      expect(parsedFull.toString(), contains('uninstallFirst: true'));
    });

    test('validates fields and throws FormatException when missing or invalid', () {
      expect(
        () => ExtensionDebuggingOptions.fromJson(const <String, Object?>{'debuggingEnabled': true}),
        throwsFormatException,
      );
      expect(
        () => ExtensionDebuggingOptions.fromJson(const <String, Object?>{'buildMode': 'release'}),
        throwsFormatException,
      );
      expect(
        () => ExtensionDebuggingOptions.fromJson(const <String, Object?>{}),
        throwsFormatException,
      );
      expect(
        () => ExtensionDebuggingOptions.fromJson(const <String, Object?>{
          'buildMode': 'invalid_mode',
          'debuggingEnabled': true,
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionDebuggingOptions.fromJson(const <String, Object?>{
          'buildMode': 'debug',
          'debuggingEnabled': 'not_a_bool',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionDebuggingOptions.fromJson(const <String, Object?>{
          'buildMode': 'debug',
          'debuggingEnabled': true,
          'engineSwitches': <Object?>[123],
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionDebuggingOptions.fromJson(const <String, Object?>{
          'buildMode': 'debug',
          'debuggingEnabled': true,
          'dartEntrypointArgs': 'not_a_list',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionDebuggingOptions.fromJson(const <String, Object?>{
          'buildMode': 'debug',
          'debuggingEnabled': true,
          'deviceVmServicePort': '8181',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionDebuggingOptions.fromJson(const <String, Object?>{
          'buildMode': 'debug',
          'debuggingEnabled': true,
          'hostVmServicePort': '8282',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionDebuggingOptions.fromJson(const <String, Object?>{
          'buildMode': 'debug',
          'debuggingEnabled': true,
          'route': 42,
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionDebuggingOptions.fromJson(const <String, Object?>{
          'buildMode': 'debug',
          'debuggingEnabled': true,
          'uninstallFirst': 'yes',
        }),
        throwsFormatException,
      );
    });
  });
}

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
    test('serializes and deserializes correctly', () {
      const options = ExtensionDebuggingOptions(buildMode: .debug, debuggingEnabled: true);
      final Map<String, Object?> map = options.toMap();
      expect(map['buildMode'], 'debug');
      expect(map['debuggingEnabled'], isTrue);

      final parsed = ExtensionDebuggingOptions.fromJson(map);
      expect(parsed, equals(options));
      expect(parsed.hashCode, equals(options.hashCode));
      expect(parsed.toString(), contains('buildMode: debug'));
      expect(parsed.toString(), contains('debuggingEnabled: true'));
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
    });
  });

  group('TargetEmulator', () {
    test('serializes and deserializes with full and minimal fields', () {
      const full = TargetEmulator(
        id: 'custom_emulator_1',
        name: 'Custom Emulator 1',
        category: Category.mobile,
        manufacturer: 'Custom Vendor',
      );
      final Map<String, Object?> fullMap = full.toMap();
      expect(fullMap, <String, Object?>{
        TargetEmulator.idKey: 'custom_emulator_1',
        TargetEmulator.nameKey: 'Custom Emulator 1',
        TargetEmulator.categoryKey: 'mobile',
        TargetEmulator.manufacturerKey: 'Custom Vendor',
      });
      final parsedFull = TargetEmulator.fromJson(fullMap);
      expect(parsedFull, equals(full));
      expect(parsedFull.hashCode, equals(full.hashCode));
      expect(
        parsedFull.toString(),
        'TargetEmulator(id: custom_emulator_1, name: Custom Emulator 1, '
        'category: mobile, manufacturer: Custom Vendor)',
      );

      const minimal = TargetEmulator(id: 'minimal_emulator', name: 'Minimal Emulator');
      final Map<String, Object?> minimalMap = minimal.toMap();
      expect(minimalMap, <String, Object?>{
        TargetEmulator.idKey: 'minimal_emulator',
        TargetEmulator.nameKey: 'Minimal Emulator',
      });
      expect(TargetEmulator.fromJson(minimalMap), equals(minimal));
    });

    test('listFromJson and fromJson throw FormatException on invalid payloads', () {
      final List<TargetEmulator> emulators = TargetEmulator.listFromJson(const <Object?>[
        <String, Object?>{TargetEmulator.idKey: 'emu_1', TargetEmulator.nameKey: 'Emulator 1'},
      ]);
      expect(emulators, const <TargetEmulator>[TargetEmulator(id: 'emu_1', name: 'Emulator 1')]);

      for (final invalidList in const <Object?>[
        null,
        'invalid',
        <Object?>['not_a_map'],
      ]) {
        expect(() => TargetEmulator.listFromJson(invalidList), throwsFormatException);
      }
      for (final invalidMap in const <Map<String, Object?>>[
        <String, Object?>{TargetEmulator.nameKey: 'Name'},
        <String, Object?>{TargetEmulator.idKey: '', TargetEmulator.nameKey: 'Name'},
        <String, Object?>{TargetEmulator.idKey: 'id', TargetEmulator.nameKey: ''},
        <String, Object?>{
          TargetEmulator.idKey: 'id',
          TargetEmulator.nameKey: 'Name',
          TargetEmulator.categoryKey: 'unknown_category',
        },
        <String, Object?>{
          TargetEmulator.idKey: 'id',
          TargetEmulator.nameKey: 'Name',
          TargetEmulator.manufacturerKey: 42,
        },
      ]) {
        expect(() => TargetEmulator.fromJson(invalidMap), throwsFormatException);
      }
    });
  });
}

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
        ephemeral: false,
        sdkNameAndVersion: 'Custom Linux 1.0.0',
        targetPlatform: 'linux-x64',
      );

      final Map<String, Object?> map = device.toMap();
      expect(map['id'], 'custom_linux_device');
      expect(map['name'], 'Linux Custom Extension Prototype Device');
      expect(map['category'], 'desktop');
      expect(map['ephemeral'], isFalse);
      expect(map['isSupported'], isTrue);
      expect(map['sdkNameAndVersion'], 'Custom Linux 1.0.0');
      expect(map['targetPlatform'], 'linux-x64');

      final parsed = TargetDevice.fromJson(map);
      expect(parsed, equals(device));
      expect(parsed.hashCode, equals(device.hashCode));
      expect(parsed.toString(), contains('custom_linux_device'));
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
      expect(device.ephemeral, isTrue);
      expect(device.isSupported, isTrue);
      expect(device.sdkNameAndVersion, isNull);
      expect(device.targetPlatform, isNull);

      final Map<String, Object?> map = device.toMap();
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
    });
  });

  group('TargetEmulator', () {
    test('serializes and deserializes correctly with all fields', () {
      const emulator = TargetEmulator(
        id: 'custom_emulator_1',
        name: 'Custom Emulator 1',
        category: Category.mobile,
        manufacturer: 'Custom Vendor',
      );

      final Map<String, Object?> map = emulator.toMap();
      expect(map[TargetEmulator.idKey], 'custom_emulator_1');
      expect(map[TargetEmulator.nameKey], 'Custom Emulator 1');
      expect(map[TargetEmulator.categoryKey], 'mobile');
      expect(map[TargetEmulator.manufacturerKey], 'Custom Vendor');

      final parsed = TargetEmulator.fromJson(map);
      expect(parsed, equals(emulator));
      expect(parsed.hashCode, equals(emulator.hashCode));
      expect(
        parsed.toString(),
        'TargetEmulator(id: custom_emulator_1, name: Custom Emulator 1, '
        'category: mobile, manufacturer: Custom Vendor)',
      );
    });

    test('serializes and deserializes with only required fields', () {
      const emulator = TargetEmulator(id: 'minimal_emulator', name: 'Minimal Emulator');

      final Map<String, Object?> map = emulator.toMap();
      expect(map.containsKey(TargetEmulator.categoryKey), isFalse);
      expect(map.containsKey(TargetEmulator.manufacturerKey), isFalse);

      final parsed = TargetEmulator.fromJson(map);
      expect(parsed, equals(emulator));
      expect(parsed.category, isNull);
      expect(parsed.manufacturer, isNull);
    });

    test('listFromJson handles valid and invalid lists', () {
      final validJson = <String, Object?>{
        TargetEmulator.idKey: 'emu_1',
        TargetEmulator.nameKey: 'Emulator 1',
      };

      final List<TargetEmulator> emulators = TargetEmulator.listFromJson(<Object?>[validJson]);
      expect(emulators, hasLength(1));
      expect(emulators.first.id, 'emu_1');
      expect(emulators.first.name, 'Emulator 1');

      expect(TargetEmulator.listFromJson(null), isEmpty);
      expect(TargetEmulator.listFromJson('invalid'), isEmpty);
    });

    test('fromJson throws FormatException on missing, empty, or invalid fields', () {
      expect(
        () => TargetEmulator.fromJson(const <String, Object?>{TargetEmulator.nameKey: 'Name'}),
        throwsFormatException,
      );
      expect(
        () => TargetEmulator.fromJson(const <String, Object?>{
          TargetEmulator.idKey: '',
          TargetEmulator.nameKey: 'Name',
        }),
        throwsFormatException,
      );
      expect(
        () => TargetEmulator.fromJson(const <String, Object?>{
          TargetEmulator.idKey: 'id',
          TargetEmulator.nameKey: '',
        }),
        throwsFormatException,
      );
      expect(
        () => TargetEmulator.fromJson(const <String, Object?>{
          TargetEmulator.idKey: 'id',
          TargetEmulator.nameKey: 'Name',
          TargetEmulator.categoryKey: 'unknown_category',
        }),
        throwsFormatException,
      );
      expect(
        () => TargetEmulator.fromJson(const <String, Object?>{
          TargetEmulator.idKey: 'id',
          TargetEmulator.nameKey: 'Name',
          TargetEmulator.manufacturerKey: 42,
        }),
        throwsFormatException,
      );
    });
  });
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:test/test.dart';

void main() {
  group('TargetDevice', () {
    test('serializes and deserializes correctly with all fields', () {
      const device = TargetDevice(
        category: 'desktop',
        id: 'custom_linux_device',
        name: 'Linux Custom Extension Prototype Device',
        platformType: 'custom',
        ephemeral: false,
        sdkNameAndVersion: 'Custom Linux 1.0.0',
        targetPlatform: 'linux-x64',
      );

      final Map<String, Object?> map = device.toMap();
      expect(map['id'], 'custom_linux_device');
      expect(map['name'], 'Linux Custom Extension Prototype Device');
      expect(map['category'], 'desktop');
      expect(map['platformType'], 'custom');
      expect(map['ephemeral'], isFalse);
      expect(map['isSupported'], isTrue);
      expect(map['isSupportedForProject'], isTrue);
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
        'platformType': 'android',
      };

      final device = TargetDevice.fromJson(minimalJson);
      expect(device.id, 'minimal_device');
      expect(device.name, 'Minimal Device');
      expect(device.category, 'mobile');
      expect(device.platformType, 'android');
      expect(device.ephemeral, isTrue);
      expect(device.isSupported, isTrue);
      expect(device.isSupportedForProject, isTrue);
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
        'platformType': 'custom',
      };

      final List<TargetDevice> devices = TargetDevice.listFromJson(<Object?>[validJson]);
      expect(devices, hasLength(1));
      expect(devices.first.id, 'device_1');
      expect(devices.first.name, 'Device 1');

      expect(TargetDevice.listFromJson(null), isEmpty);
      expect(TargetDevice.listFromJson('invalid'), isEmpty);
    });

    test('equality and hashCode distinguish different devices', () {
      const device1 = TargetDevice(
        category: 'desktop',
        id: 'device_1',
        name: 'Device 1',
        platformType: 'custom',
      );
      const device2 = TargetDevice(
        category: 'desktop',
        id: 'device_2',
        name: 'Device 2',
        platformType: 'custom',
      );

      expect(device1, isNot(equals(device2)));
      expect(device1.hashCode, isNot(equals(device2.hashCode)));
    });
  });
}

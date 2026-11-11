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
        supportsInstall: true,
        supportsScreenRecording: true,
        supportsScreenshot: true,
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
      expect(map[TargetDevice.supportsInstallKey], isTrue);
      expect(map[TargetDevice.supportsScreenshotKey], isTrue);
      expect(map[TargetDevice.supportsScreenRecordingKey], isTrue);
      expect(map['targetPlatform'], 'linux-x64');

      final parsed = TargetDevice.fromJson(map);
      expect(parsed, equals(device));
      expect(parsed.hashCode, equals(device.hashCode));
      expect(parsed.toString(), contains('custom_linux_device'));
      expect(parsed.toString(), contains('custom-linux-build'));
      expect(parsed.toString(), contains('supportsInstall: true'));
      expect(parsed.toString(), contains('supportsScreenshot: true'));
      expect(parsed.toString(), contains('supportsScreenRecording: true'));
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
      expect(device.supportsInstall, isFalse);
      expect(device.supportsScreenshot, isFalse);
      expect(device.supportsScreenRecording, isFalse);
      expect(device.targetPlatform, isNull);

      final Map<String, Object?> map = device.toMap();
      expect(map.containsKey('buildTarget'), isFalse);
      expect(map.containsKey('sdkNameAndVersion'), isFalse);
      expect(map[TargetDevice.supportsInstallKey], isFalse);
      expect(map[TargetDevice.supportsScreenshotKey], isFalse);
      expect(map[TargetDevice.supportsScreenRecordingKey], isFalse);
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

  group('ExtensionApplicationResolutionContext', () {
    final testProject = ExtensionFlutterProject(
      appName: 'my_app',
      buildDirectory: Uri.parse('file:///tmp/my_app/build/'),
      directory: Uri.parse('file:///tmp/my_app/'),
    );

    test('serializes and deserializes with all fields', () {
      final context = ExtensionApplicationResolutionContext(
        applicationBinaryUri: Uri.parse('file:///tmp/my_app/prebuilt.bin'),
        buildMode: .release,
        deviceId: 'custom_device_1',
        flavor: 'prod',
        project: testProject,
      );

      final Map<String, Object?> map = context.toMap();
      expect(
        map[ExtensionApplicationResolutionContext.applicationBinaryUriKey],
        'file:///tmp/my_app/prebuilt.bin',
      );
      expect(map[ExtensionApplicationResolutionContext.buildModeKey], 'release');
      expect(map[ExtensionApplicationResolutionContext.deviceIdKey], 'custom_device_1');
      expect(map[ExtensionApplicationResolutionContext.flavorKey], 'prod');
      expect(map[ExtensionApplicationResolutionContext.projectKey], testProject.toMap());

      final parsed = ExtensionApplicationResolutionContext.fromJson(map);
      expect(parsed, equals(context));
      expect(parsed.hashCode, equals(context.hashCode));
      expect(parsed.toString(), contains('deviceId: custom_device_1'));
      expect(parsed.toString(), contains('buildMode: release'));
      expect(parsed.toString(), contains('flavor: prod'));
    });

    test('serializes and deserializes with minimal fields', () {
      final context = ExtensionApplicationResolutionContext(
        buildMode: .debug,
        deviceId: 'custom_device_1',
        project: testProject,
      );

      final Map<String, Object?> map = context.toMap();
      expect(
        map.containsKey(ExtensionApplicationResolutionContext.applicationBinaryUriKey),
        isFalse,
      );
      expect(map.containsKey(ExtensionApplicationResolutionContext.flavorKey), isFalse);

      final parsed = ExtensionApplicationResolutionContext.fromJson(map);
      expect(parsed, equals(context));
      expect(parsed.applicationBinaryUri, isNull);
      expect(parsed.flavor, isNull);
    });

    test('validates fields and throws FormatException when missing or invalid', () {
      final Map<String, Object?> validProjectMap = testProject.toMap();
      expect(
        () => ExtensionApplicationResolutionContext.fromJson(<String, Object?>{
          ExtensionApplicationResolutionContext.buildModeKey: 'debug',
          ExtensionApplicationResolutionContext.projectKey: validProjectMap,
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionApplicationResolutionContext.fromJson(<String, Object?>{
          ExtensionApplicationResolutionContext.buildModeKey: 'debug',
          ExtensionApplicationResolutionContext.deviceIdKey: '',
          ExtensionApplicationResolutionContext.projectKey: validProjectMap,
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionApplicationResolutionContext.fromJson(<String, Object?>{
          ExtensionApplicationResolutionContext.buildModeKey: 'invalid_mode',
          ExtensionApplicationResolutionContext.deviceIdKey: 'custom_device_1',
          ExtensionApplicationResolutionContext.projectKey: validProjectMap,
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionApplicationResolutionContext.fromJson(<String, Object?>{
          ExtensionApplicationResolutionContext.applicationBinaryUriKey: 'relative/prebuilt.bin',
          ExtensionApplicationResolutionContext.buildModeKey: 'debug',
          ExtensionApplicationResolutionContext.deviceIdKey: 'custom_device_1',
          ExtensionApplicationResolutionContext.projectKey: validProjectMap,
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionApplicationResolutionContext.fromJson(<String, Object?>{
          ExtensionApplicationResolutionContext.applicationBinaryUriKey: 'file:///',
          ExtensionApplicationResolutionContext.buildModeKey: 'debug',
          ExtensionApplicationResolutionContext.deviceIdKey: 'custom_device_1',
          ExtensionApplicationResolutionContext.projectKey: validProjectMap,
        }),
        throwsFormatException,
      );
      final dirBinaryContext = ExtensionApplicationResolutionContext.fromJson(<String, Object?>{
        ExtensionApplicationResolutionContext.applicationBinaryUriKey: 'file:///tmp/MyApp.app/',
        ExtensionApplicationResolutionContext.buildModeKey: 'debug',
        ExtensionApplicationResolutionContext.deviceIdKey: 'custom_device_1',
        ExtensionApplicationResolutionContext.projectKey: validProjectMap,
      });
      expect(dirBinaryContext.applicationBinaryUri, Uri.parse('file:///tmp/MyApp.app/'));
      expect(
        () => ExtensionApplicationResolutionContext.fromJson(<String, Object?>{
          ExtensionApplicationResolutionContext.buildModeKey: 'debug',
          ExtensionApplicationResolutionContext.deviceIdKey: 'custom_device_1',
          ExtensionApplicationResolutionContext.flavorKey: '',
          ExtensionApplicationResolutionContext.projectKey: validProjectMap,
        }),
        throwsFormatException,
      );
      final validProject = ExtensionFlutterProject.fromJson(validProjectMap);
      expect(
        () => ExtensionApplicationResolutionContext(
          buildMode: .debug,
          deviceId: '',
          project: validProject,
        ),
        throwsFormatException,
      );
      expect(
        () => ExtensionApplicationResolutionContext(
          applicationBinaryUri: Uri.parse('relative/app.pkg'),
          buildMode: .debug,
          deviceId: 'custom_device_1',
          project: validProject,
        ),
        throwsFormatException,
      );
      expect(
        () => ExtensionApplicationResolutionContext(
          buildMode: .debug,
          deviceId: 'custom_device_1',
          flavor: '',
          project: validProject,
        ),
        throwsFormatException,
      );
    });
  });

  group('ExtensionApplicationPackage', () {
    test('serializes and deserializes with file, directory, and null bundleUri', () {
      final withBundle = ExtensionApplicationPackage(
        appId: 'com.example.my_app',
        bundleUri: Uri.parse('file:///tmp/build/my_app.pkg'),
      );
      final Map<String, Object?> map = withBundle.toMap();
      expect(map[ExtensionApplicationPackage.appIdKey], 'com.example.my_app');
      expect(map[ExtensionApplicationPackage.bundleUriKey], 'file:///tmp/build/my_app.pkg');

      final parsed = ExtensionApplicationPackage.fromJson(map);
      expect(parsed, equals(withBundle));
      expect(parsed.hashCode, equals(withBundle.hashCode));
      expect(parsed.toString(), contains('com.example.my_app'));

      final withDirBundle = ExtensionApplicationPackage(
        appId: 'com.example.my_app',
        bundleUri: Uri.parse('file:///tmp/build/bundle/'),
      );
      expect(ExtensionApplicationPackage.fromJson(withDirBundle.toMap()), equals(withDirBundle));

      final withoutBundle = ExtensionApplicationPackage(appId: 'com.example.my_app');
      final Map<String, Object?> minimalMap = withoutBundle.toMap();
      expect(minimalMap.containsKey(ExtensionApplicationPackage.bundleUriKey), isFalse);
      expect(ExtensionApplicationPackage.fromJson(minimalMap), equals(withoutBundle));
      expect(withoutBundle, isNot(equals(withBundle)));
    });

    test('validates fields and throws FormatException when missing or invalid', () {
      expect(
        () => ExtensionApplicationPackage.fromJson(const <String, Object?>{}),
        throwsFormatException,
      );
      expect(
        () => ExtensionApplicationPackage.fromJson(const <String, Object?>{
          ExtensionApplicationPackage.appIdKey: '',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionApplicationPackage.fromJson(const <String, Object?>{
          ExtensionApplicationPackage.appIdKey: 'com.example.my_app',
          ExtensionApplicationPackage.bundleUriKey: 'relative/bundle.pkg',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionApplicationPackage.fromJson(const <String, Object?>{
          ExtensionApplicationPackage.appIdKey: 'com.example.my_app',
          ExtensionApplicationPackage.bundleUriKey: 'file:///',
        }),
        throwsFormatException,
      );
      expect(() => ExtensionApplicationPackage(appId: ''), throwsFormatException);
      expect(
        () => ExtensionApplicationPackage(
          appId: 'com.example.my_app',
          bundleUri: Uri.parse('http://example.com/app.pkg'),
        ),
        throwsFormatException,
      );
    });
  });
}

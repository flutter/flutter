// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(cyanglaz): Remove once https://github.com/flutter/flutter/issues/59879 is fixed.
// @dart = 2.9

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:device_info_platform_interface/device_info_platform_interface.dart';
import 'package:device_info_platform_interface/method_channel/method_channel_device_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("$MethodChannelDeviceInfo", () {
    MethodChannelDeviceInfo methodChannelDeviceInfo;

    setUp(() async {
      methodChannelDeviceInfo = MethodChannelDeviceInfo();

      methodChannelDeviceInfo.channel
          .setMockMethodCallHandler((MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getAndroidDeviceInfo':
            return ({
              "version": <String, dynamic>{
                "securityPatch": "2018-09-05",
                "sdkInt": 28,
                "release": "9",
                "previewSdkInt": 0,
                "incremental": "5124027",
                "codename": "REL",
                "baseOS": "",
              },
              "board": "goldfish_x86_64",
              "bootloader": "unknown",
              "brand": "google",
              "device": "generic_x86_64",
              "display": "PSR1.180720.075",
              "fingerprint":
                  "google/sdk_gphone_x86_64/generic_x86_64:9/PSR1.180720.075/5124027:user/release-keys",
              "hardware": "ranchu",
              "host": "abfarm730",
              "id": "PSR1.180720.075",
              "manufacturer": "Google",
              "model": "Android SDK built for x86_64",
              "product": "sdk_gphone_x86_64",
              "supported32BitAbis": <String>[
                "x86",
              ],
              "supported64BitAbis": <String>[
                "x86_64",
              ],
              "supportedAbis": <String>[
                "x86_64",
                "x86",
              ],
              "tags": "release-keys",
              "type": "user",
              "isPhysicalDevice": false,
              "androidId": "f47571f3b4648f45",
              "systemFeatures": <String>[
                "android.hardware.sensor.proximity",
                "android.software.adoptable_storage",
                "android.hardware.sensor.accelerometer",
                "android.hardware.faketouch",
                "android.software.backup",
                "android.hardware.touchscreen",
              ],
            });
          case 'getIosDeviceInfo':
            return ({
              "name": "iPhone 13",
              "systemName": "iOS",
              "systemVersion": "13.0",
              "model": "iPhone",
              "localizedModel": "iPhone",
              "identifierForVendor": "88F59280-55AD-402C-B922-3203B4794C06",
              "isPhysicalDevice": false,
              "utsname": <String, dynamic>{
                "sysname": "Darwin",
                "nodename": "host",
                "release": "19.6.0",
                "version":
                    "Darwin Kernel Version 19.6.0: Thu Jun 18 20:49:00 PDT 2020; root:xnu-6153.141.1~1/RELEASE_X86_64",
                "machine": "x86_64",
              }
            });
          default:
            return null;
        }
      });
    });

    test("androidInfo", () async {
      final AndroidDeviceInfo result =
          await methodChannelDeviceInfo.androidInfo();

      expect(result.version.securityPatch, "2018-09-05");
      expect(result.version.sdkInt, 28);
      expect(result.version.release, "9");
      expect(result.version.previewSdkInt, 0);
      expect(result.version.incremental, "5124027");
      expect(result.version.codename, "REL");
      expect(result.board, "goldfish_x86_64");
      expect(result.bootloader, "unknown");
      expect(result.brand, "google");
      expect(result.device, "generic_x86_64");
      expect(result.display, "PSR1.180720.075");
      expect(result.fingerprint,
          "google/sdk_gphone_x86_64/generic_x86_64:9/PSR1.180720.075/5124027:user/release-keys");
      expect(result.hardware, "ranchu");
      expect(result.host, "abfarm730");
      expect(result.id, "PSR1.180720.075");
      expect(result.manufacturer, "Google");
      expect(result.model, "Android SDK built for x86_64");
      expect(result.product, "sdk_gphone_x86_64");
      expect(result.supported32BitAbis, <String>[
        "x86",
      ]);
      expect(result.supported64BitAbis, <String>[
        "x86_64",
      ]);
      expect(result.supportedAbis, <String>[
        "x86_64",
        "x86",
      ]);
      expect(result.tags, "release-keys");
      expect(result.type, "user");
      expect(result.isPhysicalDevice, false);
      expect(result.androidId, "f47571f3b4648f45");
      expect(result.systemFeatures, <String>[
        "android.hardware.sensor.proximity",
        "android.software.adoptable_storage",
        "android.hardware.sensor.accelerometer",
        "android.hardware.faketouch",
        "android.software.backup",
        "android.hardware.touchscreen",
      ]);
    });

    test("iosInfo", () async {
      final IosDeviceInfo result = await methodChannelDeviceInfo.iosInfo();
      expect(result.name, "iPhone 13");
      expect(result.systemName, "iOS");
      expect(result.systemVersion, "13.0");
      expect(result.model, "iPhone");
      expect(result.localizedModel, "iPhone");
      expect(
          result.identifierForVendor, "88F59280-55AD-402C-B922-3203B4794C06");
      expect(result.isPhysicalDevice, false);
      expect(result.utsname.sysname, "Darwin");
      expect(result.utsname.nodename, "host");
      expect(result.utsname.release, "19.6.0");
      expect(result.utsname.version,
          "Darwin Kernel Version 19.6.0: Thu Jun 18 20:49:00 PDT 2020; root:xnu-6153.141.1~1/RELEASE_X86_64");
      expect(result.utsname.machine, "x86_64");
    });
  });

  group(
      "$MethodChannelDeviceInfo handles null value in the map returned from method channel",
      () {
    MethodChannelDeviceInfo methodChannelDeviceInfo;

    setUp(() async {
      methodChannelDeviceInfo = MethodChannelDeviceInfo();

      methodChannelDeviceInfo.channel
          .setMockMethodCallHandler((MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getAndroidDeviceInfo':
            return ({
              "version": null,
              "board": null,
              "bootloader": null,
              "brand": null,
              "device": null,
              "display": null,
              "fingerprint": null,
              "hardware": null,
              "host": null,
              "id": null,
              "manufacturer": null,
              "model": null,
              "product": null,
              "supported32BitAbis": null,
              "supported64BitAbis": null,
              "supportedAbis": null,
              "tags": null,
              "type": null,
              "isPhysicalDevice": null,
              "androidId": null,
              "systemFeatures": null,
            });
          case 'getIosDeviceInfo':
            return ({
              "name": null,
              "systemName": null,
              "systemVersion": null,
              "model": null,
              "localizedModel": null,
              "identifierForVendor": null,
              "isPhysicalDevice": null,
              "utsname": null,
            });
          default:
            return null;
        }
      });
    });

    test("androidInfo hanels null", () async {
      final AndroidDeviceInfo result =
          await methodChannelDeviceInfo.androidInfo();

      expect(result.version.securityPatch, null);
      expect(result.version.sdkInt, -1);
      expect(result.version.release, '');
      expect(result.version.previewSdkInt, null);
      expect(result.version.incremental, '');
      expect(result.version.codename, '');
      expect(result.board, '');
      expect(result.bootloader, '');
      expect(result.brand, '');
      expect(result.device, '');
      expect(result.display, '');
      expect(result.fingerprint, '');
      expect(result.hardware, '');
      expect(result.host, '');
      expect(result.id, '');
      expect(result.manufacturer, '');
      expect(result.model, '');
      expect(result.product, '');
      expect(result.supported32BitAbis, <String>[]);
      expect(result.supported64BitAbis, <String>[]);
      expect(result.supportedAbis, <String>[]);
      expect(result.tags, '');
      expect(result.type, '');
      expect(result.isPhysicalDevice, false);
      expect(result.androidId, '');
      expect(result.systemFeatures, <String>[]);
    });

    test("iosInfo handles null", () async {
      final IosDeviceInfo result = await methodChannelDeviceInfo.iosInfo();
      expect(result.name, '');
      expect(result.systemName, '');
      expect(result.systemVersion, '');
      expect(result.model, '');
      expect(result.localizedModel, '');
      expect(result.identifierForVendor, '');
      expect(result.isPhysicalDevice, false);
      expect(result.utsname.sysname, '');
      expect(result.utsname.nodename, '');
      expect(result.utsname.release, '');
      expect(result.utsname.version, '');
      expect(result.utsname.machine, '');
    });
  });

  group("$MethodChannelDeviceInfo handles method channel returns null", () {
    MethodChannelDeviceInfo methodChannelDeviceInfo;

    setUp(() async {
      methodChannelDeviceInfo = MethodChannelDeviceInfo();

      methodChannelDeviceInfo.channel
          .setMockMethodCallHandler((MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getAndroidDeviceInfo':
            return null;
          case 'getIosDeviceInfo':
            return null;
          default:
            return null;
        }
      });
    });

    test("androidInfo handles null", () async {
      final AndroidDeviceInfo result =
          await methodChannelDeviceInfo.androidInfo();

      expect(result.version.securityPatch, null);
      expect(result.version.sdkInt, -1);
      expect(result.version.release, '');
      expect(result.version.previewSdkInt, null);
      expect(result.version.incremental, '');
      expect(result.version.codename, '');
      expect(result.board, '');
      expect(result.bootloader, '');
      expect(result.brand, '');
      expect(result.device, '');
      expect(result.display, '');
      expect(result.fingerprint, '');
      expect(result.hardware, '');
      expect(result.host, '');
      expect(result.id, '');
      expect(result.manufacturer, '');
      expect(result.model, '');
      expect(result.product, '');
      expect(result.supported32BitAbis, <String>[]);
      expect(result.supported64BitAbis, <String>[]);
      expect(result.supportedAbis, <String>[]);
      expect(result.tags, '');
      expect(result.type, '');
      expect(result.isPhysicalDevice, false);
      expect(result.androidId, '');
      expect(result.systemFeatures, <String>[]);
    });

    test("iosInfo handles null", () async {
      final IosDeviceInfo result = await methodChannelDeviceInfo.iosInfo();
      expect(result.name, '');
      expect(result.systemName, '');
      expect(result.systemVersion, '');
      expect(result.model, '');
      expect(result.localizedModel, '');
      expect(result.identifierForVendor, '');
      expect(result.isPhysicalDevice, false);
      expect(result.utsname.sysname, '');
      expect(result.utsname.nodename, '');
      expect(result.utsname.release, '');
      expect(result.utsname.version, '');
      expect(result.utsname.machine, '');
    });
  });

  group("$MethodChannelDeviceInfo android handles null values in list", () {
    MethodChannelDeviceInfo methodChannelDeviceInfo;

    setUp(() async {
      methodChannelDeviceInfo = MethodChannelDeviceInfo();

      methodChannelDeviceInfo.channel
          .setMockMethodCallHandler((MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getAndroidDeviceInfo':
            return ({
              "supported32BitAbis": <String>["x86", null],
              "supported64BitAbis": <String>["x86_64", null],
              "supportedAbis": <String>["x86_64", "x86", null],
              "systemFeatures": <String>[
                "android.hardware.sensor.proximity",
                "android.software.adoptable_storage",
                "android.hardware.sensor.accelerometer",
                "android.hardware.faketouch",
                "android.software.backup",
                "android.hardware.touchscreen",
                null
              ],
            });
          default:
            return null;
        }
      });
    });

    test("androidInfo hanels null in list", () async {
      final AndroidDeviceInfo result =
          await methodChannelDeviceInfo.androidInfo();
      expect(result.supported32BitAbis, <String>['x86']);
      expect(result.supported64BitAbis, <String>['x86_64']);
      expect(result.supportedAbis, <String>['x86_64', 'x86']);
      expect(result.systemFeatures, <String>[
        "android.hardware.sensor.proximity",
        "android.software.adoptable_storage",
        "android.hardware.sensor.accelerometer",
        "android.hardware.faketouch",
        "android.software.backup",
        "android.hardware.touchscreen"
      ]);
    });
  });
}

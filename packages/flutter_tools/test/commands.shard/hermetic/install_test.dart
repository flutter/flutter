// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';
import 'package:flutter_tools/src/android/application_package.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/install.dart';
import 'package:flutter_tools/src/ios/application_package.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  group('install', () {
    setUpAll(() {
      Cache.disableLocking();
    });

    testUsingContext('returns 0 when Android is connected and ready for an install', () async {
      final InstallCommand command = InstallCommand();
      command.applicationPackages = FakeApplicationPackageFactory(FakeAndroidApk());

      final MockAndroidDevice device = MockAndroidDevice();
      when(device.isAppInstalled(any, userIdentifier: anyNamed('userIdentifier')))
        .thenAnswer((_) async => false);
      when(device.installApp(any, userIdentifier: anyNamed('userIdentifier')))
        .thenAnswer((_) async => true);
      testDeviceManager.addDevice(device);

      await createTestCommandRunner(command).run(<String>['install']);
    }, overrides: <Type, Generator>{
      Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    });

    testUsingContext('returns 1 when targeted device is not Android with --device-user', () async {
      final InstallCommand command = InstallCommand();
      command.applicationPackages = FakeApplicationPackageFactory(FakeAndroidApk());

      final MockIOSDevice device = MockIOSDevice();
      when(device.isAppInstalled(any, userIdentifier: anyNamed('userIdentifier')))
        .thenAnswer((_) async => false);
      when(device.installApp(any, userIdentifier: anyNamed('userIdentifier')))
        .thenAnswer((_) async => true);
      testDeviceManager.addDevice(device);

      expect(() async => createTestCommandRunner(command).run(<String>['install', '--device-user', '10']),
        throwsToolExit(message: '--device-user is only supported for Android'));
    }, overrides: <Type, Generator>{
      Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    });

    testUsingContext('returns 0 when iOS is connected and ready for an install', () async {
      final InstallCommand command = InstallCommand();
      command.applicationPackages = FakeApplicationPackageFactory(FakeIOSApp());

      final MockIOSDevice device = MockIOSDevice();
      when(device.isAppInstalled(any)).thenAnswer((_) async => false);
      when(device.installApp(any)).thenAnswer((_) async => true);
      testDeviceManager.addDevice(device);

      await createTestCommandRunner(command).run(<String>['install']);
    }, overrides: <Type, Generator>{
      Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    });
  });
}

class FakeApplicationPackageFactory extends Fake implements ApplicationPackageFactory {
  FakeApplicationPackageFactory(this.app);

  final ApplicationPackage app;

  @override
  Future<ApplicationPackage> getPackageForPlatform(TargetPlatform platform, {BuildInfo buildInfo, File applicationBinary}) async {
    return app;
  }
}
class FakeIOSApp extends Fake implements IOSApp {}
class FakeAndroidApk extends Fake implements AndroidApk {}

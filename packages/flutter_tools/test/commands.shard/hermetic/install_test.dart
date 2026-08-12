// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/android/application_package.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/install.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/application_package.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  group('install', () {
    setUpAll(() {
      Cache.disableLocking();
    });

    late FileSystem fileSystem;
    late BufferLogger logger;
    late FakeToolContext toolContext;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      fileSystem.file('pubspec.yaml').createSync(recursive: true);
      logger = BufferLogger.test();
      toolContext = FakeToolContext(fs: fileSystem, logger: logger);
    });

    testUsingContext('returns 0 when Android is connected and ready for an install', () async {
      final command = InstallCommand(toolContext: toolContext, verboseHelp: false);
      command.applicationPackages = FakeApplicationPackageFactory(FakeAndroidApk());

      final device = FakeAndroidDevice();
      testDeviceManager.addAttachedDevice(device);

      await createTestCommandRunner(command).run(<String>['install']);
      expect(logger.statusText, contains('Installing FakeAndroidApk to Android...'));
    });

    testUsingContext('returns 1 when targeted device is not Android with --device-user', () async {
      final command = InstallCommand(toolContext: toolContext, verboseHelp: false);
      command.applicationPackages = FakeApplicationPackageFactory(FakeAndroidApk());

      final device = FakeIOSDevice();
      testDeviceManager.addAttachedDevice(device);

      expect(
        () async =>
            createTestCommandRunner(command).run(<String>['install', '--device-user', '10']),
        throwsToolExit(message: '--device-user is only supported for Android'),
      );
    });

    testUsingContext('returns 0 when iOS is connected and ready for an install', () async {
      final command = InstallCommand(toolContext: toolContext, verboseHelp: false);
      command.applicationPackages = FakeApplicationPackageFactory(FakeIOSApp());

      final device = FakeIOSDevice();
      testDeviceManager.addAttachedDevice(device);

      await createTestCommandRunner(command).run(<String>['install']);
      expect(logger.statusText, contains('Installing FakeIOSApp to iOS...'));
    });

    testUsingContext('fails when prebuilt binary not found', () async {
      final command = InstallCommand(toolContext: toolContext, verboseHelp: false);
      command.applicationPackages = FakeApplicationPackageFactory(FakeAndroidApk());

      final device = FakeAndroidDevice();
      testDeviceManager.addAttachedDevice(device);

      expect(
        () async => createTestCommandRunner(
          command,
        ).run(<String>['install', '--use-application-binary', 'bogus']),
        throwsToolExit(message: 'Prebuilt binary bogus does not exist'),
      );
    });

    testUsingContext('succeeds using prebuilt binary', () async {
      final command = InstallCommand(toolContext: toolContext, verboseHelp: false);
      command.applicationPackages = FakeApplicationPackageFactory(FakeAndroidApk());

      final device = FakeAndroidDevice();
      testDeviceManager.addAttachedDevice(device);
      fileSystem.file('binary').createSync(recursive: true);

      await createTestCommandRunner(
        command,
      ).run(<String>['install', '--use-application-binary', 'binary']);
      expect(logger.statusText, contains('Installing FakeAndroidApk to Android...'));
    });

    testUsingContext('Passes flavor to application package.', () async {
      const flavor = 'free';
      final command = InstallCommand(toolContext: toolContext, verboseHelp: false);
      final fakeAppFactory = FakeApplicationPackageFactory(FakeIOSApp());
      command.applicationPackages = fakeAppFactory;

      final device = FakeIOSDevice();
      testDeviceManager.addAttachedDevice(device);

      await createTestCommandRunner(command).run(<String>['install', '--flavor', flavor]);
      expect(fakeAppFactory.buildInfo, isNotNull);
      expect(fakeAppFactory.buildInfo!.flavor, flavor);
    });

    testUsingContext(
      'uninstalls app when --uninstall-only is provided and app is installed',
      () async {
        final command = InstallCommand(toolContext: toolContext, verboseHelp: false);
        command.applicationPackages = FakeApplicationPackageFactory(FakeAndroidApk());

        final device = FakeAndroidDevice(appInstalled: true);
        testDeviceManager.addAttachedDevice(device);

        await createTestCommandRunner(command).run(<String>['install', '--uninstall-only']);
        expect(logger.statusText, contains('Uninstalling FakeAndroidApk from Android...'));
        expect(device.uninstalled, isTrue);
      },
    );

    testUsingContext(
      'skips uninstall when --uninstall-only is provided and app is not installed',
      () async {
        final command = InstallCommand(toolContext: toolContext, verboseHelp: false);
        command.applicationPackages = FakeApplicationPackageFactory(FakeAndroidApk());

        final device = FakeAndroidDevice();
        testDeviceManager.addAttachedDevice(device);

        await createTestCommandRunner(command).run(<String>['install', '--uninstall-only']);
        expect(
          logger.statusText,
          contains('FakeAndroidApk not found on Android, skipping uninstall'),
        );
        expect(device.uninstalled, isFalse);
      },
    );

    testWithoutContext('installApp uninstalls old version if already installed', () async {
      final testLogger = BufferLogger.test();
      final device = FakeAndroidDevice(appInstalled: true);
      final app = FakeAndroidApk();

      final bool result = await installApp(device, app, logger: testLogger);
      expect(result, isTrue);
      expect(device.uninstalled, isTrue);
      expect(testLogger.statusText, contains('Uninstalling old version...'));
    });

    testWithoutContext('installApp logs warning if uninstalling old version fails', () async {
      final testLogger = BufferLogger.test();
      final device = FakeAndroidDevice(appInstalled: true, uninstallSucceeds: false);
      final app = FakeAndroidApk();

      final bool result = await installApp(device, app, logger: testLogger);
      expect(result, isTrue);
      expect(testLogger.warningText, contains('Warning: uninstalling old version failed'));
    });

    testWithoutContext('installApp logs error when ProcessException is thrown', () async {
      final testLogger = BufferLogger.test();
      final device = _ThrowingDevice();
      final app = FakeAndroidApk();

      final bool result = await installApp(device, app, logger: testLogger);
      expect(result, isTrue);
      expect(testLogger.errorText, contains('Error accessing device throwing-device:'));
      expect(testLogger.errorText, contains('ADB failed'));
    });
  });
}

class FakeApplicationPackageFactory extends Fake implements ApplicationPackageFactory {
  FakeApplicationPackageFactory(this.app);

  final ApplicationPackage app;
  BuildInfo? buildInfo;

  @override
  Future<ApplicationPackage> getPackageForPlatform(
    TargetPlatform platform, {
    BuildInfo? buildInfo,
    File? applicationBinary,
  }) async {
    this.buildInfo = buildInfo;
    return app;
  }
}

class FakeIOSApp extends Fake implements IOSApp {
  @override
  String toString() => 'FakeIOSApp';
}

class FakeAndroidApk extends Fake implements AndroidApk {
  @override
  String toString() => 'FakeAndroidApk';
}

class FakeIOSDevice extends Fake implements IOSDevice {
  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.ios;

  @override
  Future<bool> isAppInstalled(ApplicationPackage app, {String? userIdentifier}) async => false;

  @override
  Future<bool> installApp(IOSApp app, {String? userIdentifier}) async => true;

  @override
  String get name => 'iOS';

  @override
  String toString() => 'iOS';
}

class FakeAndroidDevice extends Fake implements AndroidDevice {
  FakeAndroidDevice({this.appInstalled = false, this.uninstallSucceeds = true});

  final bool appInstalled;
  final bool uninstallSucceeds;
  bool uninstalled = false;

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.android_arm;

  @override
  Future<bool> isAppInstalled(ApplicationPackage app, {String? userIdentifier}) async =>
      appInstalled;

  @override
  Future<bool> uninstallApp(ApplicationPackage app, {String? userIdentifier}) async {
    uninstalled = true;
    return uninstallSucceeds;
  }

  @override
  Future<bool> installApp(AndroidApk app, {String? userIdentifier}) async => true;

  @override
  String get name => 'Android';

  @override
  bool get ephemeral => true;

  @override
  String toString() => 'Android';
}

class _ThrowingDevice extends Fake implements Device {
  @override
  String get id => 'throwing-device';

  @override
  Future<bool> isAppInstalled(ApplicationPackage app, {String? userIdentifier}) async {
    throw const ProcessException('adb', <String>['shell'], 'ADB failed');
  }

  @override
  Future<bool> installApp(ApplicationPackage app, {String? userIdentifier}) async => true;
}

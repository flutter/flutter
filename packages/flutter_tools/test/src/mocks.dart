// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/build_configuration.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/toolchain.dart';
import 'package:mockito/mockito.dart';

import 'context.dart';

class MockApplicationPackageStore extends ApplicationPackageStore {
  MockApplicationPackageStore() : super(
    android: new AndroidApk(localPath: '/mock/path/to/android/SkyShell.apk'),
    iOS: new IOSApp(
      iosProjectDir: '/mock/path/to/iOS/SkyShell.app',
      iosProjectBundleId: 'io.flutter.ios.mock'
    )
  );
}

class MockCompiler extends Mock implements Compiler {
}

class MockToolchain extends Toolchain {
  MockToolchain() : super(compiler: new MockCompiler());
}

class MockAndroidDevice extends Mock implements AndroidDevice {
  TargetPlatform get platform => TargetPlatform.android;
  bool isSupported() => true;
}

class MockIOSDevice extends Mock implements IOSDevice {
  TargetPlatform get platform => TargetPlatform.iOS;
  bool isSupported() => true;
}

class MockIOSSimulator extends Mock implements IOSSimulator {
  TargetPlatform get platform => TargetPlatform.iOSSimulator;
  bool isSupported() => true;
}

class MockDeviceStore extends DeviceStore {
  MockDeviceStore() : super(
    android: new MockAndroidDevice(),
    iOS: new MockIOSDevice(),
    iOSSimulator: new MockIOSSimulator());
}

void applyMocksToCommand(FlutterCommand command, { bool noDevices: false }) {
  command
    ..applicationPackages = new MockApplicationPackageStore()
    ..toolchain = new MockToolchain()
    ..devices = new MockDeviceStore()
    ..projectRootValidator = () => true;

  if (!noDevices)
    testDeviceManager.addDevice(command.devices.android);
}

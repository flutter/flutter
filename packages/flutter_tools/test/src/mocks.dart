// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:mockito/mockito.dart';
import 'package:sky_tools/src/application_package.dart';
import 'package:sky_tools/src/build_configuration.dart';
import 'package:sky_tools/src/commands/flutter_command.dart';
import 'package:sky_tools/src/device.dart';
import 'package:sky_tools/src/toolchain.dart';

class MockApplicationPackageStore extends ApplicationPackageStore {
  MockApplicationPackageStore() : super(
    android: new AndroidApk(localPath: '/mock/path/to/android/SkyShell.apk'),
    iOS: new IOSApp(localPath: '/mock/path/to/iOS/SkyShell.app'),
    iOSSimulator: new IOSApp(localPath: '/mock/path/to/iOSSimulator/SkyShell.app'));
}

class MockCompiler extends Mock implements Compiler {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockToolchain extends Toolchain {
  MockToolchain() : super(compiler: new MockCompiler());
}

class MockAndroidDevice extends Mock implements AndroidDevice {
  TargetPlatform get platform => TargetPlatform.android;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockIOSDevice extends Mock implements IOSDevice {
  TargetPlatform get platform => TargetPlatform.iOS;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockIOSSimulator extends Mock implements IOSSimulator {
  TargetPlatform get platform => TargetPlatform.iOSSimulator;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDeviceStore extends DeviceStore {
  MockDeviceStore() : super(
    android: new MockAndroidDevice(),
    iOS: new MockIOSDevice(),
    iOSSimulator: new MockIOSSimulator());
}

void applyMocksToCommand(FlutterCommand command) {
  command
    ..applicationPackages = new MockApplicationPackageStore()
    ..toolchain = new MockToolchain()
    ..devices = new MockDeviceStore();
}

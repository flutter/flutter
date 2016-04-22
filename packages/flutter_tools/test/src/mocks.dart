// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/build_configuration.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/toolchain.dart';
import 'package:mockito/mockito.dart';

class MockApplicationPackageStore extends ApplicationPackageStore {
  MockApplicationPackageStore() : super(
    android: new AndroidApk(
      localPath: '/mock/path/to/android/SkyShell.apk',
      id: 'io.flutter.android.mock',
      launchActivity: 'io.flutter.android.mock.MockActivity'
    ),
    iOS: new IOSApp(
      iosProjectDir: '/mock/path/to/iOS/SkyShell.app',
      iosProjectBundleId: 'io.flutter.ios.mock'
    )
  );
}

class MockSnapshotCompiler extends Mock implements SnapshotCompiler {
}

class MockToolchain extends Toolchain {
  MockToolchain() : super(compiler: new MockSnapshotCompiler());
}

class MockAndroidDevice extends Mock implements AndroidDevice {
  @override
  TargetPlatform get platform => TargetPlatform.android_arm;

  @override
  bool isSupported() => true;
}

class MockIOSDevice extends Mock implements IOSDevice {
  @override
  TargetPlatform get platform => TargetPlatform.ios;

  @override
  bool isSupported() => true;
}

class MockIOSSimulator extends Mock implements IOSSimulator {
  @override
  TargetPlatform get platform => TargetPlatform.ios;

  @override
  bool isSupported() => true;
}

class MockDeviceLogReader extends DeviceLogReader {
  @override
  String get name => 'MockLogReader';

  final StreamController<String> _linesController = new StreamController<String>.broadcast();

  @override
  Stream<String> get logLines => _linesController.stream;

  void addLine(String line) => _linesController.add(line);
}

void applyMocksToCommand(FlutterCommand command) {
  command
    ..applicationPackages = new MockApplicationPackageStore()
    ..toolchain = new MockToolchain()
    ..commandValidator = () => true;
}

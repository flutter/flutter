// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:mockito/mockito.dart';

class MockApplicationPackageStore extends ApplicationPackageStore {
  MockApplicationPackageStore() : super(
    android: new AndroidApk(
      id: 'io.flutter.android.mock',
      apkPath: '/mock/path/to/android/SkyShell.apk',
      launchActivity: 'io.flutter.android.mock.MockActivity'
    ),
    iOS: new IOSApp(
      appDirectory: '/mock/path/to/iOS/SkyShell.app',
      projectBundleId: 'io.flutter.ios.mock'
    )
  );
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

  void dispose() {
    _linesController.close();
  }
}

void applyMocksToCommand(FlutterCommand command) {
  command
    ..applicationPackages = new MockApplicationPackageStore()
    ..commandValidator = () => true;
}

class MockDevFSOperations implements DevFSOperations {
  final List<String> messages = new List<String>();

  bool contains(String match) {
    print('Checking for `$match` in:');
    print(messages);
    bool result = messages.contains(match);
    messages.clear();
    return result;
  }

  @override
  Future<Uri> create(String fsName) async {
    messages.add('create $fsName');
    return Uri.parse('file:///$fsName');
  }

  @override
  Future<dynamic> destroy(String fsName) async {
    messages.add('destroy $fsName');
  }

  @override
  Future<dynamic> writeFile(String fsName, DevFSEntry entry) async {
    messages.add('writeFile $fsName ${entry.devicePath}');
  }

  @override
  Future<dynamic> deleteFile(String fsName, DevFSEntry entry) async {
    messages.add('deleteFile $fsName ${entry.devicePath}');
  }

  @override
  Future<dynamic> writeSource(String fsName,
                              String devicePath,
                              String contents) async {
    messages.add('writeSource $fsName $devicePath');
  }
}

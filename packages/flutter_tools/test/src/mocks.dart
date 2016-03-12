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
  TargetPlatform get platform => TargetPlatform.android_arm;
  bool isSupported() => true;
}

class MockIOSDevice extends Mock implements IOSDevice {
  TargetPlatform get platform => TargetPlatform.ios_arm;
  bool isSupported() => true;
}

class MockIOSSimulator extends Mock implements IOSSimulator {
  TargetPlatform get platform => TargetPlatform.ios_x64;
  bool isSupported() => true;
}

class MockDeviceLogReader extends DeviceLogReader {
  String get name => 'MockLogReader';

  final StreamController<String> _linesStreamController =
      new StreamController<String>.broadcast();

  final Completer _finishedCompleter = new Completer();

  Stream<String> get lines => _linesStreamController.stream;

  void addLine(String line) {
    _linesStreamController.add(line);
  }

  bool _started = false;

  Future start() {
    assert(!_started);
    _started = true;
    return new Future.value(this);
  }

  bool get isReading => _started;

  Future stop() {
    assert(_started);
    _started = false;
    return new Future.value(this);
  }

  Future get finished => _finishedCompleter.future;
}

void applyMocksToCommand(FlutterCommand command) {
  command
    ..applicationPackages = new MockApplicationPackageStore()
    ..toolchain = new MockToolchain()
    ..projectRootValidator = () => true;
}

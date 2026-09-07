// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/airreload_device.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/dds.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:test/fake.dart';

import '../src/common.dart';

void main() {
  testWithoutContext('supports only Android ARM64 debug attach and hot reload', () async {
    final device = AirreloadDevice(logger: BufferLogger.test());
    expect(await device.targetPlatform, TargetPlatform.android_arm64);
    expect(device.supportsRuntimeMode(BuildMode.debug), isTrue);
    expect(device.supportsRuntimeMode(BuildMode.profile), isFalse);
    expect(device.supportsRuntimeMode(BuildMode.release), isFalse);
    expect(device.supportsHotReload, isTrue);
    expect(device.supportsHotRestart, isFalse);
    expect(device.supportsFlutterExit, isFalse);
    expect(device.supportsStartPaused, isFalse);
    expect(device.portForwarder, isNull);
    expect(device.getLogReader(), isA<NoOpDeviceLogReader>());
  });

  testWithoutContext('does not install, launch, uninstall, or stop an app', () async {
    final device = AirreloadDevice(logger: BufferLogger.test());
    final app = FakeApplicationPackage();
    expect(() => device.installApp(app), throwsUnsupportedError);
    expect(() => device.uninstallApp(app), throwsUnsupportedError);
    expect(
      () => device.startApp(app, debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug)),
      throwsUnsupportedError,
    );
    expect(await device.stopApp(app), isFalse);
  });

  testWithoutContext('dispose waits for DDS shutdown', () async {
    final dds = PendingDartDevelopmentService();
    final device = TestAirreloadDevice(dds);
    var disposed = false;
    final Future<void> disposal = device.dispose().then((_) {
      disposed = true;
    });
    await Future<void>.delayed(Duration.zero);
    expect(disposed, isFalse);
    dds.shutdownCompleter.complete();
    await disposal;
    expect(disposed, isTrue);
  });
}

class FakeApplicationPackage extends Fake implements ApplicationPackage {}

class PendingDartDevelopmentService extends Fake implements DartDevelopmentService {
  final shutdownCompleter = Completer<void>();

  @override
  Future<void> shutdown() => shutdownCompleter.future;
}

class TestAirreloadDevice extends AirreloadDevice {
  TestAirreloadDevice(this._dds) : super(logger: BufferLogger.test());

  final DartDevelopmentService _dds;

  @override
  DartDevelopmentService get dds => _dds;
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'application_package.dart';
import 'build_info.dart';
import 'device.dart';
import 'device_port_forwarder.dart';
import 'project.dart';

/// A remote device represents an attached to device that was not
/// discovered through a device discoverer.
///
/// This can only be used from `flutter atttach --debug-url=`.
class RemoteDevice extends Device {
  RemoteDevice() : super('remote', category: Category.desktop, platformType: PlatformType.custom, ephemeral: true);

  @override
  void clearLogs() { }

  @override
  Future<void> dispose() async { }

  @override
  Future<String> get emulatorId async => null;

  @override
  FutureOr<DeviceLogReader> getLogReader({covariant ApplicationPackage app, bool includePastLogs = false}) {
    return NoOpDeviceLogReader(id);
  }

  @override
  Future<bool> installApp(covariant ApplicationPackage app, {String userIdentifier}) async {
    return false;
  }

  @override
  Future<bool> isAppInstalled(covariant ApplicationPackage app, {String userIdentifier}) async {
    return false;
  }

  @override
  Future<bool> isLatestBuildInstalled(covariant ApplicationPackage app) async {
    return false;
  }

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  bool isSupported() => true;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) => true;

  @override
  String get name => id;

  @override
  DevicePortForwarder get portForwarder => const NoOpDevicePortForwarder();

  @override
  Future<String> get sdkNameAndVersion async => '';

  @override
  Future<LaunchResult> startApp(covariant ApplicationPackage package, {
  	String mainPath,
  	String route,
  	DebuggingOptions debuggingOptions,
  	Map<String, dynamic> platformArgs,
  	bool prebuiltApplication = false,
  	bool ipv6 = false,
  	String userIdentifier,
  }) async {
    return LaunchResult.failed();
  }

  @override
  Future<bool> stopApp(covariant ApplicationPackage app, {String userIdentifier}) async {
    return false;
  }

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.tester;

  @override
  Future<bool> uninstallApp(covariant ApplicationPackage app, {String userIdentifier}) async {
    return false;
  }
}

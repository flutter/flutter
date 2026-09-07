// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'application_package.dart';
import 'build_info.dart';
import 'device.dart';
import 'device_port_forwarder.dart';
import 'project.dart';

class AirreloadDevice extends Device {
  AirreloadDevice({required super.logger})
    : super(
        'airreload',
        category: Category.mobile,
        platformType: PlatformType.android,
        ephemeral: true,
      );

  @override
  String get name => 'Airreload Android ARM64';

  @override
  bool supportsRuntimeMode(BuildMode buildMode) => buildMode == BuildMode.debug;

  @override
  bool get supportsStartPaused => false;

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.android_arm64;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Future<String?> get emulatorId async => null;

  @override
  Future<String> get sdkNameAndVersion async => 'App-managed TLS tunnel';

  @override
  bool isSupportedForProject(FlutterProject flutterProject) => true;

  @override
  Future<bool> isSupported() async => true;

  @override
  DevicePortForwarder? get portForwarder => null;

  @override
  DeviceLogReader getLogReader({ApplicationPackage? app, bool includePastLogs = false}) =>
      NoOpDeviceLogReader(name);

  @override
  void clearLogs() {}

  @override
  Future<void> dispose() async {
    await dds.shutdown();
  }

  @override
  bool get supportsHotRestart => false;

  @override
  bool get supportsFlutterExit => false;

  @override
  Future<bool> isAppInstalled(ApplicationPackage app, {String? userIdentifier}) async => true;

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => true;

  @override
  Future<bool> installApp(ApplicationPackage app, {String? userIdentifier}) =>
      throw UnsupportedError('Install the debug APK manually.');

  @override
  Future<bool> uninstallApp(ApplicationPackage app, {String? userIdentifier}) =>
      throw UnsupportedError('Airreload is attach-only.');

  @override
  Future<bool> stopApp(ApplicationPackage? app, {String? userIdentifier}) async => false;

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage? package, {
    String? mainPath,
    String? route,
    required DebuggingOptions debuggingOptions,
    Map<String, Object?> platformArgs = const {},
    bool prebuiltApplication = false,
    String? userIdentifier,
  }) => throw UnsupportedError('Airreload is attach-only; open the debug app on the device.');
}

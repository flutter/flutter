// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../application_package.dart';
import '../build_info.dart';
import '../device.dart';

/// Read the log for a particular device.
class _FuchsiaLogReader extends DeviceLogReader {
  FuchsiaDevice _device;

  _FuchsiaLogReader(this._device);

  @override String get name => _device.name;

  Stream<String> _logLines;
  @override
  Stream<String> get logLines {
    _logLines ??= const Stream<String>.empty();
    return _logLines;
  }

  @override
  String toString() => name;
}

class FuchsiaDevice extends Device {
  FuchsiaDevice(String id, { this.name }) : super(id);

  @override
  bool get supportsHotMode => true;

  @override
  final String name;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  bool get supportsStartPaused => false;

  @override
  Future<bool> isAppInstalled(ApplicationPackage app) async => false;

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => false;

  @override
  Future<bool> installApp(ApplicationPackage app) => new Future<bool>.value(false);

  @override
  Future<bool> uninstallApp(ApplicationPackage app) async => false;

  @override
  bool isSupported() => true;

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage app, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication: false,
    bool applicationNeedsRebuild: false,
    bool usesTerminalUi: false,
    bool ipv6: false,
  }) => new Future<Null>.error('unimplemented');

  @override
  Future<bool> stopApp(ApplicationPackage app) async {
    // Currently we don't have a way to stop an app running on Fuchsia.
    return false;
  }

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.fuchsia;

  @override
  Future<String> get sdkNameAndVersion async => 'Fuchsia';

  _FuchsiaLogReader _logReader;
  @override
  DeviceLogReader getLogReader({ApplicationPackage app}) {
    _logReader ??= new _FuchsiaLogReader(this);
    return _logReader;
  }

  @override
  DevicePortForwarder get portForwarder => null;

  @override
  void clearLogs() {
  }

  @override
  bool get supportsScreenshot => false;
}

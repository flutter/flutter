// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:path/path.dart' as path;

import 'artifacts.dart';
import 'build_configuration.dart';

abstract class ApplicationPackage {
  /// Path to the actual apk or bundle.
  final String localPath;

  /// Package ID from the Android Manifest or equivalent.
  final String id;

  /// File name of the apk or bundle.
  final String name;

  ApplicationPackage({
    String localPath,
    this.id
  }) : localPath = localPath, name = path.basename(localPath) {
    assert(localPath != null);
    assert(id != null);
  }
}

class AndroidApk extends ApplicationPackage {
  static const String _defaultName = 'SkyShell.apk';
  static const String _defaultId = 'org.domokit.sky.shell';
  static const String _defaultLaunchActivity = '$_defaultId/$_defaultId.SkyActivity';

  /// The path to the activity that should be launched.
  /// Defaults to 'org.domokit.sky.shell/org.domokit.sky.shell.SkyActivity'
  final String launchActivity;

  AndroidApk({
    String localPath,
    String id: _defaultId,
    this.launchActivity: _defaultLaunchActivity
  }) : super(localPath: localPath, id: id) {
    assert(launchActivity != null);
  }
}

class IOSApp extends ApplicationPackage {
  static const String _defaultId = 'io.flutter.runner.Runner';
  static const String _defaultPath = 'ios';

  IOSApp({
    String localPath: _defaultPath,
    String id: _defaultId
  }) : super(localPath: localPath, id: id);
}

class ApplicationPackageStore {
  final AndroidApk android;
  final IOSApp iOS;
  final IOSApp iOSSimulator;

  ApplicationPackageStore({ this.android, this.iOS, this.iOSSimulator });

  ApplicationPackage getPackageForPlatform(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return iOS;
      case TargetPlatform.iOSSimulator:
        return iOSSimulator;
      case TargetPlatform.mac:
      case TargetPlatform.linux:
        return null;
    }
  }

  static Future<ApplicationPackageStore> forConfigs(List<BuildConfiguration> configs) async {
    AndroidApk android;
    IOSApp iOS;
    IOSApp iOSSimulator;

    for (BuildConfiguration config in configs) {
      switch (config.targetPlatform) {
        case TargetPlatform.android:
          assert(android == null);
          if (config.type != BuildType.prebuilt) {
            String localPath = path.join(config.buildDir, 'apks', AndroidApk._defaultName);
            android = new AndroidApk(localPath: localPath);
          } else {
            Artifact artifact = ArtifactStore.getArtifact(
              type: ArtifactType.shell, targetPlatform: TargetPlatform.android);
            android = new AndroidApk(localPath: await ArtifactStore.getPath(artifact));
          }
          break;

        case TargetPlatform.iOS:
          assert(iOS == null);
          iOS = new IOSApp();
          break;

        case TargetPlatform.iOSSimulator:
          assert(iOSSimulator == null);
          iOSSimulator = new IOSApp();
          break;

        case TargetPlatform.mac:
        case TargetPlatform.linux:
          break;
      }
    }

    return new ApplicationPackageStore(android: android, iOS: iOS, iOSSimulator: iOSSimulator);
  }
}

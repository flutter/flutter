// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.application_package;

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

final Logger _logging = new Logger('sky_tools.application_package');

abstract class ApplicationPackage {
  /// Path to the directory the apk or bundle lives in.
  String appDir;

  /// Path to the actual apk or bundle.
  String get appPath => path.join(appDir, appFileName);

  /// Package ID from the Android Manifest or equivalent.
  String appPackageID;

  /// File name of the apk or bundle.
  String appFileName;

  ApplicationPackage(this.appDir, this.appPackageID, this.appFileName);
}

class AndroidApk extends ApplicationPackage {
  static const String _apkName = 'SkyShell.apk';
  static const String _androidPackage = 'org.domokit.sky.shell';

  AndroidApk(String appDir,
      [String appPackageID = _androidPackage, String appFileName = _apkName])
      : super(path.join(appDir, 'apks'), appPackageID, appFileName);
}

enum BuildType { prebuilt, release, debug, }

enum BuildPlatform { android, iOS, iOSSimulator, mac, linux, }

class ApplicationPackageFactory {
  static final Map<BuildPlatform, Map<BuildType, String>> _buildPaths =
      _initBuildPaths();

  /// Path to your Sky src directory, if you are building Sky locally.
  /// Required if you are requesting release or debug BuildTypes.
  static String _srcPath = null;
  static String get srcPath => _srcPath;
  static void set srcPath(String newPath) {
    _srcPath = path.normalize(newPath);
  }

  /// Default BuildType chosen if no BuildType is specified.
  static BuildType defaultBuildType = BuildType.prebuilt;

  /// Default BuildPlatforms chosen if no BuildPlatforms are specified.
  static List<BuildPlatform> defaultBuildPlatforms = [BuildPlatform.android];

  static Map<BuildPlatform, ApplicationPackage> getAvailableApplicationPackages(
      {BuildType requestedType, List<BuildPlatform> requestedPlatforms}) {
    if (requestedType == null) {
      requestedType = defaultBuildType;
    }
    if (requestedPlatforms == null) {
      requestedPlatforms = defaultBuildPlatforms;
    }

    Map<BuildPlatform, ApplicationPackage> packages = {};
    for (BuildPlatform platform in requestedPlatforms) {
      String buildPath = _getBuildPath(requestedType, platform);
      switch (platform) {
        case BuildPlatform.android:
          packages[platform] = new AndroidApk(buildPath);
          break;
        default:
          // TODO(iansf): Add other platforms
          assert(false);
      }
    }
    return packages;
  }

  static Map<BuildPlatform, Map<BuildType, String>> _initBuildPaths() {
    Map<BuildPlatform, Map<BuildType, String>> buildPaths = {};
    for (BuildPlatform platform in BuildPlatform.values) {
      buildPaths[platform] = {};
    }
    return buildPaths;
  }

  static String _getBuildPath(BuildType type, BuildPlatform platform) {
    String path = _buildPaths[platform][type];
    // You must set paths before getting them
    assert(path != null);
    return path;
  }

  static void setBuildPath(
      BuildType type, BuildPlatform platform, String buildPath) {
    // You must set srcPath before attempting to set a BuildPath for
    // non prebuilt ApplicationPackages.
    assert(type != BuildType.prebuilt || srcPath != null);
    if (type != BuildType.prebuilt) {
      buildPath = path.join(srcPath, buildPath);
    }
    if (!FileSystemEntity.isDirectorySync(buildPath)) {
      _logging.warning('$buildPath is not a valid directory');
    }
    _buildPaths[platform][type] = path.normalize(buildPath);
  }
}

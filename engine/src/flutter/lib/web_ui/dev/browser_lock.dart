// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'common.dart';
import 'environment.dart';

/// Returns the browser configuration based on the `browser_lock.yaml` file in
/// the current engine workspace.
final BrowserLock browserLock = BrowserLock();

/// Provides access to the contents of the `browser_lock.yaml` file.
class BrowserLock {
  factory BrowserLock() {
    final io.File lockFile = io.File(
      path.join(environment.webUiRootDir.path, 'dev', 'browser_lock.yaml'),
    );
    final YamlMap yaml = loadYaml(lockFile.readAsStringSync()) as YamlMap;
    return BrowserLock._fromYaml(yaml);
  }

  BrowserLock._fromYaml(YamlMap yaml) :
    chromeLock = ChromeLock._fromYaml(yaml['chrome'] as YamlMap),
    firefoxLock = FirefoxLock._fromYaml(yaml['firefox'] as YamlMap),
    edgeLock = EdgeLock._fromYaml(yaml['edge'] as YamlMap),
    safariIosLock = SafariIosLock._fromYaml(yaml['safari_ios'] as YamlMap);

  final ChromeLock chromeLock;
  final FirefoxLock firefoxLock;
  final EdgeLock edgeLock;
  final SafariIosLock safariIosLock;
}

class ChromeLock {
  ChromeLock._fromYaml(YamlMap yaml) :
    linux = (yaml['Linux'] as int).toString(),
    mac = (yaml['Mac'] as int).toString(),
    windows = (yaml['Win'] as int).toString(),
    version = yaml['version'] as String;

  final String linux;
  final String mac;
  final String windows;
  /// The major version of Chromium represented by this lock. E.g: '96' (for Chromium 96.0.554.51)
  final String version;

  /// Return the Chromium Build ID to use for the current operating system.
  String get versionForCurrentPlatform {
    return PlatformBinding.instance.getChromeBuild(this);
  }
}

class FirefoxLock {
  FirefoxLock._fromYaml(YamlMap yaml) :
    version = yaml['version'] as String;

  final String version;
}

class EdgeLock {
  EdgeLock._fromYaml(YamlMap yaml) :
      launcherVersion = yaml['launcher_version'] as String;

  final String launcherVersion;
}

class SafariIosLock {
  SafariIosLock._fromYaml(YamlMap yaml) :
    majorVersion = yaml['major_version'] as int,
    minorVersion = yaml['minor_version'] as int,
    device = yaml['device'] as String,
    heightOfHeader = yaml['height_of_header'] as int,
    heightOfFooter = yaml['height_of_footer'] as int,
    scaleFactor = yaml['scale_factor'] as double;

  final int majorVersion;
  final int minorVersion;
  final String device;
  final int heightOfHeader;
  final int heightOfFooter;
  final double scaleFactor;

  String get simulatorDescription => '$device with iOS $majorVersion.$minorVersion';
}

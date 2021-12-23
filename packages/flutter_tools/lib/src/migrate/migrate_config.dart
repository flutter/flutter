// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:yaml/yaml.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../cache.dart';

class MigrateConfig {

  MigrateConfig.fromFile(File file) {
    YamlMap = loadYaml(file.readAsStringSync());
  }

  MigrateConfig({
    this.platform,
    this.createVersion,
    this.lastMigrateVersion,
    this.unmanagedFiles
  }) {

  }

  String platform;
  String createVersion;
  String lastMigrateVersion;
  List<String> unmanagedFiles;

  void writeFile() {
    Directory platformDir;
    FlutterProject project = FlutterProject.current();
    switch (platform) {
      case 'android': {
        platformDir = project.android.directory;
        break;
      }
      case 'ios': {
        platformDir = project.ios.directory;
        break;
      }
      case 'web': {
        platformDir = project.web.directory;
        break;
      }
      case 'macos': {
        platformDir = project.macos.directory;
        break;
      }
      case 'linux': {
        platformDir = project.linux.directory;
        break;
      }
      case 'windows': {
        platformDir = project.windows.directory;
        break;
      }
      case 'windowsUwp': {
        platformDir = project.windowsUwp.directory;
        break;
      }
      case 'fuchsia': {
        platformDir = project.fuchsia.directory;
        break;
      }
    }
    File file = platformDir.childFile('.migrate_config');
    file.createSync(recursive: true);
    String unmanagedFilesString = '';
    for (String path in unmanagedFiles) {
      unmanagedFilesString += '  - $path\n';
    }
    file.writeAsStringSync('''
# Generated file
platform: $platform
createVersion: $createVersion
lastMigrateVersion: $lastMigrateVersion
unmanagedFiles:
$unmanagedFilesString
'''
    flush: true);
  }
}

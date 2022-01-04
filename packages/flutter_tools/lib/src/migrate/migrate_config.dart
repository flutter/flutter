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

  MigrateConfig.fromFile(File file) : unmanagedFiles = <String>[] {
    YamlMap yamlRoot = loadYaml(file.readAsStringSync());
    if (!validate(yamlRoot)) {
      // Error
      return;
    }
    populateFromYaml(yamlRoot);
  }

  MigrateConfig.fromPlatform(this.platform) : unmanagedFiles = <String>[] {
    MigrateConfig.fromFile(getFileFromPlatform(platform));
  }

  MigrateConfig({
    required this.platform,
    required this.createVersion,
    required this.lastMigrateVersion,
    required this.unmanagedFiles
  }) {}

  String? platform;
  String? createVersion;
  String? lastMigrateVersion;
  List<String> unmanagedFiles;

  void populateFromYaml(YamlMap yamlRoot) {
    platform = yamlRoot['platform'];
    createVersion = yamlRoot['createVersion'];
    lastMigrateVersion = yamlRoot['lastMigrateVersion'];
    unmanagedFiles = yamlRoot['unmanagedFiles'];
  }

  void writeFile() {
    File file = getFileFromPlatform(platform);
    file.createSync(recursive: true);
    String unmanagedFilesString = '';
    for (String path in unmanagedFiles) {
      unmanagedFilesString += '  - $path\n';
    }
    file.writeAsStringSync('''
# Generated section.
platform: $platform
createVersion: $createVersion
lastMigrateVersion: $lastMigrateVersion

# User provided section

# List of Local paths (relative to this file) that should be
# ignored by the migrate tool.
#
# Files that are not part of the templates will be ignored by default.
unmanagedFiles:
$unmanagedFilesString
''',
    flush: true);
  }

  static File getFileFromPlatform(String? platform) {
    Directory? platformDir;
    FlutterProject project = FlutterProject.current();
    switch (platform) {
      case 'root': {
        platformDir = project.directory;
        break;
      }
      case 'android': {
        platformDir = project.android.hostAppGradleRoot;
        break;
      }
      case 'ios': {
        platformDir = project.ios.hostAppRoot;
        break;
      }
      case 'web': {
        platformDir = project.web.directory;
        break;
      }
      case 'macos': {
        platformDir = project.macos.hostAppRoot;
        break;
      }
      case 'linux': {
        platformDir = project.linux.managedDirectory.parent;
        break;
      }
      case 'windows': {
        platformDir = project.windows.managedDirectory.parent;
        break;
      }
      case 'windowsUwp': {
        platformDir = project.windowsUwp.managedDirectory.parent;
        break;
      }
      case 'fuchsia': {
        platformDir = project.fuchsia.editableHostAppDirectory;
        break;
      }
    }
    if (platformDir == null) {
      throwToolExit('Invalid platform when creating MigrateConfig', exitCode: 1);
    }
    File file = platformDir.childFile('.migrate_config');
    return file;
  }

  bool validate(YamlMap yamlRoot) {
    return yamlRoot.keys.contains('platform') &&
    yamlRoot.keys.contains('createVersion') &&
    yamlRoot.keys.contains('lastMigrateVersion') &&
    yamlRoot.keys.contains('unmanagedFiles') &&
    yamlRoot['unmanagedFiles'] is YamlList;
  }
}

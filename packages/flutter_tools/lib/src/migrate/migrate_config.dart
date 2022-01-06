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
import '../migrate/migrate_utils.dart';
import '../flutter_project_metadata.dart';
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

  MigrateConfig.fromPlatform(this.platform, {Directory? projectDirectory}) : unmanagedFiles = <String>[] {
    MigrateConfig.fromFile(getFileFromPlatform(platform, projectDirectory: projectDirectory));
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
    unmanagedFiles = List<String>.from(yamlRoot['unmanagedFiles']);
  }

  void writeFile({Directory? projectDirectory}) {
    File file = getFileFromPlatform(platform, projectDirectory: projectDirectory);
    file.createSync(recursive: true);
    print('    writing ${file.path}');
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

  static File getFileFromPlatform(String? platform, {Directory? projectDirectory}) {
    Directory? platformDir;
    FlutterProject project = projectDirectory == null ? FlutterProject.current() : FlutterProject.fromDirectory(projectDirectory!);
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

  static List<String> getSupportedPlatforms({bool includeRoot = false}) {
    List<String> platforms = includeRoot ? <String>['root'] : <String>[];
    if (FlutterProject.current().android.existsSync()) {
      platforms.add('android');
    }
    if (FlutterProject.current().ios.existsSync()) {
      platforms.add('ios');
    }
    if (FlutterProject.current().web.existsSync()) {
      platforms.add('web');
    }
    if (FlutterProject.current().macos.existsSync()) {
      platforms.add('macos');
    }
    if (FlutterProject.current().linux.existsSync()) {
      platforms.add('linux');
    }
    if (FlutterProject.current().windows.existsSync()) {
      platforms.add('windows');
    }
    if (FlutterProject.current().windowsUwp.existsSync()) {
      platforms.add('windowsUwp');
    }
    if (FlutterProject.current().fuchsia.existsSync()) {
      platforms.add('fuchsia');
    }
    return platforms;
  }

  static Future<List<MigrateConfig>> parseOrCreateMigrateConfigs({List<String>? platforms, Directory? projectDirectory}) async {
    if (platforms == null) {
      platforms = getSupportedPlatforms(includeRoot: true);
    }
    print('  IN MIGRATE CONFIG GEN');
    print('  platforms: $platforms');
    String createVersion = '';
    String lastMigrateVersion = '';

    List<MigrateConfig> configs = <MigrateConfig>[];
    for (String platform in platforms) {
      print('  handling $platform');
      if (MigrateConfig.getFileFromPlatform(platform, projectDirectory: projectDirectory).existsSync()) {
        // Existing config. Parsing.
        print('    existing config, parsing ${MigrateConfig.getFileFromPlatform(platform).path}');
        configs.add(MigrateConfig.fromPlatform(platform, projectDirectory: projectDirectory));
      } else {
        // No config found, creating empty config.
        print('    no config found, writing new config ${MigrateConfig.getFileFromPlatform(platform).path}');
        MigrateConfig newConfig = MigrateConfig(
          platform: platform,
          createVersion: createVersion,
          lastMigrateVersion: lastMigrateVersion,
          unmanagedFiles: <String>[],
        );
        newConfig.writeFile(projectDirectory: projectDirectory);
        configs.add(newConfig);
      }
    }
    return configs;
  }

  static Future<String> getFallbackLastMigrateVersion() async {
    // Use the .metadata file if it exists.
    File metadataFile = FlutterProject.current().directory.childFile('.metadata');
    if (metadataFile.existsSync()) {
      FlutterProjectMetadata metadata = FlutterProjectMetadata(metadataFile, globals.logger);
      if (metadata.versionRevision != null) {
        return metadata.versionRevision!;
      }
    }
    return MigrateUtils.getGitHash(Cache.flutterRoot!);
  }
}

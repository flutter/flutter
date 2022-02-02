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

/// Represents one .migrate_config file.
///
/// Each platform and the root project directory includes one .migrate_config file.
/// This file tracks the flutter sdk git hashes of the last successful migration and the
/// version the project was created with.
///
/// Each platform contains its own .migrate_config file because flutter create can be
/// used to add support for new platforms, so the base create version may not always be the same.
class MigrateConfig {

  /// Creates a MigrateConfig by explicitly providing all values.
  MigrateConfig({
    required this.platform,
    required this.createVersion,
    required this.lastMigrateVersion,
    required this.unmanagedFiles
  }) {}

  /// Creates a MigrateConfig by parsing an existing migrate config yaml file.
  MigrateConfig.fromFile(File file) : unmanagedFiles = <String>[] {
    final YamlMap yamlRoot = loadYaml(file.readAsStringSync());
    if (!validate(yamlRoot)) {
      // Error
      globals.logger.printError('Invalid migrate config yaml file found at ${file.path}');
      return;
    }
    platform = yamlRoot['platform'];
    createVersion = yamlRoot['createVersion'];
    lastMigrateVersion = yamlRoot['lastMigrateVersion'];
    if (yamlRoot['unmanagedFiles'] != null) {
      unmanagedFiles = List<String>.from(yamlRoot['unmanagedFiles']);
    } else {
      unmanagedFiles = <String>[];
    }
  }
  static const String kFileName = '.migrate_config';

  String? platform;
  String? createVersion;
  String? lastMigrateVersion;
  List<String> unmanagedFiles;

  /// Writes the .migrate_config file in the provided project directory's platform subdirectory.
  void writeFile({Directory? projectDirectory}) {
    File file = getFileFromPlatform(platform, projectDirectory: projectDirectory);
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

  /// Returns the File that the migrate config belongs given a platform and a project directory.
  static File getFileFromPlatform(String? platform, {Directory? projectDirectory}) {
    Directory? platformDir;
    final FlutterProject project = projectDirectory == null ? FlutterProject.current() : FlutterProject.fromDirectory(projectDirectory!);
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
    return platformDir.childFile(kFileName);
  }

  String getBasePath(Directory? projectDirectory) {
    return getFileFromPlatform(platform, projectDirectory: projectDirectory).parent.absolute.path;
  }

  bool validate(YamlMap yamlRoot) {
    return yamlRoot.keys.contains('platform') &&
    yamlRoot.keys.contains('createVersion') &&
    yamlRoot.keys.contains('lastMigrateVersion') &&
    yamlRoot.keys.contains('unmanagedFiles');
  }

  static List<String> getSupportedPlatforms({bool includeRoot = false}) {
    final List<String> platforms = includeRoot ? <String>['root'] : <String>[];
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

  static Future<List<MigrateConfig>> parseOrCreateMigrateConfigs({List<String>? platforms, Directory? projectDirectory, bool create = true}) async {
    if (platforms == null) {
      platforms = getSupportedPlatforms(includeRoot: true);
    }

    List<MigrateConfig> configs = <MigrateConfig>[];
    for (String platform in platforms) {
      if (MigrateConfig.getFileFromPlatform(platform, projectDirectory: projectDirectory).existsSync()) {
        // Existing config. Parsing.
        configs.add(MigrateConfig.fromFile(getFileFromPlatform(platform, projectDirectory: projectDirectory)));
      } else {
        // No config found, creating empty config.
        MigrateConfig newConfig = MigrateConfig(
          platform: platform,
          createVersion: '',
          lastMigrateVersion: '',
          unmanagedFiles: <String>[],
        );
        if (create) {
          newConfig.writeFile(projectDirectory: projectDirectory);
        }
        configs.add(newConfig);
      }
    }
    return configs;
  }

  static Future<String> getFallbackLastMigrateVersion() async {
    // Use the .metadata file if it exists.
    final File metadataFile = FlutterProject.current().directory.childFile('.metadata');
    if (metadataFile.existsSync()) {
      final FlutterProjectMetadata metadata = FlutterProjectMetadata(metadataFile, globals.logger);
      if (metadata.versionRevision != null) {
        return metadata.versionRevision!;
      }
    }
    return MigrateUtils.getGitHash(Cache.flutterRoot!);
  }
}

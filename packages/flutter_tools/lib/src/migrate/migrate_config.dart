// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:yaml/yaml.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../cache.dart';
import '../flutter_project_metadata.dart';
import '../globals.dart' as globals;
import '../project.dart';

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
    this.createRevision,
    this.baseRevision,
    required this.unmanagedFiles,
  });

  /// Creates a MigrateConfig by parsing an existing migrate config yaml file.
  MigrateConfig.fromFile(File file) : unmanagedFiles = <String>[] {
    final dynamic yamlRoot = loadYaml(file.readAsStringSync());
    if (!validate(yamlRoot)) {
      // Error
      globals.logger.printError('Invalid migrate config yaml file found at ${file.path}');
      return;
    }
    final YamlMap map = yamlRoot as YamlMap;
    platform = map['platform'] as String;
    createRevision = map['createRevision'] as String;
    baseRevision = map['baseRevision'] as String;
    if (map['unmanagedFiles'] != null) {
      unmanagedFiles = List<String>.from(map['unmanagedFiles'] as Iterable<String>);
    } else {
      unmanagedFiles = <String>[];
    }
  }
  static const String kFileName = '.migrate_config';
  static const Map<String, List<String>> kIosDefaultUnmanagedFiles = <String, List<String>>{
    'root': <String>['lib/main.dart'],
    'ios': <String>['Runner.xcodeproj/project.pbxproj'],
  };

  String? platform;
  String? createRevision;
  String? baseRevision;
  List<String> unmanagedFiles;

  /// Writes the .migrate_config file in the provided project directory's platform subdirectory.
  ///
  /// We write the file manually instead of with a template because this
  /// needs to be able to write the .migrate_config file into legacy apps.
  void writeFile({Directory? projectDirectory}) {
    final File file = getFileFromPlatform(platform, projectDirectory: projectDirectory);
    file.createSync(recursive: true);
    String unmanagedFilesString = '';
    for (final String path in unmanagedFiles) {
      unmanagedFilesString += '  - $path\n';
    }
    file.writeAsStringSync('''
# Generated section.
platform: $platform
createRevision: $createRevision
baseRevision: $baseRevision

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
    final FlutterProject project = projectDirectory == null ? FlutterProject.current() : FlutterProject.fromDirectory(projectDirectory);
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

  /// Verifies the expected yaml keys are present in the file.
  bool validate(dynamic yamlRoot) {
    if (yamlRoot is! YamlMap) {
      return false;
    }
    final YamlMap map = yamlRoot;
    return map.keys.contains('platform') &&
    map.keys.contains('createRevision') &&
    map.keys.contains('baseRevision') &&
    map.keys.contains('unmanagedFiles');
  }

  /// Returns a list of platform names that are supported by the project.
  static List<String> getSupportedPlatforms({bool includeRoot = false, FlutterProject? flutterProject}) {
    final List<String> platforms = includeRoot ? <String>['root'] : <String>[];
    flutterProject ??= FlutterProject.current();
    if (flutterProject.android.existsSync()) {
      platforms.add('android');
    }
    if (flutterProject.ios.existsSync()) {
      platforms.add('ios');
    }
    if (flutterProject.web.existsSync()) {
      platforms.add('web');
    }
    if (flutterProject.macos.existsSync()) {
      platforms.add('macos');
    }
    if (flutterProject.linux.existsSync()) {
      platforms.add('linux');
    }
    if (flutterProject.windows.existsSync()) {
      platforms.add('windows');
    }
    if (flutterProject.windowsUwp.existsSync()) {
      platforms.add('windowsUwp');
    }
    if (flutterProject.fuchsia.existsSync()) {
      platforms.add('fuchsia');
    }
    return platforms;
  }

  /// Searches the flutter project for all .migrate_config files. Optionally, missing files can be
  /// initialized with default values.
  static Future<List<MigrateConfig>> parseOrCreateMigrateConfigs({List<String>? platforms, Directory? projectDirectory, String? currentRevision, String? createRevision, bool create = true}) async {
    platforms ??= getSupportedPlatforms(includeRoot: true, flutterProject: projectDirectory == null ? null : FlutterProject.fromDirectory(projectDirectory));
    final List<MigrateConfig> configs = <MigrateConfig>[];
    for (final String platform in platforms) {
      if (MigrateConfig.getFileFromPlatform(platform, projectDirectory: projectDirectory).existsSync()) {
        // Existing config. Parsing.
        configs.add(MigrateConfig.fromFile(getFileFromPlatform(platform, projectDirectory: projectDirectory)));
      } else {
        // No config found, creating empty config.
        final MigrateConfig newConfig = MigrateConfig(
          platform: platform,
          createRevision: createRevision,
          baseRevision: currentRevision,
          unmanagedFiles: kIosDefaultUnmanagedFiles[platform] != null ? kIosDefaultUnmanagedFiles[platform]! : <String>[],
        );
        if (create) {
          newConfig.writeFile(projectDirectory: projectDirectory);
        }
        configs.add(newConfig);
      }
    }
    return configs;
  }

  /// Finds the fallback revision to use when no base revision is found in the .migrate_config.
  static Future<String> getFallbackBaseRevision() async {
    // Use the .metadata file if it exists.
    final File metadataFile = FlutterProject.current().directory.childFile('.metadata');
    if (metadataFile.existsSync()) {
      final FlutterProjectMetadata metadata = FlutterProjectMetadata(metadataFile, globals.logger);
      if (metadata.versionRevision != null) {
        return metadata.versionRevision!;
      }
    }
    return getGitHash(Cache.flutterRoot!);
  }

  static Future<String> getGitHash(String projectPath, [String tag = 'HEAD']) async {
    final List<String> cmdArgs = <String>['rev-parse', tag];
    final ProcessResult result = await Process.run('git', cmdArgs, workingDirectory: projectPath);
    return result.stdout as String;
  }
}

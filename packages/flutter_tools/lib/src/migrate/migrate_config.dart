// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:yaml/yaml.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../cache.dart';
import '../flutter_project_metadata.dart';
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

  /// Creates a MigrateConfig by parsing an existing .migrate_config yaml file.
  MigrateConfig.fromFile(File file) : platform = SupportedPlatform.root, unmanagedFiles = <String>[] {
    final Object? yamlRoot = loadYaml(file.readAsStringSync());
    if (!_validate(yamlRoot)) {
      // Error
      throwToolExit('Invalid migrate config yaml file found at ${file.path}');
      return;
    }
    final YamlMap map = yamlRoot as YamlMap;
    platform = SupportedPlatform.values.firstWhere((e) => e.toString() == 'SupportedPlatform.${map['platform'] as String}');
    createRevision = map['createRevision'] as String?;
    baseRevision = map['baseRevision'] as String?;
    final Object? unmanagedFilesMap = map['unmanagedFiles'];
    if (unmanagedFilesMap is YamlList && unmanagedFilesMap.isNotEmpty) {
      unmanagedFiles = List<String>.from(unmanagedFilesMap.value.cast<String>());
    } else {
      unmanagedFiles = <String>[];
    }
  }

  /// The name of the config file.
  static const String kFileName = '.migrate_config';

  /// A mapping of the files that are unmanaged by defult for each platform.
  static const Map<String, List<String>> _kDefaultUnmanagedFiles = <String, List<String>>{
    'root': <String>['lib/main.dart'],
    'ios': <String>['Runner.xcodeproj/project.pbxproj'],
  };

  /// The platform this config file is describing.
  SupportedPlatform platform;

  /// The git revision this platform was initially created with.
  ///
  /// Null if the initial create git revision is unknown.
  String? createRevision;

  /// The git revision this platform was last successfully migrated with.
  ///
  /// Null if the project was never migrated or the revision is unknown.
  String? baseRevision;

  /// A list of paths relative to this file the migrate tool should ignore.
  ///
  /// These files are typically user-owned files that should not be changed.
  List<String> unmanagedFiles;

  /// Verifies the expected yaml keys are present in the file.
  bool _validate(Object? yamlRoot) {
    if (yamlRoot is! YamlMap) {
      return false;
    }
    final YamlMap map = yamlRoot;
    return map.keys.contains('platform') &&
    (map['platform'] is String || map['platform'] == null) &&
    map.keys.contains('createRevision') &&
    (map['createRevision'] is String || map['createRevision'] == null) &&
    map.keys.contains('baseRevision') &&
    (map['baseRevision'] is String || map['baseRevision'] == null) &&
    map.keys.contains('unmanagedFiles') &&
    (map['unmanagedFiles'] is YamlList || map['unmanagedFiles'] == null);
  }

  /// Writes the .migrate_config file in the provided project directory's platform subdirectory.
  ///
  /// We write the file manually instead of with a template because this
  /// needs to be able to write the .migrate_config file into legacy apps.
  void writeFile({Directory? projectDirectory}) {
    String unmanagedFilesString = '';
    for (final String path in unmanagedFiles) {
      unmanagedFilesString += "  - '$path'\n";
    }
    getFileFromPlatform(platform, projectDirectory: projectDirectory)
      ..createSync(recursive: true)
      ..writeAsStringSync('''
# Generated section.
platform: '${platform.toString().split('.').last}'
createRevision: ${createRevision == null ? 'null' : "'$createRevision'"}
baseRevision: ${baseRevision == null ? 'null' : "'$baseRevision'"}

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

  /// Returns the absolute path of the platform directory this config belongs to.
  ///
  /// For example, if the config is the android config with a project directory of `/project`,
  /// the base path returned would be `/project/android`.
  String getBasePath(Directory? projectDirectory) {
    return getFileFromPlatform(platform, projectDirectory: projectDirectory).parent.absolute.path;
  }

  /// Searches the flutter project for all .migrate_config files.
  ///
  /// Optionally, missing files can be initialized with default values.
  static Future<List<MigrateConfig>> parseOrCreateMigrateConfigs({
    List<SupportedPlatform>? platforms,
    Directory? projectDirectory,
    String? currentRevision,
    String? createRevision,
    bool create = true,
  }) async {
    FlutterProject flutterProject = projectDirectory == null ? FlutterProject.current() : FlutterProject.fromDirectory(projectDirectory);
    platforms ??= flutterProject.getSupportedPlatforms(includeRoot: true);
    final List<MigrateConfig> configs = <MigrateConfig>[];
    for (final SupportedPlatform platform in platforms) {
      if (MigrateConfig.getFileFromPlatform(platform, projectDirectory: projectDirectory).existsSync()) {
        // Existing config. Parsing.
        configs.add(MigrateConfig.fromFile(getFileFromPlatform(platform, projectDirectory: projectDirectory)));
      } else {
        // No config found, creating empty config.
        final MigrateConfig newConfig = MigrateConfig(
          platform: platform,
          createRevision: createRevision,
          baseRevision: currentRevision,
          unmanagedFiles: _kDefaultUnmanagedFiles[platform] ?? <String>[],
        );
        if (create) {
          newConfig.writeFile(projectDirectory: projectDirectory);
        }
        configs.add(newConfig);
      }
    }
    return configs;
  }

  /// Returns the File that the migrate config belongs given a platform and a project directory.
  ///
  /// A projectDirectory can be specified to obtain files that are based on a different project than
  /// the current working directory Flutter project.
  static File getFileFromPlatform(SupportedPlatform platform, {Directory? projectDirectory}) {
    Directory? platformDir;
    final FlutterProject project = projectDirectory == null ? FlutterProject.current() : FlutterProject.fromDirectory(projectDirectory);
    switch (platform) {
      case SupportedPlatform.root: {
        platformDir = project.directory;
        break;
      }
      case SupportedPlatform.android: {
        platformDir = project.android.hostAppGradleRoot;
        break;
      }
      case SupportedPlatform.ios: {
        platformDir = project.ios.hostAppRoot;
        break;
      }
      case SupportedPlatform.web: {
        platformDir = project.web.directory;
        break;
      }
      case SupportedPlatform.macos: {
        platformDir = project.macos.hostAppRoot;
        break;
      }
      case SupportedPlatform.linux: {
        platformDir = project.linux.managedDirectory.parent;
        break;
      }
      case SupportedPlatform.windows: {
        platformDir = project.windows.managedDirectory.parent;
        break;
      }
      case SupportedPlatform.windowsuwp: {
        platformDir = project.windowsUwp.managedDirectory.parent;
        break;
      }
      case SupportedPlatform.fuchsia: {
        platformDir = project.fuchsia.editableHostAppDirectory;
        break;
      }
    }
    return platformDir.childFile(kFileName);
  }

  /// Finds the fallback revision to use when no base revision is found in the .migrate_config.
  static Future<String> getFallbackBaseRevision(Logger logger) async {
    // Use the .metadata file if it exists.
    final File metadataFile = FlutterProject.current().directory.childFile('.metadata');
    if (metadataFile.existsSync()) {
      final FlutterProjectMetadata metadata = FlutterProjectMetadata(metadataFile, logger);
      if (metadata.versionRevision != null) {
        return metadata.versionRevision!;
      }
    }
    return _getGitHash(Cache.flutterRoot!);
  }

  static Future<String> _getGitHash(String flutterRootPath, [String tag = 'HEAD']) async {
    final List<String> cmdArgs = <String>['rev-parse', tag];
    final ProcessResult result = await Process.run('git', cmdArgs, workingDirectory: flutterRootPath);
    return result.stdout as String;
  }
}

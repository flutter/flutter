// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';

import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/utils.dart';
import 'project.dart';
import 'version.dart';

enum FlutterProjectType {
  /// This is the default project with the user-managed host code.
  /// It is different than the "module" template in that it exposes and doesn't
  /// manage the platform code.
  app,
  /// A List/Detail app template that follows community best practices.
  skeleton,
  /// The is a project that has managed platform host code. It is an application with
  /// ephemeral .ios and .android directories that can be updated automatically.
  module,
  /// This is a Flutter Dart package project. It doesn't have any native
  /// components, only Dart.
  package,
  /// This is a native plugin project.
  plugin,
  /// This is an FFI native plugin project.
  ffiPlugin,
}

String flutterProjectTypeToString(FlutterProjectType type) {
  if (type == FlutterProjectType.ffiPlugin) {
    return 'plugin_ffi';
  }
  return getEnumName(type);
}

FlutterProjectType? stringToProjectType(String value) {
  FlutterProjectType? result;
  for (final FlutterProjectType type in FlutterProjectType.values) {
    if (value == flutterProjectTypeToString(type)) {
      result = type;
      break;
    }
  }
  return result;
}

/// Represents one .migrate_config file.
///
/// Each platform and the root project directory includes one .migrate_config file.
/// This file tracks the flutter sdk git hashes of the last successful migration and the
/// version the project was created with.
///
/// Each platform contains its own .migrate_config file because flutter create can be
/// used to add support for new platforms, so the base create version may not always be the same.
class FlutterProjectMetadata {
  /// Creates a MigrateConfig by parsing an existing .migrate_config yaml file.
  FlutterProjectMetadata(File file, Logger logger) : _metadataFile = file,
                                                     _logger = logger,
                                                     migrateConfig = MigrateConfig() {
    if (!_metadataFile.existsSync()) {
      _logger.printError('No .metadata file found at ${_metadataFile.path}');
      // Create a default metadata.
      return;
    }
    Object? yamlRoot;
    try {
      yamlRoot = loadYaml(_metadataFile.readAsStringSync());
    } on YamlException {
      // Handled in _validate below.
    }
    if (!_validate(yamlRoot)) {
      _logger.printError('Invalid .metadata yaml file found at ${_metadataFile.path}');
      return;
    }
    final YamlMap map = yamlRoot! as YamlMap;
    final Object? versionYaml = map['version'];
    if (versionYaml == null || versionYaml is! YamlMap) {
      _logger.printTrace('.metadata version is malformed.');
    } else {
      final YamlMap versionYamlMap = versionYaml;
      _versionRevision = versionYamlMap['revision'] as String?;
      _versionChannel = versionYamlMap['channel'] as String?;
      _projectType = stringToProjectType(versionYamlMap['projectType'] as String);
    }

    final Object? migrationYaml = map['migration'];
    if (map['migration'] is YamlMap) {
      final YamlMap migrationYamlMap = migrationYaml! as YamlMap;

      final Object? platformsYaml = migrationYamlMap['platforms'];
      final Map<SupportedPlatform, MigratePlatformConfig> platformConfigs = <SupportedPlatform, MigratePlatformConfig>{};
      if (platformsYaml is YamlList && platformsYaml.isNotEmpty) {
        for (final Object? platform in platformsYaml) {
          if (platform != null && platform is YamlMap && platform.containsKey('platform') && platform.containsKey('createRevision') && platform.containsKey('baseRevision')) {
            final YamlMap platformYamlMap = platform;
            final SupportedPlatform platformString = SupportedPlatform.values.firstWhere((SupportedPlatform platform) => platform.toString() == 'SupportedPlatform.${platformYamlMap['platform'] as String}');
            platformConfigs[platformString] = MigratePlatformConfig(
              createRevision: platform['createRevision'] as String?,
              baseRevision: platform['baseRevision'] as String?,
            );
          } else {
            // malformed platform entry
            continue;
          }
        }
      }

      final Object? unmanagedFilesYaml = migrationYamlMap['unmanagedFiles'];
      List<String> unmanagedFiles = <String>[];
      if (unmanagedFilesYaml is YamlList && unmanagedFilesYaml.isNotEmpty) {
        unmanagedFiles = List<String>.from(unmanagedFilesYaml.value.cast<String>());
      }
      migrateConfig = MigrateConfig(
        platformConfigs: platformConfigs,
        unmanagedFiles: unmanagedFiles,
      );
    }
  }

  /// Creates a MigrateConfig by explicitly providing all values.
  FlutterProjectMetadata.explicit({
    required File file,
    required String? versionChannel,
    required String? versionRevision,
    required this.migrateConfig,
    required Logger logger,
  }) : _logger = logger,
       _versionChannel = versionChannel,
       _versionRevision = versionRevision,
       _metadataFile = file;

  /// The name of the config file.
  static const String kFileName = '.metadata';

  String? _versionChannel;
  String? get versionChannel => _versionChannel;

  String? _versionRevision;
  String? get versionRevision => _versionRevision;

  FlutterProjectType? _projectType;
  FlutterProjectType? get projectType => _projectType;


  MigrateConfig migrateConfig;

  final Logger _logger;

  final File _metadataFile;

  /// Verifies the expected yaml keys are present in the file.
  bool _validate(Object? yamlRoot) {
    final Map<String, Type> validations = <String, Type>{
      // 'versionChannel': String,
      // 'versionRevision': String,
      // 'migration': YamlMap,
    };
    if (yamlRoot != null && yamlRoot is! YamlMap) {
      return false;
    }
    final YamlMap map = yamlRoot! as YamlMap;
    bool isValid = true;
    for (final MapEntry<String, Object> entry in validations.entries) {
      if (!map.keys.contains(entry.key)) {
        isValid = false;
        _logger.printError('The key ${entry.key} was not found');
        break;
      }
      if (map[entry.key] != null && (map[entry.key] as Object).runtimeType != entry.value) {
        isValid = false;
        _logger.printError('The value of key ${entry.key} was expected to be ${entry.value} but was ${(map[entry.key] as Object).runtimeType}');
        break;
      }
    }
    return isValid;
  }


  /// Writes the .migrate_config file in the provided project directory's platform subdirectory.
  ///
  /// We write the file manually instead of with a template because this
  /// needs to be able to write the .migrate_config file into legacy apps.
  void writeFile() {
    String unmanagedFilesString = '';
    for (final String path in migrateConfig.unmanagedFiles) {
      unmanagedFilesString += "\n    - '$path'";
    }
    String platformsString = '';
    print(migrateConfig.platformConfigs.keys);
    for (final MapEntry<SupportedPlatform, MigratePlatformConfig> entry in migrateConfig.platformConfigs.entries) {
      print('building string platforms: ${entry.key}');
      platformsString += '\n    - platform: ${entry.key.toString().split('.').last}\n.      createRevision: ${entry.value.createRevision == null ? 'null' : "'${entry.value.createRevision}}'"}\n      baseRevision: ${entry.value.baseRevision == null ? 'null' : "'${entry.value.baseRevision}}'"}';
    }

    _metadataFile
      ..createSync(recursive: true)
      ..writeAsStringSync('''
# This file tracks properties of this Flutter project.
# Used by Flutter tool to assess capabilities and perform upgrades etc.
#
# This file should be version controlled.

version:
  revision: $_versionRevision
  channel: $_versionChannel

project_type: ${projectType.toString().split('.').last}

# Tracks the revisions
migration:
  platforms:$platformsString

  # User provided section

  # List of Local paths (relative to this file) that should be
  # ignored by the migrate tool.
  #
  # Files that are not part of the templates will be ignored by default.
  unmanagedFiles:$unmanagedFilesString

''',
    flush: true);
  }

  void populate({
    List<SupportedPlatform>? platforms,
    Directory? projectDirectory,
    String? currentRevision,
    String? createRevision,
    bool create = true,
    bool update = true,
    required Logger logger,
  }) {
    migrateConfig.populate(
      platforms: platforms,
      projectDirectory: projectDirectory,
      currentRevision: currentRevision,
      createRevision: createRevision,
      create: create,
      update: update,
      logger: logger,
    );
  }

  /// Finds the fallback revision to use when no base revision is found in the migrate config.
  String getFallbackBaseRevision(Logger logger, FlutterVersion flutterVersion) {
    // Use the .metadata file if it exists.
    if (versionRevision != null) {
      return versionRevision!;
    }
    return flutterVersion.frameworkRevision;
  }
}

class MigrateConfig {
  MigrateConfig({
    this.platformConfigs = const <SupportedPlatform, MigratePlatformConfig>{},
    this.unmanagedFiles = _kDefaultUnmanagedFiles
  });

  /// A mapping of the files that are unmanaged by defult for each platform.
  static const List<String> _kDefaultUnmanagedFiles = <String>[
    'lib/main.dart',
    'ios/Runner.xcodeproj/project.pbxproj',
  ];

  /// The 
  final Map<SupportedPlatform, MigratePlatformConfig> platformConfigs;

  /// A list of paths relative to this file the migrate tool should ignore.
  ///
  /// These files are typically user-owned files that should not be changed.
  final List<String> unmanagedFiles;


  void populate({
    List<SupportedPlatform>? platforms,
    Directory? projectDirectory,
    String? currentRevision,
    String? createRevision,
    bool create = true,
    bool update = true,
    required Logger logger,
  }) {
    final FlutterProject flutterProject = projectDirectory == null ? FlutterProject.current() : FlutterProject.fromDirectory(projectDirectory);
    platforms ??= flutterProject.getSupportedPlatforms(includeRoot: true);

    final Map<SupportedPlatform, MigratePlatformConfig> platformConfigs = <SupportedPlatform, MigratePlatformConfig>{};
    for (final SupportedPlatform platform in platforms) {
      if (platformConfigs.containsKey(platform)) {
        if (update) {
          print('updating $platform');
          platformConfigs[platform]!.baseRevision = currentRevision;
        }
      } else {
        if (create) {
          print('creating $platform');
          platformConfigs[platform] = MigratePlatformConfig(createRevision: createRevision, baseRevision: currentRevision);
        }
      }
    }
  }
}

class MigratePlatformConfig {
  MigratePlatformConfig({this.createRevision, this.baseRevision});

  /// The Flutter SDK revision this platform was created by.
  ///
  /// Null if the initial create git revision is unknown.
  final String? createRevision;

  /// The Flutter SDK revision this platform was last migrated by.
  ///
  /// Null if the project was never migrated or the revision is unknown.
  String? baseRevision;
}

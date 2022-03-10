// // Copyright 2014 The Flutter Authors. All rights reserved.
// // Use of this source code is governed by a BSD-style license that can be
// // found in the LICENSE file.

// import 'dart:async';

// import 'package:yaml/yaml.dart';

// import '../base/common.dart';
// import '../base/file_system.dart';
// import '../base/logger.dart';
// import '../base/utils.dart';
// // import '../flutter_project_metadata.dart';
// import '../project.dart';
// import '../version.dart';

// /// Represents one .migrate_config file.
// ///
// /// Each platform and the root project directory includes one .migrate_config file.
// /// This file tracks the flutter sdk git hashes of the last successful migration and the
// /// version the project was created with.
// ///
// /// Each platform contains its own .migrate_config file because flutter create can be
// /// used to add support for new platforms, so the base create version may not always be the same.
// class FlutterProjectMetadata {
//   /// Creates a MigrateConfig by parsing an existing .migrate_config yaml file.
//   FlutterProjectMetadata(File metadataFile, Logger logger) : _metadataFile = metadataFile,
//                                                              _logger = logger,
//                                                              unmanagedFiles = <String>[] {
//     if (!_metadataFile.existsSync()) {
//       _logger.printError('No .metadata file found at ${file.path}');
//       // Create a default metadata.
//       return;
//     }
//     Object? yamlRoot;
//     try {
//       yamlRoot = loadYaml(_metadataFile.readAsStringSync());
//     } on YamlException {
//       // Handled in _validate below.
//     }
//     if (!_validate(yamlRoot)) {
//       _logger.printError('Invalid .metadata yaml file found at ${file.path}');
//       return;
//     }
//     final YamlMap map = yamlRoot! as YamlMap;
//     final Object? versionYaml = map['version'];
//     if (versionYaml == null || versionYaml is! YamlMap) {
//       _logger.printTrace('.metadata version is malformed.');
//     } else {
//       final YamlMap versionYamlMap = versionYaml! as YamlMap;
//       _versionChannel = versionYamlMap['versionChannel'] as String?;
//       _versionRevision = versionYamlMap['versionRevision'] as String?;
//       _versionRevision = stringToProjectType(versionYamlMap['projectType'] as String);
//     }

//     final Object? migrationYaml = map['migration'];
//     if (map['migration'] is YamlMap) {
//       final YamlMap migrationYamlMap = migrationYaml! as YamlMap;

//       final Object? platformsYaml = migrationYamlMap['platforms'];
//       Map<SupportedPlatforms, MigratePlatformConfig> platformConfigs = <SupportedPlatforms, MigratePlatformConfig>{};
//       if (platformsYaml is YamlList && platformsYaml.isNotEmpty) {
//         for (final Object? platform in platformsYaml as YamlList) {
//           if (platform != null && platform is YamlMap && platform!.containsKey('platform') && platform!.containsKey('createRevision') && platform!.containsKey('baseRevision')) {
//             final YamlMap platformYamlMap = platform! as YamlMap;
//             final String platformString = SupportedPlatform.values.firstWhere((SupportedPlatform platform) => platform.toString() == 'SupportedPlatform.${platformYamlMap['platform'] as String}');
//             platformConfigs[platformString] = MigratePlatformConfig(
//               createRevision: platform['createRevision'] as String?,
//               baseRevision: platform['baseRevision'] as String?,
//             );
//           } else {
//             // malformed platform entry
//             continue;
//           }
//         }
//       }

//       final Object? unmanagedFilesYaml = migrationYamlMap['unmanagedFiles'];
//       List<String> unmanagedFiles = <String>[];
//       if (unmanagedFilesYaml is YamlList && unmanagedFilesMap.isNotEmpty) {
//         unmanagedFiles = List<String>.from(unmanagedFilesMap.value.cast<String>());
//       }
//       migrateConfig = MigrateConfig(
//         platformConfigs: platformConfigs,
//         unmanagedFiles: unmanagedFiles,
//       );
//     }
//   }

//   /// Creates a MigrateConfig by explicitly providing all values.
//   FlutterProjectMetadata.explicit({
//     required String? versionChannel,
//     required String? versionRevision,
//     requried this.migrateConfig,
//     required Logger logger,
//   }) : _logger = logger,
//        _versionChannel = versionChannel,
//        _versionRevision = versionRevision;

//   /// The name of the config file.
//   static const String kFileName = '.metadata';

//   final String? _versionChannel;
//   String? get versionChannel => _versionChannel;
//   final String? _versionRevision;
//   String? get versionRevision => _versionRevision;
//   final FlutterProjectType? _projectType;
//   FlutterProjectType? get projectType => _projectType;


//   final MigrateConfig migrateConfig;

//   final Logger _logger;

//   final File _metadataFile;

//   /// Verifies the expected yaml keys are present in the file.
//   bool _validate(Object? yamlRoot) {
//     final Map<String, Type> validations = <String, Type>{
//       'verisonChannel': String,
//       'verisonRevision': String,
//       'migration': YamlMap,
//     };
//     if (yamlRoot != null && yamlRoot is! YamlMap) {
//       return false;
//     }
//     final YamlMap map = yamlRoot! as YamlMap;
//     bool isValid = true;
//     for (final MapEntry<String, Object> entry in validations.entries) {
//       if (!map.keys.contains(entry.key)) {
//         isValid = false;
//         _logger.printError('The key ${entry.key} was not found');
//         break;
//       }
//       if (map[entry.key] != null && (map[entry.key] as Object).runtimeType != entry.value) {
//         isValid = false;
//         _logger.printError('The value of key ${entry.key} was expected to be ${entry.value} but was ${(map[entry.key] as Object).runtimeType}');
//         break;
//       }
//     }
//     return isValid;
//   }


//   /// Writes the .migrate_config file in the provided project directory's platform subdirectory.
//   ///
//   /// We write the file manually instead of with a template because this
//   /// needs to be able to write the .migrate_config file into legacy apps.
//   void writeFile({Directory? projectDirectory}) {
//     String unmanagedFilesString = '';
//     for (final String path in unmanagedFiles) {
//       unmanagedFilesString += "\n    - '$path'";
//     }
//     String platformsString = '';
//     for (final MapEntry<String, MigrateConfig> entry in platformMigrateConfigs.entries) {
//       platfromsString += '\n    - platform: ${entry.key.toString().split('.').last}\n.      createRevision: ${entry.value.createRevision == null ? 'null' : "'${entry.value.createRevision}}'"}\n      baseRevision: ${entry.value.baseRevision == null ? 'null' : "'${entry.value.baseRevision}}'"}'
//     }
//     getFileFromPlatform(platform, projectDirectory: projectDirectory)
//       ..createSync(recursive: true)
//       ..writeAsStringSync('''
// # This file tracks properties of this Flutter project.
// # Used by Flutter tool to assess capabilities and perform upgrades etc.
// #
// # This file should be version controlled.

// version:
//   revision: {{flutterRevision}}
//   channel: {{flutterChannel}}

// project_type: app

// # Tracks the revisions
// migration:
//   platforms:$platformsString

//   # User provided section

//   # List of Local paths (relative to this file) that should be
//   # ignored by the migrate tool.
//   #
//   # Files that are not part of the templates will be ignored by default.
//   unmanagedFiles:$unmanagedFilesString

// ''',
//     flush: true);
//   }

//   void populate({
//     List<SupportedPlatform>? platforms,
//     Directory? projectDirectory,
//     String? currentRevision,
//     String? createRevision,
//     bool create = true,
//     bool update = true,
//     required Logger logger,
//   }) {
//     migrateConfig.populate(
//       platforms: platforms,
//       projectDirectory: projectDirectory,
//       currentRevision: currentRevision,
//       createRevision: createRevision,
//       create: create,
//       update: update,
//       logger: logger,
//     );
//   }

//   /// Finds the fallback revision to use when no base revision is found in the migrate config.
//   String getFallbackBaseRevision(Logger logger, FlutterVersion flutterVersion) {
//     // Use the .metadata file if it exists.
//     final FlutterProjectMetadata metadata = FlutterProjectMetadata(metadataFile, logger);
//     if (versionRevision != null) {
//       return versionRevision!;
//     }
//     return flutterVersion.frameworkRevision;
//   }
// }

// class MigrateConfig {
//   MigrateConfig({
//     this.platformMigrateConfigs = const <SupportedPlatform, MigratePlatformConfig>{},
//     this.unmanagedFiles = _kDefaultUnmanagedFiles
//   });

//   /// A mapping of the files that are unmanaged by defult for each platform.
//   static const List<String> _kDefaultUnmanagedFiles = <String>[
//     'lib/main.dart',
//     'ios/Runner.xcodeproj/project.pbxproj',
//   ];

//   /// The 
//   final Map<SupportedPlatform, MigratePlatformConfig> platformConfigs;

//   /// A list of paths relative to this file the migrate tool should ignore.
//   ///
//   /// These files are typically user-owned files that should not be changed.
//   final List<String> unmanagedFiles;


//   void populate({
//     List<SupportedPlatform>? platforms,
//     Directory? projectDirectory,
//     String? currentRevision,
//     String? createRevision,
//     bool create = true,
//     bool update = true,
//     required Logger logger,
//   }) {
//     final FlutterProject flutterProject = projectDirectory == null ? FlutterProject.current() : FlutterProject.fromDirectory(projectDirectory);
//     platforms ??= flutterProject.getSupportedPlatforms(includeRoot: true);

//     final Map<SupportedPlatform, MigratePlatformConfig> platformConfigs = <SupportedPlatform, MigratePlatformConfig>{};
//     for (final SupportedPlatform platform in platforms) {
//       if (platformConfigs.containsKey(platform)) {
//         if (update) {
//           platformConfigs[platform].baseRevision = currentRevision;
//         }
//       } else {
//         if (create) {
//           platformConfigs[platform] = MigratePlatformConfig(createRevision: createRevision, baseRevision: currentRevision);
//         }
//       }
//     }
//   }
// }

// class MigratePlatformConfig {
//   MigratePlatformConfig({this.createRevision, this.baseRevision});

//   /// The Flutter SDK revision this platform was created by.
//   ///
//   /// Null if the initial create git revision is unknown.
//   final String? createRevision;

//   /// The Flutter SDK revision this platform was last migrated by.
//   ///
//   /// Null if the project was never migrated or the revision is unknown.
//   String? baseRevision;
// }

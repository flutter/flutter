// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/platform.dart';
import 'cache.dart';
import 'flutter_manifest.dart';
import 'git.dart';
import 'project.dart';
import 'project_validator_result.dart';
import 'version.dart';

abstract class ProjectValidator {
  const ProjectValidator();
  String get title;
  bool get machineOutput => false;
  bool supportsProject(FlutterProject project);

  /// Can return more than one result in case a file/command have a lot of info to share to the user
  Future<List<ProjectValidatorResult>> start(FlutterProject project);
}

abstract class MachineProjectValidator extends ProjectValidator {
  const MachineProjectValidator();

  @override
  bool get machineOutput => true;
}

/// Validator run for all platforms that extract information from the pubspec.yaml.
///
/// Specific info from different platforms should be written in their own ProjectValidator.
class VariableDumpMachineProjectValidator extends MachineProjectValidator {
  VariableDumpMachineProjectValidator({
    required this.logger,
    required this.fileSystem,
    required this.platform,
    required this.git,
  });

  final Logger logger;
  final FileSystem fileSystem;
  final Platform platform;
  final Git git;

  String _toJsonValue(Object? obj) {
    var value = obj.toString();
    if (obj is String) {
      value = '"$obj"';
    }
    value = value.replaceAll(r'\', r'\\');
    return value;
  }

  @override
  Future<List<ProjectValidatorResult>> start(FlutterProject project) async {
    final version = FlutterVersion(flutterRoot: Cache.flutterRoot!, fs: fileSystem, git: git);
    final result = <String, Object?>{
      'FlutterProject.directory': project.directory.absolute.path,
      'FlutterProject.metadataFile': project.metadataFile.absolute.path,
      'FlutterProject.android.exists': project.android.existsSync(),
      'FlutterProject.ios.exists': project.ios.exists,
      'FlutterProject.web.exists': project.web.existsSync(),
      'FlutterProject.macos.exists': project.macos.existsSync(),
      'FlutterProject.linux.exists': project.linux.existsSync(),
      'FlutterProject.windows.exists': project.windows.existsSync(),
      'FlutterProject.fuchsia.exists': project.fuchsia.existsSync(),

      'FlutterProject.android.isKotlin': project.android.isKotlin,
      'FlutterProject.ios.isSwift': project.ios.isSwift,

      'FlutterProject.isModule': project.isModule,
      'FlutterProject.isPlugin': project.isPlugin,

      'FlutterProject.manifest.appname': project.manifest.appName,

      // FlutterVersion
      'FlutterVersion.frameworkRevision': version.frameworkRevision,

      // Platform
      'Platform.operatingSystem': platform.operatingSystem,
      'Platform.isAndroid': platform.isAndroid,
      'Platform.isIOS': platform.isIOS,
      'Platform.isWindows': platform.isWindows,
      'Platform.isMacOS': platform.isMacOS,
      'Platform.isFuchsia': platform.isFuchsia,
      'Platform.pathSeparator': platform.pathSeparator,

      // Cache
      'Cache.flutterRoot': Cache.flutterRoot,
    };

    return <ProjectValidatorResult>[
      for (final String key in result.keys)
        ProjectValidatorResult(
          name: key,
          value: _toJsonValue(result[key]),
          status: StatusProjectValidator.info,
        ),
    ];
  }

  @override
  bool supportsProject(FlutterProject project) {
    // this validator will run for any type of project
    return true;
  }

  @override
  String get title => 'Machine JSON variable dump';
}

/// Validator run for all platforms that extract information from the pubspec.yaml.
///
/// Specific info from different platforms should be written in their own ProjectValidator.
class GeneralInfoProjectValidator extends ProjectValidator {
  @override
  Future<List<ProjectValidatorResult>> start(FlutterProject project) async {
    final FlutterManifest flutterManifest = project.manifest;
    final result = <ProjectValidatorResult>[];
    final ProjectValidatorResult appNameValidatorResult = _getAppNameResult(flutterManifest);
    result.add(appNameValidatorResult);
    final String supportedPlatforms = _getSupportedPlatforms(project);
    if (supportedPlatforms.isEmpty) {
      return result;
    }
    final supportedPlatformsResult = ProjectValidatorResult(
      name: 'Supported Platforms',
      value: supportedPlatforms,
      status: StatusProjectValidator.success,
    );
    final ProjectValidatorResult isFlutterPackage = _isFlutterPackageValidatorResult(
      flutterManifest,
    );
    result.addAll(<ProjectValidatorResult>[supportedPlatformsResult, isFlutterPackage]);
    if (flutterManifest.flutterDescriptor.isNotEmpty) {
      result.add(_materialDesignResult(flutterManifest));
      result.add(_pluginValidatorResult(flutterManifest));
    }
    result.add(await project.android.validateJavaAndGradleAgpVersions());
    return result;
  }

  ProjectValidatorResult _getAppNameResult(FlutterManifest flutterManifest) {
    final String appName = flutterManifest.appName;
    const name = 'App Name';
    if (appName.isEmpty) {
      return const ProjectValidatorResult(
        name: name,
        value: 'name not found',
        status: StatusProjectValidator.error,
      );
    }
    return ProjectValidatorResult(
      name: name,
      value: appName,
      status: StatusProjectValidator.success,
    );
  }

  ProjectValidatorResult _isFlutterPackageValidatorResult(FlutterManifest flutterManifest) {
    final String value;
    final StatusProjectValidator status;
    if (flutterManifest.flutterDescriptor.isNotEmpty) {
      value = 'yes';
      status = StatusProjectValidator.success;
    } else {
      value = 'no';
      status = StatusProjectValidator.warning;
    }

    return ProjectValidatorResult(name: 'Is Flutter Package', value: value, status: status);
  }

  ProjectValidatorResult _materialDesignResult(FlutterManifest flutterManifest) {
    return ProjectValidatorResult(
      name: 'Uses Material Design',
      value: flutterManifest.usesMaterialDesign ? 'yes' : 'no',
      status: StatusProjectValidator.success,
    );
  }

  String _getSupportedPlatforms(FlutterProject project) {
    return project
        .getSupportedPlatforms()
        .map((SupportedPlatform platform) => platform.name)
        .join(', ');
  }

  ProjectValidatorResult _pluginValidatorResult(FlutterManifest flutterManifest) {
    return ProjectValidatorResult(
      name: 'Is Plugin',
      value: flutterManifest.isPlugin ? 'yes' : 'no',
      status: StatusProjectValidator.success,
    );
  }

  @override
  bool supportsProject(FlutterProject project) {
    // this validator will run for any type of project
    return true;
  }

  @override
  String get title => 'General Info';
}

class AndroidProjectGradlePluginValidator extends ProjectValidator {
  @override
  bool supportsProject(FlutterProject project) {
    return project.android.existsSync();
  }

  @override
  String get title => 'Android Gradle plugins';

  @override
  Future<List<ProjectValidatorResult>> start(FlutterProject project) async {
    final Directory hostAppGradleRoot = project.android.hostAppGradleRoot;
    if (!hostAppGradleRoot.existsSync()) {
      return <ProjectValidatorResult>[];
    }
    final List<File> files = _findGradleFiles(hostAppGradleRoot, project.directory.fileSystem);
    final results = <ProjectValidatorResult>[];

    for (final file in files) {
      final String relativePath = project.directory.fileSystem.path.relative(
        file.path,
        from: hostAppGradleRoot.path,
      );
      final String basename = project.directory.fileSystem.path.basename(file.path);
      final bool isSettings = basename == 'settings.gradle' || basename == 'settings.gradle.kts';
      final incorrectPlugin = isSettings
          ? 'dev.flutter.flutter-plugin-loader'
          : 'dev.flutter.flutter-gradle-plugin';

      final String content;
      try {
        content = file.readAsStringSync();
      } on FileSystemException catch (_) {
        continue;
      }
      final String noBlockComments = content.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
      final List<String> lines = noBlockComments.split('\n');

      var hasIncorrectPlugin = false;
      for (final line in lines) {
        final String trimmed = line.trim();
        if (trimmed.startsWith('//')) {
          continue;
        }
        if (trimmed.contains(incorrectPlugin)) {
          hasIncorrectPlugin = true;
          break;
        }
      }

      if (hasIncorrectPlugin) {
        final String warningPath = relativePath.endsWith('.kts')
            ? relativePath.substring(0, relativePath.length - 4)
            : relativePath;
        final warning = isSettings
            ? 'The dev.flutter.flutter-plugin-loader plugin should be applied in build.gradle, not settings.gradle. Use dev.flutter.flutter-gradle-plugin instead.'
            : 'The dev.flutter.flutter-gradle-plugin plugin should be applied in settings.gradle, not $warningPath. Use dev.flutter.flutter-plugin-loader instead.';
        results.add(
          ProjectValidatorResult(
            name: relativePath,
            value: '$incorrectPlugin applied in $relativePath',
            status: StatusProjectValidator.error,
            warning: warning,
          ),
        );
      }
    }

    if (results.isEmpty) {
      results.add(
        const ProjectValidatorResult(
          name: 'Gradle plugins check',
          value: 'Correct plugins applied',
          status: StatusProjectValidator.success,
        ),
      );
    }
    return results;
  }

  List<File> _findGradleFiles(Directory dir, FileSystem fileSystem) {
    final results = <File>[];
    try {
      for (final FileSystemEntity entity in dir.listSync(followLinks: false)) {
        if (entity is Directory) {
          final String name = fileSystem.path.basename(entity.path);
          if (name == 'build' || name == '.gradle' || name == '.git') {
            continue;
          }
          results.addAll(_findGradleFiles(entity, fileSystem));
        } else if (entity is File) {
          final String name = fileSystem.path.basename(entity.path);
          if (name == 'settings.gradle' ||
              name == 'settings.gradle.kts' ||
              name == 'build.gradle' ||
              name == 'build.gradle.kts') {
            results.add(entity);
          }
        }
      }
    } on Exception catch (_) {
      // Safely ignore directory listing errors
    }
    return results;
  }
}

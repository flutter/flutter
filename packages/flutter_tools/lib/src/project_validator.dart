// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:process/process.dart';

import 'base/io.dart';
import 'cache.dart';
import 'convert.dart';
import 'dart_pub_json_formatter.dart';
import 'flutter_manifest.dart';
import 'project.dart';
import 'project_validator_result.dart';

abstract class ProjectValidator {
  const ProjectValidator();
  String get title;
  bool supportsProject(FlutterProject project);
  /// Can return more than one result in case a file/command have a lot of info to share to the user
  Future<List<ProjectValidatorResult>> start(FlutterProject project);
}

/// Validator run for all platforms that extract information from the pubspec.yaml.
///
/// Specific info from different platforms should be written in their own ProjectValidator.
class MachineDumpProjectValidator extends ProjectValidator{
  String _toJsonValue(Object? obj) {
    String value = entry.value.toString();
    if (entry.value is String) {
      value = '"${entry.value}"';
    }
    return value;
  } 

  @override
  Future<List<ProjectValidatorResult>> start(FlutterProject project) async {
    final Map<String, Object?> output = <String, Object?>{};

    final List<ProjectValidatorResult> result = <ProjectValidatorResult[];
    // FlutterProject
    final FlutterProjectFactory flutterProjectFactory = FlutterProjectFactory(logger: logger, fileSystem: fileSystem);
    final FlutterProject project = projectDirectory == null
      ? FlutterProject.current()
      : flutterProjectFactory.fromDirectory(fileSystem.directory(projectDirectory));
    result.add(ProjectValidatorResult(
      name: 'FlutterProject.directory',
      result: _toJsonValue(project.directory.absolute.path),
      status: StatusProjectValidator.info
    );
    result.add(ProjectValidatorResult(
      name: 'FlutterProject.metadataFile',
      result: _toJsonValue(project.metadataFile.absolute.path),
      status: StatusProjectValidator.info
    );
    result.add(ProjectValidatorResult(
      name: 'FlutterProject.android.exists',
      result: _toJsonValue(project.android.existsSync()),
      status: StatusProjectValidator.info
    );
    result.add(ProjectValidatorResult(
      name: 'FlutterProject.ios.exists',
      result: _toJsonValue(project.ios.exists),
      status: StatusProjectValidator.info
    );
    result.add(ProjectValidatorResult(
      name: 'FlutterProject.web.exists',
      result: _toJsonValue(project.web.existsSync()),
      status: StatusProjectValidator.info
    );
    result.add(ProjectValidatorResult(
      name: 'FlutterProject.macos.exists',
      result: _toJsonValue(project.macos.existsSync()),
      status: StatusProjectValidator.info
    );
    result.add(ProjectValidatorResult(
      name: 'FlutterProject.linux.exists',
      result: _toJsonValue(project.linux.existsSync()),
      status: StatusProjectValidator.info
    );
    result.add(ProjectValidatorResult(
      name: 'FlutterProject.windows.exists',
      result: _toJsonValue(project.windows.existsSync()),
      status: StatusProjectValidator.info
    );
    result.add(ProjectValidatorResult(
      name: 'FlutterProject.fuchsia.exists',
      result: _toJsonValue(project.fuchsia.existsSync()),
      status: StatusProjectValidator.info
    );

    result.add(ProjectValidatorResult(
      name: 'FlutterProject.android.isKotlin',
      result: _toJsonValue(project.android.isKotlin),
      status: StatusProjectValidator.information
    );
    result.add(ProjectValidatorResult(
      name: 'FlutterProject.ios.isSwift',
      result: _toJsonValue(project.ios.isSwift),
      status: StatusProjectValidator.information
    );

    result.add(ProjectValidatorResult(
      name: 'FlutterProject.isModule',
      result: _toJsonValue(project.isModule),
      status: StatusProjectValidator.information
    );
    result.add(ProjectValidatorResult(
      name: 'FlutterProject.isPlugin',
      result: _toJsonValue(project.isPlugin),
      status: StatusProjectValidator.information
    );

    result.add(ProjectValidatorResult(
      name: 'FlutterProject.manifest.appname',
      result: _toJsonValue(project.manifest.appName),
      status: StatusProjectValidator.information
    );

    // FlutterVersion
    final FlutterVersion version = FlutterVersion(workingDirectory: project.directory.absolute.path);
    result.add(ProjectValidatorResult(
      name: 'FlutterVersion.frameworkRevision',
      result: _toJsonValue(version.frameworkRevision),
      status: StatusProjectValidator.information
    );

    // Platform
    result.add(ProjectValidatorResult(
      name: 'Platform.operatingSystem',
      result: _toJsonValue(platform.operatingSystem),
      status: StatusProjectValidator.information
    );
    result.add(ProjectValidatorResult(
      name: 'Platform.isAndroid',
      result: _toJsonValue(platform.isAndroid),
      status: StatusProjectValidator.information
    );
    result.add(ProjectValidatorResult(
      name: 'Platform.isIOS',
      result: _toJsonValue(platform.isIOS),
      status: StatusProjectValidator.information
    );
    result.add(ProjectValidatorResult(
      name: 'Platform.isWindows',
      result: _toJsonValue(platform.isWindows),
      status: StatusProjectValidator.information
    );
    result.add(ProjectValidatorResult(
      name: 'Platform.isMacOS',
      result: _toJsonValue(platform.isMacOS),
      status: StatusProjectValidator.information
    );
    result.add(ProjectValidatorResult(
      name: 'Platform.isFuchsia',
      result: _toJsonValue(platform.isFuchsia),
      status: StatusProjectValidator.information
    );
    result.add(ProjectValidatorResult(
      name: 'Platform.pathSeparator',
      result: _toJsonValue(platform.pathSeparator),
      status: StatusProjectValidator.information
    );

    // Cache
    result.add(ProjectValidatorResult(
      name: 'Cache.flutterRoot',
      result: _toJsonValue(Cache.flutterRoot),
      status: StatusProjectValidator.information
    );

    // Print properties
    logger.printStatus('{');
    int count = 0;
    for (final MapEntry<String, Object?> entry in output.entries) {
      String value = entry.value.toString();
      if (entry.value is String) {
        value = '"${entry.value}"';
      }
      count++;
      logger.printStatus('  "${entry.key}": $value${count < output.length ? ',' : ''}');
    }
    logger.printStatus('}');
    return result;
  }

  @override
  bool supportsProject(FlutterProject project) {
    // this validator will run for any type of project
    return true;
  }

  @override
  String get title => 'General Info';
}

/// Validator run for all platforms that extract information from the pubspec.yaml.
///
/// Specific info from different platforms should be written in their own ProjectValidator.
class GeneralInfoProjectValidator extends ProjectValidator{
  @override
  Future<List<ProjectValidatorResult>> start(FlutterProject project) async {
    final FlutterManifest flutterManifest = project.manifest;
    final List<ProjectValidatorResult> result = <ProjectValidatorResult>[];
    final ProjectValidatorResult appNameValidatorResult = _getAppNameResult(flutterManifest);
    result.add(appNameValidatorResult);
    final String supportedPlatforms = _getSupportedPlatforms(project);
    if (supportedPlatforms.isEmpty) {
      return result;
    }
    final ProjectValidatorResult supportedPlatformsResult = ProjectValidatorResult(
        name: 'Supported Platforms',
        value: supportedPlatforms,
        status: StatusProjectValidator.success
    );
    final ProjectValidatorResult isFlutterPackage = _isFlutterPackageValidatorResult(flutterManifest);
    result.addAll(<ProjectValidatorResult>[supportedPlatformsResult, isFlutterPackage]);
    if (flutterManifest.flutterDescriptor.isNotEmpty) {
      result.add(_materialDesignResult(flutterManifest));
      result.add(_pluginValidatorResult(flutterManifest));
    }
    return result;
  }

  ProjectValidatorResult _getAppNameResult(FlutterManifest flutterManifest) {
    final String appName = flutterManifest.appName;
    const String name = 'App Name';
    if (appName.isEmpty) {
      return const ProjectValidatorResult(
          name: name,
          value: 'name not found',
          status: StatusProjectValidator.error
      );
    }
    return ProjectValidatorResult(
        name: name,
        value: appName,
        status: StatusProjectValidator.success
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

    return ProjectValidatorResult(
        name: 'Is Flutter Package',
        value: value,
        status: status
    );
  }

  ProjectValidatorResult _materialDesignResult(FlutterManifest flutterManifest) {
    return ProjectValidatorResult(
      name: 'Uses Material Design',
      value: flutterManifest.usesMaterialDesign? 'yes' : 'no',
      status: StatusProjectValidator.success
    );
  }

  String _getSupportedPlatforms(FlutterProject project) {
    return project.getSupportedPlatforms().map((SupportedPlatform platform) => platform.name).join(', ');
  }

  ProjectValidatorResult _pluginValidatorResult(FlutterManifest flutterManifest) {
    return ProjectValidatorResult(
      name: 'Is Plugin',
      value: flutterManifest.isPlugin? 'yes' : 'no',
      status: StatusProjectValidator.success
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

class PubDependenciesProjectValidator extends ProjectValidator {
  const PubDependenciesProjectValidator(this._processManager);
  final ProcessManager _processManager;

  @override
  Future<List<ProjectValidatorResult>> start(FlutterProject project) async {
    const String name = 'Dart dependencies';
    final ProcessResult processResult = await _processManager.run(<String>['dart', 'pub', 'deps', '--json']);
    if (processResult.stdout is! String) {
      return <ProjectValidatorResult>[
        _createProjectValidatorError(name, 'Command dart pub deps --json failed')
      ];
    }

    final LinkedHashMap<String, dynamic> jsonResult;
    final List<ProjectValidatorResult> result = <ProjectValidatorResult>[];
    try {
      jsonResult = json.decode(
        processResult.stdout.toString()
      ) as LinkedHashMap<String, dynamic>;
    } on FormatException{
      result.add(_createProjectValidatorError(name, processResult.stderr.toString()));
      return result;
    }

    final DartPubJson dartPubJson = DartPubJson(jsonResult);
    final List <String> dependencies = <String>[];

    // Information retrieved from the pubspec.lock file if a dependency comes from
    // the hosted url https://pub.dartlang.org we ignore it or if the package
    // is the current directory being analyzed (root).
    final Set<String> hostedDependencies = <String>{'hosted', 'root'};

    for (final DartDependencyPackage package in dartPubJson.packages) {
      if (!hostedDependencies.contains(package.source)) {
        dependencies.addAll(package.dependencies);
      }
    }

    final String value;
    if (dependencies.isNotEmpty) {
      final String verb = dependencies.length == 1 ? 'is' : 'are';
      value = '${dependencies.join(', ')} $verb not hosted';
    } else {
      value = 'All pub dependencies are hosted on https://pub.dartlang.org';
    }

    result.add(
       ProjectValidatorResult(
        name: name,
        value: value,
        status: StatusProjectValidator.info,
      )
    );

    return result;
  }

  @override
  bool supportsProject(FlutterProject project) {
    return true;
  }

  @override
  String get title => 'Pub dependencies';

  ProjectValidatorResult _createProjectValidatorError(String name, String value) {
    return ProjectValidatorResult(name: name, value: value, status: StatusProjectValidator.error);
  }
}

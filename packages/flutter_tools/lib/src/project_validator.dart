// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'base/file_system.dart';
import 'base/logger.dart';
import 'flutter_manifest.dart';
import 'project.dart';
import 'project_validator_result.dart';

abstract class ProjectValidator {
  String get title;
  bool supportsProject(FlutterProject project);
  /// Can return more than one result in case a file/command have a lot of info to share to the user
  Future<List<ProjectValidatorResult>> start(FlutterProject project, {required Logger logger, required FileSystem fileSystem});
  /// new ProjectValidators should be added here for the ValidateProjectCommand to run
  static List <ProjectValidator> allProjectValidators = <ProjectValidator>[
    GeneralInfoProjectValidator(),
  ];
}

/// Validator run for all platforms that extract information from the pubspec.yaml
///
/// Specific info from different platforms should be written in their own ProjectValidator
class GeneralInfoProjectValidator extends ProjectValidator{
  @override
  Future<List<ProjectValidatorResult>> start(FlutterProject project, {required Logger logger, required FileSystem fileSystem}) async {
    final FlutterManifest? flutterManifest = FlutterManifest.createFromPath(
        project.pubspecFile.path, 
        logger: logger, 
        fileSystem: fileSystem
    );
    if (flutterManifest == null) {
      return [_emptyProjectValidatorResult];
    }
    final ProjectValidatorResult appNameValidatorResult = getAppNameResult(flutterManifest);
    final String supportedPlatforms = getSupportedPlatforms(project);
    if (supportedPlatforms.isEmpty) {
      return <ProjectValidatorResult>[appNameValidatorResult];
    }
    final ProjectValidatorResult supportedPlatformsResult = ProjectValidatorResult(
        name: 'Supported Platforms',
        value: supportedPlatforms,
        status: StatusProjectValidator.success
    );
    final ProjectValidatorResult isFlutterPackage = isFlutterPackageValidatorResult(flutterManifest);
    final List<ProjectValidatorResult> result = <ProjectValidatorResult>[
      appNameValidatorResult,
      supportedPlatformsResult,
      isFlutterPackage,
    ];
    if (flutterManifest.flutterDescriptor.isNotEmpty) {
      result.add(materialDesignResult(flutterManifest));
      result.add(pluginValidatorResult(flutterManifest));
    }
    return result;
  }
  
  ProjectValidatorResult get _emptyProjectValidatorResult { 
    return const ProjectValidatorResult(
        name: 'Error',
        value: 'project not found',
        status: StatusProjectValidator.error
    );
  }

  ProjectValidatorResult getAppNameResult(FlutterManifest flutterManifest) {
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

  ProjectValidatorResult isFlutterPackageValidatorResult(FlutterManifest flutterManifest) {
    String value;
    StatusProjectValidator status;
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

  ProjectValidatorResult materialDesignResult(FlutterManifest flutterManifest) {
    return ProjectValidatorResult(
      name: 'Uses Material Design',
      value: flutterManifest.usesMaterialDesign? 'yes' : 'no',
      status: StatusProjectValidator.success
    );
  }

  String getSupportedPlatforms(FlutterProject project) {
    return project.getSupportedPlatforms().map((SupportedPlatform platform) => platform.name).join(', ');
  }

  ProjectValidatorResult pluginValidatorResult(FlutterManifest flutterManifest) {
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

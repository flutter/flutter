// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';

import 'base/pubspec_content.dart';
import 'project.dart';
import 'project_validator_result.dart';

abstract class ProjectValidator {
  String get title;
  bool supportsProject(FlutterProject project);
  /// Can return more than one result in case a file/command have a lot of info to share to the user
  Future<List<ProjectValidatorResult>> start(FlutterProject project);
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
  Future<List<ProjectValidatorResult>> start(FlutterProject project) async {
    final PubspecContent pubspecContent = PubspecContent(loadYaml(project.pubspecFile.readAsStringSync()) as YamlMap);
    final ProjectValidatorResult appNameValidatorResult = getAppNameResult(pubspecContent);
    final String supportedPlatforms = getSupportedPlatforms(project);
    if (supportedPlatforms.isEmpty) {
      return <ProjectValidatorResult>[appNameValidatorResult];
    }
    final ProjectValidatorResult supportedPlatformsResult = ProjectValidatorResult(
        name: 'Supported Platforms',
        value: supportedPlatforms,
        status: StatusProjectValidator.success
    );
    final ProjectValidatorResult isFlutterPackage = isFlutterPackageValidatorResult(pubspecContent);
    final List<ProjectValidatorResult> result = <ProjectValidatorResult>[
      appNameValidatorResult,
      supportedPlatformsResult,
      isFlutterPackage,
    ];
    if (pubspecContent.isFlutterPackage) {
      result.add(materialDesignResult(pubspecContent));
      result.add(pluginValidatorResult(pubspecContent));
    }
    return result;
  }

  ProjectValidatorResult getAppNameResult(PubspecContent pubspecContent) {
    final String? appName = pubspecContent.appName;
    const String name = 'App Name';
    if (appName == null) {
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

  ProjectValidatorResult isFlutterPackageValidatorResult(PubspecContent pubspecContent) {
    String value;
    StatusProjectValidator status;
    if (pubspecContent.isFlutterPackage) {
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

  ProjectValidatorResult materialDesignResult(PubspecContent pubspecContent) {
    return ProjectValidatorResult(
      name: 'Uses Material Design',
      value: pubspecContent.usesMaterialDesign? 'yes' : 'no',
      status: StatusProjectValidator.success
    );
  }

  String getSupportedPlatforms(FlutterProject project) {
    return project.getSupportedPlatforms().map((SupportedPlatform platform) => platform.name).join(', ');
  }

  ProjectValidatorResult pluginValidatorResult(PubspecContent pubspecContent) {
    return ProjectValidatorResult(
      name: 'Is Plugin',
      value: pubspecContent.isPlugin? 'yes' : 'no',
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

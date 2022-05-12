// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';

import 'project.dart';
import 'project_validator_result.dart';

abstract class ProjectValidator {
  String get title;
  bool supportsProject(FlutterProject project);
  /// Can return more than one result in case a file/command have a lot of info to share to the user
  Future<List<ProjectValidatorResult>> start(FlutterProject project);
  /// new ProjectValidators should be added here for the ValidateProjectCommand to run
  static List <ProjectValidator> allProjectValidators = <ProjectValidator>[
    GeneralInfoValidator(),
  ];
}

class GeneralInfoValidator extends ProjectValidator{
  @override
  Future<List<ProjectValidatorResult>> start(FlutterProject project) async {
    final YamlMap pubContent = loadYaml(project.pubspecFile.readAsStringSync()) as YamlMap;
    final ProjectValidatorResult appNameValidatorResult = getAppNameResult(pubContent);
    final String supportedPlatforms = getSupportedPlatforms(project);
    if (supportedPlatforms.isEmpty) {
      return [appNameValidatorResult];
    }
    final ProjectValidatorResult supportedPlatformsResult = ProjectValidatorResult(
        name: 'Supported Platforms',
        value: supportedPlatforms,
        status: StatusProjectValidator.success
    );
    final ProjectValidatorResult isFlutterPackage = isFlutterPackageValidatorResult(pubContent);
    final List<ProjectValidatorResult> result = <ProjectValidatorResult>[
      appNameValidatorResult,
      supportedPlatformsResult,
      isFlutterPackage,
    ];
    if (isFlutterPackage.value == 'yes') {
      final YamlMap flutterNode = pubContent['flutter'] as YamlMap;
      result.add(materialDesignResult(flutterNode));
      result.add(pluginValidatorResult(flutterNode));
    }
    return result;
  }

  ProjectValidatorResult getAppNameResult(YamlMap pubContent) {
    final String? appName = pubContent['name'] as String?;
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

  ProjectValidatorResult isFlutterPackageValidatorResult(YamlMap pubContent) {
    String value;
    StatusProjectValidator status;
    if (pubContent.containsKey('flutter')) {
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

  ProjectValidatorResult materialDesignResult(YamlMap flutterNode) {
    bool isMaterialDesign;

    if (flutterNode.containsKey('uses-material-design')) {
      isMaterialDesign = flutterNode['uses-material-design'] as bool;
    } else {
      isMaterialDesign = false;
    }

    final String value = isMaterialDesign? 'yes' : 'no';
    return ProjectValidatorResult(
      name: 'Uses Material Design',
      value: value,
      status: StatusProjectValidator.success
    );
  }

  String getSupportedPlatforms(FlutterProject project) {
    final List<SupportedPlatform> supportedPlatforms = project.getSupportedPlatforms();
    final List<String> allPlatforms = <String>[];

    for (final SupportedPlatform platform in supportedPlatforms) {
      allPlatforms.add(platform.name);
    }
    return allPlatforms.join(', ');
  }

  ProjectValidatorResult pluginValidatorResult(YamlMap flutterNode) {
    final String value = flutterNode.containsKey('plugin')? 'yes' : 'no';
    return ProjectValidatorResult(
      name: 'Is Plugin',
      value: value,
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

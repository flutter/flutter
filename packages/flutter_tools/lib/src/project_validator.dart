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
    final String appName = pubContent['name'] as String;

    final ProjectValidatorResult appNameValidatorResult = ProjectValidatorResult(
        name: 'App Name',
        value: appName,
        status: StatusProjectValidator.success
    );

    final ProjectValidatorResult isFlutterPackage = isFlutterPackageValidatorResult(pubContent);
    final ProjectValidatorResult supportedPlatforms = supportedPlatformValidatorResult(project);

    final List<ProjectValidatorResult> result = <ProjectValidatorResult>[
      appNameValidatorResult,
      supportedPlatforms,
      isFlutterPackage,
    ];

    if (isFlutterPackage.value == 'yes') {
      final YamlMap flutterNode = pubContent['flutter'] as YamlMap;
      result.add(materialDesignResult(flutterNode));
      result.add(pluginValidatorResult(flutterNode));
    }

    return result;
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
    String value;
    StatusProjectValidator status;
    bool isMaterialDesign;

    if (flutterNode.containsKey('uses-material-design')) {
      isMaterialDesign = flutterNode['uses-material-design'] as bool;
    } else {
      isMaterialDesign = false;
    }

    value = isMaterialDesign? 'yes' : 'no';
    status = StatusProjectValidator.success;

    return ProjectValidatorResult(
      name: 'Uses Material Design',
      value: value,
      status: status
    );
  }

  ProjectValidatorResult supportedPlatformValidatorResult(FlutterProject project) {
    final List<SupportedPlatform> supportedPlatforms = project.getSupportedPlatforms();
    final List<String> allPlatforms = <String>[];

    for (final SupportedPlatform platform in supportedPlatforms) {
      allPlatforms.add(platform.name);
    }
    final String value = allPlatforms.join(', ');
    return ProjectValidatorResult(
      name: 'Supported Platforms',
      value: value,
      status: StatusProjectValidator.success
    );
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
    // this validator will run for any type of flutter project
    return true;
  }

  @override
  String get title => 'General Info';
}

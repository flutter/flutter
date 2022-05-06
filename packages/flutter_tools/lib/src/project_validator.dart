// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
    return [];
  }

  @override
  bool supportsProject(FlutterProject project) {
    // this validator will run for any type of flutter project
    return true;
  }

  @override
  String get title => 'General Info';
}

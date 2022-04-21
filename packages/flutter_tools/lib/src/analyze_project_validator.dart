// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'analyze_project.dart';
import 'project.dart';

abstract class ProjectValidator {
  bool supportsProject(FlutterProject project);
  /// Can return more than one result in case a file/command have a lot of info to share to the user
  Future<List<ProjectValidatorResult>> start(FlutterProject project);
  static List <ProjectValidator> allProjectValidators = <ProjectValidator>[
    // TODO(jasguerrero): add validators
  ];
}

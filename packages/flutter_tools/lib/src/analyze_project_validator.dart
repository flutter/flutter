// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'analyze_project.dart';
import 'project.dart';

abstract class ProjectValidator {
  List<SupportedPlatform> get supportedPlatforms;
  List<ProjectValidatorResult> start(FlutterProject project);

}

class AvailableProjectValidators {

  AvailableProjectValidators() {
    allProjectValidatorsMap = <SupportedPlatform, List<ProjectValidator>>{};
    buildValidatorsByPlatformMap();
  }

  late Map<SupportedPlatform, List<ProjectValidator>> allProjectValidatorsMap;

  List<ProjectValidator> availableValidatorsList = [
    // add validators
  ];

  void buildValidatorsByPlatformMap(){
    for (final ProjectValidator validator in availableValidatorsList) {
      for (final SupportedPlatform supportedPlatform in validator.supportedPlatforms) {
        if (!allProjectValidatorsMap.containsKey(supportedPlatform)) {
          allProjectValidatorsMap[supportedPlatform] = <ProjectValidator>[];
        }
        allProjectValidatorsMap[supportedPlatform]!.add(validator);
      }
    }
  }

  List<ProjectValidator> getValidatorTasks(SupportedPlatform platform){
    if (allProjectValidatorsMap.containsKey(platform)) {
      return allProjectValidatorsMap[platform]!;
    } else {
      return [];
    }
  }
}

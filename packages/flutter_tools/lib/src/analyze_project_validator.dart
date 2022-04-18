// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'analyze_project.dart';
import 'project.dart';

abstract class ProjectValidatorTask {
  List<SupportedPlatform> get supportedPlatforms;
  List<ProjectValidatorResult> start(FlutterProject project);

}

class AvailableProjectValidators {

  AvailableProjectValidators() {
    allProjectValidatorsMap = <SupportedPlatform, List<ProjectValidatorTask>>{};
    buildValidatorsByPlatformMap();
  }

  late Map<SupportedPlatform, List<ProjectValidatorTask>> allProjectValidatorsMap;

  List<ProjectValidatorTask> availableValidatorsList = [
    // add validators
  ];

  void buildValidatorsByPlatformMap(){
    for (final ProjectValidatorTask validator in availableValidatorsList) {
      for (final SupportedPlatform supportedPlatform in validator.supportedPlatforms) {
        if (!allProjectValidatorsMap.containsKey(supportedPlatform)) {
          allProjectValidatorsMap[supportedPlatform] = <ProjectValidatorTask>[];
        }
        allProjectValidatorsMap[supportedPlatform]!.add(validator);
      }
    }
  }

  List<ProjectValidatorTask> getValidatorTasks(SupportedPlatform platform){
    if (allProjectValidatorsMap.containsKey(platform)) {
      return allProjectValidatorsMap[platform]!;
    } else {
      return [];
    }
  }
}

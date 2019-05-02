// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/platform_step.dart';
import 'package:flutter_tools/src/project.dart';

import 'src/common.dart';
import 'src/testbed.dart';

void main() {
  group(PlatformBuilders, () {
    Testbed testbed;

    setUp(() {
      testbed = Testbed();
    });

    test('Fails if more than one builder matches', () => testbed.run(() {
      const PlatformBuilders platformBuilders = PlatformBuilders(<PlatformBuildStep>[
        FakePlatformStep(
          buildModes: <BuildMode>{ BuildMode.debug, },
          targetPlatforms: <TargetPlatform>{ TargetPlatform.android_arm }
        ),
        FakePlatformStep(
          buildModes: <BuildMode>{ BuildMode.debug, },
          targetPlatforms: <TargetPlatform>{ TargetPlatform.android_arm }
        ),
      ]);
      const BuildInfo buildInfo = BuildInfo(
        BuildMode.debug,
        '',
        targetPlatform: TargetPlatform.android_arm,
      );

      expect(() => platformBuilders.selectPlatform(buildInfo: buildInfo), throwsA(isA<ToolExit>()));
    }));

    test('Fails if no builders match', () => testbed.run(() {
      const PlatformBuilders platformBuilders = PlatformBuilders(<PlatformBuildStep>[
        FakePlatformStep(
          buildModes: <BuildMode>{ BuildMode.debug, },
          targetPlatforms: <TargetPlatform>{ TargetPlatform.android_arm }
        ),
      ]);
      const BuildInfo buildInfo = BuildInfo(
        BuildMode.debug,
        '',
        targetPlatform: TargetPlatform.ios,
      );

      expect(() => platformBuilders.selectPlatform(buildInfo: buildInfo), throwsA(isA<ToolExit>()));
    }));

    test('Finds a matching step', () => testbed.run(() {
      const PlatformBuildStep iosStep = FakePlatformStep(
        buildModes: <BuildMode>{ BuildMode.debug, },
        targetPlatforms: <TargetPlatform>{ TargetPlatform.ios }
      );
      const PlatformBuilders platformBuilders = PlatformBuilders(<PlatformBuildStep>[
        FakePlatformStep(
          buildModes: <BuildMode>{ BuildMode.debug, },
          targetPlatforms: <TargetPlatform>{ TargetPlatform.android_arm }
        ),
        iosStep,
      ]);
      const BuildInfo buildInfo = BuildInfo(
        BuildMode.debug,
        '',
        targetPlatform: TargetPlatform.ios,
      );

      expect(platformBuilders.selectPlatform(buildInfo: buildInfo), iosStep);
    }));
  });
}

class FakePlatformStep extends PlatformBuildStep {
  const FakePlatformStep({
    this.buildModes,
    this.developmentArtifacts,
    this.targetPlatforms,
  });

  @override
  Future<void> build({FlutterProject project, BuildInfo buildInfo, String target}) {
    return null;
  }

  @override
  final Set<BuildMode> buildModes;

  @override
  final Set<DevelopmentArtifact> developmentArtifacts;

  @override
  final Set<TargetPlatform> targetPlatforms;
}

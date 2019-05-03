// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
          supported: <TargetPlatform, Set<BuildMode>>{
            TargetPlatform.android_arm: <BuildMode>{ BuildMode.debug, },
          }
        ),
        FakePlatformStep(
          supported: <TargetPlatform, Set<BuildMode>>{
            TargetPlatform.android_arm: <BuildMode>{ BuildMode.debug, },
          }
        ),
      ]);
      const BuildInfo buildInfo = BuildInfo(
        BuildMode.debug,
        '',
        targetPlatform: TargetPlatform.android_arm,
      );

      expect(() => platformBuilders.selectPlatform(buildInfo: buildInfo),
        throwsA(isA<AmbiguousPlatformBuilder>()));
    }));

    test('Fails if more than no builders match', () => testbed.run(() {
      const PlatformBuilders platformBuilders = PlatformBuilders(<PlatformBuildStep>[
        FakePlatformStep(
          supported: <TargetPlatform, Set<BuildMode>>{
            TargetPlatform.android_arm: <BuildMode>{ BuildMode.debug, }
          }
        ),
      ]);
      const BuildInfo buildInfo = BuildInfo(
        BuildMode.debug,
        '',
        targetPlatform: TargetPlatform.ios,
      );

      expect(() => platformBuilders.selectPlatform(buildInfo: buildInfo),
        throwsA(isA<MissingPlatformBuilder>()));
    }));

    test('Finds a matching step', () => testbed.run(() {
      const PlatformBuildStep iosStep = FakePlatformStep(
        supported: <TargetPlatform, Set<BuildMode>>{
          TargetPlatform.ios: <BuildMode>{ BuildMode.debug },
        }
      );
      const PlatformBuilders platformBuilders = PlatformBuilders(<PlatformBuildStep>[
        FakePlatformStep(
          supported: <TargetPlatform, Set<BuildMode>>{
            TargetPlatform.android_arm: <BuildMode>{ BuildMode.debug },
          }
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
    this.supported,
    this.developmentArtifacts,
  });

  @override
  Future<void> build({FlutterProject project, BuildInfo buildInfo, String target}) {
    return null;
  }

  @override
  final Set<DevelopmentArtifact> developmentArtifacts;

  @override
  final Map<TargetPlatform, Set<BuildMode>> supported;
}

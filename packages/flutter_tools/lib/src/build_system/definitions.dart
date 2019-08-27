// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'groups.dart';
import 'targets/assets.dart';
import 'targets/macos.dart';

/// All currently available build definitions.
final Map<String, BuildDefinition> kAllBuildDefinitions = <String, BuildDefinition>{
  debugMacOSApplication.name: debugMacOSApplication,
  profileMacOSApplication.name: profileMacOSApplication,
  releaseMacOSApplication.name: releaseMacOSApplication,
};

const String kMacOSOutput = '{PROJECT_DIR}/macos/Flutter/ephemeral/App.framework/Versions/A/Resources/flutter_assets';

/// The build definition for a debug macOS application.
const BuildDefinition debugMacOSApplication = BuildDefinition(
  name: 'debug_macos_application',
  groups: <TargetGroup>[
    AssetsBuildPhase(outputPrefix: kMacOSOutput),
    TargetGroup.static(
      name: 'macos',
      target: DebugMacOSBundleFlutterAssets(),
      dependencies: <String>[],
    ),
  ],
);

/// The build definition for a profile macOS application.
const BuildDefinition profileMacOSApplication = BuildDefinition(
  name: 'profile_macos_application',
  groups: <TargetGroup>[
    AssetsBuildPhase(outputPrefix: kMacOSOutput),
    TargetGroup.static(
      name: 'macos',
      target: ProfileMacOSBundleFlutterAssets(),
      dependencies: <String>[],
    ),
  ],
);

/// The build definition for a release macOS application.
const BuildDefinition releaseMacOSApplication = BuildDefinition(
  name: 'release_macos_application',
  groups: <TargetGroup>[
    AssetsBuildPhase(outputPrefix: kMacOSOutput),
    TargetGroup.static(
      name: 'macos',
      target: ReleaseMacOSBundleFlutterAssets(),
      dependencies: <String>[],
    ),
  ],
);

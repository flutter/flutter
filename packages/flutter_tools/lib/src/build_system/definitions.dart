// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'phases.dart';
import 'targets/assets.dart';
import 'targets/macos.dart';

/// All currently available build definitions.
const List<BuildDefinition> kAllBuildDefinitions = <BuildDefinition>[
  debugMacOSApplication,
  profileMacOSApplication,
  releaseMacOSApplication,
];

/// The build definition for a debug macOS application.
const BuildDefinition debugMacOSApplication = BuildDefinition(
  name: 'debug_macos_application',
  phases: <BuildPhase>[
    AssetsBuildPhase(),
    BuildPhase.static(
      name: 'unpack',
      target: UnpackMacOS(),
      dependencies: <String>[]
    ),
    BuildPhase.static(
      name: 'dart',
      target: CopyKernelDill(),
      dependencies: <String>[]
    ),
  ],
);

/// The build definition for a profile macOS application.
const BuildDefinition profileMacOSApplication = BuildDefinition(
  name: 'profile_macos_application',
  phases: <BuildPhase>[
    AssetsBuildPhase(),
    BuildPhase.static(
      name: 'unpack',
      target: UnpackMacOS(),
      dependencies: <String>[]
    ),
    BuildPhase.static(
      name: 'dart',
      target: CopyKernelDill(),
      dependencies: <String>[]
    ),
  ],
);

/// The build definition for a release macOS application.
const BuildDefinition releaseMacOSApplication = BuildDefinition(
  name: 'release_macos_application',
  phases: <BuildPhase>[
    AssetsBuildPhase(),
    BuildPhase.static(
      name: 'unpack',
      target: UnpackMacOS(),
      dependencies: <String>[]
    ),
    BuildPhase.static(
      name: 'dart',
      target: CopyKernelDill(),
      dependencies: <String>[]
    ),
  ],
);

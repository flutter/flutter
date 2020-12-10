// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/context.dart';
import '../base/platform.dart';
import '../doctor.dart';
import '../features.dart';
import 'fuchsia_sdk.dart';

/// The [FuchsiaWorkflow] instance.
FuchsiaWorkflow get fuchsiaWorkflow => context.get<FuchsiaWorkflow>();

/// The Fuchsia-specific implementation of a [Workflow].
///
/// This workflow assumes development within the fuchsia source tree,
/// including a working fx command-line tool in the user's PATH.
class FuchsiaWorkflow implements Workflow {
  FuchsiaWorkflow({
    @required Platform platform,
    @required FeatureFlags featureFlags,
    @required FuchsiaArtifacts fuchsiaArtifacts,
  }) : _platform = platform,
       _featureFlags = featureFlags,
       _fuchsiaArtifacts = fuchsiaArtifacts;

  final Platform _platform;
  final FeatureFlags _featureFlags;
  final FuchsiaArtifacts _fuchsiaArtifacts;

  @override
  bool get appliesToHostPlatform => _featureFlags.isFuchsiaEnabled && (_platform.isLinux || _platform.isMacOS);

  @override
  bool get canListDevices {
    return _fuchsiaArtifacts.devFinder != null;
  }

  @override
  bool get canLaunchDevices {
    return _fuchsiaArtifacts.devFinder != null && _fuchsiaArtifacts.sshConfig != null;
  }

  @override
  bool get canListEmulators => false;
}

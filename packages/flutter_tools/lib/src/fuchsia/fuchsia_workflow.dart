// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:meta/meta.dart';

import '../base/context.dart';
import '../base/platform.dart';
import '../doctor_validator.dart';
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

  bool get shouldUseDeviceFinder {
    final String useDeviceFinder = _platform.environment.containsKey('FUCHSIA_DISABLED_ffx_discovery')
      ? _platform.environment['FUCHSIA_DISABLED_ffx_discovery'] : '0';
    if (useDeviceFinder == '1') {
      return true;
    }
    return false;
  }

  @override
  bool get canListDevices {
    if (shouldUseDeviceFinder) {
      return _fuchsiaArtifacts.devFinder != null;
    }
    return _fuchsiaArtifacts.ffx != null;
  }

  @override
  bool get canLaunchDevices {
    if (shouldUseDeviceFinder) {
      return _fuchsiaArtifacts.devFinder != null && _fuchsiaArtifacts.sshConfig != null;
    }
    return _fuchsiaArtifacts.ffx != null && _fuchsiaArtifacts.sshConfig != null;
  }

  @override
  bool get canListEmulators => false;
}

// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../base/platform.dart';
import '../doctor.dart';
import '../globals.dart';

/// The [FuchsiaWorkflow] instance.
FuchsiaWorkflow get fuchsiaWorkflow => context[FuchsiaWorkflow];

/// The Fuchsia-specific implementation of a [Workflow].
///
/// This currently only supports Linux externally.
class FuchsiaWorkflow implements Workflow {

  @override
  bool get appliesToHostPlatform => platform.isLinux;

  @override
  bool get canListDevices {
    return cache.getArtifactDirectory('fuchsia').existsSync();
  }

  @override
  bool get canLaunchDevices {
    return cache.getArtifactDirectory('fuchsia').existsSync();
  }

  @override
  bool get canListEmulators => false;
}

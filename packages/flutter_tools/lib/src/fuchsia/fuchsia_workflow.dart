// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../doctor.dart';
import '../globals.dart' as globals;

/// The [FuchsiaWorkflow] instance.
FuchsiaWorkflow get fuchsiaWorkflow => context.get<FuchsiaWorkflow>();

/// The Fuchsia-specific implementation of a [Workflow].
///
/// This workflow assumes development within the fuchsia source tree,
/// including a working fx command-line tool in the user's PATH.
class FuchsiaWorkflow implements Workflow {

  @override
  bool get appliesToHostPlatform => globals.platform.isLinux || globals.platform.isMacOS;

  @override
  bool get canListDevices {
    return globals.fuchsiaArtifacts.devFinder != null;
  }

  @override
  bool get canLaunchDevices {
    return globals.fuchsiaArtifacts.devFinder != null && globals.fuchsiaArtifacts.sshConfig != null;
  }

  @override
  bool get canListEmulators => false;
}

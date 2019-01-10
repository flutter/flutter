// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../doctor.dart';

/// The [FuchsiaWorkflow] instance.
FuchsiaWorkflow get fuchsiaWorkflow => context[FuchsiaWorkflow];

/// The Fuchsia-specific implementation of a [Workflow].
///
/// This workflow assumes development within the fuchsia source tree,
/// including a working fx command-line tool in the user's PATH.
class FuchsiaWorkflow implements Workflow {

  @override
  bool get appliesToHostPlatform => platform.isLinux || platform.isMacOS;

  @override
  bool get canListDevices {
    return os.which('fx') != null;
  }

  @override
  bool get canLaunchDevices {
    return os.which('fx') != null;
  }

  @override
  bool get canListEmulators => false;
}

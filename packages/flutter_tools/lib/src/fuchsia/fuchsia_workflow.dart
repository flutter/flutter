// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../base/os.dart';
import '../doctor.dart';

/// The workflow for fuchsia development.
FuchsiaWorkflow get fuchsiaWorkflow => context[FuchsiaWorkflow];

/// The Fuchsia-specific implementation of a [Workflow].
///
/// This workflow assumes development within the fuchsia source tree, providing
/// the `fx` command-line tool.
class FuchsiaWorkflow implements Workflow {
  @override
  bool get appliesToHostPlatform => true;

  @override
  bool get canListDevices {
    return os.which('fx')?.path != null;
  }

  @override
  bool get canLaunchDevices {
    return os.which('fx')?.path != null;
  }

  @override
  bool get canListEmulators  {
     return false;
  }
}

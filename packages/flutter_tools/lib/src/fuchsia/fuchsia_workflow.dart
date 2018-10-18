// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../doctor.dart';

/// The workflow for fuchsia development.
FuchsiaWorkflow get fuchsiaWorkflow => context[FuchsiaWorkflow];

/// The Fuchsia-specific implementation of a [Workflow].
class FuchsiaWorkflow implements Workflow {
  @override
  bool get appliesToHostPlatform => true;

  @override
  bool get canListDevices {
    return true;
  }

  @override
  bool get canLaunchDevices {
    return true;
  }

  @override
  bool get canListEmulators  {
     return false;
  }
}
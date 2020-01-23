// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../doctor.dart';
import '../features.dart';
import '../globals.dart' as globals;

/// The [MacOSWorkflow] instance.
MacOSWorkflow get macOSWorkflow => context.get<MacOSWorkflow>();

/// The macOS-specific implementation of a [Workflow].
///
/// This workflow requires the flutter-desktop-embedding as a sibling
/// repository to the flutter repo.
class MacOSWorkflow implements Workflow {
  const MacOSWorkflow();

  @override
  bool get appliesToHostPlatform => globals.platform.isMacOS && featureFlags.isMacOSEnabled;

  @override
  bool get canLaunchDevices => globals.platform.isMacOS && featureFlags.isMacOSEnabled;

  @override
  bool get canListDevices => globals.platform.isMacOS && featureFlags.isMacOSEnabled;

  @override
  bool get canListEmulators => false;
}

// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../base/platform.dart';
import '../desktop.dart';
import '../doctor.dart';

/// The [MacOSWorkflow] instance.
MacOSWorkflow get macOSWorkflow => context.get<MacOSWorkflow>();

/// The macOS-specific implementation of a [Workflow].
///
/// This workflow requires the flutter-desktop-embedding as a sibling
/// repository to the flutter repo.
class MacOSWorkflow implements Workflow {
  const MacOSWorkflow();

  @override
  bool get appliesToHostPlatform => platform.isMacOS;

  @override
  bool get canLaunchDevices => flutterDesktopEnabled;

  @override
  bool get canListDevices => flutterDesktopEnabled;

  @override
  bool get canListEmulators => false;
}

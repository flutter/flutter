// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../doctor.dart';
import '../features.dart';
import '../globals.dart' as globals;

/// The [WindowsWorkflow] instance.
WindowsWorkflow get windowsWorkflow => context.get<WindowsWorkflow>();

/// The windows-specific implementation of a [Workflow].
///
/// This workflow requires the flutter-desktop-embedding as a sibling
/// repository to the flutter repo.
class WindowsWorkflow implements Workflow {
  const WindowsWorkflow();

  @override
  bool get appliesToHostPlatform => globals.platform.isWindows && featureFlags.isWindowsEnabled;

  @override
  bool get canLaunchDevices => globals.platform.isWindows && featureFlags.isWindowsEnabled;

  @override
  bool get canListDevices => globals.platform.isWindows && featureFlags.isWindowsEnabled;

  @override
  bool get canListEmulators => false;
}

// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../base/file_system.dart';
import '../base/platform.dart';
import '../cache.dart';
import '../doctor.dart';

/// The [MacOSWorkflow] instance.
MacOSWorkflow get macOSWorkflow => context[MacOSWorkflow];

// Only launch or display desktop embedding devices if there is a sibling
// FDE repository.
bool get _hasFlutterDesktopRepository {
  final Directory parent = fs.directory(Cache.flutterRoot).parent;
  return parent.childDirectory('flutter-desktop-embedding').existsSync();
}

/// The macos-specific implementation of a [Workflow].
///
/// This workflow requires the flutter-desktop-embedding as a sibling
/// repository to the flutter repo.
class MacOSWorkflow implements Workflow {
  const MacOSWorkflow();

  @override
  bool get appliesToHostPlatform => platform.isMacOS;

  @override
  bool get canLaunchDevices => _hasFlutterDesktopRepository;

  @override
  bool get canListDevices => _hasFlutterDesktopRepository;

  @override
  bool get canListEmulators => false;
}

// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../doctor.dart';
import '../features.dart';
import 'chrome.dart';

/// The  web workflow instance.
WebWorkflow get webWorkflow => context.get<WebWorkflow>();

class WebWorkflow extends Workflow {
  const WebWorkflow();

  @override
  bool get appliesToHostPlatform => featureFlags.isWebEnabled && (platform.isWindows || platform.isMacOS || platform.isLinux);

  @override
  bool get canLaunchDevices => featureFlags.isWebEnabled && canFindChrome();

  @override
  bool get canListDevices => featureFlags.isWebEnabled && canFindChrome();

  @override
  bool get canListEmulators => false;
}

/// Whether we can locate the chrome executable.
bool canFindChrome() {
  final String chrome = findChromeExecutable();
  try {
    return processManager.canRun(chrome);
  } on ArgumentError {
    return false;
  }
}

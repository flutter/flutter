// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../doctor.dart';
import '../version.dart';
import 'chrome.dart';

/// Only launch or display web devices if `FLUTTER_WEB`
/// environment variable is set to true.
bool get flutterWebEnabled {
  _flutterWebEnabled = platform.environment['FLUTTER_WEB']?.toLowerCase() == 'true';
  return _flutterWebEnabled && !FlutterVersion.instance.isStable;
}
bool _flutterWebEnabled;

/// The  web workflow instance.
WebWorkflow get webWorkflow => context.get<WebWorkflow>();

class WebWorkflow extends Workflow {
  const WebWorkflow();

  @override
  bool get appliesToHostPlatform => flutterWebEnabled && (platform.isWindows || platform.isMacOS || platform.isLinux);

  @override
  bool get canLaunchDevices => flutterWebEnabled && canFindChrome();

  @override
  bool get canListDevices => flutterWebEnabled && canFindChrome();

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

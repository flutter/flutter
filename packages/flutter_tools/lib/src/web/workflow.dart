// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../version.dart';
import 'chrome.dart';

@visibleForTesting
bool debugDisableWeb = false;

/// Only launch or display web devices if `FLUTTER_WEB`
/// environment variable is set to true from the daemon.
bool get flutterWebEnabled {
  if (debugDisableWeb) {
    return false;
  }
  if (isRunningFromDaemon) {
    final bool platformEnabled = platform
        .environment['FLUTTER_WEB']?.toLowerCase() == 'true';
    return platformEnabled && !FlutterVersion.instance.isStable;
  }
  return !FlutterVersion.instance.isStable;
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

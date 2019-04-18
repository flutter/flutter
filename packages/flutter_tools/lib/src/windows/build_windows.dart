// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file

import '../base/common.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process_manager.dart';
import '../build_info.dart';
import '../cache.dart';
import '../convert.dart';
import '../globals.dart';
import '../project.dart';

/// Builds the Windows project through the project bat script.
Future<void> buildWindows(WindowsProject windowsProject, BuildInfo buildInfo) async {
  final Process process = await processManager.start(<String>[
    windowsProject.buildScript.path,
    Cache.flutterRoot,
    buildInfo.isDebug ? 'debug' : 'release',
    buildInfo?.trackWidgetCreation == true ? 'track-widget-creation' : 'no-track-widget-creation',
  ], runInShell: true);
  final Status status = logger.startProgress(
    'Building Windows application...',
    timeout: null,
  );
  int result;
  try {
    process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(printError);
    process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(printTrace);
    result = await process.exitCode;
  } finally {
    status.cancel();
  }
  if (result != 0) {
    throwToolExit('Build process failed');
  }
}

// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/io.dart';
import '../base/process_manager.dart';
import '../build_info.dart';
import '../cache.dart';
import '../convert.dart';
import '../globals.dart';
import '../project.dart';

/// Builds the macOS project through the project shell script.
Future<void> buildMacOS(FlutterProject flutterProject, BuildInfo buildInfo) async {
  final Process process = await processManager.start(<String>[
    flutterProject.macos.buildScript.path,
    Cache.flutterRoot,
    buildInfo.isDebug ? 'debug' : 'release',
  ], runInShell: true);
  process.stderr
    .transform(utf8.decoder)
    .transform(const LineSplitter())
    .listen(printError);
  process.stdout
    .transform(utf8.decoder)
    .transform(const LineSplitter())
    .listen(printStatus);
  final int result = await process.exitCode;
  if (result != 0) {
    throwToolExit('Build process failed');
  }
}
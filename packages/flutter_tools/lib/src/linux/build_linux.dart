// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process_manager.dart';
import '../build_info.dart';
import '../cache.dart';
import '../convert.dart';
import '../globals.dart';
import '../project.dart';
import '../reporting/reporting.dart';

/// Builds the Linux project through the Makefile.
Future<void> buildLinux(LinuxProject linuxProject, BuildInfo buildInfo, {String target = 'lib/main.dart'}) async {
  final String buildFlag = buildInfo?.isDebug == true ? 'debug' : 'release';
  final StringBuffer buffer = StringBuffer('''
# Generated code do not commit.
export FLUTTER_ROOT=${Cache.flutterRoot}
export BUILD=$buildFlag
export TRACK_WIDGET_CREATION=${buildInfo?.trackWidgetCreation == true}
export FLUTTER_TARGET=$target
export PROJECT_DIR=${linuxProject.project.directory.path}
''');
  if (artifacts is LocalEngineArtifacts) {
    final LocalEngineArtifacts localEngineArtifacts = artifacts;
    final String engineOutPath = localEngineArtifacts.engineOutPath;
    buffer.writeln('export FLUTTER_ENGINE=${fs.path.dirname(fs.path.dirname(engineOutPath))}');
    buffer.writeln('export LOCAL_ENGINE=${fs.path.basename(engineOutPath)}');
  }

  /// Cache flutter configuration files in the linux directory.
  linuxProject.cacheDirectory.childFile('generated_config')
    ..createSync(recursive: true)
    ..writeAsStringSync(buffer.toString());

  if (!buildInfo.isDebug) {
    const String warning = '🚧 ';
    printStatus(warning * 20);
    printStatus('Warning: Only debug is currently implemented for Linux. This is effectively a debug build.');
    printStatus('See https://github.com/flutter/flutter/issues/38478 for details and updates.');
    printStatus(warning * 20);
    printStatus('');
  }

  // Invoke make.
  final Stopwatch sw = Stopwatch()..start();
  final Process process = await processManager.start(<String>[
    'make',
    '-C',
    linuxProject.editableHostAppDirectory.path,
  ], runInShell: true);
  final Status status = logger.startProgress(
    'Building Linux application...',
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
  flutterUsage.sendTiming('build', 'make-linux', Duration(milliseconds: sw.elapsedMilliseconds));
}

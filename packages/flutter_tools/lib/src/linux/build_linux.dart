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

/// Builds the Linux project through the Makefile.
Future<void> buildLinux(LinuxProject linuxProject, BuildInfo buildInfo) async {
  /// Cache flutter root in linux directory.
  linuxProject.editableHostAppDirectory.childFile('.generated_flutter_root')
    ..createSync(recursive: true)
    ..writeAsStringSync(Cache.flutterRoot);

  final String cacheDirectory = artifacts.getEngineArtifactsPath(TargetPlatform.linux_x64);
  String stampContents;
  if (artifacts is LocalEngineArtifacts) {
    // If we're working with a local engine, output the libflutter_linux.so timestamp
    // into a file that can be used as a stamp for make.
    stampContents = fs.statSync(fs.path.join(cacheDirectory, 'libflutter_linux.so')).modified.toIso8601String();
  } else {
    // Otherwise we can use the engine stamp.
    stampContents = Cache.instance.getStampFileFor('linux-sdk').readAsStringSync();
  }
  linuxProject.editableHostAppDirectory.childFile('.generated_engine_stamp')
    ..createSync()
    ..writeAsStringSync(stampContents);

  final String buildFlag = buildInfo?.isDebug == true ? 'debug' : 'release';
  final String bundleFlags = buildInfo?.trackWidgetCreation == true ? '--track-widget-creation' : '';
  // String engineVersionFile
  // final String engineVersionFile = Cache.flutterRoot
  final Process process = await processManager.start(<String>[
    'make',
    '-C',
    linuxProject.editableHostAppDirectory.path,
    'BUILD=$buildFlag',
    'FLUTTER_ROOT=${Cache.flutterRoot}',
    'FLUTTER_BUNDLE_FLAGS=$bundleFlags',
    'FLUTTER_ARTIFACT_CACHE_DIR=$cacheDirectory',
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
}

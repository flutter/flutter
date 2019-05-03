// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
Future<void> buildLinux(LinuxProject linuxProject, BuildInfo buildInfo, {String target = 'lib/main.dart'}) async {
  final Directory artifactDirectory = fs.directory(artifacts.getEngineArtifactsPath(TargetPlatform.linux_x64));
  final String buildFlag = buildInfo?.isDebug == true ? 'debug' : 'release';
  final String config = '''
# Generated code do not commit.
export FLTUTER_ROOT=${Cache.flutterRoot}
export FLUTTER_ARTIFACT_DIR=$artifactDirectory
export BUILD=$buildFlag
export TRACK_WIDGET_CREATION=${buildInfo?.trackWidgetCreation == true}
export FLUTTER_TARGET=$target
export PROJECT_DIR=${linuxProject.project.directory.path}
''';

  /// Cache flutter configuration files in the linux directory.
  linuxProject.cacheDirectory.childFile('generated_config')
    ..createSync(recursive: true)
    ..writeAsStringSync(config);

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
}

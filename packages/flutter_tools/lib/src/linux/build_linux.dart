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

// The name of the icu data file.
const String _kIcuDataName = 'icudtl.dat';

/// The name of the engine library.
const String _kLibraryName = 'libflutter_linux.so';

/// Builds the Linux project through the Makefile.
Future<void> buildLinux(LinuxProject linuxProject, BuildInfo buildInfo) async {
  /// Cache flutter root in linux directory.
  linuxProject.editableHostAppDirectory.childFile('.generated_flutter_root')
    ..createSync(recursive: true)
    ..writeAsStringSync(Cache.flutterRoot);
  final String buildFlag = buildInfo?.isDebug == true ? 'debug' : 'release';
  final Directory cacheDirectory = fs.directory(artifacts.getEngineArtifactsPath(TargetPlatform.linux_x64));
  final Directory buildDirectory = fs.directory(fs.path.join(getLinuxBuildDirectory(), 'cache', 'flutter_library'));
  final File icuData = fs.file(fs.path.join(cacheDirectory.path, _kIcuDataName));
  final File libraryFile = fs.file(fs.path.join(cacheDirectory.path, _kLibraryName));

  // Copy the source files and headers.
  copyDirectorySync(cacheDirectory, buildDirectory);

  // Copy the ICU data.
  final File icuDestination = fs.file(fs.path.join(getLinuxBuildDirectory(), buildFlag, 'data', _kIcuDataName));
  if (!icuDestination.existsSync()) {
    icuDestination.createSync(recursive: true);
  }
  icuData.copySync(icuDestination.path);

  // Copy the library file.
  final File libraryDestination = fs.file(fs.path.join(getLinuxBuildDirectory(), buildFlag, 'lib', _kLibraryName));
  if (!libraryDestination.existsSync()) {
    libraryDestination.createSync(recursive: true);
  }
  libraryFile.copySync(libraryDestination.path);


  final String bundleFlags = buildInfo?.trackWidgetCreation == true ? '--track-widget-creation' : '';
  final Process process = await processManager.start(<String>[
    'make',
    '-C',
    linuxProject.editableHostAppDirectory.path,
    'BUILD=$buildFlag',
    'FLUTTER_ROOT=${Cache.flutterRoot}',
    'FLUTTER_BUNDLE_FLAGS=$bundleFlags',
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

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import '../plugins.dart';
import '../project.dart';

/// Builds the Linux project through the Makefile.
Future<void> buildLinux(
  LinuxProject linuxProject,
  BuildInfo buildInfo, {
    String target = 'lib/main.dart',
  }) async {
  if (!linuxProject.makeFile.existsSync()) {
    throwToolExit('No Linux desktop project configured. See '
      'https://github.com/flutter/flutter/wiki/Desktop-shells#create '
      'to learn about adding Linux support to a project.');
  }

  // Check for incompatibility between the Flutter tool version and the project
  // template version, since the tempalte isn't stable yet.
  final int templateCompareResult = _compareTemplateVersions(linuxProject);
  if (templateCompareResult < 0) {
    throwToolExit('The Linux runner was created with an earlier version of the '
      'template, which is not yet stable.\n\n'
      'Delete the linux/ directory and re-run \'flutter create .\', '
      're-applying any previous changes.');
  } else if (templateCompareResult > 0) {
    throwToolExit('The Linux runner was created with a newer version of the '
      'template, which is not yet stable.\n\n'
      'Upgrade Flutter and try again.');
  }

  final StringBuffer buffer = StringBuffer('''
# Generated code do not commit.
export FLUTTER_ROOT=${Cache.flutterRoot}
export FLUTTER_TARGET=$target
export PROJECT_DIR=${linuxProject.project.directory.path}
''');
  final Map<String, String> environmentConfig = buildInfo.toEnvironmentConfig();
  for (final String key in environmentConfig.keys) {
    final String value = environmentConfig[key];
    buffer.writeln('export $key=$value');
  }

  if (globals.artifacts is LocalEngineArtifacts) {
    final LocalEngineArtifacts localEngineArtifacts = globals.artifacts as LocalEngineArtifacts;
    final String engineOutPath = localEngineArtifacts.engineOutPath;
    buffer.writeln('export FLUTTER_ENGINE=${globals.fs.path.dirname(globals.fs.path.dirname(engineOutPath))}');
    buffer.writeln('export LOCAL_ENGINE=${globals.fs.path.basename(engineOutPath)}');
  }

  /// Cache flutter configuration files in the linux directory.
  linuxProject.generatedMakeConfigFile
    ..createSync(recursive: true)
    ..writeAsStringSync(buffer.toString());
  createPluginSymlinks(linuxProject.project);

  if (!buildInfo.isDebug) {
    const String warning = '🚧 ';
    globals.printStatus(warning * 20);
    globals.printStatus('Warning: Only debug is currently implemented for Linux. This is effectively a debug build.');
    globals.printStatus('See https://github.com/flutter/flutter/issues/38478 for details and updates.');
    globals.printStatus(warning * 20);
    globals.printStatus('');
  }

  // Invoke make.
  final String buildFlag = getNameForBuildMode(buildInfo.mode ?? BuildMode.release);
  final Stopwatch sw = Stopwatch()..start();
  final Status status = globals.logger.startProgress(
    'Building Linux application...',
    timeout: null,
  );
  int result;
  try {
    result = await processUtils.stream(
      <String>[
        'make',
        '-C',
        linuxProject.makeFile.parent.path,
        'BUILD=$buildFlag',
      ],
      environment: <String, String>{
        if (globals.logger.isVerbose)
          'VERBOSE_SCRIPT_LOGGING': 'true'
      }, trace: true,
    );
  } on ArgumentError {
    throwToolExit("make not found. Run 'flutter doctor' for more information.");
  } finally {
    status.cancel();
  }
  if (result != 0) {
    throwToolExit('Build process failed');
  }
  globals.flutterUsage.sendTiming('build', 'make-linux', Duration(milliseconds: sw.elapsedMilliseconds));
}

// Checks the template version of [project] against the current template
// version. Returns < 0 if the project is older than the current template, > 0
// if it's newer, and 0 if they match.
int _compareTemplateVersions(LinuxProject project) {
  const String projectVersionBasename = '.template_version';
  final int expectedVersion = int.parse(globals.fs.file(globals.fs.path.join(
    globals.fs.path.absolute(Cache.flutterRoot),
    'packages',
    'flutter_tools',
    'templates',
    'app',
    'linux.tmpl',
    'flutter',
    projectVersionBasename,
  )).readAsStringSync());
  final File projectVersionFile = project.managedDirectory.childFile(projectVersionBasename);
  final int version = projectVersionFile.existsSync()
      ? int.tryParse(projectVersionFile.readAsStringSync())
      : 0;
  return version.compareTo(expectedVersion);
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/fingerprint.dart';
import '../build_info.dart';
import '../cache.dart';
import '../flutter_plugins.dart';
import '../globals_null_migrated.dart' as globals;
import '../project.dart';

/// For a given build, determines whether dependencies have changed since the
/// last call to processPods, then calls processPods with that information.
Future<void> processPodsIfNeeded(
  XcodeBasedProject xcodeProject,
  String buildDirectory,
  BuildMode buildMode) async {
  final FlutterProject project = xcodeProject.parent;
  // Ensure that the plugin list is up to date, since hasPlugins relies on it.
  await refreshPluginsList(project, macOSPlatform: project.macos.existsSync());
  if (!(hasPlugins(project) || (project.isModule && xcodeProject.podfile.existsSync()))) {
    return;
  }
  // If the Xcode project, Podfile, or generated xcconfig have changed since
  // last run, pods should be updated.
  final Fingerprinter fingerprinter = Fingerprinter(
    fingerprintPath: globals.fs.path.join(buildDirectory, 'pod_inputs.fingerprint'),
    paths: <String>[
      xcodeProject.xcodeProjectInfoFile.path,
      xcodeProject.podfile.path,
      xcodeProject.generatedXcodePropertiesFile.path,
      globals.fs.path.join(
        Cache.flutterRoot!,
        'packages',
        'flutter_tools',
        'bin',
        'podhelper.rb',
      ),
    ],
    fileSystem: globals.fs,
    logger: globals.logger,
  );

  final bool didPodInstall = await globals.cocoaPods?.processPods(
    xcodeProject: xcodeProject,
    buildMode: buildMode,
    dependenciesChanged: !fingerprinter.doesFingerprintMatch(),
  ) == true;
  if (didPodInstall) {
    fingerprinter.writeFingerprint();
  }
}

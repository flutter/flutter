// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/file_system.dart';
import '../base/fingerprint.dart';
import '../build_info.dart';
import '../ios/xcodeproj.dart';
import '../plugins.dart';
import '../project.dart';
import 'cocoapods.dart';

/// For a given build, determines whether dependencies have changed since the
/// last call to processPods, then calls processPods with that information.
Future<void> processPodsIfNeeded(XcodeBasedProject xcodeProject,
    String buildDirectory, BuildMode buildMode) async {
  final FlutterProject project = xcodeProject.parent;
  // Ensure that the plugin list is up to date, since hasPlugins relies on it.
  refreshPluginsList(project);
  if (!(hasPlugins(project) || (project.isModule && xcodeProject.podfile.existsSync()))) {
    return;
  }
  // If the Xcode project, Podfile, or generated xcconfig have changed since
  // last run, pods should be updated.
  final Fingerprinter fingerprinter = Fingerprinter(
    fingerprintPath: fs.path.join(buildDirectory, 'pod_inputs.fingerprint'),
    paths: <String>[
      xcodeProject.xcodeProjectInfoFile.path,
      xcodeProject.podfile.path,
      xcodeProject.generatedXcodePropertiesFile.path,
    ],
    properties: <String, String>{},
  );

  final bool didPodInstall = await cocoaPods.processPods(
    xcodeProject: xcodeProject,
    engineDir: flutterFrameworkDir(buildMode),
    isSwift: xcodeProject.isSwift,
    dependenciesChanged: !fingerprinter.doesFingerprintMatch(),
  );
  if (didPodInstall) {
    fingerprinter.writeFingerprint();
  }
}

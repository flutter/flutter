// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/config.dart';
import '../base/file_system.dart';
import '../base/fingerprint.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../base/template.dart';
import '../build_info.dart';
import '../cache.dart';
import '../darwin/darwin.dart';
import '../flutter_plugins.dart';
import '../plugins.dart';
import '../project.dart';
import 'cocoapods.dart';
import 'swift_package_manager.dart';

/// For a given build, determines whether dependencies have changed since the
/// last call to processPods, then calls processPods with that information.
Future<void> processPodsIfNeeded(
  XcodeBasedProject xcodeProject,
  String buildDirectory,
  BuildMode buildMode, {
  required CocoaPods? cocoaPods,
  required Config config,
  required FileSystem fileSystem,
  required Logger logger,
  required ProcessUtils processUtils,
  required TemplateRenderer templateRenderer,
  bool forceCocoaPodsOnly = false,
  bool forceSwiftPM = false,
}) async {
  final FlutterProject project = xcodeProject.parent;

  // When using Swift Package Manager, the Podfile may not exist so if there
  // isn't a Podfile, skip processing pods.
  if (xcodeProject.usesSwiftPackageManager &&
      !xcodeProject.podfile.existsSync() &&
      !forceCocoaPodsOnly) {
    return;
  }
  // Ensure that the plugin list is up to date, since hasPlugins relies on it.
  await refreshPluginsList(
    project,
    iosPlatform: project.ios.existsSync(),
    macOSPlatform: project.macos.existsSync(),
    forceCocoaPodsOnly: forceCocoaPodsOnly,
    forceSwiftPM: forceSwiftPM,
  );

  // If there are no plugins and if the project is a not module with an existing
  // podfile, skip processing pods
  if (!hasPlugins(project) && !(project.isModule && xcodeProject.podfile.existsSync())) {
    return;
  }

  // If forcing the use of only CocoaPods, but the project is using Swift
  // Package Manager, print a warning that CocoaPods will be used.
  if (forceCocoaPodsOnly && xcodeProject.usesSwiftPackageManager) {
    logger.printWarning(
      'Swift Package Manager does not yet support this command. '
      'CocoaPods will be used instead.',
    );

    // If CocoaPods has been deintegrated, add it back.
    if (!xcodeProject.podfile.existsSync()) {
      await cocoaPods?.setupPodfile(xcodeProject);
    }

    // Generate an empty Swift Package Manager manifest to invalidate fingerprinter
    final swiftPackageManager = SwiftPackageManager(
      fileSystem: fileSystem,
      templateRenderer: templateRenderer,
      processUtils: processUtils,
      config: config,
      logger: logger,
    );
    final FlutterDarwinPlatform platform = xcodeProject is IosProject
        ? FlutterDarwinPlatform.ios
        : FlutterDarwinPlatform.macos;

    await swiftPackageManager.generatePluginsSwiftPackage(
      const <Plugin>[],
      platform,
      xcodeProject,
      flutterAsADependency: false,
    );
  }

  // If the Xcode project, Podfile, generated plugin Swift Package, or podhelper
  // have changed since last run, pods should be updated.
  final fingerprinter = Fingerprinter(
    fingerprintPath: fileSystem.path.join(buildDirectory, 'pod_inputs.fingerprint'),
    paths: <String>[
      xcodeProject.xcodeProjectInfoFile.path,
      xcodeProject.podfile.path,
      if (xcodeProject.flutterPluginSwiftPackageManifest.existsSync())
        xcodeProject.flutterPluginSwiftPackageManifest.path,
      fileSystem.path.join(Cache.flutterRoot!, 'packages', 'flutter_tools', 'bin', 'podhelper.rb'),
    ],
    fileSystem: fileSystem,
    logger: logger,
  );

  final bool didPodInstall =
      await cocoaPods?.processPods(
        xcodeProject: xcodeProject,
        buildMode: buildMode,
        dependenciesChanged: !fingerprinter.doesFingerprintMatch(),
      ) ??
      false;
  if (didPodInstall) {
    fingerprinter.writeFingerprint();
  }
}

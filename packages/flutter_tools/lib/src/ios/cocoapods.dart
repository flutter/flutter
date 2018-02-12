// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../base/process_manager.dart';
import '../base/version.dart';
import '../cache.dart';
import '../globals.dart';
import 'xcodeproj.dart';

const String noCocoaPodsConsequence = '''
  CocoaPods is used to retrieve the iOS platform side's plugin code that responds to your plugin usage on the Dart side.
  Without resolving iOS dependencies with CocoaPods, plugins will not work on iOS.
  For more info, see https://flutter.io/platform-plugins''';

const String cocoaPodsInstallInstructions = '''
  brew install cocoapods
  pod setup''';

const String cocoaPodsUpgradeInstructions = '''
  brew upgrade cocoapods
  pod setup''';

CocoaPods get cocoaPods => context.putIfAbsent(CocoaPods, () => const CocoaPods());

class CocoaPods {
  const CocoaPods();

  Future<bool> get hasCocoaPods => exitsHappyAsync(<String>['pod', '--version']);

  String get cocoaPodsMinimumVersion => '1.0.0';

  Future<String> get cocoaPodsVersionText async => (await runAsync(<String>['pod', '--version'])).processResult.stdout.trim();

  Future<bool> get isCocoaPodsInstalledAndMeetsVersionCheck async {
    if (!await hasCocoaPods)
      return false;
    try {
      final Version installedVersion = new Version.parse(await cocoaPodsVersionText);
      return installedVersion >= new Version.parse(cocoaPodsMinimumVersion);
    } on FormatException {
      return false;
    }
  }

  /// Whether CocoaPods ran 'pod setup' once where the costly pods' specs are cloned.
  Future<bool> get isCocoaPodsInitialized => fs.isDirectory(fs.path.join(homeDirPath, '.cocoapods', 'repos', 'master'));

  Future<Null> processPods({
    @required Directory appIosDir,
    // For backward compatibility with previously created Podfile only.
    @required String iosEngineDir,
    bool isSwift: false,
    bool flutterPodChanged: true,
  }) async {
    if (await _checkPodCondition()) {
      if (_shouldRunPodInstall(appIosDir.path, flutterPodChanged))
        await _runPodInstall(appIosDir, iosEngineDir);
    }
  }

  /// Make sure the CocoaPods tools are in the right states.
  Future<bool> _checkPodCondition() async {
    if (!await isCocoaPodsInstalledAndMeetsVersionCheck) {
      final String minimumVersion = cocoaPodsMinimumVersion;
      printError(
        'Warning: CocoaPods version $minimumVersion or greater not installed. Skipping pod install.\n'
        '$noCocoaPodsConsequence\n'
        'To install:\n'
        '$cocoaPodsInstallInstructions\n',
        emphasis: true,
      );
      return false;
    }
    if (!await isCocoaPodsInitialized) {
      printError(
        'Warning: CocoaPods installed but not initialized. Skipping pod install.\n'
        '$noCocoaPodsConsequence\n'
        'To initialize CocoaPods, run:\n'
        '  pod setup\n'
        'once to finalize CocoaPods\' installation.',
        emphasis: true,
      );
      return false;
    }

    return true;
  }

  /// Creates a default `Podfile` in the Flutter project at [directory],
  /// unless one already exists at `ios/Podfile`.
  Future<Null> createPodfileIfMissing(String directory) async {
    final String iosPath = fs.path.join(directory, 'ios');
    final String podfilePath = fs.path.join(iosPath, 'Podfile');
    if (fs.file(podfilePath).existsSync()) {
      return;
    }
    final bool isSwift = getXcodeBuildSettings(
      fs.path.join(iosPath, 'Runner.xcodeproj'),
      'Runner',
    ).containsKey('SWIFT_VERSION');
    final File podfileTemplate = fs.file(fs.path.join(
      Cache.flutterRoot,
      'packages',
      'flutter_tools',
      'templates',
      'cocoapods',
      isSwift ? 'Podfile-swift' : 'Podfile-objc',
    ));
    podfileTemplate.copySync(podfilePath);
    await _addPodsDependencyToFlutterXcconfig(directory, 'Debug');
    await _addPodsDependencyToFlutterXcconfig(directory, 'Release');
  }

  Future<Null> _addPodsDependencyToFlutterXcconfig(String directory, String mode) async {
    final File file = fs.file(fs.path.join(directory, 'ios', 'Flutter', '$mode.xcconfig'));
    if (await file.exists()) {
      final String content = await file.readAsString();
      final String include = '#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.${mode
          .toLowerCase()}.xcconfig"';
      if (!content.contains(include)) {
        await file.writeAsString('$include\n$content');
      }
    }
  }

  // Check if you need to run pod install.
  // The pod install will run if any of below is true.
  // 1. The flutter.framework has changed (debug/release/profile)
  // 2. The podfile.lock doesn't exist
  // 3. The Pods/Manifest.lock doesn't exist (It is deleted when plugins change)
  // 4. The podfile.lock doesn't match Pods/Manifest.lock.
  bool _shouldRunPodInstall(String appDir, bool flutterPodChanged) {
    if (flutterPodChanged)
      return true;
    // Check if podfile.lock and Pods/Manifest.lock exist and match.
    final File podfileLockFile = fs.file(fs.path.join(appDir, 'Podfile.lock'));
    final File manifestLockFile = fs.file(fs.path.join(appDir, 'Pods', 'Manifest.lock'));
    return !podfileLockFile.existsSync()
        || !manifestLockFile.existsSync()
        || podfileLockFile.readAsStringSync() != manifestLockFile.readAsStringSync();
  }

  Future<Null> _runPodInstall(Directory bundle, String engineDirectory) async {
    final Status status = logger.startProgress('Running pod install...', expectSlowOperation: true);
    final ProcessResult result = await processManager.run(
      <String>['pod', 'install', '--verbose'],
      workingDirectory: bundle.path,
      environment: <String, String>{
        // For backward compatibility with previously created Podfile only.
        'FLUTTER_FRAMEWORK_DIR': engineDirectory,
        // See https://github.com/flutter/flutter/issues/10873.
        // CocoaPods analytics adds a lot of latency.
        'COCOAPODS_DISABLE_STATS': 'true',
      },
    );
    status.stop();
    if (logger.isVerbose || result.exitCode != 0) {
      if (result.stdout.isNotEmpty) {
        printStatus('CocoaPods\' output:\n↳');
        printStatus(result.stdout, indent: 4);
      }
      if (result.stderr.isNotEmpty) {
        printStatus('Error output from CocoaPods:\n↳');
        printStatus(result.stderr, indent: 4);
      }
    }
    if (result.exitCode != 0) {
      _diagnosePodInstallFailure(result);
      throwToolExit('Error running pod install');
    }
  }

  void _diagnosePodInstallFailure(ProcessResult result) {
    if (result.stdout is String && result.stdout.contains('out-of-date source repos')) {
      printError(
        "Error: CocoaPods's specs repository is too out-of-date to satisfy dependencies.\n"
        'To update the CocoaPods specs, run:\n'
        '  pod repo update\n',
        emphasis: true,
      );
    }
  }
}

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
import '../base/platform.dart';
import '../base/process.dart';
import '../base/process_manager.dart';
import '../base/version.dart';
import '../cache.dart';
import '../globals.dart';
import '../project.dart';
import 'xcodeproj.dart';

const String noCocoaPodsConsequence = '''
  CocoaPods is used to retrieve the iOS platform side's plugin code that responds to your plugin usage on the Dart side.
  Without resolving iOS dependencies with CocoaPods, plugins will not work on iOS.
  For more info, see https://flutter.dev/platform-plugins''';

const String unknownCocoaPodsConsequence = '''
  Flutter is unable to determine the installed CocoaPods's version.
  Ensure that the output of 'pod --version' contains only digits and . to be recognized by Flutter.''';

const String cocoaPodsInstallInstructions = '''
  brew install cocoapods
  pod setup''';

const String cocoaPodsUpgradeInstructions = '''
  brew upgrade cocoapods
  pod setup''';

CocoaPods get cocoaPods => context[CocoaPods];

/// Result of evaluating the CocoaPods installation.
enum CocoaPodsStatus {
  /// iOS plugins will not work, installation required.
  notInstalled,
  /// iOS plugins might not work, upgrade recommended.
  unknownVersion,
  /// iOS plugins will not work, upgrade required.
  belowMinimumVersion,
  /// iOS plugins may not work in certain situations (Swift, static libraries),
  /// upgrade recommended.
  belowRecommendedVersion,
  /// Everything should be fine.
  recommended,
}

class CocoaPods {
  Future<String> _versionText;

  String get cocoaPodsMinimumVersion => '1.0.0';
  String get cocoaPodsRecommendedVersion => '1.5.0';

  Future<String> get cocoaPodsVersionText {
    _versionText ??= runAsync(<String>['pod', '--version']).then<String>((RunResult result) {
      return result.exitCode == 0 ? result.stdout.trim() : null;
    }, onError: (dynamic _) => null);
    return _versionText;
  }

  Future<CocoaPodsStatus> get evaluateCocoaPodsInstallation async {
    final String versionText = await cocoaPodsVersionText;
    if (versionText == null)
      return CocoaPodsStatus.notInstalled;
    try {
      final Version installedVersion = Version.parse(versionText);
      if (installedVersion == null)
        return CocoaPodsStatus.unknownVersion;
      if (installedVersion < Version.parse(cocoaPodsMinimumVersion))
        return CocoaPodsStatus.belowMinimumVersion;
      else if (installedVersion < Version.parse(cocoaPodsRecommendedVersion))
        return CocoaPodsStatus.belowRecommendedVersion;
      else
        return CocoaPodsStatus.recommended;
    } on FormatException {
      return CocoaPodsStatus.notInstalled;
    }
  }

  /// Whether CocoaPods ran 'pod setup' once where the costly pods' specs are
  /// cloned.
  ///
  /// A user can override the default location via the CP_REPOS_DIR environment
  /// variable.
  ///
  /// See https://github.com/CocoaPods/CocoaPods/blob/master/lib/cocoapods/config.rb#L138
  /// for details of this variable.
  Future<bool> get isCocoaPodsInitialized {
    final String cocoapodsReposDir = platform.environment['CP_REPOS_DIR'] ?? fs.path.join(homeDirPath, '.cocoapods', 'repos');
    return fs.isDirectory(fs.path.join(cocoapodsReposDir, 'master'));
  }

  Future<bool> processPods({
    @required IosProject iosProject,
    // For backward compatibility with previously created Podfile only.
    @required String iosEngineDir,
    bool isSwift = false,
    bool dependenciesChanged = true,
  }) async {
    if (!(await iosProject.podfile.exists())) {
      throwToolExit('Podfile missing');
    }
    if (await _checkPodCondition()) {
      if (_shouldRunPodInstall(iosProject, dependenciesChanged)) {
        await _runPodInstall(iosProject, iosEngineDir);
        return true;
      }
    }
    return false;
  }

  /// Make sure the CocoaPods tools are in the right states.
  Future<bool> _checkPodCondition() async {
    final CocoaPodsStatus installation = await evaluateCocoaPodsInstallation;
    switch (installation) {
      case CocoaPodsStatus.notInstalled:
        printError(
          'Warning: CocoaPods not installed. Skipping pod install.\n'
          '$noCocoaPodsConsequence\n'
          'To install:\n'
          '$cocoaPodsInstallInstructions\n',
          emphasis: true,
        );
        return false;
      case CocoaPodsStatus.unknownVersion:
        printError(
          'Warning: Unknown CocoaPods version installed.\n'
          '$unknownCocoaPodsConsequence\n'
          'To upgrade:\n'
          '$cocoaPodsUpgradeInstructions\n',
          emphasis: true,
        );
        break;
      case CocoaPodsStatus.belowMinimumVersion:
        printError(
          'Warning: CocoaPods minimum required version $cocoaPodsMinimumVersion or greater not installed. Skipping pod install.\n'
          '$noCocoaPodsConsequence\n'
          'To upgrade:\n'
          '$cocoaPodsUpgradeInstructions\n',
          emphasis: true,
        );
        return false;
      case CocoaPodsStatus.belowRecommendedVersion:
        printError(
          'Warning: CocoaPods recommended version $cocoaPodsRecommendedVersion or greater not installed.\n'
          'Pods handling may fail on some projects involving plugins.\n'
          'To upgrade:\n'
          '$cocoaPodsUpgradeInstructions\n',
          emphasis: true,
        );
        break;
      default:
        break;
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

  /// Ensures the given iOS sub-project of a parent Flutter project
  /// contains a suitable `Podfile` and that its `Flutter/Xxx.xcconfig` files
  /// include pods configuration.
  void setupPodfile(IosProject iosProject) {
    if (!xcodeProjectInterpreter.isInstalled) {
      // Don't do anything for iOS when host platform doesn't support it.
      return;
    }
    final Directory runnerProject = iosProject.xcodeProject;
    if (!runnerProject.existsSync()) {
      return;
    }
    final File podfile = iosProject.podfile;
    if (!podfile.existsSync()) {
      final bool isSwift = xcodeProjectInterpreter.getBuildSettings(
        runnerProject.path,
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
      podfileTemplate.copySync(podfile.path);
    }
    addPodsDependencyToFlutterXcconfig(iosProject);
  }

  /// Ensures all `Flutter/Xxx.xcconfig` files for the given iOS sub-project of
  /// a parent Flutter project include pods configuration.
  void addPodsDependencyToFlutterXcconfig(IosProject iosProject) {
    _addPodsDependencyToFlutterXcconfig(iosProject, 'Debug');
    _addPodsDependencyToFlutterXcconfig(iosProject, 'Release');
  }

  void _addPodsDependencyToFlutterXcconfig(IosProject iosProject, String mode) {
    final File file = iosProject.xcodeConfigFor(mode);
    if (file.existsSync()) {
      final String content = file.readAsStringSync();
      final String include = '#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.${mode
          .toLowerCase()}.xcconfig"';
      if (!content.contains(include))
        file.writeAsStringSync('$include\n$content', flush: true);
    }
  }

  /// Ensures that pod install is deemed needed on next check.
  void invalidatePodInstallOutput(IosProject iosProject) {
    final File manifestLock = iosProject.podManifestLock;
    if (manifestLock.existsSync()) {
      manifestLock.deleteSync();
    }
  }

  // Check if you need to run pod install.
  // The pod install will run if any of below is true.
  // 1. Flutter dependencies have changed
  // 2. Podfile.lock doesn't exist or is older than Podfile
  // 3. Pods/Manifest.lock doesn't exist (It is deleted when plugins change)
  // 4. Podfile.lock doesn't match Pods/Manifest.lock.
  bool _shouldRunPodInstall(IosProject iosProject, bool dependenciesChanged) {
    if (dependenciesChanged)
      return true;

    final File podfileFile = iosProject.podfile;
    final File podfileLockFile = iosProject.podfileLock;
    final File manifestLockFile = iosProject.podManifestLock;

    return !podfileLockFile.existsSync()
        || !manifestLockFile.existsSync()
        || podfileLockFile.statSync().modified.isBefore(podfileFile.statSync().modified)
        || podfileLockFile.readAsStringSync() != manifestLockFile.readAsStringSync();
  }

  Future<void> _runPodInstall(IosProject iosProject, String engineDirectory) async {
    final Status status = logger.startProgress('Running pod install...', timeout: timeoutConfiguration.slowOperation);
    final ProcessResult result = await processManager.run(
      <String>['pod', 'install', '--verbose'],
      workingDirectory: iosProject.hostAppRoot.path,
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
      invalidatePodInstallOutput(iosProject);
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

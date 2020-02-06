// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../base/version.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import '../ios/xcodeproj.dart';
import '../project.dart';

const String noCocoaPodsConsequence = '''
  CocoaPods is used to retrieve the iOS and macOS platform side's plugin code that responds to your plugin usage on the Dart side.
  Without CocoaPods, plugins will not work on iOS or macOS.
  For more info, see https://flutter.dev/platform-plugins''';

const String unknownCocoaPodsConsequence = '''
  Flutter is unable to determine the installed CocoaPods's version.
  Ensure that the output of 'pod --version' contains only digits and . to be recognized by Flutter.''';

const String brokenCocoaPodsConsequence = '''
  You appear to have CocoaPods installed but it is not working.
  This can happen if the version of Ruby that CocoaPods was installed with is different from the one being used to invoke it.
  This can usually be fixed by re-installing CocoaPods. For more info, see https://github.com/flutter/flutter/issues/14293.''';

const String outOfDatePodfileConsequence = '''
  This can cause a mismatched version of Flutter to be embedded in your app, which may result in App Store submission rejection or crashes.
  If you have local Podfile edits you would like to keep, see https://github.com/flutter/flutter/issues/24641 for instructions.''';

const String cocoaPodsInstallInstructions = '''
  sudo gem install cocoapods''';

const String cocoaPodsUpgradeInstructions = '''
  sudo gem install cocoapods''';

const String podfileMigrationInstructions = '''
  rm ios/Podfile''';

CocoaPods get cocoaPods => context.get<CocoaPods>();

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
  /// iOS plugins will not work, re-install required.
  brokenInstall,
}

class CocoaPods {
  Future<String> _versionText;

  String get cocoaPodsMinimumVersion => '1.6.0';
  String get cocoaPodsRecommendedVersion => '1.6.0';

  Future<bool> get isInstalled =>
      processUtils.exitsHappy(<String>['which', 'pod']);

  Future<String> get cocoaPodsVersionText {
    _versionText ??= processUtils.run(
      <String>['pod', '--version'],
      environment: <String, String>{
        'LANG': 'en_US.UTF-8',
      },
    ).then<String>((RunResult result) {
      return result.exitCode == 0 ? result.stdout.trim() : null;
    }, onError: (dynamic _) => null);
    return _versionText;
  }

  Future<CocoaPodsStatus> get evaluateCocoaPodsInstallation async {
    if (!(await isInstalled)) {
      return CocoaPodsStatus.notInstalled;
    }
    final String versionText = await cocoaPodsVersionText;
    if (versionText == null) {
      return CocoaPodsStatus.brokenInstall;
    }
    try {
      final Version installedVersion = Version.parse(versionText);
      if (installedVersion == null) {
        return CocoaPodsStatus.unknownVersion;
      }
      if (installedVersion < Version.parse(cocoaPodsMinimumVersion)) {
        return CocoaPodsStatus.belowMinimumVersion;
      }
      if (installedVersion < Version.parse(cocoaPodsRecommendedVersion)) {
        return CocoaPodsStatus.belowRecommendedVersion;
      }
      return CocoaPodsStatus.recommended;
    } on FormatException {
      return CocoaPodsStatus.notInstalled;
    }
  }

  /// Whether CocoaPods ran 'pod setup' once where the costly pods' specs are
  /// cloned.
  ///
  /// Versions >= 1.8.0 do not require 'pod setup' and default to a CDN instead
  /// of a locally cloned repository.
  /// See http://blog.cocoapods.org/CocoaPods-1.8.0-beta/
  ///
  /// A user can override the default location via the CP_REPOS_DIR environment
  /// variable.
  ///
  /// See https://github.com/CocoaPods/CocoaPods/blob/master/lib/cocoapods/config.rb#L138
  /// for details of this variable.
  Future<bool> get isCocoaPodsInitialized async {
    final Version installedVersion = Version.parse(await cocoaPodsVersionText);
    if (installedVersion != null && installedVersion >= Version.parse('1.8.0')) {
      return true;
    }
    final String cocoapodsReposDir = globals.platform.environment['CP_REPOS_DIR']
      ?? globals.fs.path.join(globals.fsUtils.homeDirPath, '.cocoapods', 'repos');
    return globals.fs.isDirectory(globals.fs.path.join(cocoapodsReposDir, 'master'));
  }

  Future<bool> processPods({
    @required XcodeBasedProject xcodeProject,
    // For backward compatibility with previously created Podfile only.
    @required String engineDir,
    bool dependenciesChanged = true,
  }) async {
    if (!xcodeProject.podfile.existsSync()) {
      throwToolExit('Podfile missing');
    }
    bool podsProcessed = false;
    if (await _checkPodCondition()) {
      if (_shouldRunPodInstall(xcodeProject, dependenciesChanged)) {
        await _runPodInstall(xcodeProject, engineDir);
        podsProcessed = true;
      }
      _warnIfPodfileOutOfDate(xcodeProject);
    }
    return podsProcessed;
  }

  /// Make sure the CocoaPods tools are in the right states.
  Future<bool> _checkPodCondition() async {
    final CocoaPodsStatus installation = await evaluateCocoaPodsInstallation;
    switch (installation) {
      case CocoaPodsStatus.notInstalled:
        globals.printError(
          'Warning: CocoaPods not installed. Skipping pod install.\n'
          '$noCocoaPodsConsequence\n'
          'To install:\n'
          '$cocoaPodsInstallInstructions\n',
          emphasis: true,
        );
        return false;
      case CocoaPodsStatus.unknownVersion:
        globals.printError(
          'Warning: Unknown CocoaPods version installed.\n'
          '$unknownCocoaPodsConsequence\n'
          'To upgrade:\n'
          '$cocoaPodsUpgradeInstructions\n',
          emphasis: true,
        );
        break;
      case CocoaPodsStatus.belowMinimumVersion:
        globals.printError(
          'Warning: CocoaPods minimum required version $cocoaPodsMinimumVersion or greater not installed. Skipping pod install.\n'
          '$noCocoaPodsConsequence\n'
          'To upgrade:\n'
          '$cocoaPodsUpgradeInstructions\n',
          emphasis: true,
        );
        return false;
      case CocoaPodsStatus.belowRecommendedVersion:
        globals.printError(
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
      globals.printError(
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

  /// Ensures the given Xcode-based sub-project of a parent Flutter project
  /// contains a suitable `Podfile` and that its `Flutter/Xxx.xcconfig` files
  /// include pods configuration.
  Future<void> setupPodfile(XcodeBasedProject xcodeProject) async {
    if (!xcodeProjectInterpreter.isInstalled) {
      // Don't do anything for iOS when host platform doesn't support it.
      return;
    }
    final Directory runnerProject = xcodeProject.xcodeProject;
    if (!runnerProject.existsSync()) {
      return;
    }
    final File podfile = xcodeProject.podfile;
    if (podfile.existsSync()) {
      addPodsDependencyToFlutterXcconfig(xcodeProject);
      return;
    }
    String podfileTemplateName;
    if (xcodeProject is MacOSProject) {
      podfileTemplateName = 'Podfile-macos';
    } else {
      final bool isSwift = (await xcodeProjectInterpreter.getBuildSettings(
        runnerProject.path,
        'Runner',
      )).containsKey('SWIFT_VERSION');
      podfileTemplateName = isSwift ? 'Podfile-ios-swift' : 'Podfile-ios-objc';
    }
    final File podfileTemplate = globals.fs.file(globals.fs.path.join(
      Cache.flutterRoot,
      'packages',
      'flutter_tools',
      'templates',
      'cocoapods',
      podfileTemplateName,
    ));
    podfileTemplate.copySync(podfile.path);
    addPodsDependencyToFlutterXcconfig(xcodeProject);
  }

  /// Ensures all `Flutter/Xxx.xcconfig` files for the given Xcode-based
  /// sub-project of a parent Flutter project include pods configuration.
  void addPodsDependencyToFlutterXcconfig(XcodeBasedProject xcodeProject) {
    _addPodsDependencyToFlutterXcconfig(xcodeProject, 'Debug');
    _addPodsDependencyToFlutterXcconfig(xcodeProject, 'Release');
  }

  void _addPodsDependencyToFlutterXcconfig(XcodeBasedProject xcodeProject, String mode) {
    final File file = xcodeProject.xcodeConfigFor(mode);
    if (file.existsSync()) {
      final String content = file.readAsStringSync();
      final String include = '#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.${mode
          .toLowerCase()}.xcconfig"';
      if (!content.contains(include)) {
        file.writeAsStringSync('$include\n$content', flush: true);
      }
    }
  }

  /// Ensures that pod install is deemed needed on next check.
  void invalidatePodInstallOutput(XcodeBasedProject xcodeProject) {
    final File manifestLock = xcodeProject.podManifestLock;
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
  bool _shouldRunPodInstall(XcodeBasedProject xcodeProject, bool dependenciesChanged) {
    if (dependenciesChanged) {
      return true;
    }

    final File podfileFile = xcodeProject.podfile;
    final File podfileLockFile = xcodeProject.podfileLock;
    final File manifestLockFile = xcodeProject.podManifestLock;

    return !podfileLockFile.existsSync()
        || !manifestLockFile.existsSync()
        || podfileLockFile.statSync().modified.isBefore(podfileFile.statSync().modified)
        || podfileLockFile.readAsStringSync() != manifestLockFile.readAsStringSync();
  }

  Future<void> _runPodInstall(XcodeBasedProject xcodeProject, String engineDirectory) async {
    final Status status = globals.logger.startProgress('Running pod install...', timeout: timeoutConfiguration.slowOperation);
    final ProcessResult result = await globals.processManager.run(
      <String>['pod', 'install', '--verbose'],
      workingDirectory: globals.fs.path.dirname(xcodeProject.podfile.path),
      environment: <String, String>{
        'FLUTTER_FRAMEWORK_DIR': engineDirectory,
        // See https://github.com/flutter/flutter/issues/10873.
        // CocoaPods analytics adds a lot of latency.
        'COCOAPODS_DISABLE_STATS': 'true',
        'LANG': 'en_US.UTF-8',
      },
    );
    status.stop();
    if (globals.logger.isVerbose || result.exitCode != 0) {
      final String stdout = result.stdout as String;
      if (stdout.isNotEmpty) {
        globals.printStatus('CocoaPods\' output:\n↳');
        globals.printStatus(stdout, indent: 4);
      }
      final String stderr = result.stderr as String;
      if (stderr.isNotEmpty) {
        globals.printStatus('Error output from CocoaPods:\n↳');
        globals.printStatus(stderr, indent: 4);
      }
    }
    if (result.exitCode != 0) {
      invalidatePodInstallOutput(xcodeProject);
      _diagnosePodInstallFailure(result);
      throwToolExit('Error running pod install');
    }
  }

  void _diagnosePodInstallFailure(ProcessResult result) {
    final dynamic stdout = result.stdout;
    if (stdout is String && stdout.contains('out-of-date source repos')) {
      globals.printError(
        "Error: CocoaPods's specs repository is too out-of-date to satisfy dependencies.\n"
        'To update the CocoaPods specs, run:\n'
        '  pod repo update\n',
        emphasis: true,
      );
    }
  }

  // Previously, the Podfile created a symlink to the cached artifacts engine framework
  // and installed the Flutter pod from that path. This could get out of sync with the copy
  // of the Flutter engine that was copied to ios/Flutter by the xcode_backend script.
  // It was possible for the symlink to point to a Debug version of the engine when the
  // Xcode build configuration was Release, which caused App Store submission rejections.
  //
  // Warn the user if they are still symlinking to the framework.
  void _warnIfPodfileOutOfDate(XcodeBasedProject xcodeProject) {
    if (xcodeProject is! IosProject) {
      return;
    }
    final Link flutterSymlink = globals.fs.link(globals.fs.path.join(
      xcodeProject.symlinks.path,
      'flutter',
    ));
    if (flutterSymlink.existsSync()) {
      globals.printError(
        'Warning: Podfile is out of date\n'
        '$outOfDatePodfileConsequence\n'
        'To regenerate the Podfile, run:\n'
        '$podfileMigrationInstructions\n',
        emphasis: true,
      );
    }
  }
}

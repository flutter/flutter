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

final String noCocoaPodsConsequence = '''
  CocoaPods is used to retrieve the iOS platform side's plugin code that responds to your plugin usage on the Dart side.
  Without resolving iOS dependencies with CocoaPods, plugins will not work on iOS.
  For more info, see https://flutter.io/platform-plugins''';

final String cocoaPodsInstallInstructions = '''
  brew install cocoapods
  pod setup''';

final String cocoaPodsUpgradeInstructions = '''
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
    @required String iosEngineDir,
    bool isSwift: false,
  }) async {
    if (await _checkPodCondition()) {
      if (!fs.file(fs.path.join(appIosDir.path, 'Podfile')).existsSync()) {
        await _createPodfile(appIosDir, isSwift);
      } // TODO(xster): Add more logic for handling merge conflicts.

      await _runPodInstall(appIosDir, iosEngineDir);
    } else {
      throwToolExit('CocoaPods not available for project using Flutter plugins');
    }
  }

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

  Future<Null> _createPodfile(Directory bundle, bool isSwift) async {
    final File podfileTemplate = fs.file(fs.path.join(
      Cache.flutterRoot,
      'packages',
      'flutter_tools',
      'templates',
      'cocoapods',
      isSwift ? 'Podfile-swift' : 'Podfile-objc',
    ));
    podfileTemplate.copySync(fs.path.join(bundle.path, 'Podfile'));
  }

  Future<Null> _runPodInstall(Directory bundle, String engineDirectory) async {
    final Status status = logger.startProgress('Running pod install...', expectSlowOperation: true);
    final ProcessResult result = await processManager.run(
      <String>['pod', 'install', '--verbose'],
      workingDirectory: bundle.path,
      environment: <String, String>{
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
    if (result.exitCode != 0)
      throwToolExit('Error running pod install');
  }
}

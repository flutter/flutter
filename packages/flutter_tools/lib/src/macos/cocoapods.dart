// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:process/process.dart';

import '../base/common.dart';
import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/version.dart';
import '../build_info.dart';
import '../cache.dart';
import '../ios/xcodeproj.dart';
import '../reporting/reporting.dart';
import '../xcode_project.dart';

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
  This can usually be fixed by re-installing CocoaPods.''';

const String outOfDateFrameworksPodfileConsequence = '''
  This can cause a mismatched version of Flutter to be embedded in your app, which may result in App Store submission rejection or crashes.
  If you have local Podfile edits you would like to keep, see https://github.com/flutter/flutter/issues/24641 for instructions.''';

const String outOfDatePluginsPodfileConsequence = '''
  This can cause issues if your application depends on plugins that do not support iOS or macOS.
  See https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms for details.
  If you have local Podfile edits you would like to keep, see https://github.com/flutter/flutter/issues/45197 for instructions.''';

const String cocoaPodsInstallInstructions = 'see https://guides.cocoapods.org/using/getting-started.html#installation for instructions.';

const String podfileIosMigrationInstructions = '''
  rm ios/Podfile''';

const String podfileMacOSMigrationInstructions = '''
  rm macos/Podfile''';

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

const Version cocoaPodsMinimumVersion = Version.withText(1, 10, 0, '1.10.0');
const Version cocoaPodsRecommendedVersion = Version.withText(1, 11, 0, '1.11.0');

/// Cocoapods is a dependency management solution for iOS and macOS applications.
///
/// Cocoapods is generally installed via ruby gems and interacted with via
/// the `pod` CLI command.
///
/// See also:
///   * https://cocoapods.org/ - the cocoapods website.
///   * https://flutter.dev/docs/get-started/install/macos#deploy-to-ios-devices - instructions for
///     installing iOS/macOS dependencies.
class CocoaPods {
  CocoaPods({
    required FileSystem fileSystem,
    required ProcessManager processManager,
    required XcodeProjectInterpreter xcodeProjectInterpreter,
    required Logger logger,
    required Platform platform,
    required Usage usage,
  }) : _fileSystem = fileSystem,
      _processManager = processManager,
      _xcodeProjectInterpreter = xcodeProjectInterpreter,
      _logger = logger,
      _usage = usage,
      _processUtils = ProcessUtils(processManager: processManager, logger: logger),
      _operatingSystemUtils = OperatingSystemUtils(
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        processManager: processManager,
      );

  final FileSystem _fileSystem;
  final ProcessManager _processManager;
  final ProcessUtils _processUtils;
  final OperatingSystemUtils _operatingSystemUtils;
  final XcodeProjectInterpreter _xcodeProjectInterpreter;
  final Logger _logger;
  final Usage _usage;

  Future<String?>? _versionText;

  Future<bool> get isInstalled =>
    _processUtils.exitsHappy(<String>['which', 'pod']);

  Future<String?> get cocoaPodsVersionText {
    _versionText ??= _processUtils.run(
      <String>['pod', '--version'],
      environment: <String, String>{
        'LANG': 'en_US.UTF-8',
      },
    ).then<String?>((RunResult result) {
      return result.exitCode == 0 ? result.stdout.trim() : null;
    }, onError: (dynamic _) => null);
    return _versionText!;
  }

  Future<CocoaPodsStatus> get evaluateCocoaPodsInstallation async {
    if (!(await isInstalled)) {
      return CocoaPodsStatus.notInstalled;
    }
    final String? versionText = await cocoaPodsVersionText;
    if (versionText == null) {
      return CocoaPodsStatus.brokenInstall;
    }
    try {
      final Version? installedVersion = Version.parse(versionText);
      if (installedVersion == null) {
        return CocoaPodsStatus.unknownVersion;
      }
      if (installedVersion < cocoaPodsMinimumVersion) {
        return CocoaPodsStatus.belowMinimumVersion;
      }
      if (installedVersion < cocoaPodsRecommendedVersion) {
        return CocoaPodsStatus.belowRecommendedVersion;
      }
      return CocoaPodsStatus.recommended;
    } on FormatException {
      return CocoaPodsStatus.notInstalled;
    }
  }

  Future<bool> processPods({
    required XcodeBasedProject xcodeProject,
    required BuildMode buildMode,
    bool dependenciesChanged = true,
  }) async {
    if (!xcodeProject.podfile.existsSync()) {
      throwToolExit('Podfile missing');
    }
    _warnIfPodfileOutOfDate(xcodeProject);
    bool podsProcessed = false;
    if (_shouldRunPodInstall(xcodeProject, dependenciesChanged)) {
      if (!await _checkPodCondition()) {
        throwToolExit('CocoaPods not installed or not in valid state.');
      }
      await _runPodInstall(xcodeProject, buildMode);
      podsProcessed = true;
    }
    return podsProcessed;
  }

  /// Make sure the CocoaPods tools are in the right states.
  Future<bool> _checkPodCondition() async {
    final CocoaPodsStatus installation = await evaluateCocoaPodsInstallation;
    switch (installation) {
      case CocoaPodsStatus.notInstalled:
        _logger.printWarning(
          'Warning: CocoaPods not installed. Skipping pod install.\n'
          '$noCocoaPodsConsequence\n'
          'To install $cocoaPodsInstallInstructions\n',
          emphasis: true,
        );
        return false;
      case CocoaPodsStatus.brokenInstall:
        _logger.printWarning(
          'Warning: CocoaPods is installed but broken. Skipping pod install.\n'
          '$brokenCocoaPodsConsequence\n'
          'To re-install $cocoaPodsInstallInstructions\n',
          emphasis: true,
        );
        return false;
      case CocoaPodsStatus.unknownVersion:
        _logger.printWarning(
          'Warning: Unknown CocoaPods version installed.\n'
          '$unknownCocoaPodsConsequence\n'
          'To upgrade $cocoaPodsInstallInstructions\n',
          emphasis: true,
        );
        break;
      case CocoaPodsStatus.belowMinimumVersion:
        _logger.printWarning(
          'Warning: CocoaPods minimum required version $cocoaPodsMinimumVersion or greater not installed. Skipping pod install.\n'
          '$noCocoaPodsConsequence\n'
          'To upgrade $cocoaPodsInstallInstructions\n',
          emphasis: true,
        );
        return false;
      case CocoaPodsStatus.belowRecommendedVersion:
        _logger.printWarning(
          'Warning: CocoaPods recommended version $cocoaPodsRecommendedVersion or greater not installed.\n'
          'Pods handling may fail on some projects involving plugins.\n'
          'To upgrade $cocoaPodsInstallInstructions\n',
          emphasis: true,
        );
        break;
      case CocoaPodsStatus.recommended:
        break;
    }

    return true;
  }

  /// Ensures the given Xcode-based sub-project of a parent Flutter project
  /// contains a suitable `Podfile` and that its `Flutter/Xxx.xcconfig` files
  /// include pods configuration.
  Future<void> setupPodfile(XcodeBasedProject xcodeProject) async {
    if (!_xcodeProjectInterpreter.isInstalled) {
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
      final bool isSwift = (await _xcodeProjectInterpreter.getBuildSettings(
        runnerProject.path,
        buildContext: const XcodeProjectBuildContext(),
      )).containsKey('SWIFT_VERSION');
      podfileTemplateName = isSwift ? 'Podfile-ios-swift' : 'Podfile-ios-objc';
    }
    final File podfileTemplate = _fileSystem.file(_fileSystem.path.join(
      Cache.flutterRoot!,
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
      final String includeFile = 'Pods/Target Support Files/Pods-Runner/Pods-Runner.${mode
          .toLowerCase()}.xcconfig';
      final String include = '#include? "$includeFile"';
      if (!content.contains('Pods/Target Support Files/Pods-')) {
        file.writeAsStringSync('$include\n$content', flush: true);
      }
    }
  }

  /// Ensures that pod install is deemed needed on next check.
  void invalidatePodInstallOutput(XcodeBasedProject xcodeProject) {
    final File manifestLock = xcodeProject.podManifestLock;
    ErrorHandlingFileSystem.deleteIfExists(manifestLock);
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

  Future<void> _runPodInstall(XcodeBasedProject xcodeProject, BuildMode buildMode) async {
    final Status status = _logger.startProgress('Running pod install...');
    final ProcessResult result = await _processManager.run(
      <String>['pod', 'install', '--verbose'],
      workingDirectory: _fileSystem.path.dirname(xcodeProject.podfile.path),
      environment: <String, String>{
        // See https://github.com/flutter/flutter/issues/10873.
        // CocoaPods analytics adds a lot of latency.
        'COCOAPODS_DISABLE_STATS': 'true',
        'LANG': 'en_US.UTF-8',
      },
    );
    status.stop();
    if (_logger.isVerbose || result.exitCode != 0) {
      final String stdout = result.stdout as String;
      if (stdout.isNotEmpty) {
        _logger.printStatus("CocoaPods' output:\n↳");
        _logger.printStatus(stdout, indent: 4);
      }
      final String stderr = result.stderr as String;
      if (stderr.isNotEmpty) {
        _logger.printStatus('Error output from CocoaPods:\n↳');
        _logger.printStatus(stderr, indent: 4);
      }
    }

    if (result.exitCode != 0) {
      invalidatePodInstallOutput(xcodeProject);
      _diagnosePodInstallFailure(result);
      throwToolExit('Error running pod install');
    } else if (xcodeProject.podfileLock.existsSync()) {
      // Even if the Podfile.lock didn't change, update its modified date to now
      // so Podfile.lock is newer than Podfile.
      _processManager.runSync(
        <String>['touch', xcodeProject.podfileLock.path],
        workingDirectory: _fileSystem.path.dirname(xcodeProject.podfile.path),
      );
    }
  }

  void _diagnosePodInstallFailure(ProcessResult result) {
    final Object? stdout = result.stdout;
    final Object? stderr = result.stderr;
    if (stdout is! String || stderr is! String) {
      return;
    }
    if (stdout.contains('out-of-date source repos')) {
      _logger.printError(
        "Error: CocoaPods's specs repository is too out-of-date to satisfy dependencies.\n"
        'To update the CocoaPods specs, run:\n'
        '  pod repo update\n',
        emphasis: true,
      );
    } else if ((stderr.contains('ffi_c.bundle') || stderr.contains('/ffi/')) &&
        _operatingSystemUtils.hostPlatform == HostPlatform.darwin_arm64) {
      // https://github.com/flutter/flutter/issues/70796
      UsageEvent(
        'pod-install-failure',
        'arm-ffi',
        flutterUsage: _usage,
      ).send();
      _logger.printError(
        'Error: To set up CocoaPods for ARM macOS, run:\n'
        '  sudo gem uninstall ffi && sudo gem install ffi -- --enable-libffi-alloc\n',
        emphasis: true,
      );
    }
  }

  void _warnIfPodfileOutOfDate(XcodeBasedProject xcodeProject) {
    final bool isIos = xcodeProject is IosProject;
    if (isIos) {
      // Previously, the Podfile created a symlink to the cached artifacts engine framework
      // and installed the Flutter pod from that path. This could get out of sync with the copy
      // of the Flutter engine that was copied to ios/Flutter by the xcode_backend script.
      // It was possible for the symlink to point to a Debug version of the engine when the
      // Xcode build configuration was Release, which caused App Store submission rejections.
      //
      // Warn the user if they are still symlinking to the framework.
      final Link flutterSymlink = _fileSystem.link(_fileSystem.path.join(
        xcodeProject.symlinks.path,
        'flutter',
      ));
      if (flutterSymlink.existsSync()) {
        throwToolExit(
          'Warning: Podfile is out of date\n'
              '$outOfDateFrameworksPodfileConsequence\n'
              'To regenerate the Podfile, run:\n'
              '$podfileIosMigrationInstructions\n',
        );
      }
    }
    // Most of the pod and plugin parsing logic was moved from the Podfile
    // into the tool's podhelper.rb script. If the Podfile still references
    // the old parsed .flutter-plugins file, prompt the regeneration. Old line was:
    // plugin_pods = parse_KV_file('../.flutter-plugins')
    if (xcodeProject.podfile.existsSync() &&
      xcodeProject.podfile.readAsStringSync().contains(".flutter-plugins'")) {
      const String warning = 'Warning: Podfile is out of date\n'
          '$outOfDatePluginsPodfileConsequence\n'
          'To regenerate the Podfile, run:\n';
      if (isIos) {
        throwToolExit('$warning\n$podfileIosMigrationInstructions\n');
      } else {
        // The old macOS Podfile will work until `.flutter-plugins` is removed.
        // Warn instead of exit.
        _logger.printWarning('$warning\n$podfileMacOSMigrationInstructions\n', emphasis: true);
      }
    }
  }
}

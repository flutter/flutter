// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'android/gradle.dart';
import 'application_package.dart';
import 'asset.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'base/io.dart';
import 'base/logger.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'dart/dependencies.dart';
import 'dart/package_map.dart';
import 'dependency_checker.dart';
import 'device.dart';
import 'globals.dart';
import 'vmservice.dart';

// Shared code between different resident application runners.
abstract class ResidentRunner {
  ResidentRunner(this.device, {
    this.target,
    this.debuggingOptions,
    this.usesTerminalUI: true,
    String projectRootPath,
    String packagesFilePath,
    String projectAssets,
    this.stayResident,
  }) {
    _mainPath = findMainDartFile(target);
    _projectRootPath = projectRootPath ?? fs.currentDirectory.path;
    _packagesFilePath =
        packagesFilePath ?? fs.path.absolute(PackageMap.globalPackagesPath);
    if (projectAssets != null)
      _assetBundle = new AssetBundle.fixed(_projectRootPath, projectAssets);
    else
      _assetBundle = new AssetBundle();
  }

  final Device device;
  final String target;
  final DebuggingOptions debuggingOptions;
  final bool usesTerminalUI;
  final bool stayResident;
  final Completer<int> _finished = new Completer<int>();
  String _packagesFilePath;
  String get packagesFilePath => _packagesFilePath;
  String _projectRootPath;
  String get projectRootPath => _projectRootPath;
  String _mainPath;
  String get mainPath => _mainPath;
  AssetBundle _assetBundle;
  AssetBundle get assetBundle => _assetBundle;
  ApplicationPackage package;

  bool get isRunningDebug => debuggingOptions.buildMode == BuildMode.debug;
  bool get isRunningProfile => debuggingOptions.buildMode == BuildMode.profile;
  bool get isRunningRelease => debuggingOptions.buildMode == BuildMode.release;
  bool get supportsServiceProtocol => isRunningDebug || isRunningProfile;

  VMService vmService;
  FlutterView currentView;
  StreamSubscription<String> _loggingSubscription;

  /// Start the app and keep the process running during its lifetime.
  Future<int> run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<Null> appStartedCompleter,
    String route,
    bool shouldBuild: true
  });

  bool get supportsRestart => false;

  Future<OperationResult> restart({ bool fullRestart: false, bool pauseAfterRestart: false }) {
    throw 'unsupported';
  }

  Future<Null> stop() async {
    await stopEchoingDeviceLog();
    await preStop();
    return stopApp();
  }

  Future<Null> detach() async {
    await stopEchoingDeviceLog();
    await preStop();
    appFinished();
  }

  Future<Null> _debugDumpApp() async {
    if (vmService != null)
      await vmService.vm.refreshViews();
    await currentView.uiIsolate.flutterDebugDumpApp();
  }

  Future<Null> _debugDumpRenderTree() async {
    if (vmService != null)
      await vmService.vm.refreshViews();
    await currentView.uiIsolate.flutterDebugDumpRenderTree();
  }

  Future<Null> _debugToggleDebugPaintSizeEnabled() async {
    if (vmService != null)
      await vmService.vm.refreshViews();
    await currentView.uiIsolate.flutterToggleDebugPaintSizeEnabled();
  }

  Future<Null> _screenshot() async {
    final Status status = logger.startProgress('Taking screenshot...');
    final File outputFile = getUniqueFile(fs.currentDirectory, 'flutter', 'png');
    try {
      if (supportsServiceProtocol && isRunningDebug) {
        if (vmService != null)
          await vmService.vm.refreshViews();
        try {
          await currentView.uiIsolate.flutterDebugAllowBanner(false);
        } catch (error) {
          status.stop();
          printError(error);
        }
      }
      try {
        await device.takeScreenshot(outputFile);
      } finally {
        if (supportsServiceProtocol && isRunningDebug) {
          try {
            await currentView.uiIsolate.flutterDebugAllowBanner(true);
          } catch (error) {
            status.stop();
            printError(error);
          }
        }
      }
      final int sizeKB = (await outputFile.length()) ~/ 1024;
      status.stop();
      printStatus('Screenshot written to ${fs.path.relative(outputFile.path)} (${sizeKB}kB).');
    } catch (error) {
      status.stop();
      printError('Error taking screenshot: $error');
    }
  }

  Future<String> _debugRotatePlatform() async {
    if (vmService != null)
      await vmService.vm.refreshViews();
    switch (await currentView.uiIsolate.flutterPlatformOverride()) {
      case 'iOS':
        return await currentView.uiIsolate.flutterPlatformOverride('android');
      case 'android':
      default:
        return await currentView.uiIsolate.flutterPlatformOverride('iOS');
    }
  }

  void registerSignalHandlers() {
    assert(stayResident);
    ProcessSignal.SIGINT.watch().listen(_cleanUpAndExit);
    ProcessSignal.SIGTERM.watch().listen(_cleanUpAndExit);
    if (!supportsServiceProtocol || !supportsRestart)
      return;
    ProcessSignal.SIGUSR1.watch().listen(_handleSignal);
    ProcessSignal.SIGUSR2.watch().listen(_handleSignal);
  }

  Future<Null> _cleanUpAndExit(ProcessSignal signal) async {
    _resetTerminal();
    await cleanupAfterSignal();
    exit(0);
  }

  bool _processingUserRequest = false;
  Future<Null> _handleSignal(ProcessSignal signal) async {
    if (_processingUserRequest) {
      printTrace('Ignoring signal: "$signal" because we are busy.');
      return;
    }
    _processingUserRequest = true;

    final bool fullRestart = signal == ProcessSignal.SIGUSR2;

    try {
      await restart(fullRestart: fullRestart);
    } finally {
      _processingUserRequest = false;
    }
  }

  Future<Null> startEchoingDeviceLog(ApplicationPackage app) async {
    if (_loggingSubscription != null)
      return;
    _loggingSubscription = device.getLogReader(app: app).logLines.listen((String line) {
      if (!line.contains('Observatory listening on http') &&
          !line.contains('Diagnostic server listening on http'))
        printStatus(line);
    });
  }

  Future<Null> stopEchoingDeviceLog() async {
    if (_loggingSubscription != null) {
      await _loggingSubscription.cancel();
    }
    _loggingSubscription = null;
  }

  Future<Null> connectToServiceProtocol(Uri uri, {String isolateFilter}) async {
    if (!debuggingOptions.debuggingEnabled) {
      return new Future<Null>.error('Error the service protocol is not enabled.');
    }
    vmService = VMService.connect(uri);
    printTrace('Connected to service protocol: $uri');
    await vmService.getVM();

    // Refresh the view list, and wait a bit for the list to populate.
    await vmService.waitForViews();
    currentView = (isolateFilter == null)
                ? vmService.vm.firstView
                : vmService.vm.firstViewWithName(isolateFilter);
    if (currentView == null)
      throwToolExit('No Flutter view is available');

    // Listen for service protocol connection to close.
    vmService.done.then<Null>(
        _serviceProtocolDone,
        onError: _serviceProtocolError).whenComplete(appFinished);
  }

  Future<Null> _serviceProtocolDone(dynamic object) {
    printTrace('Service protocol connection closed.');
    return new Future<Null>.value(object);
  }

  Future<Null> _serviceProtocolError(dynamic error, StackTrace stack) {
    printTrace('Service protocol connection closed with an error: $error\n$stack');
    return new Future<Null>.error(error, stack);
  }

  /// Returns [true] if the input has been handled by this function.
  Future<bool> _commonTerminalInputHandler(String character) async {
    final String lower = character.toLowerCase();

    printStatus(''); // the key the user tapped might be on this line

    if (lower == 'h' || lower == '?') {
      // help
      printHelp(details: true);
      return true;
    } else if (lower == 'w') {
      if (supportsServiceProtocol) {
        await _debugDumpApp();
        return true;
      }
    } else if (lower == 't') {
      if (supportsServiceProtocol) {
        await _debugDumpRenderTree();
        return true;
      }
    } else if (lower == 'p') {
      if (supportsServiceProtocol && isRunningDebug) {
        await _debugToggleDebugPaintSizeEnabled();
        return true;
      }
    } else if (lower == 's') {
      if (device.supportsScreenshot) {
        await _screenshot();
        return true;
      }
    } else if (lower == 'o') {
      if (supportsServiceProtocol && isRunningDebug) {
        final String platform = await _debugRotatePlatform();
        print('Switched operating system to: $platform');
        return true;
      }
    } else if (lower == 'q') {
      // exit
      await stop();
      return true;
    } else if (lower == 'd') {
      await detach();
      return true;
    }

    return false;
  }

  Future<Null> processTerminalInput(String command) async {
    if (_processingUserRequest) {
      printTrace('Ignoring terminal input: "$command" because we are busy.');
      return;
    }
    _processingUserRequest = true;
    try {
      final bool handled = await _commonTerminalInputHandler(command);
      if (!handled)
        await handleTerminalCommand(command);
    } finally {
      _processingUserRequest = false;
    }
  }

  void appFinished() {
    if (_finished.isCompleted)
      return;
    printStatus('Application finished.');
    _resetTerminal();
    _finished.complete(0);
  }

  void _resetTerminal() {
    if (usesTerminalUI)
      terminal.singleCharMode = false;
  }

  void setupTerminal() {
    assert(stayResident);
    if (usesTerminalUI) {
      if (!logger.quiet) {
        printStatus('');
        printHelp(details: false);
      }
      terminal.singleCharMode = true;
      terminal.onCharInput.listen(processTerminalInput);
    }
  }

  Future<int> waitForAppToFinish() async {
    final int exitCode = await _finished.future;
    await cleanupAtFinish();
    return exitCode;
  }

  bool hasDirtyDependencies() {
    final DartDependencySetBuilder dartDependencySetBuilder =
        new DartDependencySetBuilder(mainPath, packagesFilePath);
    final DependencyChecker dependencyChecker =
        new DependencyChecker(dartDependencySetBuilder, assetBundle);
    final String path = package.packagePath;
    if (path == null) {
      return true;
    }
    final FileStat stat = fs.file(path).statSync();
    if (stat.type != FileSystemEntityType.FILE) {
      return true;
    }
    if (!fs.file(path).existsSync()) {
      return true;
    }
    final DateTime lastBuildTime = stat.modified;
    return dependencyChecker.check(lastBuildTime);
  }

  Future<Null> preStop() async { }

  Future<Null> stopApp() async {
    if (vmService != null && !vmService.isClosed) {
      if ((currentView != null) && (currentView.uiIsolate != null)) {
        // TODO(johnmccutchan): Wait for the exit command to complete.
        currentView.uiIsolate.flutterExit();
        await new Future<Null>.delayed(const Duration(milliseconds: 100));
      }
    }
    appFinished();
  }

  /// Called to print help to the terminal.
  void printHelp({ @required bool details });

  void printHelpDetails() {
    if (supportsServiceProtocol) {
      printStatus('To dump the widget hierarchy of the app (debugDumpApp), press "w".');
      printStatus('To dump the rendering tree of the app (debugDumpRenderTree), press "t".');
      if (isRunningDebug) {
        printStatus('To toggle the display of construction lines (debugPaintSizeEnabled), press "p".');
        printStatus('To simulate different operating systems, (defaultTargetPlatform), press "o".');
      }
    }
    if (device.supportsScreenshot)
      printStatus('To save a screenshot to flutter.png, press "s".');
  }

  /// Called when a signal has requested we exit.
  Future<Null> cleanupAfterSignal();
  /// Called right before we exit.
  Future<Null> cleanupAtFinish();
  /// Called when the runner should handle a terminal command.
  Future<Null> handleTerminalCommand(String code);
}

class OperationResult {
  static final OperationResult ok = new OperationResult(0, '');

  OperationResult(this.code, this.message);

  final int code;
  final String message;

  bool get isOk => code == 0;
}

/// Given the value of the --target option, return the path of the Dart file
/// where the app's main function should be.
String findMainDartFile([String target]) {
  if (target == null)
    target = '';
  final String targetPath = fs.path.absolute(target);
  if (fs.isDirectorySync(targetPath))
    return fs.path.join(targetPath, 'lib', 'main.dart');
  else
    return targetPath;
}

String getMissingPackageHintForPlatform(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.android_arm:
    case TargetPlatform.android_x64:
    case TargetPlatform.android_x86:
      String manifest = 'android/AndroidManifest.xml';
      if (isProjectUsingGradle()) {
        manifest = gradleManifestPath;
      }
      return 'Is your project missing an $manifest?\nConsider running "flutter create ." to create one.';
    case TargetPlatform.ios:
      return 'Is your project missing an ios/Runner/Info.plist?\nConsider running "flutter create ." to create one.';
    default:
      return null;
  }
}

class DebugConnectionInfo {
  DebugConnectionInfo({ this.httpUri, this.wsUri, this.baseUri });

  // TODO(danrubel): the httpUri field should be removed as part of
  // https://github.com/flutter/flutter/issues/7050
  final Uri httpUri;
  final Uri wsUri;
  final String baseUri;
}

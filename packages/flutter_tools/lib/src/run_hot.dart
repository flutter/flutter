// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';

import 'application_package.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/utils.dart';
import 'build_info.dart';

import 'dart/dependencies.dart';
import 'devfs.dart';
import 'device.dart';
import 'globals.dart';
import 'resident_runner.dart';

import 'vmservice.dart';
import 'usage.dart';

class HotRunnerConfig {
  /// Should the hot runner compute the minimal Dart dependencies?
  bool computeDartDependencies = true;
  /// Should the hot runner assume that the minimal Dart dependencies do not change?
  bool stableDartDependencies = false;
}

HotRunnerConfig get hotRunnerConfig => context[HotRunnerConfig];

const bool kHotReloadDefault = true;

class HotRunner extends ResidentRunner {
  HotRunner(
    Device device, {
    String target,
    DebuggingOptions debuggingOptions,
    bool usesTerminalUI: true,
    this.benchmarkMode: false,
    this.applicationBinary,
    String projectRootPath,
    String packagesFilePath,
    String projectAssets,
    bool stayResident: true,
  }) : super(device,
             target: target,
             debuggingOptions: debuggingOptions,
             usesTerminalUI: usesTerminalUI,
             projectRootPath: projectRootPath,
             packagesFilePath: packagesFilePath,
             projectAssets: projectAssets,
             stayResident: stayResident);

  final String applicationBinary;
  bool get prebuiltMode => applicationBinary != null;
  Set<String> _dartDependencies;
  Uri _observatoryUri;

  final bool benchmarkMode;
  final Map<String, int> benchmarkData = new Map<String, int>();
  // The initial launch is from a snapshot.
  bool _runningFromSnapshot = true;

  @override
  Future<int> run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<Null> appStartedCompleter,
    String route,
    bool shouldBuild: true
  }) {
    // Don't let uncaught errors kill the process.
    return Chain.capture(() {
      return _run(
        connectionInfoCompleter: connectionInfoCompleter,
        appStartedCompleter: appStartedCompleter,
        route: route,
        shouldBuild: shouldBuild
      );
    }, onError: (dynamic error, StackTrace stackTrace) {
      printError('Exception from flutter run: $error', stackTrace);
    });
  }

  bool _refreshDartDependencies() {
    if (!hotRunnerConfig.computeDartDependencies) {
      // Disabled.
      return true;
    }
    if (_dartDependencies != null) {
      // Already computed.
      return true;
    }
    DartDependencySetBuilder dartDependencySetBuilder =
        new DartDependencySetBuilder(
              mainPath, projectRootPath, packagesFilePath);
    try {
      Set<String> dependencies = dartDependencySetBuilder.build();
      _dartDependencies = new Set<String>();
      for (String path in dependencies) {
        // We need to tweak package: uris so that they reflect their devFS
        // location.
        if (path.startsWith('package:')) {
          // Swap out package: for packages/ because we place all package
          // sources under packages/.
          path = path.replaceFirst('package:', 'packages/');
        }
        _dartDependencies.add(path);
      }
    } catch (error) {
      printStatus('Error detected in application source code:', emphasis: true);
      printError('$error');
      return false;
    }
    return true;
  }

  Future<int> _run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<Null> appStartedCompleter,
    String route,
    bool shouldBuild: true
  }) async {
    if (!fs.isFileSync(mainPath)) {
      String message = 'Tried to run $mainPath, but that file does not exist.';
      if (target == null)
        message += '\nConsider using the -t option to specify the Dart file to start.';
      printError(message);
      return 1;
    }

    package = getApplicationPackageForPlatform(device.platform, applicationBinary: applicationBinary);

    if (package == null) {
      String message = 'No application found for ${device.platform}.';
      String hint = getMissingPackageHintForPlatform(device.platform);
      if (hint != null)
        message += '\n$hint';
      printError(message);
      return 1;
    }

    // Determine the Dart dependencies eagerly.
    if (!_refreshDartDependencies()) {
      // Some kind of source level error or missing file in the Dart code.
      return 1;
    }

    Map<String, dynamic> platformArgs = new Map<String, dynamic>();

    await startEchoingDeviceLog(package);

    String modeName = getModeName(debuggingOptions.buildMode);
    printStatus('Launching ${getDisplayPath(mainPath)} on ${device.name} in $modeName mode...');

    // Start the application.
    Future<LaunchResult> futureResult = device.startApp(
      package,
      debuggingOptions.buildMode,
      mainPath: mainPath,
      debuggingOptions: debuggingOptions,
      platformArgs: platformArgs,
      route: route,
      prebuiltApplication: prebuiltMode,
      applicationNeedsRebuild: shouldBuild || hasDirtyDependencies()
    );

    LaunchResult result = await futureResult;

    if (!result.started) {
      printError('Error launching application on ${device.name}.');
      await stopEchoingDeviceLog();
      return 2;
    }

    _observatoryUri = result.observatoryUri;
    try {
      await connectToServiceProtocol(_observatoryUri);
    } catch (error) {
      printError('Error connecting to the service protocol: $error');
      return 2;
    }

    try {
      Uri baseUri = await _initDevFS();
      if (connectionInfoCompleter != null) {
        connectionInfoCompleter.complete(
          new DebugConnectionInfo(
            httpUri: _observatoryUri,
            wsUri: vmService.wsAddress,
            baseUri: baseUri.toString()
          )
        );
      }
    } catch (error) {
      printError('Error initializing DevFS: $error');
      return 3;
    }
    bool devfsResult = await _updateDevFS();
    if (!devfsResult) {
      printError('Could not perform initial file synchronization.');
      return 3;
    }

    await vmService.vm.refreshViews();
    printTrace('Connected to ${vmService.vm.mainView}.');

    if (stayResident) {
      setupTerminal();
      registerSignalHandlers();
    }

    appStartedCompleter?.complete();

    if (benchmarkMode) {
      // We are running in benchmark mode.
      printStatus('Running in benchmark mode.');
      // Measure time to perform a hot restart.
      printStatus('Benchmarking hot restart');
      await restart(fullRestart: true);
      await vmService.vm.refreshViews();
      // TODO(johnmccutchan): Modify script entry point.
      printStatus('Benchmarking hot reload');
      // Measure time to perform a hot reload.
      await restart(fullRestart: false);
      printStatus('Benchmark completed. Exiting application.');
      await _cleanupDevFS();
      await stopEchoingDeviceLog();
      await stopApp();
      File benchmarkOutput = fs.file('hot_benchmark.json');
      benchmarkOutput.writeAsStringSync(toPrettyJson(benchmarkData));
    }

    if (stayResident)
      return waitForAppToFinish();
    await cleanupAtFinish();
    return 0;
  }

  @override
  Future<Null> handleTerminalCommand(String code) async {
    final String lower = code.toLowerCase();
    if ((lower == 'r') || (code == AnsiTerminal.KEY_F5)) {
      OperationResult result = await restart(fullRestart: code == 'R');
      if (!result.isOk) {
        // TODO(johnmccutchan): Attempt to determine the number of errors that
        // occurred and tighten this message.
        printStatus('Try again after fixing the above error(s).', emphasis: true);
      }
    }
  }

  DevFS _devFS;

  Future<Uri> _initDevFS() {
    String fsName = path.basename(projectRootPath);
    _devFS = new DevFS(vmService,
                       fsName,
                       fs.directory(projectRootPath),
                       packagesFilePath: packagesFilePath);
    return _devFS.create();
  }

  Future<bool> _updateDevFS({ DevFSProgressReporter progressReporter }) async {
    if (!_refreshDartDependencies()) {
      // Did not update DevFS because of a Dart source error.
      return false;
    }
    final bool rebuildBundle = assetBundle.needsBuild();
    if (rebuildBundle) {
      printTrace('Updating assets');
      int result = await assetBundle.build();
      if (result != 0)
        return false;
    }
    Status devFSStatus = logger.startProgress('Syncing files to device...');
    int bytes = await _devFS.update(progressReporter: progressReporter,
                        bundle: assetBundle,
                        bundleDirty: rebuildBundle,
                        fileFilter: _dartDependencies);
    devFSStatus.stop();
    if (!hotRunnerConfig.stableDartDependencies) {
      // Clear the set after the sync so they are recomputed next time.
      _dartDependencies = null;
    }
    printTrace('Synced ${getSizeAsMB(bytes)}.');
    return true;
  }

  Future<Null> _evictDirtyAssets() async {
    if (_devFS.assetPathsToEvict.isEmpty)
      return;
    if (currentView.uiIsolate == null)
      throw 'Application isolate not found';
    for (String assetPath in _devFS.assetPathsToEvict) {
      await currentView.uiIsolate.flutterEvictAsset(assetPath);
    }
    _devFS.assetPathsToEvict.clear();
  }

  Future<Null> _cleanupDevFS() async {
    if (_devFS != null) {
      // Cleanup the devFS; don't wait indefinitely, and ignore any errors.
      await _devFS.destroy()
        .timeout(new Duration(milliseconds: 250))
        .catchError((dynamic error) {
          printTrace('$error');
        });
    }
    _devFS = null;
  }

  Future<Null> _launchInView(String entryPath,
                             String packagesPath,
                             String assetsDirectoryPath) async {
    FlutterView view = vmService.vm.mainView;
    return view.runFromSource(entryPath, packagesPath, assetsDirectoryPath);
  }

  Future<Null> _launchFromDevFS(ApplicationPackage package,
                                String mainScript) async {
    String entryPath = path.relative(mainScript, from: projectRootPath);
    String deviceEntryPath =
        _devFS.baseUri.resolve(entryPath).toFilePath();
    String devicePackagesPath =
        _devFS.baseUri.resolve('.packages').toFilePath();
    String deviceAssetsDirectoryPath =
        _devFS.baseUri.resolve(getAssetBuildDirectory()).toFilePath();
    await _launchInView(deviceEntryPath,
                        devicePackagesPath,
                        deviceAssetsDirectoryPath);
  }

  Future<OperationResult> _restartFromSources() async {
    Stopwatch restartTimer = new Stopwatch();
    restartTimer.start();
    bool updatedDevFS = await _updateDevFS();
    if (!updatedDevFS)
      return new OperationResult(1, 'Dart Source Error');
    await _launchFromDevFS(package, mainPath);
    restartTimer.stop();
    printTrace('Restart performed in '
        '${getElapsedAsMilliseconds(restartTimer.elapsed)}.');
    // We are now running from sources.
    _runningFromSnapshot = false;
    if (benchmarkMode) {
      benchmarkData['hotRestartMillisecondsToFrame'] =
          restartTimer.elapsed.inMilliseconds;
    }
    flutterUsage.sendEvent('hot', 'restart');
    flutterUsage.sendTiming('hot', 'restart', restartTimer.elapsed);
    return OperationResult.ok;
  }

  /// Returns [true] if the reload was successful.
  static bool validateReloadReport(Map<String, dynamic> reloadReport) {
    if (reloadReport['type'] != 'ReloadReport') {
      printError('Hot reload received invalid response: $reloadReport');
      return false;
    }
    if (!reloadReport['success']) {
      printError('Hot reload was rejected:');
      for (Map<String, dynamic> notice in reloadReport['details']['notices'])
        printError('${notice['message']}');
      return false;
    }
    return true;
  }

  @override
  bool get supportsRestart => true;

  @override
  Future<OperationResult> restart({ bool fullRestart: false, bool pauseAfterRestart: false }) async {
    if (fullRestart) {
      Status status = logger.startProgress('Performing full restart...', progressId: 'hot.restart');
      try {
        await _restartFromSources();
        status.stop();
        printStatus('Restart complete.');
        return OperationResult.ok;
      } catch (error) {
        status.stop();
        rethrow;
      }
    } else {
      Status status = logger.startProgress('Performing hot reload...', progressId: 'hot.reload');
      try {
        OperationResult result = await _reloadSources(pause: pauseAfterRestart);
        status.stop();
        if (result.isOk)
          printStatus("${result.message}.");
        return result;
      } catch (error) {
        status.stop();
        rethrow;
      }
    }
  }

  Future<OperationResult> _reloadSources({ bool pause: false }) async {
    if (currentView.uiIsolate == null)
      throw 'Application isolate not found';
    // The initial launch is from a script snapshot. When we reload from source
    // on top of a script snapshot, the first reload will be a worst case reload
    // because all of the sources will end up being dirty (library paths will
    // change from host path to a device path). Subsequent reloads will
    // not be affected, so we resume reporting reload times on the second
    // reload.
    final bool shouldReportReloadTime = !_runningFromSnapshot;
    Stopwatch reloadTimer = new Stopwatch();
    reloadTimer.start();
    Stopwatch devFSTimer;
    Stopwatch vmReloadTimer;
    Stopwatch reassembleTimer;
    if (benchmarkMode) {
      devFSTimer = new Stopwatch();
      devFSTimer.start();
      vmReloadTimer = new Stopwatch();
      reassembleTimer = new Stopwatch();
    }
    bool updatedDevFS = await _updateDevFS();
    if (benchmarkMode) {
      devFSTimer.stop();
      // Record time it took to synchronize to DevFS.
      benchmarkData['hotReloadDevFSSyncMilliseconds'] =
            devFSTimer.elapsed.inMilliseconds;
    }
    if (!updatedDevFS)
      return new OperationResult(1, 'Dart Source Error');
    String reloadMessage;
    try {
      String entryPath = path.relative(mainPath, from: projectRootPath);
      String deviceEntryPath =
          _devFS.baseUri.resolve(entryPath).toFilePath();
      String devicePackagesPath =
          _devFS.baseUri.resolve('.packages').toFilePath();
      if (benchmarkMode)
        vmReloadTimer.start();
      Map<String, dynamic> reloadReport =
          await currentView.uiIsolate.reloadSources(
              pause: pause,
              rootLibPath: deviceEntryPath,
              packagesPath: devicePackagesPath);
      if (!validateReloadReport(reloadReport)) {
        // Reload failed.
        flutterUsage.sendEvent('hot', 'reload-reject');
        return new OperationResult(1, 'reload rejected');
      } else {
        flutterUsage.sendEvent('hot', 'reload');
        int loadedLibraryCount = reloadReport['details']['loadedLibraryCount'];
        int finalLibraryCount = reloadReport['details']['finalLibraryCount'];
        reloadMessage = 'Reloaded $loadedLibraryCount of $finalLibraryCount libraries';
      }
    } catch (error, st) {
      int errorCode = error['code'];
      String errorMessage = error['message'];
      if (errorCode == Isolate.kIsolateReloadBarred) {
        printError('Unable to hot reload app due to an unrecoverable error in '
                   'the source code. Please address the error and then use '
                   '"R" to restart the app.');
        flutterUsage.sendEvent('hot', 'reload-barred');
        return new OperationResult(errorCode, errorMessage);
      }

      printError('Hot reload failed:\ncode = $errorCode\nmessage = $errorMessage\n$st');
      return new OperationResult(errorCode, errorMessage);
    }
    if (benchmarkMode) {
      // Record time it took for the VM to reload the sources.
      vmReloadTimer.stop();
      benchmarkData['hotReloadVMReloadMilliseconds'] =
          vmReloadTimer.elapsed.inMilliseconds;
    }
    if (benchmarkMode)
      reassembleTimer.start();
    // Reload the isolate.
    await currentView.uiIsolate.reload();
    // We are now running from source.
    _runningFromSnapshot = false;
    // Check if the isolate is paused.
    final ServiceEvent pauseEvent = currentView.uiIsolate.pauseEvent;
    if ((pauseEvent != null) && (pauseEvent.isPauseEvent)) {
      // Isolate is paused. Stop here.
      printTrace('Skipping reassemble because isolate is paused.');
      return new OperationResult(OperationResult.ok.code, reloadMessage);
    }
    await _evictDirtyAssets();
    printTrace('Reassembling application');
    try {
      await currentView.uiIsolate.flutterReassemble();
    } catch (_) {
      printError('Reassembling application failed.');
      return new OperationResult(1, 'error reassembling application');
    }
    try {
      /* ensure that a frame is scheduled */
      await currentView.uiIsolate.uiWindowScheduleFrame();
    } catch (_) {
      /* ignore any errors */
    }
    reloadTimer.stop();
    printTrace('Hot reload performed in '
               '${getElapsedAsMilliseconds(reloadTimer.elapsed)}.');

    if (benchmarkMode) {
      // Record time it took for Flutter to reassemble the application.
      reassembleTimer.stop();
      benchmarkData['hotReloadFlutterReassembleMilliseconds'] =
          reassembleTimer.elapsed.inMilliseconds;
      // Record complete time it took for the reload.
      benchmarkData['hotReloadMillisecondsToFrame'] =
          reloadTimer.elapsed.inMilliseconds;
    }
    if (shouldReportReloadTime)
      flutterUsage.sendTiming('hot', 'reload', reloadTimer.elapsed);
    return new OperationResult(OperationResult.ok.code, reloadMessage);
  }

  @override
  void printHelp({ @required bool details }) {
    const String fire = '🔥';
    const String red = '\u001B[31m';
    const String bold = '\u001B[0;1m';
    const String reset = '\u001B[0m';
    printStatus(
      '$fire  To hot reload your app on the fly, press "r" or F5. To restart the app entirely, press "R".',
      ansiAlternative: '$red$fire$bold  To hot reload your app on the fly, '
                       'press "r" or F5. To restart the app entirely, press "R".$reset'
    );
    printStatus('The Observatory debugger and profiler is available at: $_observatoryUri');
    if (details) {
      printHelpDetails();
      printStatus('To repeat this help message, press "h" or F1. To quit, press "q", F10, or Ctrl-C.');
    } else {
      printStatus('For a more detailed help message, press "h" or F1. To quit, press "q", F10, or Ctrl-C.');
    }
  }

  @override
  Future<Null> cleanupAfterSignal() async {
    await stopEchoingDeviceLog();
    await stopApp();
  }

  @override
  Future<Null> preStop() => _cleanupDevFS();

  @override
  Future<Null> cleanupAtFinish() async {
    await _cleanupDevFS();
    await stopEchoingDeviceLog();
  }
}

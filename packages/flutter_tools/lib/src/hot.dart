// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'application_package.dart';
import 'asset.dart';
import 'base/logger.dart';
import 'base/process.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'cache.dart';
import 'commands/build_apk.dart';
import 'commands/install.dart';
import 'dart/package_map.dart';
import 'devfs.dart';
import 'device.dart';
import 'globals.dart';
import 'resident_runner.dart';
import 'toolchain.dart';
import 'vmservice.dart';

const bool kHotReloadDefault = true;

String getDevFSLoaderScript() {
  return path.absolute(path.join(Cache.flutterRoot,
                                 'packages',
                                 'flutter',
                                 'bin',
                                 'loader',
                                 'loader_app.dart'));
}

class StartupDependencySetBuilder {
  StartupDependencySetBuilder(this.mainScriptPath,
                              this.projectRootPath);

  final String mainScriptPath;
  final String projectRootPath;

  Set<String> build() {
    final String skySnapshotPath =
        ToolConfiguration.instance.getHostToolPath(HostTool.SkySnapshot);

    final List<String> args = <String>[
      skySnapshotPath,
      '--packages=${path.absolute(PackageMap.globalPackagesPath)}',
      '--print-deps',
      mainScriptPath
    ];

    String output;
    try {
      output = runCheckedSync(args);
    } catch (e) {
      return null;
    }

    final List<String> lines = LineSplitter.split(output).toList();
    final Set<String> minimalDependencies = new Set<String>();
    for (String line in lines) {
      // We need to convert the uris so that they are relative to the project
      // root and tweak package: uris so that they reflect their devFS location.
      if (line.startsWith('package:')) {
        // Swap out package: for packages/ because we place all package sources
        // under packages/.
        line = line.replaceFirst('package:', 'packages/');
      } else {
        // Ensure paths are relative to the project root.
        line = path.relative(line, from: projectRootPath);
      }
      minimalDependencies.add(line);
    }
    return minimalDependencies;
  }
}


class FirstFrameTimer {
  FirstFrameTimer(this.vmService);

  void start() {
    stopwatch.reset();
    stopwatch.start();
    _subscription = vmService.onExtensionEvent.listen(_onExtensionEvent);
  }

  /// Returns a Future which completes after the first frame event is received.
  Future<Null> firstFrame() => _completer.future;

  void _onExtensionEvent(ServiceEvent event) {
    if (event.extensionKind == 'Flutter.FirstFrame')
      _stop();
  }

  void _stop() {
    _subscription?.cancel();
    _subscription = null;
    stopwatch.stop();
    _completer.complete(null);
  }

  Duration get elapsed {
    assert(!stopwatch.isRunning);
    return stopwatch.elapsed;
  }

  final VMService vmService;
  final Stopwatch stopwatch = new Stopwatch();
  final Completer<Null> _completer = new Completer<Null>();
  StreamSubscription<ServiceEvent> _subscription;
}

class HotRunner extends ResidentRunner {
  HotRunner(
    Device device, {
    String target,
    DebuggingOptions debuggingOptions,
    bool usesTerminalUI: true,
    this.benchmarkMode: false,
  }) : super(device,
             target: target,
             debuggingOptions: debuggingOptions,
             usesTerminalUI: usesTerminalUI) {
    _projectRootPath = Directory.current.path;
  }

  ApplicationPackage _package;
  String _mainPath;
  String _projectRootPath;
  Set<String> _startupDependencies;
  final AssetBundle bundle = new AssetBundle();
  final bool benchmarkMode;
  final Map<String, int> benchmarkData = new Map<String, int>();

  @override
  Future<int> run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    String route,
    bool shouldBuild: true
  }) {
    // Don't let uncaught errors kill the process.
    return runZoned(() {
      return _run(
        connectionInfoCompleter: connectionInfoCompleter,
        route: route,
        shouldBuild: shouldBuild
      );
    }, onError: (dynamic error, StackTrace stackTrace) {
      printError('Exception from flutter run: $error', stackTrace);
    });
  }

  Future<int> _run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    String route,
    bool shouldBuild: true
  }) async {
    _mainPath = findMainDartFile(target);
    if (!FileSystemEntity.isFileSync(_mainPath)) {
      String message = 'Tried to run $_mainPath, but that file does not exist.';
      if (target == null)
        message += '\nConsider using the -t option to specify the Dart file to start.';
      printError(message);
      return 1;
    }

    _package = getApplicationPackageForPlatform(device.platform);

    if (_package == null) {
      String message = 'No application found for ${device.platform}.';
      String hint = getMissingPackageHintForPlatform(device.platform);
      if (hint != null)
        message += '\n$hint';
      printError(message);
      return 1;
    }

    // TODO(devoncarew): We shouldn't have to do type checks here.
    if (shouldBuild && device is AndroidDevice) {
      printTrace('Running build command.');

      int result = await buildApk(
        device.platform,
        target: target,
        buildMode: debuggingOptions.buildMode
      );

      if (result != 0)
        return result;
    }

    // TODO(devoncarew): Move this into the device.startApp() impls.
    if (_package != null) {
      printTrace("Stopping app '${_package.name}' on ${device.name}.");
      // We don't wait for the stop command to complete.
      device.stopApp(_package);
    }

    // Allow any stop commands from above to start work.
    await new Future<Duration>.delayed(Duration.ZERO);

    // TODO(devoncarew): This fails for ios devices - we haven't built yet.
    if (device is AndroidDevice) {
      printTrace('Running install command.');
      if (!(installApp(device, _package, uninstall: false)))
        return 1;
    }

    Map<String, dynamic> platformArgs = new Map<String, dynamic>();

    await startEchoingDeviceLog();

    printStatus('Launching loader on ${device.name}...');

    // Start the loader.
    Future<LaunchResult> futureResult = device.startApp(
      _package,
      debuggingOptions.buildMode,
      mainPath: getDevFSLoaderScript(),
      debuggingOptions: debuggingOptions,
      platformArgs: platformArgs,
      route: route
    );

    // In parallel, compute the minimal dependency set.
    StartupDependencySetBuilder startupDependencySetBuilder =
        new StartupDependencySetBuilder(_mainPath, _projectRootPath);
    _startupDependencies = startupDependencySetBuilder.build();
    if (_startupDependencies == null) {
      printError('Error determining the set of Dart sources necessary to start '
                 'the application. Initial file upload may take a long time.');
    }

    LaunchResult result = await futureResult;

    if (!result.started) {
      printError('Error launching DevFS loader on ${device.name}.');
      await stopEchoingDeviceLog();
      return 2;
    }

    await connectToServiceProtocol(result.observatoryPort);

    try {
      Uri baseUri = await _initDevFS();
      if (connectionInfoCompleter != null) {
        connectionInfoCompleter.complete(
          new DebugConnectionInfo(result.observatoryPort, baseUri: baseUri.toString())
        );
      }
    } catch (error) {
      printError('Error initializing DevFS: $error');
      return 3;
    }
    _loaderShowMessage('Connecting...', progress: 0);
    bool devfsResult = await _updateDevFS(
      progressReporter: (int progress, int max) {
        if (progress % 10 == 0)
          _loaderShowMessage('Syncing files to device...', progress: progress, max: max);
      }
    );
    if (!devfsResult) {
      _loaderShowMessage('Failed.');
      printError('Could not perform initial file synchronization.');
      return 3;
    }

    await vmService.vm.refreshViews();
    printStatus('Connected to ${vmService.vm.mainView}.');

    printStatus('Running ${getDisplayPath(_mainPath)} on ${device.name}...');
    _loaderShowMessage('Launching...');
    await _launchFromDevFS(_package, _mainPath);

    printStatus('Application running.');

    setupTerminal();

    registerSignalHandlers();

    printTrace('Finishing file synchronization');
    // Finish the file sync now.
    await _updateDevFS();

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
      File benchmarkOutput = new File('hot_benchmark.json');
      benchmarkOutput.writeAsStringSync(toPrettyJson(benchmarkData));
    }

    return waitForAppToFinish();
  }

  @override
  Future<Null> handleTerminalCommand(String code) async {
    final String lower = code.toLowerCase();
    if ((lower == 'r') || (code == AnsiTerminal.KEY_F5)) {
      // F5, restart
      if ((code == 'r') || (code == AnsiTerminal.KEY_F5)) {
        // lower-case 'r'
        await _reloadSources();
      } else {
        // upper-case 'R'.
        await _restartFromSources();
      }
    }
  }

  void _loaderShowMessage(String message, { int progress, int max }) {
    currentView.uiIsolate.flutterLoaderShowMessage(message);
    if (progress != null) {
      currentView.uiIsolate.flutterLoaderSetProgress(progress.toDouble());
      currentView.uiIsolate.flutterLoaderSetProgressMax(max?.toDouble() ?? 0.0);
    } else {
      currentView.uiIsolate.flutterLoaderSetProgress(0.0);
      currentView.uiIsolate.flutterLoaderSetProgressMax(-1.0);
    }
  }

  DevFS _devFS;

  Future<Uri> _initDevFS() {
    String fsName = path.basename(_projectRootPath);
    _devFS = new DevFS(vmService,
                       fsName,
                       new Directory(_projectRootPath));
    return _devFS.create();
  }

  Future<bool> _updateDevFS({ DevFSProgressReporter progressReporter }) async {
    Status devFSStatus = logger.startProgress('Syncing files to device...');
    final bool rebuildBundle = bundle.needsBuild();
    if (rebuildBundle) {
      printTrace('Updating assets');
      await bundle.build();
    }
    await _devFS.update(progressReporter: progressReporter,
                        bundle: bundle,
                        bundleDirty: rebuildBundle,
                        fileFilter: _startupDependencies);
    devFSStatus.stop(showElapsedTime: true);
    // Clear the minimal set after the first sync.
    _startupDependencies = null;
    if (progressReporter != null)
      printStatus('Synced ${getSizeAsMB(_devFS.bytes)}.');
    else
      printTrace('Synced ${getSizeAsMB(_devFS.bytes)}.');
    return true;
  }

  Future<Null> _evictDirtyAssets() async {
    if (_devFS.dirtyAssetEntries.length == 0)
      return;
    if (currentView.uiIsolate == null)
      throw 'Application isolate not found';
    for (DevFSEntry entry in _devFS.dirtyAssetEntries) {
      await currentView.uiIsolate.flutterEvictAsset(entry.assetPath);
    }
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
    String entryPath = path.relative(mainScript, from: _projectRootPath);
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

  Future<Null> _restartFromSources() async {
    FirstFrameTimer firstFrameTimer = new FirstFrameTimer(vmService);
    firstFrameTimer.start();
    await _updateDevFS();
    await _launchFromDevFS(_package, _mainPath);
    bool waitForFrame =
        await currentView.uiIsolate.flutterFrameworkPresent();
    Status restartStatus =
        logger.startProgress('Waiting for application to start...');
    if (waitForFrame) {
      // Wait for the first frame to be rendered.
      await firstFrameTimer.firstFrame();
    }
    restartStatus.stop(showElapsedTime: true);
    if (waitForFrame) {
      printStatus('Restart performed in '
                  '${getElapsedAsMilliseconds(firstFrameTimer.elapsed)}.');
      if (benchmarkMode) {
        benchmarkData['hotRestartMillisecondsToFrame'] =
            firstFrameTimer.elapsed.inMilliseconds;
      }
      flutterUsage.sendTiming('hot', 'restart', firstFrameTimer.elapsed);
    }
    flutterUsage.sendEvent('hot', 'restart');
  }

  /// Returns [true] if the reload was successful.
  bool _printReloadReport(Map<String, dynamic> reloadReport) {
    if (!reloadReport['success']) {
      printError('Hot reload was rejected:');
      for (Map<String, dynamic> notice in reloadReport['details']['notices'])
        printError('${notice['message']}');
      return false;
    }
    int loadedLibraryCount = reloadReport['details']['loadedLibraryCount'];
    int finalLibraryCount = reloadReport['details']['finalLibraryCount'];
    printStatus('Reloaded $loadedLibraryCount of $finalLibraryCount libraries.');
    return true;
  }

  @override
  Future<bool> restart({ bool fullRestart: false }) async {
    if (fullRestart) {
      await _restartFromSources();
      return true;
    } else {
      return _reloadSources();
    }
  }

  Future<bool> _reloadSources() async {
    if (currentView.uiIsolate == null)
      throw 'Application isolate not found';
    FirstFrameTimer firstFrameTimer = new FirstFrameTimer(vmService);
    firstFrameTimer.start();
    if (_devFS != null)
      await _updateDevFS();
    Status reloadStatus = logger.startProgress('Performing hot reload...');
    try {
      Map<String, dynamic> reloadReport =
          await currentView.uiIsolate.reloadSources();
      reloadStatus.stop(showElapsedTime: true);
      if (!_printReloadReport(reloadReport)) {
        // Reload failed.
        flutterUsage.sendEvent('hot', 'reload-reject');
        return false;
      } else {
        flutterUsage.sendEvent('hot', 'reload');
      }
    } catch (error, st) {
      int errorCode = error['code'];
      if (errorCode == Isolate.kIsolateReloadBarred) {
        printError('Unable to hot reload app due to an unrecoverable error in '
                   'the source code. Please address the error and then '
                   'Use "R" to restart the app.');
        flutterUsage.sendEvent('hot', 'reload-barred');
        return false;
      }
      String errorMessage = error['message'];
      reloadStatus.stop(showElapsedTime: true);
      printError('Hot reload failed:\ncode = $errorCode\nmessage = $errorMessage\n$st');
      return false;
    }
    await _evictDirtyAssets();
    printTrace('Reassembling application');
    bool waitForFrame = true;
    try {
      waitForFrame = (await currentView.uiIsolate.flutterReassemble() != null);
    } catch (_) {
      printError('Reassembling application failed.');
      return false;
    }
    try {
      /* ensure that a frame is scheduled */
      await currentView.uiIsolate.uiWindowScheduleFrame();
    } catch (_) {
      /* ignore any errors */
    }
    if (waitForFrame) {
      // When the framework is present, we can wait for the first frame
      // event and measure reload itme.
      await firstFrameTimer.firstFrame();
      printStatus('Hot reload performed in '
                  '${getElapsedAsMilliseconds(firstFrameTimer.elapsed)}.');
      if (benchmarkMode) {
        benchmarkData['hotReloadMillisecondsToFrame'] =
            firstFrameTimer.elapsed.inMilliseconds;
      }
      flutterUsage.sendTiming('hot', 'reload', firstFrameTimer.elapsed);
    }
    return true;
  }

  @override
  void printHelp() {
    printStatus('Type "h" or F1 for this help message; type "q", F10, or ctrl-c to quit.', emphasis: true);
    printStatus('Type "r" or F5 to perform a hot reload of the app, and "R" to restart the app.', emphasis: true);
    printStatus('Type "w" to print the widget hierarchy of the app, and "t" for the render tree.', emphasis: true);
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

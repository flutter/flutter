// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:json_rpc_2/error_code.dart' as rpc_error_code;
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:meta/meta.dart';

import 'base/async_guard.dart';
import 'base/common.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/platform.dart';
import 'base/terminal.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'compile.dart';
import 'convert.dart';
import 'devfs.dart';
import 'device.dart';
import 'globals.dart';
import 'reporting/reporting.dart';
import 'resident_runner.dart';
import 'vmservice.dart';

class HotRunnerConfig {
  /// Should the hot runner assume that the minimal Dart dependencies do not change?
  bool stableDartDependencies = false;
  /// A hook for implementations to perform any necessary initialization prior
  /// to a hot restart. Should return true if the hot restart should continue.
  Future<bool> setupHotRestart() async {
    return true;
  }
  /// A hook for implementations to perform any necessary operations right
  /// before the runner is about to be shut down.
  Future<void> runPreShutdownOperations() async {
    return;
  }
}

HotRunnerConfig get hotRunnerConfig => context.get<HotRunnerConfig>();

const bool kHotReloadDefault = true;

class DeviceReloadReport {
  DeviceReloadReport(this.device, this.reports);

  FlutterDevice device;
  List<Map<String, dynamic>> reports; // List has one report per Flutter view.
}

// TODO(mklim): Test this, flutter/flutter#23031.
class HotRunner extends ResidentRunner {
  HotRunner(
    List<FlutterDevice> devices, {
    String target,
    DebuggingOptions debuggingOptions,
    this.benchmarkMode = false,
    this.applicationBinary,
    this.hostIsIde = false,
    String projectRootPath,
    String packagesFilePath,
    String dillOutputPath,
    bool stayResident = true,
    bool ipv6 = false,
  }) : super(devices,
             target: target,
             debuggingOptions: debuggingOptions,
             projectRootPath: projectRootPath,
             packagesFilePath: packagesFilePath,
             stayResident: stayResident,
             hotMode: true,
             dillOutputPath: dillOutputPath,
             ipv6: ipv6);

  final bool benchmarkMode;
  final File applicationBinary;
  final bool hostIsIde;
  bool _didAttach = false;

  final Map<String, List<int>> benchmarkData = <String, List<int>>{};
  // The initial launch is from a snapshot.
  bool _runningFromSnapshot = true;
  DateTime firstBuildTime;

  void _addBenchmarkData(String name, int value) {
    benchmarkData[name] ??= <int>[];
    benchmarkData[name].add(value);
  }

  Future<void> _reloadSourcesService(
    String isolateId, {
    bool force = false,
    bool pause = false,
  }) async {
    // TODO(cbernaschina): check that isolateId is the id of the UI isolate.
    final OperationResult result = await restart(pauseAfterRestart: pause);
    if (!result.isOk) {
      throw rpc.RpcException(
        rpc_error_code.INTERNAL_ERROR,
        'Unable to reload sources',
      );
    }
  }

  Future<void> _restartService({ bool pause = false }) async {
    final OperationResult result =
      await restart(fullRestart: true, pauseAfterRestart: pause);
    if (!result.isOk) {
      throw rpc.RpcException(
        rpc_error_code.INTERNAL_ERROR,
        'Unable to restart',
      );
    }
  }

  Future<String> _compileExpressionService(
    String isolateId,
    String expression,
    List<String> definitions,
    List<String> typeDefinitions,
    String libraryUri,
    String klass,
    bool isStatic,
  ) async {
    for (FlutterDevice device in flutterDevices) {
      if (device.generator != null) {
        final CompilerOutput compilerOutput =
            await device.generator.compileExpression(expression, definitions,
                typeDefinitions, libraryUri, klass, isStatic);
        if (compilerOutput != null && compilerOutput.outputFilename != null) {
          return base64.encode(fs.file(compilerOutput.outputFilename).readAsBytesSync());
        }
      }
    }
    throw 'Failed to compile $expression';
  }

  // Returns the exit code of the flutter tool process, like [run].
  @override
  Future<int> attach({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
  }) async {
    _didAttach = true;
    try {
      await connectToServiceProtocol(
        reloadSources: _reloadSourcesService,
        restart: _restartService,
        compileExpression: _compileExpressionService,
      );
    } catch (error) {
      printError('Error connecting to the service protocol: $error');
      // https://github.com/flutter/flutter/issues/33050
      // TODO(blasten): Remove this check once https://issuetracker.google.com/issues/132325318 has been fixed.
      if (await hasDeviceRunningAndroidQ(flutterDevices) &&
          error.toString().contains(kAndroidQHttpConnectionClosedExp)) {
        printStatus('🔨 If you are using an emulator running Android Q Beta, consider using an emulator running API level 29 or lower.');
        printStatus('Learn more about the status of this issue on https://issuetracker.google.com/issues/132325318.');
      }
      return 2;
    }

    for (FlutterDevice device in flutterDevices)
      device.initLogReader();
    try {
      final List<Uri> baseUris = await _initDevFS();
      if (connectionInfoCompleter != null) {
        // Only handle one debugger connection.
        connectionInfoCompleter.complete(
          DebugConnectionInfo(
            httpUri: flutterDevices.first.observatoryUris.first,
            wsUri: flutterDevices.first.vmServices.first.wsAddress,
            baseUri: baseUris.first.toString(),
          )
        );
      }
    } catch (error) {
      printError('Error initializing DevFS: $error');
      return 3;
    }
    final Stopwatch initialUpdateDevFSsTimer = Stopwatch()..start();
    final UpdateFSReport devfsResult = await _updateDevFS(fullRestart: true);
    _addBenchmarkData(
      'hotReloadInitialDevFSSyncMilliseconds',
      initialUpdateDevFSsTimer.elapsed.inMilliseconds,
    );
    if (!devfsResult.success)
      return 3;

    await refreshViews();
    for (FlutterDevice device in flutterDevices) {
      // VM must have accepted the kernel binary, there will be no reload
      // report, so we let incremental compiler know that source code was accepted.
      if (device.generator != null)
        device.generator.accept();
      for (FlutterView view in device.views)
        printTrace('Connected to $view.');
    }

    appStartedCompleter?.complete();

    if (benchmarkMode) {
      // We are running in benchmark mode.
      printStatus('Running in benchmark mode.');
      // Measure time to perform a hot restart.
      printStatus('Benchmarking hot restart');
      await restart(fullRestart: true, benchmarkMode: true);
      printStatus('Benchmarking hot reload');
      // Measure time to perform a hot reload.
      await restart(fullRestart: false);
      if (stayResident) {
        await waitForAppToFinish();
      } else {
        printStatus('Benchmark completed. Exiting application.');
        await _cleanupDevFS();
        await stopEchoingDeviceLog();
        await exitApp();
      }
      final File benchmarkOutput = fs.file('hot_benchmark.json');
      benchmarkOutput.writeAsStringSync(toPrettyJson(benchmarkData));
      return 0;
    }

    int result = 0;
    if (stayResident)
      result = await waitForAppToFinish();
    await cleanupAtFinish();
    return result;
  }

  @override
  Future<int> run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
    String route,
  }) async {
    if (!fs.isFileSync(mainPath)) {
      String message = 'Tried to run $mainPath, but that file does not exist.';
      if (target == null)
        message += '\nConsider using the -t option to specify the Dart file to start.';
      printError(message);
      return 1;
    }

    firstBuildTime = DateTime.now();

    for (FlutterDevice device in flutterDevices) {
      final int result = await device.runHot(
        hotRunner: this,
        route: route,
      );
      if (result != 0) {
        return result;
      }
    }

    return attach(
      connectionInfoCompleter: connectionInfoCompleter,
      appStartedCompleter: appStartedCompleter,
    );
  }

  Future<List<Uri>> _initDevFS() async {
    final String fsName = fs.path.basename(projectRootPath);
    final List<Uri> devFSUris = <Uri>[];
    for (FlutterDevice device in flutterDevices) {
      final Uri uri = await device.setupDevFS(
        fsName,
        fs.directory(projectRootPath),
        packagesFilePath: packagesFilePath,
      );
      devFSUris.add(uri);
    }
    return devFSUris;
  }

  Future<UpdateFSReport> _updateDevFS({ bool fullRestart = false }) async {
    final bool isFirstUpload = assetBundle.wasBuiltOnce() == false;
    final bool rebuildBundle = assetBundle.needsBuild();
    if (rebuildBundle) {
      printTrace('Updating assets');
      final int result = await assetBundle.build();
      if (result != 0)
        return UpdateFSReport(success: false);
    }

    // Picking up first device's compiler as a source of truth - compilers
    // for all devices should be in sync.
    final List<Uri> invalidatedFiles = ProjectFileInvalidator.findInvalidated(
      lastCompiled: flutterDevices[0].devFS.lastCompiled,
      urisToMonitor: flutterDevices[0].devFS.sources,
      packagesPath: packagesFilePath,
    );
    final UpdateFSReport results = UpdateFSReport(success: true);
    for (FlutterDevice device in flutterDevices) {
      results.incorporateResults(await device.updateDevFS(
        mainPath: mainPath,
        target: target,
        bundle: assetBundle,
        firstBuildTime: firstBuildTime,
        bundleFirstUpload: isFirstUpload,
        bundleDirty: isFirstUpload == false && rebuildBundle,
        fullRestart: fullRestart,
        projectRootPath: projectRootPath,
        pathToReload: getReloadPath(fullRestart: fullRestart),
        invalidatedFiles: invalidatedFiles,
        dillOutputPath: dillOutputPath,
      ));
    }
    return results;
  }

  void _resetDirtyAssets() {
    for (FlutterDevice device in flutterDevices)
      device.devFS.assetPathsToEvict.clear();
  }

  Future<void> _cleanupDevFS() async {
    final List<Future<void>> futures = <Future<void>>[];
    for (FlutterDevice device in flutterDevices) {
      if (device.devFS != null) {
        // Cleanup the devFS, but don't wait indefinitely.
        // We ignore any errors, because it's not clear what we would do anyway.
        futures.add(device.devFS.destroy()
          .timeout(const Duration(milliseconds: 250))
          .catchError((dynamic error) {
            printTrace('Ignored error while cleaning up DevFS: $error');
          }));
      }
      device.devFS = null;
    }
    await Future.wait(futures);
  }

  Future<void> _launchInView(
    FlutterDevice device,
    Uri entryUri,
    Uri packagesUri,
    Uri assetsDirectoryUri,
  ) {
    final List<Future<void>> futures = <Future<void>>[];
    for (FlutterView view in device.views)
      futures.add(view.runFromSource(entryUri, packagesUri, assetsDirectoryUri));
    final Completer<void> completer = Completer<void>();
    Future.wait(futures).whenComplete(() { completer.complete(null); });
    return completer.future;
  }

  Future<void> _launchFromDevFS(String mainScript) async {
    final String entryUri = fs.path.relative(mainScript, from: projectRootPath);
    final List<Future<void>> futures = <Future<void>>[];
    for (FlutterDevice device in flutterDevices) {
      final Uri deviceEntryUri = device.devFS.baseUri.resolveUri(
        fs.path.toUri(entryUri));
      final Uri devicePackagesUri = device.devFS.baseUri.resolve('.packages');
      final Uri deviceAssetsDirectoryUri = device.devFS.baseUri.resolveUri(
        fs.path.toUri(getAssetBuildDirectory()));
      futures.add(_launchInView(device,
                          deviceEntryUri,
                          devicePackagesUri,
                          deviceAssetsDirectoryUri));
    }
    await Future.wait(futures);
    if (benchmarkMode) {
      futures.clear();
      for (FlutterDevice device in flutterDevices)
        for (FlutterView view in device.views)
          futures.add(view.flushUIThreadTasks());
      await Future.wait(futures);
    }
  }

  Future<OperationResult> _restartFromSources({
    String reason,
    bool benchmarkMode = false
  }) async {
    if (!_isPaused()) {
      printTrace('Refreshing active FlutterViews before restarting.');
      await refreshViews();
    }

    final Stopwatch restartTimer = Stopwatch()..start();
    // TODO(aam): Add generator reset logic once we switch to using incremental
    // compiler for full application recompilation on restart.
    final UpdateFSReport updatedDevFS = await _updateDevFS(fullRestart: true);
    if (!updatedDevFS.success) {
      for (FlutterDevice device in flutterDevices) {
        if (device.generator != null) {
          await device.generator.reject();
        }
      }
      return OperationResult(1, 'DevFS synchronization failed');
    }
    _resetDirtyAssets();
    for (FlutterDevice device in flutterDevices) {
      // VM must have accepted the kernel binary, there will be no reload
      // report, so we let incremental compiler know that source code was accepted.
      if (device.generator != null) {
        device.generator.accept();
      }
    }
    // Check if the isolate is paused and resume it.
    final List<Future<void>> futures = <Future<void>>[];
    for (FlutterDevice device in flutterDevices) {
      for (FlutterView view in device.views) {
        if (view.uiIsolate == null) {
          continue;
        }
        // Reload the isolate.
        final Completer<void> completer = Completer<void>();
        futures.add(completer.future);
        unawaited(view.uiIsolate.reload().then(
          (ServiceObject _) {
            final ServiceEvent pauseEvent = view.uiIsolate.pauseEvent;
            if ((pauseEvent != null) && pauseEvent.isPauseEvent) {
              // Resume the isolate so that it can be killed by the embedder.
              return view.uiIsolate.resume();
            }
            return null;
          },
        ).whenComplete(
          () { completer.complete(null); },
        ));
      }
    }
    await Future.wait(futures);
    // We are now running from source.
    _runningFromSnapshot = false;
    await _launchFromDevFS(mainPath + '.dill');
    restartTimer.stop();
    printTrace('Hot restart performed in ${getElapsedAsMilliseconds(restartTimer.elapsed)}.');
    // We are now running from sources.
    _runningFromSnapshot = false;
    _addBenchmarkData('hotRestartMillisecondsToFrame',
        restartTimer.elapsed.inMilliseconds);

    // Send timing analytics.
    flutterUsage.sendTiming('hot', 'restart', restartTimer.elapsed);

    // In benchmark mode, make sure all stream notifications have finished.
    if (benchmarkMode) {
      final List<Future<void>> isolateNotifications = <Future<void>>[];
      for (FlutterDevice device in flutterDevices) {
        for (FlutterView view in device.views) {
          isolateNotifications.add(
            view.owner.vm.vmService.onIsolateEvent.then((Stream<ServiceEvent> serviceEvents) async {
              await for (ServiceEvent serviceEvent in serviceEvents) {
                if (serviceEvent.owner.name.contains('_spawn') && serviceEvent.kind == ServiceEvent.kIsolateExit) {
                  return;
                }
              }
            }),
          );
        }
      }
      await Future.wait(isolateNotifications);
    }
    return OperationResult.ok;
  }

  /// Returns [true] if the reload was successful.
  /// Prints errors if [printErrors] is [true].
  static bool validateReloadReport(
    Map<String, dynamic> reloadReport, {
    bool printErrors = true,
  }) {
    if (reloadReport == null) {
      if (printErrors)
        printError('Hot reload did not receive reload report.');
      return false;
    }
    if (!(reloadReport['type'] == 'ReloadReport' &&
          (reloadReport['success'] == true ||
           (reloadReport['success'] == false &&
            (reloadReport['details'] is Map<String, dynamic> &&
             reloadReport['details']['notices'] is List<dynamic> &&
             reloadReport['details']['notices'].isNotEmpty &&
             reloadReport['details']['notices'].every(
               (dynamic item) => item is Map<String, dynamic> && item['message'] is String
             )
            )
           )
          )
         )) {
      if (printErrors)
        printError('Hot reload received invalid response: $reloadReport');
      return false;
    }
    if (!reloadReport['success']) {
      if (printErrors) {
        printError('Hot reload was rejected:');
        for (Map<String, dynamic> notice in reloadReport['details']['notices'])
          printError('${notice['message']}');
      }
      return false;
    }
    return true;
  }

  @override
  bool get supportsRestart => true;

  @override
  Future<OperationResult> restart({
    bool fullRestart = false,
    bool pauseAfterRestart = false,
    String reason,
    bool benchmarkMode = false
  }) async {
    String targetPlatform;
    String sdkName;
    bool emulator;
    if (flutterDevices.length == 1) {
      final Device device = flutterDevices.first.device;
      targetPlatform = getNameForTargetPlatform(await device.targetPlatform);
      sdkName = await device.sdkNameAndVersion;
      emulator = await device.isLocalEmulator;
    } else if (flutterDevices.length > 1) {
      targetPlatform = 'multiple';
      sdkName = 'multiple';
      emulator = false;
    } else {
      targetPlatform = 'unknown';
      sdkName = 'unknown';
      emulator = false;
    }
    final Stopwatch timer = Stopwatch()..start();
    if (fullRestart) {
      final OperationResult result = await _fullRestartHelper(
        targetPlatform: targetPlatform,
        sdkName: sdkName,
        emulator: emulator,
        reason: reason,
        benchmarkMode: benchmarkMode,
      );
      printStatus('Restarted application in ${getElapsedAsMilliseconds(timer.elapsed)}.');
      return result;
    }
    final OperationResult result = await _hotReloadHelper(
      targetPlatform: targetPlatform,
      sdkName: sdkName,
      emulator: emulator,
      reason: reason,
      pauseAfterRestart: pauseAfterRestart,
    );
    if (result.isOk) {
      final String elapsed = getElapsedAsMilliseconds(timer.elapsed);
      printStatus('${result.message} in $elapsed.');
    }
    return result;
  }

  Future<OperationResult> _fullRestartHelper({
    String targetPlatform,
    String sdkName,
    bool emulator,
    String reason,
    bool benchmarkMode,
  }) async {
    if (!canHotRestart) {
      return OperationResult(1, 'hotRestart not supported');
    }
    final Status status = logger.startProgress(
      'Performing hot restart...',
      timeout: timeoutConfiguration.fastOperation,
      progressId: 'hot.restart',
    );
    OperationResult result;
    String restartEvent = 'restart';
    try {
      if (!(await hotRunnerConfig.setupHotRestart())) {
        return OperationResult(1, 'setupHotRestart failed');
      }
      // The current implementation of the vmservice and JSON rpc may throw
      // unhandled exceptions into the zone that cannot be caught with a regular
      // try catch. The usage is [asyncGuard] is required to normalize the error
      // handling, at least until we can refactor the underlying code.
      result = await asyncGuard(() => _restartFromSources(
        reason: reason,
        benchmarkMode: benchmarkMode,
      ));
      if (!result.isOk) {
        restartEvent = 'restart-failed';
      }
    } on rpc.RpcException {
      restartEvent = 'exception';
      return OperationResult(1, 'hot restart failed to complete', fatal: true);
    } finally {
      HotEvent(restartEvent,
        targetPlatform: targetPlatform,
        sdkName: sdkName,
        emulator: emulator,
        fullRestart: true,
        reason: reason).send();
      status.cancel();
    }
    return result;
  }

  Future<OperationResult> _hotReloadHelper({
    String targetPlatform,
    String sdkName,
    bool emulator,
    String reason,
    bool pauseAfterRestart = false,
  }) async {
    final bool reloadOnTopOfSnapshot = _runningFromSnapshot;
    final String progressPrefix = reloadOnTopOfSnapshot ? 'Initializing' : 'Performing';
    Status status = logger.startProgress(
      '$progressPrefix hot reload...',
      timeout: timeoutConfiguration.fastOperation,
      progressId: 'hot.reload',
    );
    OperationResult result;
    try {
      result = await _reloadSources(
        targetPlatform: targetPlatform,
        sdkName: sdkName,
        emulator: emulator,
        pause: pauseAfterRestart,
        reason: reason,
        onSlow: (String message) {
          status?.cancel();
          status = logger.startProgress(
            message,
            timeout: timeoutConfiguration.slowOperation,
            progressId: 'hot.reload',
          );
        },
      );
    } on rpc.RpcException {
      HotEvent('exception',
        targetPlatform: targetPlatform,
        sdkName: sdkName,
        emulator: emulator,
        fullRestart: false,
        reason: reason).send();
      return OperationResult(1, 'hot reload failed to complete', fatal: true);
    } finally {
      status.cancel();
    }
    return result;
  }

  Future<OperationResult> _reloadSources({
    String targetPlatform,
    String sdkName,
    bool emulator,
    bool pause = false,
    String reason,
    void Function(String message) onSlow
  }) async {
    for (FlutterDevice device in flutterDevices) {
      for (FlutterView view in device.views) {
        if (view.uiIsolate == null) {
          return OperationResult(2, 'Application isolate not found', fatal: true);
        }
      }
    }

    // The initial launch is from a script snapshot. When we reload from source
    // on top of a script snapshot, the first reload will be a worst case reload
    // because all of the sources will end up being dirty (library paths will
    // change from host path to a device path). Subsequent reloads will
    // not be affected, so we resume reporting reload times on the second
    // reload.
    bool shouldReportReloadTime = !_runningFromSnapshot;
    final Stopwatch reloadTimer = Stopwatch()..start();

    if (!_isPaused()) {
      printTrace('Refreshing active FlutterViews before reloading.');
      await refreshViews();
    }

    final Stopwatch devFSTimer = Stopwatch()..start();
    final UpdateFSReport updatedDevFS = await _updateDevFS();
    // Record time it took to synchronize to DevFS.
    _addBenchmarkData('hotReloadDevFSSyncMilliseconds', devFSTimer.elapsed.inMilliseconds);
    if (!updatedDevFS.success) {
      return OperationResult(1, 'DevFS synchronization failed');
    }
    String reloadMessage;
    final Stopwatch vmReloadTimer = Stopwatch()..start();
    Map<String, dynamic> firstReloadDetails;
    try {
      final String entryPath = fs.path.relative(
        getReloadPath(fullRestart: false),
        from: projectRootPath,
      );
      final List<Future<DeviceReloadReport>> allReportsFutures = <Future<DeviceReloadReport>>[];
      for (FlutterDevice device in flutterDevices) {
        if (_runningFromSnapshot) {
          // Asset directory has to be set only once when we switch from
          // running from snapshot to running from uploaded files.
          await device.resetAssetDirectory();
        }
        final Completer<DeviceReloadReport> completer = Completer<DeviceReloadReport>();
        allReportsFutures.add(completer.future);
        final List<Future<Map<String, dynamic>>> reportFutures = device.reloadSources(
          entryPath, pause: pause,
        );
        unawaited(Future.wait(reportFutures).then(
          (List<Map<String, dynamic>> reports) async {
            // TODO(aam): Investigate why we are validating only first reload report,
            // which seems to be current behavior
            final Map<String, dynamic> firstReport = reports.first;
            // Don't print errors because they will be printed further down when
            // `validateReloadReport` is called again.
            await device.updateReloadStatus(
              validateReloadReport(firstReport, printErrors: false),
            );
            completer.complete(DeviceReloadReport(device, reports));
          },
        ));
      }
      final List<DeviceReloadReport> reports = await Future.wait(allReportsFutures);
      for (DeviceReloadReport report in reports) {
        final Map<String, dynamic> reloadReport = report.reports[0];
        if (!validateReloadReport(reloadReport)) {
          // Reload failed.
          HotEvent('reload-reject',
            targetPlatform: targetPlatform,
            sdkName: sdkName,
            emulator: emulator,
            fullRestart: false,
            reason: reason,
          ).send();
          return OperationResult(1, 'Reload rejected');
        }
        // Collect stats only from the first device. If/when run -d all is
        // refactored, we'll probably need to send one hot reload/restart event
        // per device to analytics.
        firstReloadDetails ??= reloadReport['details'];
        final int loadedLibraryCount = reloadReport['details']['loadedLibraryCount'];
        final int finalLibraryCount = reloadReport['details']['finalLibraryCount'];
        printTrace('reloaded $loadedLibraryCount of $finalLibraryCount libraries');
        reloadMessage = 'Reloaded $loadedLibraryCount of $finalLibraryCount libraries';
      }
    } on Map<String, dynamic> catch (error, stackTrace) {
      printTrace('Hot reload failed: $error\n$stackTrace');
      final int errorCode = error['code'];
      String errorMessage = error['message'];
      if (errorCode == Isolate.kIsolateReloadBarred) {
        errorMessage = 'Unable to hot reload application due to an unrecoverable error in '
                       'the source code. Please address the error and then use "R" to '
                       'restart the app.\n'
                       '$errorMessage (error code: $errorCode)';
        HotEvent('reload-barred',
          targetPlatform: targetPlatform,
          sdkName: sdkName,
          emulator: emulator,
          fullRestart: false,
          reason: reason,
        ).send();
        return OperationResult(errorCode, errorMessage);
      }
      return OperationResult(errorCode, '$errorMessage (error code: $errorCode)');
    } catch (error, stackTrace) {
      printTrace('Hot reload failed: $error\n$stackTrace');
      return OperationResult(1, '$error');
    }
    // Record time it took for the VM to reload the sources.
    _addBenchmarkData('hotReloadVMReloadMilliseconds', vmReloadTimer.elapsed.inMilliseconds);
    final Stopwatch reassembleTimer = Stopwatch()..start();
    // Reload the isolate.
    final List<Future<void>> allDevices = <Future<void>>[];
    for (FlutterDevice device in flutterDevices) {
      printTrace('Sending reload events to ${device.device.name}');
      final List<Future<ServiceObject>> futuresViews = <Future<ServiceObject>>[];
      for (FlutterView view in device.views) {
        printTrace('Sending reload event to "${view.uiIsolate.name}"');
        futuresViews.add(view.uiIsolate.reload());
      }
      final Completer<void> deviceCompleter = Completer<void>();
      unawaited(Future.wait(futuresViews).whenComplete(() {
        deviceCompleter.complete(device.refreshViews());
      }));
      allDevices.add(deviceCompleter.future);
    }
    await Future.wait(allDevices);
    // We are now running from source.
    _runningFromSnapshot = false;
    // Check if any isolates are paused.
    final List<FlutterView> reassembleViews = <FlutterView>[];
    String serviceEventKind;
    int pausedIsolatesFound = 0;
    for (FlutterDevice device in flutterDevices) {
      for (FlutterView view in device.views) {
        // Check if the isolate is paused, and if so, don't reassemble. Ignore the
        // PostPauseEvent event - the client requesting the pause will resume the app.
        final ServiceEvent pauseEvent = view.uiIsolate.pauseEvent;
        if (pauseEvent != null && pauseEvent.isPauseEvent && pauseEvent.kind != ServiceEvent.kPausePostRequest) {
          pausedIsolatesFound += 1;
          if (serviceEventKind == null) {
            serviceEventKind = pauseEvent.kind;
          } else if (serviceEventKind != pauseEvent.kind) {
            serviceEventKind = ''; // many kinds
          }
        } else {
          reassembleViews.add(view);
        }
      }
    }
    if (pausedIsolatesFound > 0) {
      if (onSlow != null)
        onSlow('${_describePausedIsolates(pausedIsolatesFound, serviceEventKind)}; interface might not update.');
      if (reassembleViews.isEmpty) {
        printTrace('Skipping reassemble because all isolates are paused.');
        return OperationResult(OperationResult.ok.code, reloadMessage);
      }
    }
    printTrace('Evicting dirty assets');
    await _evictDirtyAssets();
    assert(reassembleViews.isNotEmpty);
    printTrace('Reassembling application');
    bool failedReassemble = false;
    final List<Future<void>> futures = <Future<void>>[];
    for (FlutterView view in reassembleViews) {
      futures.add(() async {
        try {
          await view.uiIsolate.flutterReassemble();
        } catch (error) {
          failedReassemble = true;
          printError('Reassembling ${view.uiIsolate.name} failed: $error');
          return;
        }
      }());
    }
    final Future<void> reassembleFuture = Future.wait<void>(futures).then<void>((List<void> values) { });
    await reassembleFuture.timeout(
      const Duration(seconds: 2),
      onTimeout: () async {
        if (pausedIsolatesFound > 0) {
          shouldReportReloadTime = false;
          return; // probably no point waiting, they're probably deadlocked and we've already warned.
        }
        // Check if any isolate is newly paused.
        printTrace('This is taking a long time; will now check for paused isolates.');
        int postReloadPausedIsolatesFound = 0;
        String serviceEventKind;
        for (FlutterView view in reassembleViews) {
          await view.uiIsolate.reload();
          final ServiceEvent pauseEvent = view.uiIsolate.pauseEvent;
          if (pauseEvent != null && pauseEvent.isPauseEvent) {
            postReloadPausedIsolatesFound += 1;
            if (serviceEventKind == null) {
              serviceEventKind = pauseEvent.kind;
            } else if (serviceEventKind != pauseEvent.kind) {
              serviceEventKind = ''; // many kinds
            }
          }
        }
        printTrace('Found $postReloadPausedIsolatesFound newly paused isolate(s).');
        if (postReloadPausedIsolatesFound == 0) {
          await reassembleFuture; // must just be taking a long time... keep waiting!
          return;
        }
        shouldReportReloadTime = false;
        if (onSlow != null)
          onSlow('${_describePausedIsolates(postReloadPausedIsolatesFound, serviceEventKind)}.');
      },
    );
    // Record time it took for Flutter to reassemble the application.
    _addBenchmarkData('hotReloadFlutterReassembleMilliseconds', reassembleTimer.elapsed.inMilliseconds);

    reloadTimer.stop();
    final Duration reloadDuration = reloadTimer.elapsed;
    final int reloadInMs = reloadDuration.inMilliseconds;

    // Collect stats that help understand scale of update for this hot reload request.
    // For example, [syncedLibraryCount]/[finalLibraryCount] indicates how
    // many libraries were affected by the hot reload request.
    // Relation of [invalidatedSourcesCount] to [syncedLibraryCount] should help
    // understand sync/transfer "overhead" of updating this number of source files.
    HotEvent('reload',
      targetPlatform: targetPlatform,
      sdkName: sdkName,
      emulator: emulator,
      fullRestart: false,
      reason: reason,
      overallTimeInMs: reloadInMs,
      finalLibraryCount: firstReloadDetails['finalLibraryCount'],
      syncedLibraryCount: firstReloadDetails['receivedLibraryCount'],
      syncedClassesCount: firstReloadDetails['receivedClassesCount'],
      syncedProceduresCount: firstReloadDetails['receivedProceduresCount'],
      syncedBytes: updatedDevFS.syncedBytes,
      invalidatedSourcesCount: updatedDevFS.invalidatedSourcesCount,
      transferTimeInMs: devFSTimer.elapsed.inMilliseconds,
    ).send();

    if (shouldReportReloadTime) {
      printTrace('Hot reload performed in ${getElapsedAsMilliseconds(reloadDuration)}.');
      // Record complete time it took for the reload.
      _addBenchmarkData('hotReloadMillisecondsToFrame', reloadInMs);
    }
    // Only report timings if we reloaded a single view without any errors.
    if ((reassembleViews.length == 1) && !failedReassemble && shouldReportReloadTime)
      flutterUsage.sendTiming('hot', 'reload', reloadDuration);
    return OperationResult(
      failedReassemble ? 1 : OperationResult.ok.code,
      reloadMessage,
    );
  }

  String _describePausedIsolates(int pausedIsolatesFound, String serviceEventKind) {
    assert(pausedIsolatesFound > 0);
    final StringBuffer message = StringBuffer();
    bool plural;
    if (pausedIsolatesFound == 1) {
      if (flutterDevices.length == 1 && flutterDevices.single.views.length == 1) {
        message.write('The application is ');
      } else {
        message.write('An isolate is ');
      }
      plural = false;
    } else {
      message.write('$pausedIsolatesFound isolates are ');
      plural = true;
    }
    assert(serviceEventKind != null);
    switch (serviceEventKind) {
      case ServiceEvent.kPauseStart: message.write('paused (probably due to --start-paused)'); break;
      case ServiceEvent.kPauseExit: message.write('paused because ${ plural ? 'they have' : 'it has' } terminated'); break;
      case ServiceEvent.kPauseBreakpoint: message.write('paused in the debugger on a breakpoint'); break;
      case ServiceEvent.kPauseInterrupted: message.write('paused due in the debugger'); break;
      case ServiceEvent.kPauseException: message.write('paused in the debugger after an exception was thrown'); break;
      case ServiceEvent.kPausePostRequest: message.write('paused'); break;
      case '': message.write('paused for various reasons'); break;
      default:
        message.write('paused');
    }
    return message.toString();
  }

  bool _isPaused() {
    for (FlutterDevice device in flutterDevices) {
      for (FlutterView view in device.views) {
        if (view.uiIsolate != null) {
          final ServiceEvent pauseEvent = view.uiIsolate.pauseEvent;
          if (pauseEvent != null && pauseEvent.isPauseEvent) {
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  void printHelp({ @required bool details }) {
    const String fire = '🔥';
    String rawMessage = '  To hot reload changes while running, press "r". ';
    if (canHotRestart) {
      rawMessage += 'To hot restart (and rebuild state), press "R".';
    }
    final String message = terminal.color(
      fire + terminal.bolden(rawMessage),
      TerminalColor.red,
    );
    printStatus(message);
    for (FlutterDevice device in flutterDevices) {
      final String dname = device.device.name;
      for (Uri uri in device.observatoryUris)
        printStatus('An Observatory debugger and profiler on $dname is available at: $uri');
    }
    final String quitMessage = _didAttach
        ? 'To detach, press "d"; to quit, press "q".'
        : 'To quit, press "q".';
    if (details) {
      printHelpDetails();
      printStatus('To repeat this help message, press "h". $quitMessage');
    } else {
      printStatus('For a more detailed help message, press "h". $quitMessage');
    }
  }

  Future<void> _evictDirtyAssets() {
    final List<Future<Map<String, dynamic>>> futures = <Future<Map<String, dynamic>>>[];
    for (FlutterDevice device in flutterDevices) {
      if (device.devFS.assetPathsToEvict.isEmpty)
        continue;
      if (device.views.first.uiIsolate == null) {
        printError('Application isolate not found for $device');
        continue;
      }
      for (String assetPath in device.devFS.assetPathsToEvict) {
        futures.add(device.views.first.uiIsolate.flutterEvictAsset(assetPath));
      }
      device.devFS.assetPathsToEvict.clear();
    }
    return Future.wait<Map<String, dynamic>>(futures);
  }

  @override
  Future<void> cleanupAfterSignal() async {
    await stopEchoingDeviceLog();
    await hotRunnerConfig.runPreShutdownOperations();
    if (_didAttach) {
      appFinished();
    } else {
      await exitApp();
    }
  }

  @override
  Future<void> preExit() async {
    await _cleanupDevFS();
    await hotRunnerConfig.runPreShutdownOperations();
    await super.preExit();
  }

  @override
  Future<void> cleanupAtFinish() async {
    await _cleanupDevFS();
    await stopEchoingDeviceLog();
  }
}

class ProjectFileInvalidator {
  static const String _pubCachePathLinuxAndMac = '.pub-cache';
  static const String _pubCachePathWindows = 'Pub/Cache';

  static List<Uri> findInvalidated({
    @required DateTime lastCompiled,
    @required List<Uri> urisToMonitor,
    @required String packagesPath,
  }) {
    final List<Uri> invalidatedFiles = <Uri>[];
    int scanned = 0;
    final Stopwatch stopwatch = Stopwatch()..start();
    for (Uri uri in urisToMonitor) {
      if ((platform.isWindows && uri.path.contains(_pubCachePathWindows))
          || uri.path.contains(_pubCachePathLinuxAndMac)) {
        // Don't watch pub cache directories to speed things up a little.
        continue;
      }
      final DateTime updatedAt = fs.statSync(
          uri.toFilePath(windows: platform.isWindows)).modified;
      scanned++;
      if (updatedAt == null) {
        continue;
      }
      if (updatedAt.millisecondsSinceEpoch > lastCompiled.millisecondsSinceEpoch) {
        invalidatedFiles.add(uri);
      }
    }
    // we need to check the .packages file too since it is not used in compilation.
    final DateTime packagesUpdatedAt = fs.statSync(packagesPath).modified;
    if (lastCompiled != null && packagesUpdatedAt != null
        && packagesUpdatedAt.millisecondsSinceEpoch > lastCompiled.millisecondsSinceEpoch) {
      invalidatedFiles.add(fs.file(packagesPath).uri);
      scanned++;
    }
    printTrace('Scanned through $scanned files in ${stopwatch.elapsedMilliseconds}ms');
    return invalidatedFiles;
  }
}

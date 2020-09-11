// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:package_config/package_config.dart';
import 'package:vm_service/vm_service.dart' as vm_service;
import 'package:meta/meta.dart';
import 'package:pool/pool.dart';

import 'base/async_guard.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/platform.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'bundle.dart';
import 'compile.dart';
import 'convert.dart';
import 'dart/package_map.dart';
import 'devfs.dart';
import 'device.dart';
import 'globals.dart' as globals;
import 'reporting/reporting.dart';
import 'resident_runner.dart';
import 'vmservice.dart';

ProjectFileInvalidator get projectFileInvalidator => context.get<ProjectFileInvalidator>() ?? ProjectFileInvalidator(
  fileSystem: globals.fs,
  platform: globals.platform,
  logger: globals.logger,
);

HotRunnerConfig get hotRunnerConfig => context.get<HotRunnerConfig>();

class HotRunnerConfig {
  /// Should the hot runner assume that the minimal Dart dependencies do not change?
  bool stableDartDependencies = false;

  /// Whether the hot runner should scan for modified files asynchronously.
  bool asyncScanning = false;

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

const bool kHotReloadDefault = true;

class DeviceReloadReport {
  DeviceReloadReport(this.device, this.reports);

  FlutterDevice device;
  List<vm_service.ReloadReport> reports; // List has one report per Flutter view.
}

class HotRunner extends ResidentRunner {
  HotRunner(
    List<FlutterDevice> devices, {
    String target,
    @required DebuggingOptions debuggingOptions,
    this.benchmarkMode = false,
    this.applicationBinary,
    this.hostIsIde = false,
    String projectRootPath,
    String dillOutputPath,
    bool stayResident = true,
    bool ipv6 = false,
    bool machine = false,
  }) : super(
          devices,
          target: target,
          debuggingOptions: debuggingOptions,
          projectRootPath: projectRootPath,
          stayResident: stayResident,
          hotMode: true,
          dillOutputPath: dillOutputPath,
          ipv6: ipv6,
          machine: machine,
        );

  final bool benchmarkMode;
  final File applicationBinary;
  final bool hostIsIde;

  /// When performing a hot restart, the tool needs to upload a new main.dart.dill to
  /// each attached device's devfs. Replacing the existing file is not safe and does
  /// not work at all on the windows embedder, because the old dill file will still be
  /// memory-mapped by the embedder. To work around this issue, the tool will alternate
  /// names for the uploaded dill, sometimes inserting `.swap`. Since the active dill will
  /// never be replaced, there is no risk of writing the file while the embedder is attempting
  /// to read from it. This also avoids filling up the devfs, if a incrementing counter was
  /// used instead.
  ///
  /// This is only used for hot restart, incremental dills uploaded as part of the hot
  /// reload process do not have this issue.
  bool _swap = false;

  bool _didAttach = false;

  final Map<String, List<int>> benchmarkData = <String, List<int>>{};

  DateTime firstBuildTime;
  bool _shouldResetAssetDirectory = true;

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
    final OperationResult result = await restart(pause: pause);
    if (!result.isOk) {
      throw vm_service.RPCError(
        'Unable to reload sources',
        RPCErrorCodes.kInternalError,
        '',
      );
    }
  }

  Future<void> _restartService({ bool pause = false }) async {
    final OperationResult result =
      await restart(fullRestart: true, pause: pause);
    if (!result.isOk) {
      throw vm_service.RPCError(
        'Unable to restart',
        RPCErrorCodes.kInternalError,
        '',
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
    for (final FlutterDevice device in flutterDevices) {
      if (device.generator != null) {
        final CompilerOutput compilerOutput =
            await device.generator.compileExpression(expression, definitions,
                typeDefinitions, libraryUri, klass, isStatic);
        if (compilerOutput != null && compilerOutput.outputFilename != null) {
          return base64.encode(globals.fs.file(compilerOutput.outputFilename).readAsBytesSync());
        }
      }
    }
    throw 'Failed to compile $expression';
  }

  @override
  Future<OperationResult> reloadMethod({ String libraryId, String classId }) async {
    final OperationResult result = await restart(pause: false);
    if (!result.isOk) {
      throw vm_service.RPCError(
        'Unable to reload sources',
        RPCErrorCodes.kInternalError,
        '',
      );
    }
    return result;
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
        reloadMethod: reloadMethod,
        getSkSLMethod: writeSkSL,
      );
    // Catches all exceptions, non-Exception objects are rethrown.
    } catch (error) { // ignore: avoid_catches_without_on_clauses
      if (error is! Exception && error is! String) {
        rethrow;
      }
      globals.printError('Error connecting to the service protocol: $error');
      return 2;
    }

    for (final FlutterDevice device in flutterDevices) {
      await device.initLogReader();
    }
    try {
      final List<Uri> baseUris = await _initDevFS();
      if (connectionInfoCompleter != null) {
        // Only handle one debugger connection.
        connectionInfoCompleter.complete(
          DebugConnectionInfo(
            httpUri: flutterDevices.first.vmService.httpAddress,
            wsUri: flutterDevices.first.vmService.wsAddress,
            baseUri: baseUris.first.toString(),
          ),
        );
      }
    } on Exception catch (error) {
      globals.printError('Error initializing DevFS: $error');
      return 3;
    }
    final Stopwatch initialUpdateDevFSsTimer = Stopwatch()..start();
    final UpdateFSReport devfsResult = await _updateDevFS(fullRestart: true);
    _addBenchmarkData(
      'hotReloadInitialDevFSSyncMilliseconds',
      initialUpdateDevFSsTimer.elapsed.inMilliseconds,
    );
    if (!devfsResult.success) {
      return 3;
    }

    for (final FlutterDevice device in flutterDevices) {
      // VM must have accepted the kernel binary, there will be no reload
      // report, so we let incremental compiler know that source code was accepted.
      if (device.generator != null) {
        device.generator.accept();
      }
      final List<FlutterView> views = await device.vmService.getFlutterViews();
      for (final FlutterView view in views) {
        globals.printTrace('Connected to $view.');
      }
    }

    // In fast-start mode, apps are initialized from a placeholder splashscreen
    // app. We must do a restart here to load the program and assets for the
    // real app.
    if (debuggingOptions.fastStart) {
      await restart(
        fullRestart: true,
        benchmarkMode: !debuggingOptions.startPaused,
        reason: 'restart',
        silent: true,
      );
    }

    appStartedCompleter?.complete();

    if (benchmarkMode) {
      // We are running in benchmark mode.
      globals.printStatus('Running in benchmark mode.');
      // Measure time to perform a hot restart.
      globals.printStatus('Benchmarking hot restart');
      await restart(fullRestart: true, benchmarkMode: true);
      // Wait for notifications to finish. attempt to work around
      // timing issue caused by sentinel.
      await Future<void>.delayed(const Duration(seconds: 1));
      globals.printStatus('Benchmarking hot reload');
      // Measure time to perform a hot reload.
      await restart(fullRestart: false);
      if (stayResident) {
        await waitForAppToFinish();
      } else {
        globals.printStatus('Benchmark completed. Exiting application.');
        await _cleanupDevFS();
        await stopEchoingDeviceLog();
        await exitApp();
      }
      final File benchmarkOutput = globals.fs.file('hot_benchmark.json');
      benchmarkOutput.writeAsStringSync(toPrettyJson(benchmarkData));
      return 0;
    }
    writeVmserviceFile();

    int result = 0;
    if (stayResident) {
      result = await waitForAppToFinish();
    }
    await cleanupAtFinish();
    return result;
  }

  @override
  Future<int> run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
    String route,
  }) async {
    if (!globals.fs.isFileSync(mainPath)) {
      String message = 'Tried to run $mainPath, but that file does not exist.';
      if (target == null) {
        message += '\nConsider using the -t option to specify the Dart file to start.';
      }
      globals.printError(message);
      return 1;
    }

    firstBuildTime = DateTime.now();

    final List<Future<bool>> startupTasks = <Future<bool>>[];
    final PackageConfig packageConfig = await loadPackageConfigWithLogging(
      globals.fs.file(debuggingOptions.buildInfo.packagesPath),
      logger: globals.logger,
    );
    for (final FlutterDevice device in flutterDevices) {
      // Here we initialize the frontend_server concurrently with the platform
      // build, reducing overall initialization time. This is safe because the first
      // invocation of the frontend server produces a full dill file that the
      // subsequent invocation in devfs will not overwrite.
      await runSourceGenerators();
      if (device.generator != null) {
        startupTasks.add(
          device.generator.recompile(
            globals.fs.file(mainPath).uri,
            <Uri>[],
            // When running without a provided applicationBinary, the tool will
            // simultaneously run the initial frontend_server compilation and
            // the native build step. If there is a Dart compilation error, it
            // should only be displayed once.
            suppressErrors: applicationBinary == null,
            outputPath: dillOutputPath ??
              getDefaultApplicationKernelPath(trackWidgetCreation: debuggingOptions.buildInfo.trackWidgetCreation),
            packageConfig: packageConfig,
          ).then((CompilerOutput output) => output?.errorCount == 0)
        );
      }
      startupTasks.add(device.runHot(
        hotRunner: this,
        route: route,
      ).then((int result) => result == 0));
    }
    try {
      final List<bool> results = await Future.wait(startupTasks);
      if (!results.every((bool passed) => passed)) {
        appFailedToStart();
        return 1;
      }
      cacheInitialDillCompilation();
    } on Exception catch (err) {
      globals.printError(err.toString());
      appFailedToStart();
      return 1;
    }

    return attach(
      connectionInfoCompleter: connectionInfoCompleter,
      appStartedCompleter: appStartedCompleter,
    );
  }

  Future<List<Uri>> _initDevFS() async {
    final String fsName = globals.fs.path.basename(projectRootPath);
    return <Uri>[
      for (final FlutterDevice device in flutterDevices)
        await device.setupDevFS(
          fsName,
          globals.fs.directory(projectRootPath),
          packagesFilePath: packagesFilePath,
        ),
    ];
  }

  Future<UpdateFSReport> _updateDevFS({ bool fullRestart = false }) async {
    final bool isFirstUpload = !assetBundle.wasBuiltOnce();
    final bool rebuildBundle = assetBundle.needsBuild();
    if (rebuildBundle) {
      globals.printTrace('Updating assets');
      final int result = await assetBundle.build(packagesPath: '.packages');
      if (result != 0) {
        return UpdateFSReport(success: false);
      }
    }

    final InvalidationResult invalidationResult = await projectFileInvalidator.findInvalidated(
      lastCompiled: flutterDevices[0].devFS.lastCompiled,
      urisToMonitor: flutterDevices[0].devFS.sources,
      packagesPath: packagesFilePath,
      asyncScanning: hotRunnerConfig.asyncScanning,
      packageConfig: flutterDevices[0].devFS.lastPackageConfig,
    );
    final File entrypointFile = globals.fs.file(mainPath);
    if (!entrypointFile.existsSync()) {
      globals.printError(
        'The entrypoint file (i.e. the file with main()) ${entrypointFile.path} '
        'cannot be found. Moving or renaming this file will prevent changes to '
        'its contents from being discovered during hot reload/restart until '
        'flutter is restarted or the file is restored.'
      );
    }
    final UpdateFSReport results = UpdateFSReport(success: true);
    for (final FlutterDevice device in flutterDevices) {
      results.incorporateResults(await device.updateDevFS(
        mainUri: entrypointFile.absolute.uri,
        target: target,
        bundle: assetBundle,
        firstBuildTime: firstBuildTime,
        bundleFirstUpload: isFirstUpload,
        bundleDirty: !isFirstUpload && rebuildBundle,
        fullRestart: fullRestart,
        projectRootPath: projectRootPath,
        pathToReload: getReloadPath(fullRestart: fullRestart, swap: _swap),
        invalidatedFiles: invalidationResult.uris,
        packageConfig: invalidationResult.packageConfig,
        dillOutputPath: dillOutputPath,
      ));
    }
    return results;
  }

  void _resetDirtyAssets() {
    for (final FlutterDevice device in flutterDevices) {
      device.devFS.assetPathsToEvict.clear();
    }
  }

  Future<void> _cleanupDevFS() async {
    final List<Future<void>> futures = <Future<void>>[];
    for (final FlutterDevice device in flutterDevices) {
      if (device.devFS != null) {
        // Cleanup the devFS, but don't wait indefinitely.
        // We ignore any errors, because it's not clear what we would do anyway.
        futures.add(device.devFS.destroy()
          .timeout(const Duration(milliseconds: 250))
          .catchError((dynamic error) {
            globals.printTrace('Ignored error while cleaning up DevFS: $error');
          }));
      }
      device.devFS = null;
    }
    await Future.wait(futures);
  }

  Future<void> _launchInView(
    FlutterDevice device,
    Uri main,
    Uri assetsDirectory,
  ) async {
    final List<FlutterView> views = await device.vmService.getFlutterViews();
    await Future.wait(<Future<void>>[
      for (final FlutterView view in views)
        device.vmService.runInView(
          viewId: view.id,
          main: main,
          assetsDirectory: assetsDirectory,
        ),
    ]);
  }

  Future<void> _launchFromDevFS(String mainScript) async {
    final String entryUri = globals.fs.path.relative(mainScript, from: projectRootPath);
    final List<Future<void>> futures = <Future<void>>[];
    for (final FlutterDevice device in flutterDevices) {
      final Uri deviceEntryUri = device.devFS.baseUri.resolveUri(
        globals.fs.path.toUri(entryUri));
      final Uri deviceAssetsDirectoryUri = device.devFS.baseUri.resolveUri(
        globals.fs.path.toUri(getAssetBuildDirectory()));
      futures.add(_launchInView(device,
                          deviceEntryUri,
                          deviceAssetsDirectoryUri));
    }
    await Future.wait(futures);
    if (benchmarkMode) {
      futures.clear();
      for (final FlutterDevice device in flutterDevices) {
        final List<FlutterView> views = await device.vmService.getFlutterViews();
        for (final FlutterView view in views) {
          futures.add(device.vmService
            .flushUIThreadTasks(uiIsolateId: view.uiIsolate.id));
        }
      }
      await Future.wait(futures);
    }
  }

  Future<OperationResult> _restartFromSources({
    String reason,
    bool benchmarkMode = false,
  }) async {
    final Stopwatch restartTimer = Stopwatch()..start();
    // TODO(aam): Add generator reset logic once we switch to using incremental
    // compiler for full application recompilation on restart.
    final UpdateFSReport updatedDevFS = await _updateDevFS(fullRestart: true);
    if (!updatedDevFS.success) {
      for (final FlutterDevice device in flutterDevices) {
        if (device.generator != null) {
          await device.generator.reject();
        }
      }
      return OperationResult(1, 'DevFS synchronization failed');
    }
    _resetDirtyAssets();
    for (final FlutterDevice device in flutterDevices) {
      // VM must have accepted the kernel binary, there will be no reload
      // report, so we let incremental compiler know that source code was accepted.
      if (device.generator != null) {
        device.generator.accept();
      }
    }
    // Check if the isolate is paused and resume it.
    final List<Future<void>> operations = <Future<void>>[];
    for (final FlutterDevice device in flutterDevices) {
      final Set<String> uiIsolatesIds = <String>{};
      final List<FlutterView> views = await device.vmService.getFlutterViews();
      for (final FlutterView view in views) {
        if (view.uiIsolate == null) {
          continue;
        }
        uiIsolatesIds.add(view.uiIsolate.id);
        // Reload the isolate.
        final Future<vm_service.Isolate> reloadIsolate = device.vmService
          .getIsolateOrNull(view.uiIsolate.id);
        operations.add(reloadIsolate.then((vm_service.Isolate isolate) async {
          if ((isolate != null) && isPauseEvent(isolate.pauseEvent.kind)) {
            // The embedder requires that the isolate is unpaused, because the
            // runInView method requires interaction with dart engine APIs that
            // are not thread-safe, and thus must be run on the same thread that
            // would be blocked by the pause. Simply unpausing is not sufficient,
            // because this does not prevent the isolate from immediately hitting
            // a breakpoint, for example if the breakpoint was placed in a loop
            // or in a frequently called method. Instead, all breakpoints are first
            // disabled and then the isolate resumed.
            final List<Future<void>> breakpointRemoval = <Future<void>>[
              for (final vm_service.Breakpoint breakpoint in isolate.breakpoints)
                device.vmService.removeBreakpoint(isolate.id, breakpoint.id)
            ];
            await Future.wait(breakpointRemoval);
            await device.vmService.resume(view.uiIsolate.id);
          }
        }));
      }

      // The engine handles killing and recreating isolates that it has spawned
      // ("uiIsolates"). The isolates that were spawned from these uiIsolates
      // will not be restared, and so they must be manually killed.
      final vm_service.VM vm = await device.vmService.getVM();
      for (final vm_service.IsolateRef isolateRef in vm.isolates) {
        if (uiIsolatesIds.contains(isolateRef.id)) {
          continue;
        }
        operations.add(device.vmService.kill(isolateRef.id)
          .catchError((dynamic error, StackTrace stackTrace) {
            // Do nothing on a SentinelException since it means the isolate
            // has already been killed.
          }, test: (dynamic error) => error is vm_service.SentinelException));
      }
    }
    await Future.wait(operations);

    await _launchFromDevFS('$mainPath${_swap ? '.swap' : ''}.dill');
    restartTimer.stop();
    globals.printTrace('Hot restart performed in ${getElapsedAsMilliseconds(restartTimer.elapsed)}.');
    _addBenchmarkData('hotRestartMillisecondsToFrame',
        restartTimer.elapsed.inMilliseconds);

    // Send timing analytics.
    globals.flutterUsage.sendTiming('hot', 'restart', restartTimer.elapsed);

    // In benchmark mode, make sure all stream notifications have finished.
    if (benchmarkMode) {
      final List<Future<void>> isolateNotifications = <Future<void>>[];
      for (final FlutterDevice device in flutterDevices) {
        try {
          await device.vmService.streamListen('Isolate');
        } on vm_service.RPCError {
          // Do nothing, we're already subcribed.
        }
        isolateNotifications.add(
          device.vmService.onIsolateEvent.firstWhere((vm_service.Event event) {
            return event.kind == vm_service.EventKind.kIsolateRunnable;
          }),
        );
      }
      await Future.wait(isolateNotifications);
    }
    // Toggle the main dill name after successfully uploading.
    _swap =! _swap;

    return OperationResult.ok;
  }

  /// Returns [true] if the reload was successful.
  /// Prints errors if [printErrors] is [true].
  static bool validateReloadReport(
    Map<String, dynamic> reloadReport, {
    bool printErrors = true,
  }) {
    if (reloadReport == null) {
      if (printErrors) {
        globals.printError('Hot reload did not receive reload report.');
      }
      return false;
    }
    if (!(reloadReport['type'] == 'ReloadReport' &&
          (reloadReport['success'] == true ||
           (reloadReport['success'] == false &&
            (reloadReport['details'] is Map<String, dynamic> &&
             reloadReport['details']['notices'] is List<dynamic> &&
             (reloadReport['details']['notices'] as List<dynamic>).isNotEmpty &&
             (reloadReport['details']['notices'] as List<dynamic>).every(
               (dynamic item) => item is Map<String, dynamic> && item['message'] is String
             )
            )
           )
          )
         )) {
      if (printErrors) {
        globals.printError('Hot reload received invalid response: $reloadReport');
      }
      return false;
    }
    if (!(reloadReport['success'] as bool)) {
      if (printErrors) {
        globals.printError('Hot reload was rejected:');
        for (final Map<String, dynamic> notice in (reloadReport['details']['notices'] as List<dynamic>).cast<Map<String, dynamic>>()) {
          globals.printError('${notice['message']}');
        }
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
    String reason,
    bool benchmarkMode = false,
    bool silent = false,
    bool pause = false,
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

    // Run source generation if needed.
    await runSourceGenerators();

    if (fullRestart) {
      final OperationResult result = await _fullRestartHelper(
        targetPlatform: targetPlatform,
        sdkName: sdkName,
        emulator: emulator,
        reason: reason,
        benchmarkMode: benchmarkMode,
        silent: silent,
      );
      if (!silent) {
        globals.printStatus('Restarted application in ${getElapsedAsMilliseconds(timer.elapsed)}.');
      }
      return result;
    }
    final OperationResult result = await _hotReloadHelper(
      targetPlatform: targetPlatform,
      sdkName: sdkName,
      emulator: emulator,
      reason: reason,
      pause: pause,
    );
    if (result.isOk) {
      final String elapsed = getElapsedAsMilliseconds(timer.elapsed);
      if (!silent) {
        globals.printStatus('${result.message} in $elapsed.');
      }
    }
    return result;
  }

  Future<OperationResult> _fullRestartHelper({
    String targetPlatform,
    String sdkName,
    bool emulator,
    String reason,
    bool benchmarkMode,
    bool silent,
  }) async {
    if (!canHotRestart) {
      return OperationResult(1, 'hotRestart not supported');
    }
    Status status;
    if (!silent) {
      status = globals.logger.startProgress(
        'Performing hot restart...',
        timeout: timeoutConfiguration.fastOperation,
        progressId: 'hot.restart',
      );
    }
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
    } on vm_service.SentinelException catch (err, st) {
      restartEvent = 'exception';
      return OperationResult(1, 'hot restart failed to complete: $err\n$st', fatal: true);
    } on vm_service.RPCError  catch (err, st) {
      restartEvent = 'exception';
      return OperationResult(1, 'hot restart failed to complete: $err\n$st', fatal: true);
    } finally {
      HotEvent(restartEvent,
        targetPlatform: targetPlatform,
        sdkName: sdkName,
        emulator: emulator,
        fullRestart: true,
        nullSafety: usageNullSafety,
        reason: reason).send();
      status?.cancel();
    }
    return result;
  }

  Future<OperationResult> _hotReloadHelper({
    String targetPlatform,
    String sdkName,
    bool emulator,
    String reason,
    bool pause,
  }) async {
    Status status = globals.logger.startProgress(
      'Performing hot reload...',
      timeout: timeoutConfiguration.fastOperation,
      progressId: 'hot.reload',
    );
    OperationResult result;
    try {
      result = await _reloadSources(
        targetPlatform: targetPlatform,
        sdkName: sdkName,
        emulator: emulator,
        reason: reason,
        pause: pause,
        onSlow: (String message) {
          status?.cancel();
          status = globals.logger.startProgress(
            message,
            timeout: timeoutConfiguration.slowOperation,
            progressId: 'hot.reload',
          );
        },
      );
    } on vm_service.RPCError {
      HotEvent('exception',
        targetPlatform: targetPlatform,
        sdkName: sdkName,
        emulator: emulator,
        fullRestart: false,
        nullSafety: usageNullSafety,
        reason: reason,
      ).send();
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
    void Function(String message) onSlow,
  }) async {
    for (final FlutterDevice device in flutterDevices) {
      final List<FlutterView> views = await device.vmService.getFlutterViews();
      for (final FlutterView view in views) {
        if (view.uiIsolate == null) {
          return OperationResult(2, 'Application isolate not found', fatal: true);
        }
      }
    }

    final Stopwatch reloadTimer = Stopwatch()..start();
    final Stopwatch devFSTimer = Stopwatch()..start();
    final UpdateFSReport updatedDevFS = await _updateDevFS();
    // Record time it took to synchronize to DevFS.
    bool shouldReportReloadTime = true;
    _addBenchmarkData('hotReloadDevFSSyncMilliseconds', devFSTimer.elapsed.inMilliseconds);
    if (!updatedDevFS.success) {
      return OperationResult(1, 'DevFS synchronization failed');
    }
    String reloadMessage;
    final Stopwatch vmReloadTimer = Stopwatch()..start();
    Map<String, dynamic> firstReloadDetails;
    try {
      final String entryPath = globals.fs.path.relative(
        getReloadPath(fullRestart: false, swap: _swap),
        from: projectRootPath,
      );
      final List<Future<DeviceReloadReport>> allReportsFutures = <Future<DeviceReloadReport>>[];
      for (final FlutterDevice device in flutterDevices) {
        if (_shouldResetAssetDirectory) {
          // Asset directory has to be set only once when we switch from
          // running from bundle to uploaded files.
          await device.resetAssetDirectory();
          _shouldResetAssetDirectory = false;
        }
        final List<Future<vm_service.ReloadReport>> reportFutures = await device.reloadSources(
          entryPath, pause: pause,
        );
        allReportsFutures.add(Future.wait(reportFutures).then(
          (List<vm_service.ReloadReport> reports) async {
            // TODO(aam): Investigate why we are validating only first reload report,
            // which seems to be current behavior
            final vm_service.ReloadReport firstReport = reports.first;
            // Don't print errors because they will be printed further down when
            // `validateReloadReport` is called again.
            await device.updateReloadStatus(
              validateReloadReport(firstReport.json, printErrors: false),
            );
            return DeviceReloadReport(device, reports);
          },
        ));
      }
      final List<DeviceReloadReport> reports = await Future.wait(allReportsFutures);
      for (final DeviceReloadReport report in reports) {
        final vm_service.ReloadReport reloadReport = report.reports[0];
        if (!validateReloadReport(reloadReport.json)) {
          // Reload failed.
          HotEvent('reload-reject',
            targetPlatform: targetPlatform,
            sdkName: sdkName,
            emulator: emulator,
            fullRestart: false,
            reason: reason,
            nullSafety: usageNullSafety,
          ).send();
          return OperationResult(1, 'Reload rejected');
        }
        // Collect stats only from the first device. If/when run -d all is
        // refactored, we'll probably need to send one hot reload/restart event
        // per device to analytics.
        firstReloadDetails ??= castStringKeyedMap(reloadReport.json['details']);
        final int loadedLibraryCount = reloadReport.json['details']['loadedLibraryCount'] as int;
        final int finalLibraryCount = reloadReport.json['details']['finalLibraryCount'] as int;
        globals.printTrace('reloaded $loadedLibraryCount of $finalLibraryCount libraries');
        reloadMessage = 'Reloaded $loadedLibraryCount of $finalLibraryCount libraries';
      }
    } on Map<String, dynamic> catch (error, stackTrace) {
      globals.printTrace('Hot reload failed: $error\n$stackTrace');
      final int errorCode = error['code'] as int;
      String errorMessage = error['message'] as String;
      if (errorCode == kIsolateReloadBarred) {
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
          nullSafety: usageNullSafety,
        ).send();
        return OperationResult(errorCode, errorMessage);
      }
      return OperationResult(errorCode, '$errorMessage (error code: $errorCode)');
    } on Exception catch (error, stackTrace) {
      globals.printTrace('Hot reload failed: $error\n$stackTrace');
      return OperationResult(1, '$error');
    }
    // Record time it took for the VM to reload the sources.
    _addBenchmarkData('hotReloadVMReloadMilliseconds', vmReloadTimer.elapsed.inMilliseconds);
    final Stopwatch reassembleTimer = Stopwatch()..start();
    await _evictDirtyAssets();

    // Check if any isolates are paused and reassemble those
    // that aren't.
    final Map<FlutterView, vm_service.VmService> reassembleViews = <FlutterView, vm_service.VmService>{};
    final List<Future<void>> reassembleFutures = <Future<void>>[];
    String serviceEventKind;
    int pausedIsolatesFound = 0;
    bool failedReassemble = false;
    for (final FlutterDevice device in flutterDevices) {
      final List<FlutterView> views = await device.vmService.getFlutterViews();
      for (final FlutterView view in views) {
        // Check if the isolate is paused, and if so, don't reassemble. Ignore the
        // PostPauseEvent event - the client requesting the pause will resume the app.
        final vm_service.Isolate isolate = await device.vmService
          .getIsolateOrNull(view.uiIsolate.id);
        final vm_service.Event pauseEvent = isolate?.pauseEvent;
        if (pauseEvent != null
          && isPauseEvent(pauseEvent.kind)
          && pauseEvent.kind != vm_service.EventKind.kPausePostRequest) {
          pausedIsolatesFound += 1;
          if (serviceEventKind == null) {
            serviceEventKind = pauseEvent.kind;
          } else if (serviceEventKind != pauseEvent.kind) {
            serviceEventKind = ''; // many kinds
          }
        } else {
          reassembleViews[view] = device.vmService;
          // If the tool identified a change in a single widget, do a fast instead
          // of a full reassemble.
          Future<void> reassembleWork;
          if (updatedDevFS.fastReassemble == true) {
            reassembleWork = device.vmService.flutterFastReassemble(
              isolateId: view.uiIsolate.id,
            );
          } else {
            reassembleWork = device.vmService.flutterReassemble(
              isolateId: view.uiIsolate.id,
            );
          }
          reassembleFutures.add(reassembleWork.catchError((dynamic error) {
            failedReassemble = true;
            globals.printError('Reassembling ${view.uiIsolate.name} failed: $error');
          }, test: (dynamic error) => error is Exception));
        }
      }
    }
    if (pausedIsolatesFound > 0) {
      if (onSlow != null) {
        onSlow('${_describePausedIsolates(pausedIsolatesFound, serviceEventKind)}; interface might not update.');
      }
      if (reassembleViews.isEmpty) {
        globals.printTrace('Skipping reassemble because all isolates are paused.');
        return OperationResult(OperationResult.ok.code, reloadMessage);
      }
    }
    assert(reassembleViews.isNotEmpty);

    globals.printTrace('Reassembling application');

    final Future<void> reassembleFuture = Future.wait<void>(reassembleFutures);
    await reassembleFuture.timeout(
      const Duration(seconds: 2),
      onTimeout: () async {
        if (pausedIsolatesFound > 0) {
          shouldReportReloadTime = false;
          return; // probably no point waiting, they're probably deadlocked and we've already warned.
        }
        // Check if any isolate is newly paused.
        globals.printTrace('This is taking a long time; will now check for paused isolates.');
        int postReloadPausedIsolatesFound = 0;
        String serviceEventKind;
        for (final FlutterView view in reassembleViews.keys) {
          final vm_service.Isolate isolate = await reassembleViews[view]
            .getIsolateOrNull(view.uiIsolate.id);
          if (isolate == null) {
            continue;
          }
          if (isolate.pauseEvent != null && isPauseEvent(isolate.pauseEvent.kind)) {
            postReloadPausedIsolatesFound += 1;
            if (serviceEventKind == null) {
              serviceEventKind = isolate.pauseEvent.kind;
            } else if (serviceEventKind != isolate.pauseEvent.kind) {
              serviceEventKind = ''; // many kinds
            }
          }
        }
        globals.printTrace('Found $postReloadPausedIsolatesFound newly paused isolate(s).');
        if (postReloadPausedIsolatesFound == 0) {
          await reassembleFuture; // must just be taking a long time... keep waiting!
          return;
        }
        shouldReportReloadTime = false;
        if (onSlow != null) {
          onSlow('${_describePausedIsolates(postReloadPausedIsolatesFound, serviceEventKind)}.');
        }
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
      finalLibraryCount: firstReloadDetails['finalLibraryCount'] as int,
      syncedLibraryCount: firstReloadDetails['receivedLibraryCount'] as int,
      syncedClassesCount: firstReloadDetails['receivedClassesCount'] as int,
      syncedProceduresCount: firstReloadDetails['receivedProceduresCount'] as int,
      syncedBytes: updatedDevFS.syncedBytes,
      invalidatedSourcesCount: updatedDevFS.invalidatedSourcesCount,
      transferTimeInMs: devFSTimer.elapsed.inMilliseconds,
      nullSafety: usageNullSafety,
    ).send();

    if (shouldReportReloadTime) {
      globals.printTrace('Hot reload performed in ${getElapsedAsMilliseconds(reloadDuration)}.');
      // Record complete time it took for the reload.
      _addBenchmarkData('hotReloadMillisecondsToFrame', reloadInMs);
    }
    // Only report timings if we reloaded a single view without any errors.
    if ((reassembleViews.length == 1) && !failedReassemble && shouldReportReloadTime) {
      globals.flutterUsage.sendTiming('hot', 'reload', reloadDuration);
    }
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
      message.write('The application is ');
      plural = false;
    } else {
      message.write('$pausedIsolatesFound isolates are ');
      plural = true;
    }
    assert(serviceEventKind != null);
    switch (serviceEventKind) {
      case vm_service.EventKind.kPauseStart:
        message.write('paused (probably due to --start-paused)');
        break;
      case vm_service.EventKind.kPauseExit:
        message.write('paused because ${ plural ? 'they have' : 'it has' } terminated');
        break;
      case vm_service.EventKind.kPauseBreakpoint:
        message.write('paused in the debugger on a breakpoint');
        break;
      case vm_service.EventKind.kPauseInterrupted:
        message.write('paused due in the debugger');
        break;
      case vm_service.EventKind.kPauseException:
        message.write('paused in the debugger after an exception was thrown');
        break;
      case vm_service.EventKind.kPausePostRequest:
        message.write('paused');
        break;
      case '':
        message.write('paused for various reasons');
        break;
      default:
        message.write('paused');
    }
    return message.toString();
  }


  @override
  void printHelp({ @required bool details }) {
    globals.printStatus('Flutter run key commands.');
    commandHelp.r.print();
    if (canHotRestart) {
      commandHelp.R.print();
    }
    commandHelp.h.print();
    if (_didAttach) {
      commandHelp.d.print();
    }
    commandHelp.c.print();
    commandHelp.q.print();
    if (details) {
      printHelpDetails();
    }
    for (final FlutterDevice device in flutterDevices) {
      final String dname = device.device.name;
      // Caution: This log line is parsed by device lab tests.
      globals.printStatus(
        'An Observatory debugger and profiler on $dname is available at: '
        '${device.vmService.httpAddress}',
      );
    }
  }

  Future<void> _evictDirtyAssets() async {
    final List<Future<Map<String, dynamic>>> futures = <Future<Map<String, dynamic>>>[];
    for (final FlutterDevice device in flutterDevices) {
      if (device.devFS.assetPathsToEvict.isEmpty) {
        continue;
      }
      final List<FlutterView> views = await device.vmService.getFlutterViews();
      if (views.first.uiIsolate == null) {
        globals.printError('Application isolate not found for $device');
        continue;
      }
      for (final String assetPath in device.devFS.assetPathsToEvict) {
        futures.add(
          device.vmService
            .flutterEvictAsset(
              assetPath,
              isolateId: views.first.uiIsolate.id,
            )
        );
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
    for (final FlutterDevice flutterDevice in flutterDevices) {
      await flutterDevice.device.dispose();
    }
    await _cleanupDevFS();
    await stopEchoingDeviceLog();
  }
}

/// The result of an invalidation check from [ProjectFileInvalidator].
class InvalidationResult {
  const InvalidationResult({
    this.uris,
    this.packageConfig,
  });

  final List<Uri> uris;
  final PackageConfig packageConfig;
}

/// The [ProjectFileInvalidator] track the dependencies for a running
/// application to determine when they are dirty.
class ProjectFileInvalidator {
  ProjectFileInvalidator({
    @required FileSystem fileSystem,
    @required Platform platform,
    @required Logger logger,
  }): _fileSystem = fileSystem,
      _platform = platform,
      _logger = logger;

  final FileSystem _fileSystem;
  final Platform _platform;
  final Logger _logger;

  static const String _pubCachePathLinuxAndMac = '.pub-cache';
  static const String _pubCachePathWindows = 'Pub/Cache';

  // As of writing, Dart supports up to 32 asynchronous I/O threads per
  // isolate. We also want to avoid hitting platform limits on open file
  // handles/descriptors.
  //
  // This value was chosen based on empirical tests scanning a set of
  // ~2000 files.
  static const int _kMaxPendingStats = 8;

  Future<InvalidationResult> findInvalidated({
    @required DateTime lastCompiled,
    @required List<Uri> urisToMonitor,
    @required String packagesPath,
    @required PackageConfig packageConfig,
    bool asyncScanning = false,
  }) async {
    assert(urisToMonitor != null);
    assert(packagesPath != null);

    if (lastCompiled == null) {
      // Initial load.
      assert(urisToMonitor.isEmpty);
      return InvalidationResult(
        packageConfig: await _createPackageConfig(packagesPath),
        uris: <Uri>[]
      );
    }

    final Stopwatch stopwatch = Stopwatch()..start();
    final List<Uri> urisToScan = <Uri>[
      // Don't watch pub cache directories to speed things up a little.
      for (final Uri uri in urisToMonitor)
        if (_isNotInPubCache(uri)) uri,
    ];
    final List<Uri> invalidatedFiles = <Uri>[];
    if (asyncScanning) {
      final Pool pool = Pool(_kMaxPendingStats);
      final List<Future<void>> waitList = <Future<void>>[];
      for (final Uri uri in urisToScan) {
        waitList.add(pool.withResource<void>(
          () => _fileSystem
            .stat(uri.toFilePath(windows: _platform.isWindows))
            .then((FileStat stat) {
              final DateTime updatedAt = stat.modified;
              if (updatedAt != null && updatedAt.isAfter(lastCompiled)) {
                invalidatedFiles.add(uri);
              }
            })
        ));
      }
      await Future.wait<void>(waitList);
    } else {
      for (final Uri uri in urisToScan) {
        final DateTime updatedAt = _fileSystem.statSync(
            uri.toFilePath(windows: _platform.isWindows)).modified;
        if (updatedAt != null && updatedAt.isAfter(lastCompiled)) {
          invalidatedFiles.add(uri);
        }
      }
    }
    // We need to check the .packages file too since it is not used in compilation.
    final Uri packageUri = _fileSystem.file(packagesPath).uri;
    final DateTime updatedAt = _fileSystem.statSync(
      packageUri.toFilePath(windows: _platform.isWindows)).modified;
    if (updatedAt != null && updatedAt.isAfter(lastCompiled)) {
      invalidatedFiles.add(packageUri);
      packageConfig = await _createPackageConfig(packagesPath);
      // The frontend_server might be monitoring the package_config.json file,
      // Pub should always produce both files.
      // TODO(jonahwilliams): remove after https://github.com/flutter/flutter/issues/55249
      if (_fileSystem.path.basename(packagesPath) == '.packages') {
        final File packageConfigFile = _fileSystem.file(packagesPath)
          .parent.childDirectory('.dart_tool')
          .childFile('package_config.json');
        if (packageConfigFile.existsSync()) {
          invalidatedFiles.add(packageConfigFile.uri);
        }
      }
    }

    _logger.printTrace(
      'Scanned through ${urisToScan.length} files in '
      '${stopwatch.elapsedMilliseconds}ms'
      '${asyncScanning ? " (async)" : ""}',
    );
    return InvalidationResult(
      packageConfig: packageConfig,
      uris: invalidatedFiles,
    );
  }

  bool _isNotInPubCache(Uri uri) {
    return !(_platform.isWindows && uri.path.contains(_pubCachePathWindows))
        && !uri.path.contains(_pubCachePathLinuxAndMac);
  }

  Future<PackageConfig> _createPackageConfig(String packagesPath) {
    return loadPackageConfigWithLogging(
      _fileSystem.file(packagesPath),
      logger: _logger,
    );
  }
}

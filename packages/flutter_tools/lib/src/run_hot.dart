// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:pool/pool.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import 'base/common.dart';
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
import 'features.dart';
import 'globals.dart' as globals;
import 'project.dart';
import 'reporting/reporting.dart';
import 'resident_devtools_handler.dart';
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
    @required String target,
    @required DebuggingOptions debuggingOptions,
    this.benchmarkMode = false,
    this.applicationBinary,
    this.hostIsIde = false,
    String projectRootPath,
    String dillOutputPath,
    bool stayResident = true,
    bool ipv6 = false,
    bool machine = false,
    ResidentDevtoolsHandlerFactory devtoolsHandler = createDefaultHandler,
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
          devtoolsHandler: devtoolsHandler,
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

  /// Whether the resident runner has correctly attached to the running application.
  bool _didAttach = false;

  final Map<String, List<int>> benchmarkData = <String, List<int>>{};

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

  // Returns the exit code of the flutter tool process, like [run].
  @override
  Future<int> attach({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
    bool allowExistingDdsInstance = false,
    bool enableDevTools = false,
  }) async {
    _didAttach = true;
    try {
      await connectToServiceProtocol(
        reloadSources: _reloadSourcesService,
        restart: _restartService,
        compileExpression: _compileExpressionService,
        getSkSLMethod: writeSkSL,
        allowExistingDdsInstance: allowExistingDdsInstance,
      );
    // Catches all exceptions, non-Exception objects are rethrown.
    } catch (error) { // ignore: avoid_catches_without_on_clauses
      if (error is! Exception && error is! String) {
        rethrow;
      }
      globals.printError('Error connecting to the service protocol: $error');
      return 2;
    }

    if (enableDevTools) {
      // The method below is guaranteed never to return a failing future.
      unawaited(residentDevtoolsHandler.serveAndAnnounceDevTools(
        devToolsServerAddress: debuggingOptions.devToolsServerAddress,
        flutterDevices: flutterDevices,
      ));
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
    } on DevFSException catch (error) {
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
      final Uri deviceAssetsDirectoryUri = device.devFS.baseUri.resolveUri(globals.fs.path.toUri(getAssetBuildDirectory()));
      await Future.wait<void>(views.map<Future<void>>(
        (FlutterView view) => device.vmService.setAssetDirectory(
          assetsDirectory: deviceAssetsDirectoryUri,
          uiIsolateId: view.uiIsolate.id,
          viewId: view.id,
        )
      ));
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
        reason: 'restart',
        silent: true,
      );
    }

    appStartedCompleter?.complete();

    if (benchmarkMode) {
      // Wait multiple seconds for the isolate to have fully started.
      await Future<void>.delayed(const Duration(seconds: 10));
      // We are running in benchmark mode.
      globals.printStatus('Running in benchmark mode.');
      // Measure time to perform a hot restart.
      globals.printStatus('Benchmarking hot restart');
      await restart(fullRestart: true);
      // Wait multiple seconds to stabilize benchmark on slower devicelab hardware.
      // Hot restart finishes when the new isolate is started, not when the new isolate
      // is ready. This process can actually take multiple seconds.
      await Future<void>.delayed(const Duration(seconds: 10));

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
    writeVmServiceFile();

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
    bool enableDevTools = false,
    String route,
  }) async {
    File mainFile = globals.fs.file(mainPath);
    // `generated_main.dart` contains the Dart plugin registry.
    final Directory buildDir = FlutterProject.current()
        .directory
        .childDirectory(globals.fs.path.join('.dart_tool', 'flutter_build'));
    final File newMainDart = buildDir?.childFile('generated_main.dart');
    if (newMainDart != null && newMainDart.existsSync()) {
      mainFile = newMainDart;
    }
    firstBuildTime = DateTime.now();

    final List<Future<bool>> startupTasks = <Future<bool>>[];
    for (final FlutterDevice device in flutterDevices) {
      // Here we initialize the frontend_server concurrently with the platform
      // build, reducing overall initialization time. This is safe because the first
      // invocation of the frontend server produces a full dill file that the
      // subsequent invocation in devfs will not overwrite.
      await runSourceGenerators();
      if (device.generator != null) {
        startupTasks.add(
          device.generator.recompile(
            mainFile.uri,
            <Uri>[],
            // When running without a provided applicationBinary, the tool will
            // simultaneously run the initial frontend_server compilation and
            // the native build step. If there is a Dart compilation error, it
            // should only be displayed once.
            suppressErrors: applicationBinary == null,
            outputPath: dillOutputPath ??
              getDefaultApplicationKernelPath(
                trackWidgetCreation: debuggingOptions.buildInfo.trackWidgetCreation,
              ),
            packageConfig: debuggingOptions.buildInfo.packageConfig,
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
      enableDevTools: enableDevTools,
    );
  }

  Future<List<Uri>> _initDevFS() async {
    final String fsName = globals.fs.path.basename(projectRootPath);
    return <Uri>[
      for (final FlutterDevice device in flutterDevices)
        await device.setupDevFS(
          fsName,
          globals.fs.directory(projectRootPath),
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
      packageConfig: flutterDevices[0].devFS.lastPackageConfig
          ?? debuggingOptions.buildInfo.packageConfig,
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

  void _resetDevFSCompileTime() {
    for (final FlutterDevice device in flutterDevices) {
      device.devFS.resetLastCompiled();
    }
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

  Future<void> _launchFromDevFS() async {
    final List<Future<void>> futures = <Future<void>>[];
    for (final FlutterDevice device in flutterDevices) {
      final Uri deviceEntryUri = device.devFS.baseUri.resolve(_swap ? 'main.dart.swap.dill' : 'main.dart.dill');
      final Uri deviceAssetsDirectoryUri = device.devFS.baseUri.resolveUri(
        globals.fs.path.toUri(getAssetBuildDirectory()));
      futures.add(_launchInView(device,
                          deviceEntryUri,
                          deviceAssetsDirectoryUri));
    }
    await Future.wait(futures);
  }

  Future<OperationResult> _restartFromSources({
    String reason,
  }) async {
    final Stopwatch restartTimer = Stopwatch()..start();
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
      // will not be restarted, and so they must be manually killed.
      final vm_service.VM vm = await device.vmService.getVM();
      for (final vm_service.IsolateRef isolateRef in vm.isolates) {
        if (uiIsolatesIds.contains(isolateRef.id)) {
          continue;
        }
        operations.add(device.vmService.kill(isolateRef.id)
          .catchError((dynamic error, StackTrace stackTrace) {
            // Do nothing on a SentinelException since it means the isolate
            // has already been killed.
            // Error code 105 indicates the isolate is not yet runnable, and might
            // be triggered if the tool is attempting to kill the asset parsing
            // isolate before it has finished starting up.
          }, test: (dynamic error) => error is vm_service.SentinelException
            || (error is vm_service.RPCError && error.code == 105)));
      }
    }
    await Future.wait(operations);

    await _launchFromDevFS();
    restartTimer.stop();
    globals.printTrace('Hot restart performed in ${getElapsedAsMilliseconds(restartTimer.elapsed)}.');
    _addBenchmarkData('hotRestartMillisecondsToFrame',
        restartTimer.elapsed.inMilliseconds);

    // Send timing analytics.
    globals.flutterUsage.sendTiming('hot', 'restart', restartTimer.elapsed);

    // Toggle the main dill name after successfully uploading.
    _swap =! _swap;

    return OperationResult.ok;
  }

  /// Returns [true] if the reload was successful.
  /// Prints errors if [printErrors] is [true].
  static bool validateReloadReport(
    vm_service.ReloadReport reloadReport, {
    bool printErrors = true,
  }) {
    if (reloadReport == null) {
      if (printErrors) {
        globals.printError('Hot reload did not receive reload report.');
      }
      return false;
    }
    final ReloadReportContents contents = ReloadReportContents.fromReloadReport(reloadReport);
    if (!reloadReport.success) {
      if (printErrors) {
        globals.printError('Hot reload was rejected:');
        for (final ReasonForCancelling reason in contents.notices) {
          globals.printError(reason.toString());
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
    bool silent = false,
    bool pause = false,
  }) async {
    if (flutterDevices.any((FlutterDevice device) => device.devFS == null)) {
      return OperationResult(1, 'Device initialization has not completed.');
    }
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
        silent: silent,
      );
      if (!silent) {
        globals.printStatus('Restarted application in ${getElapsedAsMilliseconds(timer.elapsed)}.');
      }
      unawaited(residentDevtoolsHandler.hotRestart(flutterDevices));
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
    bool silent,
  }) async {
    if (!canHotRestart) {
      return OperationResult(1, 'hotRestart not supported');
    }
    Status status;
    if (!silent) {
      status = globals.logger.startProgress(
        'Performing hot restart...',
        progressId: 'hot.restart',
      );
    }
    OperationResult result;
    String restartEvent = 'restart';
    try {
      if (!(await hotRunnerConfig.setupHotRestart())) {
        return OperationResult(1, 'setupHotRestart failed');
      }
      result = await _restartFromSources(reason: reason,);
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
        reason: reason,
        fastReassemble: null,
      ).send();
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
            progressId: 'hot.reload',
          );
        },
      );
    } on vm_service.RPCError catch (error) {
      String errorMessage = 'hot reload failed to complete';
      int errorCode = 1;
      if (error.code == kIsolateReloadBarred) {
        errorCode = error.code;
        errorMessage = 'Unable to hot reload application due to an unrecoverable error in '
                      'the source code. Please address the error and then use "R" to '
                      'restart the app.\n'
                      '${error.message} (error code: ${error.code})';
        HotEvent('reload-barred',
          targetPlatform: targetPlatform,
          sdkName: sdkName,
          emulator: emulator,
          fullRestart: false,
          reason: reason,
          fastReassemble: null,
        ).send();
      } else {
        HotEvent('exception',
          targetPlatform: targetPlatform,
          sdkName: sdkName,
          emulator: emulator,
          fullRestart: false,
          reason: reason,
          fastReassemble: null,
        ).send();
      }
      return OperationResult(errorCode, errorMessage, fatal: true);
    } finally {
      status.cancel();
    }
    return result;
  }

  Future<List<Future<vm_service.ReloadReport>>> _reloadDeviceSources(
    FlutterDevice device,
    String entryPath, {
    bool pause = false,
  }) async {
    final String deviceEntryUri = device.devFS.baseUri
      .resolve(entryPath).toString();
    final vm_service.VM vm = await device.vmService.getVM();
    return <Future<vm_service.ReloadReport>>[
      for (final vm_service.IsolateRef isolateRef in vm.isolates)
        device.vmService.reloadSources(
          isolateRef.id,
          pause: pause,
          rootLibUri: deviceEntryUri,
        )
    ];
  }

  Future<OperationResult> _reloadSources({
    String targetPlatform,
    String sdkName,
    bool emulator,
    bool pause = false,
    String reason,
    void Function(String message) onSlow,
  }) async {
    final Map<FlutterDevice, List<FlutterView>> viewCache = <FlutterDevice, List<FlutterView>>{};
    for (final FlutterDevice device in flutterDevices) {
      final List<FlutterView> views = await device.vmService.getFlutterViews();
      viewCache[device] = views;
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
    String reloadMessage = 'Reloaded 0 libraries';
    final Map<String, Object> firstReloadDetails = <String, Object>{};
    if (updatedDevFS.invalidatedSourcesCount > 0) {
      final OperationResult result = await _reloadSourcesHelper(
        pause,
        firstReloadDetails,
        targetPlatform,
        sdkName,
        emulator,
        reason,
      );
      if (result.code != 0) {
        return result;
      }
      reloadMessage = result.message;
    } else {
      _addBenchmarkData('hotReloadVMReloadMilliseconds', 0);
    }

    final Stopwatch reassembleTimer = Stopwatch()..start();
    await _evictDirtyAssets();

    // Check if any isolates are paused and reassemble those that aren't.
    final Map<FlutterView, vm_service.VmService> reassembleViews = <FlutterView, vm_service.VmService>{};
    final List<Future<void>> reassembleFutures = <Future<void>>[];
    String serviceEventKind;
    int pausedIsolatesFound = 0;
    bool failedReassemble = false;
    for (final FlutterDevice device in flutterDevices) {
      final List<FlutterView> views = viewCache[device];
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
          if (updatedDevFS.fastReassembleClassName != null) {
            reassembleWork = device.vmService.flutterFastReassemble(
              isolateId: view.uiIsolate.id,
              className: updatedDevFS.fastReassembleClassName,
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
      finalLibraryCount: firstReloadDetails['finalLibraryCount'] as int ?? 0,
      syncedLibraryCount: firstReloadDetails['receivedLibraryCount'] as int ?? 0,
      syncedClassesCount: firstReloadDetails['receivedClassesCount'] as int ?? 0,
      syncedProceduresCount: firstReloadDetails['receivedProceduresCount'] as int ?? 0,
      syncedBytes: updatedDevFS.syncedBytes,
      invalidatedSourcesCount: updatedDevFS.invalidatedSourcesCount,
      transferTimeInMs: devFSTimer.elapsed.inMilliseconds,
      fastReassemble: featureFlags.isSingleWidgetReloadEnabled
        ? updatedDevFS.fastReassembleClassName != null
        : null,
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

  Future<OperationResult> _reloadSourcesHelper(
    bool pause,
    Map<String, dynamic> firstReloadDetails,
    String targetPlatform,
    String sdkName,
    bool emulator,
    String reason,
  ) async {
    final Stopwatch vmReloadTimer = Stopwatch()..start();
    const String entryPath = 'main.dart.incremental.dill';
    final List<Future<DeviceReloadReport>> allReportsFutures = <Future<DeviceReloadReport>>[];

    for (final FlutterDevice device in flutterDevices) {
      final List<Future<vm_service.ReloadReport>> reportFutures = await _reloadDeviceSources(
        device,
        entryPath,
        pause: pause,
      );
      allReportsFutures.add(Future.wait(reportFutures).then(
        (List<vm_service.ReloadReport> reports) async {
          // TODO(aam): Investigate why we are validating only first reload report,
          // which seems to be current behavior
          final vm_service.ReloadReport firstReport = reports.first;
          // Don't print errors because they will be printed further down when
          // `validateReloadReport` is called again.
          await device.updateReloadStatus(
            validateReloadReport(firstReport, printErrors: false),
          );
          return DeviceReloadReport(device, reports);
        },
      ));
    }
    final List<DeviceReloadReport> reports = await Future.wait(allReportsFutures);
    final vm_service.ReloadReport reloadReport = reports.first.reports[0];
    if (!validateReloadReport(reloadReport)) {
      // Reload failed.
      HotEvent('reload-reject',
        targetPlatform: targetPlatform,
        sdkName: sdkName,
        emulator: emulator,
        fullRestart: false,
        reason: reason,
        fastReassemble: null,
      ).send();
      // Reset devFS lastCompileTime to ensure the file will still be marked
      // as dirty on subsequent reloads.
      _resetDevFSCompileTime();
      final ReloadReportContents contents = ReloadReportContents.fromReloadReport(reloadReport);
      return OperationResult(1, 'Reload rejected: ${contents.notices.join("\n")}');
    }
    // Collect stats only from the first device. If/when run -d all is
    // refactored, we'll probably need to send one hot reload/restart event
    // per device to analytics.
    firstReloadDetails.addAll(castStringKeyedMap(reloadReport.json['details']));
    final int loadedLibraryCount = reloadReport.json['details']['loadedLibraryCount'] as int;
    final int finalLibraryCount = reloadReport.json['details']['finalLibraryCount'] as int;
    globals.printTrace('reloaded $loadedLibraryCount of $finalLibraryCount libraries');
    // reloadMessage = 'Reloaded $loadedLibraryCount of $finalLibraryCount libraries';
    // Record time it took for the VM to reload the sources.
    _addBenchmarkData('hotReloadVMReloadMilliseconds', vmReloadTimer.elapsed.inMilliseconds);
    return OperationResult(0, 'Reloaded $loadedLibraryCount of $finalLibraryCount libraries');
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
    commandHelp.h.print(); // TODO(ianh): print different message if "details" is false
    if (_didAttach) {
      commandHelp.d.print();
    }
    commandHelp.c.print();
    commandHelp.q.print();
    if (details) {
      printHelpDetails();
    }
    globals.printStatus('');
    if (debuggingOptions.buildInfo.nullSafetyMode ==  NullSafetyMode.sound) {
      globals.printStatus('💪 Running with sound null safety 💪', emphasis: true);
    } else {
      globals.printStatus(
        'Running with unsound null safety',
        emphasis: true,
      );
      globals.printStatus(
        'For more information see https://dart.dev/null-safety/unsound-null-safety',
      );
    }
    globals.printStatus('');
    printDebuggerList();
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
        packageConfig: packageConfig,
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

/// Additional serialization logic for a hot reload response.
class ReloadReportContents {
  factory ReloadReportContents.fromReloadReport(vm_service.ReloadReport report) {
    final List<ReasonForCancelling> reasons = <ReasonForCancelling>[];
    final Object notices = report.json['notices'];
    if (notices is! List<dynamic>) {
      return ReloadReportContents._(report.success, reasons, report);
    }
    for (final Object obj in notices as List<dynamic>) {
      if (obj is! Map<String, dynamic>) {
        continue;
      }
      final Map<String, dynamic> notice = obj as Map<String, dynamic>;
      reasons.add(ReasonForCancelling(
        message: notice['message'] is String
          ? notice['message'] as String
          : 'Unknown Error',
      ));
    }

    return ReloadReportContents._(report.success, reasons, report);
  }

  ReloadReportContents._(
    this.success,
    this.notices,
    this.report,
  );

  final bool success;
  final List<ReasonForCancelling> notices;
  final vm_service.ReloadReport report;
}

/// A serialization class for hot reload rejection reasons.
///
/// Injects an additional error message that a hot restart will
/// resolve the issue.
class ReasonForCancelling {
  ReasonForCancelling({
    this.message,
  });

  final String message;

  @override
  String toString() {
    return '$message.\nTry performing a hot restart instead.';
  }
}

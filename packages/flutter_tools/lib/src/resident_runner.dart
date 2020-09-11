// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:devtools_server/devtools_server.dart' as devtools_server;
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import 'application_package.dart';
import 'artifacts.dart';
import 'asset.dart';
import 'base/command_help.dart';
import 'base/common.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/io.dart' as io;
import 'base/logger.dart';
import 'base/signals.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'build_system/build_system.dart';
import 'build_system/targets/localizations.dart';
import 'bundle.dart';
import 'cache.dart';
import 'compile.dart';
import 'devfs.dart';
import 'device.dart';
import 'features.dart';
import 'globals.dart' as globals;
import 'project.dart';
import 'run_cold.dart';
import 'run_hot.dart';
import 'vmservice.dart';
import 'widget_cache.dart';

class FlutterDevice {
  FlutterDevice(
    this.device, {
    @required this.buildInfo,
    this.fileSystemRoots,
    this.fileSystemScheme,
    TargetModel targetModel = TargetModel.flutter,
    TargetPlatform targetPlatform,
    ResidentCompiler generator,
    this.userIdentifier,
    this.widgetCache,
  }) : assert(buildInfo.trackWidgetCreation != null),
       generator = generator ?? ResidentCompiler(
         globals.artifacts.getArtifactPath(
           Artifact.flutterPatchedSdkPath,
           platform: targetPlatform,
           mode: buildInfo.mode,
         ),
         buildMode: buildInfo.mode,
         trackWidgetCreation: buildInfo.trackWidgetCreation,
         fileSystemRoots: fileSystemRoots ?? <String>[],
         fileSystemScheme: fileSystemScheme,
         targetModel: targetModel,
         dartDefines: buildInfo.dartDefines,
         packagesPath: buildInfo.packagesPath,
         extraFrontEndOptions: buildInfo.extraFrontEndOptions,
         artifacts: globals.artifacts,
         processManager: globals.processManager,
         logger: globals.logger,
       );

  /// Create a [FlutterDevice] with optional code generation enabled.
  static Future<FlutterDevice> create(
    Device device, {
    @required FlutterProject flutterProject,
    @required String target,
    @required BuildInfo buildInfo,
    List<String> fileSystemRoots,
    String fileSystemScheme,
    TargetModel targetModel = TargetModel.flutter,
    List<String> experimentalFlags,
    ResidentCompiler generator,
    String userIdentifier,
    WidgetCache widgetCache,
  }) async {
    ResidentCompiler generator;
    final TargetPlatform targetPlatform = await device.targetPlatform;
    if (device.platformType == PlatformType.fuchsia) {
      targetModel = TargetModel.flutterRunner;
    }
    // For both web and non-web platforms we initialize dill to/from
    // a shared location for faster bootstrapping. If the compiler fails
    // due to a kernel target or version mismatch, no error is reported
    // and the compiler starts up as normal. Unexpected errors will print
    // a warning message and dump some debug information which can be
    // used to file a bug, but the compiler will still start up correctly.
    if (targetPlatform == TargetPlatform.web_javascript) {
      Artifact platformDillArtifact;
      List<String> extraFrontEndOptions;
      if (buildInfo.nullSafetyMode == NullSafetyMode.unsound) {
        platformDillArtifact = Artifact.webPlatformKernelDill;
        extraFrontEndOptions = buildInfo.extraFrontEndOptions;
      } else {
        platformDillArtifact = Artifact.webPlatformSoundKernelDill;
        extraFrontEndOptions = <String>[
          ...?buildInfo?.extraFrontEndOptions,
          if (!(buildInfo?.extraFrontEndOptions?.contains('--sound-null-safety') ?? false))
            '--sound-null-safety'
        ];
      }

      generator = ResidentCompiler(
        globals.artifacts.getArtifactPath(Artifact.flutterWebSdk, mode: buildInfo.mode),
        buildMode: buildInfo.mode,
        trackWidgetCreation: buildInfo.trackWidgetCreation,
        fileSystemRoots: fileSystemRoots ?? <String>[],
        // Override the filesystem scheme so that the frontend_server can find
        // the generated entrypoint code.
        fileSystemScheme: 'org-dartlang-app',
        initializeFromDill: getDefaultCachedKernelPath(
          trackWidgetCreation: buildInfo.trackWidgetCreation,
          dartDefines: buildInfo.dartDefines,
          extraFrontEndOptions: extraFrontEndOptions
        ),
        targetModel: TargetModel.dartdevc,
        extraFrontEndOptions: extraFrontEndOptions,
        platformDill: globals.fs.file(globals.artifacts
          .getArtifactPath(platformDillArtifact, mode: buildInfo.mode))
          .absolute.uri.toString(),
        dartDefines: buildInfo.dartDefines,
        librariesSpec: globals.fs.file(globals.artifacts
          .getArtifactPath(Artifact.flutterWebLibrariesJson)).uri.toString(),
        packagesPath: buildInfo.packagesPath,
        artifacts: globals.artifacts,
        processManager: globals.processManager,
        logger: globals.logger,
      );
    } else {
      generator = ResidentCompiler(
        globals.artifacts.getArtifactPath(
          Artifact.flutterPatchedSdkPath,
          platform: targetPlatform,
          mode: buildInfo.mode,
        ),
        buildMode: buildInfo.mode,
        trackWidgetCreation: buildInfo.trackWidgetCreation,
        fileSystemRoots: fileSystemRoots,
        fileSystemScheme: fileSystemScheme,
        targetModel: targetModel,
        dartDefines: buildInfo.dartDefines,
        extraFrontEndOptions: buildInfo.extraFrontEndOptions,
        initializeFromDill: getDefaultCachedKernelPath(
          trackWidgetCreation: buildInfo.trackWidgetCreation,
          dartDefines: buildInfo.dartDefines,
          extraFrontEndOptions: buildInfo.extraFrontEndOptions,
        ),
        packagesPath: buildInfo.packagesPath,
        artifacts: globals.artifacts,
        processManager: globals.processManager,
        logger: globals.logger,
      );
    }

    return FlutterDevice(
      device,
      fileSystemRoots: fileSystemRoots,
      fileSystemScheme:fileSystemScheme,
      targetModel: targetModel,
      targetPlatform: targetPlatform,
      generator: generator,
      buildInfo: buildInfo,
      userIdentifier: userIdentifier,
      widgetCache: widgetCache,
    );
  }

  final Device device;
  final ResidentCompiler generator;
  final BuildInfo buildInfo;
  final String userIdentifier;
  final WidgetCache widgetCache;
  Stream<Uri> observatoryUris;
  vm_service.VmService vmService;
  DevFS devFS;
  ApplicationPackage package;
  List<String> fileSystemRoots;
  String fileSystemScheme;
  StreamSubscription<String> _loggingSubscription;
  bool _isListeningForObservatoryUri;

  /// Whether the stream [observatoryUris] is still open.
  bool get isWaitingForObservatory => _isListeningForObservatoryUri ?? false;

  /// If the [reloadSources] parameter is not null the 'reloadSources' service
  /// will be registered.
  /// The 'reloadSources' service can be used by other Service Protocol clients
  /// connected to the VM (e.g. Observatory) to request a reload of the source
  /// code of the running application (a.k.a. HotReload).
  /// The 'compileExpression' service can be used to compile user-provided
  /// expressions requested during debugging of the application.
  /// This ensures that the reload process follows the normal orchestration of
  /// the Flutter Tools and not just the VM internal service.
  Future<void> connect({
    ReloadSources reloadSources,
    Restart restart,
    CompileExpression compileExpression,
    ReloadMethod reloadMethod,
    GetSkSLMethod getSkSLMethod,
    PrintStructuredErrorLogMethod printStructuredErrorLogMethod,
    bool disableDds = false,
    bool ipv6 = false,
  }) {
    final Completer<void> completer = Completer<void>();
    StreamSubscription<void> subscription;
    bool isWaitingForVm = false;

    subscription = observatoryUris.listen((Uri observatoryUri) async {
      // FYI, this message is used as a sentinel in tests.
      globals.printTrace('Connecting to service protocol: $observatoryUri');
      isWaitingForVm = true;
      vm_service.VmService service;
      if (!disableDds) {
        await device.dds.startDartDevelopmentService(
          observatoryUri,
          ipv6,
        );
      }
      try {
        service = await connectToVmService(
          observatoryUri,
          reloadSources: reloadSources,
          restart: restart,
          compileExpression: compileExpression,
          reloadMethod: reloadMethod,
          getSkSLMethod: getSkSLMethod,
          printStructuredErrorLogMethod: printStructuredErrorLogMethod,
          device: device,
        );
      } on Exception catch (exception) {
        globals.printTrace('Fail to connect to service protocol: $observatoryUri: $exception');
        if (!completer.isCompleted && !_isListeningForObservatoryUri) {
          completer.completeError('failed to connect to $observatoryUri');
        }
        return;
      }
      if (completer.isCompleted) {
        return;
      }
      globals.printTrace('Successfully connected to service protocol: $observatoryUri');

      vmService = service;
      (await device.getLogReader(app: package)).connectedVMService = vmService;
      completer.complete();
      await subscription.cancel();
    }, onError: (dynamic error) {
      globals.printTrace('Fail to handle observatory URI: $error');
    }, onDone: () {
      _isListeningForObservatoryUri = false;
      if (!completer.isCompleted && !isWaitingForVm) {
        completer.completeError('connection to device ended too early');
      }
    });
    _isListeningForObservatoryUri = true;
    return completer.future;
  }

  Future<void> exitApps({
    @visibleForTesting Duration timeoutDelay = const Duration(seconds: 10),
  }) async {
    if (!device.supportsFlutterExit || vmService == null) {
      return device.stopApp(package, userIdentifier: userIdentifier);
    }
    final List<FlutterView> views = await vmService.getFlutterViews();
    if (views == null || views.isEmpty) {
      return device.stopApp(package, userIdentifier: userIdentifier);
    }
    // If any of the flutter views are paused, we might not be able to
    // cleanly exit since the service extension may not have been registered.
    for (final FlutterView flutterView in views) {
      final vm_service.Isolate isolate = await vmService
        .getIsolateOrNull(flutterView.uiIsolate.id);
      if (isolate == null) {
        continue;
      }
      if (isPauseEvent(isolate.pauseEvent.kind)) {
        return device.stopApp(package, userIdentifier: userIdentifier);
      }
    }
    for (final FlutterView view in views) {
      if (view != null && view.uiIsolate != null) {
        // If successful, there will be no response from flutterExit.
        unawaited(vmService.flutterExit(
          isolateId: view.uiIsolate.id,
        ));
      }
    }
    return vmService.onDone
      .catchError((dynamic error, StackTrace stackTrace) {
        globals.logger.printError(
          'unhanlded error waiting for vm service exit:\n $error',
          stackTrace: stackTrace,
         );
      })
      .timeout(timeoutDelay, onTimeout: () {
        // TODO(jonahwilliams): this only seems to fail on CI in the
        // flutter_attach_android_test. This log should help verify this
        // is where the tool is getting stuck.
        globals.logger.printTrace('error: vm service shutdown failed');
        return device.stopApp(package, userIdentifier: userIdentifier);
      });
  }

  Future<Uri> setupDevFS(
    String fsName,
    Directory rootDirectory, {
    String packagesFilePath,
  }) {
    // One devFS per device. Shared by all running instances.
    devFS = DevFS(
      vmService,
      fsName,
      rootDirectory,
      osUtils: globals.os,
      fileSystem: globals.fs,
      logger: globals.logger,
    );
    return devFS.create();
  }

  Future<List<Future<vm_service.ReloadReport>>> reloadSources(
    String entryPath, {
    bool pause = false,
  }) async {
    final String deviceEntryUri = devFS.baseUri
      .resolveUri(globals.fs.path.toUri(entryPath)).toString();
    final vm_service.VM vm = await vmService.getVM();
    return <Future<vm_service.ReloadReport>>[
      for (final vm_service.IsolateRef isolateRef in vm.isolates)
        vmService.reloadSources(
          isolateRef.id,
          pause: pause,
          rootLibUri: deviceEntryUri,
        )
    ];
  }

  Future<void> resetAssetDirectory() async {
    final Uri deviceAssetsDirectoryUri = devFS.baseUri.resolveUri(
        globals.fs.path.toUri(getAssetBuildDirectory()));
    assert(deviceAssetsDirectoryUri != null);
    final List<FlutterView> views = await vmService.getFlutterViews();
    await Future.wait<void>(views.map<Future<void>>(
      (FlutterView view) => vmService.setAssetDirectory(
        assetsDirectory: deviceAssetsDirectoryUri,
        uiIsolateId: view.uiIsolate.id,
        viewId: view.id,
      )
    ));
  }

  Future<void> debugDumpApp() async {
    final List<FlutterView> views = await vmService.getFlutterViews();
    for (final FlutterView view in views) {
      await vmService.flutterDebugDumpApp(
        isolateId: view.uiIsolate.id,
      );
    }
  }

  Future<void> debugDumpRenderTree() async {
    final List<FlutterView> views = await vmService.getFlutterViews();
    for (final FlutterView view in views) {
      await vmService.flutterDebugDumpRenderTree(
        isolateId: view.uiIsolate.id,
      );
    }
  }

  Future<void> debugDumpLayerTree() async {
    final List<FlutterView> views = await vmService.getFlutterViews();
    for (final FlutterView view in views) {
      await vmService.flutterDebugDumpLayerTree(
        isolateId: view.uiIsolate.id,
      );
    }
  }

  Future<void> debugDumpSemanticsTreeInTraversalOrder() async {
    final List<FlutterView> views = await vmService.getFlutterViews();
    for (final FlutterView view in views) {
      await vmService.flutterDebugDumpSemanticsTreeInTraversalOrder(
        isolateId: view.uiIsolate.id,
      );
    }
  }

  Future<void> debugDumpSemanticsTreeInInverseHitTestOrder() async {
    final List<FlutterView> views = await vmService.getFlutterViews();
    for (final FlutterView view in views) {
      await vmService.flutterDebugDumpSemanticsTreeInInverseHitTestOrder(
        isolateId: view.uiIsolate.id,
      );
    }
  }

  Future<void> toggleDebugPaintSizeEnabled() async {
    final List<FlutterView> views = await vmService.getFlutterViews();
    for (final FlutterView view in views) {
      await vmService.flutterToggleDebugPaintSizeEnabled(
        isolateId: view.uiIsolate.id,
      );
    }
  }

  Future<void> toggleDebugCheckElevationsEnabled() async {
    final List<FlutterView> views = await vmService.getFlutterViews();
    for (final FlutterView view in views) {
      await vmService.flutterToggleDebugCheckElevationsEnabled(
        isolateId: view.uiIsolate.id,
      );
    }
  }

  Future<void> debugTogglePerformanceOverlayOverride() async {
    final List<FlutterView> views = await vmService.getFlutterViews();
    for (final FlutterView view in views) {
      await vmService.flutterTogglePerformanceOverlayOverride(
        isolateId: view.uiIsolate.id,
      );
    }
  }

  Future<void> toggleWidgetInspector() async {
    final List<FlutterView> views = await vmService.getFlutterViews();
    for (final FlutterView view in views) {
      await vmService.flutterToggleWidgetInspector(
        isolateId: view.uiIsolate.id,
      );
    }
  }

  Future<void> toggleInvertOversizedImages() async {
    final List<FlutterView> views = await vmService.getFlutterViews();
    for (final FlutterView view in views) {
      await vmService.flutterToggleInvertOversizedImages(
        isolateId: view.uiIsolate.id,
      );
    }
  }

  Future<void> toggleProfileWidgetBuilds() async {
    final List<FlutterView> views = await vmService.getFlutterViews();
    for (final FlutterView view in views) {
      await vmService.flutterToggleProfileWidgetBuilds(
        isolateId: view.uiIsolate.id,
      );
    }
  }

  Future<Brightness> toggleBrightness({ Brightness current }) async {
    final List<FlutterView> views = await vmService.getFlutterViews();
    Brightness next;
    if (current == Brightness.light) {
      next = Brightness.dark;
    } else if (current == Brightness.dark) {
      next = Brightness.light;
    }

    for (final FlutterView view in views) {
      next = await vmService.flutterBrightnessOverride(
        isolateId: view.uiIsolate.id,
        brightness: next,
      );
    }
    return next;
  }

  Future<String> togglePlatform({ String from }) async {
    final List<FlutterView> views = await vmService.getFlutterViews();
    final String to = nextPlatform(from, featureFlags);
    for (final FlutterView view in views) {
      await vmService.flutterPlatformOverride(
        platform: to,
        isolateId: view.uiIsolate.id,
      );
    }
    return to;
  }

  Future<void> startEchoingDeviceLog() async {
    if (_loggingSubscription != null) {
      return;
    }
    final Stream<String> logStream = (await device.getLogReader(app: package)).logLines;
    if (logStream == null) {
      globals.printError('Failed to read device log stream');
      return;
    }
    _loggingSubscription = logStream.listen((String line) {
      if (!line.contains('Observatory listening on http')) {
        globals.printStatus(line, wrap: false);
      }
    });
  }

  Future<void> stopEchoingDeviceLog() async {
    if (_loggingSubscription == null) {
      return;
    }
    await _loggingSubscription.cancel();
    _loggingSubscription = null;
  }

  Future<void> initLogReader() async {
    final vm_service.VM vm = await vmService.getVM();
    final DeviceLogReader logReader = await device.getLogReader(app: package);
    logReader.appPid = vm.pid;
  }

  Future<int> runHot({
    HotRunner hotRunner,
    String route,
  }) async {
    final bool prebuiltMode = hotRunner.applicationBinary != null;
    final String modeName = hotRunner.debuggingOptions.buildInfo.friendlyModeName;
    globals.printStatus(
      'Launching ${globals.fsUtils.getDisplayPath(hotRunner.mainPath)} '
      'on ${device.name} in $modeName mode...',
    );

    final TargetPlatform targetPlatform = await device.targetPlatform;
    package = await ApplicationPackageFactory.instance.getPackageForPlatform(
      targetPlatform,
      buildInfo: hotRunner.debuggingOptions.buildInfo,
      applicationBinary: hotRunner.applicationBinary,
    );

    if (package == null) {
      String message = 'No application found for $targetPlatform.';
      final String hint = await getMissingPackageHintForPlatform(targetPlatform);
      if (hint != null) {
        message += '\n$hint';
      }
      globals.printError(message);
      return 1;
    }

    final Map<String, dynamic> platformArgs = <String, dynamic>{};

    await startEchoingDeviceLog();

    // Start the application.
    final Future<LaunchResult> futureResult = device.startApp(
      package,
      mainPath: hotRunner.mainPath,
      debuggingOptions: hotRunner.debuggingOptions,
      platformArgs: platformArgs,
      route: route,
      prebuiltApplication: prebuiltMode,
      ipv6: hotRunner.ipv6,
      userIdentifier: userIdentifier,
    );

    final LaunchResult result = await futureResult;

    if (!result.started) {
      globals.printError('Error launching application on ${device.name}.');
      await stopEchoingDeviceLog();
      return 2;
    }
    if (result.hasObservatory) {
      observatoryUris = Stream<Uri>
        .value(result.observatoryUri)
        .asBroadcastStream();
    } else {
      observatoryUris = const Stream<Uri>
        .empty()
        .asBroadcastStream();
    }
    return 0;
  }


  Future<int> runCold({
    ColdRunner coldRunner,
    String route,
  }) async {
    final TargetPlatform targetPlatform = await device.targetPlatform;
    package = await ApplicationPackageFactory.instance.getPackageForPlatform(
      targetPlatform,
      buildInfo: coldRunner.debuggingOptions.buildInfo,
      applicationBinary: coldRunner.applicationBinary,
    );

    final String modeName = coldRunner.debuggingOptions.buildInfo.friendlyModeName;
    final bool prebuiltMode = coldRunner.applicationBinary != null;
    if (coldRunner.mainPath == null) {
      assert(prebuiltMode);
      globals.printStatus(
        'Launching ${package.displayName} '
        'on ${device.name} in $modeName mode...',
      );
    } else {
      globals.printStatus(
        'Launching ${globals.fsUtils.getDisplayPath(coldRunner.mainPath)} '
        'on ${device.name} in $modeName mode...',
      );
    }

    if (package == null) {
      String message = 'No application found for $targetPlatform.';
      final String hint = await getMissingPackageHintForPlatform(targetPlatform);
      if (hint != null) {
        message += '\n$hint';
      }
      globals.printError(message);
      return 1;
    }

    final Map<String, dynamic> platformArgs = <String, dynamic>{};
    if (coldRunner.traceStartup != null) {
      platformArgs['trace-startup'] = coldRunner.traceStartup;
    }

    await startEchoingDeviceLog();

    final LaunchResult result = await device.startApp(
      package,
      mainPath: coldRunner.mainPath,
      debuggingOptions: coldRunner.debuggingOptions,
      platformArgs: platformArgs,
      route: route,
      prebuiltApplication: prebuiltMode,
      ipv6: coldRunner.ipv6,
      userIdentifier: userIdentifier,
    );

    if (!result.started) {
      globals.printError('Error running application on ${device.name}.');
      await stopEchoingDeviceLog();
      return 2;
    }
    if (result.hasObservatory) {
      observatoryUris = Stream<Uri>
        .value(result.observatoryUri)
        .asBroadcastStream();
    } else {
      observatoryUris = const Stream<Uri>
        .empty()
        .asBroadcastStream();
    }
    return 0;
  }

  /// Validates whether this hot reload is a candidate for a fast reassemble.
  Future<bool> _attemptFastReassembleCheck(List<Uri> invalidatedFiles, PackageConfig packageConfig) async {
    if (invalidatedFiles.length != 1 || widgetCache == null) {
      return false;
    }
    final List<FlutterView> views = await vmService.getFlutterViews();
    final String widgetName = await widgetCache?.validateLibrary(invalidatedFiles.single);
    if (widgetName == null) {
      return false;
    }
    final String packageUri = packageConfig.toPackageUri(invalidatedFiles.single)?.toString()
      ?? invalidatedFiles.single.toString();
    for (final FlutterView view in views) {
      final vm_service.Isolate isolate = await vmService.getIsolateOrNull(view.uiIsolate.id);
      final vm_service.LibraryRef targetLibrary = isolate.libraries
        .firstWhere(
          (vm_service.LibraryRef libraryRef) => libraryRef.uri == packageUri,
          orElse: () => null,
        );
      if (targetLibrary == null) {
        return false;
      }
      try {
        // Evaluate an expression to allow type checking for that invalidated widget
        // name. For more information, see `debugFastReassembleMethod` in flutter/src/widgets/binding.dart
        await vmService.evaluate(
          view.uiIsolate.id,
          targetLibrary.id,
          '((){debugFastReassembleMethod=(Object _fastReassembleParam) => _fastReassembleParam is $widgetName})()',
        );
      } on Exception catch (err) {
        globals.printTrace(err.toString());
        return false;
      }
    }
    return true;
  }

  Future<UpdateFSReport> updateDevFS({
    Uri mainUri,
    String target,
    AssetBundle bundle,
    DateTime firstBuildTime,
    bool bundleFirstUpload = false,
    bool bundleDirty = false,
    bool fullRestart = false,
    String projectRootPath,
    String pathToReload,
    @required String dillOutputPath,
    @required List<Uri> invalidatedFiles,
    @required PackageConfig packageConfig,
  }) async {
    final Status devFSStatus = globals.logger.startProgress(
      'Syncing files to device ${device.name}...',
      timeout: timeoutConfiguration.fastOperation,
    );
    UpdateFSReport report;
    bool fastReassemble = false;
    try {
      await Future.wait(<Future<void>>[
        devFS.update(
          mainUri: mainUri,
          target: target,
          bundle: bundle,
          firstBuildTime: firstBuildTime,
          bundleFirstUpload: bundleFirstUpload,
          generator: generator,
          fullRestart: fullRestart,
          dillOutputPath: dillOutputPath,
          trackWidgetCreation: buildInfo.trackWidgetCreation,
          projectRootPath: projectRootPath,
          pathToReload: pathToReload,
          invalidatedFiles: invalidatedFiles,
          packageConfig: packageConfig,
        ).then((UpdateFSReport newReport) => report = newReport),
        if (!fullRestart)
          _attemptFastReassembleCheck(
            invalidatedFiles,
            packageConfig,
          ).then((bool newFastReassemble) => fastReassemble = newFastReassemble)
      ]);
      if (fastReassemble) {
        globals.logger.printTrace('Attempting fast reassemble.');
      }
      report.fastReassemble = fastReassemble;
    } on DevFSException {
      devFSStatus.cancel();
      return UpdateFSReport(success: false);
    }
    devFSStatus.stop();
    globals.printTrace('Synced ${getSizeAsMB(report.syncedBytes)}.');
    return report;
  }

  Future<void> updateReloadStatus(bool wasReloadSuccessful) async {
    if (wasReloadSuccessful) {
      generator?.accept();
    } else {
      await generator?.reject();
    }
  }
}

// Shared code between different resident application runners.
abstract class ResidentRunner {
  ResidentRunner(
    this.flutterDevices, {
    this.target,
    @required this.debuggingOptions,
    String projectRootPath,
    this.ipv6,
    this.stayResident = true,
    this.hotMode = true,
    String dillOutputPath,
    this.machine = false,
  }) : mainPath = findMainDartFile(target),
       packagesFilePath = debuggingOptions.buildInfo.packagesPath,
       projectRootPath = projectRootPath ?? globals.fs.currentDirectory.path,
       _dillOutputPath = dillOutputPath,
       artifactDirectory = dillOutputPath == null
          ? globals.fs.systemTempDirectory.createTempSync('flutter_tool.')
          : globals.fs.file(dillOutputPath).parent,
       assetBundle = AssetBundleFactory.instance.createBundle(),
       commandHelp = CommandHelp(
         logger: globals.logger,
         terminal: globals.terminal,
         platform: globals.platform,
         outputPreferences: globals.outputPreferences,
       ) {
    if (!artifactDirectory.existsSync()) {
      artifactDirectory.createSync(recursive: true);
    }
  }

  @protected
  @visibleForTesting
  final List<FlutterDevice> flutterDevices;

  final String target;
  final DebuggingOptions debuggingOptions;
  final bool stayResident;
  final bool ipv6;
  final String _dillOutputPath;
  /// The parent location of the incremental artifacts.
  final Directory artifactDirectory;
  final String packagesFilePath;
  final String projectRootPath;
  final String mainPath;
  final AssetBundle assetBundle;

  final CommandHelp commandHelp;
  final bool machine;

  DevtoolsLauncher _devtoolsLauncher;

  bool _exited = false;
  Completer<int> _finished = Completer<int>();
  bool hotMode;

  /// Whether the compiler was instructed to run with null-safety enabled.
  @protected
  bool get usageNullSafety => debuggingOptions?.buildInfo
    ?.extraFrontEndOptions?.any((String option) => option.contains('non-nullable')) ?? false;

  /// Returns true if every device is streaming observatory URIs.
  bool get isWaitingForObservatory {
    return flutterDevices.every((FlutterDevice device) {
      return device.isWaitingForObservatory;
    });
  }

  String get dillOutputPath => _dillOutputPath ?? globals.fs.path.join(artifactDirectory.path, 'app.dill');
  String getReloadPath({
    bool fullRestart = false,
    @required bool swap,
  }) {
    if (!fullRestart) {
      return '$mainPath.incremental.dill';
    }
    return '$mainPath${swap ? '.swap' : ''}.dill';
  }

  bool get debuggingEnabled => debuggingOptions.debuggingEnabled;
  bool get isRunningDebug => debuggingOptions.buildInfo.isDebug;
  bool get isRunningProfile => debuggingOptions.buildInfo.isProfile;
  bool get isRunningRelease => debuggingOptions.buildInfo.isRelease;
  bool get supportsServiceProtocol => isRunningDebug || isRunningProfile;
  bool get supportsCanvasKit => false;
  bool get supportsWriteSkSL => supportsServiceProtocol;
  bool get trackWidgetCreation => debuggingOptions.buildInfo.trackWidgetCreation;

  // Returns the Uri of the first connected device for mobile,
  // and only connected device for web.
  //
  // Would be null if there is no device connected or
  // there is no devFS associated with the first device.
  Uri get uri => flutterDevices.first?.devFS?.baseUri;

  /// Returns [true] if the resident runner exited after invoking [exit()].
  bool get exited => _exited;

  /// Whether this runner can hot restart.
  ///
  /// To prevent scenarios where only a subset of devices are hot restarted,
  /// the runner requires that all attached devices can support hot restart
  /// before enabling it.
  bool get canHotRestart {
    return flutterDevices.every((FlutterDevice device) {
      return device.device.supportsHotRestart;
    });
  }

  /// Invoke an RPC extension method on the first attached ui isolate of the first device.
  // TODO(jonahwilliams): Update/Remove this method when refactoring the resident
  // runner to support a single flutter device.
  Future<Map<String, dynamic>> invokeFlutterExtensionRpcRawOnFirstIsolate(
    String method, {
    Map<String, dynamic> params,
  }) async {
    final List<FlutterView> views = await flutterDevices
      .first
      .vmService.getFlutterViews();
    return flutterDevices
      .first
      .vmService
      .invokeFlutterExtensionRpcRaw(
        method,
        args: params,
        isolateId: views
          .first.uiIsolate.id
      );
  }

  /// Whether this runner can hot reload.
  bool get canHotReload => hotMode;

  /// Start the app and keep the process running during its lifetime.
  ///
  /// Returns the exit code that we should use for the flutter tool process; 0
  /// for success, 1 for user error (e.g. bad arguments), 2 for other failures.
  Future<int> run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
    String route,
  });

  Future<int> attach({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
  });

  bool get supportsRestart => false;

  Future<OperationResult> restart({ bool fullRestart = false, bool pause = false, String reason }) {
    final String mode = isRunningProfile ? 'profile' :
        isRunningRelease ? 'release' : 'this';
    throw '${fullRestart ? 'Restart' : 'Reload'} is not supported in $mode mode';
  }


  BuildResult _lastBuild;
  Environment _environment;
  Future<void> runSourceGenerators() async {
    _environment ??= Environment(
      artifacts: globals.artifacts,
      logger: globals.logger,
      cacheDir: globals.cache.getRoot(),
      engineVersion: globals.flutterVersion.engineRevision,
      fileSystem: globals.fs,
      flutterRootDir: globals.fs.directory(Cache.flutterRoot),
      outputDir: globals.fs.directory(getBuildDirectory()),
      processManager: globals.processManager,
      projectDir: globals.fs.currentDirectory,
    );
    globals.logger.printTrace('Starting incremental build...');
    _lastBuild = await globals.buildSystem.buildIncremental(
      const GenerateLocalizationsTarget(),
      _environment,
      _lastBuild,
    );
    if (!_lastBuild.success) {
      for (final ExceptionMeasurement exceptionMeasurement in _lastBuild.exceptions.values) {
        globals.logger.printError(
          exceptionMeasurement.exception.toString(),
          stackTrace: globals.logger.isVerbose
            ? exceptionMeasurement.stackTrace
            : null,
        );
      }
    }
    globals.logger.printTrace('complete');
  }

  /// Toggle whether canvaskit is being used for rendering, returning the new
  /// state.
  ///
  /// Only supported on the web.
  Future<bool> toggleCanvaskit() {
    throw Exception('Canvaskit not supported by this runner.');
  }

  /// Write the SkSL shaders to a zip file in build directory.
  ///
  /// Returns the name of the file, or `null` on failures.
  Future<String> writeSkSL() async {
    if (!supportsWriteSkSL) {
      throw Exception('writeSkSL is not supported by this runner.');
    }
    final List<FlutterView> views = await flutterDevices
      .first
      .vmService.getFlutterViews();
    final Map<String, Object> data = await flutterDevices.first.vmService.getSkSLs(
      viewId: views.first.id,
    );
    final Device device = flutterDevices.first.device;
    return sharedSkSlWriter(device, data);
  }

  /// The resident runner API for interaction with the reloadMethod vmservice
  /// request.
  ///
  /// This API should only be called for UI only-changes spanning a single
  /// library/Widget.
  ///
  /// The value [classId] should be the identifier of the StatelessWidget that
  /// was invalidated, or the StatefulWidget for the corresponding State class
  /// that was invalidated. This must be provided.
  ///
  /// The value [libraryId] should be the absolute file URI for the containing
  /// library of the widget that was invalidated. This must be provided.
  Future<OperationResult> reloadMethod({ String classId, String libraryId }) {
    throw UnsupportedError('Method is not supported.');
  }

  @protected
  void writeVmserviceFile() {
    if (debuggingOptions.vmserviceOutFile != null) {
      try {
        final String address = flutterDevices.first.vmService.wsAddress.toString();
        final File vmserviceOutFile = globals.fs.file(debuggingOptions.vmserviceOutFile);
        vmserviceOutFile.createSync(recursive: true);
        vmserviceOutFile.writeAsStringSync(address);
      } on FileSystemException {
        globals.printError('Failed to write vmservice-out-file at ${debuggingOptions.vmserviceOutFile}');
      }
    }
  }

  Future<void> exit() async {
    _exited = true;
    await shutdownDevtools();
    await stopEchoingDeviceLog();
    await preExit();
    await exitApp();
    await shutdownDartDevelopmentService();
  }

  Future<void> detach() async {
    await shutdownDevtools();
    await stopEchoingDeviceLog();
    await preExit();
    await shutdownDartDevelopmentService();
    appFinished();
  }

  Future<void> debugDumpApp() async {
    for (final FlutterDevice device in flutterDevices) {
      await device.debugDumpApp();
    }
  }

  Future<void> debugDumpRenderTree() async {
    for (final FlutterDevice device in flutterDevices) {
      await device.debugDumpRenderTree();
    }
  }

  Future<void> debugDumpLayerTree() async {
    for (final FlutterDevice device in flutterDevices) {
      await device.debugDumpLayerTree();
    }
  }

  Future<void> debugDumpSemanticsTreeInTraversalOrder() async {
    for (final FlutterDevice device in flutterDevices) {
      await device.debugDumpSemanticsTreeInTraversalOrder();
    }
  }

  Future<void> debugDumpSemanticsTreeInInverseHitTestOrder() async {
    for (final FlutterDevice device in flutterDevices) {
      await device.debugDumpSemanticsTreeInInverseHitTestOrder();
    }
  }

  Future<void> debugToggleDebugPaintSizeEnabled() async {
    for (final FlutterDevice device in flutterDevices) {
      await device.toggleDebugPaintSizeEnabled();
    }
  }

  Future<void> debugToggleDebugCheckElevationsEnabled() async {
    for (final FlutterDevice device in flutterDevices) {
      await device.toggleDebugCheckElevationsEnabled();
    }
  }

  Future<void> debugTogglePerformanceOverlayOverride() async {
    for (final FlutterDevice device in flutterDevices) {
      await device.debugTogglePerformanceOverlayOverride();
    }
  }

  Future<void> debugToggleWidgetInspector() async {
    for (final FlutterDevice device in flutterDevices) {
      await device.toggleWidgetInspector();
    }
  }

  Future<void> debugToggleInvertOversizedImages() async {
    for (final FlutterDevice device in flutterDevices) {
      await device.toggleInvertOversizedImages();
    }
  }

  Future<void> debugToggleProfileWidgetBuilds() async {
    for (final FlutterDevice device in flutterDevices) {
      await device.toggleProfileWidgetBuilds();
    }
  }

  Future<void> debugToggleBrightness() async {
    final Brightness brightness = await flutterDevices.first.toggleBrightness();
    Brightness next;
    for (final FlutterDevice device in flutterDevices) {
      next = await device.toggleBrightness(
        current: brightness,
      );
      globals.logger.printStatus('Changed brightness to $next.');
    }
  }

  /// Take a screenshot on the provided [device].
  ///
  /// If the device has a connected vmservice, this method will attempt to hide
  /// and restore the debug banner before taking the screenshot.
  ///
  /// Throws an [AssertionError] if [Devce.supportsScreenshot] is not true.
  Future<void> screenshot(FlutterDevice device) async {
    assert(device.device.supportsScreenshot);

    final Status status = globals.logger.startProgress(
      'Taking screenshot for ${device.device.name}...',
      timeout: timeoutConfiguration.fastOperation,
    );
    final File outputFile = globals.fsUtils.getUniqueFile(
      globals.fs.currentDirectory,
      'flutter',
      'png',
    );
    List<FlutterView> views = <FlutterView>[];
    Future<bool> setDebugBanner(bool value) async {
      try {
        for (final FlutterView view in views) {
          await device.vmService.flutterDebugAllowBanner(
            value,
            isolateId: view.uiIsolate.id,
          );
        }
        return true;
      } on Exception catch (error) {
        status.cancel();
        globals.printError('Error communicating with Flutter on the device: $error');
        return false;
      }
    }

    try {
      if (supportsServiceProtocol && isRunningDebug) {
        // Ensure that the vmService access is guarded by supportsServiceProtocol, it
        // will be null in release mode.
        views = await device.vmService.getFlutterViews();
        if (!await setDebugBanner(false)) {
          return;
        }
      }
      try {
        await device.device.takeScreenshot(outputFile);
      } finally {
        if (supportsServiceProtocol && isRunningDebug) {
          await setDebugBanner(true);
        }
      }
      final int sizeKB = outputFile.lengthSync() ~/ 1024;
      status.stop();
      globals.printStatus(
        'Screenshot written to ${globals.fs.path.relative(outputFile.path)} (${sizeKB}kB).',
      );
    } on Exception catch (error) {
      status.cancel();
      globals.printError('Error taking screenshot: $error');
    }
  }

  Future<void> debugTogglePlatform() async {
    final List<FlutterView> views = await flutterDevices
      .first
      .vmService.getFlutterViews();
    final String isolateId = views.first.uiIsolate.id;
    final String from = await flutterDevices
      .first.vmService.flutterPlatformOverride(
        isolateId: isolateId,
      );
    String to;
    for (final FlutterDevice device in flutterDevices) {
      to = await device.togglePlatform(from: from);
    }
    globals.printStatus('Switched operating system to $to');
  }

  Future<void> stopEchoingDeviceLog() async {
    await Future.wait<void>(
      flutterDevices.map<Future<void>>((FlutterDevice device) => device.stopEchoingDeviceLog())
    );
  }

  Future<void> shutdownDartDevelopmentService() async {
    await Future.wait<void>(
      flutterDevices.map<Future<void>>(
        (FlutterDevice device) => device.device?.dds?.shutdown()
      ).where((Future<void> element) => element != null)
    );
  }

  @protected
  void cacheInitialDillCompilation() {
    if (_dillOutputPath != null) {
      return;
    }
    globals.logger.printTrace('Caching compiled dill');
    final File outputDill = globals.fs.file(dillOutputPath);
    if (outputDill.existsSync()) {
      final String copyPath = getDefaultCachedKernelPath(
        trackWidgetCreation: trackWidgetCreation,
        dartDefines: debuggingOptions.buildInfo.dartDefines,
        extraFrontEndOptions: debuggingOptions.buildInfo.extraFrontEndOptions,
      );
      globals.fs
          .file(copyPath)
          .parent
          .createSync(recursive: true);
      outputDill.copySync(copyPath);
    }
  }

  void printStructuredErrorLog(vm_service.Event event) {
    if (event.extensionKind == 'Flutter.Error' && !machine) {
      final Map<dynamic, dynamic> json = event.extensionData?.data;
      if (json != null && json.containsKey('renderedErrorText')) {
        globals.printStatus('\n${json['renderedErrorText']}');
      }
    }
  }

  /// If the [reloadSources] parameter is not null the 'reloadSources' service
  /// will be registered.
  //
  // Failures should be indicated by completing the future with an error, using
  // a string as the error object, which will be used by the caller (attach())
  // to display an error message.
  Future<void> connectToServiceProtocol({
    ReloadSources reloadSources,
    Restart restart,
    CompileExpression compileExpression,
    ReloadMethod reloadMethod,
    GetSkSLMethod getSkSLMethod,
  }) async {
    if (!debuggingOptions.debuggingEnabled) {
      throw 'The service protocol is not enabled.';
    }
    _finished = Completer<int>();
    // Listen for service protocol connection to close.
    for (final FlutterDevice device in flutterDevices) {
      await device.connect(
        reloadSources: reloadSources,
        restart: restart,
        compileExpression: compileExpression,
        disableDds: debuggingOptions.disableDds,
        reloadMethod: reloadMethod,
        getSkSLMethod: getSkSLMethod,
        printStructuredErrorLogMethod: printStructuredErrorLog,
        ipv6: ipv6,
      );
      // This will wait for at least one flutter view before returning.
      final Status status = globals.logger.startProgress(
        'Waiting for ${device.device.name} to report its views...',
        timeout: const Duration(milliseconds: 200),
      );
      try {
        await device.vmService.getFlutterViews();
      } finally {
        status.stop();
      }
      // This hooks up callbacks for when the connection stops in the future.
      // We don't want to wait for them. We don't handle errors in those callbacks'
      // futures either because they just print to logger and is not critical.
      unawaited(device.vmService.onDone.then<void>(
        _serviceProtocolDone,
        onError: _serviceProtocolError,
      ).whenComplete(_serviceDisconnected));
    }
  }

  Future<void> launchDevTools() async {
    assert(supportsServiceProtocol);
    _devtoolsLauncher ??= DevtoolsLauncher.instance;
    return _devtoolsLauncher.launch(flutterDevices.first.vmService.httpAddress);
  }

  Future<void> shutdownDevtools() async {
    await _devtoolsLauncher?.close();
    _devtoolsLauncher = null;
  }

  Future<void> _serviceProtocolDone(dynamic object) async {
    globals.printTrace('Service protocol connection closed.');
  }

  Future<void> _serviceProtocolError(dynamic error, StackTrace stack) {
    globals.printTrace('Service protocol connection closed with an error: $error\n$stack');
    return Future<void>.error(error, stack);
  }

  void _serviceDisconnected() {
    if (_exited) {
      // User requested the application exit.
      return;
    }
    if (_finished.isCompleted) {
      return;
    }
    globals.printStatus('Lost connection to device.');
    _finished.complete(0);
  }

  void appFinished() {
    if (_finished.isCompleted) {
      return;
    }
    globals.printStatus('Application finished.');
    _finished.complete(0);
  }

  void appFailedToStart() {
    if (!_finished.isCompleted) {
      _finished.complete(1);
    }
  }

  Future<int> waitForAppToFinish() async {
    final int exitCode = await _finished.future;
    assert(exitCode != null);
    await cleanupAtFinish();
    return exitCode;
  }

  @mustCallSuper
  Future<void> preExit() async {
    // If _dillOutputPath is null, the tool created a temporary directory for
    // the dill.
    if (_dillOutputPath == null && artifactDirectory.existsSync()) {
      artifactDirectory.deleteSync(recursive: true);
    }
  }

  Future<void> exitApp() async {
    final List<Future<void>> futures = <Future<void>>[
      for (final FlutterDevice device in flutterDevices)  device.exitApps(),
    ];
    await Future.wait(futures);
    appFinished();
  }

  /// Called to print help to the terminal.
  void printHelp({ @required bool details });

  void printHelpDetails() {
    if (flutterDevices.any((FlutterDevice d) => d.device.supportsScreenshot)) {
      commandHelp.s.print();
    }
    if (supportsServiceProtocol) {
      commandHelp.b.print();
      commandHelp.w.print();
      commandHelp.t.print();
      if (isRunningDebug) {
        commandHelp.L.print();
        commandHelp.S.print();
        commandHelp.U.print();
        commandHelp.i.print();
        commandHelp.I.print();
        commandHelp.p.print();
        commandHelp.o.print();
        commandHelp.z.print();
        commandHelp.g.print();
      } else {
        commandHelp.S.print();
        commandHelp.U.print();
      }
      if (supportsCanvasKit){
        commandHelp.k.print();
      }
      if (supportsWriteSkSL) {
        commandHelp.M.print();
      }
      commandHelp.v.print();
      // `P` should precede `a`
      commandHelp.P.print();
      commandHelp.a.print();
    }
  }

  /// Called when a signal has requested we exit.
  Future<void> cleanupAfterSignal();

  /// Called right before we exit.
  Future<void> cleanupAtFinish();

  // Clears the screen.
  void clearScreen() => globals.logger.clear();
}

class OperationResult {
  OperationResult(this.code, this.message, { this.fatal = false });

  /// The result of the operation; a non-zero code indicates a failure.
  final int code;

  /// A user facing message about the results of the operation.
  final String message;

  /// Whether this error should cause the runner to exit.
  final bool fatal;

  bool get isOk => code == 0;

  static final OperationResult ok = OperationResult(0, '');
}

/// Given the value of the --target option, return the path of the Dart file
/// where the app's main function should be.
String findMainDartFile([ String target ]) {
  target ??= '';
  final String targetPath = globals.fs.path.absolute(target);
  if (globals.fs.isDirectorySync(targetPath)) {
    return globals.fs.path.join(targetPath, 'lib', 'main.dart');
  }
  return targetPath;
}

Future<String> getMissingPackageHintForPlatform(TargetPlatform platform) async {
  switch (platform) {
    case TargetPlatform.android_arm:
    case TargetPlatform.android_arm64:
    case TargetPlatform.android_x64:
    case TargetPlatform.android_x86:
      final FlutterProject project = FlutterProject.current();
      final String manifestPath = globals.fs.path.relative(project.android.appManifestFile.path);
      return 'Is your project missing an $manifestPath?\nConsider running "flutter create ." to create one.';
    case TargetPlatform.ios:
      return 'Is your project missing an ios/Runner/Info.plist?\nConsider running "flutter create ." to create one.';
    default:
      return null;
  }
}

/// Redirects terminal commands to the correct resident runner methods.
class TerminalHandler {
  TerminalHandler(this.residentRunner);

  final ResidentRunner residentRunner;
  bool _processingUserRequest = false;
  StreamSubscription<void> subscription;

  @visibleForTesting
  String lastReceivedCommand;

  void setupTerminal() {
    if (!globals.logger.quiet) {
      globals.printStatus('');
      residentRunner.printHelp(details: false);
    }
    globals.terminal.singleCharMode = true;
    subscription = globals.terminal.keystrokes.listen(processTerminalInput);
  }


  final Map<io.ProcessSignal, Object> _signalTokens = <io.ProcessSignal, Object>{};

  void _addSignalHandler(io.ProcessSignal signal, SignalHandler handler) {
    _signalTokens[signal] = globals.signals.addHandler(signal, handler);
  }

  void registerSignalHandlers() {
    assert(residentRunner.stayResident);

    _addSignalHandler(io.ProcessSignal.SIGINT, _cleanUp);
    _addSignalHandler(io.ProcessSignal.SIGTERM, _cleanUp);
    if (!residentRunner.supportsServiceProtocol || !residentRunner.supportsRestart) {
      return;
    }
    _addSignalHandler(io.ProcessSignal.SIGUSR1, _handleSignal);
    _addSignalHandler(io.ProcessSignal.SIGUSR2, _handleSignal);
  }

  /// Unregisters terminal signal and keystroke handlers.
  void stop() {
    assert(residentRunner.stayResident);
    for (final MapEntry<io.ProcessSignal, Object> entry in _signalTokens.entries) {
      globals.signals.removeHandler(entry.key, entry.value);
    }
    _signalTokens.clear();
    subscription.cancel();
  }

  /// Returns [true] if the input has been handled by this function.
  Future<bool> _commonTerminalInputHandler(String character) async {
    globals.printStatus(''); // the key the user tapped might be on this line
    switch(character) {
      case 'a':
        if (residentRunner.supportsServiceProtocol) {
          await residentRunner.debugToggleProfileWidgetBuilds();
          return true;
        }
        return false;
      case 'b':
        await residentRunner.debugToggleBrightness();
        return true;
      case 'c':
        residentRunner.clearScreen();
        return true;
      case 'd':
      case 'D':
        await residentRunner.detach();
        return true;
      case 'g':
        await residentRunner.runSourceGenerators();
        return true;
      case 'h':
      case 'H':
      case '?':
        // help
        residentRunner.printHelp(details: true);
        return true;
      case 'i':
        if (residentRunner.supportsServiceProtocol) {
          await residentRunner.debugToggleWidgetInspector();
          return true;
        }
        return false;
      case 'I':
        if (residentRunner.supportsServiceProtocol && residentRunner.isRunningDebug) {
          await residentRunner.debugToggleInvertOversizedImages();
          return true;
        }
        return false;
      case 'k':
        if (residentRunner.supportsCanvasKit) {
          final bool result = await residentRunner.toggleCanvaskit();
          globals.printStatus('${result ? 'Enabled' : 'Disabled'} CanvasKit');
          return true;
        }
        return false;
      case 'L':
        if (residentRunner.supportsServiceProtocol) {
          await residentRunner.debugDumpLayerTree();
          return true;
        }
        return false;
      case 'o':
      case 'O':
        if (residentRunner.supportsServiceProtocol && residentRunner.isRunningDebug) {
          await residentRunner.debugTogglePlatform();
          return true;
        }
        return false;
      case 'M':
        if (residentRunner.supportsWriteSkSL) {
          await residentRunner.writeSkSL();
          return true;
        }
        return false;
      case 'p':
        if (residentRunner.supportsServiceProtocol && residentRunner.isRunningDebug) {
          await residentRunner.debugToggleDebugPaintSizeEnabled();
          return true;
        }
        return false;
      case 'P':
        if (residentRunner.supportsServiceProtocol) {
          await residentRunner.debugTogglePerformanceOverlayOverride();
          return true;
        }
        return false;
      case 'q':
      case 'Q':
        // exit
        await residentRunner.exit();
        return true;
      case 'r':
        if (!residentRunner.canHotReload) {
          return false;
        }
        final OperationResult result = await residentRunner.restart(fullRestart: false);
        if (result.fatal) {
          throwToolExit(result.message);
        }
        if (!result.isOk) {
          globals.printStatus('Try again after fixing the above error(s).', emphasis: true);
        }
        return true;
      case 'R':
        // If hot restart is not supported for all devices, ignore the command.
        if (!residentRunner.canHotRestart || !residentRunner.hotMode) {
          return false;
        }
        final OperationResult result = await residentRunner.restart(fullRestart: true);
        if (result.fatal) {
          throwToolExit(result.message);
        }
        if (!result.isOk) {
          globals.printStatus('Try again after fixing the above error(s).', emphasis: true);
        }
        return true;
      case 's':
        for (final FlutterDevice device in residentRunner.flutterDevices) {
          if (device.device.supportsScreenshot) {
            await residentRunner.screenshot(device);
          }
        }
        return true;
      case 'S':
        if (residentRunner.supportsServiceProtocol) {
          await residentRunner.debugDumpSemanticsTreeInTraversalOrder();
          return true;
        }
        return false;
      case 't':
      case 'T':
        if (residentRunner.supportsServiceProtocol) {
          await residentRunner.debugDumpRenderTree();
          return true;
        }
        return false;
      case 'U':
        if (residentRunner.supportsServiceProtocol) {
          await residentRunner.debugDumpSemanticsTreeInInverseHitTestOrder();
          return true;
        }
        return false;
      case 'v':
        if (residentRunner.supportsServiceProtocol) {
          await residentRunner.launchDevTools();
          return true;
        }
        return false;
      case 'w':
      case 'W':
        if (residentRunner.supportsServiceProtocol) {
          await residentRunner.debugDumpApp();
          return true;
        }
        return false;
      case 'z':
      case 'Z':
        await residentRunner.debugToggleDebugCheckElevationsEnabled();
        return true;
    }
    return false;
  }

  Future<void> processTerminalInput(String command) async {
    // When terminal doesn't support line mode, '\n' can sneak into the input.
    command = command.trim();
    if (_processingUserRequest) {
      globals.printTrace('Ignoring terminal input: "$command" because we are busy.');
      return;
    }
    _processingUserRequest = true;
    try {
      lastReceivedCommand = command;
      await _commonTerminalInputHandler(command);
    // Catch all exception since this is doing cleanup and rethrowing.
    } catch (error, st) { // ignore: avoid_catches_without_on_clauses
      // Don't print stack traces for known error types.
      if (error is! ToolExit) {
        globals.printError('$error\n$st');
      }
      await _cleanUp(null);
      rethrow;
    } finally {
      _processingUserRequest = false;
    }
  }

  Future<void> _handleSignal(io.ProcessSignal signal) async {
    if (_processingUserRequest) {
      globals.printTrace('Ignoring signal: "$signal" because we are busy.');
      return;
    }
    _processingUserRequest = true;

    final bool fullRestart = signal == io.ProcessSignal.SIGUSR2;

    try {
      await residentRunner.restart(fullRestart: fullRestart);
    } finally {
      _processingUserRequest = false;
    }
  }

  Future<void> _cleanUp(io.ProcessSignal signal) async {
    globals.terminal.singleCharMode = false;
    await subscription?.cancel();
    await residentRunner.cleanupAfterSignal();
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

/// Returns the next platform value for the switcher.
///
/// These values must match what is available in
/// `packages/flutter/lib/src/foundation/binding.dart`.
String nextPlatform(String currentPlatform, FeatureFlags featureFlags) {
  switch (currentPlatform) {
    case 'android':
      return 'iOS';
    case 'iOS':
      return 'fuchsia';
    case 'fuchsia':
      if (featureFlags.isMacOSEnabled) {
        return 'macOS';
      }
      return 'android';
    case 'macOS':
      return 'android';
    default:
      assert(false); // Invalid current platform.
      return 'android';
  }
}

class DevtoolsLauncher {
  io.HttpServer _devtoolsServer;
  Future<void> launch(Uri observatoryAddress) async {
    try {
      await serve();
      await devtools_server.launchDevTools(
        <String, dynamic>{
          'reuseWindows': true,
        },
        observatoryAddress,
        'http://${_devtoolsServer.address.host}:${_devtoolsServer.port}',
        false,  // headless mode,
        false,  // machine mode
      );
    } on Exception catch (e, st) {
      globals.printTrace('Failed to launch DevTools: $e\n$st');
    }
  }

  Future<DevToolsServerAddress> serve() async {
    try {
      _devtoolsServer ??= await devtools_server.serveDevTools(
        enableStdinCommands: false,
      );
      return DevToolsServerAddress(_devtoolsServer.address.host, _devtoolsServer.port);
    } on Exception catch (e, st) {
      globals.printTrace('Failed to serve DevTools: $e\n$st');
      return null;
    }
  }

  Future<void> close() async {
    await _devtoolsServer?.close();
    _devtoolsServer = null;
  }

  static DevtoolsLauncher get instance => context.get<DevtoolsLauncher>() ?? DevtoolsLauncher();
}

class DevToolsServerAddress {
  DevToolsServerAddress(this.host, this.port);

  final String host;
  final int port;
}

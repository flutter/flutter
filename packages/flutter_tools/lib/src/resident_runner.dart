// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'application_package.dart';
import 'artifacts.dart';
import 'asset.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'base/io.dart' as io;
import 'base/logger.dart';
import 'base/terminal.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'codegen.dart';
import 'compile.dart';
import 'dart/package_map.dart';
import 'devfs.dart';
import 'device.dart';
import 'globals.dart';
import 'project.dart';
import 'run_cold.dart';
import 'run_hot.dart';
import 'vmservice.dart';

class FlutterDevice {
  FlutterDevice(
    this.device, {
    @required this.trackWidgetCreation,
    this.fileSystemRoots,
    this.fileSystemScheme,
    this.viewFilter,
    TargetModel targetModel = TargetModel.flutter,
    List<String> experimentalFlags,
    ResidentCompiler generator,
    @required BuildMode buildMode,
  }) : assert(trackWidgetCreation != null),
       generator = generator ?? ResidentCompiler(
         artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath, mode: buildMode),
         trackWidgetCreation: trackWidgetCreation,
         fileSystemRoots: fileSystemRoots,
         fileSystemScheme: fileSystemScheme,
         targetModel: targetModel,
         experimentalFlags: experimentalFlags,
       );

  /// Create a [FlutterDevice] with optional code generation enabled.
  static Future<FlutterDevice> create(
    Device device, {
    @required FlutterProject flutterProject,
    @required bool trackWidgetCreation,
    @required String target,
    @required BuildMode buildMode,
    List<String> fileSystemRoots,
    String fileSystemScheme,
    String viewFilter,
    TargetModel targetModel = TargetModel.flutter,
    List<String> experimentalFlags,
    ResidentCompiler generator,
  }) async {
    ResidentCompiler generator;
    if (flutterProject.hasBuilders) {
      generator = await CodeGeneratingResidentCompiler.create(
        flutterProject: flutterProject,
      );
    } else {
      generator = ResidentCompiler(
        artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath, mode: buildMode),
        trackWidgetCreation: trackWidgetCreation,
        fileSystemRoots: fileSystemRoots,
        fileSystemScheme: fileSystemScheme,
        targetModel: targetModel,
        experimentalFlags: experimentalFlags,
      );
    }
    return FlutterDevice(
      device,
      trackWidgetCreation: trackWidgetCreation,
      fileSystemRoots: fileSystemRoots,
      fileSystemScheme:fileSystemScheme,
      viewFilter: viewFilter,
      experimentalFlags: experimentalFlags,
      targetModel: targetModel,
      generator: generator,
      buildMode: buildMode,
    );
  }

  final Device device;
  final ResidentCompiler generator;
  List<Uri> observatoryUris;
  List<VMService> vmServices;
  DevFS devFS;
  ApplicationPackage package;
  List<String> fileSystemRoots;
  String fileSystemScheme;
  StreamSubscription<String> _loggingSubscription;
  final String viewFilter;
  final bool trackWidgetCreation;

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
  }) async {
    if (vmServices != null)
      return;
    final List<VMService> localVmServices = List<VMService>(observatoryUris.length);
    for (int i = 0; i < observatoryUris.length; i += 1) {
      printTrace('Connecting to service protocol: ${observatoryUris[i]}');
      localVmServices[i] = await VMService.connect(
        observatoryUris[i],
        reloadSources: reloadSources,
        restart: restart,
        compileExpression: compileExpression,
      );
      printTrace('Successfully connected to service protocol: ${observatoryUris[i]}');
    }
    vmServices = localVmServices;
  }

  Future<void> refreshViews() async {
    if (vmServices == null || vmServices.isEmpty)
      return Future<void>.value(null);
    final List<Future<void>> futures = <Future<void>>[];
    for (VMService service in vmServices)
      futures.add(service.vm.refreshViews(waitForViews: true));
    await Future.wait(futures);
  }

  List<FlutterView> get views {
    if (vmServices == null)
      return <FlutterView>[];

    return vmServices
      .where((VMService service) => !service.isClosed)
      .expand<FlutterView>(
        (VMService service) {
          return viewFilter != null
               ? service.vm.allViewsWithName(viewFilter)
               : service.vm.views;
        },
      )
      .toList();
  }

  Future<void> getVMs() async {
    for (VMService service in vmServices)
      await service.getVM();
  }

  Future<void> exitApps() async {
    if (!device.supportsFlutterExit) {
      await device.stopApp(package);
      return;
    }
    final List<FlutterView> flutterViews = views;
    if (flutterViews == null || flutterViews.isEmpty)
      return;
    final List<Future<void>> futures = <Future<void>>[];
    // If any of the flutter views are paused, we might not be able to
    // cleanly exit since the service extension may not have been registered.
    if (flutterViews.any((FlutterView view) {
      return view != null &&
             view.uiIsolate != null &&
             view.uiIsolate.pauseEvent.isPauseEvent;
      }
    )) {
      await device.stopApp(package);
      return;
    }
    for (FlutterView view in flutterViews) {
      if (view != null && view.uiIsolate != null) {
        assert(!view.uiIsolate.pauseEvent.isPauseEvent);
        futures.add(view.uiIsolate.flutterExit());
      }
    }
    // The flutterExit message only returns if it fails, so just wait a few
    // seconds then assume it worked.
    // TODO(ianh): We should make this return once the VM service disconnects.
    await Future.wait(futures).timeout(const Duration(seconds: 2), onTimeout: () => <void>[]);
  }

  Future<Uri> setupDevFS(
    String fsName,
    Directory rootDirectory, {
    String packagesFilePath,
  }) {
    // One devFS per device. Shared by all running instances.
    devFS = DevFS(
      vmServices[0],
      fsName,
      rootDirectory,
      packagesFilePath: packagesFilePath,
    );
    return devFS.create();
  }

  List<Future<Map<String, dynamic>>> reloadSources(
    String entryPath, {
    bool pause = false,
  }) {
    final Uri deviceEntryUri = devFS.baseUri.resolveUri(fs.path.toUri(entryPath));
    final Uri devicePackagesUri = devFS.baseUri.resolve('.packages');
    final List<Future<Map<String, dynamic>>> reports = <Future<Map<String, dynamic>>>[];
    for (FlutterView view in views) {
      final Future<Map<String, dynamic>> report = view.uiIsolate.reloadSources(
        pause: pause,
        rootLibUri: deviceEntryUri,
        packagesUri: devicePackagesUri,
      );
      reports.add(report);
    }
    return reports;
  }

  Future<void> resetAssetDirectory() async {
    final Uri deviceAssetsDirectoryUri = devFS.baseUri.resolveUri(
        fs.path.toUri(getAssetBuildDirectory()));
    assert(deviceAssetsDirectoryUri != null);
    await Future.wait<void>(views.map<Future<void>>(
      (FlutterView view) => view.setAssetDirectory(deviceAssetsDirectoryUri)
    ));
  }

  // Lists program elements changed in the most recent reload that have not
  // since executed.
  Future<List<ProgramElement>> unusedChangesInLastReload() async {
    final List<Future<List<ProgramElement>>> reports =
      <Future<List<ProgramElement>>>[];
    for (FlutterView view in views)
      reports.add(view.uiIsolate.getUnusedChangesInLastReload());
    final List<ProgramElement> elements = <ProgramElement>[];
    for (Future<List<ProgramElement>> report in reports) {
      for (ProgramElement element in await report)
        elements.add(ProgramElement(element.qualifiedName,
                                        devFS.deviceUriToHostUri(element.uri),
                                        element.line,
                                        element.column));
    }
    return elements;
  }

  Future<void> debugDumpApp() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterDebugDumpApp();
  }

  Future<void> debugDumpRenderTree() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterDebugDumpRenderTree();
  }

  Future<void> debugDumpLayerTree() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterDebugDumpLayerTree();
  }

  Future<void> debugDumpSemanticsTreeInTraversalOrder() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterDebugDumpSemanticsTreeInTraversalOrder();
  }

  Future<void> debugDumpSemanticsTreeInInverseHitTestOrder() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterDebugDumpSemanticsTreeInInverseHitTestOrder();
  }

  Future<void> toggleDebugPaintSizeEnabled() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterToggleDebugPaintSizeEnabled();
  }

  Future<void> toggleDebugCheckElevationsEnabled() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterToggleDebugCheckElevationsEnabled();
  }

  Future<void> debugTogglePerformanceOverlayOverride() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterTogglePerformanceOverlayOverride();
  }

  Future<void> toggleWidgetInspector() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterToggleWidgetInspector();
  }

  Future<void> toggleProfileWidgetBuilds() async {
    for (FlutterView view in views) {
      await view.uiIsolate.flutterToggleProfileWidgetBuilds();
    }
  }

  Future<String> togglePlatform({ String from }) async {
    String to;
    switch (from) {
      case 'iOS':
        to = 'android';
        break;
      case 'android':
      default:
        to = 'iOS';
        break;
    }
    for (FlutterView view in views)
      await view.uiIsolate.flutterPlatformOverride(to);
    return to;
  }

  void startEchoingDeviceLog() {
    if (_loggingSubscription != null) {
      return;
    }
    final Stream<String> logStream = device.getLogReader(app: package).logLines;
    if (logStream == null) {
      printError('Failed to read device log stream');
      return;
    }
    _loggingSubscription = logStream.listen((String line) {
      if (!line.contains('Observatory listening on http'))
        printStatus(line, wrap: false);
    });
  }

  Future<void> stopEchoingDeviceLog() async {
    if (_loggingSubscription == null)
      return;
    await _loggingSubscription.cancel();
    _loggingSubscription = null;
  }

  void initLogReader() {
    device.getLogReader(app: package).appPid = vmServices.first.vm.pid;
  }

  Future<int> runHot({
    HotRunner hotRunner,
    String route,
  }) async {
    final bool prebuiltMode = hotRunner.applicationBinary != null;
    final String modeName = hotRunner.debuggingOptions.buildInfo.friendlyModeName;
    printStatus('Launching ${getDisplayPath(hotRunner.mainPath)} on ${device.name} in $modeName mode...');

    final TargetPlatform targetPlatform = await device.targetPlatform;
    package = await ApplicationPackageFactory.instance.getPackageForPlatform(
      targetPlatform,
      applicationBinary: hotRunner.applicationBinary,
    );

    if (package == null) {
      String message = 'No application found for $targetPlatform.';
      final String hint = await getMissingPackageHintForPlatform(targetPlatform);
      if (hint != null)
        message += '\n$hint';
      printError(message);
      return 1;
    }

    final Map<String, dynamic> platformArgs = <String, dynamic>{};

    startEchoingDeviceLog();

    // Start the application.
    final Future<LaunchResult> futureResult = device.startApp(
      package,
      mainPath: hotRunner.mainPath,
      debuggingOptions: hotRunner.debuggingOptions,
      platformArgs: platformArgs,
      route: route,
      prebuiltApplication: prebuiltMode,
      ipv6: hotRunner.ipv6,
    );

    final LaunchResult result = await futureResult;

    if (!result.started) {
      printError('Error launching application on ${device.name}.');
      await stopEchoingDeviceLog();
      return 2;
    }
    if (result.hasObservatory) {
      observatoryUris = <Uri>[result.observatoryUri];
    } else {
      observatoryUris = <Uri>[];
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
      applicationBinary: coldRunner.applicationBinary,
    );

    final String modeName = coldRunner.debuggingOptions.buildInfo.friendlyModeName;
    final bool prebuiltMode = coldRunner.applicationBinary != null;
    if (coldRunner.mainPath == null) {
      assert(prebuiltMode);
      printStatus('Launching ${package.displayName} on ${device.name} in $modeName mode...');
    } else {
      printStatus('Launching ${getDisplayPath(coldRunner.mainPath)} on ${device.name} in $modeName mode...');
    }

    if (package == null) {
      String message = 'No application found for $targetPlatform.';
      final String hint = await getMissingPackageHintForPlatform(targetPlatform);
      if (hint != null)
        message += '\n$hint';
      printError(message);
      return 1;
    }

    final Map<String, dynamic> platformArgs = <String, dynamic>{};
    if (coldRunner.traceStartup != null)
      platformArgs['trace-startup'] = coldRunner.traceStartup;

    startEchoingDeviceLog();

    final LaunchResult result = await device.startApp(
      package,
      mainPath: coldRunner.mainPath,
      debuggingOptions: coldRunner.debuggingOptions,
      platformArgs: platformArgs,
      route: route,
      prebuiltApplication: prebuiltMode,
      ipv6: coldRunner.ipv6,
    );

    if (!result.started) {
      printError('Error running application on ${device.name}.');
      await stopEchoingDeviceLog();
      return 2;
    }
    if (result.hasObservatory) {
      observatoryUris = <Uri>[result.observatoryUri];
    } else {
      observatoryUris = <Uri>[];
    }
    return 0;
  }

  Future<UpdateFSReport> updateDevFS({
    String mainPath,
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
  }) async {
    final Status devFSStatus = logger.startProgress(
      'Syncing files to device ${device.name}...',
      timeout: timeoutConfiguration.fastOperation,
    );
    UpdateFSReport report;
    try {
      report = await devFS.update(
        mainPath: mainPath,
        target: target,
        bundle: bundle,
        firstBuildTime: firstBuildTime,
        bundleFirstUpload: bundleFirstUpload,
        generator: generator,
        fullRestart: fullRestart,
        dillOutputPath: dillOutputPath,
        trackWidgetCreation: trackWidgetCreation,
        projectRootPath: projectRootPath,
        pathToReload: pathToReload,
        invalidatedFiles: invalidatedFiles,
      );
    } on DevFSException {
      devFSStatus.cancel();
      return UpdateFSReport(success: false);
    }
    devFSStatus.stop();
    printTrace('Synced ${getSizeAsMB(report.syncedBytes)}.');
    return report;
  }

  Future<void> updateReloadStatus(bool wasReloadSuccessful) async {
    if (wasReloadSuccessful)
      generator?.accept();
    else
      await generator?.reject();
  }
}

// Issue: https://github.com/flutter/flutter/issues/33050
// Matches the following patterns:
//    HttpException: Connection closed before full header was received, uri = *
//    HttpException: , uri = *
final RegExp kAndroidQHttpConnectionClosedExp = RegExp(r'^HttpException\:.+\, uri \=.+$');

/// Returns `true` if any of the devices is running Android Q.
Future<bool> hasDeviceRunningAndroidQ(List<FlutterDevice> flutterDevices) async {
  for (FlutterDevice flutterDevice in flutterDevices) {
    final String sdkNameAndVersion = await flutterDevice.device.sdkNameAndVersion;
    if (sdkNameAndVersion != null && sdkNameAndVersion.startsWith('Android 10')) {
      return true;
    }
  }
  return false;
}

// Shared code between different resident application runners.
abstract class ResidentRunner {
  ResidentRunner(
    this.flutterDevices, {
    this.target,
    this.debuggingOptions,
    String projectRootPath,
    String packagesFilePath,
    this.ipv6,
    this.stayResident = true,
    this.hotMode = true,
    String dillOutputPath,
  }) : mainPath = findMainDartFile(target),
       projectRootPath = projectRootPath ?? fs.currentDirectory.path,
       packagesFilePath = packagesFilePath ?? fs.path.absolute(PackageMap.globalPackagesPath),
       _dillOutputPath = dillOutputPath,
       artifactDirectory = dillOutputPath == null
          ? fs.systemTempDirectory.createTempSync('_fluttter_tool')
          : fs.file(dillOutputPath).parent,
       assetBundle = AssetBundleFactory.instance.createBundle() {
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
  @visibleForTesting
  final Directory artifactDirectory;
  final Completer<int> _finished = Completer<int>();
  final String packagesFilePath;
  final String projectRootPath;
  final String mainPath;
  final AssetBundle assetBundle;

  bool _exited = false;
  bool hotMode ;

  String get dillOutputPath => _dillOutputPath ?? fs.path.join(artifactDirectory.path, 'app.dill');
  String getReloadPath({ bool fullRestart }) => mainPath + (fullRestart ? '' : '.incremental') + '.dill';

  bool get debuggingEnabled => debuggingOptions.debuggingEnabled;
  bool get isRunningDebug => debuggingOptions.buildInfo.isDebug;
  bool get isRunningProfile => debuggingOptions.buildInfo.isProfile;
  bool get isRunningRelease => debuggingOptions.buildInfo.isRelease;
  bool get supportsServiceProtocol => isRunningDebug || isRunningProfile;

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
  }) {
    return flutterDevices.first.views.first.uiIsolate
        .invokeFlutterExtensionRpcRaw(method, params: params);
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

  Future<OperationResult> restart({ bool fullRestart = false, bool pauseAfterRestart = false, String reason }) {
    final String mode = isRunningProfile ? 'profile' :
        isRunningRelease ? 'release' : 'this';
    throw '${fullRestart ? 'Restart' : 'Reload'} is not supported in $mode mode';
  }

  Future<void> exit() async {
    _exited = true;
    await stopEchoingDeviceLog();
    await preExit();
    await exitApp();
  }

  Future<void> detach() async {
    await stopEchoingDeviceLog();
    await preExit();
    appFinished();
  }

  Future<void> refreshViews() async {
    final List<Future<void>> futures = <Future<void>>[];
    for (FlutterDevice device in flutterDevices)
      futures.add(device.refreshViews());
    await Future.wait(futures);
  }

  Future<void> debugDumpApp() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.debugDumpApp();
  }

  Future<void> debugDumpRenderTree() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.debugDumpRenderTree();
  }

  Future<void> debugDumpLayerTree() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.debugDumpLayerTree();
  }

  Future<void> debugDumpSemanticsTreeInTraversalOrder() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.debugDumpSemanticsTreeInTraversalOrder();
  }

  Future<void> debugDumpSemanticsTreeInInverseHitTestOrder() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.debugDumpSemanticsTreeInInverseHitTestOrder();
  }

  Future<void> debugToggleDebugPaintSizeEnabled() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.toggleDebugPaintSizeEnabled();
  }

  Future<void> debugToggleDebugCheckElevationsEnabled() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.toggleDebugCheckElevationsEnabled();
  }

  Future<void> debugTogglePerformanceOverlayOverride() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.debugTogglePerformanceOverlayOverride();
  }

  Future<void> debugToggleWidgetInspector() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.toggleWidgetInspector();
  }

  Future<void> debugToggleProfileWidgetBuilds() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices) {
      await device.toggleProfileWidgetBuilds();
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

    final Status status = logger.startProgress('Taking screenshot for ${device.device.name}...', timeout: timeoutConfiguration.fastOperation);
    final File outputFile = getUniqueFile(fs.currentDirectory, 'flutter', 'png');
    try {
      if (supportsServiceProtocol && isRunningDebug) {
        await device.refreshViews();
        try {
          for (FlutterView view in device.views)
            await view.uiIsolate.flutterDebugAllowBanner(false);
        } catch (error) {
          status.cancel();
          printError('Error communicating with Flutter on the device: $error');
          return;
        }
      }
      try {
        await device.device.takeScreenshot(outputFile);
      } finally {
        if (supportsServiceProtocol && isRunningDebug) {
          try {
            for (FlutterView view in device.views)
              await view.uiIsolate.flutterDebugAllowBanner(true);
          } catch (error) {
            status.cancel();
            printError('Error communicating with Flutter on the device: $error');
            return;
          }
        }
      }
      final int sizeKB = outputFile.lengthSync() ~/ 1024;
      status.stop();
      printStatus('Screenshot written to ${fs.path.relative(outputFile.path)} (${sizeKB}kB).');
    } catch (error) {
      status.cancel();
      printError('Error taking screenshot: $error');
    }
  }

  Future<void> debugTogglePlatform() async {
    await refreshViews();
    final String from = await flutterDevices[0].views[0].uiIsolate.flutterPlatformOverride();
    String to;
    for (FlutterDevice device in flutterDevices)
      to = await device.togglePlatform(from: from);
    printStatus('Switched operating system to $to');
  }

  Future<void> stopEchoingDeviceLog() async {
    await Future.wait<void>(
      flutterDevices.map<Future<void>>((FlutterDevice device) => device.stopEchoingDeviceLog())
    );
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
  }) async {
    if (!debuggingOptions.debuggingEnabled)
      throw 'The service protocol is not enabled.';

    bool viewFound = false;
    for (FlutterDevice device in flutterDevices) {
      await device.connect(
        reloadSources: reloadSources,
        restart: restart,
        compileExpression: compileExpression,
      );
      await device.getVMs();
      await device.refreshViews();
      if (device.views.isNotEmpty)
        viewFound = true;
    }
    if (!viewFound) {
      if (flutterDevices.length == 1)
        throw 'No Flutter view is available on ${flutterDevices.first.device.name}.';
      throw 'No Flutter view is available on any device '
            '(${flutterDevices.map<String>((FlutterDevice device) => device.device.name).join(', ')}).';
    }

    // Listen for service protocol connection to close.
    for (FlutterDevice device in flutterDevices) {
      for (VMService service in device.vmServices) {
        // This hooks up callbacks for when the connection stops in the future.
        // We don't want to wait for them. We don't handle errors in those callbacks'
        // futures either because they just print to logger and is not critical.
        unawaited(service.done.then<void>(
          _serviceProtocolDone,
          onError: _serviceProtocolError,
        ).whenComplete(_serviceDisconnected));
      }
    }
  }

  Future<void> _serviceProtocolDone(dynamic object) {
    printTrace('Service protocol connection closed.');
    return Future<void>.value(object);
  }

  Future<void> _serviceProtocolError(dynamic error, StackTrace stack) {
    printTrace('Service protocol connection closed with an error: $error\n$stack');
    return Future<void>.error(error, stack);
  }

  void _serviceDisconnected() {
    if (_exited) {
      // User requested the application exit.
      return;
    }
    if (_finished.isCompleted)
      return;
    printStatus('Lost connection to device.');
    _finished.complete(0);
  }

  void appFinished() {
    if (_finished.isCompleted)
      return;
    printStatus('Application finished.');
    _finished.complete(0);
  }

  Future<int> waitForAppToFinish() async {
    final int exitCode = await _finished.future;
    assert(exitCode != null);
    await cleanupAtFinish();
    return exitCode;
  }

  @mustCallSuper
  Future<void> preExit() async {
    // If _dillOutputPath is null, we created a temporary directory for the dill.
    if (_dillOutputPath == null && artifactDirectory.existsSync()) {
      artifactDirectory.deleteSync(recursive: true);
    }
  }

  Future<void> exitApp() async {
    final List<Future<void>> futures = <Future<void>>[];
    for (FlutterDevice device in flutterDevices)
      futures.add(device.exitApps());
    await Future.wait(futures);
    appFinished();
  }

  /// Called to print help to the terminal.
  void printHelp({ @required bool details });

  void printHelpDetails() {
    if (supportsServiceProtocol) {
      printStatus('You can dump the widget hierarchy of the app (debugDumpApp) by pressing "w".');
      printStatus('To dump the rendering tree of the app (debugDumpRenderTree), press "t".');
      if (isRunningDebug) {
        printStatus('For layers (debugDumpLayerTree), use "L"; for accessibility (debugDumpSemantics), use "S" (for traversal order) or "U" (for inverse hit test order).');
        printStatus('To toggle the widget inspector (WidgetsApp.showWidgetInspectorOverride), press "i".');
        printStatus('To toggle the display of construction lines (debugPaintSizeEnabled), press "p".');
        printStatus('To simulate different operating systems, (defaultTargetPlatform), press "o".');
        printStatus('To toggle the elevation checker, press "z".');
      } else {
        printStatus('To dump the accessibility tree (debugDumpSemantics), press "S" (for traversal order) or "U" (for inverse hit test order).');
      }
      printStatus('To display the performance overlay (WidgetsApp.showPerformanceOverlay), press "P".');
      printStatus('To enable timeline events for all widget build methods, (debugProfileWidgetBuilds), press "a"');
    }
    if (flutterDevices.any((FlutterDevice d) => d.device.supportsScreenshot)) {
      printStatus('To save a screenshot to flutter.png, press "s".');
    }
  }

  /// Called when a signal has requested we exit.
  Future<void> cleanupAfterSignal();

  /// Called right before we exit.
  Future<void> cleanupAtFinish();
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
  final String targetPath = fs.path.absolute(target);
  if (fs.isDirectorySync(targetPath))
    return fs.path.join(targetPath, 'lib', 'main.dart');
  else
    return targetPath;
}

Future<String> getMissingPackageHintForPlatform(TargetPlatform platform) async {
  switch (platform) {
    case TargetPlatform.android_arm:
    case TargetPlatform.android_arm64:
    case TargetPlatform.android_x64:
    case TargetPlatform.android_x86:
      final FlutterProject project = FlutterProject.current();
      final String manifestPath = fs.path.relative(project.android.appManifestFile.path);
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
    if (!logger.quiet) {
      printStatus('');
      residentRunner.printHelp(details: false);
    }
    terminal.singleCharMode = true;
    subscription = terminal.keystrokes.listen(processTerminalInput);
  }

  void registerSignalHandlers() {
    assert(residentRunner.stayResident);
    io.ProcessSignal.SIGINT.watch().listen((io.ProcessSignal signal) {
      _cleanUp(signal);
      io.exit(0);
    });
    io.ProcessSignal.SIGTERM.watch().listen((io.ProcessSignal signal) {
      _cleanUp(signal);
      io.exit(0);
    });
    if (!residentRunner.supportsServiceProtocol || !residentRunner.supportsRestart)
      return;
    io.ProcessSignal.SIGUSR1.watch().listen(_handleSignal);
    io.ProcessSignal.SIGUSR2.watch().listen(_handleSignal);
  }

  /// Returns [true] if the input has been handled by this function.
  Future<bool> _commonTerminalInputHandler(String character) async {
    printStatus(''); // the key the user tapped might be on this line
    switch(character) {
      case 'a':
        if (residentRunner.supportsServiceProtocol) {
          await residentRunner.debugToggleProfileWidgetBuilds();
          return true;
        }
        return false;
      case 'd':
      case 'D':
        await residentRunner.detach();
        return true;
      case 'h':
      case 'H':
      case '?':
        // help
        residentRunner.printHelp(details: true);
        return true;
      case 'i':
      case 'I':
        if (residentRunner.supportsServiceProtocol) {
          await residentRunner.debugToggleWidgetInspector();
          return true;
        }
        return false;
      case 'l':
        final List<FlutterView> views = residentRunner.flutterDevices
            .expand((FlutterDevice d) => d.views).toList();
        printStatus('Connected ${pluralize('view', views.length)}:');
        for (FlutterView v in views) {
          printStatus('${v.uiIsolate.name} (${v.uiIsolate.id})', indent: 2);
        }
        return true;
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
      case 's':
        for (FlutterDevice device in residentRunner.flutterDevices) {
          if (device.device.supportsScreenshot)
            await residentRunner.screenshot(device);
        }
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
          printStatus('Try again after fixing the above error(s).', emphasis: true);
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
          printStatus('Try again after fixing the above error(s).', emphasis: true);
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
      printTrace('Ignoring terminal input: "$command" because we are busy.');
      return;
    }
    _processingUserRequest = true;
    try {
      lastReceivedCommand = command;
      await _commonTerminalInputHandler(command);
    } catch (error, st) {
      // Don't print stack traces for known error types.
      if (error is! ToolExit) {
        printError('$error\n$st');
      }
      await _cleanUp(null);
      rethrow;
    } finally {
      _processingUserRequest = false;
    }
  }

  Future<void> _handleSignal(io.ProcessSignal signal) async {
    if (_processingUserRequest) {
      printTrace('Ignoring signal: "$signal" because we are busy.');
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
    terminal.singleCharMode = false;
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

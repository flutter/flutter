// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'android/gradle.dart';
import 'application_package.dart';
import 'artifacts.dart';
import 'asset.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'base/io.dart';
import 'base/logger.dart';
import 'base/terminal.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'compile.dart';
import 'dart/dependencies.dart';
import 'dart/package_map.dart';
import 'dependency_checker.dart';
import 'devfs.dart';
import 'device.dart';
import 'globals.dart';
import 'run_cold.dart';
import 'run_hot.dart';
import 'vmservice.dart';

class FlutterDevice {
  final Device device;
  List<Uri> observatoryUris;
  List<VMService> vmServices;
  DevFS devFS;
  ApplicationPackage package;
  ResidentCompiler generator;
  String dillOutputPath;

  StreamSubscription<String> _loggingSubscription;

  FlutterDevice(this.device, {
    @required bool previewDart2,
    @required bool trackWidgetCreation,
    this.dillOutputPath,
  }) {
    if (previewDart2) {
      generator = new ResidentCompiler(
        artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath),
        trackWidgetCreation: trackWidgetCreation,
      );
    }
  }

  String viewFilter;

  /// If the [reloadSources] parameter is not null the 'reloadSources' service
  /// will be registered.
  /// The 'reloadSources' service can be used by other Service Protocol clients
  /// connected to the VM (e.g. Observatory) to request a reload of the source
  /// code of the running application (a.k.a. HotReload).
  /// This ensures that the reload process follows the normal orchestration of
  /// the Flutter Tools and not just the VM internal service.
  Future<Null> _connect({ReloadSources reloadSources}) async {
    if (vmServices != null)
      return;
    vmServices = new List<VMService>(observatoryUris.length);
    for (int i = 0; i < observatoryUris.length; i++) {
      printTrace('Connecting to service protocol: ${observatoryUris[i]}');
      vmServices[i] = await VMService.connect(observatoryUris[i],
          reloadSources: reloadSources);
      printTrace('Successfully connected to service protocol: ${observatoryUris[i]}');
    }
  }

  Future<Null> refreshViews() async {
    if (vmServices == null || vmServices.isEmpty)
      return;
    for (VMService service in vmServices)
      await service.vm.refreshViews();
  }

  List<FlutterView> get views {
    if (vmServices == null)
      return <FlutterView>[];

    return vmServices
      .where((VMService service) => !service.isClosed)
      .expand((VMService service) => viewFilter != null
          ? service.vm.allViewsWithName(viewFilter)
          : service.vm.views)
      .toList();
  }

  Future<Null> getVMs() async {
    for (VMService service in vmServices)
      await service.getVM();
  }

  Future<Null> waitForViews() async {
    // Refresh the view list, and wait a bit for the list to populate.
    for (VMService service in vmServices)
      await service.waitForViews();
  }

  Future<Null> stopApps() async {
    final List<FlutterView> flutterViews = views;
    if (flutterViews == null || flutterViews.isEmpty)
      return;
    for (FlutterView view in flutterViews) {
      if (view != null && view.uiIsolate != null) {
        // Manage waits specifically below.
        view.uiIsolate.flutterExit(); // ignore: unawaited_futures
      }
    }
    await new Future<Null>.delayed(const Duration(milliseconds: 100));
  }

  Future<Uri> setupDevFS(String fsName,
    Directory rootDirectory, {
    String packagesFilePath
  }) {
    // One devFS per device. Shared by all running instances.
    devFS = new DevFS(
      vmServices[0],
      fsName,
      rootDirectory,
      packagesFilePath: packagesFilePath
    );
    return devFS.create();
  }

  List<Future<Map<String, dynamic>>> reloadSources(
    String entryPath, {
    bool pause: false
  }) {
    final Uri deviceEntryUri = devFS.baseUri.resolveUri(fs.path.toUri(entryPath));
    final Uri devicePackagesUri = devFS.baseUri.resolve('.packages');
    final List<Future<Map<String, dynamic>>> reports = <Future<Map<String, dynamic>>>[];
    for (FlutterView view in views) {
      final Future<Map<String, dynamic>> report = view.uiIsolate.reloadSources(
        pause: pause,
        rootLibUri: deviceEntryUri,
        packagesUri: devicePackagesUri
      );
      reports.add(report);
    }
    return reports;
  }

  Future<Null> resetAssetDirectory() async {
    final Uri deviceAssetsDirectoryUri = devFS.baseUri.resolveUri(
        fs.path.toUri(getAssetBuildDirectory()));
    assert(deviceAssetsDirectoryUri != null);
    await Future.wait(views.map(
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
        elements.add(new ProgramElement(element.qualifiedName,
                                        devFS.deviceUriToHostUri(element.uri),
                                        element.line,
                                        element.column));
    }
    return elements;
  }

  Future<Null> debugDumpApp() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterDebugDumpApp();
  }

  Future<Null> debugDumpRenderTree() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterDebugDumpRenderTree();
  }

  Future<Null> debugDumpLayerTree() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterDebugDumpLayerTree();
  }

  Future<Null> debugDumpSemanticsTreeInGeometricOrder() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterDebugDumpSemanticsTreeInGeometricOrder();
  }

  Future<Null> debugDumpSemanticsTreeInInverseHitTestOrder() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterDebugDumpSemanticsTreeInInverseHitTestOrder();
  }

  Future<Null> toggleDebugPaintSizeEnabled() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterToggleDebugPaintSizeEnabled();
  }

  Future<Null> debugTogglePerformanceOverlayOverride() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterTogglePerformanceOverlayOverride();
  }

  Future<Null> toggleWidgetInspector() async {
    for (FlutterView view in views)
      await view.uiIsolate.flutterToggleWidgetInspector();
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
    if (_loggingSubscription != null)
      return;
    _loggingSubscription = device.getLogReader(app: package).logLines.listen((String line) {
      if (!line.contains('Observatory listening on http'))
        printStatus(line);
    });
  }

  Future<Null> stopEchoingDeviceLog() async {
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
    bool shouldBuild,
  }) async {
    final bool prebuiltMode = hotRunner.applicationBinary != null;
    final String modeName = hotRunner.debuggingOptions.buildInfo.modeName;
    printStatus('Launching ${getDisplayPath(hotRunner.mainPath)} on ${device.name} in $modeName mode...');

    final TargetPlatform targetPlatform = await device.targetPlatform;
    package = await getApplicationPackageForPlatform(
      targetPlatform,
      applicationBinary: hotRunner.applicationBinary
    );

    if (package == null) {
      String message = 'No application found for $targetPlatform.';
      final String hint = getMissingPackageHintForPlatform(targetPlatform);
      if (hint != null)
        message += '\n$hint';
      printError(message);
      return 1;
    }

    final Map<String, dynamic> platformArgs = <String, dynamic>{};

    startEchoingDeviceLog();

    // Start the application.
    final bool hasDirtyDependencies = hotRunner.hasDirtyDependencies(this);
    final Future<LaunchResult> futureResult = device.startApp(
      package,
      mainPath: hotRunner.mainPath,
      debuggingOptions: hotRunner.debuggingOptions,
      platformArgs: platformArgs,
      route: route,
      prebuiltApplication: prebuiltMode,
      applicationNeedsRebuild: shouldBuild || hasDirtyDependencies,
      usesTerminalUi: hotRunner.usesTerminalUI,
      ipv6: hotRunner.ipv6,
    );

    final LaunchResult result = await futureResult;

    if (!result.started) {
      printError('Error launching application on ${device.name}.');
      await stopEchoingDeviceLog();
      return 2;
    }
    observatoryUris = <Uri>[result.observatoryUri];
    return 0;
  }


  Future<int> runCold({
    ColdRunner coldRunner,
    String route,
    bool shouldBuild: true,
  }) async {
    final TargetPlatform targetPlatform = await device.targetPlatform;
    package = await getApplicationPackageForPlatform(
      targetPlatform,
      applicationBinary: coldRunner.applicationBinary
    );

    final String modeName = coldRunner.debuggingOptions.buildInfo.modeName;
    final bool prebuiltMode = coldRunner.applicationBinary != null;
    if (coldRunner.mainPath == null) {
      assert(prebuiltMode);
      printStatus('Launching ${package.displayName} on ${device.name} in $modeName mode...');
    } else {
      printStatus('Launching ${getDisplayPath(coldRunner.mainPath)} on ${device.name} in $modeName mode...');
    }

    if (package == null) {
      String message = 'No application found for $targetPlatform.';
      final String hint = getMissingPackageHintForPlatform(targetPlatform);
      if (hint != null)
        message += '\n$hint';
      printError(message);
      return 1;
    }

    final Map<String, dynamic> platformArgs = <String, dynamic>{};
    if (coldRunner.traceStartup != null)
      platformArgs['trace-startup'] = coldRunner.traceStartup;

    startEchoingDeviceLog();

    final bool hasDirtyDependencies = coldRunner.hasDirtyDependencies(this);
    final LaunchResult result = await device.startApp(
      package,
      mainPath: coldRunner.mainPath,
      debuggingOptions: coldRunner.debuggingOptions,
      platformArgs: platformArgs,
      route: route,
      prebuiltApplication: prebuiltMode,
      applicationNeedsRebuild: shouldBuild || hasDirtyDependencies,
      usesTerminalUi: coldRunner.usesTerminalUI,
      ipv6: coldRunner.ipv6,
    );

    if (!result.started) {
      printError('Error running application on ${device.name}.');
      await stopEchoingDeviceLog();
      return 2;
    }
    if (result.hasObservatory)
      observatoryUris = <Uri>[result.observatoryUri];
    return 0;
  }

  Future<bool> updateDevFS({
    String mainPath,
    String target,
    AssetBundle bundle,
    DateTime firstBuildTime,
    bool bundleFirstUpload: false,
    bool bundleDirty: false,
    Set<String> fileFilter,
    bool fullRestart: false
  }) async {
    final Status devFSStatus = logger.startProgress(
      'Syncing files to device ${device.name}...',
      expectSlowOperation: true
    );
    int bytes = 0;
    try {
      bytes = await devFS.update(
        mainPath: mainPath,
        target: target,
        bundle: bundle,
        firstBuildTime: firstBuildTime,
        bundleFirstUpload: bundleFirstUpload,
        bundleDirty: bundleDirty,
        fileFilter: fileFilter,
        generator: generator,
        fullRestart: fullRestart,
        dillOutputPath: dillOutputPath,
      );
    } on DevFSException {
      devFSStatus.cancel();
      return false;
    }
    devFSStatus.stop();
    printTrace('Synced ${getSizeAsMB(bytes)}.');
    return true;
  }

  void updateReloadStatus(bool wasReloadSuccessful) {
    if (wasReloadSuccessful)
      generator?.accept();
    else
      generator?.reject();
  }
}

// Shared code between different resident application runners.
abstract class ResidentRunner {
  ResidentRunner(this.flutterDevices, {
    this.target,
    this.debuggingOptions,
    this.usesTerminalUI: true,
    String projectRootPath,
    String packagesFilePath,
    this.stayResident,
    this.ipv6,
  }) {
    _mainPath = findMainDartFile(target);
    _projectRootPath = projectRootPath ?? fs.currentDirectory.path;
    _packagesFilePath =
        packagesFilePath ?? fs.path.absolute(PackageMap.globalPackagesPath);
    _assetBundle = AssetBundleFactory.instance.createBundle();
  }

  final List<FlutterDevice> flutterDevices;
  final String target;
  final DebuggingOptions debuggingOptions;
  final bool usesTerminalUI;
  final bool stayResident;
  final bool ipv6;
  final Completer<int> _finished = new Completer<int>();
  bool _stopped = false;
  String _packagesFilePath;
  String get packagesFilePath => _packagesFilePath;
  String _projectRootPath;
  String get projectRootPath => _projectRootPath;
  String _mainPath;
  String get mainPath => _mainPath;
  AssetBundle _assetBundle;
  AssetBundle get assetBundle => _assetBundle;

  bool get isRunningDebug => debuggingOptions.buildInfo.isDebug;
  bool get isRunningProfile => debuggingOptions.buildInfo.isProfile;
  bool get isRunningRelease => debuggingOptions.buildInfo.isRelease;
  bool get supportsServiceProtocol => isRunningDebug || isRunningProfile;

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
    _stopped = true;
    await stopEchoingDeviceLog();
    await preStop();
    return stopApp();
  }

  Future<Null> detach() async {
    await stopEchoingDeviceLog();
    await preStop();
    appFinished();
  }

  Future<Null> refreshViews() async {
    for (FlutterDevice device in flutterDevices)
      await device.refreshViews();
  }

  Future<Null> _debugDumpApp() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.debugDumpApp();
  }

  Future<Null> _debugDumpRenderTree() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.debugDumpRenderTree();
  }

  Future<Null> _debugDumpLayerTree() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.debugDumpLayerTree();
  }

  Future<Null> _debugDumpSemanticsTreeInGeometricOrder() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.debugDumpSemanticsTreeInGeometricOrder();
  }

  Future<Null> _debugDumpSemanticsTreeInInverseHitTestOrder() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.debugDumpSemanticsTreeInInverseHitTestOrder();
  }

  Future<Null> _debugToggleDebugPaintSizeEnabled() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.toggleDebugPaintSizeEnabled();
  }

  Future<Null> _debugTogglePerformanceOverlayOverride() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.debugTogglePerformanceOverlayOverride();
  }

  Future<Null> _debugToggleWidgetInspector() async {
    await refreshViews();
    for (FlutterDevice device in flutterDevices)
      await device.toggleWidgetInspector();
  }

  Future<Null> _screenshot(FlutterDevice device) async {
    final Status status = logger.startProgress('Taking screenshot for ${device.device.name}...');
    final File outputFile = getUniqueFile(fs.currentDirectory, 'flutter', 'png');
    try {
      if (supportsServiceProtocol && isRunningDebug) {
        await device.refreshViews();
        try {
          for (FlutterView view in device.views)
            await view.uiIsolate.flutterDebugAllowBanner(false);
        } catch (error) {
          status.stop();
          printError('Error communicating with Flutter on the device: $error');
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
            status.stop();
            printError('Error communicating with Flutter on the device: $error');
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

  Future<Null> _debugTogglePlatform() async {
    await refreshViews();
    final String from = await flutterDevices[0].views[0].uiIsolate.flutterPlatformOverride();
    String to;
    for (FlutterDevice device in flutterDevices)
      to = await device.togglePlatform(from: from);
    printStatus('Switched operating system to $to');
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

  Future<Null> stopEchoingDeviceLog() async {
    await Future.wait(
      flutterDevices.map((FlutterDevice device) => device.stopEchoingDeviceLog())
    );
  }

  /// If the [reloadSources] parameter is not null the 'reloadSources' service
  /// will be registered
  Future<Null> connectToServiceProtocol({String viewFilter,
      ReloadSources reloadSources}) async {
    if (!debuggingOptions.debuggingEnabled)
      return new Future<Null>.error('Error the service protocol is not enabled.');

    bool viewFound = false;
    for (FlutterDevice device in flutterDevices) {
      device.viewFilter = viewFilter;
      await device._connect(reloadSources: reloadSources);
      await device.getVMs();
      await device.waitForViews();
      if (device.views == null)
        printStatus('No Flutter views available on ${device.device.name}');
      else
        viewFound = true;
    }
    if (!viewFound)
      throwToolExit('No Flutter view is available');

    // Listen for service protocol connection to close.
    for (FlutterDevice device in flutterDevices) {
      for (VMService service in device.vmServices) {
        // This hooks up callbacks for when the connection stops in the future.
        // We don't want to wait for them. We don't handle errors in those callbacks'
        // futures either because they just print to logger and is not critical.
        service.done.then<Null>( // ignore: unawaited_futures
          _serviceProtocolDone,
          onError: _serviceProtocolError
        ).whenComplete(_serviceDisconnected);
      }
    }
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
    } else if (character == 'L') {
      if (supportsServiceProtocol) {
        await _debugDumpLayerTree();
        return true;
      }
    } else if (character == 'S') {
      if (supportsServiceProtocol) {
        await _debugDumpSemanticsTreeInGeometricOrder();
        return true;
      }
    } else if (character == 'U') {
      if (supportsServiceProtocol) {
        await _debugDumpSemanticsTreeInInverseHitTestOrder();
        return true;
      }
    } else if (character == 'p') {
      if (supportsServiceProtocol && isRunningDebug) {
        await _debugToggleDebugPaintSizeEnabled();
        return true;
      }
    } else if (character == 'P') {
      if (supportsServiceProtocol) {
        await _debugTogglePerformanceOverlayOverride();
      }
    } else if (lower == 'i') {
      if (supportsServiceProtocol) {
        await _debugToggleWidgetInspector();
        return true;
      }
    } else if (character == 's') {
      for (FlutterDevice device in flutterDevices) {
        if (device.device.supportsScreenshot)
          await _screenshot(device);
      }
      return true;
    } else if (lower == 'o') {
      if (supportsServiceProtocol && isRunningDebug) {
        await _debugTogglePlatform();
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
    // When terminal doesn't support line mode, '\n' can sneak into the input.
    command = command.trim();
    if (_processingUserRequest) {
      printTrace('Ignoring terminal input: "$command" because we are busy.');
      return;
    }
    _processingUserRequest = true;
    try {
      final bool handled = await _commonTerminalInputHandler(command);
      if (!handled)
        await handleTerminalCommand(command);
    } catch (error, st) {
      printError('$error\n$st');
      _cleanUpAndExit(null);
    } finally {
      _processingUserRequest = false;
    }
  }

  void _serviceDisconnected() {
    if (_stopped) {
      // User requested the application exit.
      return;
    }
    if (_finished.isCompleted)
      return;
    printStatus('Lost connection to device.');
    _resetTerminal();
    _finished.complete(0);
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

  bool hasDirtyDependencies(FlutterDevice device) {
    final DartDependencySetBuilder dartDependencySetBuilder =
        new DartDependencySetBuilder(mainPath, packagesFilePath);
    final DependencyChecker dependencyChecker =
        new DependencyChecker(dartDependencySetBuilder, assetBundle);
    final String path = device.package.packagePath;
    if (path == null)
      return true;
    final FileStat stat = fs.file(path).statSync();
    if (stat.type != FileSystemEntityType.FILE)
      return true;
    if (!fs.file(path).existsSync())
      return true;
    final DateTime lastBuildTime = stat.modified;
    return dependencyChecker.check(lastBuildTime);
  }

  Future<Null> preStop() async { }

  Future<Null> stopApp() async {
    for (FlutterDevice device in flutterDevices)
      await device.stopApps();
    appFinished();
  }

  /// Called to print help to the terminal.
  void printHelp({ @required bool details });

  void printHelpDetails() {
    if (supportsServiceProtocol) {
      printStatus('You can dump the widget hierarchy of the app (debugDumpApp) by pressing "w".');
      printStatus('To dump the rendering tree of the app (debugDumpRenderTree), press "t".');
      if (isRunningDebug) {
        printStatus('For layers (debugDumpLayerTree), use "L"; for accessibility (debugDumpSemantics), use "S" (for geometric order) or "U" (for inverse hit test order).');
        printStatus('To toggle the widget inspector (WidgetsApp.showWidgetInspectorOverride), press "i".');
        printStatus('To toggle the display of construction lines (debugPaintSizeEnabled), press "p".');
        printStatus('To simulate different operating systems, (defaultTargetPlatform), press "o".');
      } else {
        printStatus('To dump the accessibility tree (debugDumpSemantics), press "S" (for geometric order) or "U" (for inverse hit test order).');
      }
      printStatus('To display the performance overlay (WidgetsApp.showPerformanceOverlay), press "P".');
    }
    if (flutterDevices.any((FlutterDevice d) => d.device.supportsScreenshot))
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
  OperationResult(this.code, this.message, { this.hintMessage, this.hintId });

  /// The result of the operation; a non-zero code indicates a failure.
  final int code;

  /// A user facing message about the results of the operation.
  final String message;

  /// An optional hint about the results of the operation. This is used to provide
  /// sidecar data about the operation results. For example, this is used when
  /// a reload is successful but some changed program elements where not run after a
  /// reassemble.
  final String hintMessage;

  /// A key used by tools to discriminate between different kinds of operation results.
  /// For example, a successful reload might have a [code] of 0 and a [hintId] of
  /// `'restartRecommended'`.
  final String hintId;

  bool get isOk => code == 0;

  static final OperationResult ok = new OperationResult(0, '');
}

/// Given the value of the --target option, return the path of the Dart file
/// where the app's main function should be.
String findMainDartFile([String target]) {
  target ??= '';
  final String targetPath = fs.path.absolute(target);
  if (fs.isDirectorySync(targetPath))
    return fs.path.join(targetPath, 'lib', 'main.dart');
  else
    return targetPath;
}

String getMissingPackageHintForPlatform(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.android_arm:
    case TargetPlatform.android_arm64:
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

// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/web/devfs_web.dart';
import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart' as vmservice;
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart' hide StackTrace;

import '../application_package.dart';
import '../base/async_guard.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../convert.dart';
import '../devfs.dart';
import '../device.dart';
import '../features.dart';
import '../globals.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import '../resident_runner.dart';
import '../run_hot.dart';
import '../web/chrome.dart';
import '../web/web_device.dart';
import '../web/web_runner.dart';
import 'web_fs.dart';

/// Injectable factory to create a [ResidentWebRunner].
class DwdsWebRunnerFactory extends WebRunnerFactory {
  @override
  ResidentRunner createWebRunner(
    FlutterDevice device, {
    String target,
    @required FlutterProject flutterProject,
    @required bool ipv6,
    @required DebuggingOptions debuggingOptions,
  }) {
    return ResidentWebRunner(
      device,
      target: target,
      flutterProject: flutterProject,
      debuggingOptions: debuggingOptions,
      ipv6: ipv6,
    );
  }
}

/// A hot-runner which handles browser specific delegation.
class ResidentWebRunner extends ResidentRunner {
  ResidentWebRunner(this.device, {
    String target,
    @required this.flutterProject,
    @required bool ipv6,
    @required DebuggingOptions debuggingOptions,
  }) : super(
          <FlutterDevice>[],
          target: target ?? fs.path.join('lib', 'main.dart'),
          debuggingOptions: debuggingOptions,
          ipv6: ipv6,
          stayResident: true,
        );

  final FlutterDevice device;
  final FlutterProject flutterProject;
  DateTime firstBuildTime;

  // Only the debug builds of the web support the service protocol.
  @override
  bool get supportsServiceProtocol => isRunningDebug && device.device is! WebServerDevice;

  @override
  bool get debuggingEnabled => isRunningDebug && device.device is! WebServerDevice;

  WebFs _webFs;
  ConnectionResult _connectionResult;
  StreamSubscription<vmservice.Event> _stdOutSub;
  bool _exited = false;
  WipConnection _wipConnection;

  vmservice.VmService get _vmService => _connectionResult?.debugConnection?.vmService;

  @override
  bool get canHotRestart {
    return true;
  }

  @override
  Future<Map<String, dynamic>> invokeFlutterExtensionRpcRawOnFirstIsolate(
    String method, {
    Map<String, dynamic> params,
  }) async {
    final vmservice.Response response = await _vmService.callServiceExtension(method, args: params);
    return response.toJson();
  }

  @override
  Future<void> cleanupAfterSignal() async {
    await _cleanup();
  }

  @override
  Future<void> cleanupAtFinish() async {
    await _cleanup();
  }

  Future<void> _cleanup() async {
    if (_exited) {
      return;
    }
    await _stdOutSub?.cancel();
    await _webFs?.stop();
    await device.device.stopApp(null);
    _exited = true;
  }

  @override
  void printHelp({bool details = true}) {
    if (details) {
      return printHelpDetails();
    }
    const String fire = '🔥';
    const String rawMessage = '  To hot restart changes while running, press "r". '
      'To hot restart (and refresh the browser), press "R".';
    final String message = terminal.color(
      fire + terminal.bolden(rawMessage),
      TerminalColor.red,
    );
    printStatus('Warning: Flutter\'s support for web development is not stable yet and hasn\'t');
    printStatus('been thoroughly tested in production environments.');
    printStatus('For more information see https://flutter.dev/web');
    printStatus('');
    printStatus(message);
    const String quitMessage = 'To quit, press "q".';
    printStatus('For a more detailed help message, press "h". $quitMessage');
  }

  @override
  Future<int> run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
    String route,
  }) async {
    firstBuildTime = DateTime.now();
    final ApplicationPackage package = await ApplicationPackageFactory.instance.getPackageForPlatform(
      TargetPlatform.web_javascript,
      applicationBinary: null,
    );
    if (package == null) {
      printError('No application found for TargetPlatform.web_javascript.');
      printError('To add web support to a project, run `flutter create .`.');
      return 1;
    }
    if (!fs.isFileSync(mainPath)) {
      String message = 'Tried to run $mainPath, but that file does not exist.';
      if (target == null) {
        message +=
            '\nConsider using the -t option to specify the Dart file to start.';
      }
      printError(message);
      return 1;
    }
    final String modeName = debuggingOptions.buildInfo.friendlyModeName;
    printStatus('Launching ${getDisplayPath(target)} on ${device.device.name} in $modeName mode...');
    if (featureFlags.isWebIncrementalCompilerEnabled) {
      return _runExperimental(
        connectionInfoCompleter: connectionInfoCompleter,
        appStartedCompleter: appStartedCompleter,
        route: route,
        applicationPackage: package,
      );
    }

  }

  @override
  Future<int> attach({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
  }) async {
    if (featureFlags.isWebIncrementalCompilerEnabled) {
      return _attachExperimental(
        connectionInfoCompleter: connectionInfoCompleter,
        appStartedCompleter: appStartedCompleter,
      );
    }
  }

  @override
  Future<OperationResult> restart({
    bool fullRestart = false,
    bool pauseAfterRestart = false,
    String reason,
    bool benchmarkMode = false,
  }) async {
    if (featureFlags.isWebIncrementalCompilerEnabled) {
      return _restartExperimental(
        fullRestart: fullRestart,
        pauseAfterRestart: pauseAfterRestart,
        reason: reason,
        benchmarkMode: benchmarkMode,
      );
    }
  }

  Future<int> _runExperimental({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
    String route,
    ApplicationPackage applicationPackage,
  }) async {
    final String effectiveHostname = debuggingOptions.hostname ?? 'localhost';
    final int hostPort = debuggingOptions.port == null
      ? await os.findFreePort()
      : int.tryParse(debuggingOptions.port);
    device.devFS = WebDevFS(
      effectiveHostname,
      hostPort,
      packagesFilePath,
    );
    await device.devFS.create();
    await _updateDevFS(fullRestart: true);
    device.generator.accept();
    await device.device.startApp(applicationPackage,
      mainPath: target,
      debuggingOptions: debuggingOptions,
      platformArgs: <String, Object>{
        'uri': 'http://$effectiveHostname:$hostPort',
      },
    );
    return attach(
      connectionInfoCompleter: connectionInfoCompleter,
      appStartedCompleter: appStartedCompleter,
    );
  }

  /// Different implementations for the incremental compiler based workflow.
  Future<int> _attachExperimental({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
  }) async {
    final Chrome chrome = await ChromeLauncher.connectedInstance;
    final ChromeTab chromeTab = await chrome.chromeConnection.getTab((ChromeTab chromeTab) {
      return chromeTab.url.contains(debuggingOptions.hostname);
    });
    _wipConnection = await chromeTab.connect();
    appStartedCompleter?.complete();
    connectionInfoCompleter?.complete();
    final int result = await waitForAppToFinish();
    await cleanupAtFinish();
    return result;
  }

  Future<OperationResult> _restartExperimental({
    bool fullRestart = false,
    bool pauseAfterRestart = false,
    String reason,
    bool benchmarkMode = false,
  }) async {
    final UpdateFSReport report = await _updateDevFS(fullRestart: fullRestart);
    if (report.success) {
      device.generator.accept();
    } else {
      await device.generator.reject();
    }
    final String modules = report.invalidatedModules
      .map((String module) => '"$module"').join(',');
    if (fullRestart) {
      await _wipConnection.sendCommand('Page.reload');
    } else {
      await _wipConnection.debugger
        .sendCommand('Runtime.evaluate', params: <String, Object>{
        'expression': 'window.\$hotReloadHook([$modules])',
        'awaitPromise': true,
        'returnByValue': true,
      });
    }
    return OperationResult.ok;
  }

  Future<UpdateFSReport> _updateDevFS({ bool fullRestart = false }) async {
    final bool isFirstUpload = !assetBundle.wasBuiltOnce();
    final bool rebuildBundle = assetBundle.needsBuild();
    if (rebuildBundle) {
      printTrace('Updating assets');
      final int result = await assetBundle.build();
      if (result != 0) {
        return UpdateFSReport(success: false);
      }
    }
    final List<Uri> invalidatedFiles = await ProjectFileInvalidator.findInvalidated(
      lastCompiled: device.devFS.lastCompiled,
      urisToMonitor: device.devFS.sources,
      packagesPath: packagesFilePath,
    );
    final UpdateFSReport results = UpdateFSReport(success: true);
    results.incorporateResults(await device.updateDevFS(
      mainPath: mainPath,
      target: target,
      bundle: assetBundle,
      firstBuildTime: firstBuildTime,
      bundleFirstUpload: isFirstUpload,
      bundleDirty: !isFirstUpload && rebuildBundle,
      fullRestart: fullRestart,
      projectRootPath: projectRootPath,
      pathToReload: getReloadPath(fullRestart: fullRestart),
      invalidatedFiles: invalidatedFiles,
      dillOutputPath: dillOutputPath,
    ));
    return results;
  }

  @override
  Future<void> debugDumpApp() async {
    try {
      await _vmService.callServiceExtension(
        'ext.flutter.debugDumpApp',
      );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugDumpRenderTree() async {
    try {
      await _vmService?.callServiceExtension(
        'ext.flutter.debugDumpRenderTree',
      );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugDumpLayerTree() async {
    try {
      await _vmService?.callServiceExtension(
        'ext.flutter.debugDumpLayerTree',
      );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugDumpSemanticsTreeInTraversalOrder() async {
    try {
      await _vmService?.callServiceExtension(
          'ext.flutter.debugDumpSemanticsTreeInTraversalOrder');
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugTogglePlatform() async {
    try {
      final vmservice.Response response = await _vmService?.callServiceExtension(
          'ext.flutter.platformOverride');
      final String currentPlatform = response.json['value'];
      String nextPlatform;
      switch (currentPlatform) {
        case 'android':
          nextPlatform = 'iOS';
          break;
        case 'iOS':
          nextPlatform = 'android';
          break;
      }
      if (nextPlatform == null) {
        return;
      }
      await _vmService?.callServiceExtension(
        'ext.flutter.platformOverride', args: <String, Object>{
          'value': nextPlatform,
        });
      printStatus('Switched operating system to $nextPlatform');
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugDumpSemanticsTreeInInverseHitTestOrder() async {
    try {
      await _vmService?.callServiceExtension(
          'ext.flutter.debugDumpSemanticsTreeInInverseHitTestOrder');
    } on vmservice.RPCError {
      return;
    }
  }


  @override
  Future<void> debugToggleDebugPaintSizeEnabled() async {
    try {
      final vmservice.Response response = await _vmService?.callServiceExtension(
        'ext.flutter.debugPaint',
      );
      await _vmService?.callServiceExtension(
        'ext.flutter.debugPaint',
        args: <dynamic, dynamic>{'enabled': !(response.json['enabled'] == 'true')},
      );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugToggleDebugCheckElevationsEnabled() async {
    try {
      final vmservice.Response response = await _vmService?.callServiceExtension(
        'ext.flutter.debugCheckElevationsEnabled',
      );
      await _vmService?.callServiceExtension(
        'ext.flutter.debugCheckElevationsEnabled',
        args: <dynamic, dynamic>{'enabled': !(response.json['enabled'] == 'true')},
      );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugTogglePerformanceOverlayOverride() async {
    try {
      final vmservice.Response response = await _vmService?.callServiceExtension(
        'ext.flutter.showPerformanceOverlay'
      );
      await _vmService?.callServiceExtension(
        'ext.flutter.showPerformanceOverlay',
        args: <dynamic, dynamic>{'enabled': !(response.json['enabled'] == 'true')},
      );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugToggleWidgetInspector() async {
    try {
      final vmservice.Response response = await _vmService?.callServiceExtension(
        'ext.flutter.debugToggleWidgetInspector'
      );
      await _vmService?.callServiceExtension(
        'ext.flutter.debugToggleWidgetInspector',
        args: <dynamic, dynamic>{'enabled': !(response.json['enabled'] == 'true')},
      );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugToggleProfileWidgetBuilds() async {
    try {
      final vmservice.Response response = await _vmService?.callServiceExtension(
        'ext.flutter.profileWidgetBuilds'
      );
      await _vmService?.callServiceExtension(
        'ext.flutter.profileWidgetBuilds',
        args: <dynamic, dynamic>{'enabled': !(response.json['enabled'] == 'true')},
      );
    } on vmservice.RPCError {
      return;
    }
  }
}

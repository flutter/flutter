// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/run_cold.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:meta/meta.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';
import 'package:vm_service_lib/vm_service_lib.dart';

import 'application_package.dart';
import 'asset.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/terminal.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'bundle.dart';
import 'dart/package_map.dart';
import 'device.dart';
import 'globals.dart';
import 'project.dart';
import 'resident_runner.dart';
import 'run_hot.dart';
import 'web/asset_server.dart';
import 'web/chrome.dart';
import 'web/compile.dart';


import 'package:build_daemon/client.dart';
import 'package:webdev/src/serve/webdev_server.dart';
import 'package:webdev/src/serve/debugger/devtools.dart';


import 'package:webdev/src/command/build_command.dart';

import 'package:webdev/src/daemon/app_domain.dart';
import 'package:webdev/src/serve/handlers/dev_handler.dart';
import 'package:webdev/src/serve/debugger/app_debug_services.dart';

/// A hot-runner which handles browser specific delegation.
class ResidentWebRunner extends ResidentRunner {
  ResidentWebRunner(this.device, {
    String target,
    @required this.flutterProject,
    @required bool ipv6,
    @required DebuggingOptions debuggingOptions,
  }) : super(
          [],
          target: target,
          usesTerminalUI: true,
          stayResident: true,
          saveCompilationTrace: false,
          debuggingOptions: debuggingOptions,
          ipv6: ipv6,
        );

  final Device device;
  WebAssetServer _server;
  DevHandler _devHandler;
  AppDebugServices _appDebugServices;
  ProjectFileInvalidator projectFileInvalidator;
  DateTime _lastCompiled;
  WipConnection _connection;
  final FlutterProject flutterProject;

  @override
  Future<int> attach(
      {Completer<DebugConnectionInfo> connectionInfoCompleter,
      Completer<void> appStartedCompleter}) async {
    connectionInfoCompleter?.complete(DebugConnectionInfo());
    setupTerminal();
    final int result = await waitForAppToFinish();
    await cleanupAtFinish();
    return result;
  }

  @override
  Future<void> cleanupAfterSignal() async {
    await _connection.sendCommand('Browser.close');
    _connection = null;
    await _server?.dispose();
  }

  @override
  Future<void> cleanupAtFinish() async {
    await _connection?.sendCommand('Browser.close');
    _connection = null;
    await _server?.dispose();
  }

  @override
  Future<void> handleTerminalCommand(String code) async {
    if (code == 'R') {
      // If hot restart is not supported for all devices, ignore the command.
      if (!canHotRestart) {
        return;
      }
      await restart(fullRestart: true);
    }
  }
  
  VmService get vmService => _appDebugServices?.webdevClient?.client;

  @override
  void printHelp({bool details}) {
    const String fire = '🔥';
    const String rawMessage =
        '  To hot restart (and rebuild state), press "R".';
    final String message = terminal.color(
      fire + terminal.bolden(rawMessage),
      TerminalColor.red,
    );
    const String warning = '👻 ';
    printStatus(warning * 20);
    printStatus('Warning: Flutter\'s support for building web applications is highly experimental.');
    printStatus('For more information see https://github.com/flutter/flutter/issues/34082.');
    printStatus(warning * 20);
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
    bool shouldBuild = true,
  }) async {
    final ApplicationPackage package = await ApplicationPackageFactory.instance.getPackageForPlatform(
      TargetPlatform.web_javascript,
      applicationBinary: null,
    );
    if (package == null) {
      printError('No application found for TargetPlatform.web_javascript');
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

    /// Start a build daemon.
    final DaemonHandle handle = await webCompilationProxy.daemon(
      projectDirectory: FlutterProject.current().directory,
      targets: <String>[target],
      release: debuggingOptions.buildInfo.isRelease,
    );

    /// Start the webdev server?
    final Chrome chrome = await chromeLauncher.launch('???');
    final DevTools devTools = await DevTools.start('????????');
    final ServerOptions serverOptions = ServerOptions(null, null, null, null);
    final WebDevServer server = await WebDevServer.start(serverOptions, handle.buildResults, devTools);
    _devHandler = server.devHandler;
    final connection = await _devHandler.connectedApps.first;
    _appDebugServices = await _devHandler.loadAppServices(
      connection.request.appId, connection.request.instanceId);

    // where the magic is
    // server.devHandler

    // Start the web compiler and build the assets.
    // await webCompilationProxy.initialize(
    //   projectDirectory: FlutterProject.current().directory,
    //   targets: <String>[target],
    // );
    // _lastCompiled = DateTime.now();
    // final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
    // final int build = await assetBundle.build();
    // if (build != 0) {
    //   throwToolExit('Error: Failed to build asset bundle');
    // }
    // await writeBundle(fs.directory(getAssetBuildDirectory()), assetBundle.entries);

    // // Step 2: Start an HTTP server
    // _server = WebAssetServer(flutterProject, target, ipv6);
    // await _server.initialize();

    // // Step 3: Spawn an instance of Chrome and direct it to the created server.
    // final String url = 'http://localhost:${_server.port}';
    // final Chrome chrome = await chromeLauncher.launch(url);
    // final ChromeTab chromeTab = await chrome.chromeConnection.getTab((ChromeTab chromeTab) {
    //   return chromeTab.url.contains(url); // we don't care about trailing slashes or #
    // });
    // _connection = await chromeTab.connect();
    // _connection.onClose.listen((WipConnection connection) {
    //   exit();
    // });

    // We don't support the debugging proxy yet.
    appStartedCompleter?.complete();
    return attach(
      connectionInfoCompleter: connectionInfoCompleter,
      appStartedCompleter: appStartedCompleter,
    );
  }

  @override
  Future<OperationResult> restart({
    bool fullRestart = false,
    bool pauseAfterRestart = false,
    String reason,
    bool benchmarkMode = false,
  }) async {
    final Stopwatch timer = Stopwatch()..start();
    final Status status = logger.startProgress(
      'Performing hot restart...',
      timeout: timeoutConfiguration.fastOperation,
      progressId: 'hot.restart',
    );
    final Response response = await vmService.callMethod('hotRestart');
    return OperationResult.ok;

    // try {
    //   final List<Uri> invalidatedSources = ProjectFileInvalidator.findInvalidated(
    //     lastCompiled: _lastCompiled,
    //     urisToMonitor: <Uri>[
    //       for (FileSystemEntity entity in flutterProject.directory
    //           .childDirectory('lib')
    //           .listSync(recursive: true))
    //         if (entity is File && entity.path.endsWith('.dart')) entity.uri
    //     ], // Add new class to track this for web.
    //     packagesPath: PackageMap.globalPackagesPath,
    //   );
    //   await webCompilationProxy.invalidate(inputs: invalidatedSources);
    //   await _connection.sendCommand('Page.reload');
    //   await Future<void>.delayed(const Duration(milliseconds: 150));
    // } catch (err) {
    //   result = OperationResult(1, err.toString());
    // } finally {
    //   printStatus('Restarted application in ${getElapsedAsMilliseconds(timer.elapsed)}.');
    //   status.cancel();
    // }
    // return result;
  }

  @override
  Future<void> debugDumpApp() async {
    final Response response = await vmService.callMethod('flutter.ext.debugDumpApp');
  }

  @override
  Future<void> debugDumpRenderTree() async {
    final Response response = await vmService.callMethod('flutter.ext.debugDumpRenderTree');
  }

  @override
  Future<void> debugDumpLayerTree() async {
    final Response response = await vmService.callMethod('flutter.ext.debugDumpLayerTree');
  }

  @override
  Future<void> debugDumpSemanticsTreeInTraversalOrder() async {
    final Response response = await vmService.callMethod('flutter.ext.debugDumpSemanticsTreeInTraversalOrder');
  }

  @override
  Future<void> debugDumpSemanticsTreeInInverseHitTestOrder() async {
    final Response response = await vmService.callMethod('flutter.ext.debugDumpSemanticsTreeInInverseHitTestOrder');
  }

  @override
  Future<void> debugToggleDebugPaintSizeEnabled() async {
    final Response response = await vmService.callMethod('flutter.ext.debugToggleDebugPaintSizeEnabled');
  }

  @override
  Future<void> debugToggleDebugCheckElevationsEnabled() async {
    final Response response = await vmService.callMethod('flutter.ext.debugToggleDebugCheckElevationsEnabled');
  }

  @override
  Future<void> debugTogglePerformanceOverlayOverride() async {
    final Response response = await vmService.callMethod('flutter.ext.debugTogglePerformanceOverlayOverride');
  }

  @override
  Future<void> debugToggleWidgetInspector() async {
    final Response response = await vmService.callMethod('flutter.ext.debugToggleWidgetInspector');
  }

  @override
  Future<void> debugToggleProfileWidgetBuilds() async {
    final Response response = await vmService.callMethod('flutter.ext.debugToggleProfileWidgetBuilds');
  }

}

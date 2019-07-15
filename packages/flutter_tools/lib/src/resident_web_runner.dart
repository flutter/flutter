// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

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

/// A hot-runner which handles browser specific delegation.
class ResidentWebRunner extends ResidentRunner {
  ResidentWebRunner(
    List<FlutterDevice> flutterDevices, {
    String target,
    @required this.flutterProject,
    @required bool ipv6,
    @required DebuggingOptions debuggingOptions,
  }) : super(
          flutterDevices,
          target: target,
          debuggingOptions: debuggingOptions,
          ipv6: ipv6,
          usesTerminalUi: true,
          stayResident: true,
        );

  WebAssetServer _server;
  ProjectFileInvalidator projectFileInvalidator;
  DateTime _lastCompiled;
  WipConnection _connection;
  final FlutterProject flutterProject;

  @override
  bool get canHotReload => false;

  @override
  Future<int> attach(
      {Completer<DebugConnectionInfo> connectionInfoCompleter,
      Completer<void> appStartedCompleter}) async {
    connectionInfoCompleter?.complete(DebugConnectionInfo());
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
    // Start the web compiler and build the assets.
    final bool success = await webCompilationProxy.initialize(
      projectDirectory: flutterProject.directory,
    );
    if (!success) {
      throwToolExit('Failed to compile for the web.');
    }
    _lastCompiled = DateTime.now();
    final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
    final int build = await assetBundle.build();
    if (build != 0) {
      throwToolExit('Error: Failed to build asset bundle.');
    }
    await writeBundle(fs.directory(getAssetBuildDirectory()), assetBundle.entries);

    // Step 2: Start an HTTP server
    _server = WebAssetServer(flutterProject, target, ipv6);
    await _server.initialize();

    // Step 3: Spawn an instance of Chrome and direct it to the created server.
    final String url = 'http://localhost:${_server.port}';
    final Chrome chrome = await chromeLauncher.launch(url);
    final ChromeTab chromeTab = await chrome.chromeConnection.getTab((ChromeTab chromeTab) {
      return chromeTab.url.contains(url); // we don't care about trailing slashes or #
    });
    _connection = await chromeTab.connect();
    _connection.onClose.listen((WipConnection connection) {
      exit();
    });

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
    OperationResult result = OperationResult.ok;
    try {
      final List<Uri> invalidatedSources = ProjectFileInvalidator.findInvalidated(
        lastCompiled: _lastCompiled,
        urisToMonitor: <Uri>[
          for (FileSystemEntity entity in flutterProject.directory
              .childDirectory('lib')
              .listSync(recursive: true))
            if (entity is File && entity.path.endsWith('.dart')) entity.uri
        ], // Add new class to track this for web.
        packagesPath: PackageMap.globalPackagesPath,
      );
      await webCompilationProxy.invalidate(inputs: invalidatedSources);
      await _connection.sendCommand('Page.reload');
      await Future<void>.delayed(const Duration(milliseconds: 150));
    } catch (err) {
      result = OperationResult(1, err.toString());
    } finally {
      printStatus('Restarted application in ${getElapsedAsMilliseconds(timer.elapsed)}.');
      status.cancel();
    }
    return result;
  }
}

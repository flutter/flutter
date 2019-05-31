// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'asset.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'base/terminal.dart';
import 'build_info.dart';
import 'bundle.dart';
import 'dart/package_map.dart';
import 'device.dart';
import 'globals.dart';
import 'project.dart';
import 'resident_runner.dart';
import 'run_hot.dart';
import 'web/asset_server.dart';
import 'web/compile.dart';
import 'web/web_device.dart';

/// A hot-runner which handles browser specific delegation.
class ResidentWebRunner extends ResidentRunner {
  ResidentWebRunner(
    List<FlutterDevice> flutterDevices, {
    String target,
    @required this.flutterProject,
    @required bool ipv6,
  }) : super(
          flutterDevices,
          target: target,
          usesTerminalUI: true,
          stayResident: true,
          saveCompilationTrace: false,
          debuggingOptions: DebuggingOptions.enabled(
            const BuildInfo(BuildMode.debug, ''),
          ),
          ipv6: ipv6,
        );

  WebAssetServer _server;
  ProjectFileInvalidator projectFileInvalidator;
  DateTime _lastCompiled;
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
  Future<void> cleanupAfterSignal() {
    return _server?.dispose();
  }

  @override
  Future<void> cleanupAtFinish() {
    return _server?.dispose();
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

  @override
  void printHelp({bool details}) {
    const String fire = '🔥';
    const String rawMessage =
        '  To hot restart (and rebuild state), press "R".';
    final String message = terminal.color(
      fire + terminal.bolden(rawMessage),
      TerminalColor.red,
    );
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
    final FlutterProject currentProject = FlutterProject.current();
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
    await webCompilationProxy.initialize(
      projectDirectory: currentProject.directory,
      target: target,
    );
    _lastCompiled = DateTime.now();
    final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
    final int build = await assetBundle.build();
    if (build != 0) {
      throwToolExit('Error: Failed to build asset bundle');
    }
    writeBundle(fs.directory(getAssetBuildDirectory()), assetBundle.entries);

    // Step 2: Start an HTTP server
    _server = WebAssetServer(flutterProject, target, ipv6);
    await _server.initialize();

    // Step 3: Spawn an instance of Chrome and direct it to the created server.
    await chromeLauncher.launch('http:localhost:${_server.port}');

    // We don't support the debugging proxy yet.
    appStartedCompleter?.complete();
    return attach(
      connectionInfoCompleter: connectionInfoCompleter,
      appStartedCompleter: appStartedCompleter,
    );
  }

  @override
  Future<OperationResult> restart(
      {bool fullRestart = false,
      bool pauseAfterRestart = false,
      String reason,
      bool benchmarkMode = false}) async {
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
    printStatus('Sources updated, refresh browser');
    return OperationResult.ok;
  }
}

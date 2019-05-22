// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'artifacts.dart';
import 'asset.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'base/io.dart';
import 'base/terminal.dart';
import 'build_info.dart';
import 'bundle.dart';
import 'dart/package_map.dart';
import 'device.dart';
import 'globals.dart';
import 'project.dart';
import 'resident_runner.dart';
import 'run_hot.dart';
import 'web/compile.dart';
import 'web/web_device.dart';

/// A hot-runner which handles browser specific delegation.
class ResidentWebRunner extends ResidentRunner {
  ResidentWebRunner(
    List<FlutterDevice> flutterDevices, {
    String target,
    @required this.flutterProject,
  }) : super(
          flutterDevices,
          target: target,
          usesTerminalUI: true,
          stayResident: true,
          saveCompilationTrace: false,
          debuggingOptions: DebuggingOptions.enabled(
            const BuildInfo(BuildMode.debug, ''),
          ),
        );

  HttpServer _server;
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
    return null;
  }

  @override
  Future<void> cleanupAtFinish() {
    return _server?.close();
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
    if (details) {
      printHelpDetails();
      printStatus('To repeat this help message, press "h". $quitMessage');
    } else {
      printStatus('For a more detailed help message, press "h". $quitMessage');
    }
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
    await writeBundle(
        fs.directory(getAssetBuildDirectory()), assetBundle.entries);

    // Step 2: Start an HTTP server
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_basicAssetServer);
    printStatus('Serving assets from http:localhost:${_server.port}');

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

  /// An HTTP serve which provides JavaScript and web assets to the browser.
  Future<void> _basicAssetServer(HttpRequest request) async {
    if (request.method != 'GET') {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
      return;
    }
    // Resolve all get requests to the build/web/ or build/flutter_assets directory.
    final Uri uri = request.uri;
    File file;
    String contentType;
    if (uri.path == '/') {
      file = flutterProject.directory
          .childDirectory('web')
          .childFile('index.html');
      contentType = 'text/html';
    } else if (uri.path.endsWith('main.dart.js')) {
      file = fs.file(fs.path.join(flutterProject.generated.path, 'lib',
          '${fs.path.basename(target)}.js'));
      contentType = 'text/javascript';
    } else if (uri.path.endsWith('${fs.path.basename(target)}.bootstrap.js')) {
      file = fs.file(fs.path.join(flutterProject.generated.path, 'lib',
          '${fs.path.basename(target)}.bootstrap.js'));
      contentType = 'text/javascript';
    } else if (uri.path.contains('dart_sdk')) {
      file = fs.file(fs.path.join(
          artifacts.getArtifactPath(Artifact.flutterWebSdk),
          'kernel',
          'amd',
          'dart_sdk.js'));
      contentType = 'text/javascript';
    } else if (uri.path.startsWith('/packages')) {
      final List<String> segments = fs.path.split(uri.path);
      final String packageName = segments[2];
      final String filePath = fs.path.joinAll(segments.sublist(3));
      file = fs.file(fs.path.join(
          flutterProject.dartTool
              .childDirectory('build')
              .childDirectory('generated')
              .childDirectory(packageName)
              .childDirectory('lib')
              .path,
          filePath));
      contentType = 'text/javascript';
    } else {
      file = fs.file(fs.path.join(
          getAssetBuildDirectory(), uri.path.replaceFirst('/assets/', '')));
    }

    if (!file.existsSync()) {
      printTrace('Could not find ${file.path}');
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    request.response.statusCode = HttpStatus.ok;
    if (contentType != null) {
      request.response.headers.add(HttpHeaders.contentTypeHeader, contentType);
    }
    await request.response.addStream(file.openRead());
    await request.response.close();
  }
}

// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'application_package.dart';
import 'asset.dart';
import 'base/logger.dart';
import 'base/utils.dart';
import 'cache.dart';
import 'commands/build_apk.dart';
import 'commands/install.dart';
import 'device.dart';
import 'globals.dart';
import 'devfs.dart';
import 'observatory.dart';
import 'resident_runner.dart';

String getDevFSLoaderScript() {
  return path.absolute(path.join(Cache.flutterRoot,
                                 'packages',
                                 'flutter',
                                 'bin',
                                 'loader',
                                 'loader_app.dart'));
}

class HotRunner extends ResidentRunner {
  HotRunner(
    Device device, {
    String target,
    DebuggingOptions debuggingOptions,
    bool usesTerminalUI: true,
    this.pipe
  }) : super(device,
             target: target,
             debuggingOptions: debuggingOptions,
             usesTerminalUI: usesTerminalUI) {
    _projectRootPath = Directory.current.path;
  }

  ApplicationPackage _package;
  String _mainPath;
  String _projectRootPath;
  final AssetBundle bundle = new AssetBundle();
  final File pipe;

  Future<String> _readFromControlPipe() async {
    final Stream<List<int>> stream = pipe.openRead();
    final List<int> bytes = await stream.first;
    final String string = new String.fromCharCodes(bytes).trim();
    return string;
  }

  Future<Null> _startReadingFromControlPipe() async {
    if (pipe == null)
      return;

    while (true) {
      // This loop will only exit if _readFromControlPipe throws an exception.
      // If no exception is thrown this will keep the flutter command running
      // until it is explicitly stopped via some other mechanism, for example,
      // ctrl+c or sending "q" to the control pipe.
      String result = await _readFromControlPipe();
      printStatus('Control pipe received "$result"');
      await processTerminalInput(result);
      if (result.toLowerCase() == 'q') {
        printStatus("Finished reading from control pipe");
        break;
      }
    }
  }

  @override
  Future<int> run({
    Completer<int> observatoryPortCompleter,
    String route,
    bool shouldBuild: true
  }) {
    // Don't let uncaught errors kill the process.
    return runZoned(() {
      return _run(
        observatoryPortCompleter: observatoryPortCompleter,
        route: route,
        shouldBuild: shouldBuild
      );
    }, onError: (dynamic error, StackTrace stackTrace) {
      printError('Exception from flutter run: $error', stackTrace);
    });
  }

  Future<int> _run({
    Completer<int> observatoryPortCompleter,
    String route,
    bool shouldBuild: true
  }) async {
    _mainPath = findMainDartFile(target);
    if (!FileSystemEntity.isFileSync(_mainPath)) {
      String message = 'Tried to run $_mainPath, but that file does not exist.';
      if (target == null)
        message += '\nConsider using the -t option to specify the Dart file to start.';
      printError(message);
      return 1;
    }

    _package = getApplicationPackageForPlatform(device.platform);

    if (_package == null) {
      String message = 'No application found for ${device.platform}.';
      String hint = getMissingPackageHintForPlatform(device.platform);
      if (hint != null)
        message += '\n$hint';
      printError(message);
      return 1;
    }

    // TODO(devoncarew): We shouldn't have to do type checks here.
    if (shouldBuild && device is AndroidDevice) {
      printTrace('Running build command.');

      int result = await buildApk(
        device.platform,
        target: target,
        buildMode: debuggingOptions.buildMode
      );

      if (result != 0)
        return result;
    }

    // TODO(devoncarew): Move this into the device.startApp() impls.
    if (_package != null) {
      printTrace("Stopping app '${_package.name}' on ${device.name}.");
      // We don't wait for the stop command to complete.
      device.stopApp(_package);
    }

    // Allow any stop commands from above to start work.
    await new Future<Duration>.delayed(Duration.ZERO);

    // TODO(devoncarew): This fails for ios devices - we haven't built yet.
    if (device is AndroidDevice) {
      printTrace('Running install command.');
      if (!(installApp(device, _package, uninstall: false)))
        return 1;
    }

    Map<String, dynamic> platformArgs = new Map<String, dynamic>();

    await startEchoingDeviceLog();

    if (device.needsDevFS) {
      printStatus('Launching loader on ${device.name}...');
    } else {
      printStatus('Launching ${getDisplayPath(_mainPath)} on ${device.name}...');
    }

    LaunchResult result = await device.startApp(
      _package,
      debuggingOptions.buildMode,
      mainPath: device.needsDevFS ? getDevFSLoaderScript() : _mainPath,
      debuggingOptions: debuggingOptions,
      platformArgs: platformArgs,
      route: route
    );

    if (!result.started) {
      if (device.needsDevFS) {
        printError('Error launching DevFS loader on ${device.name}.');
      } else {
        printError('Error launching ${getDisplayPath(_mainPath)} on ${device.name}.');
      }
      await stopEchoingDeviceLog();
      return 2;
    }

    if (observatoryPortCompleter != null && result.hasObservatory)
      observatoryPortCompleter.complete(result.observatoryPort);

    await connectToServiceProtocol(result.observatoryPort);

    if (device.needsDevFS) {
      _loaderShowMessage('Connecting...', progress: 0);
      bool result = await _updateDevFS(
        progressReporter: (int progress, int max) {
          _loaderShowMessage('Syncing files to device...', progress: progress, max: max);
        }
      );
      if (!result) {
        _loaderShowMessage('Failed.');
        printError('Could not perform initial file synchronization.');
        return 3;
      }
      printStatus('Running ${getDisplayPath(_mainPath)} on ${device.name}...');
      _loaderShowMessage('Launching...');
      await _launchFromDevFS(_package, _mainPath);
    }

    _startReadingFromControlPipe();

    printStatus('Application running.');

    setupTerminal();

    registerSignalHandlers();

    return await waitForAppToFinish();
  }

  @override
  Future<Null> handleTerminalCommand(String code) async {
    final String lower = code.toLowerCase();
    if ((lower == 'r') || (code == AnsiTerminal.KEY_F5)) {
      // F5, restart
      if ((code == 'r') || (code == AnsiTerminal.KEY_F5)) {
        // lower-case 'r'
        await _reloadSources();
      } else {
        // upper-case 'R'.
        await _restartFromSources();
      }
    }
  }

  void _loaderShowMessage(String message, { int progress, int max }) {
    serviceProtocol.flutterLoaderShowMessage(serviceProtocol.firstIsolateId, message);
    if (progress != null) {
      serviceProtocol.flutterLoaderSetProgress(serviceProtocol.firstIsolateId, progress.toDouble());
      serviceProtocol.flutterLoaderSetProgressMax(serviceProtocol.firstIsolateId, max?.toDouble() ?? 0.0);
    } else {
      serviceProtocol.flutterLoaderSetProgress(serviceProtocol.firstIsolateId, 0.0);
      serviceProtocol.flutterLoaderSetProgressMax(serviceProtocol.firstIsolateId, -1.0);
    }
  }

  DevFS _devFS;
  Future<bool> _updateDevFS({ DevFSProgressReporter progressReporter }) async {
    if (_devFS == null) {
      String fsName = path.basename(_projectRootPath);
      _devFS = new DevFS(serviceProtocol,
                         fsName,
                         new Directory(_projectRootPath));

      try {
        await _devFS.create();
      } catch (error) {
        _devFS = null;
        printError('Error initializing DevFS: $error');
        return false;
      }
    }

    final bool rebuildBundle = bundle.needsBuild();
    if (rebuildBundle) {
      Status bundleStatus = logger.startProgress('Updating assets...');
      await bundle.build();
      bundleStatus.stop(showElapsedTime: true);
    }
    Status devFSStatus = logger.startProgress('Syncing files to device...');
    await _devFS.update(progressReporter: progressReporter,
                        bundle: bundle,
                        bundleDirty: rebuildBundle);
    devFSStatus.stop(showElapsedTime: true);
    if (progressReporter != null)
      printStatus('Synced ${getSizeAsMB(_devFS.bytes)}.');
    else
      printTrace('Synced ${getSizeAsMB(_devFS.bytes)}.');
    return true;
  }

  Future<Null> _cleanupDevFS() async {
    if (_devFS != null) {
      // Cleanup the devFS.
      await _devFS.destroy();
    }
    _devFS = null;
  }

  Future<Null> _launchInView(String entryPath,
                             String packagesPath,
                             String assetsDirectoryPath) async {
    String viewId = await serviceProtocol.getFirstViewId();
    // When this completer completes the isolate is running.
    // TODO(johnmccutchan): Have the framework send an event after the first
    // frame is rendered and use that instead of 'runnable'.
    Completer<Null> completer = new Completer<Null>();
    StreamSubscription<Event> subscription =
       serviceProtocol.onIsolateEvent.listen((Event event) {
     if (event.kind == 'IsolateStart') {
       printTrace('Isolate is spawned.');
     } else if (event.kind == 'IsolateRunnable') {
       printTrace('Isolate is runnable.');
       completer.complete(null);
     }
    });
    await serviceProtocol.runInView(viewId,
                                   entryPath,
                                   packagesPath,
                                   assetsDirectoryPath);
    await completer.future;
    await subscription.cancel();
  }

  Future<Null> _launchFromDevFS(ApplicationPackage package,
                                String mainScript) async {
    String entryPath = path.relative(mainScript, from: _projectRootPath);
    String deviceEntryPath =
        _devFS.baseUri.resolve(entryPath).toFilePath();
    String devicePackagesPath =
        _devFS.baseUri.resolve('.packages').toFilePath();
    String deviceAssetsDirectoryPath =
        _devFS.baseUri.resolve('build/flx').toFilePath();
    await _launchInView(deviceEntryPath,
                        devicePackagesPath,
                        deviceAssetsDirectoryPath);
  }

  Future<Null> _launchFromDisk(ApplicationPackage package,
                               String mainScript) async {
    Uri baseUri = new Uri.directory(_projectRootPath);
    String entryPath = path.relative(mainScript, from: _projectRootPath);
    String diskEntryPath = baseUri.resolve(entryPath).toFilePath();
    String diskPackagesPath = baseUri.resolve('.packages').toFilePath();
    String diskAssetsDirectoryPath = baseUri.resolve('build/flx').toFilePath();
    await _launchInView(diskEntryPath,
                        diskPackagesPath,
                        diskAssetsDirectoryPath);
  }

  Future<Null> _restartFromSources() async {
    if (_devFS == null) {
      Status restartStatus = logger.startProgress('Restarting application...');
      await _launchFromDisk(_package, _mainPath);
      restartStatus.stop(showElapsedTime: true);
    } else {
      await _updateDevFS();
      Status restartStatus = logger.startProgress('Restarting application...');
      await _launchFromDevFS(_package, _mainPath);
      restartStatus.stop(showElapsedTime: true);
    }
  }

  /// Returns [true] if the reload was successful.
  bool _printReloadReport(Map<String, dynamic> reloadReport) {
    if (!reloadReport['success']) {
      printError('Hot reload was rejected:');
      for (Map<String, dynamic> notice in reloadReport['details']['notices'])
        printError('${notice['message']}');
      return false;
    }
    int loadedLibraryCount = reloadReport['details']['loadedLibraryCount'];
    int finalLibraryCount = reloadReport['details']['finalLibraryCount'];
    printStatus('Reloaded $loadedLibraryCount of $finalLibraryCount libraries.');
    return true;
  }

  @override
  Future<bool> restart() => _reloadSources();

  Future<bool> _reloadSources() async {
    if (serviceProtocol.firstIsolateId == null)
      throw 'Application isolate not found';
    if (_devFS != null)
      await _updateDevFS();
    Status reloadStatus = logger.startProgress('Performing hot reload...');
    try {
      Map<String, dynamic> reloadReport =
          await serviceProtocol.reloadSources(serviceProtocol.firstIsolateId);
      reloadStatus.stop(showElapsedTime: true);
      if (!_printReloadReport(reloadReport)) {
        // Reload failed.
        return false;
      }
    } catch (errorMessage) {
      reloadStatus.stop(showElapsedTime: true);
      printError('Hot reload failed:\n$errorMessage');
      return false;
    }
    Status reassembleStatus =
        logger.startProgress('Reassembling application...');
    try {
      await serviceProtocol.flutterReassemble(serviceProtocol.firstIsolateId);
    } catch (_) {
      reassembleStatus.stop(showElapsedTime: true);
      printError('Reassembling application failed.');
      return false;
    }
    reassembleStatus.stop(showElapsedTime: true);
    return true;
  }

  @override
  void printHelp() {
    printStatus('Type "h" or F1 for this help message. Type "q", F10, or ctrl-c to quit.', emphasis: true);
    printStatus('Type "r" or F5 to perform a hot reload of the app.', emphasis: true);
    printStatus('Type "R" to restart the app', emphasis: true);
    printStatus('Type "w" to print the widget hierarchy of the app, and "t" for the render tree.', emphasis: true);
  }

  @override
  Future<Null> cleanupAfterSignal() async {
    await stopEchoingDeviceLog();
    await stopApp();
  }

  @override
  Future<Null> cleanupAtFinish() async {
    await _cleanupDevFS();
    await stopEchoingDeviceLog();
  }
}

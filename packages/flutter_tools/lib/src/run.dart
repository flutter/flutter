// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'application_package.dart';
import 'base/logger.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'commands/build_apk.dart';
import 'commands/install.dart';
import 'commands/trace.dart';
import 'dart/package_map.dart';
import 'device.dart';
import 'globals.dart';
import 'observatory.dart';

/// Given the value of the --target option, return the path of the Dart file
/// where the app's main function should be.
String findMainDartFile([String target]) {
  if (target == null)
    target = '';
  String targetPath = path.absolute(target);
  if (FileSystemEntity.isDirectorySync(targetPath))
    return path.join(targetPath, 'lib', 'main.dart');
  else
    return targetPath;
}

class RunAndStayResident {
  RunAndStayResident(
    this.device, {
    this.target,
    this.debuggingOptions,
    this.usesTerminalUI: true,
    this.useDevFS: false
  });

  final Device device;
  final String target;
  final DebuggingOptions debuggingOptions;
  final bool usesTerminalUI;
  final bool useDevFS;

  ApplicationPackage _package;
  String _mainPath;
  LaunchResult _result;

  Completer<int> _exitCompleter = new Completer<int>();
  StreamSubscription<String> _loggingSubscription;

  Observatory observatory;

  /// Start the app and keep the process running during its lifetime.
  Future<int> run({
    bool traceStartup: false,
    bool benchmark: false,
    Completer<int> observatoryPortCompleter,
    String route
  }) {
    // Don't let uncaught errors kill the process.
    return runZoned(() {
      return _run(
        traceStartup: traceStartup,
        benchmark: benchmark,
        observatoryPortCompleter: observatoryPortCompleter,
        route: route
      );
    }, onError: (dynamic error, StackTrace stackTrace) {
      printError('Exception from flutter run: $error', stackTrace);
    });
  }

  Future<bool> restart() async {
    if (observatory == null) {
      printError('Debugging is not enabled.');
      return false;
    } else {
      Status status = logger.startProgress('Re-starting application...');

      Future<Event> extensionAddedEvent = observatory.onExtensionEvent
        .where((Event event) => event.extensionKind == 'Flutter.FrameworkInitialization')
        .first;

      bool restartResult = await device.restartApp(
        _package,
        _result,
        mainPath: _mainPath,
        observatory: observatory
      );

      status.stop(showElapsedTime: true);

      if (restartResult) {
        // TODO(devoncarew): We should restore the route here.
        await extensionAddedEvent;
      }

      return restartResult;
    }
  }

  Future<Null> stop() {
    _stopLogger();
    return _stopApp();
  }

  Future<int> _run({
    bool traceStartup: false,
    bool benchmark: false,
    Completer<int> observatoryPortCompleter,
    String route
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

    Stopwatch startTime = new Stopwatch()..start();

    // TODO(devoncarew): We shouldn't have to do type checks here.
    if (device is AndroidDevice) {
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

    Map<String, dynamic> platformArgs;
    if (traceStartup != null)
      platformArgs = <String, dynamic>{ 'trace-startup': traceStartup };

    printStatus('Running ${getDisplayPath(_mainPath)} on ${device.name}...');

    _loggingSubscription = device.logReader.logLines.listen((String line) {
      if (!line.contains('Observatory listening on http') && !line.contains('Diagnostic server listening on http'))
        printStatus(line);
    });

    _result = await device.startApp(
      _package,
      debuggingOptions.buildMode,
      mainPath: _mainPath,
      debuggingOptions: debuggingOptions,
      platformArgs: platformArgs,
      route: route
    );

    if (!_result.started) {
      printError('Error running application on ${device.name}.');
      await _loggingSubscription.cancel();
      return 2;
    }

    startTime.stop();

    if (observatoryPortCompleter != null && _result.hasObservatory)
      observatoryPortCompleter.complete(_result.observatoryPort);

    // Connect to observatory.
    if (debuggingOptions.debuggingEnabled) {
      observatory = await Observatory.connect(_result.observatoryPort);
      printTrace('Connected to observatory port: ${_result.observatoryPort}.');

      observatory.populateIsolateInfo();
      observatory.onExtensionEvent.listen((Event event) {
        printTrace(event.toString());
      });
      observatory.onIsolateEvent.listen((Event event) {
        printTrace(event.toString());
      });

      if (benchmark)
        await observatory.waitFirstIsolate;

      // Listen for observatory connection close.
      observatory.done.whenComplete(() {
        if (!_exitCompleter.isCompleted) {
          printStatus('Application finished.');
          _exitCompleter.complete(0);
        }
      });
    }

    printStatus('Application running.');

    if (observatory != null && traceStartup) {
      printStatus('Downloading startup trace info...');

      await downloadStartupTrace(observatory);

      if (!_exitCompleter.isCompleted)
        _exitCompleter.complete(0);
    } else {
      if (usesTerminalUI) {
        if (!logger.quiet)
          _printHelp();

        terminal.singleCharMode = true;
        terminal.onCharInput.listen((String code) {
          String lower = code.toLowerCase();

          if (lower == 'h' || code == AnsiTerminal.KEY_F1) {
            // F1, help
            _printHelp();
          } else if (lower == 'r' || code == AnsiTerminal.KEY_F5) {
            if (device.supportsRestart) {
              // F5, restart
              restart();
            }
          } else if (lower == 'q' || code == AnsiTerminal.KEY_F10) {
            // F10, exit
            _stopApp();
          } else if (useDevFS && lower == 'd') {
            _updateDevFS();
          }
        });
      }

      ProcessSignal.SIGINT.watch().listen((ProcessSignal signal) {
        _resetTerminal();
        _stopLogger();
        _stopApp();
      });
      ProcessSignal.SIGTERM.watch().listen((ProcessSignal signal) {
        _resetTerminal();
        _stopLogger();
        _stopApp();
      });
    }

    if (benchmark) {
      await new Future<Null>.delayed(new Duration(seconds: 4));

      // Touch the file.
      File mainFile = new File(_mainPath);
      mainFile.writeAsBytesSync(mainFile.readAsBytesSync());

      Stopwatch restartTime = new Stopwatch()..start();
      bool restarted = await restart();
      restartTime.stop();
      writeRunBenchmarkFile(startTime, restarted ? restartTime : null);
      await new Future<Null>.delayed(new Duration(seconds: 2));
      stop();
    }

    return _exitCompleter.future.then((int exitCode) async {
      _resetTerminal();
      _stopLogger();
      return exitCode;
    });
  }

  DevFS devFS;

  Future<Null> _updateDevFS() async {
    if (devFS == null) {
      devFS = new DevFS(Directory.current, observatory);

      try {
        await devFS.init();
      } catch (error) {
        devFS = null;
        printError('Error initializing development client: $error');
        return null;
      }
    }

    // Send the root and lib directories.
    Directory directory = Directory.current;
    _sendFiles(directory, '', _dartFiles(directory.listSync()));

    directory = new Directory('lib');
    _sendFiles(directory, 'lib', _dartFiles(directory.listSync(recursive: true)));

    // Send the packages.
    if (FileSystemEntity.isFileSync(kPackagesFileName)) {
      PackageMap packageMap = new PackageMap(kPackagesFileName);

      for (String packageName in packageMap.map.keys) {
        Uri uri = packageMap.map[packageName];
        // Ignore self-references.
        if (uri.toString() == 'lib/')
          continue;
        Directory directory = new Directory.fromUri(uri);
        if (directory.existsSync()) {
          _sendFiles(
            directory,
            'packages/$packageName',
            _dartFiles(directory.listSync(recursive: true))
          );
        }
      }
    }

    try {
      await devFS.flush();
    } catch (error) {
      printError('Error sending sources to the client device: $error');
    }
  }

  void _sendFiles(Directory base, String prefix, List<File> files) {
    String basePath = base.path;

    for (File file in files) {
      String devPath = file.path.substring(basePath.length);
      if (devPath.startsWith('/'))
        devPath = devPath.substring(1);
      devFS.stageFile(prefix.isEmpty ? devPath : '$prefix/$devPath', file);
    }
  }

  List<File> _dartFiles(List<FileSystemEntity> entities) {
    return new List<File>.from(entities
      .where((FileSystemEntity entity) => entity is File && entity.path.endsWith('.dart')));
  }

  void _printHelp() {
    String restartText = device.supportsRestart ? ', "r" or F5 to restart the app,' : '';
    printStatus('Type "h" or F1 for help$restartText and "q", F10, or ctrl-c to quit.');

    if (useDevFS)
      printStatus('Type "d" to send modified project files to the the client\'s DevFS.');
  }

  void _stopLogger() {
    _loggingSubscription?.cancel();
  }

  void _resetTerminal() {
    if (usesTerminalUI)
      terminal.singleCharMode = false;
  }

  Future<Null> _stopApp() {
    if (observatory != null && !observatory.isClosed) {
      if (observatory.isolates.isNotEmpty) {
        observatory.flutterExit(observatory.firstIsolateId);
        return new Future<Null>.delayed(new Duration(milliseconds: 100));
      }
    }

    if (!_exitCompleter.isCompleted)
      _exitCompleter.complete(0);

    return new Future<Null>.value();
  }
}

String getMissingPackageHintForPlatform(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.android_arm:
    case TargetPlatform.android_x64:
      return 'Is your project missing an android/AndroidManifest.xml?\nConsider running "flutter create ." to create one.';
    case TargetPlatform.ios:
      return 'Is your project missing an ios/Info.plist?\nConsider running "flutter create ." to create one.';
    default:
      return null;
  }
}

void writeRunBenchmarkFile(Stopwatch startTime, [Stopwatch restartTime]) {
  final String benchmarkOut = 'refresh_benchmark.json';
  Map<String, dynamic> data = <String, dynamic>{
    'start': startTime.elapsedMilliseconds,
    'time': (restartTime ?? startTime).elapsedMilliseconds // time and restart are the same
  };
  if (restartTime != null)
    data['restart'] = restartTime.elapsedMilliseconds;

  new File(benchmarkOut).writeAsStringSync(toPrettyJson(data));
  printStatus('Run benchmark written to $benchmarkOut ($data).');
}

class DevFS {
  DevFS(this.directory, this.observatory) {
    fsName = path.basename(directory.path);
  }

  final Directory directory;
  final Observatory observatory;

  String fsName;
  Map<String, _DevFSFileEntry> entries = <String, _DevFSFileEntry>{};

  Future<dynamic> init() => observatory.createDevFS(fsName);

  void stageFile(String devPath, File file) {
    entries.putIfAbsent(devPath, () => new _DevFSFileEntry(devPath, file));
  }

  /// Flush any modified files to the devfs.
  Future<Null> flush() async {
    List<_DevFSFileEntry> toSend = entries.values
      .where((_DevFSFileEntry entry) => entry.isModified)
      .toList();

    for (_DevFSFileEntry entry in toSend) {
      printTrace('sending devfs://$fsName/${entry.devPath}');
      entry.updateLastModified();
    }

    Status status = logger.startProgress('Sending ${toSend.length} files...');

    if (toSend.isEmpty) {
      status.stop(showElapsedTime: true);
      return;
    }

    try {
      List<_DevFSFile> files = toSend.map((_DevFSFileEntry entry) {
        return new _DevFSFile('/${entry.devPath}', entry.file);
      }).toList();
      await observatory.writeDevFSFiles(fsName, files: files);
    } finally {
      status.stop(showElapsedTime: true);
    }
  }

  Future<List<String>> listDevFSFiles() => observatory.listDevFSFiles(fsName);
}

class _DevFSFileEntry {
  _DevFSFileEntry(this.devPath, this.file);

  final String devPath;
  final File file;

  DateTime lastModified;

  bool get isModified => lastModified == null || file.lastModifiedSync().isAfter(lastModified);

  void updateLastModified() {
    lastModified = file.lastModifiedSync();
  }
}

class _DevFSFile extends DevFSFile {
  _DevFSFile(String path, this.file) : super(path);

  final File file;

  @override
  List<int> getContents() => file.readAsBytesSync();
}

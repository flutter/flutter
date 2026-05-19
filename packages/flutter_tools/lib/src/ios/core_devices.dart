// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../base/template.dart';
import '../base/utils.dart';
import '../convert.dart';
import '../device.dart';
import '../macos/xcode.dart';
import '../project.dart';
import 'application_package.dart';
import 'lldb.dart';
import 'xcode_debug.dart';

/// Provides methods for launching and debugging apps on physical iOS CoreDevices.
///
/// CoreDevice is a device connectivity stack introduced in Xcode 15. Devices
/// with iOS 17 or greater are CoreDevices.
///
/// This class handles launching apps with different methods:
/// - [launchAppWithoutDebugger]: Uses `devicectl` to install and launch the app without a debugger.
/// - [launchAppWithLLDBDebugger]: Uses `devicectl` to install and launch the app, then attaches an LLDB debugger.
/// - [launchAppWithXcodeDebugger]: Uses Xcode automation to install, launch, and debug the app.
class IOSCoreDeviceLauncher {
  IOSCoreDeviceLauncher({
    required IOSCoreDeviceControl coreDeviceControl,
    required Logger logger,
    required XcodeDebug xcodeDebug,
    required FileSystem fileSystem,
    required ProcessUtils processUtils,
    @visibleForTesting LLDB? lldb,
  }) : _coreDeviceControl = coreDeviceControl,
       _logger = logger,
       _xcodeDebug = xcodeDebug,
       _fileSystem = fileSystem,
       _lldb = lldb ?? LLDB(logger: logger, processUtils: processUtils);

  final IOSCoreDeviceControl _coreDeviceControl;
  final Logger _logger;
  final XcodeDebug _xcodeDebug;
  final FileSystem _fileSystem;
  final LLDB _lldb;

  /// Contains a stream that devicectl sends logs to.
  final coreDeviceLogForwarder = IOSCoreDeviceLogForwarder();

  /// Contains a stream that LLDB sends logs to.
  final lldbLogForwarder = LLDBLogForwarder();

  /// Install and launch the app on the device with `devicectl` ([_coreDeviceControl])
  /// and do not attach a debugger. This is generally only used for release mode.
  Future<bool> launchAppWithoutDebugger({
    required String deviceId,
    required String bundlePath,
    required String bundleId,
    required List<String> launchArguments,
  }) async {
    // Install app to device
    final (bool installStatus, IOSCoreDeviceInstallResult? installResult) = await _coreDeviceControl
        .installApp(deviceId: deviceId, bundlePath: bundlePath);
    if (!installStatus) {
      return false;
    }

    // Launch app to device
    final IOSCoreDeviceLaunchResult? launchResult = await _coreDeviceControl.launchApp(
      deviceId: deviceId,
      bundleId: bundleId,
      launchArguments: launchArguments,
    );

    if (launchResult == null || launchResult.outcome != 'success') {
      return false;
    }

    return true;
  }

  /// Install and launch the app on the device with `devicectl` ([_coreDeviceControl])
  /// and then attach a LLDB debugger ([_lldb]).
  ///
  /// Requires Xcode 16+.
  Future<bool> launchAppWithLLDBDebugger({
    required String deviceId,
    required String bundlePath,
    required String bundleId,
    required List<String> launchArguments,
    required ShutdownHooks shutdownHooks,
  }) async {
    // Install app to device
    final (bool installStatus, IOSCoreDeviceInstallResult? installResult) = await _coreDeviceControl
        .installApp(deviceId: deviceId, bundlePath: bundlePath);
    final String? installationURL = installResult?.installationURL;
    if (!installStatus || installationURL == null) {
      return false;
    }

    // Launch app on device, but start it stopped so it will wait until the debugger is attached before starting.
    final bool launchResult = await _coreDeviceControl.launchAppAndStreamLogs(
      coreDeviceLogForwarder: coreDeviceLogForwarder,
      deviceId: deviceId,
      bundleId: bundleId,
      launchArguments: launchArguments,
      startStopped: true,
      shutdownHooks: shutdownHooks,
    );

    if (!launchResult) {
      return launchResult;
    }

    // Find the process that was launched using the installationURL.
    final List<IOSCoreDeviceRunningProcess> processes = await _coreDeviceControl
        .getRunningProcesses(deviceId: deviceId);
    final IOSCoreDeviceRunningProcess? launchedProcess = processes
        .where(
          (IOSCoreDeviceRunningProcess process) =>
              process.executable != null && process.executable!.contains(installationURL),
        )
        .firstOrNull;

    final int? processId = launchedProcess?.processIdentifier;
    if (launchedProcess == null || processId == null) {
      return false;
    }

    // Start LLDB and attach to the device process.
    final bool attachStatus = await _lldb.attachAndStart(
      deviceId: deviceId,
      appProcessId: processId,
      lldbLogForwarder: lldbLogForwarder,
    );

    // If it fails to attach with lldb, kill the launched process so it doesn't stay hanging.
    if (!attachStatus) {
      await stopApp(deviceId: deviceId, processId: processId);
      return false;
    }
    return attachStatus;
  }

  /// Install and launch the app on the device through Xcode using Mac Automation ([_xcodeDebug]).
  Future<bool> launchAppWithXcodeDebugger({
    required String deviceId,
    required DebuggingOptions debuggingOptions,
    required IOSApp package,
    required List<String> launchArguments,
    required TemplateRenderer templateRenderer,
    String? mainPath,
    @visibleForTesting Duration? discoveryTimeout,
  }) async {
    XcodeDebugProject? debugProject;

    if (package is PrebuiltIOSApp) {
      debugProject = await _xcodeDebug.createXcodeProjectWithCustomBundle(
        package.deviceBundlePath,
        templateRenderer: templateRenderer,
        verboseLogging: _logger.isVerbose,
      );
    } else if (package is BuildableIOSApp) {
      final IosProject project = package.project;
      final Directory bundle = _fileSystem.directory(package.deviceBundlePath);
      final Directory? xcodeWorkspace = project.xcodeWorkspace;
      if (xcodeWorkspace == null) {
        _logger.printTrace('Unable to get Xcode workspace.');
        return false;
      }
      final String? scheme = await project.schemeForBuildInfo(
        debuggingOptions.buildInfo,
        logger: _logger,
      );
      if (scheme == null) {
        return false;
      }
      _xcodeDebug.ensureXcodeDebuggerLaunchAction(project.xcodeProjectSchemeFile(scheme: scheme));

      // Before installing/launching/debugging with Xcode, update the build
      // settings to use a custom configuration build directory so Xcode
      // knows where to find the app bundle to launch.
      await _xcodeDebug.updateConfigurationBuildDir(
        project: project.parent,
        buildInfo: debuggingOptions.buildInfo,
        configurationBuildDir: bundle.parent.absolute.path,
      );

      debugProject = XcodeDebugProject(
        scheme: scheme,
        xcodeProject: project.xcodeProject,
        xcodeWorkspace: xcodeWorkspace,
        hostAppProjectName: project.hostAppProjectName,
        expectedConfigurationBuildDir: bundle.parent.absolute.path,
        verboseLogging: _logger.isVerbose,
      );
    } else {
      // This should not happen. Currently, only PrebuiltIOSApp and
      // BuildableIOSApp extend from IOSApp.
      _logger.printTrace('IOSApp type ${package.runtimeType} is not recognized.');
      return false;
    }

    // Core Devices (iOS 17 devices) are debugged through Xcode so don't
    // include these flags, which are used to check if the app was launched
    // via Flutter CLI and `ios-deploy`.
    launchArguments.removeWhere(
      (String arg) => arg == '--enable-checked-mode' || arg == '--verify-entry-points',
    );

    final bool debugSuccess = await _xcodeDebug.debugApp(
      project: debugProject,
      deviceId: deviceId,
      launchArguments: launchArguments,
    );

    return debugSuccess;
  }

  /// Stop the app depending on how it was launched.
  ///
  /// Returns `false` if the stop process fails or if there is no process to stop.
  Future<bool> stopApp({required String deviceId, int? processId}) async {
    if (_xcodeDebug.debugStarted) {
      return _xcodeDebug.exit();
    }

    int? processToStop;
    if (_lldb.isRunning) {
      processToStop = _lldb.appProcessId;
      // Exit the lldb process so it doesn't process any kill signals before
      // the app is killed by devicectl.
      _lldb.exit();
    } else {
      processToStop = processId;
    }

    // Then kill the attached launch process first so it doesn't process any additional logs when you terminate the app
    await Future.wait([coreDeviceLogForwarder.exit(), lldbLogForwarder.exit()]);

    if (processToStop == null) {
      return false;
    }

    // Killing the lldb process may not kill the app process. Kill it with
    // devicectl to ensure it stops.
    return _coreDeviceControl.terminateProcess(deviceId: deviceId, processId: processToStop);
  }
}

/// This class is used to forward logs from devicectl to any active listeners.
class IOSCoreDeviceLogForwarder {
  /// The `devicectl` process that launched the app and is streaming the logs.
  Process? launchProcess;

  final _streamController = StreamController<String>.broadcast();
  Stream<String> get logLines => _streamController.stream;

  /// Whether or not a `devicectl` launch process is running.
  bool get isRunning => launchProcess != null;

  void addLog(String log) {
    if (!_streamController.isClosed) {
      _streamController.add(log);
    }
  }

  /// Kill [launchProcess] if available and set it to null.
  Future<bool> exit() async {
    final bool success = (launchProcess == null) || launchProcess!.kill();
    launchProcess = null;
    if (_streamController.hasListener) {
      // Tell listeners the process died.
      await _streamController.close();
    }
    return success;
  }
}

/// A wrapper around the `devicectl` command line tool.
///
/// CoreDevice is a device connectivity stack introduced in Xcode 15. Devices
/// with iOS 17 or greater are CoreDevices.
///
/// `devicectl` (CoreDevice Device Control) is an Xcode CLI tool used for
/// interacting with CoreDevices.
class IOSCoreDeviceControl {
  IOSCoreDeviceControl({
    required Logger logger,
    required ProcessManager processManager,
    required Xcode xcode,
    required FileSystem fileSystem,
  }) : _logger = logger,
       _processUtils = ProcessUtils(logger: logger, processManager: processManager),
       _xcode = xcode,
       _fileSystem = fileSystem;

  final Logger _logger;
  final ProcessUtils _processUtils;
  final Xcode _xcode;
  final FileSystem _fileSystem;

  /// When the `--timeout` flag is used with `devicectl`, it must be at
  /// least 5 seconds. If lower than 5 seconds, `devicectl` will error and not
  /// run the command.
  static const _minimumTimeoutInSeconds = 5;

  /// A list of log patterns to ignore.
  static final _ignorePatterns = <Pattern>[
    // Ignore process logs that don't contain Flutter or user logs.
    // Example:
    //   * Ignore logs with prefix in brackets that doesn't match FML:
    //     2025-09-16 12:15:47.939171-0500 Runner[1230:133819] [UIKit App Config] ...
    //   * Ignore logs with timestamp/process prefix:
    //     2025-09-16 12:15:47.939171-0500 Runner[1230:133819] CoreText note: ...
    //   * Don't ignore FML logs:
    //     2025-09-16 12:05:54.162621-0500 Runner[1215:129795] [FATAL:flutter/runtime/service_protocol.cc(121)] ...
    //   * Don't ignore logs with no timestamp/process prefix:
    //     A log with no prefix (NSLog, print in Swift, and FlutterLogger)
    //   * Don't ignore flutter logs:
    //     2025-09-16 12:50:07.953318-0500 Runner[1279:149305] flutter: ...
    RegExp(
      r'^\S* \S* \S*\[[0-9:]*] ((?!(\[INFO|\[WARNING|\[ERROR|\[IMPORTANT|\[FATAL):))(?!(flutter:)).*',
    ),
    // Ignore iOS execution mode and potential error. This is not meaningful to the developer.
    // Example:
    //   * Dart execution mode: JIT
    //   * Dart execution mode: simulator
    RegExp(r'Dart execution mode: .*'),
    'Failed to execute code (error: EXC_BAD_ACCESS, debugger assist: not detected)',
  ];

  /// Executes `devicectl` command to get list of devices. The command will
  /// likely complete before [timeout] is reached. If [timeout] is reached,
  /// the command will be stopped as a failure.
  Future<List<Object?>> _listCoreDevices({
    Duration timeout = const Duration(seconds: _minimumTimeoutInSeconds),
    Completer<void>? cancelCompleter,
  }) async {
    if (!_xcode.isDevicectlInstalled) {
      _logger.printTrace('devicectl is not installed.');
      return const <Object?>[];
    }

    var validTimeout = timeout;
    if (timeout.inSeconds < _minimumTimeoutInSeconds) {
      _logger.printWarning(
        'Timeout of ${timeout.inSeconds} seconds is below the minimum timeout value '
        'for devicectl. Changing the timeout to the minimum value of $_minimumTimeoutInSeconds.',
      );
      validTimeout = const Duration(seconds: _minimumTimeoutInSeconds);
    }

    final Directory tempDirectory = _fileSystem.systemTempDirectory.createTempSync('core_devices.');
    final File output = tempDirectory.childFile('core_device_list.json');
    output.createSync();

    final command = <String>[
      ..._xcode.xcrunCommand(),
      'devicectl',
      'list',
      'devices',
      '--timeout',
      validTimeout.inSeconds.toString(),
      '--json-output',
      output.path,
    ];

    Process? process;
    try {
      process = await _processUtils.start(command);

      final Future<void> cancelFuture = cancelCompleter?.future ?? Completer<void>().future;
      final Future<dynamic> firstCompleted = Future.any<dynamic>(<Future<dynamic>>[
        process.exitCode,
        cancelFuture,
      ]);
      await firstCompleted;

      if (cancelCompleter?.isCompleted ?? false) {
        process.kill();
        return const <Object?>[];
      }

      final int exitCode = await process.exitCode;
      final String stdout = await utf8.decodeStream(process.stdout);
      final String stderr = await utf8.decodeStream(process.stderr);

      var isToolPossiblyShutdown = false;
      if (_fileSystem is ErrorHandlingFileSystem) {
        final FileSystem delegate = _fileSystem.fileSystem;
        if (delegate is LocalFileSystem) {
          isToolPossiblyShutdown = delegate.disposed;
        }
      }

      if (isToolPossiblyShutdown) {
        return const <Object?>[];
      }

      if (exitCode != 0) {
        _logger.printTrace('devicectl exited with a non-zero exit code: $exitCode');
        _logger.printTrace('devicectl stdout:\n$stdout');
        _logger.printTrace('devicectl stderr:\n$stderr');
        return const <Object?>[];
      }

      if (!output.existsSync()) {
        _logger.printTrace('After running the command ${command.join(' ')} the file');
        _logger.printTrace('${output.path} was expected to exist, but it did not.');
        _logger.printTrace('The process exited with code $exitCode and');
        _logger.printTrace('Stdout:\n\n${stdout.trim()}\n');
        _logger.printTrace('Stderr:\n\n${stderr.trim()}');
        throw StateError('Expected the file ${output.path} to exist but it did not');
      }

      final String stringOutput = output.readAsStringSync();
      _logger.printTrace(stringOutput);

      final Object? decodeResult = (json.decode(stringOutput) as Map<String, Object?>)['result'];
      if (decodeResult is Map<String, Object?>) {
        final Object? decodeDevices = decodeResult['devices'];
        if (decodeDevices is List<Object?>) {
          return decodeDevices;
        }
      }
      _logger.printTrace('devicectl returned unexpected JSON response: $stringOutput');
      return const <Object?>[];
    } on ProcessException catch (e) {
      _logger.printTrace('Error executing devicectl: $e');
      return const <Object?>[];
    } on FileSystemException catch (e) {
      _logger.printTrace('Error reading devicectl output: $e');
      return const <Object?>[];
    } on FormatException {
      _logger.printTrace('devicectl returned non-JSON response.');
      return const <Object?>[];
    } finally {
      process?.kill();
      ErrorHandlingFileSystem.deleteIfExists(tempDirectory, recursive: true);
    }
  }

  Future<List<IOSCoreDevice>> getCoreDevices({
    Duration timeout = const Duration(seconds: _minimumTimeoutInSeconds),
    Completer<void>? cancelCompleter,
  }) async {
    final List<Object?> coreDeviceObjects = await _listCoreDevices(
      timeout: timeout,
      cancelCompleter: cancelCompleter,
    );

    return <IOSCoreDevice>[
      for (final Object? deviceObject in coreDeviceObjects)
        if (deviceObject is Map<String, Object?>)
          IOSCoreDevice.fromBetaJson(deviceObject, logger: _logger),
    ];
  }

  /// Executes `devicectl` command to get list of apps installed on the device.
  /// If [bundleId] is provided, it will only return apps matching the bundle
  /// identifier exactly.
  Future<List<Object?>> _listInstalledApps({required String deviceId, String? bundleId}) async {
    if (!_xcode.isDevicectlInstalled) {
      _logger.printError('devicectl is not installed.');
      return <Object?>[];
    }

    final Directory tempDirectory = _fileSystem.systemTempDirectory.createTempSync('core_devices.');
    final File output = tempDirectory.childFile('core_device_app_list.json');
    output.createSync();

    final command = <String>[
      ..._xcode.xcrunCommand(),
      'devicectl',
      'device',
      'info',
      'apps',
      '--device',
      deviceId,
      if (bundleId != null) '--bundle-id',
      bundleId!,
      '--json-output',
      output.path,
    ];

    try {
      await _processUtils.run(command, throwOnError: true);

      final String stringOutput = output.readAsStringSync();

      try {
        final Object? decodeResult = (json.decode(stringOutput) as Map<String, Object?>)['result'];
        if (decodeResult is Map<String, Object?>) {
          final Object? decodeApps = decodeResult['apps'];
          if (decodeApps is List<Object?>) {
            return decodeApps;
          }
        }
        _logger.printError('devicectl returned unexpected JSON response: $stringOutput');
        return <Object?>[];
      } on FormatException {
        // We failed to parse the devicectl output, or it returned junk.
        _logger.printError('devicectl returned non-JSON response: $stringOutput');
        return <Object?>[];
      }
    } on ProcessException catch (err) {
      _logger.printError('Error executing devicectl: $err');
      return <Object?>[];
    } finally {
      tempDirectory.deleteSync(recursive: true);
    }
  }

  @visibleForTesting
  Future<List<IOSCoreDeviceInstalledApp>> getInstalledApps({
    required String deviceId,
    String? bundleId,
  }) async {
    final List<Object?> appsData = await _listInstalledApps(deviceId: deviceId, bundleId: bundleId);
    return <IOSCoreDeviceInstalledApp>[
      for (final Object? appObject in appsData)
        if (appObject is Map<String, Object?>) IOSCoreDeviceInstalledApp.fromBetaJson(appObject),
    ];
  }

  Future<bool> isAppInstalled({required String deviceId, required String bundleId}) async {
    final List<IOSCoreDeviceInstalledApp> apps = await getInstalledApps(
      deviceId: deviceId,
      bundleId: bundleId,
    );
    if (apps.isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<(bool, IOSCoreDeviceInstallResult?)> installApp({
    required String deviceId,
    required String bundlePath,
  }) async {
    if (!_xcode.isDevicectlInstalled) {
      _logger.printTrace('devicectl is not installed.');
      return (false, null);
    }

    final Directory tempDirectory = _fileSystem.systemTempDirectory.createTempSync('core_devices.');
    final File output = tempDirectory.childFile('install_results.json');
    output.createSync();

    final command = <String>[
      ..._xcode.xcrunCommand(),
      'devicectl',
      'device',
      'install',
      'app',
      '--device',
      deviceId,
      bundlePath,
      '--json-output',
      output.path,
    ];

    try {
      await _processUtils.run(command, throwOnError: true);
      final String stringOutput = output.readAsStringSync();

      try {
        final Object? decodedJson = json.decode(stringOutput);
        if (decodedJson is Map<String, Object?>) {
          final result = IOSCoreDeviceInstallResult.fromJson(decodedJson);
          if (result.outcome != null) {
            final success = result.outcome == 'success';
            return (success, result);
          }
        }
        _logger.printTrace('devicectl returned unexpected JSON response: $stringOutput');
        return (false, null);
      } on FormatException {
        // We failed to parse the devicectl output, or it returned junk.
        _logger.printTrace('devicectl returned non-JSON response: $stringOutput');
        return (false, null);
      }
    } on ProcessException catch (err) {
      _logger.printTrace('Error executing devicectl: $err');
      return (false, null);
    } finally {
      tempDirectory.deleteSync(recursive: true);
    }
  }

  /// Uninstalls the app from the device. Will succeed even if the app is not
  /// currently installed on the device.
  Future<bool> uninstallApp({required String deviceId, required String bundleId}) async {
    if (!_xcode.isDevicectlInstalled) {
      _logger.printError('devicectl is not installed.');
      return false;
    }

    final Directory tempDirectory = _fileSystem.systemTempDirectory.createTempSync('core_devices.');
    final File output = tempDirectory.childFile('uninstall_results.json');
    output.createSync();

    final command = <String>[
      ..._xcode.xcrunCommand(),
      'devicectl',
      'device',
      'uninstall',
      'app',
      '--device',
      deviceId,
      bundleId,
      '--json-output',
      output.path,
    ];

    try {
      await _processUtils.run(command, throwOnError: true);
      final String stringOutput = output.readAsStringSync();

      try {
        final Object? decodeResult = (json.decode(stringOutput) as Map<String, Object?>)['info'];
        if (decodeResult is Map<String, Object?> && decodeResult['outcome'] == 'success') {
          return true;
        }
        _logger.printError('devicectl returned unexpected JSON response: $stringOutput');
        return false;
      } on FormatException {
        // We failed to parse the devicectl output, or it returned junk.
        _logger.printError('devicectl returned non-JSON response: $stringOutput');
        return false;
      }
    } on ProcessException catch (err) {
      _logger.printError('Error executing devicectl: $err');
      return false;
    } finally {
      tempDirectory.deleteSync(recursive: true);
    }
  }

  /// Launches the app on the device.
  ///
  /// If [startStopped] is true, the app will be launched and paused, waiting
  /// for a debugger to attach.
  ///
  /// If [attachToConsole] is true, attaches the application to the console and waits for the app
  /// to terminate.
  ///
  /// If [interactiveMode] is true, runs the process in interactive mode (via script) to convince
  /// devicectl it has a terminal attached in order to redirect stdout.
  List<String> _launchAppCommand({
    required String deviceId,
    required String bundleId,
    List<String> launchArguments = const <String>[],
    bool startStopped = false,
    bool attachToConsole = false,
    File? outputFile,
    bool interactiveMode = false,
  }) {
    return <String>[
      if (interactiveMode) ...<String>['script', '-t', '0', '/dev/null'],
      ..._xcode.xcrunCommand(),
      'devicectl',
      'device',
      'process',
      'launch',
      '--device',
      deviceId,
      if (startStopped) '--start-stopped',
      if (attachToConsole) ...<String>[
        '--console',
        '--environment-variables',
        // OS_ACTIVITY_DT_MODE needs to be set to get NSLog and os_log output
        // See https://github.com/llvm/llvm-project/blob/19b43e1757b4fd3d0f188cf8a08e9febb0dbec2f/lldb/source/Plugins/Platform/MacOSX/PlatformDarwin.cpp#L1227-L1233
        '{"OS_ACTIVITY_DT_MODE": "enable"}',
      ],
      if (outputFile != null) ...<String>['--json-output', outputFile.path],
      bundleId,
      if (launchArguments.isNotEmpty) ...launchArguments,
    ];
  }

  /// Launches the app on the device.
  ///
  /// If [startStopped] is true, the app will be launched and paused, waiting
  /// for a debugger to attach.
  Future<IOSCoreDeviceLaunchResult?> launchApp({
    required String deviceId,
    required String bundleId,
    List<String> launchArguments = const <String>[],
    bool startStopped = false,
  }) async {
    if (!_xcode.isDevicectlInstalled) {
      _logger.printTrace('devicectl is not installed.');
      return null;
    }

    final Directory tempDirectory = _fileSystem.systemTempDirectory.createTempSync('core_devices.');
    final File output = tempDirectory.childFile('launch_results.json')..createSync();

    final List<String> command = _launchAppCommand(
      bundleId: bundleId,
      deviceId: deviceId,
      launchArguments: launchArguments,
      startStopped: startStopped,
      outputFile: output,
    );

    try {
      await _processUtils.run(command, throwOnError: true);
      final String stringOutput = output.readAsStringSync();

      try {
        final result = IOSCoreDeviceLaunchResult.fromJson(
          json.decode(stringOutput) as Map<String, Object?>,
        );
        if (result.outcome == null) {
          _logger.printTrace('devicectl returned unexpected JSON response: $stringOutput');
          return null;
        }
        return result;
      } on FormatException {
        // We failed to parse the devicectl output, or it returned junk.
        _logger.printTrace('devicectl returned non-JSON response: $stringOutput');
        return null;
      }
    } on ProcessException catch (err) {
      _logger.printTrace('Error executing devicectl: $err');
      return null;
    } finally {
      tempDirectory.deleteSync(recursive: true);
    }
  }

  /// Launches the app on the device, streams the logs, and stays attached until the app terminates.
  ///
  /// If [startStopped] is true, the app will be launched and paused, waiting
  /// for a debugger to attach.
  Future<bool> launchAppAndStreamLogs({
    required IOSCoreDeviceLogForwarder coreDeviceLogForwarder,
    required String deviceId,
    required String bundleId,
    required ShutdownHooks shutdownHooks,
    List<String> launchArguments = const <String>[],
    bool startStopped = false,
  }) async {
    if (!_xcode.isDevicectlInstalled) {
      _logger.printTrace('devicectl is not installed.');
      return false;
    }
    if (coreDeviceLogForwarder.isRunning) {
      _logger.printTrace(
        'A launch process is already running. It must be stopped before starting a new one.',
      );
      return false;
    }

    final launchCompleter = Completer<bool>();
    final List<String> command = _launchAppCommand(
      bundleId: bundleId,
      deviceId: deviceId,
      launchArguments: launchArguments,
      startStopped: startStopped,
      attachToConsole: true,
      interactiveMode: true,
    );

    try {
      final Process launchProcess = await _processUtils.start(command);
      coreDeviceLogForwarder.launchProcess = launchProcess;

      final StreamSubscription<String> stdoutSubscription = launchProcess.stdout
          .transform(utf8LineDecoder)
          .listen((String line) {
            if (line.trim().isEmpty) {
              return;
            }
            if (launchCompleter.isCompleted && !_ignoreLog(line)) {
              coreDeviceLogForwarder.addLog(line);
            } else {
              _logger.printTrace(line);
            }

            if (line.contains('Waiting for the application to terminate')) {
              launchCompleter.complete(true);
            }
          });

      final StreamSubscription<String> stderrSubscription = launchProcess.stderr
          .transform(utf8LineDecoder)
          .listen((String line) {
            if (line.trim().isEmpty) {
              return;
            }
            if (launchCompleter.isCompleted && !_ignoreLog(line)) {
              coreDeviceLogForwarder.addLog(line);
            } else {
              _logger.printTrace(line);
            }
          });

      unawaited(
        launchProcess.exitCode
            .then((int status) async {
              _logger.printTrace('lldb exited with code $status');
              await stdoutSubscription.cancel();
              await stderrSubscription.cancel();
            })
            .whenComplete(() async {
              await coreDeviceLogForwarder.exit();
              if (!launchCompleter.isCompleted) {
                launchCompleter.complete(false);
              }
            }),
      );

      // devicectl is running in an interactive shell.
      // Signal script child jobs to exit and exit the shell.
      // See https://linux.die.net/Bash-Beginners-Guide/sect_12_01.html#sect_12_01_01_02.
      shutdownHooks.addShutdownHook(() => launchProcess.kill());
      return launchCompleter.future;
    } on ProcessException catch (err) {
      _logger.printTrace('Error executing devicectl: $err');
      return false;
    }
  }

  bool _ignoreLog(String log) {
    return _ignorePatterns.any((Pattern pattern) => log.contains(pattern));
  }

  /// Terminate the [processId] on the device using `devicectl`.
  Future<bool> terminateProcess({required String deviceId, required int processId}) async {
    if (!_xcode.isDevicectlInstalled) {
      _logger.printTrace('devicectl is not installed.');
      return false;
    }

    final Directory tempDirectory = _fileSystem.systemTempDirectory.createTempSync('core_devices.');
    final File output = tempDirectory.childFile('terminate_results.json');
    output.createSync();

    final command = <String>[
      ..._xcode.xcrunCommand(),
      'devicectl',
      'device',
      'process',
      'terminate',
      '--device',
      deviceId,
      '--pid',
      processId.toString(),
      '--kill',
      '--json-output',
      output.path,
    ];

    try {
      await _processUtils.run(command, throwOnError: true);
      final String stringOutput = output.readAsStringSync();

      try {
        final Object? decodeResult = (json.decode(stringOutput) as Map<String, Object?>)['info'];
        if (decodeResult is Map<String, Object?> && decodeResult['outcome'] == 'success') {
          return true;
        }
        _logger.printTrace('devicectl returned unexpected JSON response: $stringOutput');
        return false;
      } on FormatException {
        // We failed to parse the devicectl output, or it returned junk.
        _logger.printTrace('devicectl returned non-JSON response: $stringOutput');
        return false;
      } on TypeError {
        _logger.printTrace('devicectl returned unexpected JSON response: $stringOutput');
        return false;
      }
    } on ProcessException catch (err) {
      _logger.printTrace('Error executing devicectl: $err');
      return false;
    } finally {
      tempDirectory.deleteSync(recursive: true);
    }
  }

  Future<List<Object?>> _listRunningProcesses({required String deviceId}) async {
    if (!_xcode.isDevicectlInstalled) {
      _logger.printTrace('devicectl is not installed.');
      return <Object?>[];
    }

    final Directory tempDirectory = _fileSystem.systemTempDirectory.createTempSync('core_devices.');
    final File output = tempDirectory.childFile('core_device_process_list.json')..createSync();

    final command = <String>[
      ..._xcode.xcrunCommand(),
      'devicectl',
      'device',
      'info',
      'processes',
      '--device',
      deviceId,
      '--json-output',
      output.path,
    ];

    try {
      await _processUtils.run(command, throwOnError: true);

      final String stringOutput = output.readAsStringSync();

      try {
        if (json.decode(stringOutput) case <String, Object?>{
          'result': <String, Object?>{'runningProcesses': final List<Object?> decodedProcesses},
        }) {
          return decodedProcesses;
        }
        _logger.printTrace('devicectl returned unexpected JSON response: $stringOutput');
        return <Object?>[];
      } on FormatException {
        // We failed to parse the devicectl output, or it returned junk.
        _logger.printTrace('devicectl returned non-JSON response: $stringOutput');
        return <Object?>[];
      }
    } on ProcessException catch (err) {
      _logger.printTrace('Error executing devicectl: $err');
      return <Object?>[];
    } on FileSystemException catch (err) {
      _logger.printTrace('Error reading output file: $err');
      return <Object?>[];
    } finally {
      tempDirectory.deleteSync(recursive: true);
    }
  }

  Future<List<IOSCoreDeviceRunningProcess>> getRunningProcesses({required String deviceId}) async {
    final List<Object?> processesData = await _listRunningProcesses(deviceId: deviceId);
    return <IOSCoreDeviceRunningProcess>[
      for (final Object? processObject in processesData)
        if (processObject is Map<String, Object?>)
          IOSCoreDeviceRunningProcess.fromJson(processObject),
    ];
  }
}

class IOSCoreDevice {
  IOSCoreDevice._({
    required this.capabilities,
    required this.connectionProperties,
    required this.deviceProperties,
    required this.hardwareProperties,
    required this.coreDeviceIdentifier,
    required this.visibilityClass,
  });

  /// Parse JSON from `devicectl list devices --json-output` while it's in beta preview mode.
  ///
  /// Example:
  /// {
  ///   "capabilities" : [
  ///   ],
  ///   "connectionProperties" : {
  ///   },
  ///   "deviceProperties" : {
  ///   },
  ///   "hardwareProperties" : {
  ///   },
  ///   "identifier" : "123456BB5-AEDE-7A22-B890-1234567890DD",
  ///   "visibilityClass" : "default"
  /// }
  factory IOSCoreDevice.fromBetaJson(Map<String, Object?> data, {required Logger logger}) {
    final capabilitiesList = <_IOSCoreDeviceCapability>[
      if (data case {'capabilities': final List<Object?> capabilitiesData})
        for (final Object? capabilityData in capabilitiesData)
          if (capabilityData != null && capabilityData is Map<String, Object?>)
            _IOSCoreDeviceCapability.fromBetaJson(capabilityData),
    ];

    _IOSCoreDeviceConnectionProperties? connectionProperties;
    if (data case {'connectionProperties': final Map<String, Object?> connectionPropertiesData}) {
      connectionProperties = _IOSCoreDeviceConnectionProperties.fromBetaJson(
        connectionPropertiesData,
        logger: logger,
      );
    }

    IOSCoreDeviceProperties? deviceProperties;
    if (data case {'deviceProperties': final Map<String, Object?> devicePropertiesData}) {
      deviceProperties = IOSCoreDeviceProperties.fromBetaJson(devicePropertiesData);
    }

    _IOSCoreDeviceHardwareProperties? hardwareProperties;
    if (data case {'hardwareProperties': final Map<String, Object?> hardwarePropertiesData}) {
      hardwareProperties = _IOSCoreDeviceHardwareProperties.fromBetaJson(
        hardwarePropertiesData,
        logger: logger,
      );
    }

    return IOSCoreDevice._(
      capabilities: capabilitiesList,
      connectionProperties: connectionProperties,
      deviceProperties: deviceProperties,
      hardwareProperties: hardwareProperties,
      coreDeviceIdentifier: data['identifier']?.toString(),
      visibilityClass: data['visibilityClass']?.toString(),
    );
  }

  String? get udid => hardwareProperties?.udid;

  DeviceConnectionInterface? get connectionInterface {
    return switch (connectionProperties?.transportType?.toLowerCase()) {
      'localnetwork' => DeviceConnectionInterface.wireless,
      'wired' => DeviceConnectionInterface.attached,
      _ => null,
    };
  }

  @visibleForTesting
  final List<_IOSCoreDeviceCapability> capabilities;

  @visibleForTesting
  final _IOSCoreDeviceConnectionProperties? connectionProperties;

  final IOSCoreDeviceProperties? deviceProperties;

  @visibleForTesting
  final _IOSCoreDeviceHardwareProperties? hardwareProperties;

  final String? coreDeviceIdentifier;
  final String? visibilityClass;
}

class _IOSCoreDeviceCapability {
  _IOSCoreDeviceCapability._({required this.featureIdentifier, required this.name});

  /// Parse `capabilities` section of JSON from `devicectl list devices --json-output`
  /// while it's in beta preview mode.
  ///
  /// Example:
  /// "capabilities" : [
  ///   {
  ///     "featureIdentifier" : "com.apple.coredevice.feature.spawnexecutable",
  ///     "name" : "Spawn Executable"
  ///   },
  ///   {
  ///     "featureIdentifier" : "com.apple.coredevice.feature.launchapplication",
  ///     "name" : "Launch Application"
  ///   }
  /// ]
  factory _IOSCoreDeviceCapability.fromBetaJson(Map<String, Object?> data) {
    return _IOSCoreDeviceCapability._(
      featureIdentifier: data['featureIdentifier']?.toString(),
      name: data['name']?.toString(),
    );
  }

  final String? featureIdentifier;
  final String? name;
}

class _IOSCoreDeviceConnectionProperties {
  _IOSCoreDeviceConnectionProperties._({
    required this.authenticationType,
    required this.isMobileDeviceOnly,
    required this.lastConnectionDate,
    required this.localHostnames,
    required this.pairingState,
    required this.potentialHostnames,
    required this.transportType,
    required this.tunnelIPAddress,
    required this.tunnelState,
    required this.tunnelTransportProtocol,
  });

  /// Parse `connectionProperties` section of JSON from `devicectl list devices --json-output`
  /// while it's in beta preview mode.
  ///
  /// Example:
  /// "connectionProperties" : {
  ///   "authenticationType" : "manualPairing",
  ///   "isMobileDeviceOnly" : false,
  ///   "lastConnectionDate" : "2023-06-15T15:29:00.082Z",
  ///   "localHostnames" : [
  ///     "iPadName.coredevice.local",
  ///     "00001234-0001234A3C03401E.coredevice.local",
  ///     "12345BB5-AEDE-4A22-B653-6037262550DD.coredevice.local"
  ///   ],
  ///   "pairingState" : "paired",
  ///   "potentialHostnames" : [
  ///     "00001234-0001234A3C03401E.coredevice.local",
  ///     "12345BB5-AEDE-4A22-B653-6037262550DD.coredevice.local"
  ///   ],
  ///   "transportType" : "wired",
  ///   "tunnelIPAddress" : "fdf1:23c4:cd56::1",
  ///   "tunnelState" : "connected",
  ///   "tunnelTransportProtocol" : "tcp"
  /// }
  factory _IOSCoreDeviceConnectionProperties.fromBetaJson(
    Map<String, Object?> data, {
    required Logger logger,
  }) {
    List<String>? localHostnames;
    if (data case {'localHostnames': final List<Object?> values}) {
      try {
        localHostnames = List<String>.from(values);
      } on TypeError {
        logger.printTrace('Error parsing localHostnames value: $values');
      }
    }

    List<String>? potentialHostnames;
    if (data case {'potentialHostnames': final List<Object?> values}) {
      try {
        potentialHostnames = List<String>.from(values);
      } on TypeError {
        logger.printTrace('Error parsing potentialHostnames value: $values');
      }
    }
    return _IOSCoreDeviceConnectionProperties._(
      authenticationType: data['authenticationType']?.toString(),
      isMobileDeviceOnly: data['isMobileDeviceOnly'] is bool?
          ? data['isMobileDeviceOnly'] as bool?
          : null,
      lastConnectionDate: data['lastConnectionDate']?.toString(),
      localHostnames: localHostnames,
      pairingState: data['pairingState']?.toString(),
      potentialHostnames: potentialHostnames,
      transportType: data['transportType']?.toString(),
      tunnelIPAddress: data['tunnelIPAddress']?.toString(),
      tunnelState: data['tunnelState']?.toString(),
      tunnelTransportProtocol: data['tunnelTransportProtocol']?.toString(),
    );
  }

  final String? authenticationType;
  final bool? isMobileDeviceOnly;
  final String? lastConnectionDate;
  final List<String>? localHostnames;
  final String? pairingState;
  final List<String>? potentialHostnames;
  final String? transportType;
  final String? tunnelIPAddress;
  final String? tunnelState;
  final String? tunnelTransportProtocol;
}

@visibleForTesting
class IOSCoreDeviceProperties {
  IOSCoreDeviceProperties._({
    required this.bootedFromSnapshot,
    required this.bootedSnapshotName,
    required this.bootState,
    required this.ddiServicesAvailable,
    required this.developerModeStatus,
    required this.hasInternalOSBuild,
    required this.name,
    required this.osBuildUpdate,
    required this.osVersionNumber,
    required this.rootFileSystemIsWritable,
    required this.screenViewingURL,
  });

  /// Parse `deviceProperties` section of JSON from `devicectl list devices --json-output`
  /// while it's in beta preview mode.
  ///
  /// Example:
  /// "deviceProperties" : {
  ///   "bootedFromSnapshot" : true,
  ///   "bootedSnapshotName" : "com.apple.os.update-B5336980824124F599FD39FE91016493A74331B09F475250BB010B276FE2439E3DE3537349A3A957D3FF2A4B623B4ECC",
  ///   "bootState" : "booted",
  ///   "ddiServicesAvailable" : true,
  ///   "developerModeStatus" : "enabled",
  ///   "hasInternalOSBuild" : false,
  ///   "name" : "iPadName",
  ///   "osBuildUpdate" : "21A5248v",
  ///   "osVersionNumber" : "17.0",
  ///   "rootFileSystemIsWritable" : false,
  ///   "screenViewingURL" : "coredevice-devices:/viewDeviceByUUID?uuid=123456BB5-AEDE-7A22-B890-1234567890DD"
  /// }
  factory IOSCoreDeviceProperties.fromBetaJson(Map<String, Object?> data) {
    return IOSCoreDeviceProperties._(
      bootedFromSnapshot: data['bootedFromSnapshot'] is bool?
          ? data['bootedFromSnapshot'] as bool?
          : null,
      bootedSnapshotName: data['bootedSnapshotName']?.toString(),
      bootState: data['bootState']?.toString(),
      ddiServicesAvailable: data['ddiServicesAvailable'] is bool?
          ? data['ddiServicesAvailable'] as bool?
          : null,
      developerModeStatus: data['developerModeStatus']?.toString(),
      hasInternalOSBuild: data['hasInternalOSBuild'] is bool?
          ? data['hasInternalOSBuild'] as bool?
          : null,
      name: data['name']?.toString(),
      osBuildUpdate: data['osBuildUpdate']?.toString(),
      osVersionNumber: data['osVersionNumber']?.toString(),
      rootFileSystemIsWritable: data['rootFileSystemIsWritable'] is bool?
          ? data['rootFileSystemIsWritable'] as bool?
          : null,
      screenViewingURL: data['screenViewingURL']?.toString(),
    );
  }

  final bool? bootedFromSnapshot;
  final String? bootedSnapshotName;
  final String? bootState;
  final bool? ddiServicesAvailable;
  final String? developerModeStatus;
  final bool? hasInternalOSBuild;
  final String? name;
  final String? osBuildUpdate;
  final String? osVersionNumber;
  final bool? rootFileSystemIsWritable;
  final String? screenViewingURL;
}

class _IOSCoreDeviceHardwareProperties {
  _IOSCoreDeviceHardwareProperties._({
    required this.cpuType,
    required this.deviceType,
    required this.ecid,
    required this.hardwareModel,
    required this.internalStorageCapacity,
    required this.marketingName,
    required this.platform,
    required this.productType,
    required this.serialNumber,
    required this.supportedCPUTypes,
    required this.supportedDeviceFamilies,
    required this.thinningProductType,
    required this.udid,
  });

  /// Parse `hardwareProperties` section of JSON from `devicectl list devices --json-output`
  /// while it's in beta preview mode.
  ///
  /// Example:
  /// "hardwareProperties" : {
  ///   "cpuType" : {
  ///     "name" : "arm64e",
  ///     "subType" : 2,
  ///     "type" : 16777228
  ///   },
  ///   "deviceType" : "iPad",
  ///   "ecid" : 12345678903408542,
  ///   "hardwareModel" : "J617AP",
  ///   "internalStorageCapacity" : 128000000000,
  ///   "marketingName" : "iPad Pro (11-inch) (4th generation)\"",
  ///   "platform" : "iOS",
  ///   "productType" : "iPad14,3",
  ///   "serialNumber" : "HC123DHCQV",
  ///   "supportedCPUTypes" : [
  ///     {
  ///       "name" : "arm64e",
  ///       "subType" : 2,
  ///       "type" : 16777228
  ///     },
  ///     {
  ///       "name" : "arm64",
  ///       "subType" : 0,
  ///       "type" : 16777228
  ///     }
  ///   ],
  ///   "supportedDeviceFamilies" : [
  ///     1,
  ///     2
  ///   ],
  ///   "thinningProductType" : "iPad14,3-A",
  ///   "udid" : "00001234-0001234A3C03401E"
  /// }
  factory _IOSCoreDeviceHardwareProperties.fromBetaJson(
    Map<String, Object?> data, {
    required Logger logger,
  }) {
    _IOSCoreDeviceCPUType? cpuType;
    if (data case {'cpuType': final Map<String, Object?> betaJson}) {
      cpuType = _IOSCoreDeviceCPUType.fromBetaJson(betaJson);
    }

    List<_IOSCoreDeviceCPUType>? supportedCPUTypes;
    if (data case {'supportedCPUTypes': final List<Object?> values}) {
      supportedCPUTypes = <_IOSCoreDeviceCPUType>[
        for (final Object? cpuTypeData in values)
          if (cpuTypeData is Map<String, Object?>) _IOSCoreDeviceCPUType.fromBetaJson(cpuTypeData),
      ];
    }

    List<int>? supportedDeviceFamilies;
    if (data case {'supportedDeviceFamilies': final List<Object?> values}) {
      try {
        supportedDeviceFamilies = List<int>.from(values);
      } on TypeError {
        logger.printTrace('Error parsing supportedDeviceFamilies value: $values');
      }
    }

    return _IOSCoreDeviceHardwareProperties._(
      cpuType: cpuType,
      deviceType: data['deviceType']?.toString(),
      ecid: data['ecid'] is int? ? data['ecid'] as int? : null,
      hardwareModel: data['hardwareModel']?.toString(),
      internalStorageCapacity: data['internalStorageCapacity'] is int?
          ? data['internalStorageCapacity'] as int?
          : null,
      marketingName: data['marketingName']?.toString(),
      platform: data['platform']?.toString(),
      productType: data['productType']?.toString(),
      serialNumber: data['serialNumber']?.toString(),
      supportedCPUTypes: supportedCPUTypes,
      supportedDeviceFamilies: supportedDeviceFamilies,
      thinningProductType: data['thinningProductType']?.toString(),
      udid: data['udid']?.toString(),
    );
  }

  final _IOSCoreDeviceCPUType? cpuType;
  final String? deviceType;
  final int? ecid;
  final String? hardwareModel;
  final int? internalStorageCapacity;
  final String? marketingName;
  final String? platform;
  final String? productType;
  final String? serialNumber;
  final List<_IOSCoreDeviceCPUType>? supportedCPUTypes;
  final List<int>? supportedDeviceFamilies;
  final String? thinningProductType;
  final String? udid;
}

class _IOSCoreDeviceCPUType {
  _IOSCoreDeviceCPUType._({this.name, this.subType, this.cpuType});

  /// Parse `hardwareProperties.cpuType` and `hardwareProperties.supportedCPUTypes`
  /// sections of JSON from `devicectl list devices --json-output` while it's in beta preview mode.
  ///
  /// Example:
  /// "cpuType" : {
  ///   "name" : "arm64e",
  ///   "subType" : 2,
  ///   "type" : 16777228
  /// }
  factory _IOSCoreDeviceCPUType.fromBetaJson(Map<String, Object?> data) {
    return _IOSCoreDeviceCPUType._(
      name: data['name']?.toString(),
      subType: data['subType'] is int? ? data['subType'] as int? : null,
      cpuType: data['type'] is int? ? data['type'] as int? : null,
    );
  }

  final String? name;
  final int? subType;
  final int? cpuType;
}

@visibleForTesting
class IOSCoreDeviceInstalledApp {
  IOSCoreDeviceInstalledApp._({
    required this.appClip,
    required this.builtByDeveloper,
    required this.bundleIdentifier,
    required this.bundleVersion,
    required this.defaultApp,
    required this.hidden,
    required this.internalApp,
    required this.name,
    required this.removable,
    required this.url,
    required this.version,
  });

  /// Parse JSON from `devicectl device info apps --json-output` while it's in
  /// beta preview mode.
  ///
  /// Example:
  /// {
  ///   "appClip" : false,
  ///   "builtByDeveloper" : true,
  ///   "bundleIdentifier" : "com.example.flutterApp",
  ///   "bundleVersion" : "1",
  ///   "defaultApp" : false,
  ///   "hidden" : false,
  ///   "internalApp" : false,
  ///   "name" : "Flutter App",
  ///   "removable" : true,
  ///   "url" : "file:///private/var/containers/Bundle/Application/12345E6A-7F89-0C12-345E-F6A7E890CFF1/Runner.app/",
  ///   "version" : "1.0.0"
  /// }
  factory IOSCoreDeviceInstalledApp.fromBetaJson(Map<String, Object?> data) {
    return IOSCoreDeviceInstalledApp._(
      appClip: data['appClip'] is bool? ? data['appClip'] as bool? : null,
      builtByDeveloper: data['builtByDeveloper'] is bool?
          ? data['builtByDeveloper'] as bool?
          : null,
      bundleIdentifier: data['bundleIdentifier']?.toString(),
      bundleVersion: data['bundleVersion']?.toString(),
      defaultApp: data['defaultApp'] is bool? ? data['defaultApp'] as bool? : null,
      hidden: data['hidden'] is bool? ? data['hidden'] as bool? : null,
      internalApp: data['internalApp'] is bool? ? data['internalApp'] as bool? : null,
      name: data['name']?.toString(),
      removable: data['removable'] is bool? ? data['removable'] as bool? : null,
      url: data['url']?.toString(),
      version: data['version']?.toString(),
    );
  }

  final bool? appClip;
  final bool? builtByDeveloper;
  final String? bundleIdentifier;
  final String? bundleVersion;
  final bool? defaultApp;
  final bool? hidden;
  final bool? internalApp;
  final String? name;
  final bool? removable;
  final String? url;
  final String? version;
}

class IOSCoreDeviceLaunchResult {
  IOSCoreDeviceLaunchResult._({required this.outcome, required this.process});

  /// Parse JSON from `devicectl device process launch --device <uuid|ecid|udid|name> <bundle-identifier-or-path> --json-output`.
  ///
  /// Example:
  /// {
  ///   "info" : {
  ///     ...
  ///     "outcome" : "success",
  ///   },
  ///   "result" : {
  ///     ...
  ///     "process" : {
  ///       ...
  ///       "executable" : "file:////private/var/containers/Bundle/Application/D12EFD3B-4567-890E-B1F2-23456DAA789A/Runner.app/Runner",
  ///       "processIdentifier" : 14306
  ///     }
  ///   }
  /// }
  factory IOSCoreDeviceLaunchResult.fromJson(Map<String, Object?> data) {
    String? outcome;
    IOSCoreDeviceRunningProcess? process;
    final Object? info = data['info'];
    if (info is Map<String, Object?>) {
      outcome = info['outcome'] as String?;
    }

    final Object? result = data['result'];
    if (result is Map<String, Object?>) {
      final Object? processObject = result['process'];
      if (processObject is Map<String, Object?>) {
        process = IOSCoreDeviceRunningProcess.fromJson(processObject);
      }
    }

    return IOSCoreDeviceLaunchResult._(outcome: outcome, process: process);
  }

  final String? outcome;
  final IOSCoreDeviceRunningProcess? process;
}

class IOSCoreDeviceRunningProcess {
  IOSCoreDeviceRunningProcess._({required this.executable, required this.processIdentifier});

  //// Parse `process` section of JSON from `devicectl device process launch --device <uuid|ecid|udid|name> <bundle-identifier-or-path> --json-output`.
  ///
  /// Example:
  ///     "process" : {
  ///       ...
  ///       "executable" : "file:////private/var/containers/Bundle/Application/D12EFD3B-4567-890E-B1F2-23456DAA789A/Runner.app/Runner",
  ///       "processIdentifier" : 14306
  ///     }
  factory IOSCoreDeviceRunningProcess.fromJson(Map<String, Object?> data) {
    return IOSCoreDeviceRunningProcess._(
      executable: data['executable']?.toString(),
      processIdentifier: data['processIdentifier'] is int?
          ? data['processIdentifier'] as int?
          : null,
    );
  }

  final String? executable;
  final int? processIdentifier;
}

class IOSCoreDeviceInstallResult {
  IOSCoreDeviceInstallResult._({
    required this.outcome,
    required this.bundleID,
    required this.databaseUUID,
    required this.installationURL,
    required this.launchServicesIdentifier,
  });

  /// Parse JSON from `devicectl device install app --device <uuid|ecid|udid|name> <path> --json-output`.
  ///
  /// Example:
  ///   {
  ///   "info" : {
  ///     ...
  ///     "outcome" : "success",
  ///     ...
  ///   },
  ///   "result" : {
  ///     ...
  ///     "installedApplications" : [
  ///       {
  ///         "bundleID" : "com.example.app",
  ///         "databaseSequenceNumber" : 1324,
  ///         "databaseUUID" : "DF123456-1234-4C46-B3F2-EF7D18596C3D",
  ///         "installationURL" : "file:////private/var/containers/Bundle/Application/D12EFD3B-4567-890E-B1F2-23456DAA789A/Runner.app/",
  ///         "launchServicesIdentifier" : "unknown",
  ///         "options" : {
  ///         }
  ///       }
  ///     ]
  ///   }
  /// }
  factory IOSCoreDeviceInstallResult.fromJson(Map<String, Object?> data) {
    String? outcome;
    final Object? info = data['info'];
    if (info is Map<String, Object?>) {
      outcome = info['outcome'] as String?;
    }

    final Map<String, Object?>? installedApp = switch (data['result']) {
      {'installedApplications': [final Map<String, Object?> app, ...]} => app,
      _ => null,
    };

    return IOSCoreDeviceInstallResult._(
      outcome: outcome,
      bundleID: installedApp?['bundleID'] as String?,
      databaseUUID: installedApp?['databaseUUID'] as String?,
      installationURL: installedApp?['installationURL'] as String?,
      launchServicesIdentifier: installedApp?['launchServicesIdentifier'] as String?,
    );
  }

  final String? outcome;
  final String? bundleID;
  final String? databaseUUID;
  final String? installationURL;
  final String? launchServicesIdentifier;
}

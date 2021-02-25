// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:async/async.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../android/android_workflow.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../convert.dart';
import '../device.dart';
import '../emulator.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../resident_runner.dart';
import '../run_cold.dart';
import '../run_hot.dart';
import '../runner/flutter_command.dart';
import '../web/web_runner.dart';

const String protocolVersion = '0.6.0';

/// A server process command. This command will start up a long-lived server.
/// It reads JSON-RPC based commands from stdin, executes them, and returns
/// JSON-RPC based responses and events to stdout.
///
/// It can be shutdown with a `daemon.shutdown` command (or by killing the
/// process).
class DaemonCommand extends FlutterCommand {
  DaemonCommand({ this.hidden = false });

  @override
  final String name = 'daemon';

  @override
  final String description = 'Run a persistent, JSON-RPC based server to communicate with devices.';

  @override
  final bool hidden;

  @override
  Future<FlutterCommandResult> runCommand() async {
    globals.printStatus('Starting device daemon...');
    final Daemon daemon = Daemon(
      stdinCommandStream, stdoutCommandResponse,
      notifyingLogger: asLogger<NotifyingLogger>(globals.logger),
    );
    final int code = await daemon.onExit;
    if (code != 0) {
      throwToolExit('Daemon exited with non-zero exit code: $code', exitCode: code);
    }
    return FlutterCommandResult.success();
  }
}

typedef DispatchCommand = void Function(Map<String, dynamic> command);

typedef CommandHandler = Future<dynamic> Function(Map<String, dynamic> args);

class Daemon {
  Daemon(
    Stream<Map<String, dynamic>> commandStream,
    this.sendCommand, {
    this.notifyingLogger,
    this.logToStdout = false,
  }) {
    // Set up domains.
    _registerDomain(daemonDomain = DaemonDomain(this));
    _registerDomain(appDomain = AppDomain(this));
    _registerDomain(deviceDomain = DeviceDomain(this));
    _registerDomain(emulatorDomain = EmulatorDomain(this));
    _registerDomain(devToolsDomain = DevToolsDomain(this));

    // Start listening.
    _commandSubscription = commandStream.listen(
      _handleRequest,
      onDone: () {
        if (!_onExitCompleter.isCompleted) {
          _onExitCompleter.complete(0);
        }
      },
    );
  }

  DaemonDomain daemonDomain;
  AppDomain appDomain;
  DeviceDomain deviceDomain;
  EmulatorDomain emulatorDomain;
  DevToolsDomain devToolsDomain;
  StreamSubscription<Map<String, dynamic>> _commandSubscription;
  int _outgoingRequestId = 1;
  final Map<String, Completer<dynamic>> _outgoingRequestCompleters = <String, Completer<dynamic>>{};

  final DispatchCommand sendCommand;
  final NotifyingLogger notifyingLogger;
  final bool logToStdout;

  final Completer<int> _onExitCompleter = Completer<int>();
  final Map<String, Domain> _domainMap = <String, Domain>{};

  void _registerDomain(Domain domain) {
    _domainMap[domain.name] = domain;
  }

  Future<int> get onExit => _onExitCompleter.future;

  void _handleRequest(Map<String, dynamic> request) {
    // {id, method, params}

    // [id] is an opaque type to us.
    final dynamic id = request['id'];

    if (id == null) {
      globals.stdio.stderrWrite('no id for request: $request\n');
      return;
    }

    try {
      final String method = request['method'] as String;
      if (method != null) {
        if (!method.contains('.')) {
          throw 'method not understood: $method';
        }

        final String prefix = method.substring(0, method.indexOf('.'));
        final String name = method.substring(method.indexOf('.') + 1);
        if (_domainMap[prefix] == null) {
          throw 'no domain for method: $method';
        }

        _domainMap[prefix].handleCommand(name, id, castStringKeyedMap(request['params']) ?? const <String, dynamic>{});
      } else {
        // If there was no 'method' field then it's a response to a daemon-to-editor request.
        final Completer<dynamic> completer = _outgoingRequestCompleters[id.toString()];
        if (completer == null) {
          throw 'unexpected response with id: $id';
        }
        _outgoingRequestCompleters.remove(id.toString());

        if (request['error'] != null) {
          completer.completeError(request['error']);
        } else {
          completer.complete(request['result']);
        }
      }
    } on Exception catch (error, trace) {
      _send(<String, dynamic>{
        'id': id,
        'error': _toJsonable(error),
        'trace': '$trace',
      });
    }
  }

  Future<dynamic> sendRequest(String method, [ dynamic args ]) {
    final Map<String, dynamic> map = <String, dynamic>{'method': method};
    if (args != null) {
      map['params'] = _toJsonable(args);
    }

    final int id = _outgoingRequestId++;
    final Completer<dynamic> completer = Completer<dynamic>();

    map['id'] = id.toString();
    _outgoingRequestCompleters[id.toString()] = completer;

    _send(map);
    return completer.future;
  }

  void _send(Map<String, dynamic> map) => sendCommand(map);

  Future<void> shutdown({ dynamic error }) async {
    await devToolsDomain?.dispose();
    await _commandSubscription?.cancel();
    for (final Domain domain in _domainMap.values) {
      await domain.dispose();
    }
    if (!_onExitCompleter.isCompleted) {
      if (error == null) {
        _onExitCompleter.complete(0);
      } else {
        _onExitCompleter.completeError(error);
      }
    }
  }
}

abstract class Domain {
  Domain(this.daemon, this.name);


  final Daemon daemon;
  final String name;
  final Map<String, CommandHandler> _handlers = <String, CommandHandler>{};

  void registerHandler(String name, CommandHandler handler) {
    _handlers[name] = handler;
  }

  @override
  String toString() => name;

  void handleCommand(String command, dynamic id, Map<String, dynamic> args) {
    Future<dynamic>.sync(() {
      if (_handlers.containsKey(command)) {
        return _handlers[command](args);
      }
      throw 'command not understood: $name.$command';
    }).then<dynamic>((dynamic result) {
      if (result == null) {
        _send(<String, dynamic>{'id': id});
      } else {
        _send(<String, dynamic>{'id': id, 'result': _toJsonable(result)});
      }
    }).catchError((dynamic error, dynamic trace) {
      _send(<String, dynamic>{
        'id': id,
        'error': _toJsonable(error),
        'trace': '$trace',
      });
    });
  }

  void sendEvent(String name, [ dynamic args ]) {
    final Map<String, dynamic> map = <String, dynamic>{'event': name};
    if (args != null) {
      map['params'] = _toJsonable(args);
    }
    _send(map);
  }

  void _send(Map<String, dynamic> map) => daemon._send(map);

  String _getStringArg(Map<String, dynamic> args, String name, { bool required = false }) {
    if (required && !args.containsKey(name)) {
      throw '$name is required';
    }
    final dynamic val = args[name];
    if (val != null && val is! String) {
      throw '$name is not a String';
    }
    return val as String;
  }

  bool _getBoolArg(Map<String, dynamic> args, String name, { bool required = false }) {
    if (required && !args.containsKey(name)) {
      throw '$name is required';
    }
    final dynamic val = args[name];
    if (val != null && val is! bool) {
      throw '$name is not a bool';
    }
    return val as bool;
  }

  int _getIntArg(Map<String, dynamic> args, String name, { bool required = false }) {
    if (required && !args.containsKey(name)) {
      throw '$name is required';
    }
    final dynamic val = args[name];
    if (val != null && val is! int) {
      throw '$name is not an int';
    }
    return val as int;
  }

  Future<void> dispose() async { }
}

/// This domain responds to methods like [version] and [shutdown].
///
/// This domain fires the `daemon.logMessage` event.
class DaemonDomain extends Domain {
  DaemonDomain(Daemon daemon) : super(daemon, 'daemon') {
    registerHandler('version', version);
    registerHandler('shutdown', shutdown);
    registerHandler('getSupportedPlatforms', getSupportedPlatforms);

    sendEvent(
      'daemon.connected',
      <String, dynamic>{
        'version': protocolVersion,
        'pid': pid,
      },
    );

    _subscription = daemon.notifyingLogger.onMessage.listen((LogMessage message) {
      if (daemon.logToStdout) {
        if (message.level == 'status') {
          // We use `print()` here instead of `stdout.writeln()` in order to
          // capture the print output for testing.
          print(message.message);
        } else if (message.level == 'error') {
          globals.stdio.stderrWrite('${message.message}\n');
          if (message.stackTrace != null) {
            globals.stdio.stderrWrite(
              '${message.stackTrace.toString().trimRight()}\n',
            );
          }
        }
      } else {
        if (message.stackTrace != null) {
          sendEvent('daemon.logMessage', <String, dynamic>{
            'level': message.level,
            'message': message.message,
            'stackTrace': message.stackTrace.toString(),
          });
        } else {
          sendEvent('daemon.logMessage', <String, dynamic>{
            'level': message.level,
            'message': message.message,
          });
        }
      }
    });
  }

  StreamSubscription<LogMessage> _subscription;

  Future<String> version(Map<String, dynamic> args) {
    return Future<String>.value(protocolVersion);
  }

  /// Sends a request back to the client asking it to expose/tunnel a URL.
  ///
  /// This method should only be called if the client opted-in with the
  /// --web-allow-expose-url switch. The client may return the same URL back if
  /// tunnelling is not required for a given URL.
  Future<String> exposeUrl(String url) async {
    final dynamic res = await daemon.sendRequest('app.exposeUrl', <String, String>{'url': url});
    if (res is Map<String, dynamic> && res['url'] is String) {
      return res['url'] as String;
    } else {
      globals.printError('Invalid response to exposeUrl - params should include a String url field');
      return url;
    }
  }

  Future<void> shutdown(Map<String, dynamic> args) {
    Timer.run(daemon.shutdown);
    return Future<void>.value();
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
  }

  /// Enumerates the platforms supported by the provided project.
  ///
  /// This does not filter based on the current workflow restrictions, such
  /// as whether command line tools are installed or whether the host platform
  /// is correct.
  Future<Map<String, Object>> getSupportedPlatforms(Map<String, dynamic> args) async {
    final String projectRoot = _getStringArg(args, 'projectRoot', required: true);
    final List<String> result = <String>[];
    try {
      final FlutterProject flutterProject = FlutterProject.fromDirectory(globals.fs.directory(projectRoot));
      if (featureFlags.isLinuxEnabled && flutterProject.linux.existsSync()) {
        result.add('linux');
      }
      if (featureFlags.isMacOSEnabled && flutterProject.macos.existsSync()) {
        result.add('macos');
      }
      if (featureFlags.isWindowsEnabled && flutterProject.windows.existsSync()) {
        result.add('windows');
      }
      if (featureFlags.isIOSEnabled && flutterProject.ios.existsSync()) {
        result.add('ios');
      }
      if (featureFlags.isAndroidEnabled && flutterProject.android.existsSync()) {
        result.add('android');
      }
      if (featureFlags.isWebEnabled && flutterProject.web.existsSync()) {
        result.add('web');
      }
      if (featureFlags.isFuchsiaEnabled && flutterProject.fuchsia.existsSync()) {
        result.add('fuchsia');
      }
      return <String, Object>{
        'platforms': result,
      };
    } on Exception catch (err, stackTrace) {
      sendEvent('log', <String, dynamic>{
        'log': 'Failed to parse project metadata',
        'stackTrace': stackTrace.toString(),
        'error': true,
      });
      // On any sort of failure, fall back to Android and iOS for backwards
      // comparability.
      return <String, Object>{
        'platforms': <String>[
          'android',
          'ios',
        ],
      };
    }
  }
}

typedef _RunOrAttach = Future<void> Function({
  Completer<DebugConnectionInfo> connectionInfoCompleter,
  Completer<void> appStartedCompleter,
});

/// This domain responds to methods like [start] and [stop].
///
/// It fires events for application start, stop, and stdout and stderr.
class AppDomain extends Domain {
  AppDomain(Daemon daemon) : super(daemon, 'app') {
    registerHandler('restart', restart);
    registerHandler('callServiceExtension', callServiceExtension);
    registerHandler('stop', stop);
    registerHandler('detach', detach);
  }

  // TODO(jonahwilliams): update after google3 uuid is updated.
  // ignore: prefer_const_constructors
  static final Uuid _uuidGenerator = Uuid();

  static String _getNewAppId() => _uuidGenerator.v4();

  final List<AppInstance> _apps = <AppInstance>[];

  final DebounceOperationQueue<OperationResult, OperationType> operationQueue = DebounceOperationQueue<OperationResult, OperationType>();

  Future<AppInstance> startApp(
    Device device,
    String projectDirectory,
    String target,
    String route,
    DebuggingOptions options,
    bool enableHotReload, {
    File applicationBinary,
    @required bool trackWidgetCreation,
    String projectRootPath,
    String packagesFilePath,
    String dillOutputPath,
    bool ipv6 = false,
    String isolateFilter,
    bool machine = true,
  }) async {
    if (!await device.supportsRuntimeMode(options.buildInfo.mode)) {
      throw Exception(
        '${toTitleCase(options.buildInfo.friendlyModeName)} '
        'mode is not supported for ${device.name}.',
      );
    }

    // We change the current working directory for the duration of the `start` command.
    final Directory cwd = globals.fs.currentDirectory;
    globals.fs.currentDirectory = globals.fs.directory(projectDirectory);
    final FlutterProject flutterProject = FlutterProject.current();

    final FlutterDevice flutterDevice = await FlutterDevice.create(
      device,
      target: target,
      buildInfo: options.buildInfo,
      platform: globals.platform,
    );

    ResidentRunner runner;

    if (await device.targetPlatform == TargetPlatform.web_javascript) {
      runner = webRunnerFactory.createWebRunner(
        flutterDevice,
        flutterProject: flutterProject,
        target: target,
        debuggingOptions: options,
        ipv6: ipv6,
        stayResident: true,
        urlTunneller: options.webEnableExposeUrl ? daemon.daemonDomain.exposeUrl : null,
        machine: machine,
      );
    } else if (enableHotReload) {
      runner = HotRunner(
        <FlutterDevice>[flutterDevice],
        target: target,
        debuggingOptions: options,
        applicationBinary: applicationBinary,
        projectRootPath: projectRootPath,
        dillOutputPath: dillOutputPath,
        ipv6: ipv6,
        hostIsIde: true,
        machine: machine,
      );
    } else {
      runner = ColdRunner(
        <FlutterDevice>[flutterDevice],
        target: target,
        debuggingOptions: options,
        applicationBinary: applicationBinary,
        ipv6: ipv6,
        machine: machine,
      );
    }

    return launch(
      runner,
      ({
        Completer<DebugConnectionInfo> connectionInfoCompleter,
        Completer<void> appStartedCompleter,
      }) {
        return runner.run(
          connectionInfoCompleter: connectionInfoCompleter,
          appStartedCompleter: appStartedCompleter,
          enableDevTools: true,
          route: route,
        );
      },
      device,
      projectDirectory,
      enableHotReload,
      cwd,
      LaunchMode.run,
      asLogger<AppRunLogger>(globals.logger),
    );
  }

  Future<AppInstance> launch(
    ResidentRunner runner,
    _RunOrAttach runOrAttach,
    Device device,
    String projectDirectory,
    bool enableHotReload,
    Directory cwd,
    LaunchMode launchMode,
    AppRunLogger logger,
  ) async {
    final AppInstance app = AppInstance(_getNewAppId(),
        runner: runner, logToStdout: daemon.logToStdout, logger: logger);
    _apps.add(app);

    // Set the domain and app for the given AppRunLogger. This allows the logger
    // to log messages containing the app ID to the host.
    logger.domain = this;
    logger.app = app;

    _sendAppEvent(app, 'start', <String, dynamic>{
      'deviceId': device.id,
      'directory': projectDirectory,
      'supportsRestart': isRestartSupported(enableHotReload, device),
      'launchMode': launchMode.toString(),
    });

    Completer<DebugConnectionInfo> connectionInfoCompleter;

    if (runner.debuggingEnabled) {
      connectionInfoCompleter = Completer<DebugConnectionInfo>();
      // We don't want to wait for this future to complete and callbacks won't fail.
      // As it just writes to stdout.
      unawaited(connectionInfoCompleter.future.then<void>(
        (DebugConnectionInfo info) {
          final Map<String, dynamic> params = <String, dynamic>{
            // The web vmservice proxy does not have an http address.
            'port': info.httpUri?.port ?? info.wsUri.port,
            'wsUri': info.wsUri.toString(),
          };
          if (info.baseUri != null) {
            params['baseUri'] = info.baseUri;
          }
          _sendAppEvent(app, 'debugPort', params);
        },
      ));
    }
    final Completer<void> appStartedCompleter = Completer<void>();
    // We don't want to wait for this future to complete, and callbacks won't fail,
    // as it just writes to stdout.
    unawaited(appStartedCompleter.future.then<void>((void value) {
      _sendAppEvent(app, 'started');
    }));

    await app._runInZone<void>(this, () async {
      try {
        await runOrAttach(
          connectionInfoCompleter: connectionInfoCompleter,
          appStartedCompleter: appStartedCompleter,
        );
        _sendAppEvent(app, 'stop');
      } on Exception catch (error, trace) {
        _sendAppEvent(app, 'stop', <String, dynamic>{
          'error': _toJsonable(error),
          'trace': '$trace',
        });
      } finally {
        // If the full directory is used instead of the path then this causes
        // a TypeError with the ErrorHandlingFileSystem.
        globals.fs.currentDirectory = cwd.path;
        _apps.remove(app);
      }
    });
    return app;
  }

  bool isRestartSupported(bool enableHotReload, Device device) =>
      enableHotReload && device.supportsHotRestart;

  final int _hotReloadDebounceDurationMs = 50;

  Future<OperationResult> restart(Map<String, dynamic> args) async {
    final String appId = _getStringArg(args, 'appId', required: true);
    final bool fullRestart = _getBoolArg(args, 'fullRestart') ?? false;
    final bool pauseAfterRestart = _getBoolArg(args, 'pause') ?? false;
    final String restartReason = _getStringArg(args, 'reason');
    final bool debounce = _getBoolArg(args, 'debounce') ?? false;
    // This is an undocumented parameter used for integration tests.
    final int debounceDurationOverrideMs = _getIntArg(args, 'debounceDurationOverrideMs');

    final AppInstance app = _getApp(appId);
    if (app == null) {
      throw "app '$appId' not found";
    }

    return _queueAndDebounceReloadAction(
      app,
      fullRestart ? OperationType.restart: OperationType.reload,
      debounce,
      debounceDurationOverrideMs,
      () {
        return app.restart(
            fullRestart: fullRestart,
            pause: pauseAfterRestart,
            reason: restartReason);
      },
    );
  }

  /// Debounce and queue reload actions.
  ///
  /// Only one reload action will run at a time. Actions requested in quick
  /// succession (within [_hotReloadDebounceDuration]) will be merged together
  /// and all return the same result. If an action is requested after an identical
  /// action has already started, it will be queued and run again once the first
  /// action completes.
  Future<OperationResult> _queueAndDebounceReloadAction(
    AppInstance app,
    OperationType operationType,
    bool debounce,
    int debounceDurationOverrideMs,
    Future<OperationResult> Function() action,
  ) {
    final Duration debounceDuration = debounce
        ? Duration(milliseconds: debounceDurationOverrideMs ?? _hotReloadDebounceDurationMs)
        : Duration.zero;

    return operationQueue.queueAndDebounce(
      operationType,
      debounceDuration,
      () => app._runInZone<OperationResult>(this, action),
    );
  }

  /// Returns an error, or the service extension result (a map with two fixed
  /// keys, `type` and `method`). The result may have one or more additional keys,
  /// depending on the specific service extension end-point. For example:
  ///
  ///     {
  ///       "value":"android",
  ///       "type":"_extensionType",
  ///       "method":"ext.flutter.platformOverride"
  ///     }
  Future<Map<String, dynamic>> callServiceExtension(Map<String, dynamic> args) async {
    final String appId = _getStringArg(args, 'appId', required: true);
    final String methodName = _getStringArg(args, 'methodName');
    final Map<String, dynamic> params = args['params'] == null ? <String, dynamic>{} : castStringKeyedMap(args['params']);

    final AppInstance app = _getApp(appId);
    if (app == null) {
      throw "app '$appId' not found";
    }

    final Map<String, dynamic> result = await app.runner
        .invokeFlutterExtensionRpcRawOnFirstIsolate(methodName, params: params);
    if (result == null) {
      throw 'method not available: $methodName';
    }

    if (result.containsKey('error')) {
      throw result['error'];
    }

    return result;
  }

  Future<bool> stop(Map<String, dynamic> args) async {
    final String appId = _getStringArg(args, 'appId', required: true);

    final AppInstance app = _getApp(appId);
    if (app == null) {
      throw "app '$appId' not found";
    }

    return app.stop().then<bool>(
      (void value) => true,
      onError: (dynamic error, StackTrace stack) {
        _sendAppEvent(app, 'log', <String, dynamic>{'log': '$error', 'error': true});
        app.closeLogger();
        _apps.remove(app);
        return false;
      },
    );
  }

  Future<bool> detach(Map<String, dynamic> args) async {
    final String appId = _getStringArg(args, 'appId', required: true);

    final AppInstance app = _getApp(appId);
    if (app == null) {
      throw "app '$appId' not found";
    }

    return app.detach().then<bool>(
      (void value) => true,
      onError: (dynamic error, StackTrace stack) {
        _sendAppEvent(app, 'log', <String, dynamic>{'log': '$error', 'error': true});
        app.closeLogger();
        _apps.remove(app);
        return false;
      },
    );
  }

  AppInstance _getApp(String id) {
    return _apps.firstWhere((AppInstance app) => app.id == id, orElse: () => null);
  }

  void _sendAppEvent(AppInstance app, String name, [ Map<String, dynamic> args ]) {
    sendEvent('app.$name', <String, dynamic>{
      'appId': app.id,
      ...?args,
    });
  }
}

typedef _DeviceEventHandler = void Function(Device device);

/// This domain lets callers list and monitor connected devices.
///
/// It exports a `getDevices()` call, as well as firing `device.added` and
/// `device.removed` events.
class DeviceDomain extends Domain {
  DeviceDomain(Daemon daemon) : super(daemon, 'device') {
    registerHandler('getDevices', getDevices);
    registerHandler('enable', enable);
    registerHandler('disable', disable);
    registerHandler('forward', forward);
    registerHandler('unforward', unforward);

    // Use the device manager discovery so that client provided device types
    // are usable via the daemon protocol.
    globals.deviceManager.deviceDiscoverers.forEach(addDeviceDiscoverer);
  }

  void addDeviceDiscoverer(DeviceDiscovery discoverer) {
    if (!discoverer.supportsPlatform) {
      return;
    }

    if (discoverer is PollingDeviceDiscovery) {
      _discoverers.add(discoverer);
      discoverer.onAdded.listen(_onDeviceEvent('device.added'));
      discoverer.onRemoved.listen(_onDeviceEvent('device.removed'));
    }
  }

  Future<void> _serializeDeviceEvents = Future<void>.value();

  _DeviceEventHandler _onDeviceEvent(String eventName) {
    return (Device device) {
      _serializeDeviceEvents = _serializeDeviceEvents.then<void>((_) async {
        try {
          final Map<String, Object> response = await _deviceToMap(device);
          sendEvent(eventName, response);
        } on Exception catch (err) {
          globals.printError('$err');
        }
      });
    };
  }

  final List<PollingDeviceDiscovery> _discoverers = <PollingDeviceDiscovery>[];

  /// Return a list of the current devices, with each device represented as a map
  /// of properties (id, name, platform, ...).
  Future<List<Map<String, dynamic>>> getDevices([ Map<String, dynamic> args ]) async {
    return <Map<String, dynamic>>[
      for (final PollingDeviceDiscovery discoverer in _discoverers)
        for (final Device device in await discoverer.devices)
          await _deviceToMap(device),
    ];
  }

  /// Enable device events.
  Future<void> enable(Map<String, dynamic> args) async {
    for (final PollingDeviceDiscovery discoverer in _discoverers) {
      discoverer.startPolling();
    }
  }

  /// Disable device events.
  Future<void> disable(Map<String, dynamic> args) async {
    for (final PollingDeviceDiscovery discoverer in _discoverers) {
      discoverer.stopPolling();
    }
  }

  /// Forward a host port to a device port.
  Future<Map<String, dynamic>> forward(Map<String, dynamic> args) async {
    final String deviceId = _getStringArg(args, 'deviceId', required: true);
    final int devicePort = _getIntArg(args, 'devicePort', required: true);
    int hostPort = _getIntArg(args, 'hostPort');

    final Device device = await daemon.deviceDomain._getDevice(deviceId);
    if (device == null) {
      throw "device '$deviceId' not found";
    }

    hostPort = await device.portForwarder.forward(devicePort, hostPort: hostPort);

    return <String, dynamic>{'hostPort': hostPort};
  }

  /// Removes a forwarded port.
  Future<void> unforward(Map<String, dynamic> args) async {
    final String deviceId = _getStringArg(args, 'deviceId', required: true);
    final int devicePort = _getIntArg(args, 'devicePort', required: true);
    final int hostPort = _getIntArg(args, 'hostPort', required: true);

    final Device device = await daemon.deviceDomain._getDevice(deviceId);
    if (device == null) {
      throw "device '$deviceId' not found";
    }

    return device.portForwarder.unforward(ForwardedPort(hostPort, devicePort));
  }

  @override
  Future<void> dispose() {
    for (final PollingDeviceDiscovery discoverer in _discoverers) {
      discoverer.dispose();
    }
    return Future<void>.value();
  }

  /// Return the device matching the deviceId field in the args.
  Future<Device> _getDevice(String deviceId) async {
    for (final PollingDeviceDiscovery discoverer in _discoverers) {
      final Device device = (await discoverer.devices).firstWhere((Device device) => device.id == deviceId, orElse: () => null);
      if (device != null) {
        return device;
      }
    }
    return null;
  }
}

class DevToolsDomain extends Domain {
  DevToolsDomain(Daemon daemon) : super(daemon, 'devtools') {
    registerHandler('serve', serve);
  }

  DevtoolsLauncher _devtoolsLauncher;

  Future<Map<String, dynamic>> serve([ Map<String, dynamic> args ]) async {
    _devtoolsLauncher ??= DevtoolsLauncher.instance;
    final DevToolsServerAddress server = await _devtoolsLauncher.serve();
    return<String, dynamic>{
      'host': server?.host,
      'port': server?.port,
    };
  }

  @override
  Future<void> dispose() async {
    await _devtoolsLauncher?.close();
  }
}

Stream<Map<String, dynamic>> get stdinCommandStream => globals.stdio.stdin
  .transform<String>(utf8.decoder)
  .transform<String>(const LineSplitter())
  .where((String line) => line.startsWith('[{') && line.endsWith('}]'))
  .map<Map<String, dynamic>>((String line) {
    line = line.substring(1, line.length - 1);
    return castStringKeyedMap(json.decode(line));
  });

void stdoutCommandResponse(Map<String, dynamic> command) {
  globals.stdio.stdoutWrite(
    '[${jsonEncodeObject(command)}]\n',
    fallback: (String message, dynamic error, StackTrace stack) {
      throwToolExit('Failed to write daemon command response to stdout: $error');
    },
  );
}

String jsonEncodeObject(dynamic object) {
  return json.encode(object, toEncodable: _toEncodable);
}

dynamic _toEncodable(dynamic object) {
  if (object is OperationResult) {
    return _operationResultToMap(object);
  }
  return object;
}

Future<Map<String, dynamic>> _deviceToMap(Device device) async {
  return <String, dynamic>{
    'id': device.id,
    'name': device.name,
    'platform': getNameForTargetPlatform(await device.targetPlatform),
    'emulator': await device.isLocalEmulator,
    'category': device.category?.toString(),
    'platformType': device.platformType?.toString(),
    'ephemeral': device.ephemeral,
    'emulatorId': await device.emulatorId,
  };
}

Map<String, dynamic> _emulatorToMap(Emulator emulator) {
  return <String, dynamic>{
    'id': emulator.id,
    'name': emulator.name,
    'category': emulator.category?.toString(),
    'platformType': emulator.platformType?.toString(),
  };
}

Map<String, dynamic> _operationResultToMap(OperationResult result) {
  return <String, dynamic>{
    'code': result.code,
    'message': result.message,
  };
}

dynamic _toJsonable(dynamic obj) {
  if (obj is String || obj is int || obj is bool || obj is Map<dynamic, dynamic> || obj is List<dynamic> || obj == null) {
    return obj;
  }
  if (obj is OperationResult) {
    return obj;
  }
  if (obj is ToolExit) {
    return obj.message;
  }
  return '$obj';
}

class NotifyingLogger extends DelegatingLogger {
  NotifyingLogger({ @required this.verbose, @required Logger parent }) : super(parent) {
    _messageController = StreamController<LogMessage>.broadcast(
      onListen: _onListen,
    );
  }

  final bool verbose;
  final List<LogMessage> messageBuffer = <LogMessage>[];
  StreamController<LogMessage> _messageController;

  void _onListen() {
    if (messageBuffer.isNotEmpty) {
      messageBuffer.forEach(_messageController.add);
      messageBuffer.clear();
    }
  }

  Stream<LogMessage> get onMessage => _messageController.stream;

  @override
  void printError(
    String message, {
    StackTrace stackTrace,
    bool emphasis = false,
    TerminalColor color,
    int indent,
    int hangingIndent,
    bool wrap,
  }) {
    _sendMessage(LogMessage('error', message, stackTrace));
  }

  @override
  void printStatus(
    String message, {
    bool emphasis = false,
    TerminalColor color,
    bool newline = true,
    int indent,
    int hangingIndent,
    bool wrap,
  }) {
    _sendMessage(LogMessage('status', message));
  }

  @override
  void printTrace(String message) {
    if (!verbose) {
      return;
    }
    super.printError(message);
  }

  @override
  Status startProgress(
    String message, {
    @required Duration timeout,
    String progressId,
    bool multilineOutput = false,
    int progressIndicatorPadding = kDefaultStatusPadding,
  }) {
    assert(timeout != null);
    printStatus(message);
    return SilentStatus(
      stopwatch: Stopwatch(),
    );
  }

  void _sendMessage(LogMessage logMessage) {
    if (_messageController.hasListener) {
      return _messageController.add(logMessage);
    }
    messageBuffer.add(logMessage);
  }

  void dispose() {
    _messageController.close();
  }

  @override
  void sendEvent(String name, [Map<String, dynamic> args]) { }

  @override
  bool get supportsColor => throw UnimplementedError();

  @override
  bool get hasTerminal => false;

  // This method is only relevant for terminals.
  @override
  void clear() { }
}

/// A running application, started by this daemon.
class AppInstance {
  AppInstance(this.id, { this.runner, this.logToStdout = false, @required AppRunLogger logger })
    : _logger = logger;

  final String id;
  final ResidentRunner runner;
  final bool logToStdout;
  final AppRunLogger _logger;

  Future<OperationResult> restart({ bool fullRestart = false, bool pause = false, String reason }) {
    return runner.restart(fullRestart: fullRestart, pause: pause, reason: reason);
  }

  Future<void> stop() => runner.exit();
  Future<void> detach() => runner.detach();

  void closeLogger() {
    _logger.close();
  }

  Future<T> _runInZone<T>(AppDomain domain, FutureOr<T> method()) async {
    return method();
  }
}

/// This domain responds to methods like [getEmulators] and [launch].
class EmulatorDomain extends Domain {
  EmulatorDomain(Daemon daemon) : super(daemon, 'emulator') {
    registerHandler('getEmulators', getEmulators);
    registerHandler('launch', launch);
    registerHandler('create', create);
  }

  EmulatorManager emulators = EmulatorManager(
    fileSystem: globals.fs,
    logger: globals.logger,
    androidSdk: globals.androidSdk,
    processManager: globals.processManager,
    androidWorkflow: androidWorkflow,
  );

  Future<List<Map<String, dynamic>>> getEmulators([ Map<String, dynamic> args ]) async {
    final List<Emulator> list = await emulators.getAllAvailableEmulators();
    return list.map<Map<String, dynamic>>(_emulatorToMap).toList();
  }

  Future<void> launch(Map<String, dynamic> args) async {
    final String emulatorId = _getStringArg(args, 'emulatorId', required: true);
    final List<Emulator> matches =
        await emulators.getEmulatorsMatching(emulatorId);
    if (matches.isEmpty) {
      throw "emulator '$emulatorId' not found";
    } else if (matches.length > 1) {
      throw "multiple emulators match '$emulatorId'";
    } else {
      await matches.first.launch();
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> args) async {
    final String name = _getStringArg(args, 'name', required: false);
    final CreateEmulatorResult res = await emulators.createEmulator(name: name);
    return <String, dynamic>{
      'success': res.success,
      'emulatorName': res.emulatorName,
      'error': res.error,
    };
  }
}

/// A [Logger] which sends log messages to a listening daemon client.
///
/// This class can either:
///   1) Send stdout messages and progress events to the client IDE
///   1) Log messages to stdout and send progress events to the client IDE
//
// TODO(devoncarew): To simplify this code a bit, we could choose to specialize
// this class into two, one for each of the above use cases.
class AppRunLogger extends DelegatingLogger {
  AppRunLogger({ @required Logger parent }) : super(parent);

  AppDomain domain;
  AppInstance app;
  int _nextProgressId = 0;

  Status _status;

  @override
  Status startProgress(
    String message, {
    @required Duration timeout,
    String progressId,
    bool multilineOutput = false,
    int progressIndicatorPadding = kDefaultStatusPadding,
  }) {
    final int id = _nextProgressId++;

    _sendProgressEvent(
      eventId: id.toString(),
      eventType: progressId,
      message: message,
    );

    _status = SilentStatus(
      onFinish: () {
        _status = null;
        _sendProgressEvent(
          eventId: id.toString(),
          eventType: progressId,
          finished: true,
        );
      }, stopwatch: Stopwatch())..start();
    return _status;
  }

  void close() {
    domain = null;
  }

  void _sendProgressEvent({
    @required String eventId,
    @required String eventType,
    bool finished = false,
    String message,
  }) {
    if (domain == null) {
      // If we're sending progress events before an app has started, send the
      // progress messages as plain status messages.
      if (message != null) {
        printStatus(message);
      }
    } else {
      final Map<String, dynamic> event = <String, dynamic>{
        'id': eventId,
        'progressId': eventType,
        if (message != null) 'message': message,
        if (finished != null) 'finished': finished,
      };

      domain._sendAppEvent(app, 'progress', event);
    }
  }

  @override
  void sendEvent(String name, [Map<String, dynamic> args]) {
    if (domain == null) {
      printStatus('event sent after app closed: $name');
    } else {
      domain.sendEvent(name, args);
    }
  }

  @override
  bool get supportsColor => throw UnimplementedError();

  @override
  bool get hasTerminal => false;

  // This method is only relevant for terminals.
  @override
  void clear() { }
}

class LogMessage {
  LogMessage(this.level, this.message, [this.stackTrace]);

  final String level;
  final String message;
  final StackTrace stackTrace;
}

/// The method by which the flutter app was launched.
class LaunchMode {
  const LaunchMode._(this._value);

  /// The app was launched via `flutter run`.
  static const LaunchMode run = LaunchMode._('run');

  /// The app was launched via `flutter attach`.
  static const LaunchMode attach = LaunchMode._('attach');

  final String _value;

  @override
  String toString() => _value;
}

enum OperationType {
  reload,
  restart
}

/// A queue that debounces operations for a period and merges operations of the same type.
/// Only one action (or any type) will run at a time. Actions of the same type requested
/// in quick succession will be merged together and all return the same result. If an action
/// is requested after an identical action has already started, it will be queued
/// and run again once the first action completes.
class DebounceOperationQueue<T, K> {
  final Map<K, RestartableTimer> _debounceTimers = <K, RestartableTimer>{};
  final Map<K, Future<T>> _operationQueue = <K, Future<T>>{};
  Future<void> _inProgressAction;

  Future<T> queueAndDebounce(
    K operationType,
    Duration debounceDuration,
    Future<T> Function() action,
  ) {
    // If there is already an operation of this type waiting to run, reset its
    // debounce timer and return its future.
    if (_operationQueue[operationType] != null) {
      _debounceTimers[operationType]?.reset();
      return _operationQueue[operationType];
    }

    // Otherwise, put one in the queue with a timer.
    final Completer<T> completer = Completer<T>();
    _operationQueue[operationType] = completer.future;
    _debounceTimers[operationType] = RestartableTimer(
      debounceDuration,
      () async {
        // Remove us from the queue so we can't be reset now we've started.
        unawaited(_operationQueue.remove(operationType));
        _debounceTimers.remove(operationType);

        // No operations should be allowed to run concurrently even if they're
        // different types.
        while (_inProgressAction != null) {
          await _inProgressAction;
        }

        _inProgressAction = action()
            .then(completer.complete, onError: completer.completeError)
            .whenComplete(() => _inProgressAction = null);
      },
    );

    return completer.future;
  }
}

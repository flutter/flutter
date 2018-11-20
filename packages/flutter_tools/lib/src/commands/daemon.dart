// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';

import '../android/android_device.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../device.dart';
import '../emulator.dart';
import '../globals.dart';
import '../ios/devices.dart';
import '../ios/simulators.dart';
import '../resident_runner.dart';
import '../run_cold.dart';
import '../run_hot.dart';
import '../runner/flutter_command.dart';
import '../tester/flutter_tester.dart';
import '../vmservice.dart';

const String protocolVersion = '0.4.2';

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
    printStatus('Starting device daemon...');

    final NotifyingLogger notifyingLogger = NotifyingLogger();

    Cache.releaseLockEarly();

    await context.run<void>(
      body: () async {
        final Daemon daemon = Daemon(
            stdinCommandStream, stdoutCommandResponse,
            daemonCommand: this, notifyingLogger: notifyingLogger);

        final int code = await daemon.onExit;
        if (code != 0)
          throwToolExit('Daemon exited with non-zero exit code: $code', exitCode: code);
      },
      overrides: <Type, Generator>{
        Logger: () => notifyingLogger,
      },
    );
    return null;
  }
}

typedef DispatchCommand = void Function(Map<String, dynamic> command);

typedef CommandHandler = Future<dynamic> Function(Map<String, dynamic> args);

class Daemon {
  Daemon(
    Stream<Map<String, dynamic>> commandStream,
    this.sendCommand, {
    this.daemonCommand,
    this.notifyingLogger,
    this.logToStdout = false,
  }) {
    // Set up domains.
    _registerDomain(daemonDomain = DaemonDomain(this));
    _registerDomain(appDomain = AppDomain(this));
    _registerDomain(deviceDomain = DeviceDomain(this));
    _registerDomain(emulatorDomain = EmulatorDomain(this));

    // Start listening.
    _commandSubscription = commandStream.listen(
      _handleRequest,
      onDone: () {
        if (!_onExitCompleter.isCompleted)
            _onExitCompleter.complete(0);
      }
    );
  }

  DaemonDomain daemonDomain;
  AppDomain appDomain;
  DeviceDomain deviceDomain;
  EmulatorDomain emulatorDomain;
  StreamSubscription<Map<String, dynamic>> _commandSubscription;

  final DispatchCommand sendCommand;
  final DaemonCommand daemonCommand;
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
      stderr.writeln('no id for request: $request');
      return;
    }

    try {
      final String method = request['method'];
      if (!method.contains('.'))
        throw 'method not understood: $method';

      final String prefix = method.substring(0, method.indexOf('.'));
      final String name = method.substring(method.indexOf('.') + 1);
      if (_domainMap[prefix] == null)
        throw 'no domain for method: $method';

      _domainMap[prefix].handleCommand(name, id, request['params'] ?? const <String, dynamic>{});
    } catch (error, trace) {
      _send(<String, dynamic>{
        'id': id,
        'error': _toJsonable(error),
        'trace': '$trace',
      });
    }
  }

  void _send(Map<String, dynamic> map) => sendCommand(map);

  void shutdown({dynamic error}) {
    _commandSubscription?.cancel();
    for (Domain domain in _domainMap.values)
      domain.dispose();
    if (!_onExitCompleter.isCompleted) {
      if (error == null)
        _onExitCompleter.complete(0);
      else
        _onExitCompleter.completeError(error);
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

  FlutterCommand get command => daemon.daemonCommand;

  @override
  String toString() => name;

  void handleCommand(String command, dynamic id, Map<String, dynamic> args) {
    // Remove 'new' once Google catches up to dev4.0 Dart SDK.
    //ignore: unnecessary_new
    new Future<dynamic>.sync(() {
      if (_handlers.containsKey(command))
        return _handlers[command](args);
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

  void sendEvent(String name, [dynamic args]) {
    final Map<String, dynamic> map = <String, dynamic>{ 'event': name };
    if (args != null)
      map['params'] = _toJsonable(args);
    _send(map);
  }

  void _send(Map<String, dynamic> map) => daemon._send(map);

  String _getStringArg(Map<String, dynamic> args, String name, { bool required = false }) {
    if (required && !args.containsKey(name))
      throw '$name is required';
    final dynamic val = args[name];
    if (val != null && val is! String)
      throw '$name is not a String';
    return val;
  }

  bool _getBoolArg(Map<String, dynamic> args, String name, { bool required = false }) {
    if (required && !args.containsKey(name))
      throw '$name is required';
    final dynamic val = args[name];
    if (val != null && val is! bool)
      throw '$name is not a bool';
    return val;
  }

  int _getIntArg(Map<String, dynamic> args, String name, { bool required = false }) {
    if (required && !args.containsKey(name))
      throw '$name is required';
    final dynamic val = args[name];
    if (val != null && val is! int)
      throw '$name is not an int';
    return val;
  }

  void dispose() { }
}

/// This domain responds to methods like [version] and [shutdown].
///
/// This domain fires the `daemon.logMessage` event.
class DaemonDomain extends Domain {
  DaemonDomain(Daemon daemon) : super(daemon, 'daemon') {
    registerHandler('version', version);
    registerHandler('shutdown', shutdown);

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
          stderr.writeln(message.message);
          if (message.stackTrace != null)
            stderr.writeln(message.stackTrace.toString().trimRight());
        }
      } else {
        if (message.stackTrace != null) {
          sendEvent('daemon.logMessage', <String, dynamic>{
            'level': message.level,
            'message': message.message,
            'stackTrace': message.stackTrace.toString()
          });
        } else {
          sendEvent('daemon.logMessage', <String, dynamic>{
            'level': message.level,
            'message': message.message
          });
        }
      }
    });
  }

  StreamSubscription<LogMessage> _subscription;

  Future<String> version(Map<String, dynamic> args) {
    return Future<String>.value(protocolVersion);
  }

  Future<void> shutdown(Map<String, dynamic> args) {
    Timer.run(daemon.shutdown);
    return Future<void>.value();
  }

  @override
  void dispose() {
    _subscription?.cancel();
  }
}

typedef _RunOrAttach = Future<void> Function({
  Completer<DebugConnectionInfo> connectionInfoCompleter,
  Completer<void> appStartedCompleter
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

  static final Uuid _uuidGenerator = Uuid();

  static String _getNewAppId() => _uuidGenerator.generateV4();

  final List<AppInstance> _apps = <AppInstance>[];

  Future<AppInstance> startApp(
    Device device, String projectDirectory, String target, String route,
    DebuggingOptions options, bool enableHotReload, {
    File applicationBinary,
    @required bool trackWidgetCreation,
    String projectRootPath,
    String packagesFilePath,
    String dillOutputPath,
    bool ipv6 = false,
    String isolateFilter,
  }) async {
    if (await device.isLocalEmulator && !options.buildInfo.supportsEmulator) {
      throw '${toTitleCase(options.buildInfo.modeName)} mode is not supported for emulators.';
    }

    // We change the current working directory for the duration of the `start` command.
    final Directory cwd = fs.currentDirectory;
    fs.currentDirectory = fs.directory(projectDirectory);

    final FlutterDevice flutterDevice = FlutterDevice(
      device,
      trackWidgetCreation: trackWidgetCreation,
      dillOutputPath: dillOutputPath,
      viewFilter: isolateFilter,
    );

    ResidentRunner runner;

    if (enableHotReload) {
      runner = HotRunner(
        <FlutterDevice>[flutterDevice],
        target: target,
        debuggingOptions: options,
        usesTerminalUI: false,
        applicationBinary: applicationBinary,
        projectRootPath: projectRootPath,
        packagesFilePath: packagesFilePath,
        dillOutputPath: dillOutputPath,
        ipv6: ipv6,
        hostIsIde: true,
      );
    } else {
      runner = ColdRunner(
        <FlutterDevice>[flutterDevice],
        target: target,
        debuggingOptions: options,
        usesTerminalUI: false,
        applicationBinary: applicationBinary,
        ipv6: ipv6,
      );
    }

    return launch(
        runner,
        ({ Completer<DebugConnectionInfo> connectionInfoCompleter,
            Completer<void> appStartedCompleter }) => runner.run(
                connectionInfoCompleter: connectionInfoCompleter,
                appStartedCompleter: appStartedCompleter,
                route: route),
        device,
        projectDirectory,
        enableHotReload,
        cwd);
  }

  Future<AppInstance> launch(
      ResidentRunner runner,
      _RunOrAttach runOrAttach,
      Device device,
      String projectDirectory,
      bool enableHotReload,
      Directory cwd) async {
    final AppInstance app = AppInstance(_getNewAppId(),
        runner: runner, logToStdout: daemon.logToStdout);
    _apps.add(app);
    _sendAppEvent(app, 'start', <String, dynamic>{
      'deviceId': device.id,
      'directory': projectDirectory,
      'supportsRestart': isRestartSupported(enableHotReload, device),
    });

    Completer<DebugConnectionInfo> connectionInfoCompleter;

    if (runner.debuggingOptions.debuggingEnabled) {
      connectionInfoCompleter = Completer<DebugConnectionInfo>();
      // We don't want to wait for this future to complete and callbacks won't fail.
      // As it just writes to stdout.
      connectionInfoCompleter.future.then<void>((DebugConnectionInfo info) { // ignore: unawaited_futures
        final Map<String, dynamic> params = <String, dynamic>{
          'port': info.httpUri.port,
          'wsUri': info.wsUri.toString(),
        };
        if (info.baseUri != null)
          params['baseUri'] = info.baseUri;
        _sendAppEvent(app, 'debugPort', params);
      });
    }
    final Completer<void> appStartedCompleter = Completer<void>();
    // We don't want to wait for this future to complete and callbacks won't fail.
    // As it just writes to stdout.
    appStartedCompleter.future.then<void>((_) { // ignore: unawaited_futures
      _sendAppEvent(app, 'started');
    });

    await app._runInZone<void>(this, () async {
      try {
        await runOrAttach(
            connectionInfoCompleter: connectionInfoCompleter,
            appStartedCompleter: appStartedCompleter);
        _sendAppEvent(app, 'stop');
      } catch (error, trace) {
        _sendAppEvent(app, 'stop', <String, dynamic>{
          'error': _toJsonable(error),
          'trace': '$trace',
        });
      } finally {
        fs.currentDirectory = cwd;
        _apps.remove(app);
      }
    });
    return app;
  }

  bool isRestartSupported(bool enableHotReload, Device device) =>
      enableHotReload && device.supportsHotRestart;

  Future<OperationResult> _inProgressHotReload;

  Future<OperationResult> restart(Map<String, dynamic> args) async {
    final String appId = _getStringArg(args, 'appId', required: true);
    final bool fullRestart = _getBoolArg(args, 'fullRestart') ?? false;
    final bool pauseAfterRestart = _getBoolArg(args, 'pause') ?? false;
    final String restartReason = _getStringArg(args, 'reason');

    final AppInstance app = _getApp(appId);
    if (app == null)
      throw "app '$appId' not found";

    if (_inProgressHotReload != null)
      throw 'hot restart already in progress';

    _inProgressHotReload = app._runInZone<OperationResult>(this, () {
      return app.restart(fullRestart: fullRestart, pauseAfterRestart: pauseAfterRestart, reason: restartReason);
    });
    return _inProgressHotReload.whenComplete(() {
      _inProgressHotReload = null;
    });
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
    if (app == null)
      throw "app '$appId' not found";

    final Isolate isolate = app.runner.flutterDevices.first.views.first.uiIsolate;
    final Map<String, dynamic> result = await isolate.invokeFlutterExtensionRpcRaw(methodName, params: params);
    if (result == null)
      throw 'method not available: $methodName';

    if (result.containsKey('error'))
      throw result['error'];

    return result;
  }

  Future<bool> stop(Map<String, dynamic> args) async {
    final String appId = _getStringArg(args, 'appId', required: true);

    final AppInstance app = _getApp(appId);
    if (app == null)
      throw "app '$appId' not found";

    return app.stop().timeout(const Duration(seconds: 5)).then<bool>((_) {
      return true;
    }).catchError((dynamic error) {
      _sendAppEvent(app, 'log', <String, dynamic>{ 'log': '$error', 'error': true });
      app.closeLogger();
      _apps.remove(app);
      return false;
    });
  }

  Future<bool> detach(Map<String, dynamic> args) async {
    final String appId = _getStringArg(args, 'appId', required: true);

    final AppInstance app = _getApp(appId);
    if (app == null)
      throw "app '$appId' not found";

    return app.detach().timeout(const Duration(seconds: 5)).then<bool>((_) {
      return true;
    }).catchError((dynamic error) {
      _sendAppEvent(app, 'log', <String, dynamic>{ 'log': '$error', 'error': true });
      app.closeLogger();
      _apps.remove(app);
      return false;
    });
  }

  AppInstance _getApp(String id) {
    return _apps.firstWhere((AppInstance app) => app.id == id, orElse: () => null);
  }

  void _sendAppEvent(AppInstance app, String name, [Map<String, dynamic> args]) {
    final Map<String, dynamic> eventArgs = <String, dynamic> { 'appId': app.id };
    if (args != null)
      eventArgs.addAll(args);
    sendEvent('app.$name', eventArgs);
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

    addDeviceDiscoverer(AndroidDevices());
    addDeviceDiscoverer(IOSDevices());
    addDeviceDiscoverer(IOSSimulators());
    addDeviceDiscoverer(FlutterTesterDevices());
  }

  void addDeviceDiscoverer(PollingDeviceDiscovery discoverer) {
    if (!discoverer.supportsPlatform)
      return;

    if (!discoverer.canListAnything) {
      // This event will affect the client UI. Coordinate changes here
      // with the Flutter IntelliJ team.
      sendEvent(
        'daemon.showMessage',
        <String, String>{
          'level': 'warning',
          'title': 'Unable to list devices',
          'message':
              'Unable to discover ${discoverer.name}. Please run '
              '"flutter doctor" to diagnose potential issues',
        },
      );
    }

    _discoverers.add(discoverer);

    discoverer.onAdded.listen(_onDeviceEvent('device.added'));
    discoverer.onRemoved.listen(_onDeviceEvent('device.removed'));
  }

  Future<void> _serializeDeviceEvents = Future<void>.value();

  _DeviceEventHandler _onDeviceEvent(String eventName) {
    return (Device device) {
      _serializeDeviceEvents = _serializeDeviceEvents.then<void>((_) async {
        sendEvent(eventName, await _deviceToMap(device));
      });
    };
  }

  final List<PollingDeviceDiscovery> _discoverers = <PollingDeviceDiscovery>[];

  Future<List<Device>> getDevices([Map<String, dynamic> args]) async {
    final List<Device> devices = <Device>[];
    for (PollingDeviceDiscovery discoverer in _discoverers) {
      devices.addAll(await discoverer.devices);
    }
    return devices;
  }

  /// Enable device events.
  Future<void> enable(Map<String, dynamic> args) {
    for (PollingDeviceDiscovery discoverer in _discoverers)
      discoverer.startPolling();
    return Future<void>.value();
  }

  /// Disable device events.
  Future<void> disable(Map<String, dynamic> args) {
    for (PollingDeviceDiscovery discoverer in _discoverers)
      discoverer.stopPolling();
    return Future<void>.value();
  }

  /// Forward a host port to a device port.
  Future<Map<String, dynamic>> forward(Map<String, dynamic> args) async {
    final String deviceId = _getStringArg(args, 'deviceId', required: true);
    final int devicePort = _getIntArg(args, 'devicePort', required: true);
    int hostPort = _getIntArg(args, 'hostPort');

    final Device device = await daemon.deviceDomain._getDevice(deviceId);
    if (device == null)
      throw "device '$deviceId' not found";

    hostPort = await device.portForwarder.forward(devicePort, hostPort: hostPort);

    return <String, dynamic>{ 'hostPort': hostPort };
  }

  /// Removes a forwarded port.
  Future<void> unforward(Map<String, dynamic> args) async {
    final String deviceId = _getStringArg(args, 'deviceId', required: true);
    final int devicePort = _getIntArg(args, 'devicePort', required: true);
    final int hostPort = _getIntArg(args, 'hostPort', required: true);

    final Device device = await daemon.deviceDomain._getDevice(deviceId);
    if (device == null)
      throw "device '$deviceId' not found";

    return device.portForwarder.unforward(ForwardedPort(hostPort, devicePort));
  }

  @override
  void dispose() {
    for (PollingDeviceDiscovery discoverer in _discoverers)
      discoverer.dispose();
  }

  /// Return the device matching the deviceId field in the args.
  Future<Device> _getDevice(String deviceId) async {
    for (PollingDeviceDiscovery discoverer in _discoverers) {
      final Device device = (await discoverer.devices).firstWhere((Device device) => device.id == deviceId, orElse: () => null);
      if (device != null)
        return device;
    }
    return null;
  }
}

Stream<Map<String, dynamic>> get stdinCommandStream => stdin
  .transform<String>(utf8.decoder)
  .transform<String>(const LineSplitter())
  .where((String line) => line.startsWith('[{') && line.endsWith('}]'))
  .map<Map<String, dynamic>>((String line) {
    line = line.substring(1, line.length - 1);
    return json.decode(line);
  });

void stdoutCommandResponse(Map<String, dynamic> command) {
  stdout.writeln('[${jsonEncodeObject(command)}]');
}

String jsonEncodeObject(dynamic object) {
  return json.encode(object, toEncodable: _toEncodable);
}

dynamic _toEncodable(dynamic object) {
  if (object is OperationResult)
    return _operationResultToMap(object);
  return object;
}

Future<Map<String, dynamic>> _deviceToMap(Device device) async {
  return <String, dynamic>{
    'id': device.id,
    'name': device.name,
    'platform': getNameForTargetPlatform(await device.targetPlatform),
    'emulator': await device.isLocalEmulator,
  };
}

Map<String, dynamic> _emulatorToMap(Emulator emulator) {
  return <String, dynamic>{
    'id': emulator.id,
    'name': emulator.name,
  };
}

Map<String, dynamic> _operationResultToMap(OperationResult result) {
  final Map<String, dynamic> map = <String, dynamic>{
    'code': result.code,
    'message': result.message,
  };

  if (result.hintMessage != null)
    map['hintMessage'] = result.hintMessage;
  if (result.hintId != null)
    map['hintId'] = result.hintId;

  return map;
}

dynamic _toJsonable(dynamic obj) {
  if (obj is String || obj is int || obj is bool || obj is Map<dynamic, dynamic> || obj is List<dynamic> || obj == null)
    return obj;
  if (obj is OperationResult)
    return obj;
  if (obj is ToolExit)
    return obj.message;
  return '$obj';
}

class NotifyingLogger extends Logger {
  final StreamController<LogMessage> _messageController = StreamController<LogMessage>.broadcast();

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
    _messageController.add(LogMessage('error', message, stackTrace));
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
    _messageController.add(LogMessage('status', message));
  }

  @override
  void printTrace(String message) {
    // This is a lot of traffic to send over the wire.
  }

  @override
  Status startProgress(
    String message, {
    String progressId,
    bool expectSlowOperation = false,
    bool multilineOutput,
    int progressIndicatorPadding = kDefaultStatusPadding,
  }) {
    printStatus(message);
    return Status();
  }

  void dispose() {
    _messageController.close();
  }
}

/// A running application, started by this daemon.
class AppInstance {
  AppInstance(this.id, { this.runner, this.logToStdout = false });

  final String id;
  final ResidentRunner runner;
  final bool logToStdout;

  _AppRunLogger _logger;

  Future<OperationResult> restart({ bool fullRestart = false, bool pauseAfterRestart = false, String reason }) {
    return runner.restart(fullRestart: fullRestart, pauseAfterRestart: pauseAfterRestart, reason: reason);
  }

  Future<void> stop() => runner.stop();
  Future<void> detach() => runner.detach();

  void closeLogger() {
    _logger.close();
  }

  Future<T> _runInZone<T>(AppDomain domain, dynamic method()) {
    _logger ??= _AppRunLogger(domain, this, parent: logToStdout ? logger : null);

    return context.run<T>(
      body: method,
      overrides: <Type, Generator>{
        Logger: () => _logger,
      },
    );
  }
}

/// This domain responds to methods like [getEmulators] and [launch].
class EmulatorDomain extends Domain {
  EmulatorDomain(Daemon daemon) : super(daemon, 'emulator') {
    registerHandler('getEmulators', getEmulators);
    registerHandler('launch', launch);
    registerHandler('create', create);
  }

  EmulatorManager emulators = EmulatorManager();

  Future<List<Map<String, dynamic>>> getEmulators([Map<String, dynamic> args]) async {
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
class _AppRunLogger extends Logger {
  _AppRunLogger(this.domain, this.app, { this.parent });

  AppDomain domain;
  final AppInstance app;
  final Logger parent;
  int _nextProgressId = 0;

  @override
  void printError(
      String message, {
      StackTrace stackTrace,
      bool emphasis,
      TerminalColor color,
      int indent,
      int hangingIndent,
      bool wrap,
    }) {
    if (parent != null) {
      parent.printError(
        message,
        stackTrace: stackTrace,
        emphasis: emphasis,
        indent: indent,
        hangingIndent: hangingIndent,
        wrap: wrap,
      );
    } else {
      if (stackTrace != null) {
        _sendLogEvent(<String, dynamic>{
          'log': message,
          'stackTrace': stackTrace.toString(),
          'error': true
        });
      } else {
        _sendLogEvent(<String, dynamic>{
          'log': message,
          'error': true
        });
      }
    }
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
    if (parent != null) {
      parent.printStatus(
        message,
        emphasis: emphasis,
        color: color,
        newline: newline,
        indent: indent,
        hangingIndent: hangingIndent,
        wrap: wrap,
      );
    } else {
      _sendLogEvent(<String, dynamic>{'log': message});
    }
  }

  @override
  void printTrace(String message) {
    if (parent != null) {
      parent.printTrace(message);
    } else {
      _sendLogEvent(<String, dynamic>{ 'log': message, 'trace': true });
    }
  }

  Status _status;

  @override
  Status startProgress(
    String message, {
    String progressId,
    bool expectSlowOperation = false,
    bool multilineOutput,
    int progressIndicatorPadding = 52,
  }) {
    final int id = _nextProgressId++;

    _sendProgressEvent(<String, dynamic>{
      'id': id.toString(),
      'progressId': progressId,
      'message': message,
    });

    _status = Status(onFinish: () {
      _status = null;
      _sendProgressEvent(<String, dynamic>{
        'id': id.toString(),
        'progressId': progressId,
        'finished': true
      });
    })..start();
    return _status;
  }

  void close() {
    domain = null;
  }

  void _sendLogEvent(Map<String, dynamic> event) {
    if (domain == null)
      printStatus('event sent after app closed: $event');
    else
      domain._sendAppEvent(app, 'log', event);
  }

  void _sendProgressEvent(Map<String, dynamic> event) {
    if (domain == null)
      printStatus('event sent after app closed: $event');
    else
      domain._sendAppEvent(app, 'progress', event);
  }
}

class LogMessage {
  LogMessage(this.level, this.message, [this.stackTrace]);

  final String level;
  final String message;
  final StackTrace stackTrace;
}

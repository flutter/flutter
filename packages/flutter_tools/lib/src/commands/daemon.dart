// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../android/android_device.dart';
import '../base/context.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../device.dart';
import '../globals.dart';
import '../ios/devices.dart';
import '../ios/simulators.dart';
import '../run.dart';
import '../runner/flutter_command.dart';

const String protocolVersion = '0.2.0';

/// A server process command. This command will start up a long-lived server.
/// It reads JSON-RPC based commands from stdin, executes them, and returns
/// JSON-RPC based responses and events to stdout.
///
/// It can be shutdown with a `daemon.shutdown` command (or by killing the
/// process).
class DaemonCommand extends FlutterCommand {
  DaemonCommand({ this.hidden: false });

  @override
  final String name = 'daemon';

  @override
  final String description = 'Run a persistent, JSON-RPC based server to communicate with devices.';

  @override
  bool get requiresProjectRoot => false;

  @override
  final bool hidden;

  @override
  Future<int> runInProject() {
    printStatus('Starting device daemon...');

    AppContext appContext = new AppContext();
    NotifyingLogger notifyingLogger = new NotifyingLogger();
    appContext[Logger] = notifyingLogger;

    return appContext.runInZone(() {
      Stream<Map<String, dynamic>> commandStream = stdin
        .transform(UTF8.decoder)
        .transform(const LineSplitter())
        .where((String line) => line.startsWith('[{') && line.endsWith('}]'))
        .map((String line) {
          line = line.substring(1, line.length - 1);
          return JSON.decode(line);
        });

      Daemon daemon = new Daemon(commandStream, (Map<String, dynamic> command) {
        stdout.writeln('[${JSON.encode(command, toEncodable: _jsonEncodeObject)}]');
      }, daemonCommand: this, notifyingLogger: notifyingLogger);

      return daemon.onExit;
    }, onError: _handleError);
  }

  dynamic _jsonEncodeObject(dynamic object) {
    if (object is Device)
      return _deviceToMap(object);
    return object;
  }

  dynamic _handleError(dynamic error, StackTrace stackTrace) {
    printError('Error from flutter daemon: $error', stackTrace);
    return null;
  }
}

typedef void DispatchComand(Map<String, dynamic> command);

typedef Future<dynamic> CommandHandler(Map<String, dynamic> args);

class Daemon {
  Daemon(Stream<Map<String, dynamic>> commandStream, this.sendCommand, {
    this.daemonCommand,
    this.notifyingLogger
  }) {
    // Set up domains.
    _registerDomain(daemonDomain = new DaemonDomain(this));
    _registerDomain(appDomain = new AppDomain(this));
    _registerDomain(deviceDomain = new DeviceDomain(this));

    // Start listening.
    commandStream.listen(
      (Map<String, dynamic> request) => _handleRequest(request),
      onDone: () => _onExitCompleter.complete(0)
    );
  }

  DaemonDomain daemonDomain;
  AppDomain appDomain;
  DeviceDomain deviceDomain;

  final DispatchComand sendCommand;
  final DaemonCommand daemonCommand;
  final NotifyingLogger notifyingLogger;

  final Completer<int> _onExitCompleter = new Completer<int>();
  final Map<String, Domain> _domainMap = <String, Domain>{};

  void _registerDomain(Domain domain) {
    _domainMap[domain.name] = domain;
  }

  Future<int> get onExit => _onExitCompleter.future;

  void _handleRequest(Map<String, dynamic> request) {
    // {id, method, params}

    // [id] is an opaque type to us.
    dynamic id = request['id'];

    if (id == null) {
      stderr.writeln('no id for request: $request');
      return;
    }

    try {
      String method = request['method'];
      if (method.indexOf('.') == -1)
        throw 'method not understood: $method';

      String prefix = method.substring(0, method.indexOf('.'));
      String name = method.substring(method.indexOf('.') + 1);
      if (_domainMap[prefix] == null)
        throw 'no domain for method: $method';

      _domainMap[prefix].handleCommand(name, id, request['params'] ?? <String, dynamic>{});
    } catch (error) {
      _send(<String, dynamic>{'id': id, 'error': _toJsonable(error)});
    }
  }

  void _send(Map<String, dynamic> map) => sendCommand(map);

  void shutdown() {
    _domainMap.values.forEach((Domain domain) => domain.dispose());
    if (!_onExitCompleter.isCompleted)
      _onExitCompleter.complete(0);
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
    new Future<dynamic>.sync(() {
      if (_handlers.containsKey(command))
        return _handlers[command](args);
      throw 'command not understood: $name.$command';
    }).then((dynamic result) {
      if (result == null) {
        _send(<String, dynamic>{'id': id});
      } else {
        _send(<String, dynamic>{'id': id, 'result': _toJsonable(result)});
      }
    }).catchError((dynamic error, dynamic trace) {
      _send(<String, dynamic>{'id': id, 'error': _toJsonable(error)});
    });
  }

  void sendEvent(String name, [dynamic args]) {
    Map<String, dynamic> map = <String, dynamic>{ 'event': name };
    if (args != null)
      map['params'] = _toJsonable(args);
    _send(map);
  }

  void _send(Map<String, dynamic> map) => daemon._send(map);

  String _getArgAsString(Map<String, dynamic> args, String name, { bool required: false }) {
    if (required && !args.containsKey(name))
      throw "$name is required";
    dynamic val = args[name];
    if (val != null && val is! String)
      throw "$name is not a string";
    return val;
  }

  bool _getArgAsBool(Map<String, dynamic> args, String name, { bool required: false }) {
    if (required && !args.containsKey(name))
      throw "$name is required";
    dynamic val = args[name];
    if (val != null && val is! bool)
      throw "$name is not a boolean";
    return val;
  }

  int _getArgAsInt(Map<String, dynamic> args, String name, { bool required: false }) {
    if (required && !args.containsKey(name))
      throw "$name is required";
    dynamic val = args[name];
    if (val != null && val is! int)
      throw "$name is not an int";
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

    _subscription = daemon.notifyingLogger.onMessage.listen((LogMessage message) {
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
    });
  }

  StreamSubscription<LogMessage> _subscription;

  Future<String> version(Map<String, dynamic> args) {
    return new Future<String>.value(protocolVersion);
  }

  Future<Null> shutdown(Map<String, dynamic> args) {
    Timer.run(() => daemon.shutdown());
    return new Future<Null>.value();
  }

  @override
  void dispose() {
    _subscription?.cancel();
  }
}

/// This domain responds to methods like [start] and [stop].
///
/// It fires events for application start, stop, and stdout and stderr.
class AppDomain extends Domain {
  AppDomain(Daemon daemon) : super(daemon, 'app') {
    registerHandler('start', start);
    registerHandler('restart', restart);
    registerHandler('stop', stop);
    registerHandler('discover', discover);
  }

  static int _nextAppId = 0;

  static String _getNextAppId() => 'app-${_nextAppId++}';

  List<AppInstance> _apps = <AppInstance>[];

  Future<Map<String, dynamic>> start(Map<String, dynamic> args) async {
    String deviceId = _getArgAsString(args, 'deviceId', required: true);
    String projectDirectory = _getArgAsString(args, 'projectDirectory', required: true);
    bool startPaused = _getArgAsBool(args, 'startPaused');
    // TODO(devoncarew): Use the route param.
    String route = _getArgAsString(args, 'route'); // ignore: unused_local_variable
    String mode = _getArgAsString(args, 'mode');
    String target = _getArgAsString(args, 'target');

    Device device = daemon.deviceDomain._getDevice(deviceId);
    if (device == null)
      throw "device '$deviceId' not found";

    if (!FileSystemEntity.isDirectorySync(projectDirectory))
      throw "'$projectDirectory' does not exist";

    BuildMode buildMode = parseBuildMode(mode) ?? BuildMode.debug;
    DebuggingOptions options;

    if (buildMode == BuildMode.release)
      options = new DebuggingOptions.disabled(buildMode);
    else
      options = new DebuggingOptions.enabled(buildMode, startPaused: startPaused);

    // We change the current working directory for the duration of the `start` command.
    Directory cwd = Directory.current;
    Directory.current = new Directory(projectDirectory);

    RunAndStayResident runner = new RunAndStayResident(
      device,
      target: target,
      debuggingOptions: options,
      usesTerminalUI: false
    );

    AppInstance app = new AppInstance(_getNextAppId(), runner);
    _apps.add(app);
    _sendAppEvent(app, 'start', <String, dynamic>{
      'directory': projectDirectory,
      'deviceId': deviceId
    });

    Completer<int> observatoryPortCompleter;

    if (options.debuggingEnabled) {
      observatoryPortCompleter = new Completer<int>();
      observatoryPortCompleter.future.then((int port) {
        _sendAppEvent(app, 'debugPort', <String, dynamic>{ 'port': port });
      });
    }

    app._runInZone(this, () {
      runner.run(observatoryPortCompleter: observatoryPortCompleter).then((_) {
        _sendAppEvent(app, 'stop');
      }).catchError((dynamic error) {
        _sendAppEvent(app, 'stop', <String, dynamic>{ 'error' : error.toString() });
      }).whenComplete(() {
        Directory.current = cwd;
        _apps.remove(app);
      });
    });

    return <String, dynamic>{ 'appId': app.id };
  }

  Future<bool> restart(Map<String, dynamic> args) async {
    String appId = _getArgAsString(args, 'appId', required: true);

    AppInstance app = _getApp(appId);
    if (app == null)
      throw "app '$appId' not found";

    return app._runInZone(this, () {
      return app.restart();
    });
  }

  Future<bool> stop(Map<String, dynamic> args) async {
    String appId = _getArgAsString(args, 'appId', required: true);

    AppInstance app = _getApp(appId);
    if (app == null)
      throw "app '$appId' not found";

    return app.stop().timeout(new Duration(seconds: 5)).then((_) {
      return true;
    }).catchError((dynamic error) {
      _sendAppEvent(app, 'log', <String, dynamic>{ 'log': '$error', 'error': true });
      app.closeLogger();
      _apps.remove(app);
      return false;
    });
  }

  Future<List<Map<String, dynamic>>> discover(Map<String, dynamic> args) async {
    String deviceId = _getArgAsString(args, 'deviceId', required: true);

    Device device = daemon.deviceDomain._getDevice(deviceId);
    if (device == null)
      throw "device '$deviceId' not found";

    List<DiscoveredApp> apps = await device.discoverApps();
    return apps.map((DiscoveredApp app) {
      return <String, dynamic>{
        'id': app.id,
        'observatoryDevicePort': app.observatoryPort
      };
    }).toList();
  }

  AppInstance _getApp(String id) {
    return _apps.firstWhere((AppInstance app) => app.id == id, orElse: () => null);
  }

  void _sendAppEvent(AppInstance app, String name, [Map<String, dynamic> args]) {
    Map<String, dynamic> eventArgs = <String, dynamic> { 'appId': app.id };
    if (args != null)
      eventArgs.addAll(args);
    sendEvent('app.$name', eventArgs);
  }
}

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

    PollingDeviceDiscovery deviceDiscovery = new AndroidDevices();
    if (deviceDiscovery.supportsPlatform)
      _discoverers.add(deviceDiscovery);

    deviceDiscovery = new IOSDevices();
    if (deviceDiscovery.supportsPlatform)
      _discoverers.add(deviceDiscovery);

    deviceDiscovery = new IOSSimulators();
    if (deviceDiscovery.supportsPlatform)
      _discoverers.add(deviceDiscovery);

    for (PollingDeviceDiscovery discoverer in _discoverers) {
      discoverer.onAdded.listen((Device device) {
        sendEvent('device.added', _deviceToMap(device));
      });
      discoverer.onRemoved.listen((Device device) {
        sendEvent('device.removed', _deviceToMap(device));
      });
    }
  }

  List<PollingDeviceDiscovery> _discoverers = <PollingDeviceDiscovery>[];

  Future<List<Device>> getDevices([Map<String, dynamic> args]) {
    List<Device> devices = _discoverers.expand((PollingDeviceDiscovery discoverer) {
      return discoverer.devices;
    }).toList();
    return new Future<List<Device>>.value(devices);
  }

  /// Enable device events.
  Future<Null> enable(Map<String, dynamic> args) {
    for (PollingDeviceDiscovery discoverer in _discoverers)
      discoverer.startPolling();
    return new Future<Null>.value();
  }

  /// Disable device events.
  Future<Null> disable(Map<String, dynamic> args) {
    for (PollingDeviceDiscovery discoverer in _discoverers)
      discoverer.stopPolling();
    return new Future<Null>.value();
  }

  /// Forward a host port to a device port.
  Future<Map<String, dynamic>> forward(Map<String, dynamic> args) async {
    String deviceId = _getArgAsString(args, 'deviceId', required: true);
    int devicePort = _getArgAsInt(args, 'devicePort', required: true);
    int hostPort = _getArgAsInt(args, 'hostPort');

    Device device = daemon.deviceDomain._getDevice(deviceId);
    if (device == null)
      throw "device '$deviceId' not found";

    hostPort = await device.portForwarder.forward(devicePort, hostPort: hostPort);

    return <String, dynamic>{ 'hostPort': hostPort };
  }

  /// Removes a forwarded port.
  Future<Null> unforward(Map<String, dynamic> args) async {
    String deviceId = _getArgAsString(args, 'deviceId', required: true);
    int devicePort = _getArgAsInt(args, 'devicePort', required: true);
    int hostPort = _getArgAsInt(args, 'hostPort', required: true);

    Device device = daemon.deviceDomain._getDevice(deviceId);
    if (device == null)
      throw "device '$deviceId' not found";

    return device.portForwarder.unforward(new ForwardedPort(hostPort, devicePort));
  }

  @override
  void dispose() {
    for (PollingDeviceDiscovery discoverer in _discoverers)
      discoverer.dispose();
  }

  /// Return the device matching the deviceId field in the args.
  Device _getDevice(String deviceId) {
    List<Device> devices = _discoverers.expand((PollingDeviceDiscovery discoverer) {
      return discoverer.devices;
    }).toList();
    return devices.firstWhere((Device device) => device.id == deviceId, orElse: () => null);
  }
}

Map<String, String> _deviceToMap(Device device) {
  return <String, String>{
    'id': device.id,
    'name': device.name,
    'platform': getNameForTargetPlatform(device.platform)
  };
}

dynamic _toJsonable(dynamic obj) {
  if (obj is String || obj is int || obj is bool || obj is Map<dynamic, dynamic> || obj is List<dynamic> || obj == null)
    return obj;
  if (obj is Device)
    return obj;
  return '$obj';
}

class NotifyingLogger extends Logger {
  StreamController<LogMessage> _messageController = new StreamController<LogMessage>.broadcast();

  Stream<LogMessage> get onMessage => _messageController.stream;

  @override
  void printError(String message, [StackTrace stackTrace]) {
    _messageController.add(new LogMessage('error', message, stackTrace));
  }

  @override
  void printStatus(String message, { bool emphasis: false }) {
    _messageController.add(new LogMessage('status', message));
  }

  @override
  void printTrace(String message) {
    // This is a lot of traffic to send over the wire.
  }

  @override
  Status startProgress(String message) {
    printStatus(message);
    return new Status();
  }
}

/// A running application, started by this daemon.
class AppInstance {
  AppInstance(this.id, [this.runner]);

  final String id;
  final RunAndStayResident runner;

  _AppRunLogger _logger;

  Future<bool> restart() => runner.restart();

  Future<Null> stop() => runner.stop();

  void closeLogger() {
    _logger.close();
  }

  dynamic _runInZone(AppDomain domain, dynamic method()) {
    if (_logger == null)
      _logger = new _AppRunLogger(domain, this);

    AppContext appContext = new AppContext();
    appContext[Logger] = _logger;
    return appContext.runInZone(method);
  }
}

/// A [Logger] which sends log messages to a listening daemon client.
class _AppRunLogger extends Logger {
  _AppRunLogger(this.domain, this.app);

  AppDomain domain;
  final AppInstance app;

  @override
  void printError(String message, [StackTrace stackTrace]) {
    if (stackTrace != null) {
      domain?._sendAppEvent(app, 'log', <String, dynamic>{
        'log': message,
        'stackTrace': stackTrace.toString(),
        'error': true
      });
    } else {
      domain?._sendAppEvent(app, 'log', <String, dynamic>{
        'log': message,
        'error': true
      });
    }
  }

  @override
  void printStatus(String message, { bool emphasis: false }) {
    domain?._sendAppEvent(app, 'log', <String, dynamic>{ 'log': message });
  }

  @override
  void printTrace(String message) { }

  @override
  Status startProgress(String message) {
    printStatus(message);
    return new Status();
  }

  void close() {
    domain = null;
  }
}

class LogMessage {
  final String level;
  final String message;
  final StackTrace stackTrace;

  LogMessage(this.level, this.message, [this.stackTrace]);
}

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../android/android_device.dart';
import '../application_package.dart';
import '../base/context.dart';
import '../base/logger.dart';
import '../build_configuration.dart';
import '../device.dart';
import '../globals.dart';
import '../ios/devices.dart';
import '../ios/simulators.dart';
import '../runner/flutter_command.dart';
import 'run.dart';

const String protocolVersion = '0.1.0';

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
    });
  }

  dynamic _jsonEncodeObject(dynamic object) {
    if (object is Device)
      return _deviceToMap(object);
    return object;
  }
}

typedef void DispatchComand(Map<String, dynamic> command);

typedef Future<dynamic> CommandHandler(dynamic args);

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

      _domainMap[prefix].handleCommand(name, id, request['params']);
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

  void handleCommand(String command, dynamic id, dynamic args) {
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

  Future<String> version(dynamic args) {
    return new Future<String>.value(protocolVersion);
  }

  Future<Null> shutdown(dynamic args) {
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
/// It'll be extended to fire events for when applications start, stop, and
/// log data.
class AppDomain extends Domain {
  AppDomain(Daemon daemon) : super(daemon, 'app') {
    registerHandler('start', start);
    registerHandler('stop', stop);
  }

  Future<dynamic> start(Map<String, dynamic> args) async {
    if (args == null || args['deviceId'] is! String)
      throw "deviceId is required";
    Device device = await _getDevice(args['deviceId']);
    if (device == null)
      throw "device '${args['deviceId']}' not found";

    if (args['projectDirectory'] is! String)
      throw "projectDirectory is required";
    String projectDirectory = args['projectDirectory'];
    if (!FileSystemEntity.isDirectorySync(projectDirectory))
      throw "'$projectDirectory' does not exist";

    // We change the current working directory for the duration of the `start` command.
    // TODO(devoncarew): Make flutter_tools work better with commands run from any directory.
    Directory cwd = Directory.current;
    Directory.current = new Directory(projectDirectory);

    try {
      int result = await startApp(
        device,
        stop: true,
        target: args['target'],
        route: args['route']
      );

      if (result != 0)
        throw 'Error starting app: $result';
    } finally {
      Directory.current = cwd;
    }

    return null;
  }

  Future<bool> stop(dynamic args) async {
    if (args == null || args['deviceId'] is! String)
      throw "deviceId is required";
    Device device = await _getDevice(args['deviceId']);
    if (device == null)
      throw "device '${args['deviceId']}' not found";

    if (args['projectDirectory'] is! String)
      throw "projectDirectory is required";
    String projectDirectory = args['projectDirectory'];
    if (!FileSystemEntity.isDirectorySync(projectDirectory))
      throw "'$projectDirectory' does not exist";

    Directory cwd = Directory.current;
    Directory.current = new Directory(projectDirectory);

    try {
      ApplicationPackage app = command.applicationPackages.getPackageForPlatform(device.platform);
      return device.stopApp(app);
    } finally {
      Directory.current = cwd;
    }
  }

  Future<Device> _getDevice(String deviceId) async {
    List<Device> devices = await daemon.deviceDomain.getDevices();
    return devices.firstWhere((Device device) => device.id == deviceId, orElse: () => null);
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

  Future<List<Device>> getDevices([dynamic args]) {
    List<Device> devices = _discoverers.expand((PollingDeviceDiscovery discoverer) {
      return discoverer.devices;
    }).toList();
    return new Future<List<Device>>.value(devices);
  }

  /// Enable device events.
  Future<Null> enable(dynamic args) {
    for (PollingDeviceDiscovery discoverer in _discoverers) {
      discoverer.startPolling();
    }
    return new Future<Null>.value();
  }

  /// Disable device events.
  Future<Null> disable(dynamic args) {
    for (PollingDeviceDiscovery discoverer in _discoverers) {
      discoverer.stopPolling();
    }
    return new Future<Null>.value();
  }

  @override
  void dispose() {
    for (PollingDeviceDiscovery discoverer in _discoverers) {
      discoverer.dispose();
    }
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

class LogMessage {
  final String level;
  final String message;
  final StackTrace stackTrace;

  LogMessage(this.level, this.message, [this.stackTrace]);
}

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../android/adb.dart';
import '../android/device_android.dart';
import '../base/context.dart';
import '../device.dart';
import '../ios/device_ios.dart';
import '../ios/simulator.dart';
import '../runner/flutter_command.dart';
import 'start.dart';
import 'stop.dart' as stop;

const String protocolVersion = '0.1.0';

/// A server process command. This command will start up a long-lived server.
/// It reads JSON-RPC based commands from stdin, executes them, and returns
/// JSON-RPC based responses and events to stdout.
///
/// It can be shutdown with a `daemon.shutdown` command (or by killing the
/// process).
class DaemonCommand extends FlutterCommand {
  final String name = 'daemon';
  final String description = 'Run a persistent, JSON-RPC based server to communicate with devices.';

  bool get requiresProjectRoot => false;

  Future<int> runInProject() {
    printStatus('Starting device daemon...');

    NotifyingAppContext appContext = new NotifyingAppContext();

    return runZoned(() {
      Stream<Map<String, dynamic>> commandStream = stdin
        .transform(UTF8.decoder)
        .transform(const LineSplitter())
        .where((String line) => line.startsWith('[{') && line.endsWith('}]'))
        .map((String line) {
          line = line.substring(1, line.length - 1);
          return JSON.decode(line);
        });

      Daemon daemon = new Daemon(commandStream, (Map command) {
        stdout.writeln('[${JSON.encode(command, toEncodable: _jsonEncodeObject)}]');
      }, daemonCommand: this, appContext: appContext);

      return daemon.onExit;
    }, zoneValues: {'context': appContext});
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
  Daemon(Stream<Map> commandStream, this.sendCommand, {
    this.daemonCommand,
    this.appContext
  }) {
    // Set up domains.
    _registerDomain(new DaemonDomain(this));
    _registerDomain(new AppDomain(this));
    _registerDomain(new DeviceDomain(this));

    // Start listening.
    commandStream.listen(
      (Map request) => _handleRequest(request),
      onDone: () => _onExitCompleter.complete(0)
    );
  }

  final DispatchComand sendCommand;
  final DaemonCommand daemonCommand;
  final NotifyingAppContext appContext;

  final Completer<int> _onExitCompleter = new Completer<int>();
  final Map<String, Domain> _domainMap = <String, Domain>{};

  void _registerDomain(Domain domain) {
    _domainMap[domain.name] = domain;
  }

  Future<int> get onExit => _onExitCompleter.future;

  void _handleRequest(Map request) {
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
    } catch (error, trace) {
      _send({'id': id, 'error': _toJsonable(error)});
      stderr.writeln('error handling $request: $error');
      stderr.writeln(trace);
    }
  }

  void _send(Map map) => sendCommand(map);

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
  final Map<String, CommandHandler> _handlers = {};

  void registerHandler(String name, CommandHandler handler) {
    _handlers[name] = handler;
  }

  FlutterCommand get command => daemon.daemonCommand;

  String toString() => name;

  void handleCommand(String command, dynamic id, dynamic args) {
    new Future.sync(() {
      if (_handlers.containsKey(command))
        return _handlers[command](args);
      throw 'command not understood: $name.$command';
    }).then((result) {
      if (result == null) {
        _send({'id': id});
      } else {
        _send({'id': id, 'result': _toJsonable(result)});
      }
    }).catchError((error, trace) {
      _send({'id': id, 'error': _toJsonable(error)});
      stderr.writeln("error handling '$name.$command': $error");
      stderr.writeln(trace);
    });
  }

  void sendEvent(String name, [dynamic args]) {
    Map<String, dynamic> map = { 'event': name };
    if (args != null)
      map['params'] = _toJsonable(args);
    _send(map);
  }

  void _send(Map map) => daemon._send(map);

  void dispose() { }
}

/// This domain responds to methods like [version] and [shutdown].
///
/// This domain fires the `daemon.logMessage` event.
class DaemonDomain extends Domain {
  DaemonDomain(Daemon daemon) : super(daemon, 'daemon') {
    registerHandler('version', version);
    registerHandler('shutdown', shutdown);

    _subscription = daemon.appContext.onMessage.listen((LogMessage message) {
      if (message.stackTrace != null) {
        sendEvent('daemon.logMessage', {
          'level': message.level,
          'message': message.message,
          'stackTrace': message.stackTrace.toString()
        });
      } else {
        sendEvent('daemon.logMessage', {
          'level': message.level,
          'message': message.message
        });
      }
    });
  }

  StreamSubscription<LogMessage> _subscription;

  Future<String> version(dynamic args) {
    return new Future.value(protocolVersion);
  }

  Future shutdown(dynamic args) {
    Timer.run(() => daemon.shutdown());
    return new Future.value();
  }

  void dispose() {
    _subscription?.cancel();
  }
}

/// This domain responds to methods like [start] and [stopAll].
///
/// It'll be extended to fire events for when applications start, stop, and
/// log data.
class AppDomain extends Domain {
  AppDomain(Daemon daemon) : super(daemon, 'app') {
    registerHandler('start', start);
    registerHandler('stopAll', stopAll);
  }

  Future<dynamic> start(Map<String, dynamic> args) async {
    // TODO(devoncarew): We need to be able to specify the target device.

    if (args['projectDirectory'] is! String)
      throw "A 'projectDirectory' is required";

    String projectDirectory = args['projectDirectory'];
    if (!FileSystemEntity.isDirectorySync(projectDirectory))
      throw "The '$projectDirectory' does not exist";

    // We change the current working directory for the duration of the `start`
    // command. This would have race conditions with other commands happening in
    // parallel and doesn't play well with the caching built into `FlutterCommand`.
    // TODO(devoncarew): Make flutter_tools work better with commands run from any directory.
    // TODO(devoncarew): Use less (or more explicit) caching.
    Directory cwd = Directory.current;
    Directory.current = new Directory(projectDirectory);

    try {
      await Future.wait([
        command.downloadToolchain(),
        command.downloadApplicationPackagesAndConnectToDevices(),
      ], eagerError: true);

      int result = await startApp(
        command.devices,
        command.applicationPackages,
        command.toolchain,
        command.buildConfigurations,
        target: args['target'],
        route: args['route'],
        checked: args['checked'] ?? true
      );

      if (result != 0)
        throw 'Error starting app: $result';
    } finally {
      Directory.current = cwd;
    }

    return null;
  }

  Future<bool> stopAll(dynamic args) {
    return stop.stopAll(command.devices, command.applicationPackages);
  }
}

/// This domain lets callers list and monitor connected devices.
///
/// It exports a `getDevices()` call, as well as firing `device.added`,
/// `device.removed`, and `device.changed` events.
class DeviceDomain extends Domain {
  DeviceDomain(Daemon daemon) : super(daemon, 'device') {
    registerHandler('getDevices', getDevices);

    _androidDeviceDiscovery = new AndroidDeviceDiscovery();
    _androidDeviceDiscovery.onAdded.listen((Device device) {
      sendEvent('device.added', _deviceToMap(device));
    });
    _androidDeviceDiscovery.onRemoved.listen((Device device) {
      sendEvent('device.removed', _deviceToMap(device));
    });
    _androidDeviceDiscovery.onChanged.listen((Device device) {
      sendEvent('device.changed', _deviceToMap(device));
    });

    if (Platform.isMacOS) {
      _iosSimulatorDeviceDiscovery = new IOSSimulatorDeviceDiscovery();
      _iosSimulatorDeviceDiscovery.onAdded.listen((Device device) {
        sendEvent('device.added', _deviceToMap(device));
      });
      _iosSimulatorDeviceDiscovery.onRemoved.listen((Device device) {
        sendEvent('device.removed', _deviceToMap(device));
      });
    }
  }

  AndroidDeviceDiscovery _androidDeviceDiscovery;
  IOSSimulatorDeviceDiscovery _iosSimulatorDeviceDiscovery;

  Future<List<Device>> getDevices(dynamic args) {
    List<Device> devices = <Device>[];
    devices.addAll(_androidDeviceDiscovery.getDevices());
    if (_iosSimulatorDeviceDiscovery != null)
      devices.addAll(_iosSimulatorDeviceDiscovery.getDevices());
    return new Future.value(devices);
  }

  void dispose() {
    _androidDeviceDiscovery.dispose();
    _iosSimulatorDeviceDiscovery?.dispose();
  }
}

class AndroidDeviceDiscovery {
  AndroidDeviceDiscovery() {
    _initAdb();

    if (_adb != null) {
      _subscription = _adb.trackDevices().listen(_handleUpdatedDevices);
    }
  }

  Adb _adb;
  StreamSubscription _subscription;
  Map<String, AndroidDevice> _devices = new Map<String, AndroidDevice>();

  StreamController<Device> addedController = new StreamController<Device>.broadcast();
  StreamController<Device> removedController = new StreamController<Device>.broadcast();
  StreamController<Device> changedController = new StreamController<Device>.broadcast();

  List<Device> getDevices() => _devices.values.toList();

  Stream<Device> get onAdded => addedController.stream;
  Stream<Device> get onRemoved => removedController.stream;
  Stream<Device> get onChanged => changedController.stream;

  void _initAdb() {
    if (_adb == null) {
      _adb = new Adb(getAdbPath());
      if (!_adb.exists())
        _adb = null;
    }
  }

  void _handleUpdatedDevices(List<AdbDevice> newDevices) {
    List<AndroidDevice> currentDevices = new List.from(getDevices());

    for (AdbDevice device in newDevices) {
      AndroidDevice androidDevice = _devices[device.id];

      if (androidDevice == null) {
        // device added
        androidDevice = new AndroidDevice(
          device.id,
          productID: device.productID,
          modelID: device.modelID,
          deviceCodeName: device.deviceCodeName,
          connected: device.isAvailable
        );
        _devices[androidDevice.id] = androidDevice;
        addedController.add(androidDevice);
      } else {
        currentDevices.remove(androidDevice);

        // check state
        if (androidDevice.isConnected() != device.isAvailable) {
          androidDevice.setConnected(device.isAvailable);
          changedController.add(androidDevice);
        }
      }
    }

    // device removed
    for (AndroidDevice device in currentDevices) {
      _devices.remove(device.id);

      removedController.add(device);
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

class IOSSimulatorDeviceDiscovery {
  IOSSimulatorDeviceDiscovery() {
    _subscription = SimControl.trackDevices().listen(_handleUpdatedDevices);
  }

  StreamSubscription<List<SimDevice>> _subscription;

  Map<String, IOSSimulator> _devices = new Map<String, IOSSimulator>();

  StreamController<Device> addedController = new StreamController<Device>.broadcast();
  StreamController<Device> removedController = new StreamController<Device>.broadcast();

  List<Device> getDevices() => _devices.values.toList();

  Stream<Device> get onAdded => addedController.stream;
  Stream<Device> get onRemoved => removedController.stream;

  void _handleUpdatedDevices(List<SimDevice> newDevices) {
    List<IOSSimulator> currentDevices = new List.from(getDevices());

    for (SimDevice device in newDevices) {
      IOSSimulator androidDevice = _devices[device.udid];

      if (androidDevice == null) {
        // device added
        androidDevice = new IOSSimulator(device.udid, name: device.name);
        _devices[androidDevice.id] = androidDevice;
        addedController.add(androidDevice);
      } else {
        currentDevices.remove(androidDevice);
      }
    }

    // device removed
    for (IOSSimulator device in currentDevices) {
      _devices.remove(device.id);

      removedController.add(device);
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

Map<String, dynamic> _deviceToMap(Device device) {
  return <String, dynamic>{
    'id': device.id,
    'name': device.name,
    'platform': _enumToString(device.platform),
    'available': device.isConnected()
  };
}

/// Take an enum value and get the best string representation of that.
///
/// toString() on enums returns 'EnumType.enumName'.
String _enumToString(dynamic enumValue) {
  String str = '$enumValue';
  if (str.contains('.'))
    return str.substring(str.indexOf('.') + 1);
  return str;
}

dynamic _toJsonable(dynamic obj) {
  if (obj is String || obj is int || obj is bool || obj is Map || obj is List || obj == null)
    return obj;
  if (obj is Device)
    return obj;
  return '$obj';
}

class NotifyingAppContext implements AppContext {
  StreamController<LogMessage> _messageController = new StreamController<LogMessage>.broadcast();

  Stream<LogMessage> get onMessage => _messageController.stream;

  bool verbose = false;

  void printError(String message, [StackTrace stackTrace]) {
    _messageController.add(new LogMessage('error', message, stackTrace));
  }

  void printStatus(String message) {
    _messageController.add(new LogMessage('status', message));
  }

  void printTrace(String message) {
    _messageController.add(new LogMessage('trace', message));
  }
}

class LogMessage {
  final String level;
  final String message;
  final StackTrace stackTrace;

  LogMessage(this.level, this.message, [this.stackTrace]);
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import '../application_package.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../convert.dart';
import '../daemon.dart';
import '../device.dart';
import '../device_port_forwarder.dart';
import '../project.dart';

bool _isNullable<T>() => null is T;

T _cast<T>(Object? object) {
  if (!_isNullable<T>() && object == null) {
    throw Exception('Expected $T, received null!');
  } else {
    return object as T;
  }
}

/// A [DeviceDiscovery] that will connect to a flutter daemon and connects to
/// the devices remotely.
class ProxiedDevices extends DeviceDiscovery {
  ProxiedDevices(this.connection, {
    required Logger logger,
  }) : _logger = logger;

  /// [DaemonConnection] used to communicate with the daemon.
  final DaemonConnection connection;

  final Logger _logger;

  @override
  bool get supportsPlatform => true;

  @override
  bool get canListAnything => true;

  List<Device>? _devices;

  @override
  Future<List<Device>> get devices async =>
      _devices ?? await discoverDevices();

  @override
  Future<List<Device>> discoverDevices({Duration? timeout}) async {
    final List<Map<String, Object?>> discoveredDevices = _cast<List<dynamic>>(await connection.sendRequest('device.discoverDevices')).cast<Map<String, Object?>>();
    final List<ProxiedDevice> devices = <ProxiedDevice>[
      for (final Map<String, Object?> device in discoveredDevices)
        _deviceFromDaemonResult(device),
    ];

    _devices = devices;
    return devices;
  }

  @override
  List<String> get wellKnownIds => const <String>[];

  ProxiedDevice _deviceFromDaemonResult(Map<String, Object?> device) {
    final Map<String, Object?> capabilities = _cast<Map<String, Object?>>(device['capabilities']);
    return ProxiedDevice(
      connection, _cast<String>(device['id']),
      category: Category.fromString(_cast<String>(device['category'])),
      platformType: PlatformType.fromString(_cast<String>(device['platformType'])),
      targetPlatform: getTargetPlatformForName(_cast<String>(device['platform'])),
      ephemeral: _cast<bool>(device['ephemeral']),
      name: 'Proxied ${device['name']}',
      isLocalEmulator: _cast<bool>(device['emulator']),
      emulatorId: _cast<String?>(device['emulatorId']),
      sdkNameAndVersion: _cast<String>(device['sdk']),
      supportsHotReload: _cast<bool>(capabilities['hotReload']),
      supportsHotRestart: _cast<bool>(capabilities['hotRestart']),
      supportsFlutterExit: _cast<bool>(capabilities['flutterExit']),
      supportsScreenshot: _cast<bool>(capabilities['screenshot']),
      supportsFastStart: _cast<bool>(capabilities['fastStart']),
      supportsHardwareRendering: _cast<bool>(capabilities['hardwareRendering']),
      logger: _logger,
    );
  }
}

/// A [Device] that acts as a proxy to remotely connected device.
///
/// The communication happens via a flutter daemon.
class ProxiedDevice extends Device {
  ProxiedDevice(this.connection, String id, {
    required Category? category,
    required PlatformType? platformType,
    required TargetPlatform targetPlatform,
    required bool ephemeral,
    required this.name,
    required bool isLocalEmulator,
    required String? emulatorId,
    required String sdkNameAndVersion,
    required this.supportsHotReload,
    required this.supportsHotRestart,
    required this.supportsFlutterExit,
    required this.supportsScreenshot,
    required this.supportsFastStart,
    required bool supportsHardwareRendering,
    required Logger logger,
  }): _isLocalEmulator = isLocalEmulator,
      _emulatorId = emulatorId,
      _sdkNameAndVersion = sdkNameAndVersion,
      _supportsHardwareRendering = supportsHardwareRendering,
      _targetPlatform = targetPlatform,
      _logger = logger,
      super(id,
        category: category,
        platformType: platformType,
        ephemeral: ephemeral);

  /// [DaemonConnection] used to communicate with the daemon.
  final DaemonConnection connection;

  final Logger _logger;

  @override
  final String name;

  final bool _isLocalEmulator;
  @override
  Future<bool> get isLocalEmulator async => _isLocalEmulator;

  final String? _emulatorId;
  @override
  Future<String?> get emulatorId async => _emulatorId;

  @override
  Future<bool> supportsRuntimeMode(BuildMode buildMode) async =>
     _cast<bool>(await connection.sendRequest('device.supportsRuntimeMode', <String, Object>{
      'deviceId': id,
      'buildMode': buildMode.toString(),
    }));

  final bool _supportsHardwareRendering;
  @override
  Future<bool> get supportsHardwareRendering async => _supportsHardwareRendering;

  // ProxiedDevice is intended to be used with prebuilt projects. No building
  // is required, so we returns true for all projects.
  @override
  bool isSupportedForProject(FlutterProject flutterProject) => true;

  @override
  Future<bool> isAppInstalled(
    covariant ApplicationPackage app, {
    String? userIdentifier,
  }) => throw UnimplementedError();

  @override
  Future<bool> isLatestBuildInstalled(covariant ApplicationPackage app) => throw UnimplementedError();

  @override
  Future<bool> installApp(
    covariant ApplicationPackage app, {
    String? userIdentifier,
  }) => throw UnimplementedError();

  @override
  Future<bool> uninstallApp(
    covariant ApplicationPackage app, {
    String? userIdentifier,
  }) => throw UnimplementedError();

  @override
  bool isSupported() => true;

  final TargetPlatform _targetPlatform;
  @override
  Future<TargetPlatform> get targetPlatform async => _targetPlatform;
  TargetPlatform get targetPlatformSync => _targetPlatform;

  final String _sdkNameAndVersion;
  @override
  Future<String> get sdkNameAndVersion async => _sdkNameAndVersion;

  @override
  FutureOr<DeviceLogReader> getLogReader({
    covariant PrebuiltApplicationPackage? app,
    bool includePastLogs = false,
  }) => _ProxiedLogReader(connection, this, app);

  _ProxiedPortForwarder? _proxiedPortForwarder;
  _ProxiedPortForwarder get proxiedPortForwarder => _proxiedPortForwarder ??= _ProxiedPortForwarder(connection, logger: _logger);

  @override
  DevicePortForwarder get portForwarder => throw UnimplementedError();

  @override
  void clearLogs() => throw UnimplementedError();

  @override
  Future<LaunchResult> startApp(
    covariant PrebuiltApplicationPackage package, {
    String? mainPath,
    String? route,
    required DebuggingOptions debuggingOptions,
    Map<String, Object?> platformArgs = const <String, Object?>{},
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String? userIdentifier,
  }) async {
    final Map<String, Object?> result = _cast<Map<String, Object?>>(await connection.sendRequest('device.startApp', <String, Object?>{
      'deviceId': id,
      'applicationPackageId': await applicationPackageId(package),
      'mainPath': mainPath,
      'route': route,
      'debuggingOptions': debuggingOptions.toJson(),
      'platformArgs': platformArgs,
      'prebuiltApplication': prebuiltApplication,
      'ipv6': ipv6,
      'userIdentifier': userIdentifier,
    }));
    final bool started = _cast<bool>(result['started']);
    final String? observatoryUriStr = _cast<String?>(result['observatoryUri']);
    final Uri? observatoryUri = observatoryUriStr == null ? null : Uri.parse(observatoryUriStr);
    if (started) {
      if (observatoryUri != null) {
        final int hostPort = await proxiedPortForwarder.forward(observatoryUri.port);
        return LaunchResult.succeeded(observatoryUri: observatoryUri.replace(port: hostPort));
      } else {
        return LaunchResult.succeeded();
      }
    } else {
      return LaunchResult.failed();
    }
  }

  @override
  final bool supportsHotReload;

  @override
  final bool supportsHotRestart;

  @override
  final bool supportsFlutterExit;

  @override
  final bool supportsScreenshot;

  @override
  final bool supportsFastStart;

  @override
  Future<bool> stopApp(
    covariant PrebuiltApplicationPackage app, {
    String? userIdentifier,
  }) async {
    return _cast<bool>(await connection.sendRequest('device.stopApp', <String, Object?>{
      'deviceId': id,
      'applicationPackageId': await applicationPackageId(app),
      'userIdentifier': userIdentifier,
    }));
  }

  @override
  Future<MemoryInfo> queryMemoryInfo() => throw UnimplementedError();

  @override
  Future<void> takeScreenshot(File outputFile) async {
    final String imageBase64 = _cast<String>(await connection.sendRequest('device.takeScreenshot', <String, Object?>{
      'deviceId': id,
    }));
    await outputFile.writeAsBytes(base64.decode(imageBase64));
  }

  @override
  Future<void> dispose() async {}

  final Map<String, Future<String>> _applicationPackageMap = <String, Future<String>>{};
  Future<String> applicationPackageId(PrebuiltApplicationPackage package) async {
    final File binary = package.applicationPackage as File;
    final String path = binary.absolute.path;
    if (_applicationPackageMap.containsKey(path)) {
      return _applicationPackageMap[path]!;
    }
    final String fileName = binary.basename;
    final Completer<String> idCompleter = Completer<String>();
    _applicationPackageMap[path] = idCompleter.future;
    await connection.sendRequest('proxy.writeTempFile', <String, Object>{
      'path': fileName,
    }, await binary.readAsBytes());
    final String id = _cast<String>(await connection.sendRequest('device.uploadApplicationPackage', <String, Object>{
      'targetPlatform': getNameForTargetPlatform(_targetPlatform),
      'applicationBinary': fileName,
    }));
    idCompleter.complete(id);
    return id;
  }
}

/// A [DeviceLogReader] for a proxied device.
class _ProxiedLogReader extends DeviceLogReader {
  _ProxiedLogReader(this.connection, this.device, this.applicationPackage);

  final DaemonConnection connection;
  final ProxiedDevice device;
  final PrebuiltApplicationPackage? applicationPackage;

  @override
  String get name => device.name;

  final StreamController<String> _logLinesStreamController = StreamController<String>();
  Stream<String>? _logLines;

  String? _id;

  @override
  Stream<String> get logLines => _logLines ??= _start();

  Stream<String> _start() {
    final PrebuiltApplicationPackage? package = applicationPackage;
    final Future<String?> applicationPackageId = package != null ? device.applicationPackageId(package) : Future<String?>.value();
    final Future<String> idFuture = applicationPackageId.then((String? applicationPackageId) async =>
       _cast<String>(await connection.sendRequest('device.logReader.start', <String, Object>{
        'deviceId': device.id,
        if (applicationPackageId != null)
          'applicationPackageId': applicationPackageId,
      })));
    idFuture.then((String id) {
      _id = id;
      final Stream<String> stream = connection.listenToEvent('device.logReader.logLines.$_id').map((DaemonEventData event) => event.data! as String);
      _logLinesStreamController.addStream(stream);
    });
    return _logLinesStreamController.stream;
  }

  @override
  void dispose() {
    if (_id != null) {
      connection.sendRequest('device.logReader.stop', <String, Object?>{
        'id': _id,
      });
    }
  }
}

/// A [DevicePortForwarder] for a proxied device.
class _ProxiedPortForwarder extends DevicePortForwarder {
  _ProxiedPortForwarder(this.connection, {
    required Logger logger,
  }) : _logger = logger;

  DaemonConnection connection;

  final Logger _logger;

  @override
  final List<ForwardedPort> forwardedPorts = <ForwardedPort>[];

  final List<Socket> _connectedSockets = <Socket>[];

  final Map<int, ServerSocket> _serverSockets = <int, ServerSocket>{};

  @override
  Future<int> forward(int devicePort, { int? hostPort }) async {
    final ServerSocket serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, hostPort ?? 0);

    _serverSockets[serverSocket.port] = serverSocket;
    forwardedPorts.add(ForwardedPort(serverSocket.port, devicePort));

    serverSocket.listen((Socket socket) async {
      final String id = _cast<String>(await connection.sendRequest('proxy.connect', <String, Object>{
        'port': devicePort,
      }));
      final Stream<List<int>> dataStream = connection.listenToEvent('proxy.data.$id').asyncExpand((DaemonEventData event) => event.binary);
      dataStream.listen(socket.add);
      final Future<DaemonEventData> disconnectFuture = connection.listenToEvent('proxy.disconnected.$id').first;
      unawaited(disconnectFuture.then((_) {
        socket.close();
      }));
      socket.listen((Uint8List data) {
        connection.sendRequest('proxy.write', <String, Object>{
          'id': id,
        }, data);
      });
      _connectedSockets.add(socket);

      unawaited(socket.done.then((dynamic value) {
        connection.sendRequest('proxy.disconnect', <String, Object>{
          'id': id,
        });
        _connectedSockets.remove(socket);
      }).onError((Object? error, StackTrace stackTrace) {
        connection.sendRequest('proxy.disconnect', <String, Object>{
          'id': id,
        });
        _connectedSockets.remove(socket);
      }));
    }, onError: (Object error, StackTrace stackTrace) {
      _logger.printWarning('Server socket error: $error');
      _logger.printTrace('Server socket error: $error, stack trace: $stackTrace');
    });
    return serverSocket.port;
  }

  @override
  Future<void> unforward(ForwardedPort forwardedPort) async {
    if (!forwardedPorts.remove(forwardedPort)) {
      // Not in list. Nothing to remove.
      return;
    }

    forwardedPort.dispose();

    final ServerSocket? serverSocket = _serverSockets.remove(forwardedPort.hostPort);
    await serverSocket?.close();
  }

  @override
  Future<void> dispose() async {
    for (final ForwardedPort forwardedPort in forwardedPorts) {
      forwardedPort.dispose();
    }

    for (final ServerSocket serverSocket in _serverSockets.values) {
      await serverSocket.close();
    }

    for (final Socket socket in _connectedSockets) {
      await socket.close();
    }
  }
}

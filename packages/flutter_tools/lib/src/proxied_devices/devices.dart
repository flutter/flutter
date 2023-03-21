// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../convert.dart';
import '../daemon.dart';
import '../device.dart';
import '../device_port_forwarder.dart';
import '../project.dart';
import 'file_transfer.dart';

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
///
/// If [deltaFileTransfer] is true, the proxy will use an rsync-like algorithm that
/// only transfers the changed part of the application package for deployment.
class ProxiedDevices extends DeviceDiscovery {
  ProxiedDevices(this.connection, {
    bool deltaFileTransfer = true,
    required Logger logger,
  }) : _deltaFileTransfer = deltaFileTransfer,
       _logger = logger;

  /// [DaemonConnection] used to communicate with the daemon.
  final DaemonConnection connection;

  final Logger _logger;

  final bool _deltaFileTransfer;

  @override
  bool get supportsPlatform => true;

  @override
  bool get canListAnything => true;

  List<Device>? _devices;

  @override
  Future<List<Device>> devices({DeviceDiscoveryFilter? filter}) async =>
      _filterDevices(_devices ?? await discoverDevices(), filter);

  @override
  Future<List<Device>> discoverDevices({
    Duration? timeout,
    DeviceDiscoveryFilter? filter
  }) async {
    final List<Map<String, Object?>> discoveredDevices = _cast<List<dynamic>>(await connection.sendRequest('device.discoverDevices')).cast<Map<String, Object?>>();
    final List<ProxiedDevice> devices = <ProxiedDevice>[
      for (final Map<String, Object?> device in discoveredDevices)
        deviceFromDaemonResult(device),
    ];

    _devices = devices;
    return _filterDevices(devices, filter);
  }

  Future<List<Device>> _filterDevices(List<Device> devices, DeviceDiscoveryFilter? filter) async {
    if (filter == null) {
      return devices;
    }
    return filter.filterDevices(devices);
  }

  @override
  List<String> get wellKnownIds => const <String>[];

  @visibleForTesting
  ProxiedDevice deviceFromDaemonResult(Map<String, Object?> device) {
    final Map<String, Object?> capabilities = _cast<Map<String, Object?>>(device['capabilities']);
    return ProxiedDevice(
      connection, _cast<String>(device['id']),
      deltaFileTransfer: _deltaFileTransfer,
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
///
/// If [deltaFileTransfer] is true, the proxy will use an rsync-like algorithm that
/// only transfers the changed part of the application package for deployment.
class ProxiedDevice extends Device {
  ProxiedDevice(this.connection, String id, {
    bool deltaFileTransfer = true,
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
  }): _deltaFileTransfer = deltaFileTransfer,
      _isLocalEmulator = isLocalEmulator,
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

  final bool _deltaFileTransfer;

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
    ApplicationPackage app, {
    String? userIdentifier,
  }) => throw UnimplementedError();

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) => throw UnimplementedError();

  @override
  Future<bool> installApp(
    ApplicationPackage app, {
    String? userIdentifier,
  }) => throw UnimplementedError();

  @override
  Future<bool> uninstallApp(
    ApplicationPackage app, {
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

  ProxiedPortForwarder? _proxiedPortForwarder;
  /// [proxiedPortForwarder] forwards a port from the remote host to local host.
  ProxiedPortForwarder get proxiedPortForwarder => _proxiedPortForwarder ??= ProxiedPortForwarder(connection, logger: _logger);

  DevicePortForwarder? _portForwarder;
  /// [portForwarder] forwards a port from the remote device to remote host, and
  /// then forward the port from remote host to local host.
  @override
  DevicePortForwarder get portForwarder => _portForwarder ??= ProxiedPortForwarder(connection, deviceId: id, logger: _logger);

  @override
  void clearLogs() => throw UnimplementedError();

  @override
  Future<LaunchResult> startApp(
    PrebuiltApplicationPackage package, {
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
    // TODO(bkonyi): remove once clients have migrated to relying on vmServiceUri.
    final String? vmServiceUriStr = _cast<String?>(result['vmServiceUri']) ?? _cast<String?>(result['observatoryUri']);
    final Uri? vmServiceUri = vmServiceUriStr == null ? null : Uri.parse(vmServiceUriStr);
    if (started) {
      if (vmServiceUri != null) {
        final int hostPort = await proxiedPortForwarder.forward(vmServiceUri.port);
        return LaunchResult.succeeded(vmServiceUri: vmServiceUri.replace(port: hostPort));
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
    covariant PrebuiltApplicationPackage? app, {
    String? userIdentifier,
  }) async {
    return _cast<bool>(await connection.sendRequest('device.stopApp', <String, Object?>{
      'deviceId': id,
      if (app != null)
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

    final Map<String, Object> args = <String, Object>{'path': fileName};

    Map<String, Object?>? rollingHashResultJson;
    if (_deltaFileTransfer) {
     rollingHashResultJson = _cast<Map<String, Object?>?>(await connection.sendRequest('proxy.calculateFileHashes', args));
    }

    if (rollingHashResultJson == null) {
      // Either file not found on the remote end, or deltaFileTransfer is set to false, transfer the file directly.
      if (_deltaFileTransfer) {
        _logger.printTrace('Delta file transfer is enabled but file is not found on the remote end, do a full transfer.');
      }

      await connection.sendRequest('proxy.writeTempFile', args, await binary.readAsBytes());
    } else {
      final BlockHashes rollingHashResult = BlockHashes.fromJson(rollingHashResultJson);
      final List<FileDeltaBlock> delta = await FileTransfer().computeDelta(binary, rollingHashResult);

      // Delta is empty if the file does not need to be updated
      if (delta.isNotEmpty) {
        final List<Map<String, Object>> deltaJson = delta.map((FileDeltaBlock block) => block.toJson()).toList();
        final Uint8List buffer = await FileTransfer().binaryForRebuilding(binary, delta);

        await connection.sendRequest('proxy.updateFile', <String, Object>{
          'path': fileName,
          'delta': deltaJson,
        }, buffer);
      }
    }

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

/// A port forwarded by a [ProxiedPortForwarder].
class _ProxiedForwardedPort extends ForwardedPort {
  _ProxiedForwardedPort(this.connection, {
    required int hostPort,
    required int devicePort,
    required this.remoteDevicePort,
    required this.deviceId,
    required this.serverSocket
  }): super(hostPort, devicePort);

  /// [DaemonConnection] used to communicate with the daemon.
  final DaemonConnection connection;

  /// The forwarded port on the remote device.
  final int? remoteDevicePort;

  /// The device identifier of the remote device.
  final String? deviceId;

  /// The [ServerSocket] that is serving the local forwarded port.
  final ServerSocket serverSocket;

  @override
  void dispose() {
    unforward();
  }

  /// Unforwards the remote port, and stops the local server.
  Future<void> unforward() async {
    await serverSocket.close();

    if (remoteDevicePort != null && deviceId != null) {
      await connection.sendRequest('device.unforward', <String, Object>{
        'deviceId': deviceId!,
        'devicePort': remoteDevicePort!,
        'hostPort': devicePort,
      });
    }
  }
}

typedef CreateSocketServer = Future<ServerSocket> Function(Logger logger, int? hostPort);

/// A [DevicePortForwarder] for a proxied device.
///
/// If [deviceId] is not null, the port forwarder forwards ports from the remote
/// device, to the remote host, and then to the local host.
///
/// If [deviceId] is null, then the port forwarder only forwards ports from the
/// remote host to the local host.
@visibleForTesting
class ProxiedPortForwarder extends DevicePortForwarder {
  ProxiedPortForwarder(this.connection, {
    String? deviceId,
    required Logger logger,
    @visibleForTesting CreateSocketServer createSocketServer = _defaultCreateServerSocket,
  }) : _logger = logger,
       _deviceId = deviceId,
       _createSocketServer = createSocketServer;

  final String? _deviceId;

  DaemonConnection connection;

  final Logger _logger;

  final CreateSocketServer _createSocketServer;

  @override
  List<ForwardedPort> get forwardedPorts => _hostPortToForwardedPorts.values.toList();

  final Map<int, _ProxiedForwardedPort> _hostPortToForwardedPorts = <int, _ProxiedForwardedPort>{};

  final List<Socket> _connectedSockets = <Socket>[];

  @override
  Future<int> forward(int devicePort, { int? hostPort }) async {
    int? remoteDevicePort;
    final String? deviceId = _deviceId;

    // If deviceId is set, we need to forward the remote device port to remote host as well.
    // And then, forward the remote host port to a local host port.
    if (deviceId != null) {
      final Map<String, Object?> result = _cast<Map<String, Object?>>(
        await connection.sendRequest('device.forward', <String, Object>{
          'deviceId': deviceId,
          'devicePort': devicePort,
        }));
      remoteDevicePort = devicePort;
      devicePort = result['hostPort']! as int;
    }

    final ServerSocket serverSocket = await _startProxyServer(devicePort, hostPort);

    _hostPortToForwardedPorts[serverSocket.port] = _ProxiedForwardedPort(
      connection,
      hostPort: serverSocket.port,
      devicePort: devicePort,
      remoteDevicePort: remoteDevicePort,
      deviceId: deviceId,
      serverSocket: serverSocket,
    );

    return serverSocket.port;
  }

  Future<ServerSocket> _startProxyServer(int devicePort, int? hostPort) async {
    final ServerSocket serverSocket = await _createSocketServer(_logger, hostPort);

    serverSocket.listen((Socket socket) async {
      final String id = _cast<String>(await connection.sendRequest('proxy.connect', <String, Object>{
        'port': devicePort,
      }));
      final Stream<List<int>> dataStream = connection.listenToEvent('proxy.data.$id').asyncExpand((DaemonEventData event) => event.binary);
      dataStream.listen(socket.add);
      final Future<DaemonEventData> disconnectFuture = connection.listenToEvent('proxy.disconnected.$id').first;
      unawaited(disconnectFuture.then<void>((_) async {
          try {
            await socket.close();
          } on Exception {
            // ignore
          }
        },
        onError: (_) {
          // The event is not guaranteed to be sent if we initiated the disconnection.
          // Do nothing here.
        },
      ));
      socket.listen((Uint8List data) {
        unawaited(connection.sendRequest('proxy.write', <String, Object>{
          'id': id,
        }, data).then(
          (Object? obj) => obj,
          onError: (Object error, StackTrace stackTrace) {
            // Log the error, but proceed normally. Network failure should not
            // crash the tool. If this is critical, the place where the connection
            // is being used would crash.
            _logger.printWarning('Write to remote proxy error: $error');
            _logger.printTrace('Write to remote proxy error: $error, stack trace: $stackTrace');
            return null;
          },
        ));
      });
      _connectedSockets.add(socket);

      unawaited(socket.done.then(
        (Object? obj) => obj,
        onError: (Object error, StackTrace stackTrace) {
        // Do nothing here. Everything will be handled in the `then` block below.
        return false;
      }).whenComplete(() {
        // Send a proxy disconnect event just in case.
        unawaited(connection.sendRequest('proxy.disconnect', <String, Object>{
          'id': id,
        }).then(
          (Object? obj) => obj,
          onError: (Object error, StackTrace stackTrace) {
            // Ignore the error here. There might be a race condition when the
            // remote end also disconnects. In any case, this request is just to
            // notify the remote end to disconnect and we should not crash when
            // there is an error here.
            return null;
          },
        ));
        _connectedSockets.remove(socket);
      }));
    }, onError: (Object error, StackTrace stackTrace) {
      _logger.printWarning('Server socket error: $error');
      _logger.printTrace('Server socket error: $error, stack trace: $stackTrace');
    });

    return serverSocket;
  }

  @override
  Future<void> unforward(ForwardedPort forwardedPort) async {
    // Look for the forwarded port entry in our own map.
    final _ProxiedForwardedPort? proxiedForwardedPort = _hostPortToForwardedPorts.remove(forwardedPort.hostPort);
    await proxiedForwardedPort?.unforward();
  }

  @override
  Future<void> dispose() async {
    for (final _ProxiedForwardedPort forwardedPort in _hostPortToForwardedPorts.values) {
      await forwardedPort.unforward();
    }

    for (final Socket socket in _connectedSockets) {
      await socket.close();
    }
  }
}

Future<ServerSocket> _defaultCreateServerSocket(Logger logger, int? hostPort) async {
  try {
    return await ServerSocket.bind(InternetAddress.loopbackIPv4, hostPort ?? 0);
  } on SocketException {
    logger.printTrace('Bind on $hostPort failed with IPv4, retrying on IPv6');
  }

  // If binding on ipv4 failed, try binding on ipv6.
  // Omit try catch here, let the failure fallthrough.
  return ServerSocket.bind(InternetAddress.loopbackIPv6, hostPort ?? 0);
}

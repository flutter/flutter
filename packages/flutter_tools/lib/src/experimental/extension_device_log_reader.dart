// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import '../base/logger.dart';
import '../device.dart';
import '../vmservice.dart';
import 'extension_discovery.dart';

/// A [DeviceLogReader] that streams log lines from a tool extension isolate
/// via [DeviceService.logEntryNotificationMethod] notifications.
class ExtensionDeviceLogReader extends DeviceLogReader {
  ExtensionDeviceLogReader._({
    required this._connection,
    required this._deviceId,
    required this._deviceService,
    required this._logger,
    required this.name,
    this._appId,
    this._onDispose,
  }) {
    // Defer flushing buffered lines to a microtask so that if multiple
    // subscribers attach to the broadcast stream in the same synchronous turn,
    // all of them receive the initial buffered lines rather than only the first
    // subscriber that triggered onListen synchronously.
    _logLinesController = StreamController<String>.broadcast(
      onListen: () => scheduleMicrotask(_flushPendingLines),
    );
  }

  /// Creates an [ExtensionDeviceLogReader] and starts the device log stream on
  /// the extension isolate.
  static Future<ExtensionDeviceLogReader> create({
    required ExtensionConnection connection,
    required String deviceId,
    required DeviceService deviceService,
    required Logger logger,
    required String name,
    String? appId,
    void Function()? onDispose,
  }) async {
    final reader = ExtensionDeviceLogReader._(
      appId: appId,
      connection: connection,
      deviceId: deviceId,
      deviceService: deviceService,
      logger: logger,
      name: name,
      onDispose: onDispose,
    );
    await reader._startLogStream();
    return reader;
  }

  static const _maxPendingLines = 1000;

  String? _appId;
  final ExtensionConnection _connection;
  final String _deviceId;
  final DeviceService _deviceService;
  final Logger _logger;
  final void Function()? _onDispose;
  final _pendingLines = <String>[];

  @override
  final String name;

  late final StreamController<String> _logLinesController;
  StreamSubscription<Map<String, Object?>>? _notificationSubscription;
  bool _closeAfterFlush = false;
  bool _isDisposed = false;

  /// The application identifier currently scoping this log stream, or `null`
  /// when streaming device-wide logs.
  String? get appId => _appId;

  /// Whether [dispose] has been called (or initial stream startup failed).
  bool get isDisposed => _isDisposed;

  /// Whether at least one subscriber is actively listening to [logLines].
  bool get hasActiveSubscriber => _logLinesController.hasListener;

  @override
  Stream<String> get logLines => _logLinesController.stream;

  void _flushPendingLines() {
    if (_isDisposed || _logLinesController.isClosed) {
      return;
    }
    if (_pendingLines.isNotEmpty) {
      _pendingLines.forEach(_logLinesController.add);
      _pendingLines.clear();
    }
    if (_closeAfterFlush) {
      unawaited(_logLinesController.close());
    }
  }

  Future<void> _startLogStream() async {
    try {
      _notificationSubscription = _connection
          .onNotification(DeviceService.logEntryNotificationMethod)
          .listen(
            (Map<String, Object?> params) {
              if (_isDisposed || _logLinesController.isClosed) {
                return;
              }
              if (params[DeviceService.deviceIdParam] == _deviceId) {
                if (params[DeviceService.lineKey] case final String line) {
                  if (_logLinesController.hasListener) {
                    _logLinesController.add(line);
                  } else if (_pendingLines.length < _maxPendingLines) {
                    _pendingLines.add(line);
                  }
                }
              }
            },
            onDone: () {
              if (_isDisposed || _logLinesController.isClosed) {
                return;
              }
              if (_pendingLines.isEmpty) {
                unawaited(_logLinesController.close());
              } else {
                _closeAfterFlush = true;
              }
            },
          );
      await _deviceService.startLogStream(appId: _appId, deviceId: _deviceId);
    } on Object catch (error) {
      _logger.printWarning('Failed to start log stream for extension device "$_deviceId": $error');
      if (!_isDisposed) {
        _isDisposed = true;
        _onDispose?.call();
        await _notificationSubscription?.cancel();
        _notificationSubscription = null;
        if (!_logLinesController.isClosed) {
          await _logLinesController.close();
        }
      }
    }
  }

  /// Updates the application filter of this active log stream in place without
  /// closing [logLines], clearing buffered unsubscribed lines when
  /// [clearPendingLines] is `true`.
  Future<void> reconfigureAppId(String? appId, {bool clearPendingLines = false}) async {
    if (_isDisposed) {
      return;
    }
    if (clearPendingLines) {
      _pendingLines.clear();
    }
    if (_appId == appId) {
      return;
    }
    _appId = appId;
    try {
      await _deviceService.startLogStream(appId: appId, deviceId: _deviceId);
    } on Object catch (error) {
      _logger.printWarning('Failed to update log stream for extension device "$_deviceId": $error');
    }
  }

  @override
  Future<void> provideVmService(FlutterVmService connectedVmService) async {}

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _onDispose?.call();
    _pendingLines.clear();
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    try {
      await _deviceService.stopLogStream(deviceId: _deviceId);
    } on Object {
      // Ignore errors when stopping log streams during disposal.
    }
    await _logLinesController.close();
  }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'base/io.dart';
import 'base/logger.dart';
import 'base/utils.dart';
import 'device.dart';
import 'device_port_forwarder.dart';
import 'vmservice.dart';

/// Discovers a specific service protocol on a device, and forwards the service
/// protocol device port to the host.
class ProtocolDiscovery {
  ProtocolDiscovery._(
    this.logReader,
    this.serviceName, {
    this.portForwarder,
    required this.throttleDuration,
    required this.failureReasonTimeout,
    this.hostPort,
    this.devicePort,
    required this._ipv6,
    required this._logger,
  }) {
    _deviceLogSubscription = logReader.logLines.listen(_handleLine, onDone: _stopScrapingLogs);
  }

  factory ProtocolDiscovery.vmService(
    DeviceLogReader logReader, {
    DevicePortForwarder? portForwarder,
    Duration? throttleDuration,
    Duration? failureReasonTimeout,
    int? hostPort,
    int? devicePort,
    required bool ipv6,
    required Logger logger,
  }) {
    const kVmServiceService = 'VM Service';
    return ProtocolDiscovery._(
      logReader,
      kVmServiceService,
      portForwarder: portForwarder,
      throttleDuration: throttleDuration ?? const Duration(milliseconds: 200),
      failureReasonTimeout: failureReasonTimeout ?? const Duration(seconds: 5),
      hostPort: hostPort,
      devicePort: devicePort,
      ipv6: ipv6,
      logger: logger,
    );
  }

  final DeviceLogReader logReader;
  final String serviceName;
  final DevicePortForwarder? portForwarder;
  final int? hostPort;
  final int? devicePort;
  final bool _ipv6;
  final Logger _logger;

  /// The time to wait before forwarding a new VM Service URIs from [logReader].
  final Duration throttleDuration;

  /// How long to wait for the reason after the app reports that the VM
  /// service failed to start, before failing without it.
  final Duration failureReasonTimeout;

  StreamSubscription<String>? _deviceLogSubscription;
  final _uriStreamController = _BufferedStreamController<Uri>();

  /// The discovered service URL.
  ///
  /// Returns null if the log reader shuts down before any uri is found.
  ///
  /// Use [uris] instead.
  // TODO(egarciad): replace `uri` for `uris`.
  Future<Uri?> get uri async {
    try {
      return await uris.first;
    } on StateError {
      return null;
    }
  }

  /// The discovered service URLs.
  ///
  /// When a new VM Service URL: is available in [logReader],
  /// the URLs are forwarded at most once every [throttleDuration].
  ///
  /// Port forwarding is only attempted when this is invoked,
  /// for each VM Service URL in the stream.
  Stream<Uri> get uris {
    final Stream<Uri> uriStream = _uriStreamController.stream.transformWithCallSite(
      _throttle<Uri>(waitDuration: throttleDuration),
    );
    return uriStream.asyncMap<Uri>(_forwardPort);
  }

  Future<void> cancel() => _stopScrapingLogs();

  Future<void> _stopScrapingLogs() async {
    _failureReasonTimer?.cancel();
    await _uriStreamController.close();
    await _deviceLogSubscription?.cancel();
    _deviceLogSubscription = null;
  }

  Match? _getPatternMatch(String line) {
    return kVMServiceMessageRegExp.firstMatch(line);
  }

  Uri? _getVmServiceUri(String line) {
    final Match? match = _getPatternMatch(line);
    if (match != null) {
      return Uri.parse(match[1]!);
    }
    return null;
  }

  /// The engine's log line when the VM service HTTP server fails to start.
  ///
  /// The engine prints the error (e.g. a `SocketException`) on the next line,
  /// followed by a stack trace.
  static const _kVmServiceStartFailure = 'Could not start Dart VM service HTTP server:';

  /// The text that came before [_kVmServiceStartFailure] on its line (such
  /// as a logcat tag), or null if that line has not been seen.
  ///
  /// When this is non-null, the next line that starts with it holds the reason
  /// for the failure. Lines without it (e.g. from other processes interleaved
  /// in logcat) are skipped.
  String? _vmServiceStartFailurePrefix;

  /// Fails discovery without a reason if the reason does not arrive within
  /// [failureReasonTimeout].
  Timer? _failureReasonTimer;

  void _handleLine(String line) {
    if (_vmServiceStartFailurePrefix case final String prefix) {
      if (line.startsWith(prefix)) {
        _reportVmServiceStartFailure(line.substring(prefix.length).trim());
      }
      return;
    }
    final int failureIndex = line.indexOf(_kVmServiceStartFailure);
    if (failureIndex != -1) {
      _vmServiceStartFailurePrefix = line.substring(0, failureIndex);
      _failureReasonTimer = Timer(failureReasonTimeout, () => _reportVmServiceStartFailure(null));
      return;
    }

    Uri? uri;
    try {
      uri = _getVmServiceUri(line);
    } on FormatException catch (error, stackTrace) {
      _uriStreamController.addError(error, stackTrace);
    }
    if (uri == null || uri.host.isEmpty) {
      return;
    }
    if (devicePort != null && uri.port != devicePort) {
      _logger.printTrace('skipping potential VM Service $uri due to device port mismatch');
      return;
    }
    _uriStreamController.add(uri);
  }

  void _reportVmServiceStartFailure(String? reason) {
    _failureReasonTimer?.cancel();
    _failureReasonTimer = null;
    _vmServiceStartFailurePrefix = null;
    _uriStreamController.addError(VmServiceStartException(reason));
  }

  Future<Uri> _forwardPort(Uri deviceUri) async {
    _logger.printTrace('$serviceName URL on device: $deviceUri');
    var hostUri = deviceUri;

    final DevicePortForwarder? forwarder = portForwarder;
    if (forwarder != null) {
      final int actualDevicePort = deviceUri.port;
      final int actualHostPort = await forwarder.forward(actualDevicePort, hostPort: hostPort);
      _logger.printTrace(
        'Forwarded host port $actualHostPort to device port $actualDevicePort for $serviceName',
      );
      hostUri = deviceUri.replace(port: actualHostPort);
    }

    if (InternetAddress(hostUri.host).isLoopback && _ipv6) {
      hostUri = hostUri.replace(host: InternetAddress.loopbackIPv6.host);
    }
    return hostUri;
  }
}

/// Thrown by [ProtocolDiscovery.uris] when the app reports
/// that the Dart VM service HTTP server failed to start.
class VmServiceStartException implements Exception {
  VmServiceStartException(this.reason);

  /// The error the app reported, e.g. `SocketException: Failed to create
  /// server socket (OS Error: Operation not permitted, errno = 1), ...`.
  ///
  /// Null if the app did not report the error in time.
  final String? reason;

  @override
  String toString() => switch (reason) {
    final String reason => 'The Dart VM service failed to start: $reason',
    null => 'The Dart VM service failed to start.',
  };
}

/// Provides a broadcast stream controller that buffers the events
/// if there isn't a listener attached.
/// The events are then delivered when a listener is attached to the stream.
class _BufferedStreamController<T extends Object> {
  _BufferedStreamController() : _events = <Object>[];

  /// The stream that this controller is controlling.
  Stream<T> get stream {
    return _streamController.stream;
  }

  late final StreamController<T> _streamController = () {
    final streamControllerInstance = StreamController<T>.broadcast();
    streamControllerInstance.onListen = () {
      for (final Object event in _events) {
        if (event is T) {
          streamControllerInstance.add(event);
        } else {
          streamControllerInstance.addError(
            (event as Iterable<Object?>).first!,
            event.last as StackTrace?,
          );
        }
      }
      _events.clear();
    };
    return streamControllerInstance;
  }();

  final List<Object> _events;

  /// Sends [event] if there is a listener attached to the broadcast stream.
  /// Otherwise, it enqueues [event] until a listener is attached.
  void add(T event) {
    if (_streamController.hasListener) {
      _streamController.add(event);
    } else {
      _events.add(event);
    }
  }

  /// Sends or enqueues an error event.
  void addError(Object error, [StackTrace? stackTrace]) {
    if (_streamController.hasListener) {
      _streamController.addError(error, stackTrace);
    } else {
      _events.add(<Object?>[error, stackTrace]);
    }
  }

  /// Closes the stream.
  Future<void> close() {
    return _streamController.close();
  }
}

/// This transformer will produce an event at most once every [waitDuration].
///
/// For example, consider a `waitDuration` of `10ms`, and list of event names
/// and arrival times: `a (0ms), b (5ms), c (11ms), d (21ms)`.
/// The events `a`, `c`, and `d` will be produced as a result.
StreamTransformer<S, S> _throttle<S>({required Duration waitDuration}) {
  S latestLine;
  int? lastExecution;
  Future<void>? throttleFuture;
  var done = false;

  return StreamTransformer<S, S>.fromHandlers(
    handleData: (S value, EventSink<S> sink) {
      latestLine = value;

      final isFirstMessage = lastExecution == null;
      final int currentTime = DateTime.now().millisecondsSinceEpoch;
      lastExecution ??= currentTime;
      final int remainingTime = currentTime - lastExecution!;

      // Always send the first event immediately.
      final int nextExecutionTime = isFirstMessage || remainingTime > waitDuration.inMilliseconds
          ? 0
          : waitDuration.inMilliseconds - remainingTime;
      throttleFuture ??= Future<void>.delayed(Duration(milliseconds: nextExecutionTime))
          .whenComplete(() {
            if (done) {
              return;
            }
            sink.add(latestLine);
            throttleFuture = null;
            lastExecution = DateTime.now().millisecondsSinceEpoch;
          });
    },
    handleDone: (EventSink<S> sink) {
      done = true;
      sink.close();
    },
  );
}

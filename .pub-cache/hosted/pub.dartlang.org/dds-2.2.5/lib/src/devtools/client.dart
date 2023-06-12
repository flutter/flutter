// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:devtools_shared/devtools_server.dart';
import 'package:json_rpc_2/src/peer.dart' as json_rpc;
import 'package:meta/meta.dart';
import 'package:sse/src/server/sse_handler.dart';
import 'package:stream_channel/stream_channel.dart';

class LoggingMiddlewareSink<S> implements StreamSink<S> {
  LoggingMiddlewareSink(this.sink);

  @override
  void add(S event) {
    print('DevTools SSE response: $event');
    sink.add(event);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    print('DevTools SSE error response: $error');
    sink.addError(error);
  }

  @override
  Future addStream(Stream<S> stream) {
    return sink.addStream(stream);
  }

  @override
  Future close() => sink.close();

  @override
  Future get done => sink.done;

  final StreamSink sink;
}

/// A connection between a DevTools front-end app and the DevTools server.
///
/// see `packages/devtools_app/lib/src/server_connection.dart`.
class ClientManager {
  ClientManager({required this.requestNotificationPermissions});

  /// Whether to immediately request notification permissions when a client connects.
  /// Otherwise permission will be requested only with the first notification.
  final bool requestNotificationPermissions;
  final List<DevToolsClient> _clients = [];

  void acceptClient(SseConnection connection, {bool enableLogging = false}) {
    final client = DevToolsClient.fromSSEConnection(
      connection,
      enableLogging,
    );
    if (requestNotificationPermissions) {
      client.enableNotifications();
    }
    _clients.add(client);
    connection.sink.done.then((_) => _clients.remove(client));
  }

  /// Finds an active DevTools instance that is not already connecting to
  /// a VM service that we can reuse (for example if a user stopped debugging
  /// and it disconnected, then started debugging again, we want to reuse
  /// the open DevTools window).
  DevToolsClient? findReusableClient() {
    return _clients.firstWhereOrNull(
      (c) => !c.hasConnection && !c.embedded,
    );
  }

  /// Finds a client that may already be connected to this VM Service.
  DevToolsClient? findExistingConnectedReusableClient(Uri vmServiceUri) {
    // Checking the whole URI will fail if DevTools converted it from HTTP to
    // WS, so just check the host, port and first segment of path (token).
    return _clients.firstWhereOrNull(
      (c) =>
          c.hasConnection &&
          !c.embedded &&
          _areSameVmServices(c.vmServiceUri!, vmServiceUri),
    );
  }

  @override
  String toString() {
    return _clients.map((c) {
      return '${c.hasConnection.toString().padRight(5)} '
          '${c.currentPage?.padRight(12)} ${c.vmServiceUri.toString()}';
    }).join('\n');
  }

  Map<String, dynamic> toJson(dynamic id) => {
        'id': id,
        'result': {
          'clients': _clients.map((e) => e.toJson()).toList(),
        }
      };

  bool _areSameVmServices(Uri uri1, Uri uri2) {
    return uri1.host == uri2.host &&
        uri1.port == uri2.port &&
        uri1.pathSegments.isNotEmpty &&
        uri2.pathSegments.isNotEmpty &&
        uri1.pathSegments[0] == uri2.pathSegments[0];
  }
}

/// Represents a DevTools client connection to the DevTools server API.
class DevToolsClient {
  factory DevToolsClient.fromSSEConnection(
    SseConnection sse,
    bool loggingEnabled,
  ) {
    Stream<String> stream = sse.stream;
    StreamSink sink = sse.sink;
    return DevToolsClient(
      stream: stream,
      sink: sink,
      loggingEnabled: loggingEnabled,
    );
  }

  @visibleForTesting
  DevToolsClient({
    required Stream<String> stream,
    required StreamSink sink,
    bool loggingEnabled = false,
  }) {
    if (loggingEnabled) {
      stream = stream.map<String>((String e) {
        print('DevTools SSE request: $e');
        return e;
      });
      sink = LoggingMiddlewareSink(sink);
    }

    _devToolsPeer = json_rpc.Peer(
      StreamChannel(stream, sink as StreamSink<String>),
      strictProtocolChecks: false,
    );
    _registerJsonRpcMethods();
    _devToolsPeer.listen();
  }

  void _registerJsonRpcMethods() {
    _devToolsPeer.registerMethod('connected', (parameters) {
      _vmServiceUri = Uri.parse(parameters['uri'].asString);
    });

    _devToolsPeer.registerMethod('disconnected', (parameters) {
      _vmServiceUri = null;
    });

    _devToolsPeer.registerMethod('currentPage', (parameters) {
      _currentPage = parameters['id'].asString;
      _embedded = parameters['embedded'].asBool;
    });

    _devToolsPeer.registerMethod('getPreferenceValue', (parameters) {
      final key = parameters['key'].asString;
      final value = ServerApi.devToolsPreferences.properties[key];
      return value;
    });

    _devToolsPeer.registerMethod('setPreferenceValue', (parameters) {
      final key = parameters['key'].asString;
      final value = parameters['value'].value;
      ServerApi.devToolsPreferences.properties[key] = value;
    });
  }

  /// Notify the DevTools client to connect to a specific VM service instance.
  void connectToVmService(Uri uri, bool notifyUser) {
    _devToolsPeer.sendNotification('connectToVm', {
      'uri': uri.toString(),
      'notify': notifyUser,
    });
  }

  void notify() => _devToolsPeer.sendNotification('notify');

  /// Enable notifications to the user from this DevTools client.
  void enableNotifications() =>
      _devToolsPeer.sendNotification('enableNotifications');

  /// Notify the DevTools client to show a specific page.
  void showPage(String pageId) {
    _devToolsPeer.sendNotification('showPage', {
      'page': pageId,
    });
  }

  Map<String, dynamic> toJson() => {
        'hasConnection': hasConnection,
        'currentPage': currentPage,
        'embedded': embedded,
        'vmServiceUri': vmServiceUri?.toString(),
      };

  /// The current DevTools page displayed by this client.
  String? get currentPage => _currentPage;
  String? _currentPage;

  /// Returns true if this DevTools client is embedded.
  bool get embedded => _embedded;
  bool _embedded = false;

  /// Returns the VM service URI that the DevTools client is currently
  /// connected to. Returns null if the client is not connected to a process.
  Uri? get vmServiceUri => _vmServiceUri;
  Uri? _vmServiceUri;

  bool get hasConnection => _vmServiceUri != null;

  late json_rpc.Peer _devToolsPeer;
}

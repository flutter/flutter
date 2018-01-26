// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:meta/meta.dart';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/io.dart';

const Duration _kConnectTimeout = const Duration(seconds: 30);

const Duration _kReconnectAttemptInterval = const Duration(seconds: 3);

const Duration _kRpcTimeout = const Duration(seconds: 5);

final Logger _log = new Logger('FuchsiaDartVm');

/// Simple JSON RPC peer with a Fuchsia Dart VM service instance. Wraps most
/// methods around a JSON RPC peer class.
class FuchsiaDartVm {
  final json_rpc.Peer _peer;

  FuchsiaDartVm._(this._peer);

  /// Attempts to connect to the given `Uri`.
  ///
  /// Throws an error if unable to connect.
  static Future<FuchsiaDartVm> connect(Uri uri) async {
    final Stopwatch timer = new Stopwatch()..start();
    if (uri.scheme == 'http') uri = uri.replace(scheme: 'ws', path: '/ws');
    return await _attemptConnection(uri, timer);
  }

  static Future<FuchsiaDartVm> _attemptConnection(
      final Uri uri, final Stopwatch runningTimer) async {
    WebSocket socket;
    try {
      socket = await WebSocket.connect(uri.toString());
      json_rpc.Peer peer =
          new json_rpc.Peer(new IOWebSocketChannel(socket).cast())..listen();
      return new FuchsiaDartVm._(peer);
    } catch (e) {
      await socket?.close();
      if (runningTimer.elapse < _kConnectTimeout) {
        log.info('Attempting to reconnect');
        await new Future<Null>.delayed(_kReconnectAttemptInterval);
        return FuchsiaDartVm._attemptConnection(uri, runningTimer);
      } else {
        log.critical('Connection to Fuchsia\'s Dart VM timed out at '
            '${uri.toString()}');
        rethrow;
      }
    }
  }

  /// Invokes a raw JSON RPC command with the VM service.
  Future<Map<String, dynamic>> invokeRpc(String function,
      {Map<String, dynamic> params, Duration timeout}) async {
    return _peer.sendRequest(function, params ?? {});
  }

  /// Returns a list of flutter views names.
  ///
  /// If there is no associated isolate with the flutter view (used to determine
  /// the flutter view's name), then the flutter view's ID will be added
  /// instead. If none of these things can be found (isolate has no name or the
  /// flutter view has no ID), then the result will not be added to the list.
  Future<List<String>> listFlutterViewNames() async {
    // TODO(awdavies): Add some abstraction so that these views can be talked to
    // over RPC as well. Then these errors won't need to be handled in such an
    // ugly way.
    final List<String> viewNames = <String>[];
    final Map<String, dynamic> rpcResponse =
        await invokeRpc('_flutter.listViews', timeout: _kRpcTimeout);
    final List<Map<String, dynamic>> flutterViews = rpcResponse['views'];
    for (Map<String, dynamic> flutterView in flutterViews) {
      Map<String, dynamic> isolate = flutterView['isolate'];
      final String id = flutterView['id'];
      if (isolate != null) {
        final String name = isolate['name'];
        if (name != null) {
          viewNames.add(name);
        } else {
          _log.warning('Unable to find name for isolate "$isolate"');
        }
      } else if (id != null) {
        viewNames.add(id);
      } else {
        _log.warning(
            'Unable to find view name for the following JSON structure '
            '"$flutterView"');
      }
    }
    return viewNames;
  }

  /// Shuts down all active connections.
  Future<Null> stop() async {
    await _peer?.close();
  }
}

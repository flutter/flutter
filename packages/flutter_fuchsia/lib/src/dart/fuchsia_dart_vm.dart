// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
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
    if (uri.scheme == 'http') {
      uri = uri.replace(scheme: 'ws', path: '/ws');
    }
    return await _attemptConnection(uri, timer);
  }

  static Future<FuchsiaDartVm> _attemptConnection(
      final Uri uri, final Stopwatch runningTimer) async {
    WebSocket socket;
    json_rpc.Peer peer;
    try {
      socket = await WebSocket.connect(uri.toString());
      peer = new json_rpc.Peer(new IOWebSocketChannel(socket).cast())..listen();
      return new FuchsiaDartVm._(peer);
    } catch (e) {
      await peer?.close();
      await socket?.close();
      if (runningTimer.elapsed < _kConnectTimeout) {
        _log.info('Attempting to reconnect');
        await new Future<Null>.delayed(_kReconnectAttemptInterval);
        return FuchsiaDartVm._attemptConnection(uri, runningTimer);
      } else {
        _log.severe('Connection to Fuchsia\'s Dart VM timed out at '
            '${uri.toString()}');
        rethrow;
      }
    }
  }

  /// Invokes a raw JSON RPC command with the VM service.
  Future<Map<String, dynamic>> invokeRpc(String function,
      {Map<String, dynamic> params, Duration timeout}) async {
    return _peer.sendRequest(function, params ?? <String, dynamic>{});
  }

  /// Returns a list of `FuchsiaFlutterViews` running across all Dart VM's.
  ///
  /// If there is no associated isolate with the flutter view (used to determine
  /// the flutter view's name), then the flutter view's ID will be added
  /// instead. If none of these things can be found (isolate has no name or the
  /// flutter view has no ID), then the result will not be added to the list.
  Future<List<FuchsiaFlutterView>> getAllFlutterViews() async {
    final List<FuchsiaFlutterView> views = <FuchsiaFlutterView>[];
    final Map<String, dynamic> rpcResponse =
        await invokeRpc('_flutter.listViews', timeout: _kRpcTimeout);
    final List<Map<String, dynamic>> flutterViewsJson = rpcResponse['views'];
    for (Map<String, dynamic> jsonView in flutterViewsJson) {
      final FuchsiaFlutterView flutterView =
          new FuchsiaFlutterView._fromJson(jsonView);
      if (flutterView != null) {
        views.add(flutterView);
      }
    }
    return views;
  }

  /// Shuts down all active connections.
  Future<Null> stop() async {
    await _peer?.close();
  }
}

/// Represents an instance of a Flutter view running on a Fuchsia device.
class FuchsiaFlutterView {
  /// Determines the name of the Isolate associated with this view. If there is
  /// no associated Isolate, this will be set to the view's ID.
  final String _name;

  /// The ID of the Flutter view.
  final String _id;

  /// Attempts to construct a `FuchsiaFlutterView` from a json representation.
  ///
  /// If there is no Isolate and no id for the view, returns null. If there is
  /// an associated isolate, and there is name for said isolate, also returns
  /// null.
  ///
  /// All other cases return a `FuchsiaFlutterView` instance. The name of the
  /// view may be null, but the id will always be set.
  factory FuchsiaFlutterView._fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> isolate = json['isolate'];
    final String id = json['id'];
    String name;
    if (isolate != null) {
      name = isolate['name'];
      if (name == null) {
        _log.warning('Unable to find name for isolate "$isolate"');
        return null;
      }
    }

    if (id == null) {
      _log.warning('Unable to find view name for the following JSON structure '
          '"$json"');
      return null;
    }

    return new FuchsiaFlutterView._(name, id);
  }

  FuchsiaFlutterView._(this._name, this._id);

  /// The ID of the `FuchsiaFlutterView`.
  String get id => _id;

  /// Returns the name of the `FucshiaFlutterView`.
  ///
  /// May be null if there is no associated isolate.
  String get name => _name;
}

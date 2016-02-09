// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library observatory_sky_shell_service_client;


import 'dart:async';
import 'dart:convert';

class ServiceClient {
  ServiceClient(this.client) {
    client.listen(_onData,
                  onError: _onError,
                  cancelOnError: true);
  }

  Future<Map> invokeRPC(String method, [Map params]) async {
    var key = _createKey();
    var request = JSON.encode({
      'jsonrpc': '2.0',
      'method': method,
      'params': params == null ? {} : params,
      'id': key,
    });
    client.add(request);
    var completer = new Completer();
    _outstanding_requests[key] = completer;
    print('-> $key ($method)');
    return completer.future;
  }

  String _createKey() {
    var key = '$_id';
    _id++;
    return key;
  }

  void _onData(String message) {
    var response = JSON.decode(message);
    var key = response['id'];
    print('<- $key');
    var completer = _outstanding_requests.remove(key);
    assert(completer != null);
    var result = response['result'];
    var error = response['error'];
    if (error != null) {
      assert(result == null);
      completer.completeError(error);
    } else {
      assert(result != null);
      completer.complete(result);
    }
  }

  void _onError(error) {
    print('WebSocket error: $error');
  }

  final WebSocket client;
  final Map<String, Completer> _outstanding_requests = <String, Completer>{};
  var _id = 1;
}

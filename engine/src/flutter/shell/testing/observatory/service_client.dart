// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library observatory_sky_shell_service_client;

import 'dart:async';
import 'dart:convert';
import 'dart:io';


class ServiceClient {
  Completer<dynamic> isolateStartedId;
  Completer<dynamic> isolatePausedId;
  Completer<dynamic> isolateResumeId;

  ServiceClient(this.client, {this.isolateStartedId, this.isolatePausedId,
      this.isolateResumeId}) {
    client.listen(_onData,
                  onError: _onError,
                  cancelOnError: true);
  }

  Future<Map<String, dynamic>> invokeRPC(String method, [Map<String, dynamic> params]) async {
    final String key = _createKey();
    final String request = json.encode(<String, dynamic>{
      'jsonrpc': '2.0',
      'method': method,
      'params': params == null ? <String, dynamic>{} : params,
      'id': key,
    });
    client.add(request);
    final Completer<Map<String, dynamic>> completer = new Completer<Map<String, dynamic>>();
    _outstandingRequests[key] = completer;
    print('-> $key ($method)');
    return completer.future;
  }

  String _createKey() {
    final String key = '$_id';
    _id++;
    return key;
  }

  void _onData(dynamic message) {
    final Map<String, dynamic> response = json.decode(message);
    final dynamic key = response['id'];
    if (key != null) {
      print('<- $key');
      final dynamic completer = _outstandingRequests.remove(key);
      assert(completer != null);
      final dynamic result = response['result'];
      final dynamic error = response['error'];
      if (error != null) {
        assert(result == null);
        completer.completeError(error);
      } else {
        assert(result != null);
        completer.complete(result);
      }
    } else {
      if (response['method'] == 'streamNotify') {
        _onServiceEvent(response['params']);
      }
    }
  }

  void _onServiceEvent(Map<String, dynamic> params) {
    if (params == null) {
      return;
    }
    final Map<String, dynamic> event = params['event'];
    if (event == null || event['type'] != 'Event') {
      return;
    }
    final dynamic isolateId = event['isolate']['id'];
    switch (params['streamId']) {
      case 'Isolate':
        if (event['kind'] == 'IsolateStart') {
          isolateStartedId?.complete(isolateId);
        }
        break;
      case 'Debug':
        switch (event['kind']) {
          case 'Resume':
            isolateResumeId?.complete(isolateId);
            break;
          case 'PauseStart':
            isolatePausedId?.complete(isolateId);
            break;
        }
        break;
    }
  }

  void _onError(dynamic error) {
    print('WebSocket error: $error');
  }

  final WebSocket client;
  final Map<String, Completer<dynamic>> _outstandingRequests = <String, Completer<dynamic>>{};
  int _id = 1;
}

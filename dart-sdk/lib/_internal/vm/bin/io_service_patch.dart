// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "common_patch.dart";

@pragma("vm:external-name", "IOService_NewServicePort")
external SendPort _newServicePort();

@patch
class _IOService {
  static final SendPort _port = _newServicePort();

  static final RawReceivePort _receivePort = RawReceivePort((
    List<Object?> data,
  ) {
    assert(data.length == 2);
    _forwardResponse(data[0] as int, data[1]);
  }, 'IO Service');
  static HashMap<int, Completer> _messageMap = HashMap<int, Completer>();
  static int _id = 0;

  @patch
  static Future<Object?> _dispatch(int request, List data) {
    int id;
    do {
      id = _getNextId();
    } while (_messageMap.containsKey(id));
    final Completer completer = Completer();
    try {
      if (_messageMap.isEmpty) {
        // This is the first outgoing request after being in an idle state,
        // make sure to mark [_receivePort] alive.
        _receivePort.keepIsolateAlive = true;
      }
      _messageMap[id] = completer;
      _port.send(<dynamic>[id, _receivePort.sendPort, request, data]);
    } catch (error) {
      _forwardResponse(id, error);
    }
    return completer.future;
  }

  static void _forwardResponse(int id, Object? response) {
    _messageMap.remove(id)!.complete(response);
    if (_messageMap.isEmpty) {
      // Last pending response received. We are entering idle state so
      // mark _receivePort inactive.
      _id = 0;
      _receivePort.keepIsolateAlive = false;
    }
  }

  static int _getNextId() {
    if (_id == 0x7FFFFFFF) _id = 0;
    return _id++;
  }
}

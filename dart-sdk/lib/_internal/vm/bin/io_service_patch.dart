// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "common_patch.dart";

class _IOServicePorts {
  // We limit the number of IO Service ports per isolate so that we don't
  // spawn too many threads all at once, which can crash the VM on Windows.
  static const int maxPorts = 32;
  final List<SendPort> _ports = [];
  final List<int> _useCounts = [];
  final List<int> _freePorts = [];
  final Map<int, int> _usedPorts = HashMap<int, int>();

  _IOServicePorts();

  SendPort _getPort(int forRequestId) {
    assert(!_usedPorts.containsKey(forRequestId));
    if (_freePorts.isEmpty && _ports.length < maxPorts) {
      final SendPort port = _newServicePort();
      _ports.add(port);
      _useCounts.add(0);
      _freePorts.add(_ports.length - 1);
    }
    // Use a free port if one exists.
    final index = _freePorts.isNotEmpty
        ? _freePorts.removeLast()
        : forRequestId % maxPorts;
    _usedPorts[forRequestId] = index;
    _useCounts[index]++;
    return _ports[index];
  }

  void _returnPort(int forRequestId) {
    final index = _usedPorts.remove(forRequestId)!;
    if (--_useCounts[index] == 0) {
      _freePorts.add(index);
    }
  }

  @pragma("vm:external-name", "IOService_NewServicePort")
  external static SendPort _newServicePort();
}

@patch
class _IOService {
  static _IOServicePorts _servicePorts = new _IOServicePorts();
  static RawReceivePort? _receivePort;
  static late SendPort _replyToPort;
  static HashMap<int, Completer> _messageMap = new HashMap<int, Completer>();
  static int _id = 0;

  @patch
  static Future<Object?> _dispatch(int request, List data) {
    int id;
    do {
      id = _getNextId();
    } while (_messageMap.containsKey(id));
    final SendPort servicePort = _servicePorts._getPort(id);
    _ensureInitialize();
    final Completer completer = new Completer();
    _messageMap[id] = completer;
    try {
      servicePort.send(<dynamic>[id, _replyToPort, request, data]);
    } catch (error) {
      _messageMap.remove(id)!.complete(error);
      if (_messageMap.length == 0) {
        _finalize();
      }
    }
    return completer.future;
  }

  static void _ensureInitialize() {
    if (_receivePort == null) {
      _receivePort = new RawReceivePort(null, 'IO Service');
      _replyToPort = _receivePort!.sendPort;
      _receivePort!.handler = (List<Object?> data) {
        assert(data.length == 2);
        _messageMap.remove(data[0])!.complete(data[1]);
        _servicePorts._returnPort(data[0] as int);
        if (_messageMap.length == 0) {
          _finalize();
        }
      };
    }
  }

  static void _finalize() {
    _id = 0;
    _receivePort!.close();
    _receivePort = null;
  }

  static int _getNextId() {
    if (_id == 0x7FFFFFFF) _id = 0;
    return _id++;
  }
}


import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_socket_io/flutter_socket_io.dart';

class SocketIOManager {

  static SocketIOManager _instance = new SocketIOManager._internal();
  static const MethodChannel _channel = const MethodChannel('flutter_socket_io');
  Map<String, SocketIO> _sockets;

  factory SocketIOManager() {
   return _instance;
  }

  SocketIOManager._internal() {
    _sockets = new Map();
    _channel.setMethodCallHandler(handler);
  }

  Future<dynamic> handler(MethodCall call) {
    //structure of method call: "<socketId>|<event>|<callbackName>"
    if (call.method.contains("|")) {
      dynamic params = _parserMethodCall(call.method);
      print(params);
      if (params != null && params.length > 2) {
        SocketIO socketIO = _getSocketIO(params[0]);
        if(socketIO != null) {
          socketIO.handlerMethodCall(params[1], params[2], call.arguments);
        } else {
          print("NOT FOUND SOCKET ${params[0]}");
        }
      }
    }
    return null;
  }

  String _getSocketId(String domain, String namespace) {
    if (domain != null) {
      return domain + (namespace != null ? namespace : "");
    }
    return null;
  }

  SocketIO _getSocketIO(String socketId) {
    if(socketId != null && socketId.isNotEmpty && _sockets != null) {
      SocketIO result;
      _sockets.forEach((id, socket) {
        if(id == socketId) {
          result = socket;
          return;
        }
      });
      return result;
    }
    return null;
  }

  SocketIO createSocketIO(String domain, String namespace, {String query, Function socketStatusCallback}) {
    if(domain == null || domain.isEmpty) {
      print("DOMAIN IS NULL OR EMPTY!");
      return null;
    }
    String socketId = _getSocketId(domain, namespace);
    SocketIO socketIO = _getSocketIO(socketId);

    if(socketIO == null) {
      print("CREATING NEW SOCKET: $socketId");
      socketIO = new SocketIO(
          _channel,
          domain,
          namespace,
          query: query,
          socketStatusCallback: socketStatusCallback
      );
      _sockets.putIfAbsent(socketId, () => socketIO);
    }

    return socketIO;
  }

  Future<void> destroySocket(SocketIO socket) async {
    if(socket != null && _sockets != null) {
      _sockets.remove(socket.getId());
      socket.destroy();
      socket = null;
    }
  }

  Future<void> destroyAllSocket() async {
    if(_sockets != null) {
      _sockets.forEach((id, socket) {
        socket.destroy();
      });
      _sockets.clear();
    }
  }

  dynamic _parserMethodCall(String method) {
    if (method != null && method.isNotEmpty && method.contains("|")) {
      return method.split("|");
    }
    return null;
  }

}
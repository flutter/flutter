import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class SocketIO {

  String _domain;
  String _namespace;
  String _query;
  Function _statusCallback;
  String _statusCallbackName;
  MethodChannel _channel;

  Map<String, CallbackFunctions> _callbacks;

  ///domain: domain url
  ///namespace: just for iOS
  ///socketStatusCallback [optional]: the status of socket [connect/disconnect/reconnect/...] will be sent into this function
  SocketIO(MethodChannel channel, String domain, String namespace, {String query, Function socketStatusCallback}) {
    _channel = channel;
    _domain = domain;
    _namespace = namespace;
    _query = query;

    _callbacks = new Map();
    _statusCallback = socketStatusCallback;
    _statusCallbackName = _parserFunctionName(socketStatusCallback);
  }

  Future<dynamic> handlerMethodCall(String event, String callbackFuncName, dynamic arguments) {
    if (event != null && event.isNotEmpty) {
      if (event == _statusCallbackName && _statusCallback != null) {
        _statusCallback(arguments);
      } else {
        CallbackFunctions functions = _callbacks[event];
        if (functions != null) {
          SocketIOFunction f = functions.getFunctionByName(callbackFuncName);
          if (f != null && f.function != null) {
            print("CALLLING FUNCTION: " + f.functionName);
            f.function(arguments);
            return null;
          }
        }
      }
    }
    return null;
  }

  _clearAll() {
    if(_callbacks != null) {
      _callbacks.clear();
    }
  }

  /// Get Id (Url + Namespace) of the socket
  String getId() {
    if (_domain != null) {
      return _domain + (_namespace != null ? _namespace : "");
    }
    return null;
  }

  /// Init socket before doing anything with socket
  Future<void> init({String query}) async {
    if (query != null) {
      _query = query;
    }

    await _channel.invokeMethod(MethodCallName.SOCKET_INIT, {
      MethodCallArgumentsName.SOCKET_DOMAIN: _domain,
      MethodCallArgumentsName.SOCKET_NAME_SPACE: _namespace,
      MethodCallArgumentsName.SOCKET_QUERY: _query,
      MethodCallArgumentsName.SOCKET_CALLBACK: _statusCallbackName
    });
  }

  /// Create a new socket and connects the client
  Future<void> connect() async {
    await _channel.invokeMethod(MethodCallName.SOCKET_CONNECT, {
      MethodCallArgumentsName.SOCKET_DOMAIN: _domain,
      MethodCallArgumentsName.SOCKET_NAME_SPACE: _namespace,
    });
  }

  /// Subscribe to a channel with a callback
  Future<void> subscribe(String event, Function callback) async {
    if (event != null && event.isNotEmpty) {
      CallbackFunctions functions = _callbacks[event];
      SocketIOFunction f;

      if (functions == null) {
        functions = new CallbackFunctions();
      }

      if (callback != null) {
        f = functions.addFunction(callback);
      }

      _callbacks[event] = functions;

      var subscribes = new Map<String, String>();
      subscribes.putIfAbsent(event, () => f == null ? "" : f.functionName);

      await _channel.invokeMethod(MethodCallName.SOCKET_SUBSCRIBES, {
        MethodCallArgumentsName.SOCKET_DOMAIN: _domain,
        MethodCallArgumentsName.SOCKET_NAME_SPACE: _namespace,
        MethodCallArgumentsName.SOCKET_DATA: json.encode(subscribes),
      });
    }
  }

  /// Unsubscribe from a channel
  ///
  /// When no callback is provided, unsubscribe all subscribers of the channel. Otherwise, unsubscribe only the callback passed in
  Future<void> unSubscribe(String event, [Function callback]) async {

    if (event != null && event.isNotEmpty) {

      CallbackFunctions callbackFunctions = _callbacks[event];

      if (callbackFunctions != null) {

        callbackFunctions.remove(callback);

        if(callbackFunctions.functions.length < 1) {
          _callbacks.remove(event);
        } else {
          _callbacks[event] = callbackFunctions;
        }

      }

      SocketIOFunction f = new SocketIOFunction(callback);
      var unSubscribes = new Map<String, String>();
      unSubscribes.putIfAbsent(event, () => f == null ? "" : f.functionName);
      await _channel.invokeMethod(MethodCallName.SOCKET_UNSUBSCRIBES, {
        MethodCallArgumentsName.SOCKET_DOMAIN: _domain,
        MethodCallArgumentsName.SOCKET_NAME_SPACE: _namespace,
        MethodCallArgumentsName.SOCKET_DATA: json.encode(unSubscribes),
      });
    }
  }

  /// Send a message via a channel (i.e. event)
  Future<void> sendMessage(String event, dynamic message, [Function callback]) async {
    if (event != null && event.isNotEmpty) {
      CallbackFunctions functions = _callbacks[event];
      SocketIOFunction f;

      if (functions == null) {
        functions = new CallbackFunctions();
      }

      if (callback != null) {
        f = functions.addFunction(callback);
      }

      _callbacks[event] = functions;

      await _channel.invokeMethod(MethodCallName.SOCKET_SEND_MESSAGE, {
        MethodCallArgumentsName.SOCKET_DOMAIN: _domain,
        MethodCallArgumentsName.SOCKET_NAME_SPACE: _namespace,
        MethodCallArgumentsName.SOCKET_EVENT: event,
        MethodCallArgumentsName.SOCKET_MESSAGE: message,
        MethodCallArgumentsName.SOCKET_CALLBACK: f == null ? "" : f.functionName
      });
    }
  }

  /// Disconnect from the socket
  Future<void> disconnect() async {
    await _channel.invokeMethod(MethodCallName.SOCKET_DISCONNECT, {
      MethodCallArgumentsName.SOCKET_DOMAIN: _domain,
      MethodCallArgumentsName.SOCKET_NAME_SPACE: _namespace,
    });
  }

  /// Destroy the socket and cleanup all memory usage
  Future<void> destroy() async {
    _clearAll();
    await _channel.invokeMethod(MethodCallName.SOCKET_DESTROY, {
      MethodCallArgumentsName.SOCKET_DOMAIN: _domain,
      MethodCallArgumentsName.SOCKET_NAME_SPACE: _namespace
    });
  }

  /// Unsubscribe all subscribers from all channels
  Future<void> unSubscribesAll() async {
    _clearAll();
    await _channel.invokeMethod(MethodCallName.SOCKET_UNSUBSCRIBES_ALL, {
      MethodCallArgumentsName.SOCKET_DOMAIN: _domain,
      MethodCallArgumentsName.SOCKET_NAME_SPACE: _namespace
    });
  }
}

String _parserFunctionName(Object function) {
  if (function != null) {
    return "FunctionId@${function.hashCode}";
  }
  return null;
}

class SocketIOFunction {
  String _funcName;
  Function _function;

  SocketIOFunction(Function function) {
    _function = function;
    _funcName = _parserFunctionName(function);
  }

  set setFunction(Function function) {
    _function = function;
    _funcName = _parserFunctionName(function);
  }

  String get functionName => _funcName;

  Function get function => _function;
}

class CallbackFunctions {

  List<SocketIOFunction> _functions;

  CallbackFunctions() {
    _functions = new List();
  }

  SocketIOFunction addFunction(Function function) {
    SocketIOFunction f = getFunction(function);
    if (f == null) {
      f = new SocketIOFunction(function);
      _functions.add(f);
    }
    return f;
  }

  SocketIOFunction getFunctionByName(String funcName) {
    if (funcName != null && funcName.isNotEmpty) {
      SocketIOFunction result;
      _functions.forEach((f) {
        if (f != null && f.functionName == funcName) {
          result = f;
          return;
        }
      });
      return result;
    }
    return null;
  }

  SocketIOFunction getFunction(Function function) {
    if (function != null) {
      SocketIOFunction result;
      String funcName = _parserFunctionName(function);
      _functions.forEach((f) {
        if (f != null && funcName != null && f.functionName == funcName) {
          result = f;
          return;
        }
      });
      return result;
    }
    return null;
  }

  bool remove(Function function) {
    if (function != null) {
      String funcName = _parserFunctionName(function);
      SocketIOFunction socketIOFunction;
      _functions.forEach((f) {
        if (f != null && funcName != null && f.functionName == funcName) {
          socketIOFunction = f;
          return;
        }
      });

      return _functions.remove(socketIOFunction);
    }
    return false;
  }

  void removeAllFunctions() {
    if (_functions != null) {
      _functions.clear();
    }
  }

  List<SocketIOFunction> get functions => _functions;
}

class MethodCallArgumentsName {
  static final String SOCKET_DOMAIN = "socketDomain";
  static final String SOCKET_NAME_SPACE = "socketNameSpace";
  static final String SOCKET_CALLBACK = "socketCallback";
  static final String SOCKET_EVENT = "socketEvent";
  static final String SOCKET_MESSAGE = "socketMessage";
  static final String SOCKET_DATA = "socketData";
  static final String SOCKET_QUERY = "socketQuery";
}

class MethodCallName {
  static final String SOCKET_INIT = "socketInit";
  static final String SOCKET_CONNECT = "socketConnect";
  static final String SOCKET_DISCONNECT = "socketDisconnect";
  static final String SOCKET_SUBSCRIBES = "socketSubcribes";
  static final String SOCKET_UNSUBSCRIBES = "socketUnsubcribes";
  static final String SOCKET_UNSUBSCRIBES_ALL = "socketUnsubcribesAll";
  static final String SOCKET_SEND_MESSAGE = "socketSendMessage";
  static final String SOCKET_DESTROY = "socketDestroy";
  static final String SOCKET_DESTROY_ALL = "socketDestroyAll";
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

typedef void Listener(dynamic msg);
typedef void MultiUseCallback(dynamic msg);
typedef void CancelListening();

/// WatchListener, listen data sent from Watch or Phone
class WatchListener {

  /// Method channel to communnicate with native code
  static const _channel = const MethodChannel("watchConnection");

  /// Next Callback Id
  static int _nextCallbackId = 0;

  /// Message Callbacks By Id
  static Map<int, MultiUseCallback> _messageCallbacksById = new Map();

  /// Data Callbacks By Id
  static Map<int, MultiUseCallback> _dataCallbacksById = new Map();

  /// Set Method Call Handler
  WatchListener() {
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  /// Method Call Handler for messageReceived & dataReceived
  static Future<void> _methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'messageReceived':
        if (call.arguments["args"] is String) {
          try {
            Map value = json.decode(call.arguments["args"]);
            _messageCallbacksById[call.arguments?["id"]]!(value);
            // ignore: non_constant_identifier_names
          } catch (Exception) {
            _messageCallbacksById[call.arguments["id"]]!(call.arguments["args"]);
          }
        } else {
          _messageCallbacksById[call.arguments["id"]]!(call.arguments["args"]);
        }
        break;
      case 'dataReceived':
        if (call.arguments["args"] is String) {
          try {
            Map value = json.decode(call.arguments["args"]);
            _dataCallbacksById[call.arguments["id"]]!(value);
            // ignore: non_constant_identifier_names
          } catch (Exception) {
            _dataCallbacksById[call.arguments["id"]]!(call.arguments["args"]);
          }
        } else {
          _dataCallbacksById[call.arguments["id"]]!(call.arguments["args"]);
        }

        break;
      default:
        print(
            'TestFairy: Ignoring invoke from native. This normally shouldn\'t happen.');
    }
  }

  /// Listen for Message
  static Future<Null Function()> listenForMessage(MultiUseCallback callback) async {
    _channel.setMethodCallHandler(_methodCallHandler);
    int currentListenerId = _nextCallbackId++;
    _messageCallbacksById[currentListenerId] = callback;
    await _channel.invokeMethod("listenMessages", currentListenerId);
    return () {
      _channel.invokeMethod("cancelListeningMessages", currentListenerId);
      _messageCallbacksById.remove(currentListenerId);
    };
  }

  /// listen for Data Layer
  static Future<Null Function()> listenForDataLayer(MultiUseCallback callback) async {
    _channel.setMethodCallHandler(_methodCallHandler);
    int currentListenerId = _nextCallbackId++;
    _dataCallbacksById[currentListenerId] = callback;
    await _channel.invokeMethod("listenData", currentListenerId);
    return () {
      _channel.invokeMethod("cancelListeningData", currentListenerId);
      _dataCallbacksById.remove(currentListenerId);
    };
  }
}
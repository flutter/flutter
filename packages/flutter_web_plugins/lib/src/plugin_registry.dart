import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef _MessageHandler = Future<ByteData> Function(ByteData);

class PluginRegistry {
  final BinaryMessenger _binaryMessenger;

  PluginRegistry(this._binaryMessenger);

  Registrar registrarFor(Type key) => Registrar(_binaryMessenger);

  void registerMessageHandler() {
    ui.webOnlySetPluginHandler(_binaryMessenger.handlePlatformMessage);
  }
}

class Registrar {
  final BinaryMessenger messenger;

  Registrar(this.messenger);
}

final webPluginRegistry = PluginRegistry(_platformBinaryMessenger);

class _PlatformBinaryMessenger extends BinaryMessenger {
  final Map<String, _MessageHandler> _handlers = <String, _MessageHandler>{};
  final Map<String, _MessageHandler> _mockHandlers =
      <String, _MessageHandler>{};

  @override
  Future<void> handlePlatformMessage(String channel, ByteData data,
      ui.PlatformMessageResponseCallback callback) async {
    ByteData response;
    try {
      final MessageHandler handler = _handlers[channel];
      if (handler != null) {
        response = await handler(data);
      }
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'flutter web shell',
        context: ErrorDescription('during a plugin platform message call'),
      ));
    } finally {
      callback(response);
    }
  }

  /// Sends a platform message from the platform side back to the framework.
  @override
  Future<ByteData> send(String channel, ByteData message) {
    // TODO: implement send
    return null;
  }

  @override
  void setMessageHandler(
      String channel, Future<ByteData> Function(ByteData message) handler) {
    if (handler == null)
      _handlers.remove(channel);
    else
      _handlers[channel] = handler;
  }

  @override
  void setMockMessageHandler(
      String channel, Future<ByteData> Function(ByteData message) handler) {
    if (handler == null)
      _mockHandlers.remove(channel);
    else
      _mockHandlers[channel] = handler;
  }
}

final _PlatformBinaryMessenger _platformBinaryMessenger =
    _PlatformBinaryMessenger();

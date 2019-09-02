// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef _MessageHandler = Future<ByteData> Function(ByteData);

/// This class registers web platform plugins.
class PluginRegistry {
  /// Creates a plugin registry.
  PluginRegistry(this._binaryMessenger);

  final BinaryMessenger _binaryMessenger;

  /// Creates a registrar for the given plugin implementation class.
  Registrar registrarFor(Type key) => Registrar(_binaryMessenger);

  /// Registers this plugin handler with the engine, so that unrecognized
  /// platform messages are forwarded to the registry, where they can be
  /// correctly dispatched to one of the registered plugins.
  void registerMessageHandler() {
    // The function below is only defined in the Web dart:ui.
    // ignore: undefined_function
    ui.webOnlySetPluginHandler(_binaryMessenger.handlePlatformMessage);
  }
}

/// A registrar for a particular plugin.
///
/// Gives access to a [BinaryMessenger] which has been configured to receive
/// platform messages from the framework side.
class Registrar {
  /// Creates a registrar with the given [BinaryMessenger].
  Registrar(this.messenger);

  /// A [BinaryMessenger] configured to receive platform messages from the
  /// framework side.
  ///
  /// Use this [BinaryMessenger] when creating platform channels in order for
  /// them to receive messages from the platform side. For example:
  ///
  ///
  ///     class MyPlugin {
  ///       static void registerWith(Registrar registrar) {
  ///         final MethodChannel channel = MethodChannel(
  ///             'com.my_plugin/my_plugin',
  ///             const StandardMethodCodec(),
  ///             registrar.messenger);
  ///         final MyPlugin instance = MyPlugin();
  ///         channel.setMethodCallHandler(instance.handleMethodCall);
  ///       }
  ///       ...
  ///     }
  final BinaryMessenger messenger;
}

/// The default plugin registry for the web.
final PluginRegistry webPluginRegistry = PluginRegistry(pluginBinaryMessenger);

/// A [BinaryMessenger] which does the inverse of the default framework
/// messenger.
///
/// Instead of sending messages from the framework to the engine, this
/// receives messages from the framework and dispatches them to registered
/// plugins.
class _PlatformBinaryMessenger extends BinaryMessenger {
  final Map<String, _MessageHandler> _handlers = <String, _MessageHandler>{};

  /// Receives a platform message from the framework.
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
    throw FlutterError(
        'Cannot send messages from the platform side to the framework.');
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
    throw FlutterError(
        'Setting mock handlers is not supported on the platform side.');
  }
}

/// The default [BinaryMessenger] for Flutter Web plugins.
final BinaryMessenger pluginBinaryMessenger = _PlatformBinaryMessenger();

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'messages.dart';

typedef ToolExtensionHandler = FutureOr<Response> Function(Map<String, Object?> params);

/// An interface for registering RPC handlers for an extension service.
abstract interface class RpcRegistrar {
  /// Registers a handler for the given RPC [method].
  ///
  /// The [handler] is invoked when the tool calls the [method] on the extension.
  void registerRpc(String method, ToolExtensionHandler handler);
}

/// Base class for services provided by a Flutter Tool Extension.
///
/// Extensions can register one or more services to expose functionality to the
/// Flutter tool.
abstract class ToolExtensionService {
  /// Const constructor for subclasses.
  const ToolExtensionService();

  /// Initializes the service and registers its RPC handlers with the [registrar].
  ///
  /// This is called when the extension is starting up.
  FutureOr<void> initialize(RpcRegistrar registrar);

  /// Cleans up resources held by this service.
  ///
  /// This is called when the extension is shutting down.
  FutureOr<void> shutdown() => null;
}

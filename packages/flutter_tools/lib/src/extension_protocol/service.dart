// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A registrar interface used by extension services to register their RPC handlers.
abstract interface class RpcRegistrar {
  /// Registers an RPC handler for the given [method].
  ///
  /// The [handler] must be a [Function] that takes either zero arguments or one
  /// argument of type `Parameters` from `package:json_rpc_2`.
  void registerRpc(String method, Function handler);
}

/// Represents a one-way notification sent between the host tool and the extension.
class Notification {
  /// Creates a [Notification] with the given [method] and [params].
  const Notification({required this.method, this.params});

  /// The name of the method/event.
  final String method;

  /// The parameters associated with the notification, if any.
  final Map<String, Object?>? params;
}

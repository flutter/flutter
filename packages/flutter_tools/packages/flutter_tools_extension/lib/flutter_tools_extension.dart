// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Generic extension protocol base classes and extension interfaces for Flutter
/// tools extensibility.
///
/// This package defines the platform-agnostic RPC protocol framing, handshake,
/// and service handler interfaces implemented by extension authors.
library flutter_tools_extension;

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

export 'src/build.dart';
export 'src/config.dart';
export 'src/device.dart';
export 'src/diagnostics.dart';
export 'src/protocol_base/provider.dart';
export 'src/protocol_base/service.dart';
export 'src/templates.dart';

/// An exception thrown by tool extension service RPC handlers when a JSON-RPC
/// 2.0 request fails (for example, via `RpcException.invalidParams(...)`).
typedef RpcException = json_rpc.RpcException;

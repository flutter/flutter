// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'src/generic_extension_protocol/manager.dart';
/// @docImport 'src/generic_extension_protocol/provider.dart';
/// The Tool Extension Protocol library.
///
/// This library defines the communication protocol between the host Flutter tool
/// and extension isolates. It exposes the [ToolExtensionManager] for the host,
/// [ToolExtensionProvider] for the extension, and common service interfaces
/// and messages.
library generic_extension_protocol;

export 'package:json_rpc_2/json_rpc_2.dart' show Parameters, RpcException;

export 'src/generic_extension_protocol/manager.dart';
export 'src/generic_extension_protocol/provider.dart';
export 'src/generic_extension_protocol/service.dart';

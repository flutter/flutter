// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Testing utilities and harnesses for Flutter Tool Extensions.
///
/// Provides [ExtensionTestHarness] for in-process Isolate and JSON-RPC 2.0
/// testing, and [verifyExtensionPackage] for validating extension entrypoints
/// and runtime capabilities.
///
/// @docImport 'src/testing/harness.dart';
/// @docImport 'src/testing/verify_package.dart';
library flutter_tools_extension.testing;

export 'package:json_rpc_2/json_rpc_2.dart' show RpcException;

export 'flutter_tools_extension.dart';
export 'src/protocol_base/clients.dart';
export 'src/protocol_base/connection.dart' show ExtensionIsolateEntryPoint, ExtensionRpcChannel;
export 'src/testing/harness.dart';
export 'src/testing/verify_package.dart';

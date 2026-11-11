// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Testing utilities and harnesses for Flutter Tool Extensions.
///
/// Provides `createTestDependencies` and `MemoryExtensionFileSystem`,
/// `ExtensionTestHarness` for in-process Isolate and JSON-RPC 2.0 testing, and
/// `verifyExtensionPackage` for validating extension entrypoints and runtime
/// capabilities.
library flutter_tools_extension.testing;

export 'package:json_rpc_2/json_rpc_2.dart' show RpcException;

export 'flutter_tools_extension.dart';
export 'src/testing/clients.dart';
export 'src/testing/harness.dart';
export 'src/testing/test_dependencies.dart';
export 'src/testing/verify_package.dart';

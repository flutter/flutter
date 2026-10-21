// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Testing utilities and harnesses for Flutter Tool Extensions.
///
/// Provides `createTestDependencies` and test doubles (`MemoryExtensionFileSystem`,
/// `FakeExtensionProcessManager`, `BufferExtensionLogger`), `ExtensionTestHarness`
/// for in-process Isolate and JSON-RPC 2.0 testing, and `verifyExtensionPackage`
/// for validating `extension/flutter_tools/config.yaml` manifests against
/// runtime extension capabilities.
library flutter_tools_extension.testing;

export 'flutter_tools_extension.dart';
export 'src/testing.dart';
export 'src/testing/test_dependencies.dart';

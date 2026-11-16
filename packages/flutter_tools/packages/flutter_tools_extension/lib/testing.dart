// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Testing utilities and harnesses for Flutter Tool Extensions.
///
/// Provides [ServiceTestHarness] for in-process testing of
/// [ToolExtensionService] implementations and [verifyExtensionPackage] for
/// validating extension entrypoints and runtime capabilities over JSON-RPC 2.0.
///
/// @docImport 'src/protocol_base/service.dart';
/// @docImport 'src/testing/service_harness.dart';
/// @docImport 'src/testing/verify_package.dart';
library flutter_tools_extension.testing;

export 'flutter_tools_extension.dart';
export 'src/testing/service_harness.dart';
export 'src/testing/verify_package.dart';

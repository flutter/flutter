// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Host and test-harness JSON-RPC 2.0 isolate connection and typed wire clients
/// for communicating with Flutter Tool extension isolates.
library flutter_tools_extension.client;

export 'src/protocol_base/clients.dart';
export 'src/protocol_base/connection.dart';
export 'src/protocol_base/service.dart' show ToolExtensionCapabilities;

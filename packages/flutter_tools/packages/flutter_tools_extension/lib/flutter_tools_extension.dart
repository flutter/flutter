// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Generic extension protocol base classes and extension interfaces for Flutter
/// tools extensibility.
///
/// This package defines the platform-agnostic RPC protocol framing, handshake,
/// and service handler interfaces implemented by extension authors.
library flutter_tools_extension;

export 'src/diagnostics.dart';
export 'src/protocol_base/provider.dart';
export 'src/protocol_base/service.dart';

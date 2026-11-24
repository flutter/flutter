// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Wire protocol version exchanged during `extension.getCapabilities`.
///
/// Incremented only on breaking JSON-RPC wire-protocol changes; additive
/// methods, notifications, and defaulted fields keep this version unchanged.
const int kExtensionProtocolVersion = 1;

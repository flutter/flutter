// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui;

/// This is a no-op on non-web platforms.
void setPluginHandler(Future<void> Function(String, ByteData?, ui.PlatformMessageResponseCallback?) handler) {}

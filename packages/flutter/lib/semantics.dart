// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The Flutter semantics package.
///
/// To use, import `package:flutter/semantics.dart`.
///
/// The [SemanticsEvent] classes define the protocol for sending semantic events
/// to the platform.
///
/// The [SemanticsNode] hierarchy represents the semantic structure of the UI
/// and is used by the platform-specific accessibility services.
library semantics;

export 'src/semantics/binding.dart';
export 'src/semantics/debug.dart';
export 'src/semantics/semantics.dart';
export 'src/semantics/semantics_service.dart';

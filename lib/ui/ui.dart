// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Built-in types and core primitives for a Flutter application.
///
/// To use, import `dart:ui`.
///
/// This library exposes the lowest-level services that Flutter frameworks use
/// to bootstrap applications, such as methods to obtain handles for the mojo
/// IPC system, classes for driving the graphics and text layout and rendering
/// subsystems, callbacks for integrating with the engine scheduler and the
/// pointer input system, and functions for image decoding.
library dart_ui;

import 'dart:_internal';
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:mojo.internal';
import 'dart:nativewrappers';
import 'dart:typed_data';

part 'compositing.dart';
part 'geometry.dart';
part 'hash_codes.dart';
part 'hooks.dart';
part 'lerp.dart';
part 'mojo_services.dart';
part 'natives.dart';
part 'painting.dart';
part 'text.dart';
part 'window.dart';

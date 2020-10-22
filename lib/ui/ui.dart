// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Built-in types and core primitives for a Flutter application.
///
/// To use, import `dart:ui`.
///
/// This library exposes the lowest-level services that Flutter frameworks use
/// to bootstrap applications, such as classes for driving the input, graphics
/// text, layout, and rendering subsystems.
// @dart = 2.10
library dart.ui;

import 'dart:_internal' hide Symbol; // ignore: unused_import
import 'dart:async';
import 'dart:collection' as collection;
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io'; // ignore: unused_import
import 'dart:isolate' show SendPort;
import 'dart:math' as math;
import 'dart:nativewrappers';
import 'dart:typed_data';

part 'annotations.dart';
part 'channel_buffers.dart';
part 'compositing.dart';
part 'geometry.dart';
part 'hash_codes.dart';
part 'hooks.dart';
part 'isolate_name_server.dart';
part 'lerp.dart';
part 'natives.dart';
part 'painting.dart';
part 'platform_dispatcher.dart';
part 'plugins.dart';
part 'pointer.dart';
part 'semantics.dart';
part 'text.dart';
part 'window.dart';

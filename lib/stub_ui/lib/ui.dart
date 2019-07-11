// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This library defines the web equivalent of the native dart:ui.
///
/// All types in this library are public.
library ui;

import 'dart:async';
import 'dart:collection';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';

import 'src/engine.dart' as engine;
export 'src/engine.dart'
    show persistedPictureFactory, houdiniPictureFactory, platformViewRegistry;

part 'src/ui/canvas.dart';
part 'src/ui/compositing.dart';
part 'src/ui/geometry.dart';
part 'src/ui/hash_codes.dart';
part 'src/ui/initialization.dart';
part 'src/ui/lerp.dart';
part 'src/ui/natives.dart';
part 'src/ui/painting.dart';
part 'src/ui/pointer.dart';
part 'src/ui/semantics.dart';
part 'src/ui/test_embedding.dart';
part 'src/ui/text.dart';
part 'src/ui/tile_mode.dart';
part 'src/ui/window.dart';

/// Provides a compile time constant to customize flutter framework and other
/// users of ui engine for web runtime.
const bool isWeb = true;

/// Web specific SMI. Used by bitfield. The 0x3FFFFFFFFFFFFFFF used on VM
/// is not supported on Web platform.
const int kMaxUnsignedSMI = -1;

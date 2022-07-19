// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The Flutter gesture recognizers.
///
/// To use, import `package:flutter/gestures.dart`.
library gestures;

export 'dart:ui' show FlutterView, Offset, PointerData, PointerDeviceKind;

export 'package:flutter/foundation.dart';
export 'package:vector_math/vector_math_64.dart' show Matrix4;

export 'src/gestures/arena.dart';
export 'src/gestures/binding.dart';
export 'src/gestures/constants.dart';
export 'src/gestures/converter.dart';
export 'src/gestures/debug.dart';
export 'src/gestures/drag.dart';
export 'src/gestures/drag_details.dart';
export 'src/gestures/eager.dart';
export 'src/gestures/events.dart';
export 'src/gestures/force_press.dart';
export 'src/gestures/gesture_settings.dart';
export 'src/gestures/hit_test.dart';
export 'src/gestures/long_press.dart';
export 'src/gestures/lsq_solver.dart';
export 'src/gestures/monodrag.dart';
export 'src/gestures/multidrag.dart';
export 'src/gestures/multitap.dart';
export 'src/gestures/pointer_router.dart';
export 'src/gestures/pointer_signal_resolver.dart';
export 'src/gestures/recognizer.dart';
export 'src/gestures/resampler.dart';
export 'src/gestures/scale.dart';
export 'src/gestures/tap.dart';
export 'src/gestures/team.dart';
export 'src/gestures/velocity_tracker.dart';

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The Flutter rendering tree.
///
/// To use, import `package:flutter/rendering.dart`.
///
/// The [RenderObject] hierarchy is used by the Flutter Widgets library to
/// implement its layout and painting back-end. Generally, while you may use
/// custom [RenderBox] classes for specific effects in your applications, most
/// of the time your only interaction with the [RenderObject] hierarchy will be
/// in debugging layout issues.
///
/// If you are developing your own library or application directly on top of the
/// rendering library, then you will want to have a binding (see [BindingBase]).
/// You can use [RenderingFlutterBinding], or you can create your own binding.
/// If you create your own binding, it needs to import at least
/// [ServicesBinding], [GestureBinding], [SchedulerBinding], [PaintingBinding],
/// and [RendererBinding]. The rendering library does not automatically create a
/// binding, but relies on one being initialized with those features.
library rendering;

export 'package:flutter/foundation.dart' show
  VoidCallback,
  ValueChanged,
  ValueGetter,
  ValueSetter,
  DiagnosticLevel;
export 'package:flutter/semantics.dart';
export 'package:vector_math/vector_math_64.dart' show Matrix4;

export 'src/rendering/rendering.dart';

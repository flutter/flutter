// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The Flutter painting library.
///
/// To use, import `package:flutter/painting.dart`.
///
/// This library includes a variety of classes that wrap the Flutter
/// engine's painting API for more specialized purposes, such as painting scaled
/// images, interpolating between shadows, painting borders around boxes, etc.
///
/// In particular:
///
///  * Use the [TextPainter] class for painting text.
///  * Use [Decoration] (and more concretely [BoxDecoration]) for
///    painting boxes.
library painting;

export 'src/painting/basic_types.dart';
export 'src/painting/border.dart';
export 'src/painting/border_radius.dart';
export 'src/painting/box_fit.dart';
export 'src/painting/box_painter.dart';
export 'src/painting/colors.dart';
export 'src/painting/decoration.dart';
export 'src/painting/edge_insets.dart';
export 'src/painting/flutter_logo.dart';
export 'src/painting/fractional_offset.dart';
export 'src/painting/gradient.dart';
export 'src/painting/text_painter.dart';
export 'src/painting/text_span.dart';
export 'src/painting/text_style.dart';
export 'src/painting/transforms.dart';
export 'src/painting/utils.dart';

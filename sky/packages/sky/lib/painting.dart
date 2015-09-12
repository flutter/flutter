// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Utilities for painting.
///
/// This library includes and re-exports a variety of classes that wrap the Sky
/// engine's painting API for more specialised purposes, such as painting scaled
/// images, interpolating between shadows, painting borders around boxes, etc.
library painting;

export 'src/painting/box_painter.dart';
export 'src/painting/radial_reaction.dart';
export 'src/painting/shadows.dart';
export 'src/painting/text_painter.dart';
export 'src/painting/text_style.dart';

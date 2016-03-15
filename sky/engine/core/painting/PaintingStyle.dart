// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

// List of predefined painting styles. This list comes from Skia's
// SkPaint.h and the values (order) should be kept in sync.

/// Strategies for painting shapes and paths on a canvas.
///
/// See [Paint.style].
enum PaintingStyle {
  /// Apply the [Paint] to the inside of the shape. For example, when
  /// applied to the [Paint.drawCircle] call, this results in a disc
  /// of the given size being painted.
  fill,

  /// Apply the [Paint] to the edge of the shape. For example, when
  /// applied to the [Paint.drawCircle] call, this results is a hoop
  /// of the given size being painted. The line drawn on the edge will
  /// be the width given by the [Paint.strokeWidth] property.
  stroke,

  /// Apply the [Paint] to the inside of the shape and the edge of the
  /// shape at the same time. The resulting drawing is similar to what
  /// would be achieved by inflating the shape by half the stroke
  /// width (as given by [Paint.strokeWidth]), and then using [fill].
  strokeAndFill,
}

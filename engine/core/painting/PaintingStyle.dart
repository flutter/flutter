// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.sky;

/// List of predefined painting styles. This list comes from Skia's
/// SkPaint.h and the values (order) should be kept in sync.
enum PaintingStyle {
  fill,
  stroke,
  strokeAndFill,
}

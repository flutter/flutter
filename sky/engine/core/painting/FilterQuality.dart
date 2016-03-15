// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

// List of predefined filter quality modes. This list comes from Skia's
// SkFilterQuality.h and the values (order) should be kept in sync.

/// Quality levels for image filters.
///
/// See [Paint.filterQuality].
enum FilterQuality {
  none,
  low,
  medium,
  high,
}

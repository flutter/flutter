// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.sky;

/// Blur styles. These mirror SkBlurStyle and must be kept in sync.
enum BlurStyle {
  normal,  /// Fuzzy inside and outside.
  solid,  /// Solid inside, fuzzy outside.
  outer,  /// Nothing inside, fuzzy outside.
  inner,  /// Fuzzy inside, nothing outside.
}

// Extends the generated _MaskFilter interface via the PrivateDart attribute.
class MaskFilter extends _MaskFilter {
  MaskFilter.blur(BlurStyle style, double sigma,
                  {bool ignoreTransform: false, bool highQuality: false})
      : super(style.index, sigma, _makeBlurFlags(ignoreTransform, highQuality));

  // Convert constructor parameters to the SkBlurMaskFilter::BlurFlags type.
  static int _makeBlurFlags(bool ignoreTransform, bool highQuality) {
    int flags = 0;
    if (ignoreTransform) flags |= 0x01;
    if (highQuality) flags |= 0x02;
    return flags;
  }
}

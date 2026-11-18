// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_BASE_FLAGS_H_
#define FLUTTER_IMPELLER_BASE_FLAGS_H_

namespace impeller {
struct Flags {
  /// Use SDFs for rendering.
  bool use_sdfs = false;

  /// Whether the origin of the default framebuffer (framebuffer 0) is the
  /// top-left of the window rather than OpenGL's usual bottom-left.
  ///
  /// Set by embedders whose window surface is created with an inverted Y
  /// axis, such as ANGLE's EGL_SURFACE_ORIENTATION_INVERT_Y_ANGLE. Only
  /// meaningful for the OpenGL ES backend.
  bool top_left_default_framebuffer_origin = false;

  bool operator==(const Flags&) const = default;
};
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_BASE_FLAGS_H_

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/blending.glsl>

vec3 Blend(vec3 dst, vec3 src) {
  return IPBlendColor(dst, src);
}

#include "framebuffer_blend.glsl"

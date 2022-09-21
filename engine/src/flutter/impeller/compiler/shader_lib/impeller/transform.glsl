// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TRANSFORM_GLSL_
#define TRANSFORM_GLSL_

/// Returns the Cartesian coordinates of `position` in `transform` space.
vec2 IPVec2TransformPosition(mat4 matrix, vec2 point) {
  vec4 transformed = matrix * vec4(point, 0, 1);
  return transformed.xy / transformed.w;
}

#endif

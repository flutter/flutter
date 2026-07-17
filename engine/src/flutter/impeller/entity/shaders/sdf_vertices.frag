// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/gaussian.glsl>
#include <impeller/types.glsl>

uniform FragInfo {
  // path_color is the premultiplied color supplied to DrawPath (or other
  // Draw call that was generalized to a path). It will be modulated by the
  // coverage opacity of the sdf function, provided by the per vertex data.
  f16vec4 path_color;
}
frag_info;

// v_sdf will contain the distance to the edge of the shape measured in
// the number of "antialias" pixels. Negative distances are outside the
// shape and positive distances are inside the shape. Half an antialias
// pixel outside the shape is mapped to a coverage alpha of 0.0 by the
// smoothstep function and half an antialias pixel inside the shape is
// mapped to a coverage alpha of 1.0 by the smoothstep.
in float16_t v_gaussian;

out f16vec4 frag_color;

// A shader that modulates the path color by a smoothstep of the v_sdf
// parameter.
void main() {
  frag_color = frag_info.path_color * smoothstep(-0.5, 0.5, v_gaussian);
}

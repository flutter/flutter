// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#version 450
layout(set = 0, binding = 0) uniform sampler2D backing_store;
layout(push_constant) uniform Placement {
  ivec2 origin;
}
layer;
layout(location = 0) out vec4 color;
void main() {
  color = texelFetch(backing_store, ivec2(gl_FragCoord.xy) - layer.origin, 0);
}

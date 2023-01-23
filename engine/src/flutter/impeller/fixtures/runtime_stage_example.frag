// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

layout(location = 0) uniform vec2 iResolution;
layout(location = 1) uniform float iTime;

layout(location = 0) out vec4 fragColor;

void main() {
  vec2 uv = gl_FragCoord.xy / iResolution;
  float t = 4 * iTime;
  vec3 col = 0.5 + 0.5 * cos(t + uv.xyx + vec3(0, 1, 4));
  fragColor = vec4(col, 1.0);
}

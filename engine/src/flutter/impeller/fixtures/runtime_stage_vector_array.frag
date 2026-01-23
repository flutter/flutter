// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <flutter/runtime_effect.glsl>

uniform vec2 iResolution;
uniform vec4 iValues[1];

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord() / iResolution;
  float value;
  if (uv.y < .25) {
    value = iValues[0].r;
  } else if (uv.y < .5) {
    value = iValues[0].g;
  } else if (uv.y < .75) {
    value = iValues[0].b;
  } else {
    value = iValues[0].a;
  }
  vec3 color = vec3(value);
  fragColor = vec4(color, 1);
}

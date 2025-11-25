#version 320 es

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <flutter/runtime_effect.glsl>

out vec4 fragColor;
uniform vec2 uSize;

void main() {
    vec2 p = FlutterFragCoord().xy / uSize;
    vec2 center = vec2(0.5, 0.5);
    float radius = 0.25;
    float d = length(p - center) - radius;
    fragColor = vec4(d, 0.0, 0.0, 1.0);
}

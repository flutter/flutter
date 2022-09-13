#version 460 es

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision highp float;

layout (location = 0) uniform float animation;
layout (location = 1) uniform float width;
layout (location = 2) uniform float height;
layout (location = 3) uniform sampler2D source;

layout(location = 0) out vec4 fragColor;

void main() {
    vec2 p = gl_FragCoord.xy;
    float animated = 200 * animation;
    vec2 uv = round(p / vec2(width, height) * animated) / animated;
    fragColor = texture(source, uv) * (animation);
}

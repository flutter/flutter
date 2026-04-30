#version 320 es

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// If updating this file, also update
// engine/src/flutter/lib/web_ui/test/ui/fragment_shader_test.dart

precision highp float;

uniform vec2[2] color_array;

out vec4 fragColor;

void main() {
  fragColor = vec4(color_array[0].x, color_array[0].y, color_array[1].x,
                   color_array[1].y);
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// If updating this file, also update
// engine/src/flutter/lib/web_ui/test/canvaskit/fragment_program_test.dart and
// engine/src/flutter/lib/web_ui/test/ui/fragment_shader_test.dart

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uFloats[10];
uniform float uLoneFloat;
uniform vec2 uVectors[3];
uniform vec3 uLoneVector;
uniform mat4 uMatrices[2];
uniform mat4 uLoneMatrix;

out vec4 fragColor;

void main() {
  vec2 pos = FlutterFragCoord().xy;
  vec2 uv = pos / uSize;
  float barWidth = 0.100000001490116119384765625;
  float barIndex = floor(uv.x / barWidth);
  for (int i = 0; i < 10; i++) {
    if (i == int(barIndex)) {
      float barHeight = uFloats[i];
      if (uv.y > (1.0 - barHeight)) {
        fragColor =
            vec4(0.3300000131130218505859375, 0.0900000035762786865234375,
                 0.0900000035762786865234375, 1.0);
      } else {
        fragColor = vec4(1.0);
      }
    }
  }
}

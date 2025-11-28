// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;

  vec2 screenUV = vec2(fragCoord.x / uSize.x, fragCoord.y / uSize.y);
  vec2 correctedScreenUV = screenUV;
#ifdef IMPELLER_TARGET_OPENGLES
  correctedScreenUV.y = 1.0 - screenUV.y;
#endif
  vec4 texColor = texture(uTexture, correctedScreenUV);

  // Check if we're within 20px of any edge
  float borderWidth = 20.0;
  bool inBorder =
      fragCoord.x < borderWidth || fragCoord.x > (uSize.x - borderWidth) ||
      fragCoord.y < borderWidth || fragCoord.y > (uSize.y - borderWidth);

  if (inBorder) {
    fragColor = vec4(0.5, 0.0, 0.5, 1.0);  // Purple border
  } else {
    fragColor = vec4(screenUV, 0.0, 1.0);
    fragColor = mix(fragColor, texColor, .5);
  }
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// If updating this file, also update
// engine/src/flutter/lib/web_ui/test/ui/fragment_shader_test.dart

#include <flutter/runtime_effect.glsl>

uniform float uTileSize;

out vec4 fragColor;

float rand(vec2 co) {
  return fract(sin(dot(co, vec2(12.98980045318603515625, 78.233001708984375))) *
               43758.546875);
}

vec2 fuzzGridPoint(vec2 coordinate) {
  return coordinate +
         vec2((rand(coordinate * 400.0) - 0.5) * 0.800000011920928955078125,
              (rand(coordinate * 400.0) - 0.5) * 0.800000011920928955078125);
}

vec3 getColorForGridPoint(vec2 coordinate) {
  return vec3(rand(coordinate * 100.0), rand(coordinate * 200.0),
              rand(coordinate * 300.0));
}

void main() {
  vec2 uv = FlutterFragCoord().xy / vec2(uTileSize);
  vec2 upperLeft = floor(uv);
  vec2 upperRight = vec2(ceil(uv.x), floor(uv.y));
  vec2 bottomLeft = vec2(floor(uv.x), ceil(uv.y));
  vec2 bottomRight = ceil(uv);
  vec2 closestPoint = upperLeft;
  float dist = distance(uv, fuzzGridPoint(upperLeft));
  float upperRightDistance = distance(uv, fuzzGridPoint(upperRight));
  if (upperRightDistance < dist) {
    dist = upperRightDistance;
    closestPoint = upperRight;
  }
  float bottomLeftDistance = distance(uv, fuzzGridPoint(bottomLeft));
  if (bottomLeftDistance < dist) {
    dist = bottomLeftDistance;
    closestPoint = bottomLeft;
  }
  float bottomRightDistance = distance(uv, fuzzGridPoint(bottomRight));
  if (bottomRightDistance < dist) {
    dist = bottomRightDistance;
    closestPoint = bottomRight;
  }
  fragColor = vec4(getColorForGridPoint(closestPoint), 1.0);
}

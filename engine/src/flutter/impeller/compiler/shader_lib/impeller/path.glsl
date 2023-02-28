// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef PATH_GLSL_
#define PATH_GLSL_

#define MOVE 0
#define LINE 1
#define QUAD 2
#define CUBIC 3

struct LineData {
  vec2 p1;
  vec2 p2;
};

struct QuadData {
  vec2 p1;
  vec2 cp;
  vec2 p2;
};

struct CubicData {
  vec2 p1;
  vec2 cp1;
  vec2 cp2;
  vec2 p2;
};

struct Position {
  uint index;
  uint count;
};

/// Solve for point on a quadratic Bezier curve defined by starting point `p1`,
/// control point `cp`, and end point `p2` at time `t`.
vec2 QuadraticSolve(QuadData quad, float t) {
  return (1.0 - t) * (1.0 - t) * quad.p1 +  //
         2.0 * (1.0 - t) * t * quad.cp +    //
         t * t * quad.p2;
}

vec2 CubicSolve(CubicData cubic, float t) {
  return (1. - t) * (1. - t) * (1. - t) * cubic.p1 +  //
         3 * (1. - t) * (1. - t) * t * cubic.cp1 +    //
         3 * (1. - t) * t * t * cubic.cp2 +           //
         t * t * t * cubic.p2;
}

/// Used to approximate quadratic curves using parabola.
///
/// See
/// https://raphlinus.github.io/graphics/curves/2019/12/23/flatten-quadbez.html
float ApproximateParabolaIntegral(float x) {
  float d = 0.67;
  return x / (1.0 - d + sqrt(sqrt(pow(d, 4) + 0.25 * x * x)));
}

bool isfinite(float f) {
  return !isnan(f) && !isinf(f);
}

float Cross(vec2 p1, vec2 p2) {
  return p1.x * p2.y - p1.y * p2.x;
}

#endif

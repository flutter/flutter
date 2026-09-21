// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SDF_FUNCTIONS_GLSL_
#define SDF_FUNCTIONS_GLSL_

const float PI = 3.14159265;
const float TWO_PI = 6.28318531;
const float PI_OVER_FOUR = 0.78539816;

// SDF for a superellipse defined by (x/a)^n + (y/b)^n = 1
//
// `p` is the coordinate of the point relative to the center of the superellipse
// normalized by the length of the ellipse semi-axes (a, b)
// `n` is the exponent of the superellipse
//
// https://iquilezles.org/articles/ellipsedist/
//
// The MIT License
// Copyright © 2015 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions: The above copyright
// notice and this permission notice shall be included in all copies or
// substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS",
// WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
// TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
// THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// https://www.youtube.com/c/InigoQuilez
// https://iquilezles.org

float sdSuperellipse(vec2 p, float n) {
  // symmetries
  p = abs(p);
  if (p.y > p.x)
    p = p.yx;

  n = 2.0 / n;  // note the remapping in order to match the implicit versions

  float xa = 0.0, xb = TWO_PI / 8.0;
  for (int i = 0; i < 6; i++) {
    float x = 0.5 * (xa + xb);
    float c = cos(x);
    float s = sin(x);
    float cn = pow(c, n);
    float sn = pow(s, n);
    float y = (p.x - cn) * cn * s * s - (p.y - sn) * sn * c * c;

    if (y < 0.0)
      xa = x;
    else
      xb = x;
  }
  // compute distance
  vec2 qa = pow(vec2(cos(xa), sin(xa)), vec2(n));
  vec2 qb = pow(vec2(cos(xb), sin(xb)), vec2(n));
  vec2 pa = p - qa, ba = qb - qa;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - ba * h) * sign(pa.x * ba.y - pa.y * ba.x);
}

#endif

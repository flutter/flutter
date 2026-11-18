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
//
// Shaders that include this file can define SD_SUPERELLIPSE_PRECISION as
// `highp` to compute it in highp (otherwise it uses the default precision).
// The result is a distance in units of the axis length, and it has to resolve
// a fraction of a device pixel, so for shapes hundreds of pixels across it
// needs more than mediump's 11 bits. That applies to the bisection as well:
// unlike Newton's method it does not correct a wrong step, so a search done at
// lower precision than the result gives the distance to the wrong segment for
// some pixels.

#ifndef SD_SUPERELLIPSE_PRECISION
#define SD_SUPERELLIPSE_PRECISION
#endif

SD_SUPERELLIPSE_PRECISION float sdSuperellipse(
    SD_SUPERELLIPSE_PRECISION vec2 p,
    SD_SUPERELLIPSE_PRECISION float n) {
  // symmetries
  p = abs(p);
  if (p.y > p.x)
    p = p.yx;

  n = 2.0 / n;  // note the remapping in order to match the implicit versions

  SD_SUPERELLIPSE_PRECISION float xa = 0.0, xb = TWO_PI / 8.0;
  for (int i = 0; i < 6; i++) {
    SD_SUPERELLIPSE_PRECISION float x = 0.5 * (xa + xb);
    SD_SUPERELLIPSE_PRECISION float c = cos(x);
    SD_SUPERELLIPSE_PRECISION float s = sin(x);
    SD_SUPERELLIPSE_PRECISION float cn = pow(c, n);
    SD_SUPERELLIPSE_PRECISION float sn = pow(s, n);
    SD_SUPERELLIPSE_PRECISION float y =
        (p.x - cn) * cn * s * s - (p.y - sn) * sn * c * c;

    if (y < 0.0)
      xa = x;
    else
      xb = x;
  }
  // compute distance
  SD_SUPERELLIPSE_PRECISION vec2 qa = pow(vec2(cos(xa), sin(xa)), vec2(n));
  SD_SUPERELLIPSE_PRECISION vec2 qb = pow(vec2(cos(xb), sin(xb)), vec2(n));
  SD_SUPERELLIPSE_PRECISION vec2 pa = p - qa, ba = qb - qa;
  SD_SUPERELLIPSE_PRECISION float h =
      clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - ba * h) * sign(pa.x * ba.y - pa.y * ba.x);
}

#endif

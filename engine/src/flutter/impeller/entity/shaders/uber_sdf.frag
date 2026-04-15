// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision mediump float;

#include <impeller/color.glsl>
#include <impeller/types.glsl>

uniform FragInfo {
  vec4 color;
  vec2 center;
  vec2 size;
  float stroke_width;
  float stroke_join;
  float aa_pixels;
  float stroked;
  float type;
}
frag_info;

out vec4 frag_color;

highp in vec2 v_position;

bool typeIsCircle() {
  return abs(frag_info.type - 0.0) < 0.01;
}

bool typeIsRect() {
  return abs(frag_info.type - 1.0) < 0.01;
}

bool typeIsOval() {
  return abs(frag_info.type - 2.0) < 0.01;
}

float distanceFromCircle(vec2 p, float radius) {
  return length(p) - radius;
}

float distanceFromRect(vec2 p, vec2 b) {
  vec2 d = abs(p) - b;
  return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// Define an ellipse as q(w) = (a*cos(w), b*sin(w)), and p = (x, y) on the
// plane. Let q(w0) be the closest point on q to p, then q(w0) - p is tangent to
// q(w0), and (q(w0) - p) dot q'(w0) = 0. This function uses the Newton-Raphson
// method to find q(w0).
//
// `p` is the coordinate of the point relative to the center of the oval
// `ab` is the extent of the oval from the center to the x and y axis
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

float distanceFromOval(vec2 p, vec2 ab) {
  // The ellipse is symmetric along both axes, do the calculation in the upper
  // right quadrant.
  p = abs(p);

  // Initial guess for w0. Determine whether q is closer to the top of the
  // ellipse or closer to the righthand side. Use the top (0) or righthand side
  // (pi/2) as the initial guess for w0.
  vec2 q = ab * (p - ab);
  float w = (q.x < q.y) ? 1.570796327 : 0.0;
  for (int i = 0; i < 5; i++) {
    vec2 cs = vec2(cos(w), sin(w));

    // u = q(w) = (a*cos(w), b*sin(w))
    vec2 u = ab * vec2(cs.x, cs.y);

    // v = q'(w) = (a*-sin(w), b*cos(w))
    vec2 v = ab * vec2(-cs.y, cs.x);

    // Newton-Raphson update step, w_n = w_n-1 + f(w_n-1)/f'(w_n-1)
    // In this case f(w) = (p - q(w)) dot q'(w) = (p - u) dot v
    w = w + dot(p - u, v) / (dot(p - u, u) + dot(v, v));
  }

  // Compute final point and distance
  float d = length(p - ab * vec2(cos(w), sin(w)));

  // Return signed distance.
  // p is outside the ellipse if (p.x/a)^2 + (p.y/b)^2 > 0
  return (dot(p / ab, p / ab) > 1.0) ? d : -d;
}

float distanceFromChamferRect(vec2 p, vec2 b, float chamfer) {
  vec2 d = abs(p) - b;

  d = (d.y > d.x) ? d.yx : d.xy;
  d.y += chamfer;

  const float k = 1.0 - sqrt(2.0);
  if (d.y < 0.0 && d.y + d.x * k < 0.0) {
    return d.x;
  }

  if (d.x < d.y) {
    return (d.x + d.y) * sqrt(0.5);
  }

  return length(d);
}

float filledSDF(vec2 p) {
  if (typeIsCircle()) {  // Circle
    return distanceFromCircle(p, frag_info.size.x);
  } else if (typeIsRect()) {  // Rect
    return distanceFromRect(p, frag_info.size);
  } else {
    return distanceFromOval(p, frag_info.size);
  }
}

float strokedSDF(vec2 p) {
  float half_stroke = max(frag_info.stroke_width, 0.0) * 0.5;
  float outer;
  float inner;

  if (typeIsCircle()) {
    outer = distanceFromCircle(p, frag_info.size.x + half_stroke);
    inner = distanceFromCircle(p, frag_info.size.x - half_stroke);
  } else if (typeIsRect()) {
    if (frag_info.stroke_join < 0.5) {  // Miter
      // Rectangle expanded by half_stroke
      outer = distanceFromRect(p, frag_info.size + half_stroke);
    } else if (frag_info.stroke_join < 1.5) {  // Bevel
      // Rectangle expanded by half_stroke, with half_stroke chamfer
      outer =
          distanceFromChamferRect(p, frag_info.size + half_stroke, half_stroke);
    } else {  // Round
      // Rectangle sdf expanded by half_stroke, to give a half_stroke radius
      // https://www.shadertoy.com/view/NfXSDr
      outer = distanceFromRect(p, frag_info.size) - half_stroke;
    }
    inner = distanceFromRect(p, frag_info.size - half_stroke);
  } else {
    outer = distanceFromOval(p, frag_info.size) - half_stroke;
    inner = distanceFromOval(p, frag_info.size) + half_stroke;
  }

  return max(outer, -inner);
}

void main() {
  vec2 p = v_position - frag_info.center;

  float dist = (frag_info.stroked < 0.5) ? filledSDF(p) : strokedSDF(p);

  // Anti-aliasing
  // fwidth(dist) gives the change in SDF per pixel.
  float fade_size = fwidth(dist) * frag_info.aa_pixels * 0.5;

  float alpha = 1.0 - smoothstep(-fade_size, fade_size, dist);

  frag_color = vec4(frag_info.color.rgb, frag_info.color.a * alpha);
  frag_color = IPPremultiply(frag_color);
}

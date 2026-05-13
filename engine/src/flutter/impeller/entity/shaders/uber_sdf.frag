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
  vec4 superellipse_degrees_top;
  vec4 superellipse_degrees_right;
  vec4 superellipse_semi_axes_top;
  vec4 superellipse_semi_axes_right;
  vec4 angle_spans_top;
  vec4 angle_spans_right;
  vec4 octant_offsets_c;
  vec4 radii_width;
  vec4 radii_height;
  vec4 circle_centers_top_x;
  vec4 circle_centers_top_y;
  vec4 circle_centers_right_x;
  vec4 circle_centers_right_y;
  vec4 superellipse_scales_x;
  vec4 superellipse_scales_y;
  vec4 quadrant_centers_x;
  vec4 quadrant_centers_y;
  vec4 quadrant_splits;
}
frag_info;

out vec4 frag_color;

highp in vec2 v_position;

const float PI = 3.14159265;
const float TWO_PI = 6.28318531;
const float PI_OVER_FOUR = 0.78539816;

float distanceFromCircle(vec2 p, float radius) {
  return length(p) - radius;
}

float distanceFromRect(vec2 p, vec2 b) {
  vec2 d = abs(p) - b;
  return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

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

float getComponent(vec4 v, int index) {
  if (index == 0)
    return v.x;
  if (index == 1)
    return v.y;
  if (index == 2)
    return v.z;
  return v.w;
}

float smax(float a, float b, float k) {
  float m = max(a, b);
  // Taper the smoothing factor to 0 outside the shape to prevent
  // bloat/overdraw.
  float effective_k = k * smoothstep(0.0, -k, m);
  if (effective_k < 0.001)
    return m;

  float h = clamp(0.5 + 0.5 * (b - a) / effective_k, 0.0, 1.0);
  return mix(a, b, h) + effective_k * h * (1.0 - h);
}

float getQuadrantDistance(vec2 p, int quadrant_index) {
  float se_degree_top =
      getComponent(frag_info.superellipse_degrees_top, quadrant_index);
  float se_degree_right =
      getComponent(frag_info.superellipse_degrees_right, quadrant_index);
  float se_a_top =
      getComponent(frag_info.superellipse_semi_axes_top, quadrant_index);
  float se_a_right =
      getComponent(frag_info.superellipse_semi_axes_right, quadrant_index);
  float angle_span_top =
      getComponent(frag_info.angle_spans_top, quadrant_index);
  float angle_span_right =
      getComponent(frag_info.angle_spans_right, quadrant_index);
  float c = getComponent(frag_info.octant_offsets_c, quadrant_index);
  float radius_top = getComponent(frag_info.radii_width, quadrant_index);
  float radius_right = getComponent(frag_info.radii_height, quadrant_index);

  vec2 circle_center_top =
      vec2(getComponent(frag_info.circle_centers_top_x, quadrant_index),
           getComponent(frag_info.circle_centers_top_y, quadrant_index));
  vec2 circle_center_right =
      vec2(getComponent(frag_info.circle_centers_right_x, quadrant_index),
           getComponent(frag_info.circle_centers_right_y, quadrant_index));

  vec2 scale =
      vec2(getComponent(frag_info.superellipse_scales_x, quadrant_index),
           getComponent(frag_info.superellipse_scales_y, quadrant_index));

  vec2 q_center =
      vec2(getComponent(frag_info.quadrant_centers_x, quadrant_index),
           getComponent(frag_info.quadrant_centers_y, quadrant_index));

  vec2 q_sign = vec2(1.0);
  if (quadrant_index == 0)
    q_sign = vec2(1.0, -1.0);
  else if (quadrant_index == 1)
    q_sign = vec2(1.0, 1.0);
  else if (quadrant_index == 2)
    q_sign = vec2(-1.0, 1.0);
  else
    q_sign = vec2(-1.0, -1.0);

  vec2 p_local = (p - q_center) * q_sign;

  vec2 p_clamped = max(p_local, 0.0);

  vec2 p_norm = p_clamped / scale;

  float se_degree;
  float span;
  float radius;
  vec2 circle_center;
  float axis_length;
  vec2 p_oct;

  if (p_norm.y + c > p_norm.x) {
    p_oct = p_norm + vec2(0.0, c);
    se_degree = se_degree_top;
    span = angle_span_top;
    radius = radius_top;
    circle_center = circle_center_top;
    axis_length = se_a_top;
  } else {
    p_oct = p_norm.yx - vec2(0.0, c);
    se_degree = se_degree_right;
    span = angle_span_right;
    radius = radius_right;
    circle_center = circle_center_right;
    axis_length = se_a_right;
  }

  vec2 p_rel = p_oct - circle_center;
  float theta = atan(p_rel.y, p_rel.x);

  float d_theta = theta - PI_OVER_FOUR;
  d_theta = mod(d_theta + PI, TWO_PI) - PI;

  float d_scaled;
  vec2 grad_oct;
  if (abs(d_theta) < abs(span)) {
    d_scaled = distanceFromCircle(p_rel, radius);
    grad_oct = normalize(p_rel);
  } else {
    d_scaled = sdSuperellipse(p_oct / axis_length, se_degree) * axis_length;
    vec2 p_oct_clamped = max(p_oct, vec2(0.001));
    float max_p = max(p_oct_clamped.x, p_oct_clamped.y);
    vec2 p_safe = p_oct_clamped / max_p;
    grad_oct = normalize(pow(p_safe, vec2(se_degree - 1.0)));
  }

  vec2 grad_norm;
  if (p_norm.y + c > p_norm.x) {
    grad_norm = grad_oct;
  } else {
    grad_norm = grad_oct.yx;
  }

  float corner_dist = d_scaled / length(grad_norm / scale);

  return corner_dist;
}

float distanceFromRoundedSuperellipse(vec2 p) {
  float d0 = getQuadrantDistance(p, 0);
  float d1 = getQuadrantDistance(p, 1);
  float d2 = getQuadrantDistance(p, 2);
  float d3 = getQuadrantDistance(p, 3);
  return max(max(d0, d1), max(d2, d3));
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

// Exact math for rounded rect.
//
// `p` is position relative to the center of the shape.
// `b` is the size of box, .x is the distance between center and left/right, .y
// is the distance between center and top/bottom. `r` is radii for each corner
// in order [bottom_right, top_right, bottom_left, top_left].
//
// See https://iquilezles.org/articles/distfunctions2d/
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

float distanceFromRoundedRect(in vec2 p, in vec2 b, in vec4 r) {
  r.xy = (p.x > 0.0) ? r.xy : r.zw;
  r.x = (p.y > 0.0) ? r.x : r.y;
  vec2 q = abs(p) - b + r.x;
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
}

// Returns the pixel size for the given SDF value.
//
// This is the size of a pixel at the current fragment, measured in the
// direction perpendicular to the SDF's shape.
float pixelSize(float sdf) {
  // Gradient vector of the SDF at point p. Points in the direction of steepest
  // increase away from SDF's shape. At the edges of the shape, this is
  // perpendicular to the edge.
  //
  // The x and y magnitudes of the gradient are determined by the dFdx and dFdy
  // of the SDF value. dFdx and dFdy return the change of a value in the x and y
  // direction per screen-space unit (physical pixel). So this gradient
  // is the change in the SDF, at point p, in local space units per pixel.
  vec2 gradient = vec2(dFdx(sdf), dFdy(sdf));

  // The length of the gradient vector is how fast the SDF changes per
  // screen-space pixel distance. In other words, it is the size of a pixel
  // measured in the units of the SDF calculation.
  //
  // In local space, the SDF always increases by 1 in the gradient's direction
  // per unit distance. That's the definition of an SDF: it is the distance to
  // the closest point of the shape. But in terms of screen-space, the SDF may
  // increase by a different amount than 1 per unit distance (in screen-space
  // units, i.e. physical pixels), due to scales/skews/rotations.
  //
  // As an example, consider the SDF of an unscaled/unskewed circle centered at
  // the origin. The gradient is vec2(1.0, 0.0) for points along the positive x
  // axis[^1]: for every one pixel we move along the positive x axis,
  // the SDF value increases by 1.0. Now consider the same circle with a
  // transformation that scales it by 2 along the x axis. With a transformation,
  // the local space size of the circle remains the same, but the way it maps
  // onto screen-space pixels is changed. In screen-space the circle is
  // stretched to be twice as wide as the original circle in the postive and
  // negative x directions. The gradient for this will be vec2(0.5, 0.0) along
  // the positive x axis: for every physical pixel we move along the positive x
  // axis, we move only 0.5 units in the SDF's local space.
  //
  // [^1]: In the real world, there would not be a pixel where the gradient
  // vector for a circle is exactly (1.0, 0.0) due to the way dFdx and dFdy are
  // approximated from pixel samples. This does not affect the applicability
  // of this example.
  return length(gradient);
}

// Computes the SDF value and pixel size for a filled shape.
//
// `p` is position relative to the center of the shape.
//
// Returns a vec2 with:
//   x: The SDF value at `p`.
//   y: The pixel size at `p`.
vec2 filledSDF(vec2 p) {
  float sdf;
  if (frag_info.type < 0.5) {  // Circle
    sdf = distanceFromCircle(p, frag_info.size.x);
  } else if (frag_info.type < 1.5) {  // Rect
    sdf = distanceFromRect(p, frag_info.size);
  } else if (frag_info.type < 2.5) {  // Oval
    sdf = distanceFromOval(p, frag_info.size);
  } else if (frag_info.type < 3.5) {  // Rounded Rect
    sdf = distanceFromRoundedRect(p, frag_info.size, frag_info.radii_width);
  } else {
    sdf = distanceFromRoundedSuperellipse(p);
  }
  return vec2(sdf, pixelSize(sdf));
}

// Computes the SDF value and pixel size for a stroked shape.
//
// `p` is position relative to the center of the shape.
//
// Returns a vec2 with:
//   x: The SDF value at `p`.
//   y: The pixel size at `p`.
vec2 strokedSDF(vec2 p) {
  // Get the base (filled) SDF for this shape. The filled SDF pixel size is used
  // to calculate a minimum stroke width, and the filled SDF value is used to
  // calculate the stroked SDF value for many shapes.
  vec2 base_sdf_and_pixel_size = filledSDF(p);
  float base_sdf = base_sdf_and_pixel_size.x;
  float base_pixel_size = base_sdf_and_pixel_size.y;

  // Stroke width is clamped to be at least the base sdf's pixel size.
  float half_stroke = max(frag_info.stroke_width, base_pixel_size) * 0.5;

  // Some cases need special handling because their stroked SDFs have a
  // different shape from their base SDFs.
  if (frag_info.type >= 0.5 && frag_info.type < 1.5) {  // Rect

    if (frag_info.stroke_join < 0.5) {  // Miter
      // Outer edge is the SDF for a rect with size expanded by half_stroke.
      float outer = distanceFromRect(p, frag_info.size + half_stroke);
      // Inner edge is base_sdf's -half_stroke isoline.
      float inner = base_sdf + half_stroke;
      float sdf = max(outer, -inner);
      return vec2(sdf, pixelSize(sdf));
    } else if (frag_info.stroke_join < 1.5) {  // Bevel
      // Outer edge is the SDF for a rect with size expanded by half_stroke,
      // with a half_stroke chamfer.
      float outer =
          distanceFromChamferRect(p, frag_info.size + half_stroke, half_stroke);
      // Inner edge is base_sdf's -half_stroke isoline.
      float inner = base_sdf + half_stroke;
      float sdf = max(outer, -inner);
      return vec2(sdf, pixelSize(sdf));
    }  // else stroke_join is Round. Fall through to the common case.
  }

  // For most shapes, the stroked SDF is defined by the +/- half_stroke
  // isolines of the base SDF. See the "Making shapes annular" section in
  // https://iquilezles.org/articles/distfunctions2d/.
  float sdf = abs(base_sdf) - half_stroke;
  // For these shapes, the stroked pixel size is the same as the base pixel
  // size. This is because the stroked SDF's gradient has the same magnitudes as
  // the base SDF's gradient (except for a discontinuity at the center of the
  // stroke, which does not affect the final render).
  return vec2(sdf, base_pixel_size);
}

float distanceToSegment(vec2 p, vec2 a, vec2 b) {
  vec2 pa = p - a, ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - ba * h);
}

void main() {
  vec2 p = v_position - frag_info.center;

  vec2 sdf_and_pixel_size =
      (frag_info.stroked < 0.5) ? filledSDF(p) : strokedSDF(p);
  float sdf = sdf_and_pixel_size.x;
  float pixel_size = sdf_and_pixel_size.y;

  // Anti-aliasing. Fade from alpha 1 to 0 across the edge of the SDF (where it
  // goes from negative to positive). Fade through distance of half
  // (pixel_size * aa_pixels) in each direction.
  float fade_size = pixel_size * frag_info.aa_pixels * 0.5;
  float alpha = 1.0 - smoothstep(-fade_size, fade_size, sdf);

  if (frag_info.type > 3.5) {  // Rounded Superellipse
    // Base visualizer
    vec3 col = (sdf < 0.0) ? vec3(0.9, 0.6, 0.3) : vec3(0.4, 0.7, 0.85);
    col *= 1.0 - exp(-3.0 * abs(sdf / 100.0));
    col *= 0.8 + 0.2 * cos(1.2 * sdf);
    col = mix(col, vec3(1.0), 1.0 - smoothstep(0.0, 1.5, abs(sdf)));

    // 1. Quadrant centers TR (Red), BR (Green), BL (Blue), TL (Yellow)
    float dot_radius = 3.5;
    vec2 C_TR =
        vec2(frag_info.quadrant_centers_x[0], frag_info.quadrant_centers_y[0]);
    vec2 C_BR =
        vec2(frag_info.quadrant_centers_x[1], frag_info.quadrant_centers_y[1]);
    vec2 C_BL =
        vec2(frag_info.quadrant_centers_x[2], frag_info.quadrant_centers_y[2]);
    vec2 C_TL =
        vec2(frag_info.quadrant_centers_x[3], frag_info.quadrant_centers_y[3]);

    float dt_ctr_TR = length(p - C_TR) - dot_radius;
    float dt_ctr_BR = length(p - C_BR) - dot_radius;
    float dt_ctr_BL = length(p - C_BL) - dot_radius;
    float dt_ctr_TL = length(p - C_TL) - dot_radius;

    float alpha_ctr_TR = max(0.0, 1.0 - smoothstep(-1.0, 1.0, dt_ctr_TR));
    float alpha_ctr_BR = max(0.0, 1.0 - smoothstep(-1.0, 1.0, dt_ctr_BR));
    float alpha_ctr_BL = max(0.0, 1.0 - smoothstep(-1.0, 1.0, dt_ctr_BL));
    float alpha_ctr_TL = max(0.0, 1.0 - smoothstep(-1.0, 1.0, dt_ctr_TL));

    col = mix(col, vec3(1.0, 0.0, 0.0), alpha_ctr_TR);  // Red
    col = mix(col, vec3(0.0, 1.0, 0.0), alpha_ctr_BR);  // Green
    col = mix(col, vec3(0.0, 0.0, 1.0), alpha_ctr_BL);  // Blue
    col = mix(col, vec3(1.0, 1.0, 0.0), alpha_ctr_TL);  // Yellow

    frag_color = vec4(col, frag_info.color.a);
    frag_color = IPPremultiply(frag_color);
  }
  {
    frag_color = vec4(frag_info.color.rgb, frag_info.color.a * alpha);
    frag_color = IPPremultiply(frag_color);
  }
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision mediump float;

#include <impeller/color.glsl>
#include <impeller/types.glsl>

#include "sdf_functions.glsl"
#include "sdf_utils.glsl"

uniform FragInfo {
  vec4 color;
  vec2 center;
  vec2 size;
  float stroke_width;
  float stroke_join;
  float aa_pixels;
  float stroked;
  float type;
  vec2 superellipse_degree;
  vec2 superellipse_semi_axis;
  vec2 angle_span;
  float octant_offset_c;
  vec2 radius;
  vec2 circle_center_top;
  vec2 circle_center_right;
  vec2 superellipse_scale;
  vec2 quadrant_center;
  vec4 radii;
}
frag_info;

out vec4 frag_color;

highp in vec2 v_position;

float distanceFromCircle(vec2 p, float radius) {
  return length(p) - radius;
}

float distanceFromRect(vec2 p, vec2 b) {
  vec2 d = abs(p) - b;
  return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float distanceFromOval(vec2 p, vec2 ab) {
  p = abs(p);
  vec2 q = ab * (p - ab);
  float w = (q.x < q.y) ? 1.570796327 : 0.0;
  for (int i = 0; i < 5; i++) {
    vec2 cs = vec2(cos(w), sin(w));
    vec2 u = ab * vec2(cs.x, cs.y);
    vec2 v = ab * vec2(-cs.y, cs.x);
    w = w + dot(p - u, v) / (dot(p - u, u) + dot(v, v));
  }
  float d = length(p - ab * vec2(cos(w), sin(w)));
  return (dot(p / ab, p / ab) > 1.0) ? d : -d;
}

float distanceFromRoundedRect(in vec2 p, in vec2 b, in vec4 r) {
  r.xy = (p.x > 0.0) ? r.xy : r.zw;
  r.x = (p.y > 0.0) ? r.x : r.y;
  vec2 q = abs(p) - b + r.x;
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
}

float distanceFromChamferRect(vec2 p, vec2 half_size, float chamfer_size) {
  p = abs(p);
  float d1 = max(p.x - half_size.x, p.y - half_size.y);
  float d2 =
      (p.x + p.y - half_size.x - half_size.y + chamfer_size) * 0.70710678;
  return max(d1, d2);
}

float getQuadrantDistanceSymmetric(vec2 p,
                                   vec2 se_degree,
                                   vec2 se_a,
                                   vec2 angle_span,
                                   float c,
                                   vec2 radius,
                                   vec2 circle_center_top,
                                   vec2 circle_center_right,
                                   vec2 scale,
                                   vec2 q_center) {
  vec2 p_local = p - q_center;
  vec2 p_clamped = max(p_local, 0.0);

  vec2 extents = vec2(scale.x * se_a.x, scale.y * se_a.y);
  vec2 d_rect = p_local - extents;
  float dist_rect_local =
      length(max(d_rect, 0.0)) + min(max(d_rect.x, d_rect.y), 0.0);

  if (p_local.x <= 0.0 || p_local.y <= 0.0) {
    return dist_rect_local;
  }

  vec2 p_norm = p_clamped / scale;

  float se_d;
  float span;
  float r;
  vec2 circle_center;
  float axis_length;

  vec2 p_oct;

  if (p_norm.y + c > p_norm.x) {
    p_oct = p_norm + vec2(0.0, c);
    se_d = se_degree.x;
    span = angle_span.x;
    r = radius.x;
    circle_center = circle_center_top;
    axis_length = se_a.x;
  } else {
    p_oct = p_norm.yx - vec2(0.0, c);
    se_d = se_degree.y;
    span = angle_span.y;
    r = radius.y;
    circle_center = circle_center_right;
    axis_length = se_a.y;
  }

  vec2 p_rel = p_oct - circle_center;
  float theta = atan(p_rel.y, p_rel.x);

  float d_theta = theta - PI_OVER_FOUR;
  d_theta = mod(d_theta + PI, TWO_PI) - PI;

  float dist_raw;
  vec2 grad_oct;

  if (abs(d_theta) < abs(span)) {
    dist_raw = distanceFromCircle(p_rel, r);
    grad_oct = normalize(p_rel);
  } else {
    dist_raw = sdSuperellipse(p_oct / axis_length, se_d) * axis_length;
    vec2 p_oct_clamped = max(p_oct, vec2(0.001));
    float max_p = max(p_oct_clamped.x, p_oct_clamped.y);
    vec2 p_safe = p_oct_clamped / max_p;
    grad_oct = normalize(pow(p_safe, vec2(se_d - 1.0)));
  }

  if (p_norm.y + c <= p_norm.x) {
    grad_oct = grad_oct.yx;
  }

  float corner_dist = dist_raw / length(grad_oct / scale);

  return max(dist_rect_local, corner_dist);
}

float distanceFromSymmetricRoundedSuperellipse(vec2 p,
                                               vec2 superellipse_degree,
                                               vec2 superellipse_semi_axis,
                                               vec2 angle_span,
                                               float octant_offset_c,
                                               vec2 radius,
                                               vec2 circle_center_top,
                                               vec2 circle_center_right,
                                               vec2 superellipse_scale,
                                               vec2 quadrant_center) {
  // Fold the pixel into the Top-Right quadrant (x > 0, y < 0)
  vec2 p_folded = vec2(abs(p.x), -abs(p.y));

  return getQuadrantDistanceSymmetric(
      p_folded, superellipse_degree, superellipse_semi_axis, angle_span,
      octant_offset_c, radius, circle_center_top, circle_center_right,
      superellipse_scale, quadrant_center);
}

float pixelSize(float sdf) {
  vec2 gradient = vec2(dFdx(sdf), dFdy(sdf));
  return length(gradient);
}

vec2 filledSDF(vec2 p) {
  float sdf;
  if (frag_info.type < 0.5) {  // Circle
    sdf = distanceFromCircle(p, frag_info.size.x);
  } else if (frag_info.type < 1.5) {  // Rect
    sdf = distanceFromRect(p, frag_info.size);
  } else if (frag_info.type < 2.5) {  // Oval
    sdf = distanceFromOval(p, frag_info.size);
  } else if (frag_info.type < 3.5) {  // Rounded Rect
    sdf = distanceFromRoundedRect(p, frag_info.size, frag_info.radii);
  } else {  // Symmetric Rounded Superellipse
    sdf = distanceFromSymmetricRoundedSuperellipse(
        p, frag_info.superellipse_degree, frag_info.superellipse_semi_axis,
        frag_info.angle_span, frag_info.octant_offset_c, frag_info.radius,
        frag_info.circle_center_top, frag_info.circle_center_right,
        frag_info.superellipse_scale, frag_info.quadrant_center);
  }
  return vec2(sdf, pixelSize(sdf));
}

vec2 strokedSDF(vec2 p) {
  vec2 base_sdf_and_pixel_size = filledSDF(p);
  float base_sdf = base_sdf_and_pixel_size.x;
  float base_pixel_size = base_sdf_and_pixel_size.y;

  float half_stroke = max(frag_info.stroke_width, base_pixel_size) * 0.5;

  if (frag_info.type >= 0.5 && frag_info.type < 1.5) {  // Rect

    if (frag_info.stroke_join < 0.5) {  // Miter
      float outer = distanceFromRect(p, frag_info.size + half_stroke);
      float inner = base_sdf + half_stroke;
      float sdf = max(outer, -inner);
      return vec2(sdf, pixelSize(sdf));
    } else if (frag_info.stroke_join < 1.5) {  // Bevel
      float outer =
          distanceFromChamferRect(p, frag_info.size + half_stroke, half_stroke);
      float inner = base_sdf + half_stroke;
      float sdf = max(outer, -inner);
      return vec2(sdf, pixelSize(sdf));
    }
  }

  return SDFStroke(base_sdf, base_pixel_size, frag_info.stroke_width);
}

void main() {
  vec2 p = v_position - frag_info.center;

  vec2 sdf_and_pixel_size =
      (frag_info.stroked < 0.5) ? filledSDF(p) : strokedSDF(p);
  float sdf = sdf_and_pixel_size.x;
  float pixel_size = sdf_and_pixel_size.y;

  float alpha = SDFAlpha(sdf, pixel_size, frag_info.aa_pixels);

  frag_color = vec4(frag_info.color.rgb, frag_info.color.a * alpha);
  frag_color = IPPremultiply(frag_color);
}

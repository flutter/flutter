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

bool joinIsMiter() {
  return abs(frag_info.stroke_join - 0.0) < 0.01;
}

bool joinIsBevel() {
  return abs(frag_info.stroke_join - 1.0) < 0.01;
}

bool joinIsRound() {
  return abs(frag_info.stroke_join - 2.0) < 0.01;
}

float distanceFromCircle(vec2 p, float radius) {
  return length(p) - radius;
}

float distanceFromRect(vec2 p, vec2 b) {
  vec2 d = abs(p) - b;
  return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
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
  if (frag_info.type < 0.5) {  // Circle
    return distanceFromCircle(p, frag_info.size.x);
  } else {  // Rect
    return distanceFromRect(p, frag_info.size);
  }
}

float strokedSDF(vec2 p, float base_sdf, float pixel_size) {
  float half_stroke = max(frag_info.stroke_width, pixel_size) * 0.5;

  // Special case handling for certain shapes.
  if (typeIsRect()) {
    if (joinIsMiter()) {
      // Outer edge is the SDF for a rect with size expanded by half_stroke.
      float outer = distanceFromRect(p, frag_info.size + half_stroke);
      // Inner edge is base_sdf's -half_stroke isoline.
      float inner = base_sdf + half_stroke;
      return max(outer, -inner);
    } else if (joinIsBevel()) {
      // Outer edge is the SDF for a rect with size expanded by half_stroke,
      // with a half_stroke chamfer.
      float outer =
          distanceFromChamferRect(p, frag_info.size + half_stroke, half_stroke);
      // Inner edge is base_sdf's -half_stroke isoline.
      float inner = base_sdf + half_stroke;
      return max(outer, -inner);
    }
  }

  // Most stroked SDFs are the shape within the half-stroke offset isolines of
  // the filled SDF.
  return abs(base_sdf) - half_stroke;
}

void main() {
  vec2 p = v_position - frag_info.center;

  float base_sdf = filledSDF(p);

  // Gradient vector of the SDF. Points in the direction of steepest increase
  // away from shape. At the edges of the shape, this is perpendicular to the
  // edge.
  vec2 gradient = vec2(dFdx(base_sdf), dFdy(base_sdf));

  // The length of the gradient vector is how fast the SDF changes per unit
  // distance. This is equal to the width of a pixel in the direction of the
  // gradient.
  float pixel_size = length(gradient);

  float sdf = (frag_info.stroked < 0.5) ? base_sdf
                                        : strokedSDF(p, base_sdf, pixel_size);

  // Anti-aliasing
  float fade_size = pixel_size * frag_info.aa_pixels * 0.5;

  float alpha = 1.0 - smoothstep(-fade_size, fade_size, sdf);

  frag_color = vec4(frag_info.color.rgb, frag_info.color.a * alpha);
  frag_color = IPPremultiply(frag_color);
}

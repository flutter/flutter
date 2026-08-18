// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision mediump float;

#include <impeller/color.glsl>
#include <impeller/types.glsl>

#include "rse_sdf.glsl"
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
  float superellipse_degree;
  float superellipse_angle_span;
  vec2 circle_center;
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

float distanceFromRoundedSuperellipse(vec2 p,
                                      float se_degree,
                                      float se_a,
                                      float radius,
                                      float angle_span,
                                      vec2 circle_center) {
  p = abs(p);
  return distanceFromRSEOctant(p, circle_center, radius, angle_span, se_a,
                               se_degree);
}

// Special case pixel size calculation for rectangles. The standard `pixelSize`
// function uses SDF derivatives, which gives invalid results for very small
// shapes, where adjacent device pixels span across opposing edges of the shape.
// This function calculates pixel size for rectangles without using SDF
// derivatives.
float rectPixelSize(vec2 p) {
  // The change in local coordinates per horizontal device pixel (device_dx)
  // and vertical device pixel (device_dy).
  vec2 device_dx = dFdx(v_position);
  vec2 device_dy = dFdy(v_position);
  // The size of a device pixel in terms of local coordinates.
  vec2 device_pixel_size = vec2(length(vec2(device_dx.x, device_dy.x)),
                                length(vec2(device_dx.y, device_dy.y)));

  // Get pixel size in the direction perpendicular to the closest edge of the
  // rectangle: device_pixel_size.x when closer to a vertical edge, and
  // pixel_size.y when closer to a horizontal edge.
  vec2 distance = abs(abs(p) - frag_info.size);
  return (distance.x < distance.y) ? device_pixel_size.x : device_pixel_size.y;
}

// Special case pixel size calculation for rounded rectangles, similar to
// `rectPixelSize` for regular rectangles.
float roundRectPixelSize(vec2 p) {
  // The change in local coordinates per horizontal device pixel (device_dx)
  // and vertical device pixel (device_dy).
  vec2 device_dx = dFdx(v_position);
  vec2 device_dy = dFdy(v_position);
  // The size of a device pixel in terms of local coordinates.
  vec2 device_pixel_size = vec2(length(vec2(device_dx.x, device_dy.x)),
                                length(vec2(device_dx.y, device_dy.y)));

  // Select the corner radius for the quadrant of p.
  vec4 r = frag_info.radii;
  r.xy = (p.x > 0.0) ? r.xy : r.zw;
  float radius = (p.y > 0.0) ? r.x : r.y;

  // Vector from corner circle center to abs(p).
  vec2 corner_center = frag_info.size - radius;
  vec2 q = abs(p) - corner_center;

  float pixel_size;
  // If in the rounded corner arc, blend X and Y pixel sizes along the normal.
  if (q.x > 0.0 && q.y > 0.0) {
    pixel_size = length(normalize(q) * device_pixel_size);
  } else {
    // Otherwise, we are closer to a straight edge. Get pixel size in the
    // direction perpendicular to the closer edge.
    pixel_size = (q.x > q.y) ? device_pixel_size.x : device_pixel_size.y;
  }
  return pixel_size;
}

float pixelSize(float sdf) {
  vec2 gradient = vec2(dFdx(sdf), dFdy(sdf));
  return length(gradient);
}

// Evaluates the SDF for the shape selected by frag_info.type.
// Returns vec2(sdf, pixel_size).
vec2 filledSDF(vec2 p) {
  float sdf;
  float pixel_size;
  if (frag_info.type < 0.5) {  // Circle
    sdf = distanceFromCircle(p, frag_info.size.x);
    pixel_size = pixelSize(sdf);
  } else if (frag_info.type < 1.5) {  // Rect
    sdf = distanceFromRect(p, frag_info.size);
    // Rect has its own separate logic for calculating pixel size.
    pixel_size = rectPixelSize(p);
  } else if (frag_info.type < 2.5) {  // Oval
    sdf = distanceFromOval(p, frag_info.size);
    pixel_size = pixelSize(sdf);
  } else if (frag_info.type < 3.5) {  // Rounded Rect
    sdf = distanceFromRoundedRect(p, frag_info.size, frag_info.radii);
    // RoundRect has its own separate logic for calculating pixel size.
    pixel_size = roundRectPixelSize(p);
  } else {  // Symmetric Rounded Superellipse
    sdf = distanceFromRoundedSuperellipse(
        p, frag_info.superellipse_degree, frag_info.size.x, frag_info.radii.x,
        frag_info.superellipse_angle_span, frag_info.circle_center);
    pixel_size = pixelSize(sdf);
  }
  return vec2(sdf, pixel_size);
}

// Evaluates the stroked SDF for the shape selected by frag_info.type.
// Returns vec2(sdf, pixel_size).
vec2 strokedSDF(vec2 p) {
  vec2 base_sdf_and_pixel_size = filledSDF(p);
  float base_sdf = base_sdf_and_pixel_size.x;
  float base_pixel_size = base_sdf_and_pixel_size.y;

  float half_stroke = max(frag_info.stroke_width, base_pixel_size) * 0.5;

  float sdf;
  float pixel_size;
  if (frag_info.type >= 0.5 && frag_info.type < 1.5 &&
      frag_info.stroke_join < 0.5) {
    // Rect with Miter join
    float outer = distanceFromRect(p, frag_info.size + half_stroke);
    float inner = base_sdf + half_stroke;
    sdf = max(outer, -inner);
    pixel_size = pixelSize(sdf);
  } else if (frag_info.type >= 0.5 && frag_info.type < 1.5 &&
             frag_info.stroke_join >= 0.5 && frag_info.stroke_join < 1.5) {
    // Rect with Bevel join
    float outer =
        distanceFromChamferRect(p, frag_info.size + half_stroke, half_stroke);
    float inner = base_sdf + half_stroke;
    sdf = max(outer, -inner);
    pixel_size = pixelSize(sdf);
  } else {
    // All other shapes
    vec2 sdf_and_pixel_size =
        SDFStroke(base_sdf, base_pixel_size, frag_info.stroke_width);
    sdf = sdf_and_pixel_size.x;
    pixel_size = sdf_and_pixel_size.y;
  }
  return vec2(sdf, pixel_size);
}

// Converts linear coverage alpha to perceptual alpha.
float gammaCorrectedAlpha(float alpha, vec3 foreground_rgb) {
  // Gamma corrected alpha used for dark colors.
  // Fast approximation for `1.0 - pow(1.0 - alpha, 1.0 / 2.2)`.
  float alpha_dark = 1.0 - sqrt(1.0 - alpha);

  // Gamma corrected alpha used for light colors.
  // Fast approximation for `pow(alpha, 1.0 / 2.2)`.
  float alpha_light = sqrt(alpha);

  // Interpolate between the dark and light gamma corrected alphas based on the
  // foreground luma.
  float luma = dot(foreground_rgb, vec3(0.2126, 0.7152, 0.0722));
  return mix(alpha_dark, alpha_light, luma);
}

void main() {
  vec2 p = v_position - frag_info.center;

  vec2 sdf_and_pixel_size =
      (frag_info.stroked < 0.5) ? filledSDF(p) : strokedSDF(p);
  float sdf = sdf_and_pixel_size.x;
  float pixel_size = sdf_and_pixel_size.y;

  float alpha = SDFAlpha(sdf, pixel_size, frag_info.aa_pixels);
  // Clamp alpha in case floating point precision errors cause it to be outside
  // [0.0, 1.0].
  alpha = clamp(alpha, 0.0, 1.0);
  alpha = gammaCorrectedAlpha(alpha, frag_info.color.rgb);

  frag_color = vec4(frag_info.color.rgb, frag_info.color.a * alpha);
  frag_color = IPPremultiply(frag_color);
}

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
  vec2 circle_center_top;
  vec2 circle_center_right;
  vec2 superellipse_scale;
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
                                      vec2 degree,
                                      vec2 se_a,
                                      vec2 radii,
                                      vec2 angle_span,
                                      vec2 circle_center_top,
                                      vec2 circle_center_right,
                                      float c,
                                      vec2 scale) {
  // Do work in the first quadrant to simply things.
  p = abs(p);
  // Map p in to a square.
  vec2 p_norm = p / scale;

  // Declare all RSE params for a single octant.
  float se_degree, span, radius, axis_length;
  vec2 circle_center;

  // 'p' in the coordinate system of the octant.
  vec2 p_oct;

  // We split the quadrant along the diagonal of the transition (p_norm.y + c ==
  // p_norm.x). This allows us to grab the correct set of parameters for the
  // "top" and "right" halves of the corner.
  if (p_norm.y + c > p_norm.x) {
    p_oct = p_norm + vec2(0.0, c);
    se_degree = degree.x;
    span = angle_span.x;
    radius = radii.x;
    circle_center = circle_center_top;
    axis_length = se_a.x;
  } else {
    // For the 'right' octant, we flip the point and shift it according to
    // the CPU's OctantContains/Flip logic.
    p_oct = p_norm.yx - vec2(0.0, c);
    se_degree = degree.y;
    span = angle_span.y;
    radius = radii.y;
    circle_center = circle_center_right;
    axis_length = se_a.y;
  }

  // Move the point to the corner circle's coordinate system.
  vec2 p_rel = p_oct - circle_center;

  // Grab the angle offset of the point.
  float theta = atan(p_rel.y, p_rel.x);

  // The angular distance between the point and the 45 degree midline.
  float d_theta = theta - PI_OVER_FOUR;
  d_theta = mod(d_theta + PI, TWO_PI) - PI;

  // If the point is within the span of the corner circle's arc,
  // use a circle SDF.
  // This works because the normals of the circular and superelliptical sections
  // agree at the transition angle, the total RSE curve is continuous and
  // the closest point on a continuous curve to a point lies along the normal.
  if (abs(d_theta) < abs(span)) {
    return distanceFromCircle(p_rel, radius);
  }
  return sdSuperellipse(p_oct / axis_length, se_degree) * axis_length;
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

float pixelSize(float sdf) {
  vec2 gradient = vec2(dFdx(sdf), dFdy(sdf));
  return length(gradient);
}

// Evaluates the SDF for the shape selected by frag_info.type.
// Returns vec2(sdf, pixel_size).
vec2 filledSDF(vec2 p) {
  float sdf;
  if (frag_info.type < 0.5) {  // Circle
    sdf = distanceFromCircle(p, frag_info.size.x);
  } else if (frag_info.type < 1.5) {  // Rect
    sdf = distanceFromRect(p, frag_info.size);
    // Rect has its own separate logic for calculating pixel size.
    return vec2(sdf, rectPixelSize(p));
  } else if (frag_info.type < 2.5) {  // Oval
    sdf = distanceFromOval(p, frag_info.size);
  } else if (frag_info.type < 3.5) {  // Rounded Rect
    sdf = distanceFromRoundedRect(p, frag_info.size, frag_info.radii);
  } else {  // Symmetric Rounded Superellipse
    sdf = distanceFromRoundedSuperellipse(
        p, frag_info.superellipse_degree, frag_info.superellipse_semi_axis,
        frag_info.radii.xy, frag_info.angle_span, frag_info.circle_center_top,
        frag_info.circle_center_right, frag_info.octant_offset_c,
        frag_info.superellipse_scale);
  }
  return vec2(sdf, pixelSize(sdf));
}

// Evaluates the stroked SDF for the shape selected by frag_info.type.
// Returns vec2(sdf, pixel_size).
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
      return vec2(sdf, base_pixel_size);
    } else if (frag_info.stroke_join < 1.5) {  // Bevel
      float outer =
          distanceFromChamferRect(p, frag_info.size + half_stroke, half_stroke);
      float inner = base_sdf + half_stroke;
      float sdf = max(outer, -inner);
      return vec2(sdf, base_pixel_size);
    }
  }

  return SDFStroke(base_sdf, base_pixel_size, frag_info.stroke_width);
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

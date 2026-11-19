// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef RSE_SDF_GLSL_
#define RSE_SDF_GLSL_

#include <impeller/constants.glsl>

#include "sdf_functions.glsl"
#include "sdf_utils.glsl"

bool useCircularDistance(vec2 p, float radius, float span) {
  // Grab the angle offset of the point.
  float theta = atan(p.y, p.x);

  // The angular distance between the point and the 45 degree midline.
  float d_theta = theta - PI_OVER_FOUR;
  d_theta = mod(d_theta + PI, TWO_PI) - PI;

  // If the point is within the span of the corner circle's arc,
  // use a circle SDF.
  // This works because the normals of the circular and superelliptical sections
  // agree at the transition angle, the total RSE curve is continuous and
  // the closest point on a continuous curve to a point lies along the normal.
  if (abs(d_theta) < abs(span)) {
    return true;
  }

  return false;
}

/// Returns whether the closest point on a rounded superellipse octant to `p`
/// is on the octant's corner circle, in which case the distance to the
/// superellipse is the distance to that circle.
///
/// `p` is relative to the corner circle's center. The closest point is on the
/// circle when `p` is within the circle's arc, i.e. when the angle between `p`
/// and the 45 degree midline is less than the arc's angular span. This is
/// tested as cos(angle) > `cos_span`, where `cos_span` is the cosine of the
/// angular span.
///
/// This gives the same result as `useCircularDistance`, which takes the span
/// itself, but avoids atan() and mod(), which need more constants and uniform
/// registers.
///
/// @see useCircularDistance
bool useCircularDistanceCos(vec2 p, float cos_span) {
  return dot(p, vec2(kHalfSqrtTwo)) > cos_span * length(p);
}

/// Returns the signed distance from `p_oct` to one octant of a rounded
/// superellipse, in the octant's coordinate system.
///
/// The octant is a superellipse with exponent `se_degree` and axis length
/// `axis_length`, joined to a corner circle with center `circle_center` and
/// radius `radius`. `cos_span` is the cosine of the angular span of the
/// circle's arc.
///
/// @see useCircularDistanceCos
float distanceFromRSEOctantCos(vec2 p_oct,
                               vec2 circle_center,
                               float radius,
                               float cos_span,
                               float axis_length,
                               float se_degree) {
  // Move the point to the corner circle's coordinate system.
  vec2 p_rel = p_oct - circle_center;

  if (useCircularDistanceCos(p_rel, cos_span)) {
    return length(p_rel) - radius;
  }
  return sdSuperellipse(p_oct / axis_length, se_degree) * axis_length;
}

vec3 distanceFromRSEOctantWithGrad(vec2 p_oct,
                                   vec2 circle_center,
                                   float radius,
                                   float span,
                                   float axis_length,
                                   float se_degree) {
  // Move the point to the corner circle's coordinate system.
  vec2 p_rel = p_oct - circle_center;
  // Gradient of the sdf.
  vec2 grad_oct;

  if (useCircularDistance(p_rel, radius, span)) {
    grad_oct = normalize(p_rel);
    float dist = length(p_rel) - radius;
    return vec3(dist, grad_oct);
  }

  // Clamp the coordinate to avoid division by zero
  vec2 p_oct_clamped = max(p_oct, vec2(0.001));
  float max_p = max(p_oct_clamped.x, p_oct_clamped.y);
  vec2 p_safe = p_oct_clamped / max_p;
  // Approximation of the gradient
  grad_oct = normalize(pow(p_safe, vec2(se_degree - 1.0)));

  float dist = sdSuperellipse(p_oct / axis_length, se_degree) * axis_length;
  return vec3(dist, grad_oct);
}

#endif  // RSE_SDF_GLSL_

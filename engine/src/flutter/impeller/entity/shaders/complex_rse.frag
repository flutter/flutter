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
  float stroked;
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

float distanceFromCircle(vec2 p, float radius) {
  return length(p) - radius;
}

float getQuadrantDistance(vec2 p,
                          float se_degree_top,
                          float se_degree_right,
                          float se_a_top,
                          float se_a_right,
                          float angle_span_top,
                          float angle_span_right,
                          float c,
                          float radius_top,
                          float radius_right,
                          vec2 circle_center_top,
                          vec2 circle_center_right,
                          vec2 scale,
                          vec2 q_center,
                          int quadrant_index) {
  vec2 q_sign = vec2(1.0);
  if (quadrant_index == 0)
    q_sign = vec2(1.0, 1.0);
  else if (quadrant_index == 1)
    q_sign = vec2(1.0, -1.0);
  else if (quadrant_index == 2)
    q_sign = vec2(-1.0, 1.0);
  else
    q_sign = vec2(-1.0, -1.0);

  // Transform the point into the quadrant's local space
  vec2 p_local = (p - q_center) * q_sign;

  // Clamp the point to positive values - this avoids issues with the sdf
  // calculations below. This also means that interior distances for this
  // function are not totally accurate.
  vec2 p_clamped = max(p_local, 0.0);

  // For points that we clamped, return an approximate interior distance
  vec2 extents = vec2(scale.x * se_a_top, scale.y * se_a_right);
  vec2 d_rect = p_local - extents;
  float dist_rect_local =
      length(max(d_rect, 0.0)) + min(max(d_rect.x, d_rect.y), 0.0);

  if (p_local.x <= 0.0 || p_local.y <= 0.0) {
    return dist_rect_local;
  }

  // Map p in to a square.
  vec2 p_norm = p_clamped / scale;

  // Declare all RSE params for a single octant.
  float se_degree;
  float span;
  float radius;
  vec2 circle_center;
  float axis_length;

  // 'p_norm' in the coordinate system of the octant.
  vec2 p_oct;

  // We split the quadrant along the diagonal of the transition (p_norm.y + c ==
  // p_norm.x). This allows us to grab the correct set of parameters for the
  // "top" and "right" halves of the corner.
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

  // Move the point to the corner circle's coordinate system.
  vec2 p_rel = p_oct - circle_center;
  // Grab the angle offset of the point.
  float theta = atan(p_rel.y, p_rel.x);

  // The angular distance between the point and the 45 degree midline.
  float d_theta = theta - PI_OVER_FOUR;
  d_theta = mod(d_theta + PI, TWO_PI) - PI;

  float dist_raw;
  vec2 grad_oct;

  // If the point is within the span of the corner circle's arc,
  // use a circle SDF.
  // This works because the normals of the circular and superelliptical sections
  // agree at the transition angle, the total RSE curve is continuous and
  // the closest point on a continuous curve to a point lies along the normal.

  // We also compute the gradient of the distance function for normalization.
  if (abs(d_theta) < abs(span)) {
    dist_raw = distanceFromCircle(p_rel, radius);
    grad_oct = normalize(p_rel);
  } else {
    dist_raw = sdSuperellipse(p_oct / axis_length, se_degree) * axis_length;
    // Clamp the coordinate to avoid division by zero
    vec2 p_oct_clamped = max(p_oct, vec2(0.001));
    float max_p = max(p_oct_clamped.x, p_oct_clamped.y);
    vec2 p_safe = p_oct_clamped / max_p;
    // Approximation of the gradient
    grad_oct = normalize(pow(p_safe, vec2(se_degree - 1.0)));
  }

  if (p_norm.y + c <= p_norm.x) {
    grad_oct = grad_oct.yx;
  }

  // Divide the distance by the length of the gradient.
  // This ensures that the resulting distance has a gradient magnitude of 1
  // everywhere, allowing to be mixed cleanly with other SDFs.
  float corner_dist = dist_raw / length(grad_oct / scale);

  return max(dist_rect_local, corner_dist);
}

float distanceFromRoundedSuperellipse(vec2 p,
                                      vec4 quadrant_splits,
                                      vec2 size,
                                      vec4 superellipse_degrees_top,
                                      vec4 superellipse_degrees_right,
                                      vec4 superellipse_semi_axes_top,
                                      vec4 superellipse_semi_axes_right,
                                      vec4 angle_spans_top,
                                      vec4 angle_spans_right,
                                      vec4 octant_offsets_c,
                                      vec4 radii_width,
                                      vec4 radii_height,
                                      vec4 circle_centers_top_x,
                                      vec4 circle_centers_top_y,
                                      vec4 circle_centers_right_x,
                                      vec4 circle_centers_right_y,
                                      vec4 superellipse_scales_x,
                                      vec4 superellipse_scales_y,
                                      vec4 quadrant_centers_x,
                                      vec4 quadrant_centers_y) {
  vec2 T = vec2(quadrant_splits.x, -size.y);
  vec2 R = vec2(size.x, quadrant_splits.w);
  vec2 B = vec2(quadrant_splits.y, size.y);
  vec2 L = vec2(-size.x, quadrant_splits.z);

  // Grab the 2d cross products between p and the split points.
  // Imagine drawing a line L from the center of the shape to each split point,
  // p x L tells us whether p is clockwise or counterclockwise relative to L.
  float cT = T.x * p.y - T.y * p.x;
  float cR = R.x * p.y - R.y * p.x;
  float cB = B.x * p.y - B.y * p.x;
  float cL = L.x * p.y - L.y * p.x;

  int quadrant_index = 0;
  // cR = p x R <= 0 -> p is counterclockwise relative to R.
  // cT = p x T > 0 -> p is clockwise relative to T.
  // If p is clockwise relative to T and counterclockwise relative to R,
  // p must lie in the TR quadrant.
  // If cT = p x T == 0, p is parallel to T, which can misidentify points in the
  // BR quadrant.
  if ((cR < 0.0 || cR == 0.0 && p.x > 0.0) &&
      (cT > 0.0 || cT == 0.0 && p.x > 0.0)) {
    quadrant_index = 1;  // TR
  } else if ((cB < 0.0 || cB == 0.0 && p.x > 0.0) &&
             (cR > 0.0 || cR == 0.0 && p.x > 0.0)) {
    quadrant_index = 0;  // BR
  } else if (cB >= 0.0 && cL <= 0.0) {
    quadrant_index = 2;  // BL
  } else {
    quadrant_index = 3;  // TL
  }

  float se_degree_top = superellipse_degrees_top[quadrant_index];
  float se_degree_right = superellipse_degrees_right[quadrant_index];
  float se_a_top = superellipse_semi_axes_top[quadrant_index];
  float se_a_right = superellipse_semi_axes_right[quadrant_index];
  float angle_span_top = angle_spans_top[quadrant_index];
  float angle_span_right = angle_spans_right[quadrant_index];
  float c = octant_offsets_c[quadrant_index];
  float radius_top = radii_width[quadrant_index];
  float radius_right = radii_height[quadrant_index];

  vec2 circle_center_top = vec2(circle_centers_top_x[quadrant_index],
                                circle_centers_top_y[quadrant_index]);
  vec2 circle_center_right = vec2(circle_centers_right_x[quadrant_index],
                                  circle_centers_right_y[quadrant_index]);

  vec2 scale = vec2(superellipse_scales_x[quadrant_index],
                    superellipse_scales_y[quadrant_index]);

  vec2 q_center = vec2(quadrant_centers_x[quadrant_index],
                       quadrant_centers_y[quadrant_index]);

  return getQuadrantDistance(
      p, se_degree_top, se_degree_right, se_a_top, se_a_right, angle_span_top,
      angle_span_right, c, radius_top, radius_right, circle_center_top,
      circle_center_right, scale, q_center, quadrant_index);
}

float pixelSize(float sdf) {
  vec2 gradient = vec2(dFdx(sdf), dFdy(sdf));
  return length(gradient);
}

void main() {
  vec2 p = v_position - frag_info.center;

  float base_sdf = distanceFromRoundedSuperellipse(
      p, frag_info.quadrant_splits, frag_info.size,
      frag_info.superellipse_degrees_top, frag_info.superellipse_degrees_right,
      frag_info.superellipse_semi_axes_top,
      frag_info.superellipse_semi_axes_right, frag_info.angle_spans_top,
      frag_info.angle_spans_right, frag_info.octant_offsets_c,
      frag_info.radii_width, frag_info.radii_height,
      frag_info.circle_centers_top_x, frag_info.circle_centers_top_y,
      frag_info.circle_centers_right_x, frag_info.circle_centers_right_y,
      frag_info.superellipse_scales_x, frag_info.superellipse_scales_y,
      frag_info.quadrant_centers_x, frag_info.quadrant_centers_y);

  float base_pixel_size = pixelSize(base_sdf);

  vec2 sdf_and_pixel_size =
      (frag_info.stroked < 0.5)
          ? vec2(base_sdf, base_pixel_size)
          : SDFStroke(base_sdf, base_pixel_size, frag_info.stroke_width);

  float sdf = sdf_and_pixel_size.x;
  float pixel_size = sdf_and_pixel_size.y;

  float alpha = SDFAlpha(sdf, pixel_size, 1.0);

  frag_color = vec4(frag_info.color.rgb, frag_info.color.a * alpha);
  frag_color = IPPremultiply(frag_color);
}
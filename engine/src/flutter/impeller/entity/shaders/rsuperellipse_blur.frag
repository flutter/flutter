// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This algorithm is an adaptation of the RRect blur technique
// (`rrect_blur.frag`), tailored specifically for the RSuperellipse shape. The
// core distinction lies in how RSuperellipse curves are slightly drawn inward
// compared to RRect's.
//
// We begin by mapping the fragment's position to polar coordinates within the
// octant, with the angle `theta` ranging from 0 to pi/4. From this angle, we
// calculate a `baseRetraction`. This `baseRetraction` is crucial because it
// ensures the shape precisely matches an RSuperellipse when the blur `sigma` is
// very small.
//
// As we move further away from the edge (indicated by `d`, the radial
// distance), this retraction is progressively scaled down by `retractionDepth`.
// This scaling diminishes the influence of the retraction when the blur is
// significant, reflecting the idea that for larger blur values, subtle
// geometric differences like this retraction become visually insignificant.
//
// Essentially, the `baseRetraction` represents the exact distance between the
// RRect and RSuperellipse curves at a given `theta`.
//
// We split the angular range at `splitRadian`. This is a critical point because
// the RRect's geometry, and thus its formula, changes significantly: one side
// is a straight edge, the other a rounded corner. Our retraction calculation
// must adapt to these distinct behaviors.
//
// When `theta` is less than `splitRadian`, the RRect's edge is a straight line,
// and the RSuperellipse follows a well-defined superellipse formula. This
// allows us to directly compute the distance between the two curves.
//
// However, for `theta` greater than `splitRadian`, the exact mathematical
// expressions for both curves become too complex to evaluate efficiently. In
// these cases, we approximate the distance using a heuristic polynomial fit.
// This approximation is based on the observed behavior of the difference curve:
// it smoothly rises, then falls, eventually reaching zero with a zero slope.
//
// To see a visual representation of how this algorithm affects the shadow,
// refer to the `RoundSuperellipseShadowComparison` playground.
//
// (Note that the `theta` used throughout this file is distinct from the `theta`
// variable used in `RoundSuperellipseParam`.)

precision highp float;

#include <impeller/gaussian.glsl>
#include <impeller/math.glsl>
#include <impeller/rrect.glsl>
#include <impeller/types.glsl>

uniform FragInfo {
  vec4 color;
  vec4 center_adjust;
  vec3 r1_exponent_exponentInv;
  vec3 sInv_minEdge_scale;

  vec4 halfAxes_retractionDepth;
  // Information to compute retraction for two octants respectively.
  // [splitRadian, splitGap, n, nInvNeg]
  vec4 infoTop;
  vec4 infoRight;
  // Polynomial coeffs
  vec4 polyTop;
  vec4 polyRight;
}
frag_info;

in vec2 v_position;

out vec4 frag_color;

const float kPiOverFour = 3.1415926 / 4.0;

void main() {
  vec2 center = frag_info.center_adjust.xy;
  vec2 adjust = frag_info.center_adjust.zw;

  vec2 centered = abs(v_position - center);
  float d =
      computeRRectDistance(centered, adjust, frag_info.r1_exponent_exponentInv);

  /**** Start of RSuperellipse math ****/

  vec2 halfAxes = frag_info.halfAxes_retractionDepth.xy;
  float retractionDepth = frag_info.halfAxes_retractionDepth[2];
  float octantOffset = halfAxes.y - halfAxes.x;

  bool useTop = (centered.y - octantOffset) > centered.x;
  vec4 angularInfo = useTop ? frag_info.infoTop : frag_info.infoRight;
  float theta = atan(useTop ? centered.x / (centered.y - octantOffset)
                            : centered.y / (centered.x + octantOffset));

  float splitRadian = angularInfo[0];
  float splitGap = angularInfo[1];
  float n = angularInfo[2];
  float nInvNeg = angularInfo[3];

  float baseRetraction;
  if (theta < splitRadian) {
    float a = useTop ? halfAxes.x : halfAxes.y;
    baseRetraction = (1.0 - POW(1.0 + POW(tan(theta), n), nInvNeg)) * a;
  } else {
    float t = (theta - splitRadian) / (kPiOverFour - splitRadian);
    float tt = t * t;
    float ttt = tt * t;
    float retProg = dot(vec4(ttt, tt, t, 1.0),
                        useTop ? frag_info.polyTop : frag_info.polyRight);
    // Squaring `retProg` improves results empirically by boosting values > 1
    // and dampening values < 1.
    baseRetraction = retProg * retProg * splitGap;
  }
  float depthProg = smoothstep(-retractionDepth, 0.0, -abs(d));
  d += baseRetraction * depthProg;

  /**** End of RSuperellipse math ****/

  float z = computeRRectFade(d, frag_info.sInv_minEdge_scale);

  frag_color = frag_info.color * float16_t(z);
}

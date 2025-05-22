// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This approximate algorithm is based on the RRect blur algorithm
// (rrect_blur.frag), with adjustments to match the RSuperellipse shape. The key
// difference is that RSuperellipse curves are slightly retracted inward
// compared to RRect.
//
// The fragment position is first mapped to polar coordinates within the octant
// (theta in [0, pi/4]). A `baseRetraction` is computed from the angle, so that
// the shape matches a RSuperellipse when `sigma` is near zero. Then, the
// retraction is scaled based on the radial distance from the edge (`d`),
// reducing its influence when far away (`retractionDepth`). This reflects the
// idea that for large sigma, small geometric differences like retraction become
// visually negligible.
//
// The base retraction is the actual distance between the RRect and
// RSuperellipse curves at a given angle `theta`.
//
// The range is divided at the point where the RRect transitions from a straight
// edge to a rounded corner (marked as `splitRadian`), since this is where the
// shape difference becomes most noticeable.
//
// For theta < splitRadian, the RRect edge is a straight line and the
// RSuperellipse has a known superellipse formula, so we can directly compute
// the distance between them.
//
// For theta > splitRadian, the exact expressions for both curves are too
// complex to evaluate efficiently. Instead, we approximate the distance using a
// heuristic polynomial fit. This is based on the observation that the
// difference curve rises, then falls smoothly, eventually reaching zero with
// zero slope.
//
// See the `RoundSuperellipseShadowComparison` test for a visual preview of
// this algorithm's effect.

precision highp float;

#include <impeller/gaussian.glsl>
#include <impeller/math.glsl>
#include <impeller/rrect.glsl>
#include <impeller/types.glsl>

uniform FragInfo {
  vec4 color;
  vec2 center;
  vec2 adjust;
  float minEdge;
  float r1;
  float exponent;
  float sInv;
  float exponentInv;
  float scale;

  float octantOffset;
  // Information to compute retraction for two octants respectively.
  // [splitRadian, splitGap, n, nInvNeg]
  vec4 infoTop;
  vec4 infoRight;
  vec4 polyTop;
  vec4 polyRight;
  // Retraction penetration depth.
  float retractionDepth;
}
frag_info;

in vec2 v_position;

out f16vec4 frag_color;

const float kPiOverFour = 3.1415926 / 4.0;

void main() {
  vec2 centered = abs(v_position - frag_info.center);
  float d = computeRRectDistance(centered, frag_info.adjust, frag_info.r1,
                                 frag_info.exponent, frag_info.exponentInv);

  /**** Start of RSuperellipse math ****/

  bool useTop = (centered.y - frag_info.octantOffset) > centered.x;
  vec4 angularInfo = useTop ? frag_info.infoTop : frag_info.infoRight;
  float theta =
      atan(useTop ? centered.x / (centered.y - frag_info.octantOffset)
                  : centered.y / (centered.x + frag_info.octantOffset));

  float splitRadian = angularInfo[0];
  float splitGap = angularInfo[1];
  float n = angularInfo[2];
  float nInvNeg = angularInfo[3];

  float baseRetraction;
  if (theta < splitRadian) {
    float a = useTop ? frag_info.center.x : frag_info.center.y;
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
  float depthProg = smoothstep(-frag_info.retractionDepth, 0.0, -abs(d));
  d += baseRetraction * depthProg;

  /**** End of RSuperellipse math ****/

  float z =
      computeRRectFade(d, frag_info.sInv, frag_info.minEdge, frag_info.scale);

  frag_color = frag_info.color * float16_t(z);
}

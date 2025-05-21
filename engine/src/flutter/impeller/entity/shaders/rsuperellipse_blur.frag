// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This approximate algorithm is based on the RRect blur algorithm
// (rrect_blur.frag), with adjustments to match the RSuperellipse shape. The key
// difference is that RSuperellipse curves are slightly retracted inward
// compared to RRect.
//
// The fragment position is first mapped to polar coordinates within the octant
// (theta in [0, pi/4]). A base `retraction` is computed from the angle, so that
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
// edge to a rounded corner (marked as `peakRadian`), since this is where the
// shape difference becomes most noticeable.
//
// For theta < peakRadian, the RRect edge is a straight line and the
// RSuperellipse has a known superellipse formula, so we can directly compute
// the distance between them.
//
// For theta > peakRadian, the exact expressions for both curves are too complex
// to evaluate efficiently. Instead, we approximate the distance using a
// heuristic polynomial fit. This is based on the observation that the
// difference curve rises, then falls smoothly, eventually reaching zero with
// zero slope.
//
// See the `RoundSuperellipseShadowComparison` test for a visual preview of
// this algorithm's effect.

precision highp float;

#include <impeller/gaussian.glsl>
#include <impeller/math.glsl>
#include <impeller/types.glsl>

uniform FragInfo {
  f16vec4 color;
  vec2 center;
  vec2 adjust;
  float minEdge;
  float r1;
  float exponent;
  float sInv;
  float exponentInv;
  float scale;

  float octantOffset;
  // Angular retraction factors for two octants.
  // [peakRadian, n, peakGap, v0]
  vec4 factorTop;
  vec4 factorRight;
  // Retraction penetration depth.
  float retractionDepth;
}
frag_info;

in vec2 v_position;

out f16vec4 frag_color;

const float kTwoOverSqrtPi = 2.0 / sqrt(3.1415926);
const float kPiOverFour = 3.1415926 / 4.0;

float maxXY(vec2 v) {
  return max(v.x, v.y);
}

// use crate::math::compute_erf7;
float computeErf7(float x) {
  x *= kTwoOverSqrtPi;
  float xx = x * x;
  x = x + (0.24295 + (0.03395 + 0.0104 * xx) * xx) * (x * xx);
  return x / sqrt(1.0 + x * x);
}

// The length formula, but with an exponent other than 2
float powerDistance(vec2 p) {
  float xp = POW(p.x, frag_info.exponent);
  float yp = POW(p.y, frag_info.exponent);
  return POW(xp + yp, frag_info.exponentInv);
}

void main() {
  vec2 centered = abs(v_position - frag_info.center);
  vec2 adjusted = centered - frag_info.adjust;

  float dPos = powerDistance(max(adjusted, 0.0));
  float dNeg = min(maxXY(adjusted), 0.0);
  float d = dPos + dNeg - frag_info.r1;

  /**** Start of RSuperellipse math ****/

  bool useTop = (centered.y - frag_info.octantOffset) > centered.x;
  vec4 angularFactors = useTop ? frag_info.factorTop : frag_info.factorRight;
  float theta =
      atan(useTop ? centered.x / (centered.y - frag_info.octantOffset)
                  : centered.y / (centered.x + frag_info.octantOffset));

  float peakRadian = angularFactors[0];
  float n = angularFactors[1];
  float peakGap = angularFactors[2];
  float v0 = angularFactors[3];

  float retraction;
  if (theta < peakRadian) {
    float a = useTop ? frag_info.center.x : frag_info.center.y;
    retraction = (1.0 - POW(1.0 + POW(tan(theta), n), -1.0 / n)) * a;
  } else {
    float t = (theta - peakRadian) / (kPiOverFour - peakRadian);
    float tt = t * t;
    float ttt = tt * t;
    // A polynomial that satisfies f(0) = 1, f'(0) = v0, f(1) = 0, f'(1) = 0
    float retProg = ((v0 + 2.0) * ttt + (-2.0 * v0 - 3.0) * tt + v0 * t + 1.0);
    // Squaring `retProg` improves results empirically by boosting values > 1
    // and dampening values < 1.
    retraction = retProg * retProg * peakGap;
  }
  float depthProg = smoothstep(-frag_info.retractionDepth, 0., d);
  d += retraction * depthProg;

  /**** End of RSuperellipse math ****/

  float z =
      frag_info.scale * (computeErf7(frag_info.sInv * (frag_info.minEdge + d)) -
                         computeErf7(frag_info.sInv * d));

  frag_color = frag_info.color * float16_t(z);
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/dl_canvas.h"

namespace {

// ShadowBounds code adapted from SkShadowUtils using the Directional flag.

using DlScalar = flutter::DlScalar;
using DlVector3 = flutter::DlVector3;
using DlVector2 = flutter::DlVector2;
using DlRect = flutter::DlRect;
using DlMatrix = flutter::DlMatrix;

static constexpr DlScalar kAmbientHeightFactor = 1.0f / 128.0f;
static constexpr DlScalar kAmbientGeomFactor = 64.0f;
// Assuming that we have a light height of 600 for the spot shadow, the spot
// values will reach their maximum at a height of approximately 292.3077.
// We'll round up to 300 to keep it simple.
static constexpr DlScalar kMaxAmbientRadius =
    300.0f * kAmbientHeightFactor * kAmbientGeomFactor;

inline DlScalar AmbientBlurRadius(DlScalar height) {
  return std::min(height * kAmbientHeightFactor * kAmbientGeomFactor,
                  kMaxAmbientRadius);
}

struct DrawShadowRec {
  DlVector3 light_position;
  DlScalar light_radius = 0.0f;
  DlScalar occluder_z = 0.0f;
};

static inline float DivideAndClamp(float numer,
                                   float denom,
                                   float min,
                                   float max) {
  float result = std::clamp(numer / denom, min, max);
  // ensure that clamp handled non-finites correctly
  FML_DCHECK(result >= min && result <= max);
  return result;
}

inline void GetDirectionalParams(DrawShadowRec params,
                                 DlScalar* blur_radius,
                                 DlScalar* scale,
                                 DlVector2* translate) {
  *blur_radius = params.light_radius * params.occluder_z;
  *scale = 1.0f;
  // Max z-ratio is ("max expected elevation" / "min allowable z").
  constexpr DlScalar kMaxZRatio = 64.0f / flutter::kEhCloseEnough;
  DlScalar zRatio = DivideAndClamp(params.occluder_z, params.light_position.z,
                                   0.0f, kMaxZRatio);
  *translate = DlVector2(-zRatio * params.light_position.x,
                         -zRatio * params.light_position.y);
}

DlRect GetLocalBounds(DlRect ambient_bounds,
                      const DlMatrix& matrix,
                      const DrawShadowRec& params) {
  if (!matrix.IsInvertible() || ambient_bounds.IsEmpty()) {
    return DlRect();
  }

  DlScalar ambient_blur;
  DlScalar spot_blur;
  DlScalar spot_scale;
  DlVector2 spot_offset;

  if (matrix.HasPerspective2D()) {
    // transform ambient and spot bounds into device space
    ambient_bounds = ambient_bounds.TransformAndClipBounds(matrix);

    // get ambient blur (in device space)
    ambient_blur = AmbientBlurRadius(params.occluder_z);

    // get spot params (in device space)
    GetDirectionalParams(params, &spot_blur, &spot_scale, &spot_offset);
  } else {
    auto min_scale = matrix.GetMinScale2D();
    // We've already checked the matrix for perspective elements.
    FML_DCHECK(min_scale.has_value());
    DlScalar device_to_local_scale = 1.0f / min_scale.value_or(1.0f);

    // get ambient blur (in local space)
    DlScalar device_space_ambient_blur = AmbientBlurRadius(params.occluder_z);
    ambient_blur = device_space_ambient_blur * device_to_local_scale;

    // get spot params (in local space)
    GetDirectionalParams(params, &spot_blur, &spot_scale, &spot_offset);
    // light dir is in device space, map spot offset back into local space
    DlMatrix inverse = matrix.Invert();
    spot_offset = inverse.TransformDirection(spot_offset);

    // convert spot blur to local space
    spot_blur *= device_to_local_scale;
  }

  // in both cases, adjust ambient and spot bounds
  DlRect spot_bounds = ambient_bounds;
  ambient_bounds = ambient_bounds.Expand(ambient_blur);
  spot_bounds = spot_bounds.Scale(spot_scale);
  spot_bounds = spot_bounds.Shift(spot_offset);
  spot_bounds = spot_bounds.Expand(spot_blur);

  // merge bounds
  DlRect result = ambient_bounds.Union(spot_bounds);
  // outset a bit to account for floating point error
  result = result.Expand(1.0f, 1.0f);

  // if perspective, transform back to src space
  if (matrix.HasPerspective2D()) {
    DlMatrix inverse = matrix.Invert();
    result = result.TransformAndClipBounds(inverse);
  }
  return result;
}

}  // namespace

namespace flutter {

DlRect DlCanvas::ComputeShadowBounds(const DlPath& path,
                                     float elevation,
                                     DlScalar dpr,
                                     const DlMatrix& ctm) {
  return GetLocalBounds(
      path.GetBounds(), ctm,
      {
          .light_position = DlVector3(0.0f, -1.0f, 1.0f),
          .light_radius = kShadowLightRadius / kShadowLightHeight,
          .occluder_z = dpr * elevation,
      });
}

}  // namespace flutter

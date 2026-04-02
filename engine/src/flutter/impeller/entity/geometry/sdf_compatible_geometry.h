// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_GEOMETRY_SDF_COMPATIBLE_GEOMETRY_H_
#define FLUTTER_IMPELLER_ENTITY_GEOMETRY_SDF_COMPATIBLE_GEOMETRY_H_

#include "impeller/entity/geometry/geometry.h"
#include "impeller/geometry/rect.h"
#include "impeller/geometry/stroke_parameters.h"

namespace impeller {

// Interface for geometries that can be rendered with an SDF shader.
class SDFCompatibleGeometry : public Geometry {
 public:
  // Returns the bounds rectangle of the base shape. This is used by the
  // shader to determine the size of drawn shape.
  //
  // This base shape bounds does not include padding for stroke width and
  // antialiasing. The drawn shape's size is based on this bounds, but will be
  // larger than this bounds to account for stroke and AA padding.
  virtual Rect GetBaseShapeBounds() const = 0;

  // If the geometry is stroked, returns the stroke parameters.
  virtual std::optional<StrokeParameters> GetStrokeParameters() const {
    return std::nullopt;
  }

  // Set the padding pixels used for antialiasing.
  void SetAntialiasPadding(Scalar antialias_padding) {
    antialias_padding_ = antialias_padding;
  }

  // Get the padding pixels used for antialiasing.
  Scalar GetAntialiasPadding() const { return antialias_padding_; }

 private:
  Scalar antialias_padding_ = 0.0f;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_SDF_COMPATIBLE_GEOMETRY_H_

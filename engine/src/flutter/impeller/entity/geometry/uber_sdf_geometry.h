// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_GEOMETRY_UBER_SDF_GEOMETRY_H_
#define FLUTTER_IMPELLER_ENTITY_GEOMETRY_UBER_SDF_GEOMETRY_H_

#include <memory>

#include "impeller/entity/contents/uber_sdf_parameters.h"
#include "impeller/entity/geometry/geometry.h"

namespace impeller {

class UberSDFGeometry {
 public:
  static std::unique_ptr<Geometry> Make(const UberSDFParameters& params);
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_UBER_SDF_GEOMETRY_H_

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <array>
#include <memory>

#include "impeller/scene/importer/importer.h"

#include "flutter/fml/mapping.h"

namespace impeller {
namespace scene {
namespace importer {

bool ParseGLTF(const fml::Mapping& source_mapping, fb::MeshT& out_mesh) {
  // TODO(bdero): Parse source_mapping and populare out_mesh with just the first
  //              mesh in the GLTF.
  return true;
}

}  // namespace importer
}  // namespace scene
}  // namespace impeller

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_SCENE_PIPELINE_KEY_H_
#define FLUTTER_IMPELLER_SCENE_PIPELINE_KEY_H_

#include "flutter/fml/hash_combine.h"

namespace impeller {
namespace scene {

enum class GeometryType {
  kUnskinned = 0,
  kSkinned = 1,
  kLastType = kSkinned,
};
enum class MaterialType {
  kUnlit = 0,
  kLastType = kUnlit,
};

struct PipelineKey {
  GeometryType geometry_type = GeometryType::kUnskinned;
  MaterialType material_type = MaterialType::kUnlit;

  struct Hash {
    constexpr std::size_t operator()(const PipelineKey& o) const {
      return fml::HashCombine(o.geometry_type, o.material_type);
    }
  };

  struct Equal {
    constexpr bool operator()(const PipelineKey& lhs,
                              const PipelineKey& rhs) const {
      return lhs.geometry_type == rhs.geometry_type &&
             lhs.material_type == rhs.material_type;
    }
  };
};

}  // namespace scene
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_SCENE_PIPELINE_KEY_H_

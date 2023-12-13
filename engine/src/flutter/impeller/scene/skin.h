// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_SCENE_SKIN_H_
#define FLUTTER_IMPELLER_SCENE_SKIN_H_

#include <memory>
#include <optional>

#include "flutter/fml/macros.h"

#include "impeller/core/allocator.h"
#include "impeller/core/texture.h"
#include "impeller/scene/importer/scene_flatbuffers.h"
#include "impeller/scene/node.h"

namespace impeller {
namespace scene {

class Skin final {
 public:
  static std::unique_ptr<Skin> MakeFromFlatbuffer(
      const fb::Skin& skin,
      const std::vector<std::shared_ptr<Node>>& scene_nodes);
  ~Skin();

  Skin(Skin&&);
  Skin& operator=(Skin&&);

  std::shared_ptr<Texture> GetJointsTexture(Allocator& allocator);

 private:
  Skin();

  std::vector<std::shared_ptr<Node>> joints_;
  std::vector<Matrix> inverse_bind_matrices_;

  Skin(const Skin&) = delete;

  Skin& operator=(const Skin&) = delete;
};

}  // namespace scene
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_SCENE_SKIN_H_

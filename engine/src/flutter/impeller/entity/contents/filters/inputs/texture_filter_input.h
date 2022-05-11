// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/entity/contents/filters/inputs/filter_input.h"

#include "impeller/geometry/matrix.h"

namespace impeller {

class TextureFilterInput final : public FilterInput {
 public:
  ~TextureFilterInput() override;

  // |FilterInput|
  Variant GetInput() const override;

  // |FilterInput|
  std::optional<Snapshot> GetSnapshot(const ContentContext& renderer,
                                      const Entity& entity) const override;

  // |FilterInput|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |FilterInput|
  Matrix GetLocalTransform(const Entity& entity) const override;

 private:
  TextureFilterInput(std::shared_ptr<Texture> texture,
                     Matrix local_transform = Matrix());

  std::shared_ptr<Texture> texture_;
  Matrix local_transform_;

  friend FilterInput;
};

}  // namespace impeller

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/entity/contents/filters/inputs/filter_input.h"

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

 private:
  TextureFilterInput(std::shared_ptr<Texture> texture);

  std::shared_ptr<Texture> texture_;

  friend FilterInput;
};

}  // namespace impeller

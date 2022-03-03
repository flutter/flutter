// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/geometry/rect.h"

namespace impeller {

class Texture;

class TextureContents final : public Contents {
 public:
  TextureContents();

  ~TextureContents() override;

  void SetTexture(std::shared_ptr<Texture> texture);

  std::shared_ptr<Texture> GetTexture() const;

  void SetSourceRect(const IRect& source_rect);

  void SetOpacity(Scalar opacity);

  const IRect& GetSourceRect() const;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

 public:
  std::shared_ptr<Texture> texture_;
  IRect source_rect_;
  Scalar opacity_ = 1.0f;

  FML_DISALLOW_COPY_AND_ASSIGN(TextureContents);
};

}  // namespace impeller

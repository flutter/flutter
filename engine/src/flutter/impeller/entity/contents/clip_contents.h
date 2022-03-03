// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/contents.h"
#include "typographer/glyph_atlas.h"

namespace impeller {

class GlyphAtlas;

class ClipContents final : public Contents {
 public:
  ClipContents();

  ~ClipContents();

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(ClipContents);
};

class ClipRestoreContents final : public Contents {
 public:
  ClipRestoreContents();

  ~ClipRestoreContents();

  void SetGlyphAtlas(std::shared_ptr<GlyphAtlas> atlas);

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(ClipRestoreContents);
};

}  // namespace impeller

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <variant>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/geometry/color.h"
#include "impeller/typographer/text_frame.h"

namespace impeller {

class GlyphAtlas;
class LazyGlyphAtlas;
class Context;

class TextContents final : public Contents {
 public:
  TextContents();

  ~TextContents();

  void SetTextFrame(TextFrame frame);

  void SetGlyphAtlas(std::shared_ptr<GlyphAtlas> atlas);

  void SetGlyphAtlas(std::shared_ptr<LazyGlyphAtlas> atlas);

  void SetColor(Color color);

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

 private:
  TextFrame frame_;
  Color color_;
  mutable std::variant<std::shared_ptr<GlyphAtlas>,
                       std::shared_ptr<LazyGlyphAtlas>>
      atlas_;

  std::shared_ptr<GlyphAtlas> ResolveAtlas(
      std::shared_ptr<Context> context) const;

  FML_DISALLOW_COPY_AND_ASSIGN(TextContents);
};

}  // namespace impeller

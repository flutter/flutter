// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/geometry/color.h"
#include "impeller/typographer/text_frame.h"

namespace impeller {

class GlyphAtlas;

class TextContents final : public Contents {
 public:
  TextContents();

  ~TextContents();

  void SetTextFrame(TextFrame frame);

  void SetGlyphAtlas(std::shared_ptr<GlyphAtlas> atlas);

  void SetColor(Color color);

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

 private:
  TextFrame frame_;
  Color color_;
  std::shared_ptr<GlyphAtlas> atlas_;

  FML_DISALLOW_COPY_AND_ASSIGN(TextContents);
};

}  // namespace impeller

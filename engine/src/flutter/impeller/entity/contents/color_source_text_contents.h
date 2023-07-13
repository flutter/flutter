// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <variant>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/text_contents.h"

namespace impeller {

class ColorSourceTextContents final : public Contents {
 public:
  ColorSourceTextContents();

  ~ColorSourceTextContents();

  void SetTextContents(std::shared_ptr<TextContents> text_contents);

  void SetColorSourceContents(
      std::shared_ptr<ColorSourceContents> color_source_contents);

  void SetTextPosition(Point position);

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

 private:
  Point position_;
  std::shared_ptr<TextContents> text_contents_;
  std::shared_ptr<ColorSourceContents> color_source_contents_;

  FML_DISALLOW_COPY_AND_ASSIGN(ColorSourceTextContents);
};

}  // namespace impeller

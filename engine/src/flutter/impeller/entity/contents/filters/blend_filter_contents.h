// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/entity/contents/filters/filter_contents.h"

namespace impeller {

class BlendFilterContents : public FilterContents {
 public:
  using AdvancedBlendProc =
      std::function<bool(const std::vector<Snapshot>& input_textures,
                         const ContentContext& renderer,
                         RenderPass& pass)>;

  BlendFilterContents();

  ~BlendFilterContents() override;

  void SetBlendMode(Entity::BlendMode blend_mode);

 private:
  // |FilterContents|
  bool RenderFilter(const std::vector<Snapshot>& input_textures,
                    const ContentContext& renderer,
                    RenderPass& pass,
                    const Matrix& transform) const override;

  Entity::BlendMode blend_mode_;
  AdvancedBlendProc advanced_blend_proc_;

  FML_DISALLOW_COPY_AND_ASSIGN(BlendFilterContents);
};

}  // namespace impeller

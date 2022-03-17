// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/contents.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      Disregard existing contents on the render target and use the
///             provided filter to render to the entire target.
///
class ClearContents final : public Contents {
 public:
  ClearContents(std::shared_ptr<Contents> contents);

  ~ClearContents();

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

 private:
  std::shared_ptr<Contents> contents_;

  FML_DISALLOW_COPY_AND_ASSIGN(ClearContents);
};

}  // namespace impeller

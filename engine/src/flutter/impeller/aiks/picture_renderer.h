// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/entity/entity_renderer.h"

namespace impeller {

class Surface;
class RenderPass;
class Context;
struct Picture;

class PictureRenderer {
 public:
  PictureRenderer(std::shared_ptr<Context> context);

  ~PictureRenderer();

  bool IsValid() const;

  [[nodiscard]] bool Render(const Surface& surface,
                            RenderPass& parent_pass,
                            const Picture& picture);

 private:
  EntityRenderer entity_renderer_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(PictureRenderer);
};

}  // namespace impeller

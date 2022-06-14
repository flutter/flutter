// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

struct Picture;
class RenderPass;

class AiksContext {
 public:
  AiksContext(std::shared_ptr<Context> context);

  ~AiksContext();

  bool IsValid() const;

  std::shared_ptr<Context> GetContext() const;

  bool Render(const Picture& picture, RenderTarget& render_target);

 private:
  std::shared_ptr<Context> context_;
  std::unique_ptr<ContentContext> content_context_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(AiksContext);
};

}  // namespace impeller

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/render_target.h"
#include "impeller/typographer/typographer_context.h"

namespace impeller {

struct Picture;
class RenderPass;

class AiksContext {
 public:
  /// Construct a new AiksContext.
  ///
  /// @param context              The Impeller context that Aiks should use for
  ///                             allocating resources and executing device
  ///                             commands. Required.
  /// @param typographer_context  The text backend to use for rendering text. If
  ///                             `nullptr` is supplied, then attempting to draw
  ///                             text with Aiks will result in validation
  ///                             errors.
  AiksContext(std::shared_ptr<Context> context,
              std::shared_ptr<TypographerContext> typographer_context);

  ~AiksContext();

  bool IsValid() const;

  std::shared_ptr<Context> GetContext() const;

  ContentContext& GetContentContext() const;

  bool Render(const Picture& picture, RenderTarget& render_target);

 private:
  std::shared_ptr<Context> context_;
  std::unique_ptr<ContentContext> content_context_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(AiksContext);
};

}  // namespace impeller

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/playground/playground_test.h"

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/entity_pass.h"
#include "impeller/typographer/text_render_context.h"

namespace impeller {

class EntityPlayground : public PlaygroundTest {
 public:
  using EntityPlaygroundCallback =
      std::function<bool(ContentContext& context, RenderPass& pass)>;

  EntityPlayground();

  ~EntityPlayground();

  void SetTextRenderContext(
      std::shared_ptr<TextRenderContext> text_render_context);

  bool OpenPlaygroundHere(Entity entity);

  bool OpenPlaygroundHere(EntityPass& entity_pass);

  bool OpenPlaygroundHere(EntityPlaygroundCallback callback);

 private:
  std::shared_ptr<TextRenderContext> text_render_context_;

  FML_DISALLOW_COPY_AND_ASSIGN(EntityPlayground);
};

}  // namespace impeller

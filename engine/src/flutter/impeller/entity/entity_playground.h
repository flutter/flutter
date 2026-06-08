// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_ENTITY_PLAYGROUND_H_
#define FLUTTER_IMPELLER_ENTITY_ENTITY_PLAYGROUND_H_

#include "impeller/playground/playground_test.h"

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/typographer/typographer_context.h"

namespace impeller {

class EntityPlayground : public PlaygroundTest {
 public:
  using EntityPlaygroundCallback =
      std::function<bool(ContentContext& context, RenderPass& pass)>;

  EntityPlayground();

  ~EntityPlayground();

  void SetTypographerContext(
      std::shared_ptr<TypographerContext> typographer_context);

  std::shared_ptr<TypographerContext> GetTypographerContext() const;

  bool OpenPlaygroundHere(Entity entity);

  bool OpenPlaygroundHere(EntityPlaygroundCallback callback);

  std::shared_ptr<ContentContext> GetContentContext() const;

 private:
  std::shared_ptr<TypographerContext> typographer_context_;

  class ContentContextHolder {
   public:
    ContentContextHolder(
        const std::shared_ptr<Context>& context,
        const std::shared_ptr<TypographerContext>& typographer_context)
        : content_context_(
              std::make_shared<ContentContext>(context, typographer_context)) {}

    ~ContentContextHolder() {
      content_context_->GetTransientsDataBuffer().Reset();
      content_context_->GetTransientsIndexesBuffer().Reset();
      content_context_->GetTextShadowCache().MarkFrameEnd();
      content_context_->GetLazyGlyphAtlas()->ResetTextFrames();
      content_context_->GetContext()->DisposeThreadLocalCachedResources();
      content_context_.reset();
    }

    std::shared_ptr<ContentContext> GetContentContext() {
      return content_context_;
    }

   private:
    std::shared_ptr<ContentContext> content_context_;
  };

  mutable std::shared_ptr<ContentContextHolder> context_holder_;

  EntityPlayground(const EntityPlayground&) = delete;

  EntityPlayground& operator=(const EntityPlayground&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_ENTITY_PLAYGROUND_H_

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_TEXT_SHADOW_CACHE_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_TEXT_SHADOW_CACHE_H_

#include <memory>
#include <unordered_map>

#include "impeller/entity/entity.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

class TextShadowCache {
 public:
  TextShadowCache() = default;

  ~TextShadowCache() = default;

  void MarkFrameStart();

  void MarkFrameEnd();

  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass,
              const std::shared_ptr<FilterContents>& contents,
              int text_key);

 private:
  struct TextShadowCacheData {
    Entity entity;
    bool used_this_frame = true;
  };

  std::unordered_map<int, TextShadowCacheData> entries_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_TEXT_SHADOW_CACHE_H_

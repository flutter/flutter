// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/playground/playground.h"

namespace impeller {

class EntityPlayground : public Playground {
 public:
  using EntityPlaygroundCallback =
      std::function<bool(ContentContext& context, RenderPass& pass)>;

  EntityPlayground();

  ~EntityPlayground();

  bool OpenPlaygroundHere(Entity entity);

  bool OpenPlaygroundHere(EntityPlaygroundCallback callback);

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(EntityPlayground);
};

}  // namespace impeller

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/aiks_playground.h"

#include "impeller/aiks/picture_renderer.h"

namespace impeller {

AiksPlayground::AiksPlayground() = default;

AiksPlayground::~AiksPlayground() = default;

bool AiksPlayground::OpenPlaygroundHere(const Picture& picture) {
  auto renderer = std::make_shared<PictureRenderer>(GetContext());
  if (!renderer) {
    return false;
  }

  return Playground::OpenPlaygroundHere(
      [renderer, &picture](const Surface& surface, RenderPass& pass) -> bool {
        return renderer->Render(surface, pass, picture);
      });
}

}  // namespace impeller

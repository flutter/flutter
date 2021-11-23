// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/aiks_playground.h"

#include "impeller/aiks/aiks_renderer.h"

namespace impeller {

AiksPlayground::AiksPlayground() = default;

AiksPlayground::~AiksPlayground() = default;

bool AiksPlayground::OpenPlaygroundHere(const Picture& picture) {
  AiksRenderer renderer(GetContext());

  if (!renderer.IsValid()) {
    return false;
  }

  return Playground::OpenPlaygroundHere(
      [&renderer, &picture](RenderPass& pass) -> bool {
        return renderer.Render(picture, pass);
      });
}

}  // namespace impeller

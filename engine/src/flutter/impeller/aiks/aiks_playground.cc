// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/aiks_playground.h"

#include <memory>

#include "impeller/aiks/aiks_context.h"
#include "impeller/typographer/backends/skia/typographer_context_skia.h"
#include "impeller/typographer/typographer_context.h"

namespace impeller {

AiksPlayground::AiksPlayground()
    : typographer_context_(TypographerContextSkia::Make()) {}

AiksPlayground::~AiksPlayground() = default;

void AiksPlayground::SetTypographerContext(
    std::shared_ptr<TypographerContext> typographer_context) {
  typographer_context_ = std::move(typographer_context);
}

void AiksPlayground::TearDown() {
  inspector_.HackResetDueToTextureLeaks();
  PlaygroundTest::TearDown();
}

bool AiksPlayground::OpenPlaygroundHere(Picture picture) {
  return OpenPlaygroundHere([&picture](AiksContext& renderer) -> Picture {
    return std::move(picture);
  });
}

bool AiksPlayground::OpenPlaygroundHere(AiksPlaygroundCallback callback) {
  if (!switches_.enable_playground) {
    return true;
  }

  AiksContext renderer(GetContext(), typographer_context_);

  if (!renderer.IsValid()) {
    return false;
  }

  return Playground::OpenPlaygroundHere(
      [this, &renderer, &callback](RenderTarget& render_target) -> bool {
        const std::optional<Picture>& picture = inspector_.RenderInspector(
            renderer, [&]() { return callback(renderer); });

        if (!picture.has_value()) {
          return false;
        }
        return renderer.Render(*picture, render_target, true);
      });
}

bool AiksPlayground::ImGuiBegin(const char* name,
                                bool* p_open,
                                ImGuiWindowFlags flags) {
  ImGui::Begin(name, p_open, flags);
  return true;
}

}  // namespace impeller

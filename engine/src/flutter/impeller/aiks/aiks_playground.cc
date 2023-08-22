// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/aiks_playground.h"

#include <memory>

#include "impeller/aiks/aiks_context.h"
#include "impeller/typographer/backends/skia/text_render_context_skia.h"
#include "impeller/typographer/text_render_context.h"
#include "third_party/imgui/imgui.h"

namespace impeller {

AiksPlayground::AiksPlayground()
    : text_render_context_(TextRenderContextSkia::Make()) {}

AiksPlayground::~AiksPlayground() = default;

void AiksPlayground::SetTextRenderContext(
    std::shared_ptr<TextRenderContext> text_render_context) {
  text_render_context_ = std::move(text_render_context);
}

bool AiksPlayground::OpenPlaygroundHere(const Picture& picture) {
  return OpenPlaygroundHere(
      [&picture](AiksContext& renderer, RenderTarget& render_target) -> bool {
        return renderer.Render(picture, render_target);
      });
}

bool AiksPlayground::OpenPlaygroundHere(AiksPlaygroundCallback callback) {
  if (!switches_.enable_playground) {
    return true;
  }

  AiksContext renderer(GetContext(), text_render_context_);

  if (!renderer.IsValid()) {
    return false;
  }

  return Playground::OpenPlaygroundHere(
      [&renderer, &callback](RenderTarget& render_target) -> bool {
        static bool wireframe = false;
        if (ImGui::IsKeyPressed(ImGuiKey_Z)) {
          wireframe = !wireframe;
          renderer.GetContentContext().SetWireframe(wireframe);
        }
        return callback(renderer, render_target);
      });
}

}  // namespace impeller

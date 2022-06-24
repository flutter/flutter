// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/picture.h"

#include <memory>
#include <optional>

#include "impeller/base/validation.h"
#include "impeller/entity/entity.h"
#include "impeller/renderer/render_target.h"
#include "impeller/renderer/snapshot.h"

namespace impeller {

std::optional<Snapshot> Picture::Snapshot(AiksContext& context) {
  auto coverage = pass->GetElementsCoverage(std::nullopt);
  if (!coverage.has_value() || coverage->IsEmpty()) {
    return std::nullopt;
  }

  const auto translate = Matrix::MakeTranslation(-coverage->origin);
  pass->IterateAllEntities([&translate](auto& entity) -> bool {
    entity.SetTransformation(translate * entity.GetTransformation());
    return true;
  });

  // This texture isn't host visible, but we might want to add host visible
  // features to Image someday.
  auto target = RenderTarget::CreateOffscreen(
      *context.GetContext(),
      ISize(coverage->size.width, coverage->size.height));
  if (!target.IsValid()) {
    VALIDATION_LOG << "Could not create valid RenderTarget.";
    return std::nullopt;
  }

  if (!context.Render(*this, target)) {
    VALIDATION_LOG << "Could not render Picture to Texture.";
    return std::nullopt;
  }

  auto texture = target.GetRenderTargetTexture();
  if (!texture) {
    VALIDATION_LOG << "RenderTarget has no target texture.";
    return std::nullopt;
  }

  return impeller::Snapshot{
      .texture = std::move(texture),
      .transform = translate.MakeTranslation(coverage->origin)};
};

}  // namespace impeller

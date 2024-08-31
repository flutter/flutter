// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/picture.h"

#include <memory>
#include <optional>

#include "impeller/base/validation.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

std::shared_ptr<Texture> Picture::ToImage(AiksContext& context,
                                          ISize size) const {
  if (size.IsEmpty()) {
    return nullptr;
  }
  return RenderToTexture(context, size);
}

std::shared_ptr<Texture> Picture::RenderToTexture(
    AiksContext& context,
    ISize size,
    std::optional<const Matrix> translate) const {
  FML_DCHECK(!size.IsEmpty());

  pass->IterateAllEntities([&translate](auto& entity) -> bool {
    auto matrix = translate.has_value()
                      ? translate.value() * entity.GetTransform()
                      : entity.GetTransform();
    entity.SetTransform(matrix);
    return true;
  });

  // This texture isn't host visible, but we might want to add host visible
  // features to Image someday.
  const std::shared_ptr<Context>& impeller_context = context.GetContext();
  // Do not use the render target cache as the lifecycle of this texture
  // will outlive a particular frame.
  RenderTargetAllocator render_target_allocator =
      RenderTargetAllocator(impeller_context->GetResourceAllocator());
  RenderTarget target;
  if (impeller_context->GetCapabilities()->SupportsOffscreenMSAA()) {
    target = render_target_allocator.CreateOffscreenMSAA(
        *impeller_context,  // context
        size,               // size
        /*mip_count=*/1,
        "Picture Snapshot MSAA",  // label
        RenderTarget::
            kDefaultColorAttachmentConfigMSAA  // color_attachment_config
    );
  } else {
    target = render_target_allocator.CreateOffscreen(
        *impeller_context,  // context
        size,               // size
        /*mip_count=*/1,
        "Picture Snapshot",                          // label
        RenderTarget::kDefaultColorAttachmentConfig  // color_attachment_config
    );
  }
  if (!target.IsValid()) {
    VALIDATION_LOG << "Could not create valid RenderTarget.";
    return nullptr;
  }

  if (!context.Render(*this, target, false)) {
    VALIDATION_LOG << "Could not render Picture to Texture.";
    return nullptr;
  }

  auto texture = target.GetRenderTargetTexture();
  if (!texture) {
    VALIDATION_LOG << "RenderTarget has no target texture.";
    return nullptr;
  }

  return texture;
}

}  // namespace impeller

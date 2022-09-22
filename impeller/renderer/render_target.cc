// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/render_target.h"

#include "impeller/base/strings.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/allocator.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/texture.h"

namespace impeller {

RenderTarget::RenderTarget() = default;

RenderTarget::~RenderTarget() = default;

bool RenderTarget::IsValid() const {
  // Validate that there is a color attachment at zero index.
  if (!HasColorAttachment(0u)) {
    VALIDATION_LOG
        << "Render target does not have color attachment at index 0.";
    return false;
  }

  // Validate that all attachments are of the same size.
  {
    std::optional<ISize> size;
    bool sizes_are_same = true;
    auto iterator = [&](const Attachment& attachment) -> bool {
      if (!size.has_value()) {
        size = attachment.texture->GetSize();
      }
      if (size != attachment.texture->GetSize()) {
        sizes_are_same = false;
        return false;
      }
      return true;
    };
    IterateAllAttachments(iterator);
    if (!sizes_are_same) {
      VALIDATION_LOG
          << "Sizes of all render target attachments are not the same.";
      return false;
    }
  }

  // Validate that all attachments are of the same type and sample counts.
  {
    std::optional<TextureType> texture_type;
    std::optional<SampleCount> sample_count;
    bool passes_type_validation = true;
    auto iterator = [&](const Attachment& attachment) -> bool {
      if (!texture_type.has_value() || !sample_count.has_value()) {
        texture_type = attachment.texture->GetTextureDescriptor().type;
        sample_count = attachment.texture->GetTextureDescriptor().sample_count;
      }

      if (texture_type != attachment.texture->GetTextureDescriptor().type) {
        passes_type_validation = false;
        return false;
      }

      if (sample_count !=
          attachment.texture->GetTextureDescriptor().sample_count) {
        passes_type_validation = false;
        return false;
      }

      return true;
    };
    IterateAllAttachments(iterator);
    if (!passes_type_validation) {
      VALIDATION_LOG << "Render target texture types are not of the same type "
                        "and sample count.";
      return false;
    }
  }

  return true;
}

void RenderTarget::IterateAllAttachments(
    std::function<bool(const Attachment& attachment)> iterator) const {
  for (const auto& color : colors_) {
    if (!iterator(color.second)) {
      return;
    }
  }

  if (depth_.has_value()) {
    if (!iterator(depth_.value())) {
      return;
    }
  }

  if (stencil_.has_value()) {
    if (!iterator(stencil_.value())) {
      return;
    }
  }
}

SampleCount RenderTarget::GetSampleCount() const {
  if (auto found = colors_.find(0u); found != colors_.end()) {
    return found->second.texture->GetTextureDescriptor().sample_count;
  }
  return SampleCount::kCount1;
}

bool RenderTarget::HasColorAttachment(size_t index) const {
  if (auto found = colors_.find(index); found != colors_.end()) {
    return true;
  }
  return false;
}

std::optional<ISize> RenderTarget::GetColorAttachmentSize(size_t index) const {
  auto found = colors_.find(index);

  if (found == colors_.end()) {
    return std::nullopt;
  }

  return found->second.texture->GetSize();
}

ISize RenderTarget::GetRenderTargetSize() const {
  auto size = GetColorAttachmentSize(0u);
  return size.has_value() ? size.value() : ISize{};
}

std::shared_ptr<Texture> RenderTarget::GetRenderTargetTexture() const {
  auto found = colors_.find(0u);
  if (found == colors_.end()) {
    return nullptr;
  }
  return found->second.resolve_texture ? found->second.resolve_texture
                                       : found->second.texture;
}

RenderTarget& RenderTarget::SetColorAttachment(ColorAttachment attachment,
                                               size_t index) {
  if (attachment.IsValid()) {
    colors_[index] = attachment;
  }
  return *this;
}

RenderTarget& RenderTarget::SetDepthAttachment(DepthAttachment attachment) {
  if (attachment.IsValid()) {
    depth_ = std::move(attachment);
  }
  return *this;
}

RenderTarget& RenderTarget::SetStencilAttachment(StencilAttachment attachment) {
  if (attachment.IsValid()) {
    stencil_ = std::move(attachment);
  }
  return *this;
}

const std::map<size_t, ColorAttachment>& RenderTarget::GetColorAttachments()
    const {
  return colors_;
}

const std::optional<DepthAttachment>& RenderTarget::GetDepthAttachment() const {
  return depth_;
}

const std::optional<StencilAttachment>& RenderTarget::GetStencilAttachment()
    const {
  return stencil_;
}

}  // namespace impeller

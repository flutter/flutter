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
    const std::function<bool(const Attachment& attachment)>& iterator) const {
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

PixelFormat RenderTarget::GetRenderTargetPixelFormat() const {
  if (auto texture = GetRenderTargetTexture(); texture != nullptr) {
    return texture->GetTextureDescriptor().format;
  }

  return PixelFormat::kUnknown;
}

size_t RenderTarget::GetMaxColorAttacmentBindIndex() const {
  size_t max = 0;
  for (const auto& color : colors_) {
    max = std::max(color.first, max);
  }
  return max;
}

RenderTarget& RenderTarget::SetColorAttachment(
    const ColorAttachment& attachment,
    size_t index) {
  if (attachment.IsValid()) {
    colors_[index] = attachment;
  }
  return *this;
}

RenderTarget& RenderTarget::SetDepthAttachment(
    std::optional<DepthAttachment> attachment) {
  if (!attachment.has_value()) {
    depth_ = std::nullopt;
  } else if (attachment->IsValid()) {
    depth_ = std::move(attachment);
  }
  return *this;
}

RenderTarget& RenderTarget::SetStencilAttachment(
    std::optional<StencilAttachment> attachment) {
  if (!attachment.has_value()) {
    stencil_ = std::nullopt;
  } else if (attachment->IsValid()) {
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

RenderTarget RenderTarget::CreateOffscreen(
    const Context& context,
    ISize size,
    const std::string& label,
    AttachmentConfig color_attachment_config,
    std::optional<AttachmentConfig> stencil_attachment_config) {
  if (size.IsEmpty()) {
    return {};
  }

  RenderTarget target;
  PixelFormat pixel_format = context.GetCapabilities()->GetDefaultColorFormat();
  TextureDescriptor color_tex0;
  color_tex0.storage_mode = color_attachment_config.storage_mode;
  color_tex0.format = pixel_format;
  color_tex0.size = size;
  color_tex0.usage = static_cast<uint64_t>(TextureUsage::kRenderTarget) |
                     static_cast<uint64_t>(TextureUsage::kShaderRead);

  ColorAttachment color0;
  color0.clear_color = Color::BlackTransparent();
  color0.load_action = color_attachment_config.load_action;
  color0.store_action = color_attachment_config.store_action;
  color0.texture = context.GetResourceAllocator()->CreateTexture(color_tex0);

  if (!color0.texture) {
    return {};
  }
  color0.texture->SetLabel(SPrintF("%s Color Texture", label.c_str()));
  target.SetColorAttachment(color0, 0u);

  if (stencil_attachment_config.has_value()) {
    TextureDescriptor stencil_tex0;
    stencil_tex0.storage_mode = stencil_attachment_config->storage_mode;
    stencil_tex0.format = context.GetCapabilities()->GetDefaultStencilFormat();
    stencil_tex0.size = size;
    stencil_tex0.usage =
        static_cast<TextureUsageMask>(TextureUsage::kRenderTarget);

    StencilAttachment stencil0;
    stencil0.load_action = stencil_attachment_config->load_action;
    stencil0.store_action = stencil_attachment_config->store_action;
    stencil0.clear_stencil = 0u;
    stencil0.texture =
        context.GetResourceAllocator()->CreateTexture(stencil_tex0);

    if (!stencil0.texture) {
      return {};
    }
    stencil0.texture->SetLabel(SPrintF("%s Stencil Texture", label.c_str()));
    target.SetStencilAttachment(std::move(stencil0));
  } else {
    target.SetStencilAttachment(std::nullopt);
  }

  return target;
}

RenderTarget RenderTarget::CreateOffscreenMSAA(
    const Context& context,
    ISize size,
    const std::string& label,
    AttachmentConfigMSAA color_attachment_config,
    std::optional<AttachmentConfig> stencil_attachment_config) {
  if (size.IsEmpty()) {
    return {};
  }

  RenderTarget target;
  PixelFormat pixel_format = context.GetCapabilities()->GetDefaultColorFormat();

  // Create MSAA color texture.

  TextureDescriptor color0_tex_desc;
  color0_tex_desc.storage_mode = color_attachment_config.storage_mode;
  color0_tex_desc.type = TextureType::kTexture2DMultisample;
  color0_tex_desc.sample_count = SampleCount::kCount4;
  color0_tex_desc.format = pixel_format;
  color0_tex_desc.size = size;
  color0_tex_desc.usage = static_cast<uint64_t>(TextureUsage::kRenderTarget);

  auto color0_msaa_tex =
      context.GetResourceAllocator()->CreateTexture(color0_tex_desc);
  if (!color0_msaa_tex) {
    VALIDATION_LOG << "Could not create multisample color texture.";
    return {};
  }
  color0_msaa_tex->SetLabel(
      SPrintF("%s Color Texture (Multisample)", label.c_str()));

  // Create color resolve texture.

  TextureDescriptor color0_resolve_tex_desc;
  color0_resolve_tex_desc.storage_mode =
      color_attachment_config.resolve_storage_mode;
  color0_resolve_tex_desc.format = pixel_format;
  color0_resolve_tex_desc.size = size;
  color0_resolve_tex_desc.usage =
      static_cast<uint64_t>(TextureUsage::kRenderTarget) |
      static_cast<uint64_t>(TextureUsage::kShaderRead);

  auto color0_resolve_tex =
      context.GetResourceAllocator()->CreateTexture(color0_resolve_tex_desc);
  if (!color0_resolve_tex) {
    VALIDATION_LOG << "Could not create color texture.";
    return {};
  }
  color0_resolve_tex->SetLabel(SPrintF("%s Color Texture", label.c_str()));

  // Color attachment.

  ColorAttachment color0;
  color0.clear_color = Color::BlackTransparent();
  color0.load_action = color_attachment_config.load_action;
  color0.store_action = color_attachment_config.store_action;
  color0.texture = color0_msaa_tex;
  color0.resolve_texture = color0_resolve_tex;

  target.SetColorAttachment(color0, 0u);

  // Create MSAA stencil texture.

  if (stencil_attachment_config.has_value()) {
    TextureDescriptor stencil_tex0;
    stencil_tex0.storage_mode = stencil_attachment_config->storage_mode;
    stencil_tex0.type = TextureType::kTexture2DMultisample;
    stencil_tex0.sample_count = SampleCount::kCount4;
    stencil_tex0.format = context.GetCapabilities()->GetDefaultStencilFormat();
    stencil_tex0.size = size;
    stencil_tex0.usage =
        static_cast<TextureUsageMask>(TextureUsage::kRenderTarget);

    StencilAttachment stencil0;
    stencil0.load_action = stencil_attachment_config->load_action;
    stencil0.store_action = stencil_attachment_config->store_action;
    stencil0.clear_stencil = 0u;
    stencil0.texture =
        context.GetResourceAllocator()->CreateTexture(stencil_tex0);

    if (!stencil0.texture) {
      return {};
    }
    stencil0.texture->SetLabel(SPrintF("%s Stencil Texture", label.c_str()));
    target.SetStencilAttachment(std::move(stencil0));
  } else {
    target.SetStencilAttachment(std::nullopt);
  }

  return target;
}

size_t RenderTarget::GetTotalAttachmentCount() const {
  size_t count = 0u;
  for (const auto& [_, color] : colors_) {
    if (color.texture) {
      count++;
    }
    if (color.resolve_texture) {
      count++;
    }
  }
  if (depth_.has_value()) {
    count++;
  }
  if (stencil_.has_value()) {
    count++;
  }
  return count;
}

}  // namespace impeller

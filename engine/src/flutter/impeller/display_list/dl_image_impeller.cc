// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/display_list/dl_image_impeller.h"
#include "impeller/display_list/aiks_context.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/filters/filter_contents.h"

namespace impeller {

sk_sp<DlImageImpeller> DlImageImpeller::Make(std::shared_ptr<Texture> texture,
                                             OwningContext owning_context) {
  if (!texture) {
    return nullptr;
  }
  return sk_make_sp<DlImageImpellerTexture>(std::move(texture), owning_context);
}

sk_sp<DlImageImpeller> DlImageImpeller::MakeFromYUVTextures(
    AiksContext* aiks_context,
    std::shared_ptr<Texture> y_texture,
    std::shared_ptr<Texture> uv_texture,
    YUVColorSpace yuv_color_space) {
  if (!aiks_context || !y_texture || !uv_texture) {
    return nullptr;
  }
  auto yuv_to_rgb_filter_contents = FilterContents::MakeYUVToRGBFilter(
      std::move(y_texture), std::move(uv_texture), yuv_color_space);
  impeller::Entity entity;
  entity.SetBlendMode(impeller::BlendMode::kSrc);

  // Disable the render target cache so that this snapshot's texture will not
  // be reused later by other operations.
  const auto& renderer = aiks_context->GetContentContext();
  renderer.GetRenderTargetCache()->DisableCache();
  fml::ScopedCleanupClosure restore_cache(
      [&] { renderer.GetRenderTargetCache()->EnableCache(); });

  std::optional<Snapshot> snapshot =
      yuv_to_rgb_filter_contents->RenderToSnapshot(
          renderer, entity,
          {.coverage_limit = std::nullopt,
           .sampler_descriptor = std::nullopt,
           .msaa_enabled = true,
           .mip_count = 1,
           .label = "MakeYUVToRGBFilter Snapshot"});
  if (!snapshot.has_value()) {
    return nullptr;
  }
  return impeller::DlImageImpeller::Make(snapshot->texture);
}

std::shared_ptr<Texture> DlImageImpeller::GetCachedTexture(
    const ContentContext& renderer) const {
  auto texture = renderer.GetCachedTexture(this);
  if (texture) {
    return texture;
  }
  texture = GetImpellerTexture(renderer.GetContext());
  renderer.SetCachedTexture(this, texture);
  return texture;
}

DlImageImpellerTexture::DlImageImpellerTexture(std::shared_ptr<Texture> texture,
                                               OwningContext owning_context)
    : texture_(std::move(texture)), owning_context_(owning_context) {}

// |DlImage|
DlImageImpellerTexture::~DlImageImpellerTexture() = default;

// |DlImage|
std::shared_ptr<impeller::Texture> DlImageImpellerTexture::GetImpellerTexture(
    const std::shared_ptr<impeller::Context>& context) const {
  return texture_;
}

// |DlImage|
flutter::DlColorSpace DlImageImpellerTexture::GetColorSpace() const {
  if (!texture_) {
    return flutter::DlColorSpace::kSRGB;
  }
  switch (texture_->GetTextureDescriptor().format) {
    case impeller::PixelFormat::kB10G10R10XR:
    case impeller::PixelFormat::kR16G16B16A16Float:
      return flutter::DlColorSpace::kExtendedSRGB;
    default:
      return flutter::DlColorSpace::kSRGB;
  }
}

// |DlImage|
bool DlImageImpellerTexture::isOpaque() const {
  // Impeller doesn't currently implement opaque alpha types.
  return false;
}

// |DlImage|
bool DlImageImpellerTexture::isUIThreadSafe() const {
  // Impeller textures are always thread-safe
  return true;
}

// |DlImage|
flutter::DlISize DlImageImpellerTexture::GetSize() const {
  // texture |GetSize()| returns a 64-bit size, but we need a 32-bit size,
  // so we need to convert to DlISize (the 32-bit variant) either way.
  return texture_ ? flutter::DlISize(texture_->GetSize()) : flutter::DlISize();
}

// |DlImage|
size_t DlImageImpellerTexture::GetApproximateByteSize() const {
  auto size = sizeof(*this);
  if (texture_) {
    size += texture_->GetTextureDescriptor().GetByteSizeOfBaseMipLevel();
  }
  return size;
}

}  // namespace impeller

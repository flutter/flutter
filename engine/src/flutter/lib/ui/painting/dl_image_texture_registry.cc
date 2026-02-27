#include "flutter/lib/ui/painting/dl_image_texture_registry.h"

namespace flutter {

DlImageTextureRegistry::DlImageTextureRegistry(int64_t texture_id,
                                               int width,
                                               int height)
    : texture_id_(texture_id), size_(DlISize(width, height)) {}

sk_sp<SkImage> DlImageTextureRegistry::skia_image() const {
  auto texture_registry = TextureRegistry::GetCurrent().lock();
  if (!texture_registry) {
    return nullptr;
  }
  auto texture = texture_registry->GetTexture(texture_id_);
  if (!texture) {
    return nullptr;
  }
  Texture::PaintContext ctx;
  ctx.gr_context = TextureRegistry::GetCurrentGrContext();
  auto dl_image =
      texture->GetTextureImage(ctx, DlRect::MakeSize(GetSize()), false);
  return dl_image ? dl_image->skia_image() : nullptr;
}

std::shared_ptr<impeller::Texture> DlImageTextureRegistry::impeller_texture()
    const {
  auto texture_registry = TextureRegistry::GetCurrent().lock();
  if (!texture_registry) {
    return nullptr;
  }
  auto texture = texture_registry->GetTexture(texture_id_);
  if (!texture) {
    return nullptr;
  }
  Texture::PaintContext ctx;
  ctx.aiks_context = TextureRegistry::GetCurrentAiksContext();
  ctx.gr_context = TextureRegistry::GetCurrentGrContext();
  auto dl_image =
      texture->GetTextureImage(ctx, DlRect::MakeSize(GetSize()), false);
  return dl_image ? dl_image->impeller_texture() : nullptr;
}

}  // namespace flutter

#include "flutter/lib/ui/painting/dl_image_texture_registry.h"

namespace flutter {

DlImageTextureRegistry::DlImageTextureRegistry(
    const std::shared_ptr<flutter::TextureRegistry>& registry,
    const std::shared_ptr<impeller::AiksContext>& aiks_context,
    GrDirectContext* gr_context,
    int64_t texture_id,
    int width,
    int height)
    : registry_(registry),
      aiks_context_(aiks_context),
      gr_context_(gr_context),
      texture_id_(texture_id),
      size_(DlISize(width, height)) {}

sk_sp<SkImage> DlImageTextureRegistry::skia_image() const {
  auto registry = registry_.lock();
  if (!registry) {
    return nullptr;
  }
  auto texture = registry->GetTexture(texture_id_);
  if (!texture) {
    return nullptr;
  }
  Texture::PaintContext ctx;
  ctx.gr_context = gr_context_;
  auto dl_image =
      texture->GetTextureImage(ctx, DlRect::MakeSize(GetSize()), false);
  return dl_image ? dl_image->skia_image() : nullptr;
}

std::shared_ptr<impeller::Texture> DlImageTextureRegistry::impeller_texture()
    const {
  auto registry = registry_.lock();
  if (!registry) {
    return nullptr;
  }
  auto texture = registry->GetTexture(texture_id_);
  if (!texture) {
    return nullptr;
  }
  auto aiks_context = aiks_context_.lock();
  if (!aiks_context) {
    return nullptr;
  }
  Texture::PaintContext ctx;
  ctx.aiks_context = aiks_context.get();
  ctx.gr_context = gr_context_;
  auto dl_image =
      texture->GetTextureImage(ctx, DlRect::MakeSize(GetSize()), false);
  return dl_image ? dl_image->impeller_texture() : nullptr;
}

}  // namespace flutter

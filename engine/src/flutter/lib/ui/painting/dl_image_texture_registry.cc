// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/dl_image_texture_registry.h"

namespace flutter {

DlImageTextureRegistry::DlImageTextureRegistry(
    fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate,
    int64_t texture_id,
    int width,
    int height)
    : snapshot_delegate_(std::move(snapshot_delegate)),
      texture_id_(texture_id),
      size_(DlISize(width, height)) {}

sk_sp<SkImage> DlImageTextureRegistry::skia_image() const {
  if (!snapshot_delegate_) {
    return nullptr;
  }
  std::shared_ptr<TextureRegistry> registry =
      snapshot_delegate_->GetTextureRegistry();
  if (!registry) {
    return nullptr;
  }
  std::shared_ptr<Texture> texture = registry->GetTexture(texture_id_);
  if (!texture) {
    return nullptr;
  }
  Texture::PaintContext ctx;
  ctx.gr_context = snapshot_delegate_->GetGrContext();
  sk_sp<DlImage> dl_image =
      texture->GetTextureImage(ctx, DlRect::MakeSize(GetSize()), false);
  return dl_image ? dl_image->skia_image() : nullptr;
}

std::shared_ptr<impeller::Texture> DlImageTextureRegistry::impeller_texture()
    const {
  if (!snapshot_delegate_) {
    return nullptr;
  }
  std::shared_ptr<TextureRegistry> registry =
      snapshot_delegate_->GetTextureRegistry();
  if (!registry) {
    return nullptr;
  }
  std::shared_ptr<Texture> texture = registry->GetTexture(texture_id_);
  if (!texture) {
    return nullptr;
  }
  std::shared_ptr<impeller::AiksContext> aiks_context =
      snapshot_delegate_->GetSnapshotDelegateAiksContext();
  if (!aiks_context) {
    return nullptr;
  }
  Texture::PaintContext ctx;
  ctx.aiks_context = aiks_context.get();
  ctx.gr_context = snapshot_delegate_->GetGrContext();
  sk_sp<DlImage> dl_image =
      texture->GetTextureImage(ctx, DlRect::MakeSize(GetSize()), false);
  return dl_image ? dl_image->impeller_texture() : nullptr;
}

}  // namespace flutter

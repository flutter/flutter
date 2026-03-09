// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/dl_image_texture_registry.h"

#include <utility>

#include "flutter/common/graphics/texture.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/trace_event.h"

namespace flutter {

sk_sp<DlImageTextureRegistry> DlImageTextureRegistry::Make(
    fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate,
    fml::RefPtr<fml::TaskRunner> raster_task_runner,
    int64_t texture_id,
    int width,
    int height) {
  return sk_sp<DlImageTextureRegistry>(
      new DlImageTextureRegistry(DlImageTextureRegistry::TextureWrapper::Make(
          std::move(snapshot_delegate), std::move(raster_task_runner),
          texture_id, DlISize(width, height))));
}

DlImageTextureRegistry::DlImageTextureRegistry(
    std::shared_ptr<TextureWrapper> wrapper)
    : wrapper_(std::move(wrapper)) {}

sk_sp<SkImage> DlImageTextureRegistry::skia_image() const {
  FML_DCHECK(false) << "DlImageTextureRegistry is not supported on Skia.";
  return nullptr;
}

std::shared_ptr<impeller::Texture> DlImageTextureRegistry::impeller_texture()
    const {
  if (!wrapper_) {
    return nullptr;
  }
  return wrapper_->texture();
}

bool DlImageTextureRegistry::isTextureBacked() const {
  return true;
}

DlISize DlImageTextureRegistry::GetSize() const {
  return wrapper_ ? wrapper_->size() : DlISize();
}

size_t DlImageTextureRegistry::GetApproximateByteSize() const {
  auto size = sizeof(DlImageTextureRegistry);
  if (wrapper_) {
    if (wrapper_->texture()) {
      size += wrapper_->texture()
                  ->GetTextureDescriptor()
                  .GetByteSizeOfBaseMipLevel();
    } else {
      size += wrapper_->size().Area() * 4;
    }
  }
  return size;
}

std::optional<std::string> DlImageTextureRegistry::get_error() const {
  return wrapper_ ? wrapper_->get_error() : std::nullopt;
}

std::shared_ptr<DlImageTextureRegistry::TextureWrapper>
DlImageTextureRegistry::TextureWrapper::Make(
    fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate,
    fml::RefPtr<fml::TaskRunner> raster_task_runner,
    int64_t texture_id,
    const DlISize& size) {
  auto wrapper = std::shared_ptr<TextureWrapper>(
      new TextureWrapper(std::move(snapshot_delegate),
                         std::move(raster_task_runner), texture_id, size));
  wrapper->SnapshotTexture();
  return wrapper;
}

DlImageTextureRegistry::TextureWrapper::TextureWrapper(
    fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate,
    fml::RefPtr<fml::TaskRunner> raster_task_runner,
    int64_t texture_id,
    const DlISize& size)
    : snapshot_delegate_(std::move(snapshot_delegate)),
      raster_task_runner_(std::move(raster_task_runner)),
      texture_id_(texture_id),
      size_(size) {}

bool DlImageTextureRegistry::TextureWrapper::isTextureBacked() const {
  std::shared_ptr<impeller::Texture> tex = std::atomic_load(&texture_);
  return tex && tex->IsValid();
}

void DlImageTextureRegistry::TextureWrapper::SnapshotTexture() {
  fml::TaskRunner::RunNowOrPostTask(
      raster_task_runner_,
      fml::MakeCopyable([weak_this = weak_from_this()]() mutable {
        TRACE_EVENT0("flutter", "SnapshotTexture (impeller)");
        auto wrapper = weak_this.lock();
        if (!wrapper) {
          return;
        }
        FML_DCHECK(!wrapper->texture_) << "should only execute once.";
        auto snapshot_delegate = wrapper->snapshot_delegate_;
        if (!snapshot_delegate) {
          return;
        }

        std::shared_ptr<TextureRegistry> registry =
            snapshot_delegate->GetTextureRegistry();
        if (!registry) {
          std::scoped_lock lock(wrapper->error_mutex_);
          wrapper->error_ = "Texture registry is missing.";
          return;
        }

        std::shared_ptr<Texture> texture =
            registry->GetTexture(wrapper->texture_id_);
        if (!texture) {
          std::scoped_lock lock(wrapper->error_mutex_);
          wrapper->error_ = "Texture not found.";
          return;
        }

        std::shared_ptr<impeller::AiksContext> aiks_context =
            snapshot_delegate->GetSnapshotDelegateAiksContext();
        if (!aiks_context) {
          std::scoped_lock lock(wrapper->error_mutex_);
          wrapper->error_ = "Aiks context is missing.";
          return;
        }

        Texture::PaintContext ctx;
        ctx.aiks_context = aiks_context.get();
        ctx.gr_context = snapshot_delegate->GetGrContext();
        sk_sp<DlImage> dl_image = texture->GetTextureImage(
            ctx, DlRect::MakeSize(wrapper->size_), false);
        if (!dl_image) {
          std::scoped_lock lock(wrapper->error_mutex_);
          wrapper->error_ = "Failed to create snapshot.";
          return;
        }

        std::atomic_store(&wrapper->texture_, dl_image->impeller_texture());
      }));
}

std::optional<std::string> DlImageTextureRegistry::TextureWrapper::get_error()
    const {
  std::scoped_lock lock(error_mutex_);
  return error_;
}

std::shared_ptr<impeller::Texture>
DlImageTextureRegistry::TextureWrapper::texture() const {
  return std::atomic_load(&texture_);
}

}  // namespace flutter

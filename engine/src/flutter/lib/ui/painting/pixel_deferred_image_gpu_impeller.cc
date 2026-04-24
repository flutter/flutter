// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/pixel_deferred_image_gpu_impeller.h"

#include "flutter/fml/make_copyable.h"
#include "flutter/fml/trace_event.h"

namespace flutter {

sk_sp<PixelDeferredImageGPUImpeller> PixelDeferredImageGPUImpeller::Make(
    sk_sp<SkImage> image,
    fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate,
    fml::RefPtr<fml::TaskRunner> raster_task_runner) {
  return sk_sp<PixelDeferredImageGPUImpeller>(new PixelDeferredImageGPUImpeller(
      PixelDeferredImageGPUImpeller::ImageWrapper::Make(
          std::move(image), std::move(snapshot_delegate),
          std::move(raster_task_runner))));
}

PixelDeferredImageGPUImpeller::PixelDeferredImageGPUImpeller(
    std::shared_ptr<ImageWrapper> wrapper)
    : wrapper_(std::move(wrapper)) {}

PixelDeferredImageGPUImpeller::~PixelDeferredImageGPUImpeller() = default;

std::shared_ptr<impeller::Texture>
PixelDeferredImageGPUImpeller::GetImpellerTexture(
    const std::shared_ptr<impeller::Context>& context) const {
  if (!wrapper_) {
    return nullptr;
  }
  return wrapper_->texture();
}

bool PixelDeferredImageGPUImpeller::isOpaque() const {
  return false;
}

bool PixelDeferredImageGPUImpeller::isUIThreadSafe() const {
  return true;
}

DlISize PixelDeferredImageGPUImpeller::GetSize() const {
  return wrapper_ ? wrapper_->size() : DlISize();
}

size_t PixelDeferredImageGPUImpeller::GetApproximateByteSize() const {
  auto size = sizeof(PixelDeferredImageGPUImpeller);
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

flutter::DlColorSpace PixelDeferredImageGPUImpeller::GetColorSpace() const {
  if (!wrapper_) {
    return flutter::DlColorSpace::kSRGB;
  }
  std::shared_ptr<impeller::Texture> texture = wrapper_->texture();
  if (!texture) {
    return flutter::DlColorSpace::kSRGB;
  }
  switch (texture->GetTextureDescriptor().format) {
    case impeller::PixelFormat::kB10G10R10XR:
    case impeller::PixelFormat::kR16G16B16A16Float:
      return flutter::DlColorSpace::kExtendedSRGB;
    default:
      return flutter::DlColorSpace::kSRGB;
  }
}

std::optional<std::string> PixelDeferredImageGPUImpeller::get_error() const {
  return wrapper_ ? wrapper_->get_error() : std::nullopt;
}

std::shared_ptr<PixelDeferredImageGPUImpeller::ImageWrapper>
PixelDeferredImageGPUImpeller::ImageWrapper::Make(
    sk_sp<SkImage> image,
    fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate,
    fml::RefPtr<fml::TaskRunner> raster_task_runner) {
  auto wrapper = std::shared_ptr<ImageWrapper>(new ImageWrapper(
      image, std::move(snapshot_delegate), std::move(raster_task_runner)));
  wrapper->SnapshotImage(std::move(image));
  return wrapper;
}

PixelDeferredImageGPUImpeller::ImageWrapper::ImageWrapper(
    const sk_sp<SkImage>& image,
    fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate,
    fml::RefPtr<fml::TaskRunner> raster_task_runner)
    : size_(DlISize(image->width(), image->height())),
      snapshot_delegate_(std::move(snapshot_delegate)),
      raster_task_runner_(std::move(raster_task_runner)) {}

PixelDeferredImageGPUImpeller::ImageWrapper::~ImageWrapper() = default;

void PixelDeferredImageGPUImpeller::ImageWrapper::SnapshotImage(
    sk_sp<SkImage> image) {
  fml::TaskRunner::RunNowOrPostTask(
      raster_task_runner_,
      fml::MakeCopyable(
          [weak_this = weak_from_this(), image = std::move(image)]() mutable {
            TRACE_EVENT0("flutter", "SnapshotImage (impeller)");
            auto wrapper = weak_this.lock();
            if (!wrapper) {
              return;
            }
            FML_DCHECK(!wrapper->texture_) << "should only execute once.";
            auto snapshot_delegate = wrapper->snapshot_delegate_;
            if (!snapshot_delegate) {
              return;
            }

            // Use MakeImpellerTextureImage directly.
            auto snapshot_texture = snapshot_delegate->MakeImpellerTextureImage(
                image, SnapshotPixelFormat::kDontCare);
            if (!snapshot_texture) {
              std::scoped_lock lock(wrapper->error_mutex_);
              wrapper->error_ = "Failed to create snapshot.";
              return;
            }
            wrapper->texture_ = snapshot_texture;
          }));
}

std::optional<std::string>
PixelDeferredImageGPUImpeller::ImageWrapper::get_error() const {
  std::scoped_lock lock(error_mutex_);
  return error_;
}

}  // namespace flutter

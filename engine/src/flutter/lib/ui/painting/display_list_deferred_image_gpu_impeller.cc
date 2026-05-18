// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/display_list_deferred_image_gpu_impeller.h"

#include <utility>
#include <variant>

#include "flutter/fml/make_copyable.h"

// Disable a warning on Windows about use of deprecated atomic operations
// on std::shared_ptr.  These functions are used because libcxx does not
// yet support std::atomic<std::shared_ptr>.
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

namespace flutter {

sk_sp<DlDeferredImageGPUImpeller> DlDeferredImageGPUImpeller::Make(
    std::unique_ptr<LayerTree> layer_tree,
    fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate,
    fml::RefPtr<fml::TaskRunner> raster_task_runner) {
  return sk_sp<DlDeferredImageGPUImpeller>(new DlDeferredImageGPUImpeller(
      DlDeferredImageGPUImpeller::ImageWrapper::Make(
          std::move(layer_tree), std::move(snapshot_delegate),
          std::move(raster_task_runner))));
}

sk_sp<DlDeferredImageGPUImpeller> DlDeferredImageGPUImpeller::Make(
    sk_sp<DisplayList> display_list,
    const DlISize& size,
    SnapshotPixelFormat pixel_format,
    fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate,
    fml::RefPtr<fml::TaskRunner> raster_task_runner) {
  return sk_sp<DlDeferredImageGPUImpeller>(new DlDeferredImageGPUImpeller(
      DlDeferredImageGPUImpeller::ImageWrapper::Make(
          std::move(display_list), size, pixel_format,
          std::move(snapshot_delegate), std::move(raster_task_runner))));
}

DlDeferredImageGPUImpeller::DlDeferredImageGPUImpeller(
    std::shared_ptr<ImageWrapper> wrapper)
    : wrapper_(std::move(wrapper)) {}

// |DlImage|
DlDeferredImageGPUImpeller::~DlDeferredImageGPUImpeller() = default;

// |DlImage|
std::shared_ptr<impeller::Texture>
DlDeferredImageGPUImpeller::GetImpellerTexture(
    const std::shared_ptr<impeller::Context>& context) const {
  if (!wrapper_) {
    return nullptr;
  }
  return wrapper_->texture();
}

// |DlImage|
flutter::DlColorSpace DlDeferredImageGPUImpeller::GetColorSpace() const {
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

// |DlImage|
bool DlDeferredImageGPUImpeller::isOpaque() const {
  // Impeller doesn't currently implement opaque alpha types.
  return false;
}

// |DlImage|
bool DlDeferredImageGPUImpeller::isUIThreadSafe() const {
  return true;
}

// |DlImage|
DlISize DlDeferredImageGPUImpeller::GetSize() const {
  return wrapper_ ? wrapper_->size() : DlISize();
}

// |DlImage|
size_t DlDeferredImageGPUImpeller::GetApproximateByteSize() const {
  auto size = sizeof(DlDeferredImageGPUImpeller);
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

std::shared_ptr<DlDeferredImageGPUImpeller::ImageWrapper>
DlDeferredImageGPUImpeller::ImageWrapper::Make(
    sk_sp<DisplayList> display_list,
    const DlISize& size,
    SnapshotPixelFormat pixel_format,
    fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate,
    fml::RefPtr<fml::TaskRunner> raster_task_runner) {
  auto wrapper = std::shared_ptr<ImageWrapper>(
      new ImageWrapper(size, pixel_format, std::move(snapshot_delegate),
                       std::move(raster_task_runner)));
  wrapper->SnapshotDisplayList(std::move(display_list));
  return wrapper;
}

std::shared_ptr<DlDeferredImageGPUImpeller::ImageWrapper>
DlDeferredImageGPUImpeller::ImageWrapper::Make(
    std::unique_ptr<LayerTree> layer_tree,
    fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate,
    fml::RefPtr<fml::TaskRunner> raster_task_runner) {
  auto wrapper = std::shared_ptr<ImageWrapper>(new ImageWrapper(
      layer_tree->frame_size(), SnapshotPixelFormat::kDontCare,
      std::move(snapshot_delegate), std::move(raster_task_runner)));
  wrapper->SnapshotDisplayList(std::move(layer_tree));
  return wrapper;
}

DlDeferredImageGPUImpeller::ImageWrapper::ImageWrapper(
    const DlISize& size,
    SnapshotPixelFormat pixel_format,
    fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate,
    fml::RefPtr<fml::TaskRunner> raster_task_runner)
    : size_(size),
      pixel_format_(pixel_format),
      snapshot_delegate_(std::move(snapshot_delegate)),
      raster_task_runner_(std::move(raster_task_runner)) {}

DlDeferredImageGPUImpeller::ImageWrapper::~ImageWrapper() = default;

void DlDeferredImageGPUImpeller::ImageWrapper::OnGrContextCreated() {}

void DlDeferredImageGPUImpeller::ImageWrapper::OnGrContextDestroyed() {}

std::shared_ptr<impeller::Texture>
DlDeferredImageGPUImpeller::ImageWrapper::texture() const {
  return std::atomic_load(&texture_);
}

void DlDeferredImageGPUImpeller::ImageWrapper::SnapshotDisplayList(
    std::variant<sk_sp<DisplayList>, std::unique_ptr<LayerTree>> content) {
  fml::TaskRunner::RunNowOrPostTask(
      raster_task_runner_,
      fml::MakeCopyable([weak_this = weak_from_this(),
                         content = std::move(content)]() mutable {
        TRACE_EVENT0("flutter", "SnapshotDisplayList (impeller)");
        auto wrapper = weak_this.lock();
        if (!wrapper) {
          return;
        }
        auto snapshot_delegate = wrapper->snapshot_delegate_;
        if (!snapshot_delegate) {
          return;
        }

        sk_sp<DisplayList> display_list;

        if (std::holds_alternative<sk_sp<DisplayList>>(content)) {
          display_list = std::get<sk_sp<DisplayList>>(std::move(content));
        } else if (std::holds_alternative<std::unique_ptr<LayerTree>>(
                       content)) {
          std::unique_ptr<LayerTree> layer_tree =
              std::get<std::unique_ptr<LayerTree>>(std::move(content));
          display_list = layer_tree->Flatten(
              DlRect::MakeWH(wrapper->size_.width, wrapper->size_.height),
              snapshot_delegate->GetTextureRegistry());
        }

        auto texture = snapshot_delegate->MakeImpellerSnapshotSync(
            display_list, wrapper->size_, wrapper->pixel_format_);
        if (!texture) {
          std::scoped_lock lock(wrapper->error_mutex_);
          wrapper->error_ = "Failed to create snapshot.";
          return;
        }
        std::atomic_store(&wrapper->texture_, texture);
      }));
}

std::optional<std::string>
DlDeferredImageGPUImpeller::ImageWrapper::get_error() {
  std::scoped_lock lock(error_mutex_);
  return error_;
}

}  // namespace flutter

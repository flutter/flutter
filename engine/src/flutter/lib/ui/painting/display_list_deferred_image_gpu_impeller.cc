// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/display_list_deferred_image_gpu_impeller.h"

#include <utility>
#include <variant>

#include "flutter/fml/make_copyable.h"

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
    fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate,
    fml::RefPtr<fml::TaskRunner> raster_task_runner) {
  return sk_sp<DlDeferredImageGPUImpeller>(new DlDeferredImageGPUImpeller(
      DlDeferredImageGPUImpeller::ImageWrapper::Make(
          std::move(display_list), size, std::move(snapshot_delegate),
          std::move(raster_task_runner))));
}

DlDeferredImageGPUImpeller::DlDeferredImageGPUImpeller(
    std::shared_ptr<ImageWrapper> wrapper)
    : wrapper_(std::move(wrapper)) {}

// |DlImage|
DlDeferredImageGPUImpeller::~DlDeferredImageGPUImpeller() = default;

// |DlImage|
sk_sp<SkImage> DlDeferredImageGPUImpeller::skia_image() const {
  return nullptr;
};

// |DlImage|
std::shared_ptr<impeller::Texture>
DlDeferredImageGPUImpeller::impeller_texture() const {
  if (!wrapper_) {
    return nullptr;
  }
  return wrapper_->texture();
}

// |DlImage|
bool DlDeferredImageGPUImpeller::isOpaque() const {
  // Impeller doesn't currently implement opaque alpha types.
  return false;
}

// |DlImage|
bool DlDeferredImageGPUImpeller::isTextureBacked() const {
  return wrapper_ && wrapper_->isTextureBacked();
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
    fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate,
    fml::RefPtr<fml::TaskRunner> raster_task_runner) {
  auto wrapper = std::shared_ptr<ImageWrapper>(new ImageWrapper(
      size, std::move(snapshot_delegate), std::move(raster_task_runner)));
  wrapper->SnapshotDisplayList(std::move(display_list));
  return wrapper;
}

std::shared_ptr<DlDeferredImageGPUImpeller::ImageWrapper>
DlDeferredImageGPUImpeller::ImageWrapper::Make(
    std::unique_ptr<LayerTree> layer_tree,
    fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate,
    fml::RefPtr<fml::TaskRunner> raster_task_runner) {
  auto wrapper = std::shared_ptr<ImageWrapper>(
      new ImageWrapper(layer_tree->frame_size(), std::move(snapshot_delegate),
                       std::move(raster_task_runner)));
  wrapper->SnapshotDisplayList(std::move(layer_tree));
  return wrapper;
}

DlDeferredImageGPUImpeller::ImageWrapper::ImageWrapper(
    const DlISize& size,
    fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate,
    fml::RefPtr<fml::TaskRunner> raster_task_runner)
    : size_(size),
      snapshot_delegate_(std::move(snapshot_delegate)),
      raster_task_runner_(std::move(raster_task_runner)) {}

DlDeferredImageGPUImpeller::ImageWrapper::~ImageWrapper() = default;

void DlDeferredImageGPUImpeller::ImageWrapper::OnGrContextCreated() {}

void DlDeferredImageGPUImpeller::ImageWrapper::OnGrContextDestroyed() {}

bool DlDeferredImageGPUImpeller::ImageWrapper::isTextureBacked() const {
  return texture_ && texture_->IsValid();
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

        auto snapshot = snapshot_delegate->MakeRasterSnapshotSync(
            display_list, wrapper->size_);
        if (!snapshot) {
          std::scoped_lock lock(wrapper->error_mutex_);
          wrapper->error_ = "Failed to create snapshot.";
          return;
        }
        wrapper->texture_ = snapshot->impeller_texture();
      }));
}

std::optional<std::string>
DlDeferredImageGPUImpeller::ImageWrapper::get_error() {
  std::scoped_lock lock(error_mutex_);
  return error_;
}

}  // namespace flutter

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/display_list_deferred_image_gpu.h"

#include "display_list_deferred_image_gpu.h"
#include "third_party/skia/include/core/SkColorSpace.h"

namespace flutter {

sk_sp<DlDeferredImageGPU> DlDeferredImageGPU::Make(
    const SkImageInfo& image_info,
    sk_sp<DisplayList> display_list,
    fml::WeakPtr<SnapshotDelegate> snapshot_delegate,
    fml::RefPtr<fml::TaskRunner> raster_task_runner,
    fml::RefPtr<SkiaUnrefQueue> unref_queue) {
  return sk_sp<DlDeferredImageGPU>(new DlDeferredImageGPU(
      ImageWrapper::Make(image_info, std::move(display_list),
                         std::move(snapshot_delegate), raster_task_runner,
                         std::move(unref_queue)),
      raster_task_runner));
}

DlDeferredImageGPU::DlDeferredImageGPU(
    std::shared_ptr<ImageWrapper> image_wrapper,
    fml::RefPtr<fml::TaskRunner> raster_task_runner)
    : image_wrapper_(std::move(image_wrapper)),
      raster_task_runner_(std::move(raster_task_runner)) {}

// |DlImage|
DlDeferredImageGPU::~DlDeferredImageGPU() {
  fml::TaskRunner::RunNowOrPostTask(
      raster_task_runner_, [image_wrapper = std::move(image_wrapper_)]() {
        if (!image_wrapper) {
          return;
        }
        image_wrapper->Unregister();
        image_wrapper->DeleteTexture();
      });
}

// |DlImage|
sk_sp<SkImage> DlDeferredImageGPU::skia_image() const {
  return image_wrapper_ ? image_wrapper_->CreateSkiaImage() : nullptr;
};

// |DlImage|
std::shared_ptr<impeller::Texture> DlDeferredImageGPU::impeller_texture()
    const {
  return nullptr;
}

// |DlImage|
bool DlDeferredImageGPU::isTextureBacked() const {
  return image_wrapper_ ? image_wrapper_->isTextureBacked() : false;
}

// |DlImage|
SkISize DlDeferredImageGPU::dimensions() const {
  return image_wrapper_ ? image_wrapper_->image_info().dimensions()
                        : SkISize::MakeEmpty();
}

// |DlImage|
size_t DlDeferredImageGPU::GetApproximateByteSize() const {
  return sizeof(this) + (image_wrapper_
                             ? image_wrapper_->image_info().computeMinByteSize()
                             : 0);
}

std::optional<std::string> DlDeferredImageGPU::get_error() const {
  return image_wrapper_ ? image_wrapper_->get_error() : std::nullopt;
}

std::shared_ptr<DlDeferredImageGPU::ImageWrapper>
DlDeferredImageGPU::ImageWrapper::Make(
    const SkImageInfo& image_info,
    sk_sp<DisplayList> display_list,
    fml::WeakPtr<SnapshotDelegate> snapshot_delegate,
    fml::RefPtr<fml::TaskRunner> raster_task_runner,
    fml::RefPtr<SkiaUnrefQueue> unref_queue) {
  auto wrapper = std::shared_ptr<ImageWrapper>(new ImageWrapper(
      image_info, std::move(display_list), std::move(snapshot_delegate),
      std::move(raster_task_runner), std::move(unref_queue)));
  wrapper->SnapshotDisplayList();
  return wrapper;
}

DlDeferredImageGPU::ImageWrapper::ImageWrapper(
    const SkImageInfo& image_info,
    sk_sp<DisplayList> display_list,
    fml::WeakPtr<SnapshotDelegate> snapshot_delegate,
    fml::RefPtr<fml::TaskRunner> raster_task_runner,
    fml::RefPtr<SkiaUnrefQueue> unref_queue)
    : image_info_(image_info),
      display_list_(std::move(display_list)),
      snapshot_delegate_(std::move(snapshot_delegate)),
      raster_task_runner_(std::move(raster_task_runner)),
      unref_queue_(std::move(unref_queue)) {}

void DlDeferredImageGPU::ImageWrapper::OnGrContextCreated() {
  FML_DCHECK(raster_task_runner_->RunsTasksOnCurrentThread());
  SnapshotDisplayList();
}

void DlDeferredImageGPU::ImageWrapper::OnGrContextDestroyed() {
  FML_DCHECK(raster_task_runner_->RunsTasksOnCurrentThread());

  DeleteTexture();
}

sk_sp<SkImage> DlDeferredImageGPU::ImageWrapper::CreateSkiaImage() const {
  FML_DCHECK(raster_task_runner_->RunsTasksOnCurrentThread());

  if (texture_.isValid() && context_) {
    return SkImage::MakeFromTexture(
        context_.get(), texture_, kTopLeft_GrSurfaceOrigin,
        image_info_.colorType(), image_info_.alphaType(),
        image_info_.refColorSpace());
  }
  return image_;
}

bool DlDeferredImageGPU::ImageWrapper::isTextureBacked() const {
  return texture_.isValid();
}

void DlDeferredImageGPU::ImageWrapper::SnapshotDisplayList() {
  fml::TaskRunner::RunNowOrPostTask(
      raster_task_runner_, [weak_this = weak_from_this()]() {
        auto wrapper = weak_this.lock();
        if (!wrapper) {
          return;
        }
        auto snapshot_delegate = wrapper->snapshot_delegate_;
        if (!snapshot_delegate) {
          return;
        }
        auto result = snapshot_delegate->MakeGpuImage(wrapper->display_list_,
                                                      wrapper->image_info_);
        if (result->texture.isValid()) {
          wrapper->texture_ = result->texture;
          wrapper->context_ = std::move(result->context);
          wrapper->texture_registry_ =
              wrapper->snapshot_delegate_->GetTextureRegistry();
          wrapper->texture_registry_->RegisterContextListener(
              reinterpret_cast<uintptr_t>(wrapper.get()), weak_this);
        } else if (result->image) {
          wrapper->image_ = std::move(result->image);
        } else {
          std::scoped_lock lock(wrapper->error_mutex_);
          wrapper->error_ = std::move(result->error);
        }
      });
}

std::optional<std::string> DlDeferredImageGPU::ImageWrapper::get_error() {
  std::scoped_lock lock(error_mutex_);
  return error_;
}

void DlDeferredImageGPU::ImageWrapper::Unregister() {
  if (texture_registry_) {
    texture_registry_->UnregisterContextListener(
        reinterpret_cast<uintptr_t>(this));
  }
}

void DlDeferredImageGPU::ImageWrapper::DeleteTexture() {
  if (texture_.isValid()) {
    unref_queue_->DeleteTexture(std::move(texture_));
    texture_ = GrBackendTexture();
  }
  image_.reset();
  context_.reset();
}

}  // namespace flutter

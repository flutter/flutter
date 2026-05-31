// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/surface.h"

#include <cstdint>

#include "flutter/lib/gpu/formats.h"
#include "flutter/lib/ui/painting/image.h"
#include "fml/logging.h"
#include "impeller/core/allocator.h"
#include "tonic/converter/dart_converter.h"

#if IMPELLER_SUPPORTS_RENDERING
#include "impeller/display_list/dl_image_impeller.h"  // nogncheck
#endif

namespace flutter {
namespace gpu {

IMPLEMENT_WRAPPERTYPEINFO(flutter_gpu, Surface);

namespace {

constexpr int64_t kMaxInternalTextureReferences = 3;

}  // namespace

Surface::TextureRecord::TextureRecord(
    std::shared_ptr<impeller::Texture> texture,
    sk_sp<DlImage> image,
    impeller::ISize size,
    impeller::PixelFormat format)
    : texture(std::move(texture)),
      image(std::move(image)),
      size(size),
      format(format) {}

Surface::Surface(std::shared_ptr<impeller::Context> context,
                 impeller::ISize size,
                 impeller::PixelFormat format)
    : context_(std::move(context)), size_(size), format_(format) {}

Surface::~Surface() = default;

std::shared_ptr<Surface::TextureRecord> Surface::CreateTextureRecord() const {
#if !IMPELLER_SUPPORTS_RENDERING
  FML_LOG(ERROR) << "Flutter GPU surfaces require Impeller rendering support.";
  return nullptr;
#else
  impeller::TextureDescriptor desc;
  desc.storage_mode = impeller::StorageMode::kDevicePrivate;
  desc.size = size_;
  desc.format = format_;
  desc.sample_count = impeller::SampleCount::kCount1;
  desc.type = impeller::TextureType::kTexture2D;
  desc.mip_count = 1;
  desc.usage = {};
  desc.usage |= impeller::TextureUsage::kRenderTarget;
  desc.usage |= impeller::TextureUsage::kShaderRead;

  auto texture = context_->GetResourceAllocator()->CreateTexture(desc, true);
  if (!texture) {
    FML_LOG(ERROR) << "Failed to create Flutter GPU surface texture.";
    return nullptr;
  }
  texture->SetCoordinateSystem(
      impeller::TextureCoordinateSystem::kRenderToTexture);

  auto image = impeller::DlImageImpeller::Make(texture);
  if (!image) {
    FML_LOG(ERROR) << "Failed to create Flutter GPU surface image.";
    return nullptr;
  }

  return std::make_shared<TextureRecord>(std::move(texture), std::move(image),
                                         size_, format_);
#endif
}

bool Surface::IsReusable(const std::shared_ptr<TextureRecord>& record,
                         size_t index) const {
  if (current_index_.has_value() && current_index_.value() == index) {
    return false;
  }
  return record && record->size.width == size_.width &&
         record->size.height == size_.height && record->format == format_ &&
         !record->acquired && !record->producer_pending.load() &&
         record->image && record->image->unique() &&
         static_cast<int64_t>(record->texture.use_count()) <=
             kMaxInternalTextureReferences;
}

void Surface::PruneTextureRecords() {
  for (size_t i = 0; i < records_.size(); i++) {
    auto& record = records_[i];
    if (!record) {
      continue;
    }

    const bool is_current =
        current_index_.has_value() && current_index_.value() == i;
    const bool matches_surface = record->size.width == size_.width &&
                                 record->size.height == size_.height &&
                                 record->format == format_;
    // The surface record, its image, and the Dart texture wrapper handed out
    // for the completed frame may all still reference an otherwise
    // unreferenced texture.
    const bool has_external_references =
        !record->image || !record->image->unique() ||
        static_cast<int64_t>(record->texture.use_count()) >
            kMaxInternalTextureReferences;

    if (!is_current && !matches_surface && !record->acquired &&
        !record->producer_pending.load() && !has_external_references) {
      record.reset();
    }
  }

  while (!records_.empty() && !records_.back()) {
    records_.pop_back();
  }
}

int Surface::AcquireNextFrame(Dart_Handle texture_wrapper) {
  std::optional<size_t> available_index;
  size_t index = 0;
  for (const auto& record : records_) {
    if (!record && !available_index.has_value()) {
      available_index = index;
    }
    if (IsReusable(record, index)) {
      record->acquired = true;
      auto texture = fml::MakeRefCounted<Texture>(record->texture);
      texture->AssociateWithDartWrapper(texture_wrapper);
      return static_cast<int>(index);
    }
    index++;
  }

  auto record = CreateTextureRecord();
  if (!record) {
    return -1;
  }
  record->acquired = true;

  if (available_index.has_value()) {
    records_[available_index.value()] = record;
    index = available_index.value();
  } else {
    records_.push_back(record);
    index = records_.size() - 1u;
  }

  auto texture = fml::MakeRefCounted<Texture>(record->texture);
  texture->AssociateWithDartWrapper(texture_wrapper);
  return static_cast<int>(index);
}

Dart_Handle Surface::CreateImage(const sk_sp<DlImage>& image) const {
  if (!image) {
    return Dart_Null();
  }
  auto canvas_image = CanvasImage::Create();
  canvas_image->set_image(image);
  return canvas_image->CreateOuterWrapping();
}

Dart_Handle Surface::PresentFrame(size_t texture_index,
                                  CommandBuffer& command_buffer) {
  if (texture_index >= records_.size()) {
    return tonic::ToDart("SurfaceFrame does not belong to this GpuSurface.");
  }

  auto record = records_[texture_index];
  if (!record || !record->acquired) {
    return tonic::ToDart(
        "SurfaceFrame has already been presented or discarded.");
  }

  record->producer_pending.store(true);
  if (!command_buffer.AddCompletionCallback(
          [record](impeller::CommandBuffer::Status status) {
            (void)status;
            record->producer_pending.store(false);
          })) {
    record->producer_pending.store(false);
    return tonic::ToDart(
        "SurfaceFrame.present must be called before submitting the command "
        "buffer.");
  }

  record->acquired = false;
  current_index_ = texture_index;
  PruneTextureRecords();
  return CreateImage(record->image);
}

void Surface::DiscardFrame(size_t texture_index) {
  if (texture_index >= records_.size()) {
    return;
  }
  auto record = records_[texture_index];
  if (record) {
    record->acquired = false;
  }
}

Dart_Handle Surface::GetCurrentImage() const {
  if (!current_index_.has_value() ||
      current_index_.value() >= records_.size()) {
    return Dart_Null();
  }
  auto record = records_[current_index_.value()];
  if (!record) {
    return Dart_Null();
  }
  return CreateImage(record->image);
}

std::optional<std::string> Surface::Resize(impeller::ISize size) {
  for (const auto& record : records_) {
    if (record && record->acquired) {
      return "GpuSurface.resize cannot be called while a SurfaceFrame is "
             "acquired.";
    }
  }
  size_ = size;
  PruneTextureRecords();
  return std::nullopt;
}

size_t Surface::GetBackingTextureCount() const {
  size_t count = 0;
  for (const auto& record : records_) {
    if (record) {
      count++;
    }
  }
  return count;
}

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

Dart_Handle InternalFlutterGpu_Surface_Initialize(
    Dart_Handle wrapper,
    flutter::gpu::Context* gpu_context,
    int width,
    int height,
    int format) {
  if (width <= 0 || height <= 0) {
    return tonic::ToDart("GpuSurface dimensions must be greater than zero.");
  }

  auto pixel_format = flutter::gpu::ToImpellerPixelFormat(format);
  if (pixel_format == impeller::PixelFormat::kUnknown) {
    return tonic::ToDart("Unsupported GpuSurface pixel format.");
  }

  auto res = fml::MakeRefCounted<flutter::gpu::Surface>(
      gpu_context->GetContextShared(), impeller::ISize{width, height},
      pixel_format);
  res->AssociateWithDartWrapper(wrapper);
  return Dart_Null();
}

int InternalFlutterGpu_Surface_AcquireNextFrame(flutter::gpu::Surface* wrapper,
                                                Dart_Handle texture_wrapper) {
  return wrapper->AcquireNextFrame(texture_wrapper);
}

Dart_Handle InternalFlutterGpu_Surface_PresentFrame(
    flutter::gpu::Surface* wrapper,
    int texture_index,
    flutter::gpu::CommandBuffer* command_buffer) {
  if (texture_index < 0) {
    return tonic::ToDart("Invalid SurfaceFrame texture index.");
  }
  return wrapper->PresentFrame(static_cast<size_t>(texture_index),
                               *command_buffer);
}

void InternalFlutterGpu_Surface_DiscardFrame(flutter::gpu::Surface* wrapper,
                                             int texture_index) {
  if (texture_index < 0) {
    return;
  }
  wrapper->DiscardFrame(static_cast<size_t>(texture_index));
}

Dart_Handle InternalFlutterGpu_Surface_GetCurrentImage(
    flutter::gpu::Surface* wrapper) {
  return wrapper->GetCurrentImage();
}

Dart_Handle InternalFlutterGpu_Surface_Resize(flutter::gpu::Surface* wrapper,
                                              int width,
                                              int height) {
  if (width <= 0 || height <= 0) {
    return tonic::ToDart("GpuSurface dimensions must be greater than zero.");
  }
  auto error = wrapper->Resize(impeller::ISize{width, height});
  if (error.has_value()) {
    return tonic::ToDart(error.value());
  }
  return Dart_Null();
}

int InternalFlutterGpu_Surface_GetBackingTextureCount(
    flutter::gpu::Surface* wrapper) {
  return static_cast<int>(wrapper->GetBackingTextureCount());
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_encoding_impeller.h"

#include "flutter/lib/ui/painting/image.h"
#include "impeller/core/device_buffer.h"
#include "impeller/core/formats.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/context.h"
#include "third_party/skia/include/core/SkBitmap.h"

namespace flutter {
namespace {

std::optional<SkColorType> ToSkColorType(impeller::PixelFormat format) {
  switch (format) {
    case impeller::PixelFormat::kR8G8B8A8UNormInt:
      return SkColorType::kRGBA_8888_SkColorType;
    case impeller::PixelFormat::kR16G16B16A16Float:
      return SkColorType::kRGBA_F16_SkColorType;
    case impeller::PixelFormat::kB8G8R8A8UNormInt:
      return SkColorType::kBGRA_8888_SkColorType;
    case impeller::PixelFormat::kB10G10R10XR:
      return SkColorType::kBGR_101010x_XR_SkColorType;
    default:
      return std::nullopt;
  }
}

sk_sp<SkImage> ConvertBufferToSkImage(
    const std::shared_ptr<impeller::DeviceBuffer>& buffer,
    SkColorType color_type,
    SkISize dimensions) {
  auto buffer_view = buffer->AsBufferView();

  SkImageInfo image_info = SkImageInfo::Make(dimensions, color_type,
                                             SkAlphaType::kPremul_SkAlphaType);

  SkBitmap bitmap;
  auto func = [](void* addr, void* context) {
    auto buffer =
        static_cast<std::shared_ptr<impeller::DeviceBuffer>*>(context);
    buffer->reset();
    delete buffer;
  };
  auto bytes_per_pixel = image_info.bytesPerPixel();
  bitmap.installPixels(image_info, buffer_view.contents,
                       dimensions.width() * bytes_per_pixel, func,
                       new std::shared_ptr<impeller::DeviceBuffer>(buffer));
  bitmap.setImmutable();

  sk_sp<SkImage> raster_image = SkImage::MakeFromBitmap(bitmap);
  return raster_image;
}

void DoConvertImageToRasterImpeller(
    const sk_sp<DlImage>& dl_image,
    std::function<void(sk_sp<SkImage>)> encode_task,
    const std::shared_ptr<const fml::SyncSwitch>& is_gpu_disabled_sync_switch,
    const std::shared_ptr<impeller::Context>& impeller_context) {
  is_gpu_disabled_sync_switch->Execute(
      fml::SyncSwitch::Handlers()
          .SetIfTrue([&encode_task] { encode_task(nullptr); })
          .SetIfFalse([&dl_image, &encode_task, &impeller_context] {
            ImageEncodingImpeller::ConvertDlImageToSkImage(
                dl_image, std::move(encode_task), impeller_context);
          }));
}

}  // namespace

void ImageEncodingImpeller::ConvertDlImageToSkImage(
    const sk_sp<DlImage>& dl_image,
    std::function<void(sk_sp<SkImage>)> encode_task,
    const std::shared_ptr<impeller::Context>& impeller_context) {
  auto texture = dl_image->impeller_texture();

  if (impeller_context == nullptr) {
    FML_LOG(ERROR) << "Impeller context was null.";
    encode_task(nullptr);
    return;
  }

  if (texture == nullptr) {
    FML_LOG(ERROR) << "Image was null.";
    encode_task(nullptr);
    return;
  }

  auto dimensions = dl_image->dimensions();
  auto color_type = ToSkColorType(texture->GetTextureDescriptor().format);

  if (dimensions.isEmpty()) {
    FML_LOG(ERROR) << "Image dimensions were empty.";
    encode_task(nullptr);
    return;
  }

  if (!color_type.has_value()) {
    FML_LOG(ERROR) << "Failed to get color type from pixel format.";
    encode_task(nullptr);
    return;
  }

  impeller::DeviceBufferDescriptor buffer_desc;
  buffer_desc.storage_mode = impeller::StorageMode::kHostVisible;
  buffer_desc.size =
      texture->GetTextureDescriptor().GetByteSizeOfBaseMipLevel();
  auto buffer =
      impeller_context->GetResourceAllocator()->CreateBuffer(buffer_desc);
  auto command_buffer = impeller_context->CreateCommandBuffer();
  command_buffer->SetLabel("BlitTextureToBuffer Command Buffer");
  auto pass = command_buffer->CreateBlitPass();
  pass->SetLabel("BlitTextureToBuffer Blit Pass");
  pass->AddCopy(texture, buffer);
  pass->EncodeCommands(impeller_context->GetResourceAllocator());
  auto completion = [buffer, color_type = color_type.value(), dimensions,
                     encode_task = std::move(encode_task)](
                        impeller::CommandBuffer::Status status) {
    if (status != impeller::CommandBuffer::Status::kCompleted) {
      encode_task(nullptr);
      return;
    }
    auto sk_image = ConvertBufferToSkImage(buffer, color_type, dimensions);
    encode_task(sk_image);
  };

  if (!command_buffer->SubmitCommands(completion)) {
    FML_LOG(ERROR) << "Failed to submit commands.";
  }
}

void ImageEncodingImpeller::ConvertImageToRaster(
    const sk_sp<DlImage>& dl_image,
    std::function<void(sk_sp<SkImage>)> encode_task,
    const fml::RefPtr<fml::TaskRunner>& raster_task_runner,
    const fml::RefPtr<fml::TaskRunner>& io_task_runner,
    const std::shared_ptr<const fml::SyncSwitch>& is_gpu_disabled_sync_switch,
    const std::shared_ptr<impeller::Context>& impeller_context) {
  auto original_encode_task = std::move(encode_task);
  encode_task = [original_encode_task = std::move(original_encode_task),
                 io_task_runner](sk_sp<SkImage> image) mutable {
    fml::TaskRunner::RunNowOrPostTask(
        io_task_runner,
        [original_encode_task = std::move(original_encode_task),
         image = std::move(image)]() { original_encode_task(image); });
  };

  if (dl_image->owning_context() != DlImage::OwningContext::kRaster) {
    DoConvertImageToRasterImpeller(dl_image, std::move(encode_task),
                                   is_gpu_disabled_sync_switch,
                                   impeller_context);
    return;
  }

  raster_task_runner->PostTask([dl_image, encode_task = std::move(encode_task),
                                io_task_runner, is_gpu_disabled_sync_switch,
                                impeller_context]() mutable {
    DoConvertImageToRasterImpeller(dl_image, std::move(encode_task),
                                   is_gpu_disabled_sync_switch,
                                   impeller_context);
  });
}

int ImageEncodingImpeller::GetColorSpace(
    const std::shared_ptr<impeller::Texture>& texture) {
  const impeller::TextureDescriptor& desc = texture->GetTextureDescriptor();
  switch (desc.format) {
    case impeller::PixelFormat::kB10G10R10XR:  // intentional_fallthrough
    case impeller::PixelFormat::kR16G16B16A16Float:
      return ColorSpace::kExtendedSRGB;
    default:
      return ColorSpace::kSRGB;
  }
}

}  // namespace flutter

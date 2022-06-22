// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_decoder_impeller.h"

#include <memory>

#include "flutter/fml/closure.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/trace_event.h"
#include "flutter/impeller/display_list/display_list_image_impeller.h"
#include "flutter/impeller/renderer/allocator.h"
#include "flutter/impeller/renderer/context.h"
#include "flutter/impeller/renderer/texture.h"
#include "flutter/lib/ui/painting/image_decoder_skia.h"
#include "impeller/base/strings.h"
#include "include/core/SkSize.h"
#include "third_party/skia/include/core/SkPixmap.h"

namespace flutter {

ImageDecoderImpeller::ImageDecoderImpeller(
    TaskRunners runners,
    std::shared_ptr<fml::ConcurrentTaskRunner> concurrent_task_runner,
    fml::WeakPtr<IOManager> io_manager)
    : ImageDecoder(std::move(runners),
                   std::move(concurrent_task_runner),
                   io_manager) {
  std::promise<std::shared_ptr<impeller::Context>> context_promise;
  context_ = context_promise.get_future();
  runners_.GetIOTaskRunner()->PostTask(fml::MakeCopyable(
      [promise = std::move(context_promise), io_manager]() mutable {
        promise.set_value(io_manager ? io_manager->GetImpellerContext()
                                     : nullptr);
      }));
}

ImageDecoderImpeller::~ImageDecoderImpeller() = default;

static SkColorType ChooseCompatibleColorType(SkColorType type) {
  return kRGBA_8888_SkColorType;
}

static SkAlphaType ChooseCompatibleAlphaType(SkAlphaType type) {
  return type;
}

static std::optional<impeller::PixelFormat> ToPixelFormat(SkColorType type) {
  switch (type) {
    case kRGBA_8888_SkColorType:
      return impeller::PixelFormat::kR8G8B8A8UNormInt;
    default:
      return std::nullopt;
  }
  return std::nullopt;
}

std::shared_ptr<SkBitmap> ImageDecoderImpeller::DecompressTexture(
    ImageDescriptor* descriptor,
    SkISize target_size) {
  TRACE_EVENT0("impeller", __FUNCTION__);
  if (!descriptor) {
    FML_DLOG(ERROR) << "Invalid descriptor.";
    return nullptr;
  }

  if (!descriptor->is_compressed()) {
    FML_DLOG(ERROR)
        << "Uncompressed images are not implemented in Impeller yet.";
    return nullptr;
  }

  const SkISize source_size = descriptor->image_info().dimensions();
  auto decode_size = descriptor->get_scaled_dimensions(std::max(
      static_cast<double>(target_size.width()) / source_size.width(),
      static_cast<double>(target_size.height()) / source_size.height()));

  //----------------------------------------------------------------------------
  /// 1. Decode the image into the image generator's closest supported size.
  ///

  const auto base_image_info = descriptor->image_info();
  const auto image_info =
      base_image_info.makeWH(decode_size.width(), decode_size.height())
          .makeColorType(ChooseCompatibleColorType(base_image_info.colorType()))
          .makeAlphaType(
              ChooseCompatibleAlphaType(base_image_info.alphaType()));

  const auto pixel_format = ToPixelFormat(image_info.colorType());
  if (!pixel_format.has_value()) {
    FML_DLOG(ERROR) << "Codec pixel format not supported by Impeller.";
    return nullptr;
  }

  auto bitmap = std::make_shared<SkBitmap>();
  if (!bitmap->tryAllocPixels(image_info)) {
    FML_DLOG(ERROR)
        << "Could not allocate intermediate for image decompression.";
    return nullptr;
  }

  if (!descriptor->get_pixels(bitmap->pixmap())) {
    FML_DLOG(ERROR) << "Could not decompress image.";
    return nullptr;
  }

  if (decode_size == target_size) {
    return bitmap;
  }

  //----------------------------------------------------------------------------
  /// 2. If the decoded image isn't the requested target size, resize it.
  ///

  TRACE_EVENT0("impeller", "DecodeScale");
  const auto scaled_image_info = image_info.makeDimensions(target_size);

  auto scaled_bitmap = std::make_shared<SkBitmap>();
  if (!scaled_bitmap->tryAllocPixels(scaled_image_info)) {
    FML_LOG(ERROR)
        << "Could not allocate scaled bitmap for image decompression.";
    return nullptr;
  }
  if (!bitmap->pixmap().scalePixels(
          scaled_bitmap->pixmap(),
          SkSamplingOptions(SkFilterMode::kLinear, SkMipmapMode::kNone))) {
    FML_LOG(ERROR) << "Could not scale decoded bitmap data.";
  }
  scaled_bitmap->setImmutable();

  return scaled_bitmap;
}

static sk_sp<DlImage> UploadTexture(std::shared_ptr<impeller::Context> context,
                                    std::shared_ptr<SkBitmap> bitmap) {
  TRACE_EVENT0("impeller", __FUNCTION__);
  if (!context || !bitmap) {
    return nullptr;
  }
  const auto image_info = bitmap->info();
  const auto pixel_format = ToPixelFormat(image_info.colorType());
  if (!pixel_format) {
    FML_DLOG(ERROR) << "Pixel format unsupported by Impeller.";
    return nullptr;
  }

  impeller::TextureDescriptor texture_descriptor;
  texture_descriptor.format = pixel_format.value();
  texture_descriptor.size = {image_info.width(), image_info.height()};

  auto texture = context->GetPermanentsAllocator()->CreateTexture(
      impeller::StorageMode::kHostVisible, texture_descriptor);
  if (!texture) {
    FML_DLOG(ERROR) << "Could not create Impeller texture.";
    return nullptr;
  }

  auto mapping = std::make_shared<fml::NonOwnedMapping>(
      reinterpret_cast<const uint8_t*>(bitmap->getAddr(0, 0)),  // data
      texture_descriptor.GetByteSizeOfBaseMipLevel(),           // size
      [bitmap](auto, auto) mutable { bitmap.reset(); }          // proc
  );

  if (!texture->SetContents(mapping)) {
    FML_DLOG(ERROR) << "Could not copy contents into Impeller texture.";
    return nullptr;
  }

  texture->SetLabel(impeller::SPrintF("ui.Image(%p)", texture.get()).c_str());

  return impeller::DlImageImpeller::Make(std::move(texture));
}

// |ImageDecoder|
void ImageDecoderImpeller::Decode(fml::RefPtr<ImageDescriptor> descriptor,
                                  uint32_t target_width,
                                  uint32_t target_height,
                                  const ImageResult& p_result) {
  FML_DCHECK(descriptor);
  FML_DCHECK(p_result);

  // Wrap the result callback so that it can be invoked from any thread.
  auto raw_descriptor = descriptor.get();
  raw_descriptor->AddRef();
  ImageResult result = [p_result,                               //
                        raw_descriptor,                         //
                        ui_runner = runners_.GetUITaskRunner()  //
  ](auto image) {
    ui_runner->PostTask([raw_descriptor, p_result, image]() {
      raw_descriptor->Release();
      p_result(std::move(image));
    });
  };

  concurrent_task_runner_->PostTask(
      [raw_descriptor,                                            //
       context = context_.get(),                                  //
       target_size = SkISize::Make(target_width, target_height),  //
       io_runner = runners_.GetIOTaskRunner(),                    //
       result                                                     //
  ]() {
        // Always decompress on the concurrent runner.
        auto bitmap = DecompressTexture(raw_descriptor, target_size);
        if (!bitmap) {
          result(nullptr);
          return;
        }
        auto upload_texture_and_invoke_result = [result, context, bitmap]() {
          result(UploadTexture(context, bitmap));
        };
        // Depending on whether the context has threading restrictions, stay on
        // the concurrent runner to perform texture upload or move to an IO
        // runner.
        if (context->HasThreadingRestrictions()) {
          io_runner->PostTask(upload_texture_and_invoke_result);
        } else {
          upload_texture_and_invoke_result();
        }
      });
}

}  // namespace flutter

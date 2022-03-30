// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_decoder_impeller.h"

#include "flutter/fml/closure.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/trace_event.h"
#include "flutter/impeller/display_list/display_list_image_impeller.h"
#include "flutter/impeller/renderer/allocator.h"
#include "flutter/impeller/renderer/context.h"
#include "flutter/impeller/renderer/texture.h"
#include "flutter/lib/ui/painting/image_decoder_skia.h"
#include "impeller/base/strings.h"
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

static sk_sp<DlImage> DecompressAndUploadTexture(
    std::shared_ptr<impeller::Context> context,
    ImageDescriptor* descriptor,
    SkISize target_size,
    std::string label) {
  TRACE_EVENT0("flutter", __FUNCTION__);

  if (!context || !descriptor) {
    return nullptr;
  }

  if (!descriptor->is_compressed()) {
    FML_DLOG(ERROR)
        << "Uncompressed images are not implemented in Impeller yet.";
    return nullptr;
  }

  const auto base_image_info = descriptor->image_info();
  const auto image_info =
      base_image_info.makeWH(target_size.width(), target_size.height())
          .makeColorType(ChooseCompatibleColorType(base_image_info.colorType()))
          .makeAlphaType(
              ChooseCompatibleAlphaType(base_image_info.alphaType()));

  const auto pixel_format = ToPixelFormat(image_info.colorType());
  if (!pixel_format.has_value()) {
    FML_DLOG(ERROR) << "Codec pixel format not supported by Impeller.";
    return nullptr;
  }

  SkBitmap bitmap;
  if (!bitmap.tryAllocPixels(image_info)) {
    FML_DLOG(ERROR)
        << "Could not allocate intermediate for image decompression.";
    return nullptr;
  }

  if (!descriptor->get_pixels(bitmap.pixmap())) {
    FML_DLOG(ERROR) << "Could not decompress image.";
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

  if (!texture->SetContents(
          reinterpret_cast<const uint8_t*>(bitmap.getAddr(0, 0)),
          texture_descriptor.GetByteSizeOfBaseMipLevel())) {
    FML_DLOG(ERROR) << "Could not copy contents into Impeller texture.";
    return nullptr;
  }

  texture->SetLabel(label.c_str());

  return impeller::DlImageImpeller::Make(std::move(texture));
}

// |ImageDecoder|
void ImageDecoderImpeller::Decode(fml::RefPtr<ImageDescriptor> descriptor,
                                  uint32_t target_width,
                                  uint32_t target_height,
                                  const ImageResult& result) {
  FML_DCHECK(descriptor);
  FML_DCHECK(result);

  auto raw_descriptor = descriptor.get();
  raw_descriptor->AddRef();
  concurrent_task_runner_->PostTask(
      [raw_descriptor,                                             //
       context = context_.get(),                                   //
       target_size = SkISize::Make(target_width, target_height),   //
       label = impeller::SPrintF("ui.Image %zu", label_count_++),  //
       ui_runner = runners_.GetUITaskRunner(),                     //
       result                                                      //
  ]() {
        auto image = DecompressAndUploadTexture(context,         //
                                                raw_descriptor,  //
                                                target_size,     //
                                                label            //
        );

        ui_runner->PostTask([raw_descriptor, image, result]() {
          raw_descriptor->Release();
          result(image);
        });
      });
}

}  // namespace flutter

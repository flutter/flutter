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
#include "flutter/impeller/renderer/command_buffer.h"
#include "flutter/impeller/renderer/context.h"
#include "flutter/impeller/renderer/texture.h"
#include "flutter/lib/ui/painting/image_decoder_skia.h"
#include "impeller/base/strings.h"
#include "impeller/geometry/size.h"
#include "include/core/SkSize.h"
#include "third_party/skia/include/core/SkMallocPixelRef.h"
#include "third_party/skia/include/core/SkPixmap.h"

namespace flutter {

namespace {
/**
 *  Loads the gamut as a set of three points (triangle).
 */
void LoadGamut(SkPoint abc[3], const skcms_Matrix3x3& xyz) {
  // rx = rX / (rX + rY + rZ)
  // ry = rY / (rX + rY + rZ)
  // gx, gy, bx, and gy are calculated similarly.
  for (int index = 0; index < 3; index++) {
    float sum = xyz.vals[index][0] + xyz.vals[index][1] + xyz.vals[index][2];
    abc[index].fX = xyz.vals[index][0] / sum;
    abc[index].fY = xyz.vals[index][1] / sum;
  }
}

/**
 *  Calculates the area of the triangular gamut.
 */
float CalculateArea(SkPoint abc[3]) {
  const SkPoint& a = abc[0];
  const SkPoint& b = abc[1];
  const SkPoint& c = abc[2];
  return 0.5f * fabsf(a.fX * b.fY + b.fX * c.fY - a.fX * c.fY - c.fX * b.fY -
                      b.fX * a.fY);
}

static constexpr float kSrgbD50GamutArea = 0.084f;

// Source:
// https://source.chromium.org/chromium/_/skia/skia.git/+/393fb1ec80f41d8ad7d104921b6920e69749fda1:src/codec/SkAndroidCodec.cpp;l=67;drc=46572b4d445f41943059d0e377afc6d6748cd5ca;bpv=1;bpt=0
bool IsWideGamut(const SkColorSpace& color_space) {
  skcms_Matrix3x3 xyzd50;
  color_space.toXYZD50(&xyzd50);
  SkPoint rgb[3];
  LoadGamut(rgb, xyzd50);
  return CalculateArea(rgb) > kSrgbD50GamutArea;
}
}  // namespace

ImageDecoderImpeller::ImageDecoderImpeller(
    const TaskRunners& runners,
    std::shared_ptr<fml::ConcurrentTaskRunner> concurrent_task_runner,
    const fml::WeakPtr<IOManager>& io_manager,
    bool supports_wide_gamut)
    : ImageDecoder(runners, std::move(concurrent_task_runner), io_manager),
      supports_wide_gamut_(supports_wide_gamut) {
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
    case kRGBA_F16_SkColorType:
      return impeller::PixelFormat::kR16G16B16A16Float;
    default:
      return std::nullopt;
  }
  return std::nullopt;
}

std::shared_ptr<SkBitmap> ImageDecoderImpeller::DecompressTexture(
    ImageDescriptor* descriptor,
    SkISize target_size,
    impeller::ISize max_texture_size,
    bool supports_wide_gamut) {
  TRACE_EVENT0("impeller", __FUNCTION__);
  if (!descriptor) {
    FML_DLOG(ERROR) << "Invalid descriptor.";
    return nullptr;
  }

  target_size.set(std::min(static_cast<int32_t>(max_texture_size.width),
                           target_size.width()),
                  std::min(static_cast<int32_t>(max_texture_size.height),
                           target_size.height()));

  const SkISize source_size = descriptor->image_info().dimensions();
  auto decode_size = source_size;
  if (descriptor->is_compressed()) {
    decode_size = descriptor->get_scaled_dimensions(std::max(
        static_cast<double>(target_size.width()) / source_size.width(),
        static_cast<double>(target_size.height()) / source_size.height()));
  }

  //----------------------------------------------------------------------------
  /// 1. Decode the image.
  ///

  const auto base_image_info = descriptor->image_info();
  const bool is_wide_gamut =
      supports_wide_gamut ? IsWideGamut(*base_image_info.colorSpace()) : false;
  SkAlphaType alpha_type =
      ChooseCompatibleAlphaType(base_image_info.alphaType());
  SkImageInfo image_info;
  if (is_wide_gamut) {
    // TODO(gaaclarke): Branch on alpha_type so it's 32bpp for opaque images.
    //                  I tried using kBGRA_1010102_SkColorType and
    //                  kBGR_101010x_SkColorType but Skia fails to decode the
    //                  image that way.
    SkColorType color_type = kRGBA_F16_SkColorType;
    image_info =
        base_image_info.makeWH(decode_size.width(), decode_size.height())
            .makeColorType(color_type)
            .makeAlphaType(alpha_type)
            .makeColorSpace(SkColorSpace::MakeSRGB());
  } else {
    image_info =
        base_image_info.makeWH(decode_size.width(), decode_size.height())
            .makeColorType(
                ChooseCompatibleColorType(base_image_info.colorType()))
            .makeAlphaType(alpha_type);
  }

  const auto pixel_format = ToPixelFormat(image_info.colorType());
  if (!pixel_format.has_value()) {
    FML_DLOG(ERROR) << "Codec pixel format not supported by Impeller.";
    return nullptr;
  }

  auto bitmap = std::make_shared<SkBitmap>();
  if (descriptor->is_compressed()) {
    if (!bitmap->tryAllocPixels(image_info)) {
      FML_DLOG(ERROR)
          << "Could not allocate intermediate for image decompression.";
      return nullptr;
    }
    // Decode the image into the image generator's closest supported size.
    if (!descriptor->get_pixels(bitmap->pixmap())) {
      FML_DLOG(ERROR) << "Could not decompress image.";
      return nullptr;
    }
  } else {
    bitmap->setInfo(image_info);
    auto pixel_ref = SkMallocPixelRef::MakeWithData(
        image_info, descriptor->row_bytes(), descriptor->data());
    bitmap->setPixelRef(pixel_ref, 0, 0);
    bitmap->setImmutable();
  }

  if (bitmap->dimensions() == target_size) {
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

sk_sp<DlImage> ImageDecoderImpeller::UploadTexture(
    const std::shared_ptr<impeller::Context>& context,
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
  texture_descriptor.storage_mode = impeller::StorageMode::kHostVisible;
  texture_descriptor.format = pixel_format.value();
  texture_descriptor.size = {image_info.width(), image_info.height()};
  texture_descriptor.mip_count = texture_descriptor.size.MipCount();

  auto texture =
      context->GetResourceAllocator()->CreateTexture(texture_descriptor);
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

  {
    auto command_buffer = context->CreateCommandBuffer();
    if (!command_buffer) {
      FML_DLOG(ERROR)
          << "Could not create command buffer for mipmap generation.";
      return nullptr;
    }
    command_buffer->SetLabel("Mipmap Command Buffer");

    auto blit_pass = command_buffer->CreateBlitPass();
    if (!blit_pass) {
      FML_DLOG(ERROR) << "Could not create blit pass for mipmap generation.";
      return nullptr;
    }
    blit_pass->SetLabel("Mipmap Blit Pass");
    blit_pass->GenerateMipmap(texture);

    blit_pass->EncodeCommands(context->GetResourceAllocator());
    if (!command_buffer->SubmitCommands()) {
      FML_DLOG(ERROR) << "Failed to submit blit pass command buffer.";
      return nullptr;
    }
  }

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
       result,
       supports_wide_gamut = supports_wide_gamut_  //
  ]() {
        FML_CHECK(context) << "No valid impeller context";
        auto max_size_supported =
            context->GetResourceAllocator()->GetMaxTextureSizeSupported();

        // Always decompress on the concurrent runner.
        auto bitmap =
            DecompressTexture(raw_descriptor, target_size, max_size_supported,
                              supports_wide_gamut);
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
        if (context->GetDeviceCapabilities().HasThreadingRestrictions()) {
          io_runner->PostTask(upload_texture_and_invoke_result);
        } else {
          upload_texture_and_invoke_result();
        }
      });
}

}  // namespace flutter

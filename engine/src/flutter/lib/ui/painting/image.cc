// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image.h"

#include "tonic/logging/dart_invoke.h"

#if IMPELLER_SUPPORTS_RENDERING
#include "flutter/lib/ui/painting/image_encoding_impeller.h"
#include "flutter/lib/ui/painting/pixel_deferred_image_gpu_impeller.h"
#endif
#include "flutter/display_list/image/dl_image.h"
#include "flutter/lib/ui/painting/image_encoding.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/tonic/converter/dart_converter.h"

namespace flutter {

typedef CanvasImage Image;

// Since _Image is a private class, we can't use IMPLEMENT_WRAPPERTYPEINFO
static const tonic::DartWrapperInfo kDartWrapperInfoUIImage("ui", "_Image");
const tonic::DartWrapperInfo& Image::dart_wrapper_info_ =
    kDartWrapperInfoUIImage;

CanvasImage::CanvasImage() = default;

CanvasImage::~CanvasImage() = default;

Dart_Handle CanvasImage::CreateOuterWrapping() {
  Dart_Handle ui_lib = Dart_LookupLibrary(tonic::ToDart("dart:ui"));
  return tonic::DartInvokeField(ui_lib, "_wrapImage", {ToDart(this)});
}

Dart_Handle CanvasImage::toByteData(int format, Dart_Handle callback) {
  return EncodeImage(this, format, callback);
}

void CanvasImage::dispose() {
  image_.reset();
  ClearDartWrapper();
}

int CanvasImage::colorSpace() {
  if (image_->skia_image()) {
    return ColorSpace::kSRGB;
  } else if (image_->impeller_texture()) {
#if IMPELLER_SUPPORTS_RENDERING
    return ImageEncodingImpeller::GetColorSpace(image_->impeller_texture());
#endif  // IMPELLER_SUPPORTS_RENDERING
  }
  return ColorSpace::kSRGB;
}

}  // namespace flutter

namespace flutter {

namespace {

int BytesPerPixel(int pixel_format) {
  switch (pixel_format) {
    case 0:  // rgba8888
    case 1:  // bgra8888
    case 3:  // r32Float
      return 4;
    case 2:  // rgbaFloat32
      return 16;
    case 4:  // gray8
      return 1;
    default:
      return 4;
  }
}

SkColorType PixelFormatToSkColorType(int pixel_format) {
  switch (pixel_format) {
    case 0:  // rgba8888
      return kRGBA_8888_SkColorType;
    case 1:  // bgra8888
      return kBGRA_8888_SkColorType;
    case 2:  // rgbaFloat32
      return kRGBA_F32_SkColorType;
    case 3:                         // r32Float
      return kUnknown_SkColorType;  // Not supported for direct SkImage creation
                                    // usually?
    case 4:                         // gray8
      return kGray_8_SkColorType;
    default:
      return kUnknown_SkColorType;
  }
}
}  // namespace

void CanvasImage::decodeImageFromPixelsSync(Dart_Handle pixels_handle,
                                            uint32_t width,
                                            uint32_t height,
                                            int32_t pixel_format,
                                            int32_t row_bytes,
                                            int32_t target_width,
                                            int32_t target_height,
                                            bool allow_upscaling,
                                            int32_t target_pixel_format,
                                            Dart_Handle raw_image_handle) {
  auto* dart_state = UIDartState::Current();
  if (!dart_state) {
    Dart_ThrowException(tonic::ToDart("Dart state is null."));
    return;
  }

  if (!dart_state->IsImpellerEnabled()) {
    Dart_ThrowException(
        tonic::ToDart("decodeImageFromPixelsSync is not implemented on "
                      "Skia."));
    return;
  }

  if (width == 0 || height == 0) {
    Dart_ThrowException(
        tonic::ToDart("Image dimensions must be greater than zero."));
    return;
  }

  if (target_width == 0) {
    target_width = width;
  }
  if (target_height == 0) {
    target_height = height;
  }

  if (target_width != static_cast<int32_t>(width) ||
      target_height != static_cast<int32_t>(height)) {
    Dart_ThrowException(tonic::ToDart(
        "decodeImageFromPixelsSync resizing is not implemented."));
    return;
  }

  if (!allow_upscaling) {
    if (target_width > static_cast<int32_t>(width)) {
      target_width = width;
    }
    if (target_height > static_cast<int32_t>(height)) {
      target_height = height;
    }
  }

  tonic::Uint8List pixels(pixels_handle);
  if (!pixels.data()) {
    Dart_ThrowException(tonic::ToDart("Pixels must not be null."));
    return;
  }

  if (row_bytes == 0) {
    row_bytes = width * BytesPerPixel(pixel_format);
  }

  SkColorType color_type = PixelFormatToSkColorType(pixel_format);
  if (color_type == kUnknown_SkColorType) {
    Dart_ThrowException(tonic::ToDart("Unsupported pixel format."));
    return;
  }

  SkImageInfo image_info =
      SkImageInfo::Make(width, height, color_type, kUnpremul_SkAlphaType);
  if (pixel_format == 2) {  // rgbaFloat32
    image_info = image_info.makeAlphaType(kUnpremul_SkAlphaType);
  } else {
    image_info = image_info.makeAlphaType(kPremul_SkAlphaType);
  }

  auto sk_data = SkData::MakeWithCopy(pixels.data(), pixels.num_elements());
  auto sk_image =
      SkImages::RasterFromData(image_info, std::move(sk_data), row_bytes);
  if (!sk_image) {
    Dart_ThrowException(tonic::ToDart("Failed to create image from pixels."));
    return;
  }

  auto snapshot_delegate = dart_state->GetSnapshotDelegate();
  auto raster_task_runner = dart_state->GetTaskRunners().GetRasterTaskRunner();

  auto result_image = CanvasImage::Create();
  sk_sp<DlImage> deferred_image;

#if IMPELLER_SUPPORTS_RENDERING
  deferred_image = PixelDeferredImageGPUImpeller::Make(
      sk_image, std::move(snapshot_delegate), std::move(raster_task_runner));
#endif  // IMPELLER_SUPPORTS_RENDERING

  result_image->set_image(deferred_image);
  result_image->AssociateWithDartWrapper(raw_image_handle);
}

}  // namespace flutter

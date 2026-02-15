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

int BytesPerPixel(PixelFormat pixel_format) {
  switch (pixel_format) {
    case PixelFormat::kRgba8888:
    case PixelFormat::kBgra8888:
    case PixelFormat::kRFloat32:
      return 4;
    case PixelFormat::kRgbaFloat32:
      return 16;
  }
  return 4;
}

SkColorType PixelFormatToSkColorType(PixelFormat pixel_format) {
  switch (pixel_format) {
    case PixelFormat::kRgba8888:
      return kRGBA_8888_SkColorType;
    case PixelFormat::kBgra8888:
      return kBGRA_8888_SkColorType;
    case PixelFormat::kRgbaFloat32:
      return kRGBA_F32_SkColorType;
    case PixelFormat::kRFloat32:
      return kUnknown_SkColorType;
  }
  return kUnknown_SkColorType;
}

// Returns only static strings.
const char* DoDecodeImageFromPixelsSync(Dart_Handle pixels_handle,
                                        uint32_t width,
                                        uint32_t height,
                                        int32_t pixel_format,
                                        Dart_Handle raw_image_handle) {
  auto* dart_state = UIDartState::Current();
  if (!dart_state) {
    return "Dart state is null.";
  }

  if (!dart_state->IsImpellerEnabled()) {
    return "decodeImageFromPixelsSync is not implemented on Skia.";
  }

  if (width == 0 || height == 0) {
    return "Image dimensions must be greater than zero.";
  }

  if (pixel_format < 0 ||
      pixel_format > static_cast<int32_t>(kLastPixelFormat)) {
    return "Invalid pixel format.";
  }
  PixelFormat format = static_cast<PixelFormat>(pixel_format);

  sk_sp<SkData> sk_data;
  sk_sp<SkImage> sk_image;
  {
    tonic::Uint8List pixels(pixels_handle);
    if (!pixels.data()) {
      return "Pixels must not be null.";
    }

    int32_t row_bytes = width * BytesPerPixel(format);
    SkColorType color_type = PixelFormatToSkColorType(format);
    if (color_type == kUnknown_SkColorType) {
      return "Unsupported pixel format.";
    }

    SkImageInfo image_info =
        SkImageInfo::Make(width, height, color_type, kUnpremul_SkAlphaType);
    if (pixel_format == 2) {  // rgbaFloat32
      image_info = image_info.makeAlphaType(kUnpremul_SkAlphaType);
    } else {
      image_info = image_info.makeAlphaType(kPremul_SkAlphaType);
    }

    sk_data = SkData::MakeWithCopy(pixels.data(), pixels.num_elements());
    sk_image = SkImages::RasterFromData(image_info, sk_data, row_bytes);
    if (!sk_image) {
      return "Failed to create image from pixels.";
    }
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

  return nullptr;
}
}  // namespace

void CanvasImage::decodeImageFromPixelsSync(Dart_Handle pixels_handle,
                                            uint32_t width,
                                            uint32_t height,
                                            int32_t pixel_format,
                                            Dart_Handle raw_image_handle) {
  const char* error = DoDecodeImageFromPixelsSync(
      pixels_handle, width, height, pixel_format, raw_image_handle);
  if (error) {
    Dart_ThrowException(tonic::ToDart(error));
  }
}

}  // namespace flutter

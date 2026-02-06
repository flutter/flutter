// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_descriptor.h"

#include "flutter/fml/build_config.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "flutter/lib/ui/painting/multi_frame_codec.h"
#include "flutter/lib/ui/painting/single_frame_codec.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/logging/dart_invoke.h"

namespace flutter {

IMPLEMENT_WRAPPERTYPEINFO(ui, ImageDescriptor);

ImageDescriptor::ImageInfo ImageDescriptor::CreateImageInfo(
    const SkImageInfo& sk_image_info) {
  PixelFormat format;
  switch (sk_image_info.colorType()) {
    case kUnknown_SkColorType:
      format = kUnknown;
      break;
    case kRGBA_8888_SkColorType:
      format = kRGBA8888;
      break;
    case kBGRA_8888_SkColorType:
      format = kBGRA8888;
      break;
    case kRGBA_F32_SkColorType:
      format = kRGBAFloat32;
      break;
    case kGray_8_SkColorType:
      format = kGray8;
      break;
    default:
      FML_DCHECK(false) << "Unsupported pixel format: "
                        << sk_image_info.colorType();
      format = kRGBA8888;
  }
  return ImageInfo{
      .width = static_cast<uint32_t>(sk_image_info.width()),
      .height = static_cast<uint32_t>(sk_image_info.height()),
      .format = format,
      .alpha_type = sk_image_info.alphaType(),
      .color_space = sk_image_info.refColorSpace(),
  };
}

SkImageInfo ImageDescriptor::ToSkImageInfo(const ImageInfo& image_info) {
  SkColorType color_type = kUnknown_SkColorType;
  switch (image_info.format) {
    case PixelFormat::kUnknown:
      color_type = kUnknown_SkColorType;
      break;
    case PixelFormat::kRGBA8888:
      color_type = kRGBA_8888_SkColorType;
      break;
    case PixelFormat::kBGRA8888:
      color_type = kBGRA_8888_SkColorType;
      break;
    case PixelFormat::kRGBAFloat32:
      color_type = kRGBA_F32_SkColorType;
      break;
    case PixelFormat::kGray8:
      color_type = kGray_8_SkColorType;
      break;
    case PixelFormat::kR32Float:
      FML_DCHECK(false) << "not a supported skia format";
      break;
  }
  return SkImageInfo::Make(image_info.width, image_info.height, color_type,
                           image_info.alpha_type, image_info.color_space);
}

ImageDescriptor::ImageDescriptor(sk_sp<SkData> buffer,
                                 const ImageInfo& image_info,
                                 std::optional<size_t> row_bytes)
    : buffer_(std::move(buffer)),
      image_info_(image_info),
      generator_(nullptr),
      row_bytes_(row_bytes) {}

ImageDescriptor::ImageDescriptor(sk_sp<SkData> buffer,
                                 std::shared_ptr<ImageGenerator> generator)
    : buffer_(std::move(buffer)),
      image_info_(CreateImageInfo(generator->GetInfo())),
      generator_(std::move(generator)),
      row_bytes_(std::nullopt) {}

Dart_Handle ImageDescriptor::initEncoded(Dart_Handle descriptor_handle,
                                         ImmutableBuffer* immutable_buffer,
                                         Dart_Handle callback_handle) {
  if (!Dart_IsClosure(callback_handle)) {
    return tonic::ToDart("Callback must be a function");
  }

  if (!immutable_buffer) {
    return tonic::ToDart("Buffer parameter must not be null");
  }

  // This has to be valid because this method is called from Dart.
  auto dart_state = UIDartState::Current();
  auto registry = dart_state->GetImageGeneratorRegistry();

  if (!registry) {
    return tonic::ToDart(
        "Failed to access the internal image decoder "
        "registry on this isolate. Please file a bug on "
        "https://github.com/flutter/flutter/issues.");
  }

  auto generator =
      registry->CreateCompatibleGenerator(immutable_buffer->data());

  if (!generator) {
    // No compatible image decoder was found.
    return tonic::ToDart("Invalid image data");
  }

  auto descriptor = fml::MakeRefCounted<ImageDescriptor>(
      immutable_buffer->data(), std::move(generator));

  FML_DCHECK(descriptor);

  descriptor->AssociateWithDartWrapper(descriptor_handle);
  tonic::DartInvoke(callback_handle, {Dart_TypeVoid()});

  return Dart_Null();
}

namespace {
// Must be kept in sync with painting.dart.
ImageDescriptor::PixelFormat toImageDescriptorPixelFormat(int val) {
  switch (val) {
    case 0:
      return ImageDescriptor::PixelFormat::kRGBA8888;
    case 1:
      return ImageDescriptor::PixelFormat::kBGRA8888;
    case 2:
      return ImageDescriptor::PixelFormat::kRGBAFloat32;
    case 3:
      return ImageDescriptor::PixelFormat::kR32Float;
    default:
      FML_DCHECK(false) << "unrecognized format";
      return ImageDescriptor::PixelFormat::kRGBA8888;
  }
}
}  // namespace

void ImageDescriptor::initRaw(Dart_Handle descriptor_handle,
                              const fml::RefPtr<ImmutableBuffer>& data,
                              int width,
                              int height,
                              int row_bytes,
                              int pixel_format) {
  ImageDescriptor::PixelFormat image_descriptor_pixel_format =
      toImageDescriptorPixelFormat(pixel_format);
  const ImageInfo image_info = {
      .width = static_cast<uint32_t>(width),
      .height = static_cast<uint32_t>(height),
      .format = image_descriptor_pixel_format,
      .alpha_type = image_descriptor_pixel_format == PixelFormat::kRGBAFloat32
                        ? kUnpremul_SkAlphaType
                        : kPremul_SkAlphaType,
      .color_space = SkColorSpace::MakeSRGB(),
  };

  auto descriptor = fml::MakeRefCounted<ImageDescriptor>(
      data->data(), image_info,
      row_bytes == -1 ? std::nullopt : std::optional<size_t>(row_bytes));
  descriptor->AssociateWithDartWrapper(descriptor_handle);
}

// This should match the order of `TargetPixelFormat` in
// //engine/src/flutter/lib/ui/painting.dart.
ImageDecoder::TargetPixelFormat ToImageDecoderTargetPixelFormat(int32_t value) {
  switch (value) {
    case 0:
      return ImageDecoder::TargetPixelFormat::kDontCare;
    case 1:
      return ImageDecoder::TargetPixelFormat::kR32G32B32A32Float;
    case 2:
      return ImageDecoder::TargetPixelFormat::kR32Float;
    default:
      FML_DCHECK(false) << "Unknown pixel format.";
      return ImageDecoder::TargetPixelFormat::kUnknown;
  }
}

void ImageDescriptor::instantiateCodec(Dart_Handle codec_handle,
                                       int32_t target_width,
                                       int32_t target_height,
                                       int32_t destination_format) {
  fml::RefPtr<Codec> ui_codec;
  if (!generator_ || generator_->GetFrameCount() == 1) {
    ui_codec = fml::MakeRefCounted<SingleFrameCodec>(
        static_cast<fml::RefPtr<ImageDescriptor>>(this),  //
        target_width,                                     //
        target_height,                                    //
        ToImageDecoderTargetPixelFormat(destination_format));
  } else {
    ui_codec = fml::MakeRefCounted<MultiFrameCodec>(generator_);
  }
  ui_codec->AssociateWithDartWrapper(codec_handle);
}

sk_sp<SkImage> ImageDescriptor::image() const {
  return generator_->GetImage();
}

bool ImageDescriptor::get_pixels(const SkPixmap& pixmap) const {
  FML_DCHECK(generator_);
  return generator_->GetPixels(pixmap.info(), pixmap.writable_addr(),
                               pixmap.rowBytes());
}

int ImageDescriptor::bytesPerPixel() const {
  switch (image_info_.format) {
    case kUnknown:
      return 0;
    case kGray8:
      return 1;
    case kRGBA8888:
    case kBGRA8888:
    case kR32Float:
      return 4;
    case kRGBAFloat32:
      return 16;
  }
}

}  // namespace flutter

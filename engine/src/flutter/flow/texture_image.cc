// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flow/open_gl.h"
#include "flow/texture_image.h"
#include "glue/trace_event.h"
#include "third_party/skia/include/gpu/gl/GrGLTypes.h"

namespace flow {

enum class TextureImageFormat {
  Grey,
  GreyAlpha,
  RGB,
  RGBA,
};

enum class TextureImageDataFormat {
  UnsignedByte,
  UnsignedShort565,
};

static inline GLint ToGLFormat(TextureImageFormat format) {
  switch (format) {
    case TextureImageFormat::RGBA:
      return GL_RGBA;
    case TextureImageFormat::RGB:
      return GL_RGB;
    case TextureImageFormat::Grey:
      return GL_LUMINANCE;
    case TextureImageFormat::GreyAlpha:
      return GL_LUMINANCE_ALPHA;
  }
  return GL_NONE;
}

static inline GLint ToGLDataFormat(TextureImageDataFormat dataFormat) {
  switch (dataFormat) {
    case TextureImageDataFormat::UnsignedByte:
      return GL_UNSIGNED_BYTE;
    case TextureImageDataFormat::UnsignedShort565:
      return GL_UNSIGNED_SHORT_5_6_5;
  }
  return GL_NONE;
}

static inline GrPixelConfig ToGrPixelConfig(TextureImageDataFormat dataFormat) {
  switch (dataFormat) {
    case TextureImageDataFormat::UnsignedByte:
      return kRGBA_8888_GrPixelConfig;
    case TextureImageDataFormat::UnsignedShort565:
      return kRGB_565_GrPixelConfig;
  }
  return kUnknown_GrPixelConfig;
}

static inline SkColorType ToSkColorType(TextureImageFormat format) {
  switch (format) {
    case TextureImageFormat::RGBA:
      return SkColorType::kRGBA_8888_SkColorType;
    case TextureImageFormat::RGB:
    case TextureImageFormat::Grey:
    case TextureImageFormat::GreyAlpha:
      // Add more specializations for greyscale images.
      return SkColorType::kRGB_565_SkColorType;
  }
  return kRGB_565_SkColorType;
}

static sk_sp<SkImage> TextureImageCreate(GrContext* context,
                                         TextureImageFormat format,
                                         const SkISize& size,
                                         TextureImageDataFormat dataFormat,
                                         const uint8_t* data) {
  TRACE_EVENT2("flutter", __func__, "width", size.width(), "height",
               size.height());

  if (context == nullptr) {
    return nullptr;
  }

  GLuint handle = GL_NONE;

  // Generate the texture handle.
  glGenTextures(1, &handle);

  // Bind the texture.
  glBindTexture(GL_TEXTURE_2D, handle);

  // Specify default texture properties.
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

  // Update unpack alignment based on format.
  glPixelStorei(GL_UNPACK_ALIGNMENT,
                dataFormat == TextureImageDataFormat::UnsignedByte ? 4 : 2);

  GLint gl_format = ToGLFormat(format);

  // Upload the texture.
  glTexImage2D(GL_TEXTURE_2D,               // target
               0,                           // level
               gl_format,                   // internal format
               size.fWidth,                 // width
               size.fHeight,                // height
               0,                           // border
               gl_format,                   // format
               ToGLDataFormat(dataFormat),  // format
               data);

  // Clear the binding. We are done.
  glBindTexture(GL_TEXTURE_2D, GL_NONE);

  // Flush the texture before it can be bound by another thread.
  glFlush();

  GrGLTextureInfo texInfo;
  texInfo.fTarget = GL_TEXTURE_2D;
  texInfo.fID = handle;

  // Create an SkImage handle from the texture.
  GrBackendTextureDesc desc;

  desc.fOrigin = kTopLeft_GrSurfaceOrigin;
  desc.fFlags = kNone_GrBackendTextureFlag;
  desc.fWidth = size.fWidth;
  desc.fHeight = size.fHeight;
  desc.fTextureHandle = reinterpret_cast<GrBackendObject>(&texInfo);

  desc.fConfig = ToGrPixelConfig(dataFormat);

  if (auto image = SkImage::MakeFromAdoptedTexture(context, desc)) {
    // Texture handle was successfully adopted by the SkImage.
    return image;
  }

  // We could not create an SkImage from the texture. Since it could not be
  // adopted, delete the handle and return null.
  glDeleteTextures(1, &handle);

  return nullptr;
}

static sk_sp<SkImage> TextureImageCreate(GrContext* context,
                                         const SkBitmap& bitmap) {
  if (context == nullptr) {
    return nullptr;
  }

  if (bitmap.drawsNothing()) {
    return nullptr;
  }

  TextureImageDataFormat dataFormat = TextureImageDataFormat::UnsignedByte;
  TextureImageFormat imageFormat = TextureImageFormat::RGBA;

  switch (bitmap.colorType()) {
    case kRGB_565_SkColorType:
      dataFormat = TextureImageDataFormat::UnsignedShort565;
      imageFormat = TextureImageFormat::RGB;
      break;
    case kRGBA_8888_SkColorType:
      dataFormat = TextureImageDataFormat::UnsignedByte;
      imageFormat = TextureImageFormat::RGBA;
      break;
    default:
      // Add more as supported.
      return nullptr;
  }

  return TextureImageCreate(
      context,                                              // context
      imageFormat,                                          // image format
      SkISize::Make(bitmap.width(), bitmap.height()),       // size
      dataFormat,                                           // data format
      reinterpret_cast<const uint8_t*>(bitmap.getPixels())  // data
      );
}

sk_sp<SkImage> BitmapImageCreate(SkImageGenerator& generator) {
  SkBitmap bitmap;

  if (generator.tryGenerateBitmap(&bitmap)) {
    return SkImage::MakeFromBitmap(bitmap);
  }

  return nullptr;
}

sk_sp<SkImage> TextureImageCreate(GrContext* context,
                                  SkImageGenerator& generator) {
  if (context == nullptr) {
    return nullptr;
  }

  const SkImageInfo& info = generator.getInfo();

  if (info.isEmpty()) {
    return nullptr;
  }

  TextureImageFormat imageFormat = TextureImageFormat::RGBA;
  bool preferOpaque = SkAlphaTypeIsOpaque(info.alphaType());

  if (preferOpaque) {
    imageFormat = TextureImageFormat::RGB;
  }

  auto preferredImageInfo =
      SkImageInfo::Make(info.bounds().width(),       // width
                        info.bounds().height(),      // height
                        ToSkColorType(imageFormat),  // color type
                        preferOpaque ? SkAlphaType::kOpaque_SkAlphaType
                                     : SkAlphaType::kPremul_SkAlphaType);

  SkBitmap bitmap;

  {
    TRACE_EVENT1("flutter", "DecodePrimaryPreferrence", "Type",
                 preferOpaque ? "RGB565" : "RGBA8888");
    // Try our preferred config.
    if (generator.tryGenerateBitmap(&bitmap, preferredImageInfo, nullptr)) {
      // Our got our preferred bitmap.
      return TextureImageCreate(context, bitmap);
    }
  }

  {
    TRACE_EVENT0("flutter", "DecodeRecommended");
    // Try the guessed config.
    if (generator.tryGenerateBitmap(&bitmap)) {
      return TextureImageCreate(context, bitmap);
    }
  }

  return nullptr;
}

}  // namespace flow

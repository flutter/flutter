// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flow/texture_image.h"
#include "flow/open_gl.h"

namespace flow {

inline GLint ToGLFormat(TextureImageFormat format) {
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

inline GLint ToGLDataFormat(TextureImageDataFormat dataFormat) {
  switch (dataFormat) {
    case TextureImageDataFormat::UnsignedByte:
      return GL_UNSIGNED_BYTE;
    case TextureImageDataFormat::UnsignedShort565:
      return GL_UNSIGNED_SHORT_5_6_5;
  }
  return GL_NONE;
}

sk_sp<SkImage> TextureImageCreate(GrContext* context,
                                  TextureImageFormat format,
                                  const SkISize& size,
                                  TextureImageDataFormat dataFormat,
                                  const uint8_t* data) {
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

  // Create an SkImage handle from the texture.
  GrBackendTextureDesc desc;

  desc.fWidth = size.fWidth;
  desc.fHeight = size.fHeight;
  desc.fTextureHandle = handle;

  if (auto image = SkImage::MakeFromAdoptedTexture(context, desc)) {
    // Texture handle was successfully adopted by the SkImage.
    return image;
  }

  // We could not create an SkImage from the texture. Since it could not be
  // adopted, delete the handle and return null.
  glDeleteTextures(1, &handle);

  return nullptr;
}

}  // namespace flow

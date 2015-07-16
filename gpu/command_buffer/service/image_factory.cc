// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/image_factory.h"

#include "gpu/command_buffer/common/capabilities.h"
#include "ui/gl/gl_bindings.h"

namespace gpu {

ImageFactory::ImageFactory() {
}

ImageFactory::~ImageFactory() {
}

// static
gfx::GpuMemoryBuffer::Format ImageFactory::ImageFormatToGpuMemoryBufferFormat(
    unsigned internalformat) {
  switch (internalformat) {
    case GL_RGB:
      return gfx::GpuMemoryBuffer::RGBX_8888;
    case GL_RGBA:
      return gfx::GpuMemoryBuffer::RGBA_8888;
    case GL_ATC_RGB_AMD:
      return gfx::GpuMemoryBuffer::ATC;
    case GL_ATC_RGBA_INTERPOLATED_ALPHA_AMD:
      return gfx::GpuMemoryBuffer::ATCIA;
    case GL_COMPRESSED_RGB_S3TC_DXT1_EXT:
      return gfx::GpuMemoryBuffer::DXT1;
    case GL_COMPRESSED_RGBA_S3TC_DXT5_EXT:
      return gfx::GpuMemoryBuffer::DXT5;
    case GL_ETC1_RGB8_OES:
      return gfx::GpuMemoryBuffer::ETC1;
    default:
      NOTREACHED();
      return gfx::GpuMemoryBuffer::RGBA_8888;
  }
}

// static
gfx::GpuMemoryBuffer::Usage ImageFactory::ImageUsageToGpuMemoryBufferUsage(
    unsigned usage) {
  switch (usage) {
    case GL_MAP_CHROMIUM:
      return gfx::GpuMemoryBuffer::MAP;
    case GL_SCANOUT_CHROMIUM:
      return gfx::GpuMemoryBuffer::SCANOUT;
    default:
      NOTREACHED();
      return gfx::GpuMemoryBuffer::MAP;
  }
}

// static
bool ImageFactory::IsImageFormatCompatibleWithGpuMemoryBufferFormat(
    unsigned internalformat,
    gfx::GpuMemoryBuffer::Format format) {
  switch (internalformat) {
    case GL_RGB:
      switch (format) {
        case gfx::GpuMemoryBuffer::ATC:
        case gfx::GpuMemoryBuffer::ATCIA:
        case gfx::GpuMemoryBuffer::DXT1:
        case gfx::GpuMemoryBuffer::DXT5:
        case gfx::GpuMemoryBuffer::ETC1:
        case gfx::GpuMemoryBuffer::RGBX_8888:
          return true;
        case gfx::GpuMemoryBuffer::RGBA_8888:
        case gfx::GpuMemoryBuffer::BGRA_8888:
          return false;
      }
      NOTREACHED();
      return false;
    case GL_RGBA:
      switch (format) {
        case gfx::GpuMemoryBuffer::RGBX_8888:
          return false;
        case gfx::GpuMemoryBuffer::ATC:
        case gfx::GpuMemoryBuffer::ATCIA:
        case gfx::GpuMemoryBuffer::DXT1:
        case gfx::GpuMemoryBuffer::DXT5:
        case gfx::GpuMemoryBuffer::ETC1:
        case gfx::GpuMemoryBuffer::RGBA_8888:
        case gfx::GpuMemoryBuffer::BGRA_8888:
          return true;
      }
      NOTREACHED();
      return false;
    default:
      NOTREACHED();
      return false;
  }
}

// static
bool ImageFactory::IsGpuMemoryBufferFormatSupported(
    gfx::GpuMemoryBuffer::Format format,
    const gpu::Capabilities& capabilities) {
  switch (format) {
    case gfx::GpuMemoryBuffer::ATC:
    case gfx::GpuMemoryBuffer::ATCIA:
      return capabilities.texture_format_atc;
    case gfx::GpuMemoryBuffer::BGRA_8888:
      return capabilities.texture_format_bgra8888;
    case gfx::GpuMemoryBuffer::DXT1:
      return capabilities.texture_format_dxt1;
    case gfx::GpuMemoryBuffer::DXT5:
      return capabilities.texture_format_dxt5;
    case gfx::GpuMemoryBuffer::ETC1:
      return capabilities.texture_format_etc1;
    case gfx::GpuMemoryBuffer::RGBA_8888:
    case gfx::GpuMemoryBuffer::RGBX_8888:
      return true;
  }

  NOTREACHED();
  return false;
}

// static
bool ImageFactory::IsImageSizeValidForGpuMemoryBufferFormat(
    const gfx::Size& size,
    gfx::GpuMemoryBuffer::Format format) {
  switch (format) {
    case gfx::GpuMemoryBuffer::ATC:
    case gfx::GpuMemoryBuffer::ATCIA:
    case gfx::GpuMemoryBuffer::DXT1:
    case gfx::GpuMemoryBuffer::DXT5:
    case gfx::GpuMemoryBuffer::ETC1:
      // Compressed images must have a width and height that's evenly divisible
      // by the block size.
      return size.width() % 4 == 0 && size.height() % 4 == 0;
    case gfx::GpuMemoryBuffer::RGBA_8888:
    case gfx::GpuMemoryBuffer::BGRA_8888:
    case gfx::GpuMemoryBuffer::RGBX_8888:
      return true;
  }

  NOTREACHED();
  return false;
}

}  // namespace gpu

// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_image_linux_dma_buffer.h"

#include <unistd.h>

#define FOURCC(a, b, c, d)                                    \
  ((static_cast<uint32>(a)) | (static_cast<uint32>(b) << 8) | \
   (static_cast<uint32>(c) << 16) | (static_cast<uint32>(d) << 24))

#define DRM_FORMAT_ARGB8888 FOURCC('A', 'R', '2', '4')
#define DRM_FORMAT_XRGB8888 FOURCC('X', 'R', '2', '4')

namespace gfx {
namespace {

bool ValidFormat(unsigned internalformat, gfx::GpuMemoryBuffer::Format format) {
  switch (internalformat) {
    case GL_ATC_RGB_AMD:
      return format == gfx::GpuMemoryBuffer::ATC;
    case GL_ATC_RGBA_INTERPOLATED_ALPHA_AMD:
      return format == gfx::GpuMemoryBuffer::ATCIA;
    case GL_COMPRESSED_RGB_S3TC_DXT1_EXT:
      return format == gfx::GpuMemoryBuffer::DXT1;
    case GL_COMPRESSED_RGBA_S3TC_DXT5_EXT:
      return format == gfx::GpuMemoryBuffer::DXT5;
    case GL_ETC1_RGB8_OES:
      return format == gfx::GpuMemoryBuffer::ETC1;
    case GL_RGB:
      switch (format) {
        case gfx::GpuMemoryBuffer::RGBX_8888:
          return true;
        case gfx::GpuMemoryBuffer::ATC:
        case gfx::GpuMemoryBuffer::ATCIA:
        case gfx::GpuMemoryBuffer::DXT1:
        case gfx::GpuMemoryBuffer::DXT5:
        case gfx::GpuMemoryBuffer::ETC1:
        case gfx::GpuMemoryBuffer::RGBA_8888:
        case gfx::GpuMemoryBuffer::BGRA_8888:
          return false;
      }
      NOTREACHED();
      return false;
    case GL_RGBA:
      switch (format) {
        case gfx::GpuMemoryBuffer::BGRA_8888:
          return true;
        case gfx::GpuMemoryBuffer::ATC:
        case gfx::GpuMemoryBuffer::ATCIA:
        case gfx::GpuMemoryBuffer::DXT1:
        case gfx::GpuMemoryBuffer::DXT5:
        case gfx::GpuMemoryBuffer::ETC1:
        case gfx::GpuMemoryBuffer::RGBX_8888:
        case gfx::GpuMemoryBuffer::RGBA_8888:
          return false;
      }
      NOTREACHED();
      return false;
    default:
      return false;
  }
}

EGLint FourCC(gfx::GpuMemoryBuffer::Format format) {
  switch (format) {
    case gfx::GpuMemoryBuffer::BGRA_8888:
      return DRM_FORMAT_ARGB8888;
    case gfx::GpuMemoryBuffer::RGBX_8888:
      return DRM_FORMAT_XRGB8888;
    case gfx::GpuMemoryBuffer::ATC:
    case gfx::GpuMemoryBuffer::ATCIA:
    case gfx::GpuMemoryBuffer::DXT1:
    case gfx::GpuMemoryBuffer::DXT5:
    case gfx::GpuMemoryBuffer::ETC1:
    case gfx::GpuMemoryBuffer::RGBA_8888:
      NOTREACHED();
      return 0;
  }

  NOTREACHED();
  return 0;
}

bool IsHandleValid(const base::FileDescriptor& handle) {
  return handle.fd >= 0;
}

}  // namespace

GLImageLinuxDMABuffer::GLImageLinuxDMABuffer(const gfx::Size& size,
                                             unsigned internalformat)
    : GLImageEGL(size), internalformat_(internalformat) {
}

GLImageLinuxDMABuffer::~GLImageLinuxDMABuffer() {
}

bool GLImageLinuxDMABuffer::Initialize(const base::FileDescriptor& handle,
                                       gfx::GpuMemoryBuffer::Format format,
                                       int pitch) {
  if (!ValidFormat(internalformat_, format)) {
    LOG(ERROR) << "Invalid format: " << internalformat_;
    return false;
  }

  if (!IsHandleValid(handle)) {
    LOG(ERROR) << "Invalid file descriptor: " << handle.fd;
    return false;
  }

  // Note: If eglCreateImageKHR is successful for a EGL_LINUX_DMA_BUF_EXT
  // target, the EGL will take a reference to the dma_buf.
  EGLint attrs[] = {EGL_WIDTH,
                    size_.width(),
                    EGL_HEIGHT,
                    size_.height(),
                    EGL_LINUX_DRM_FOURCC_EXT,
                    FourCC(format),
                    EGL_DMA_BUF_PLANE0_FD_EXT,
                    handle.fd,
                    EGL_DMA_BUF_PLANE0_OFFSET_EXT,
                    0,
                    EGL_DMA_BUF_PLANE0_PITCH_EXT,
                    pitch,
                    EGL_NONE};
  return GLImageEGL::Initialize(
      EGL_LINUX_DMA_BUF_EXT, static_cast<EGLClientBuffer>(NULL), attrs);
}

}  // namespace gfx

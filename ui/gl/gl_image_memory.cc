// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_image_memory.h"

#include "base/logging.h"
#include "base/trace_event/trace_event.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_surface_egl.h"
#include "ui/gl/scoped_binders.h"

namespace gfx {
namespace {

bool ValidInternalFormat(unsigned internalformat) {
  switch (internalformat) {
    case GL_RGBA:
      return true;
    default:
      return false;
  }
}

bool ValidFormat(gfx::GpuMemoryBuffer::Format format) {
  switch (format) {
    case gfx::GpuMemoryBuffer::ATC:
    case gfx::GpuMemoryBuffer::ATCIA:
    case gfx::GpuMemoryBuffer::DXT1:
    case gfx::GpuMemoryBuffer::DXT5:
    case gfx::GpuMemoryBuffer::ETC1:
    case gfx::GpuMemoryBuffer::RGBA_8888:
    case gfx::GpuMemoryBuffer::BGRA_8888:
      return true;
    case gfx::GpuMemoryBuffer::RGBX_8888:
      return false;
  }

  NOTREACHED();
  return false;
}

bool IsCompressedFormat(gfx::GpuMemoryBuffer::Format format) {
  switch (format) {
    case gfx::GpuMemoryBuffer::ATC:
    case gfx::GpuMemoryBuffer::ATCIA:
    case gfx::GpuMemoryBuffer::DXT1:
    case gfx::GpuMemoryBuffer::DXT5:
    case gfx::GpuMemoryBuffer::ETC1:
      return true;
    case gfx::GpuMemoryBuffer::RGBA_8888:
    case gfx::GpuMemoryBuffer::BGRA_8888:
    case gfx::GpuMemoryBuffer::RGBX_8888:
      return false;
  }

  NOTREACHED();
  return false;
}

GLenum TextureFormat(gfx::GpuMemoryBuffer::Format format) {
  switch (format) {
    case gfx::GpuMemoryBuffer::ATC:
      return GL_ATC_RGB_AMD;
    case gfx::GpuMemoryBuffer::ATCIA:
      return GL_ATC_RGBA_INTERPOLATED_ALPHA_AMD;
    case gfx::GpuMemoryBuffer::DXT1:
      return GL_COMPRESSED_RGB_S3TC_DXT1_EXT;
    case gfx::GpuMemoryBuffer::DXT5:
      return GL_COMPRESSED_RGBA_S3TC_DXT5_EXT;
    case gfx::GpuMemoryBuffer::ETC1:
      return GL_ETC1_RGB8_OES;
    case gfx::GpuMemoryBuffer::RGBA_8888:
      return GL_RGBA;
    case gfx::GpuMemoryBuffer::BGRA_8888:
      return GL_BGRA_EXT;
    case gfx::GpuMemoryBuffer::RGBX_8888:
      NOTREACHED();
      return 0;
  }

  NOTREACHED();
  return 0;
}

GLenum DataFormat(gfx::GpuMemoryBuffer::Format format) {
  return TextureFormat(format);
}

GLenum DataType(gfx::GpuMemoryBuffer::Format format) {
  switch (format) {
    case gfx::GpuMemoryBuffer::RGBA_8888:
    case gfx::GpuMemoryBuffer::BGRA_8888:
      return GL_UNSIGNED_BYTE;
    case gfx::GpuMemoryBuffer::ATC:
    case gfx::GpuMemoryBuffer::ATCIA:
    case gfx::GpuMemoryBuffer::DXT1:
    case gfx::GpuMemoryBuffer::DXT5:
    case gfx::GpuMemoryBuffer::ETC1:
    case gfx::GpuMemoryBuffer::RGBX_8888:
      NOTREACHED();
      return 0;
  }

  NOTREACHED();
  return 0;
}

GLsizei SizeInBytes(const gfx::Size& size,
                    gfx::GpuMemoryBuffer::Format format) {
  size_t stride_in_bytes = 0;
  bool valid_stride = GLImageMemory::StrideInBytes(
      size.width(), format, &stride_in_bytes);
  DCHECK(valid_stride);
  return static_cast<GLsizei>(stride_in_bytes * size.height());
}

}  // namespace

GLImageMemory::GLImageMemory(const gfx::Size& size, unsigned internalformat)
    : size_(size),
      internalformat_(internalformat),
      memory_(NULL),
      format_(gfx::GpuMemoryBuffer::RGBA_8888),
      in_use_(false),
      target_(0),
      need_do_bind_tex_image_(false),
      egl_texture_id_(0u),
      egl_image_(EGL_NO_IMAGE_KHR) {
}

GLImageMemory::~GLImageMemory() {
  DCHECK_EQ(EGL_NO_IMAGE_KHR, egl_image_);
  DCHECK_EQ(0u, egl_texture_id_);
}

// static
bool GLImageMemory::StrideInBytes(size_t width,
                                  gfx::GpuMemoryBuffer::Format format,
                                  size_t* stride_in_bytes) {
  base::CheckedNumeric<size_t> s = width;
  switch (format) {
    case gfx::GpuMemoryBuffer::ATCIA:
    case gfx::GpuMemoryBuffer::DXT5:
      *stride_in_bytes = width;
      return true;
    case gfx::GpuMemoryBuffer::ATC:
    case gfx::GpuMemoryBuffer::DXT1:
    case gfx::GpuMemoryBuffer::ETC1:
      DCHECK_EQ(width % 2, 0U);
      s /= 2;
      if (!s.IsValid())
        return false;

      *stride_in_bytes = s.ValueOrDie();
      return true;
    case gfx::GpuMemoryBuffer::RGBA_8888:
    case gfx::GpuMemoryBuffer::BGRA_8888:
      s *= 4;
      if (!s.IsValid())
        return false;

      *stride_in_bytes = s.ValueOrDie();
      return true;
    case gfx::GpuMemoryBuffer::RGBX_8888:
      NOTREACHED();
      return false;
  }

  NOTREACHED();
  return false;
}

bool GLImageMemory::Initialize(const unsigned char* memory,
                               gfx::GpuMemoryBuffer::Format format) {
  if (!ValidInternalFormat(internalformat_)) {
    LOG(ERROR) << "Invalid internalformat: " << internalformat_;
    return false;
  }

  if (!ValidFormat(format)) {
    LOG(ERROR) << "Invalid format: " << format;
    return false;
  }

  DCHECK(memory);
  DCHECK(!memory_);
  DCHECK_IMPLIES(IsCompressedFormat(format), size_.width() % 4 == 0);
  DCHECK_IMPLIES(IsCompressedFormat(format), size_.height() % 4 == 0);
  memory_ = memory;
  format_ = format;
  return true;
}

void GLImageMemory::Destroy(bool have_context) {
  if (egl_image_ != EGL_NO_IMAGE_KHR) {
    eglDestroyImageKHR(GLSurfaceEGL::GetHardwareDisplay(), egl_image_);
    egl_image_ = EGL_NO_IMAGE_KHR;
  }

  if (egl_texture_id_) {
    if (have_context)
      glDeleteTextures(1, &egl_texture_id_);
    egl_texture_id_ = 0u;
  }
  memory_ = NULL;
}

gfx::Size GLImageMemory::GetSize() {
  return size_;
}

bool GLImageMemory::BindTexImage(unsigned target) {
  if (target_ && target_ != target) {
    LOG(ERROR) << "GLImage can only be bound to one target";
    return false;
  }
  target_ = target;

  // Defer DoBindTexImage if not currently in use.
  if (!in_use_) {
    need_do_bind_tex_image_ = true;
    return true;
  }

  DoBindTexImage(target);
  return true;
}

bool GLImageMemory::CopyTexImage(unsigned target) {
  TRACE_EVENT0("gpu", "GLImageMemory::CopyTexImage");

  // GL_TEXTURE_EXTERNAL_OES is not a supported CopyTexImage target.
  if (target == GL_TEXTURE_EXTERNAL_OES)
    return false;

  DCHECK(memory_);
  if (IsCompressedFormat(format_)) {
    glCompressedTexSubImage2D(target,
                              0,  // level
                              0,  // x-offset
                              0,  // y-offset
                              size_.width(), size_.height(),
                              DataFormat(format_), SizeInBytes(size_, format_),
                              memory_);
  } else {
    glTexSubImage2D(target, 0,  // level
                    0,          // x
                    0,          // y
                    size_.width(), size_.height(), DataFormat(format_),
                    DataType(format_), memory_);
  }

  return true;
}

void GLImageMemory::WillUseTexImage() {
  DCHECK(!in_use_);
  in_use_ = true;

  if (!need_do_bind_tex_image_)
    return;

  DCHECK(target_);
  DoBindTexImage(target_);
}

void GLImageMemory::DidUseTexImage() {
  DCHECK(in_use_);
  in_use_ = false;
}

bool GLImageMemory::ScheduleOverlayPlane(gfx::AcceleratedWidget widget,
                                         int z_order,
                                         OverlayTransform transform,
                                         const Rect& bounds_rect,
                                         const RectF& crop_rect) {
  return false;
}

void GLImageMemory::DoBindTexImage(unsigned target) {
  TRACE_EVENT0("gpu", "GLImageMemory::DoBindTexImage");

  DCHECK(need_do_bind_tex_image_);
  need_do_bind_tex_image_ = false;

  DCHECK(memory_);
  if (target == GL_TEXTURE_EXTERNAL_OES) {
    if (egl_image_ == EGL_NO_IMAGE_KHR) {
      DCHECK_EQ(0u, egl_texture_id_);
      glGenTextures(1, &egl_texture_id_);

      {
        ScopedTextureBinder texture_binder(GL_TEXTURE_2D, egl_texture_id_);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        if (IsCompressedFormat(format_)) {
          glCompressedTexImage2D(GL_TEXTURE_2D,
                                 0,  // mip level
                                 TextureFormat(format_), size_.width(),
                                 size_.height(),
                                 0,  // border
                                 SizeInBytes(size_, format_), memory_);
        } else {
          glTexImage2D(GL_TEXTURE_2D,
                       0,  // mip level
                       TextureFormat(format_),
                       size_.width(),
                       size_.height(),
                       0,  // border
                       DataFormat(format_),
                       DataType(format_),
                       memory_);
        }
      }

      EGLint attrs[] = {EGL_IMAGE_PRESERVED_KHR, EGL_TRUE, EGL_NONE};
      // Need to pass current EGL rendering context to eglCreateImageKHR for
      // target type EGL_GL_TEXTURE_2D_KHR.
      egl_image_ =
          eglCreateImageKHR(GLSurfaceEGL::GetHardwareDisplay(),
                            eglGetCurrentContext(),
                            EGL_GL_TEXTURE_2D_KHR,
                            reinterpret_cast<EGLClientBuffer>(egl_texture_id_),
                            attrs);
      DCHECK_NE(EGL_NO_IMAGE_KHR, egl_image_)
          << "Error creating EGLImage: " << eglGetError();
    } else {
      ScopedTextureBinder texture_binder(GL_TEXTURE_2D, egl_texture_id_);

      if (IsCompressedFormat(format_)) {
        glCompressedTexSubImage2D(GL_TEXTURE_2D,
                                  0,  // mip level
                                  0,  // x-offset
                                  0,  // y-offset
                                  size_.width(), size_.height(),
                                  DataFormat(format_),
                                  SizeInBytes(size_, format_),
                                  memory_);
      } else {
        glTexSubImage2D(GL_TEXTURE_2D,
                        0,  // mip level
                        0,  // x-offset
                        0,  // y-offset
                        size_.width(),
                        size_.height(),
                        DataFormat(format_),
                        DataType(format_),
                        memory_);
      }
    }

    glEGLImageTargetTexture2DOES(target, egl_image_);
    DCHECK_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError());
    return;
  }

  DCHECK_NE(static_cast<GLenum>(GL_TEXTURE_EXTERNAL_OES), target);
  if (IsCompressedFormat(format_)) {
    glCompressedTexImage2D(target,
                           0,  // mip level
                           TextureFormat(format_), size_.width(),
                           size_.height(),
                           0,  // border
                           SizeInBytes(size_, format_), memory_);
  } else {
    glTexImage2D(target,
                 0,  // mip level
                 TextureFormat(format_),
                 size_.width(),
                 size_.height(),
                 0,  // border
                 DataFormat(format_),
                 DataType(format_),
                 memory_);
  }
}

}  // namespace gfx

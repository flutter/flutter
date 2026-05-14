// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/formats_gles.h"

namespace impeller {

std::string DebugToFramebufferError(int status) {
  switch (status) {
    case GL_FRAMEBUFFER_UNDEFINED:
      return "GL_FRAMEBUFFER_UNDEFINED";
    case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
      return "GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT";
    case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
      return "GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT";
    case GL_FRAMEBUFFER_UNSUPPORTED:
      return "GL_FRAMEBUFFER_UNSUPPORTED";
    case GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE:
      return "GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE";
    default:
      return "Unknown error code: " + std::to_string(status);
  }
}

std::optional<PixelFormatGLES> ToPixelFormatGLES(PixelFormat pixel_format,
                                                 bool supports_bgra) {
  PixelFormatGLES format;

  switch (pixel_format) {
    case PixelFormat::kA8UNormInt:
      format.internal_format = GL_ALPHA;
      format.external_format = GL_ALPHA;
      format.type = GL_UNSIGNED_BYTE;
      break;
    case PixelFormat::kR8UNormInt:
      format.internal_format = GL_RED;
      format.external_format = GL_RED;
      format.type = GL_UNSIGNED_BYTE;
      break;
    case PixelFormat::kR8G8B8A8UNormInt:
    case PixelFormat::kR8G8B8A8UNormIntSRGB:
      format.internal_format = GL_RGBA;
      format.external_format = GL_RGBA;
      format.type = GL_UNSIGNED_BYTE;
      break;
    case PixelFormat::kB8G8R8A8UNormInt:
    case PixelFormat::kB8G8R8A8UNormIntSRGB:
      if (supports_bgra) {
        format.internal_format = GL_BGRA_EXT;
        format.external_format = GL_BGRA_EXT;
      } else {
        format.internal_format = GL_RGBA;
        format.external_format = GL_RGBA;
      }
      format.type = GL_UNSIGNED_BYTE;
      break;
    case PixelFormat::kR32G32B32A32Float:
      format.internal_format = GL_RGBA32F;
      format.external_format = GL_RGBA;
      format.type = GL_FLOAT;
      break;
    case PixelFormat::kR32Float:
      format.internal_format = GL_R32F;
      format.external_format = GL_RED;
      format.type = GL_FLOAT;
      break;
    case PixelFormat::kR16G16B16A16Float:
      format.internal_format = GL_RGBA16F;
      format.external_format = GL_RGBA;
      format.type = GL_HALF_FLOAT;
      break;
    case PixelFormat::kS8UInt:
      // Pure stencil textures are only available in OpenGL 4.4+, which is
      // ~0% of mobile devices. Instead, we use a depth-stencil texture and
      // only use the stencil component.
      //
      // https://registry.khronos.org/OpenGL-Refpages/gl4/html/glTexImage2D.xhtml
    case PixelFormat::kD24UnormS8Uint:
      format.internal_format = GL_DEPTH_STENCIL;
      format.external_format = GL_DEPTH_STENCIL;
      format.type = GL_UNSIGNED_INT_24_8;
      break;
    case PixelFormat::kUnknown:
    case PixelFormat::kD32FloatS8UInt:
    case PixelFormat::kR8G8UNormInt:
    case PixelFormat::kB10G10R10XRSRGB:
    case PixelFormat::kB10G10R10XR:
    case PixelFormat::kB10G10R10A10XR:
      return std::nullopt;
  }
  return format;
}

}  // namespace impeller

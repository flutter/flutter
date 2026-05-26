// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/formats_gles.h"

// Compressed texture internal formats. ETC2/EAC are core in OpenGL ES 3.0, but
// the S3TC (BC1/BC3), RGTC (BC5), BPTC (BC7), and ASTC enums come from
// extension headers that are not present on every platform, so they are
// guarded here.
#ifndef GL_COMPRESSED_RGBA_S3TC_DXT1_EXT
#define GL_COMPRESSED_RGBA_S3TC_DXT1_EXT 0x83F1
#endif
#ifndef GL_COMPRESSED_RGBA_S3TC_DXT5_EXT
#define GL_COMPRESSED_RGBA_S3TC_DXT5_EXT 0x83F3
#endif
#ifndef GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT
#define GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT 0x8C4D
#endif
#ifndef GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT
#define GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT 0x8C4F
#endif
#ifndef GL_COMPRESSED_RG_RGTC2
#define GL_COMPRESSED_RG_RGTC2 0x8DBD
#endif
#ifndef GL_COMPRESSED_RGBA_BPTC_UNORM
#define GL_COMPRESSED_RGBA_BPTC_UNORM 0x8E8C
#endif
#ifndef GL_COMPRESSED_SRGB_ALPHA_BPTC_UNORM
#define GL_COMPRESSED_SRGB_ALPHA_BPTC_UNORM 0x8E8D
#endif
#ifndef GL_COMPRESSED_RGB8_ETC2
#define GL_COMPRESSED_RGB8_ETC2 0x9274
#endif
#ifndef GL_COMPRESSED_SRGB8_ETC2
#define GL_COMPRESSED_SRGB8_ETC2 0x9275
#endif
#ifndef GL_COMPRESSED_RGBA8_ETC2_EAC
#define GL_COMPRESSED_RGBA8_ETC2_EAC 0x9278
#endif
#ifndef GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC
#define GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC 0x9279
#endif
#ifndef GL_COMPRESSED_RGBA_ASTC_4x4_KHR
#define GL_COMPRESSED_RGBA_ASTC_4x4_KHR 0x93B0
#endif
#ifndef GL_COMPRESSED_RGBA_ASTC_8x8_KHR
#define GL_COMPRESSED_RGBA_ASTC_8x8_KHR 0x93B7
#endif
#ifndef GL_COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR 0x93D0
#endif
#ifndef GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR 0x93D7
#endif

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
    // Block-compressed formats. Only the internal format is meaningful; the
    // data is uploaded with glCompressedTexImage2D rather than glTexImage2D.
    case PixelFormat::kBC1RGBAUNormInt:
      format.internal_format = GL_COMPRESSED_RGBA_S3TC_DXT1_EXT;
      format.is_compressed = true;
      break;
    case PixelFormat::kBC1RGBAUNormIntSRGB:
      format.internal_format = GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT;
      format.is_compressed = true;
      break;
    case PixelFormat::kBC3RGBAUNormInt:
      format.internal_format = GL_COMPRESSED_RGBA_S3TC_DXT5_EXT;
      format.is_compressed = true;
      break;
    case PixelFormat::kBC3RGBAUNormIntSRGB:
      format.internal_format = GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT;
      format.is_compressed = true;
      break;
    case PixelFormat::kBC5RGUNormInt:
      format.internal_format = GL_COMPRESSED_RG_RGTC2;
      format.is_compressed = true;
      break;
    case PixelFormat::kBC7RGBAUNormInt:
      format.internal_format = GL_COMPRESSED_RGBA_BPTC_UNORM;
      format.is_compressed = true;
      break;
    case PixelFormat::kBC7RGBAUNormIntSRGB:
      format.internal_format = GL_COMPRESSED_SRGB_ALPHA_BPTC_UNORM;
      format.is_compressed = true;
      break;
    case PixelFormat::kETC2RGB8UNormInt:
      format.internal_format = GL_COMPRESSED_RGB8_ETC2;
      format.is_compressed = true;
      break;
    case PixelFormat::kETC2RGB8UNormIntSRGB:
      format.internal_format = GL_COMPRESSED_SRGB8_ETC2;
      format.is_compressed = true;
      break;
    case PixelFormat::kETC2RGBA8UNormInt:
      format.internal_format = GL_COMPRESSED_RGBA8_ETC2_EAC;
      format.is_compressed = true;
      break;
    case PixelFormat::kETC2RGBA8UNormIntSRGB:
      format.internal_format = GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC;
      format.is_compressed = true;
      break;
    case PixelFormat::kASTC4x4LDR:
      format.internal_format = GL_COMPRESSED_RGBA_ASTC_4x4_KHR;
      format.is_compressed = true;
      break;
    case PixelFormat::kASTC4x4LDRSRGB:
      format.internal_format = GL_COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR;
      format.is_compressed = true;
      break;
    case PixelFormat::kASTC8x8LDR:
      format.internal_format = GL_COMPRESSED_RGBA_ASTC_8x8_KHR;
      format.is_compressed = true;
      break;
    case PixelFormat::kASTC8x8LDRSRGB:
      format.internal_format = GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR;
      format.is_compressed = true;
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

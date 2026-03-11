// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/blit_command_gles.h"

#include "flutter/fml/closure.h"
#include "impeller/base/validation.h"
#include "impeller/core/formats.h"
#include "impeller/geometry/point.h"
#include "impeller/renderer/backend/gles/device_buffer_gles.h"
#include "impeller/renderer/backend/gles/formats_gles.h"
#include "impeller/renderer/backend/gles/reactor_gles.h"
#include "impeller/renderer/backend/gles/texture_gles.h"

namespace impeller {

namespace {
static void FlipImage(uint8_t* buffer,
                      size_t width,
                      size_t height,
                      size_t stride) {
  if (buffer == nullptr || stride == 0) {
    return;
  }

  const auto byte_width = width * stride;

  for (size_t top = 0; top < height; top++) {
    size_t bottom = height - top - 1;
    if (top >= bottom) {
      break;
    }
    auto* top_row = buffer + byte_width * top;
    auto* bottom_row = buffer + byte_width * bottom;
    std::swap_ranges(top_row, top_row + byte_width, bottom_row);
  }
}
}  // namespace

BlitEncodeGLES::~BlitEncodeGLES() = default;

static void DeleteFBO(const ProcTableGLES& gl, GLuint fbo, GLenum type) {
  if (fbo != GL_NONE) {
    gl.BindFramebuffer(type, GL_NONE);
    gl.DeleteFramebuffers(1u, &fbo);
  }
};

static std::optional<GLuint> ConfigureFBO(
    const ProcTableGLES& gl,
    const std::shared_ptr<Texture>& texture,
    GLenum fbo_type) {
  auto handle = TextureGLES::Cast(texture.get())->GetGLHandle();
  if (!handle.has_value()) {
    return std::nullopt;
  }

  if (TextureGLES::Cast(*texture).IsWrapped()) {
    // The texture is attached to the default FBO, so there's no need to
    // create/configure one.
    gl.BindFramebuffer(fbo_type, 0);
    return 0;
  }

  GLuint fbo;
  gl.GenFramebuffers(1u, &fbo);
  gl.BindFramebuffer(fbo_type, fbo);

  if (!TextureGLES::Cast(*texture).SetAsFramebufferAttachment(
          fbo_type, TextureGLES::AttachmentType::kColor0)) {
    VALIDATION_LOG << "Could not attach texture to framebuffer.";
    DeleteFBO(gl, fbo, fbo_type);
    return std::nullopt;
  }

  GLenum status = gl.CheckFramebufferStatus(fbo_type);
  if (status != GL_FRAMEBUFFER_COMPLETE) {
    VALIDATION_LOG << "Could not create a complete framebuffer: "
                   << DebugToFramebufferError(status);
    DeleteFBO(gl, fbo, fbo_type);
    return std::nullopt;
  }

  return fbo;
};

BlitCopyTextureToTextureCommandGLES::~BlitCopyTextureToTextureCommandGLES() =
    default;

std::string BlitCopyTextureToTextureCommandGLES::GetLabel() const {
  return label;
}

bool BlitCopyTextureToTextureCommandGLES::Encode(
    const ReactorGLES& reactor) const {
  const auto& gl = reactor.GetProcTable();

  // glBlitFramebuffer is a GLES3 proc. Since we target GLES2, we need to
  // emulate the blit when it's not available in the driver.
  if (!gl.BlitFramebuffer.IsAvailable()) {
    // TODO(157064): Emulate the blit using a raster draw call here.
    VALIDATION_LOG << "Texture blit fallback not implemented yet for GLES2.";
    return false;
  }

  GLuint read_fbo = GL_NONE;
  GLuint draw_fbo = GL_NONE;
  fml::ScopedCleanupClosure delete_fbos([&gl, &read_fbo, &draw_fbo]() {
    DeleteFBO(gl, read_fbo, GL_READ_FRAMEBUFFER);
    DeleteFBO(gl, draw_fbo, GL_DRAW_FRAMEBUFFER);
  });

  {
    auto read = ConfigureFBO(gl, source, GL_READ_FRAMEBUFFER);
    if (!read.has_value()) {
      return false;
    }
    read_fbo = read.value();
  }

  {
    auto draw = ConfigureFBO(gl, destination, GL_DRAW_FRAMEBUFFER);
    if (!draw.has_value()) {
      return false;
    }
    draw_fbo = draw.value();
  }

  gl.Disable(GL_SCISSOR_TEST);
  gl.Disable(GL_DEPTH_TEST);
  gl.Disable(GL_STENCIL_TEST);

  gl.BlitFramebuffer(source_region.GetX(),       // srcX0
                     source_region.GetY(),       // srcY0
                     source_region.GetWidth(),   // srcX1
                     source_region.GetHeight(),  // srcY1
                     destination_origin.x,       // dstX0
                     destination_origin.y,       // dstY0
                     source_region.GetWidth(),   // dstX1
                     source_region.GetHeight(),  // dstY1
                     GL_COLOR_BUFFER_BIT,        // mask
                     GL_NEAREST                  // filter
  );

  return true;
};

BlitCopyBufferToTextureCommandGLES::~BlitCopyBufferToTextureCommandGLES() =
    default;

std::string BlitCopyBufferToTextureCommandGLES::GetLabel() const {
  return label;
}

bool BlitCopyBufferToTextureCommandGLES::Encode(
    const ReactorGLES& reactor) const {
  TextureGLES& texture_gles = TextureGLES::Cast(*destination);

  if (texture_gles.GetType() != TextureGLES::Type::kTexture) {
    VALIDATION_LOG << "Incorrect texture usage flags for setting contents on "
                      "this texture object.";
    return false;
  }

  if (texture_gles.IsWrapped()) {
    VALIDATION_LOG << "Cannot set the contents of a wrapped texture.";
    return false;
  }

  const auto& tex_descriptor = texture_gles.GetTextureDescriptor();

  if (tex_descriptor.size.IsEmpty()) {
    return true;
  }

  if (!tex_descriptor.IsValid() ||
      source.GetRange().length !=
          BytesPerPixelForPixelFormat(tex_descriptor.format) *
              destination_region.Area()) {
    return false;
  }

  destination->SetCoordinateSystem(TextureCoordinateSystem::kUploadFromHost);

  GLenum texture_type;
  GLenum texture_target;
  switch (tex_descriptor.type) {
    case TextureType::kTexture2D:
      texture_type = GL_TEXTURE_2D;
      texture_target = GL_TEXTURE_2D;
      break;
    case TextureType::kTexture2DMultisample:
      VALIDATION_LOG << "Multisample texture uploading is not supported for "
                        "the OpenGLES backend.";
      return false;
    case TextureType::kTextureCube:
      texture_type = GL_TEXTURE_CUBE_MAP;
      texture_target = GL_TEXTURE_CUBE_MAP_POSITIVE_X + slice;
      break;
    case TextureType::kTextureExternalOES:
      texture_type = GL_TEXTURE_EXTERNAL_OES;
      texture_target = GL_TEXTURE_EXTERNAL_OES;
      break;
  }

  std::optional<PixelFormatGLES> gles_format =
      ToPixelFormatGLES(tex_descriptor.format,
                        /*supports_bgra=*/
                        reactor.GetProcTable().GetDescription()->HasExtension(
                            "GL_EXT_texture_format_BGRA8888"));
  if (!gles_format.has_value()) {
    VALIDATION_LOG << "Invalid texture format.";
    return false;
  }

  auto gl_handle = texture_gles.GetGLHandle();
  if (!gl_handle.has_value()) {
    VALIDATION_LOG
        << "Texture was collected before it could be uploaded to the GPU.";
    return false;
  }
  const auto& gl = reactor.GetProcTable();
  gl.BindTexture(texture_type, gl_handle.value());
  const GLvoid* tex_data =
      source.GetBuffer()->OnGetContents() + source.GetRange().offset;

  // GL_INVALID_OPERATION if the texture array has not been
  // defined by a previous glTexImage2D operation.
  if (!texture_gles.IsSliceInitialized(slice)) {
    gl.TexImage2D(texture_target,                // target
                  mip_level,                     // LOD level
                  gles_format->internal_format,  // internal format
                  tex_descriptor.size.width,     // width
                  tex_descriptor.size.height,    // height
                  0u,                            // border
                  gles_format->external_format,  // format
                  gles_format->type,             // type
                  nullptr);                      // data
    texture_gles.MarkSliceInitialized(slice);
  }

  {
    gl.PixelStorei(GL_UNPACK_ALIGNMENT, 1);
    gl.TexSubImage2D(texture_target,                  // target
                     mip_level,                       // LOD level
                     destination_region.GetX(),       // xoffset
                     destination_region.GetY(),       // yoffset
                     destination_region.GetWidth(),   // width
                     destination_region.GetHeight(),  // height
                     gles_format->external_format,    // format
                     gles_format->type,               // type
                     tex_data);                       // data
  }
  return true;
}

BlitCopyTextureToBufferCommandGLES::~BlitCopyTextureToBufferCommandGLES() =
    default;

std::string BlitCopyTextureToBufferCommandGLES::GetLabel() const {
  return label;
}

bool BlitCopyTextureToBufferCommandGLES::Encode(
    const ReactorGLES& reactor) const {
  const auto& gl = reactor.GetProcTable();

  PixelFormat source_format = source->GetTextureDescriptor().format;
  std::optional<PixelFormatGLES> gles_format =
      ToPixelFormatGLES(source_format,
                        /*supports_bgra=*/
                        reactor.GetProcTable().GetDescription()->HasExtension(
                            "GL_EXT_texture_format_BGRA8888"));

  if (!gles_format.has_value()) {
    VALIDATION_LOG << "Texture has unsupported pixel format.";
    return false;
  }

  TextureCoordinateSystem coord_system = source->GetCoordinateSystem();

  GLuint read_fbo = GL_NONE;
  fml::ScopedCleanupClosure delete_fbos(
      [&gl, &read_fbo]() { DeleteFBO(gl, read_fbo, GL_FRAMEBUFFER); });

  {
    auto read = ConfigureFBO(gl, source, GL_FRAMEBUFFER);
    if (!read.has_value()) {
      return false;
    }
    read_fbo = read.value();
  }

  DeviceBufferGLES::Cast(*destination)
      .UpdateBufferData(
          [&gl,                                                          //
           this,                                                         //
           format = gles_format->external_format,                        //
           type = gles_format->type,                                     //
           coord_system,                                                 //
           bytes_per_pixel = BytesPerPixelForPixelFormat(source_format)  //
  ](uint8_t* data, size_t length) {
            gl.ReadPixels(source_region.GetX(), source_region.GetY(),
                          source_region.GetWidth(), source_region.GetHeight(),
                          format, type, data + destination_offset);
            switch (coord_system) {
              case TextureCoordinateSystem::kUploadFromHost:
                break;
              case TextureCoordinateSystem::kRenderToTexture:
                // The texture is upside down, and must be inverted when copying
                // byte data out.
                FlipImage(data + destination_offset, source_region.GetWidth(),
                          source_region.GetHeight(), bytes_per_pixel);
            }
          });

  return true;
};

BlitGenerateMipmapCommandGLES::~BlitGenerateMipmapCommandGLES() = default;

std::string BlitGenerateMipmapCommandGLES::GetLabel() const {
  return label;
}

bool BlitGenerateMipmapCommandGLES::Encode(const ReactorGLES& reactor) const {
  auto texture_gles = TextureGLES::Cast(texture.get());
  if (!texture_gles->GenerateMipmap()) {
    return false;
  }

  return true;
};

//////  BlitResizeTextureCommandGLES
//////////////////////////////////////////////////////

BlitResizeTextureCommandGLES::~BlitResizeTextureCommandGLES() = default;

std::string BlitResizeTextureCommandGLES::GetLabel() const {
  return "Resize Texture";
}

bool BlitResizeTextureCommandGLES::Encode(const ReactorGLES& reactor) const {
  const auto& gl = reactor.GetProcTable();

  // glBlitFramebuffer is a GLES3 proc. Since we target GLES2, we need to
  // emulate the blit when it's not available in the driver.
  if (!gl.BlitFramebuffer.IsAvailable()) {
    // TODO(157064): Emulate the blit using a raster draw call here.
    VALIDATION_LOG << "Texture blit fallback not implemented yet for GLES2.";
    return false;
  }

  destination->SetCoordinateSystem(source->GetCoordinateSystem());

  GLuint read_fbo = GL_NONE;
  GLuint draw_fbo = GL_NONE;
  fml::ScopedCleanupClosure delete_fbos([&gl, &read_fbo, &draw_fbo]() {
    DeleteFBO(gl, read_fbo, GL_READ_FRAMEBUFFER);
    DeleteFBO(gl, draw_fbo, GL_DRAW_FRAMEBUFFER);
  });

  {
    auto read = ConfigureFBO(gl, source, GL_READ_FRAMEBUFFER);
    if (!read.has_value()) {
      return false;
    }
    read_fbo = read.value();
  }

  {
    auto draw = ConfigureFBO(gl, destination, GL_DRAW_FRAMEBUFFER);
    if (!draw.has_value()) {
      return false;
    }
    draw_fbo = draw.value();
  }

  gl.Disable(GL_SCISSOR_TEST);
  gl.Disable(GL_DEPTH_TEST);
  gl.Disable(GL_STENCIL_TEST);

  const IRect source_region = IRect::MakeSize(source->GetSize());
  const IRect destination_region = IRect::MakeSize(destination->GetSize());

  gl.BlitFramebuffer(source_region.GetX(),            // srcX0
                     source_region.GetY(),            // srcY0
                     source_region.GetWidth(),        // srcX1
                     source_region.GetHeight(),       // srcY1
                     destination_region.GetX(),       // dstX0
                     destination_region.GetY(),       // dstY0
                     destination_region.GetWidth(),   // dstX1
                     destination_region.GetHeight(),  // dstY1
                     GL_COLOR_BUFFER_BIT,             // mask
                     GL_LINEAR                        // filter
  );

  return true;
}

}  // namespace impeller

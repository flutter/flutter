// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/blit_command_gles.h"

#include "flutter/fml/closure.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/gles/device_buffer_gles.h"
#include "impeller/renderer/backend/gles/texture_gles.h"

namespace impeller {

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
          fbo_type, fbo, TextureGLES::AttachmentPoint::kColor0)) {
    VALIDATION_LOG << "Could not attach texture to framebuffer.";
    DeleteFBO(gl, fbo, fbo_type);
    return std::nullopt;
  }

  if (gl.CheckFramebufferStatus(fbo_type) != GL_FRAMEBUFFER_COMPLETE) {
    VALIDATION_LOG << "Could not create a complete frambuffer.";
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
    // TODO(bdero): Emulate the blit using a raster draw call here.
    FML_LOG(ERROR) << "Texture blit fallback not implemented yet for GLES2.";
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

  gl.BlitFramebuffer(source_region.origin.x,     // srcX0
                     source_region.origin.y,     // srcY0
                     source_region.size.width,   // srcX1
                     source_region.size.height,  // srcY1
                     destination_origin.x,       // dstX0
                     destination_origin.y,       // dstY0
                     source_region.size.width,   // dstX1
                     source_region.size.height,  // dstY1
                     GL_COLOR_BUFFER_BIT,        // mask
                     GL_NEAREST                  // filter
  );

  return true;
};

BlitCopyTextureToBufferCommandGLES::~BlitCopyTextureToBufferCommandGLES() =
    default;

std::string BlitCopyTextureToBufferCommandGLES::GetLabel() const {
  return label;
}

bool BlitCopyTextureToBufferCommandGLES::Encode(
    const ReactorGLES& reactor) const {
  if (source->GetTextureDescriptor().format != PixelFormat::kR8G8B8A8UNormInt) {
    VALIDATION_LOG << "Only textures with pixel format RGBA are supported yet.";
    return false;
  }

  const auto& gl = reactor.GetProcTable();

  GLuint read_fbo = GL_NONE;
  fml::ScopedCleanupClosure delete_fbos(
      [&gl, &read_fbo]() { DeleteFBO(gl, read_fbo, GL_READ_FRAMEBUFFER); });

  {
    auto read = ConfigureFBO(gl, source, GL_READ_FRAMEBUFFER);
    if (!read.has_value()) {
      return false;
    }
    read_fbo = read.value();
  }

  DeviceBufferGLES::Cast(*destination)
      .UpdateBufferData([&gl, this](uint8_t* data, size_t length) {
        gl.ReadPixels(source_region.origin.x, source_region.origin.y,
                      source_region.size.width, source_region.size.height,
                      GL_RGBA, GL_UNSIGNED_BYTE, data + destination_offset);
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

}  // namespace impeller

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/capabilities_gles.h"

#include "impeller/renderer/backend/gles/proc_table_gles.h"

namespace impeller {

// https://registry.khronos.org/OpenGL/extensions/EXT/EXT_shader_framebuffer_fetch.txt
static const constexpr char* kFramebufferFetchExt =
    "GL_EXT_shader_framebuffer_fetch";

static const constexpr char* kTextureBorderClampExt =
    "GL_EXT_texture_border_clamp";
static const constexpr char* kNvidiaTextureBorderClampExt =
    "GL_NV_texture_border_clamp";
static const constexpr char* kOESTextureBorderClampExt =
    "GL_OES_texture_border_clamp";

CapabilitiesGLES::CapabilitiesGLES(const ProcTableGLES& gl) {
  {
    GLint value = 0;
    gl.GetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, &value);
    max_combined_texture_image_units = value;
  }

  {
    GLint value = 0;
    gl.GetIntegerv(GL_MAX_CUBE_MAP_TEXTURE_SIZE, &value);
    max_cube_map_texture_size = value;
  }

  if (gl.GetDescription()->IsES()) {
    GLint value = 0;
    gl.GetIntegerv(GL_MAX_FRAGMENT_UNIFORM_VECTORS, &value);
    max_fragment_uniform_vectors = value;
  }

  {
    GLint value = 0;
    gl.GetIntegerv(GL_MAX_RENDERBUFFER_SIZE, &value);
    max_renderbuffer_size = value;
  }

  {
    GLint value = 0;
    gl.GetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &value);
    max_texture_image_units = value;
  }

  {
    GLint value = 0;
    gl.GetIntegerv(GL_MAX_TEXTURE_SIZE, &value);
    max_texture_size = ISize{value, value};
  }

  if (gl.GetDescription()->IsES()) {
    GLint value = 0;
    gl.GetIntegerv(GL_MAX_VARYING_VECTORS, &value);
    max_varying_vectors = value;
  }

  {
    GLint value = 0;
    gl.GetIntegerv(GL_MAX_VERTEX_ATTRIBS, &value);
    max_vertex_attribs = value;
  }

  {
    GLint value = 0;
    gl.GetIntegerv(GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS, &value);
    max_vertex_texture_image_units = value;
  }

  if (gl.GetDescription()->IsES()) {
    GLint value = 0;
    gl.GetIntegerv(GL_MAX_VERTEX_UNIFORM_VECTORS, &value);
    max_vertex_uniform_vectors = value;
  }

  {
    GLint values[2] = {};
    gl.GetIntegerv(GL_MAX_VIEWPORT_DIMS, values);
    max_viewport_dims = ISize{values[0], values[1]};
  }

  {
    GLint value = 0;
    gl.GetIntegerv(GL_NUM_COMPRESSED_TEXTURE_FORMATS, &value);
    num_compressed_texture_formats = value;
  }

  if (gl.GetDescription()->IsES()) {
    GLint value = 0;
    gl.GetIntegerv(GL_NUM_SHADER_BINARY_FORMATS, &value);
    num_shader_binary_formats = value;
  }

  supports_framebuffer_fetch_ =
      gl.GetDescription()->HasExtension(kFramebufferFetchExt);

  if (gl.GetDescription()->HasExtension(kTextureBorderClampExt) ||
      gl.GetDescription()->HasExtension(kNvidiaTextureBorderClampExt) ||
      gl.GetDescription()->HasExtension(kOESTextureBorderClampExt)) {
    supports_decal_sampler_address_mode_ = true;
  }
}

size_t CapabilitiesGLES::GetMaxTextureUnits(ShaderStage stage) const {
  switch (stage) {
    case ShaderStage::kVertex:
      return max_vertex_texture_image_units;
    case ShaderStage::kFragment:
      return max_texture_image_units;
    case ShaderStage::kUnknown:
    case ShaderStage::kTessellationControl:
    case ShaderStage::kTessellationEvaluation:
    case ShaderStage::kCompute:
      return 0u;
  }
  FML_UNREACHABLE();
}

bool CapabilitiesGLES::SupportsOffscreenMSAA() const {
  return false;
}

bool CapabilitiesGLES::SupportsSSBO() const {
  return false;
}

bool CapabilitiesGLES::SupportsBufferToTextureBlits() const {
  return false;
}

bool CapabilitiesGLES::SupportsTextureToTextureBlits() const {
  return false;
}

bool CapabilitiesGLES::SupportsFramebufferFetch() const {
  return supports_framebuffer_fetch_;
}

bool CapabilitiesGLES::SupportsCompute() const {
  return false;
}

bool CapabilitiesGLES::SupportsComputeSubgroups() const {
  return false;
}

bool CapabilitiesGLES::SupportsReadFromOnscreenTexture() const {
  return false;
}

bool CapabilitiesGLES::SupportsReadFromResolve() const {
  return false;
}

bool CapabilitiesGLES::SupportsDecalSamplerAddressMode() const {
  return supports_decal_sampler_address_mode_;
}

bool CapabilitiesGLES::SupportsDeviceTransientTextures() const {
  return false;
}

PixelFormat CapabilitiesGLES::GetDefaultColorFormat() const {
  return PixelFormat::kR8G8B8A8UNormInt;
}

PixelFormat CapabilitiesGLES::GetDefaultStencilFormat() const {
  return PixelFormat::kS8UInt;
}

PixelFormat CapabilitiesGLES::GetDefaultDepthStencilFormat() const {
  return PixelFormat::kD24UnormS8Uint;
}

}  // namespace impeller

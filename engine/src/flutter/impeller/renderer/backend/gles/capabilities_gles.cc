// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/capabilities_gles.h"

#include "impeller/core/formats.h"
#include "impeller/renderer/backend/gles/proc_table_gles.h"

namespace impeller {

// https://registry.khronos.org/OpenGL/extensions/EXT/EXT_shader_framebuffer_fetch.txt
static const constexpr char* kFramebufferFetchExt =
    "GL_EXT_shader_framebuffer_fetch";

static const constexpr char* kTextureBorderClampExt =
    "GL_EXT_texture_border_clamp";
static const constexpr char* kNvidiaTextureBorderClampExt =
    "GL_NV_texture_border_clamp";

// https://www.khronos.org/registry/OpenGL/extensions/EXT/EXT_multisampled_render_to_texture.txt
static const constexpr char* kMultisampledRenderToTextureExt =
    "GL_EXT_multisampled_render_to_texture";

// https://registry.khronos.org/OpenGL/extensions/EXT/EXT_multisampled_render_to_texture2.txt
static const constexpr char* kMultisampledRenderToTexture2Ext =
    "GL_EXT_multisampled_render_to_texture2";

// https://registry.khronos.org/OpenGL/extensions/OES/OES_element_index_uint.txt
static const constexpr char* kElementIndexUintExt = "GL_OES_element_index_uint";

// The BC family spans three separate OpenGL ES extensions: S3TC (BC1-BC3),
// RGTC (BC5), and BPTC (BC7). All three are required to report kBC support.
// https://registry.khronos.org/OpenGL/extensions/EXT/EXT_texture_compression_s3tc.txt
static const constexpr char* kTextureCompressionS3TCExt =
    "GL_EXT_texture_compression_s3tc";
// https://registry.khronos.org/OpenGL/extensions/EXT/EXT_texture_compression_rgtc.txt
static const constexpr char* kTextureCompressionRGTCExt =
    "GL_EXT_texture_compression_rgtc";
// https://registry.khronos.org/OpenGL/extensions/EXT/EXT_texture_compression_bptc.txt
static const constexpr char* kTextureCompressionBPTCExt =
    "GL_EXT_texture_compression_bptc";

// https://registry.khronos.org/OpenGL/extensions/KHR/KHR_texture_compression_astc_hdr.txt
static const constexpr char* kTextureCompressionAstcLdrExt =
    "GL_KHR_texture_compression_astc_ldr";
// https://registry.khronos.org/OpenGL/extensions/OES/OES_texture_compression_astc.txt
static const constexpr char* kTextureCompressionAstcOesExt =
    "GL_OES_texture_compression_astc";
// https://registry.khronos.org/OpenGL/extensions/KHR/KHR_texture_compression_astc_hdr.txt
static const constexpr char* kTextureCompressionAstcHdrExt =
    "GL_KHR_texture_compression_astc_hdr";

// https://registry.khronos.org/OpenGL/extensions/APPLE/APPLE_texture_max_level.txt
static const constexpr char* kAppleTextureMaxLevelExt =
    "GL_APPLE_texture_max_level";

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

  auto const desc = gl.GetDescription();

  if (desc->IsES()) {
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

  if (desc->IsES()) {
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

  if (desc->IsES()) {
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

  if (desc->IsES()) {
    GLint value = 0;
    gl.GetIntegerv(GL_NUM_SHADER_BINARY_FORMATS, &value);
    num_shader_binary_formats = value;
  }

  if (desc->IsES()) {
    default_glyph_atlas_format_ = PixelFormat::kA8UNormInt;
  } else {
    default_glyph_atlas_format_ = PixelFormat::kR8UNormInt;
  }

  if (desc->GetGlVersion().major_version >= 3) {
    supports_texture_to_texture_blits_ = true;
  }

  supports_framebuffer_fetch_ = desc->HasExtension(kFramebufferFetchExt);

  if (desc->HasExtension(kTextureBorderClampExt) ||
      desc->HasExtension(kNvidiaTextureBorderClampExt)) {
    supports_decal_sampler_address_mode_ = true;
  }

  if (desc->HasExtension(kElementIndexUintExt)) {
    supports_32bit_primitive_indices_ = true;
  }

  if (desc->HasExtension(kMultisampledRenderToTextureExt)) {
    supports_implicit_msaa_ = true;

    if (desc->HasExtension(kMultisampledRenderToTexture2Ext)) {
      // We hard-code 4x MSAA, so let's make sure it's supported.
      GLint value = 0;
      gl.GetIntegerv(GL_MAX_SAMPLES_EXT, &value);
      supports_offscreen_msaa_ = value >= 4;
    }
  } else if (desc->GetGlVersion().major_version >= 3 && desc->IsES()) {
    GLint value = 0;
    gl.GetIntegerv(GL_MAX_SAMPLES, &value);
    supports_offscreen_msaa_ = value >= 4;
  }
  is_es_ = desc->IsES();
  is_angle_ = desc->IsANGLE();

  // ETC2 and EAC are mandatory in OpenGL ES 3.0. BC and ASTC are gated behind
  // extensions and are not present on most mobile or desktop GLES. The whole BC
  // family requires S3TC, RGTC, and BPTC to all be present.
  supports_texture_compression_bc_ =
      desc->HasExtension(kTextureCompressionS3TCExt) &&
      desc->HasExtension(kTextureCompressionRGTCExt) &&
      desc->HasExtension(kTextureCompressionBPTCExt);
  // Either extension is sufficient: both expose the same LDR 2D ASTC internal
  // formats this backend uses. KHR is the common one; OES is a superset that
  // also adds HDR and 3D, which are not used here.
  supports_texture_compression_astc_ =
      desc->HasExtension(kTextureCompressionAstcLdrExt) ||
      desc->HasExtension(kTextureCompressionAstcOesExt);
  // HDR reuses the same internal formats as LDR, gated by a separate extension.
  // The OES extension is a superset that also covers HDR.
  supports_texture_compression_astc_hdr_ =
      desc->HasExtension(kTextureCompressionAstcHdrExt) ||
      desc->HasExtension(kTextureCompressionAstcOesExt);
  supports_texture_compression_etc2_ =
      desc->IsES() && desc->GetGlVersion().major_version >= 3;

  // GL_TEXTURE_MAX_LEVEL is core on desktop GL and ES 3.0+, and available on
  // ES 2.0 through GL_APPLE_texture_max_level.
  supports_texture_max_level_ = !desc->IsES() ||
                                desc->GetGlVersion().major_version >= 3 ||
                                desc->HasExtension(kAppleTextureMaxLevelExt);
}

bool CapabilitiesGLES::IsES() const {
  return is_es_;
}

bool CapabilitiesGLES::SupportsFramebufferRenderMipmap() const {
  // Rendering into a non-zero mip level is not yet supported on the GLES
  // backend. The texture storage path allocates levels with mutable, lazily
  // allocated glTexImage2D storage, which yields an incomplete framebuffer
  // when a non-base mip level is attached. Until that is reworked, do not
  // advertise the capability so callers fall back instead of failing to
  // create the framebuffer. Rendering into a cube map face is unaffected.
  return false;
}

bool CapabilitiesGLES::SupportsTextureMaxLevel() const {
  return supports_texture_max_level_;
}

size_t CapabilitiesGLES::GetMaxTextureUnits(ShaderStage stage) const {
  switch (stage) {
    case ShaderStage::kVertex:
      return max_vertex_texture_image_units;
    case ShaderStage::kFragment:
      return max_texture_image_units;
    case ShaderStage::kUnknown:
    case ShaderStage::kCompute:
      return 0u;
  }
  FML_UNREACHABLE();
}

bool CapabilitiesGLES::SupportsOffscreenMSAA() const {
  return supports_offscreen_msaa_;
}

bool CapabilitiesGLES::SupportsImplicitResolvingMSAA() const {
  return supports_implicit_msaa_;
}

bool CapabilitiesGLES::SupportsSSBO() const {
  return false;
}

bool CapabilitiesGLES::SupportsTextureToTextureBlits() const {
  return supports_texture_to_texture_blits_;
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

bool CapabilitiesGLES::SupportsReadFromResolve() const {
  return false;
}

bool CapabilitiesGLES::SupportsDecalSamplerAddressMode() const {
  return supports_decal_sampler_address_mode_;
}

bool CapabilitiesGLES::SupportsDeviceTransientTextures() const {
  return false;
}

bool CapabilitiesGLES::SupportsTriangleFan() const {
  return true;
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

bool CapabilitiesGLES::IsANGLE() const {
  return is_angle_;
}

bool CapabilitiesGLES::SupportsPrimitiveRestart() const {
  return false;
}

bool CapabilitiesGLES::Supports32BitPrimitiveIndices() const {
  return supports_32bit_primitive_indices_;
}

bool CapabilitiesGLES::SupportsManuallyMippedTextures() const {
  // Without GL_TEXTURE_MAX_LEVEL the sampled mip range cannot be bounded to
  // the levels the texture declares, so a hand-uploaded chain is mipmap
  // incomplete and samples as black.
  return supports_texture_max_level_;
}

bool CapabilitiesGLES::SupportsExtendedRangeFormats() const {
  return false;
}

bool CapabilitiesGLES::SupportsTextureCompression(
    CompressedTextureFamily family) const {
  switch (family) {
    case CompressedTextureFamily::kBC:
      return supports_texture_compression_bc_;
    case CompressedTextureFamily::kETC2:
      return supports_texture_compression_etc2_;
    case CompressedTextureFamily::kASTC:
      return supports_texture_compression_astc_;
    case CompressedTextureFamily::kASTCHDR:
      return supports_texture_compression_astc_hdr_;
  }
  return false;
}

PixelFormat CapabilitiesGLES::GetDefaultGlyphAtlasFormat() const {
  return default_glyph_atlas_format_;
}

ISize CapabilitiesGLES::GetMaximumRenderPassAttachmentSize() const {
  return max_texture_size;
}

size_t CapabilitiesGLES::GetMinimumUniformAlignment() const {
  return 256;
}

bool CapabilitiesGLES::NeedsPartitionedHostBuffer() const {
#ifdef FML_OS_EMSCRIPTEN
  // WebGL has special requirements here to keep indexes and other data
  // separate. See
  // https://registry.khronos.org/webgl/specs/latest/2.0/#BUFFER_OBJECT_BINDING
  return true;
#else
  return false;
#endif
}

}  // namespace impeller

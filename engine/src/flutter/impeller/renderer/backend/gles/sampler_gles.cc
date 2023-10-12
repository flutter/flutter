// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/sampler_gles.h"

#include <iostream>

#include "impeller/base/validation.h"
#include "impeller/core/formats.h"
#include "impeller/renderer/backend/gles/formats_gles.h"
#include "impeller/renderer/backend/gles/proc_table_gles.h"
#include "impeller/renderer/backend/gles/texture_gles.h"

namespace impeller {

SamplerGLES::SamplerGLES(SamplerDescriptor desc) : Sampler(std::move(desc)) {}

SamplerGLES::~SamplerGLES() = default;

bool SamplerGLES::IsValid() const {
  return true;
}

static GLint ToParam(MinMagFilter minmag_filter,
                     std::optional<MipFilter> mip_filter = std::nullopt) {
  if (!mip_filter.has_value()) {
    switch (minmag_filter) {
      case MinMagFilter::kNearest:
        return GL_NEAREST;
      case MinMagFilter::kLinear:
        return GL_LINEAR;
    }
    FML_UNREACHABLE();
  }

  switch (mip_filter.value()) {
    case MipFilter::kNearest:
      switch (minmag_filter) {
        case MinMagFilter::kNearest:
          return GL_NEAREST_MIPMAP_NEAREST;
        case MinMagFilter::kLinear:
          return GL_LINEAR_MIPMAP_NEAREST;
      }
    case MipFilter::kLinear:
      switch (minmag_filter) {
        case MinMagFilter::kNearest:
          return GL_NEAREST_MIPMAP_LINEAR;
        case MinMagFilter::kLinear:
          return GL_LINEAR_MIPMAP_LINEAR;
      }
  }
  FML_UNREACHABLE();
}

static GLint ToAddressMode(SamplerAddressMode mode,
                           bool supports_decal_sampler_address_mode) {
  switch (mode) {
    case SamplerAddressMode::kClampToEdge:
      return GL_CLAMP_TO_EDGE;
    case SamplerAddressMode::kRepeat:
      return GL_REPEAT;
    case SamplerAddressMode::kMirror:
      return GL_MIRRORED_REPEAT;
    case SamplerAddressMode::kDecal:
      if (supports_decal_sampler_address_mode) {
        return IMPELLER_GL_CLAMP_TO_BORDER;
      } else {
        return GL_CLAMP_TO_EDGE;
      }
  }
  FML_UNREACHABLE();
}

bool SamplerGLES::ConfigureBoundTexture(const TextureGLES& texture,
                                        const ProcTableGLES& gl) const {
  if (!IsValid()) {
    return false;
  }

  if (texture.NeedsMipmapGeneration()) {
    VALIDATION_LOG
        << "Texture mip count is > 1, but the mipmap has not been generated. "
           "Texture can not be sampled safely.";
    return false;
  }

  auto target = ToTextureTarget(texture.GetTextureDescriptor().type);

  if (!target.has_value()) {
    return false;
  }
  const auto& desc = GetDescriptor();

  std::optional<MipFilter> mip_filter = std::nullopt;
  if (texture.GetTextureDescriptor().mip_count > 1) {
    mip_filter = desc.mip_filter;
  }

  gl.TexParameteri(*target, GL_TEXTURE_MIN_FILTER,
                   ToParam(desc.min_filter, mip_filter));
  gl.TexParameteri(*target, GL_TEXTURE_MAG_FILTER, ToParam(desc.mag_filter));

  const auto supports_decal_mode =
      gl.GetCapabilities()->SupportsDecalSamplerAddressMode();

  const auto wrap_s =
      ToAddressMode(desc.width_address_mode, supports_decal_mode);
  const auto wrap_t =
      ToAddressMode(desc.height_address_mode, supports_decal_mode);

  gl.TexParameteri(*target, GL_TEXTURE_WRAP_S, wrap_s);
  gl.TexParameteri(*target, GL_TEXTURE_WRAP_T, wrap_t);

  if (wrap_s == IMPELLER_GL_CLAMP_TO_BORDER ||
      wrap_t == IMPELLER_GL_CLAMP_TO_BORDER) {
    // Transparent black.
    const GLfloat border_color[4] = {0.0f, 0.0f, 0.0f, 0.0f};
    gl.TexParameterfv(*target, IMPELLER_GL_TEXTURE_BORDER_COLOR, border_color);
  }

  return true;
}

}  // namespace impeller

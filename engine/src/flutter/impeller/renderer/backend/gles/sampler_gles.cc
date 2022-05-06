// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/sampler_gles.h"

#include "impeller/renderer/backend/gles/proc_table_gles.h"

namespace impeller {

SamplerGLES::SamplerGLES(SamplerDescriptor desc) : Sampler(std::move(desc)) {}

SamplerGLES::~SamplerGLES() = default;

bool SamplerGLES::IsValid() const {
  return true;
}

static GLint ToParam(MinMagFilter filter) {
  switch (filter) {
    case MinMagFilter::kNearest:
      return GL_NEAREST;
    case MinMagFilter::kLinear:
      return GL_LINEAR;
  }
  FML_UNREACHABLE();
}

static GLint ToAddressMode(SamplerAddressMode mode) {
  switch (mode) {
    case SamplerAddressMode::kClampToEdge:
      return GL_CLAMP_TO_EDGE;
    case SamplerAddressMode::kRepeat:
      return GL_REPEAT;
    case SamplerAddressMode::kMirror:
      return GL_MIRRORED_REPEAT;
  }
  FML_UNREACHABLE();
}

bool SamplerGLES::ConfigureBoundTexture(const ProcTableGLES& gl) const {
  if (!IsValid()) {
    return false;
  }

  const auto& desc = GetDescriptor();
  gl.TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
                   ToParam(desc.min_filter));
  gl.TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
                   ToParam(desc.mag_filter));
  gl.TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,
                   ToAddressMode(desc.width_address_mode));
  gl.TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,
                   ToAddressMode(desc.height_address_mode));
  return true;
}

}  // namespace impeller

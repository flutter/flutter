// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/sampler_library_gles.h"

#include "impeller/base/config.h"
#include "impeller/base/validation.h"
#include "impeller/core/formats.h"
#include "impeller/renderer/backend/gles/sampler_gles.h"

namespace impeller {

SamplerLibraryGLES::SamplerLibraryGLES() = default;

// |SamplerLibrary|
SamplerLibraryGLES::~SamplerLibraryGLES() = default;

// |SamplerLibrary|
std::shared_ptr<const Sampler> SamplerLibraryGLES::GetSampler(
    SamplerDescriptor descriptor) {
  // TODO(bdero): Change this validation once optional support for kDecal is
  //              added to the OpenGLES backend:
  //              https://github.com/flutter/flutter/issues/129358
  if (descriptor.width_address_mode == SamplerAddressMode::kDecal ||
      descriptor.height_address_mode == SamplerAddressMode::kDecal ||
      descriptor.depth_address_mode == SamplerAddressMode::kDecal) {
    VALIDATION_LOG << "SamplerAddressMode::kDecal is not supported by the "
                      "OpenGLES backend.";
    return nullptr;
  }

  auto found = samplers_.find(descriptor);
  if (found != samplers_.end()) {
    return found->second;
  }
  return samplers_[descriptor] =
             std::shared_ptr<SamplerGLES>(new SamplerGLES(descriptor));
}

}  // namespace impeller

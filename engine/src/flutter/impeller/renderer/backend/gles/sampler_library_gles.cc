// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/sampler_library_gles.h"

#include "impeller/base/config.h"
#include "impeller/base/validation.h"
#include "impeller/core/formats.h"
#include "impeller/renderer/backend/gles/sampler_gles.h"

namespace impeller {

static const std::unique_ptr<const Sampler> kNullSampler = nullptr;

SamplerLibraryGLES::SamplerLibraryGLES(bool supports_decal_sampler_address_mode)
    : supports_decal_sampler_address_mode_(
          supports_decal_sampler_address_mode) {}

// |SamplerLibrary|
SamplerLibraryGLES::~SamplerLibraryGLES() = default;

// |SamplerLibrary|
const std::unique_ptr<const Sampler>& SamplerLibraryGLES::GetSampler(
    SamplerDescriptor descriptor) {
  if (!supports_decal_sampler_address_mode_ &&
      (descriptor.width_address_mode == SamplerAddressMode::kDecal ||
       descriptor.height_address_mode == SamplerAddressMode::kDecal ||
       descriptor.depth_address_mode == SamplerAddressMode::kDecal)) {
    VALIDATION_LOG << "SamplerAddressMode::kDecal is not supported by the "
                      "current OpenGLES backend.";
    return kNullSampler;
  }

  auto found = samplers_.find(descriptor);
  if (found != samplers_.end()) {
    return found->second;
  }
  return (samplers_[descriptor] =
              std::unique_ptr<SamplerGLES>(new SamplerGLES(descriptor)));
}

}  // namespace impeller

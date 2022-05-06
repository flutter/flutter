// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/sampler_library_gles.h"

#include "impeller/base/config.h"
#include "impeller/renderer/backend/gles/sampler_gles.h"

namespace impeller {

SamplerLibraryGLES::SamplerLibraryGLES() = default;

// |SamplerLibrary|
SamplerLibraryGLES::~SamplerLibraryGLES() = default;

// |SamplerLibrary|
std::shared_ptr<const Sampler> SamplerLibraryGLES::GetSampler(
    SamplerDescriptor descriptor) {
  auto found = samplers_.find(descriptor);
  if (found != samplers_.end()) {
    return found->second;
  }
  return samplers_[std::move(descriptor)] =
             std::shared_ptr<SamplerGLES>(new SamplerGLES(descriptor));
}

}  // namespace impeller

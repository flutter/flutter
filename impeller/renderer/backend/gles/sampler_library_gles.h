// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/renderer/sampler_library.h"

namespace impeller {

class SamplerLibraryGLES final : public SamplerLibrary {
 public:
  explicit SamplerLibraryGLES(bool supports_decal_sampler_address_mode);
  // |SamplerLibrary|
  ~SamplerLibraryGLES() override;

 private:
  friend class ContextGLES;

  SamplerMap samplers_;

  SamplerLibraryGLES();

  // |SamplerLibrary|
  std::shared_ptr<const Sampler> GetSampler(
      SamplerDescriptor descriptor) override;

  bool supports_decal_sampler_address_mode_ = false;

  SamplerLibraryGLES(const SamplerLibraryGLES&) = delete;

  SamplerLibraryGLES& operator=(const SamplerLibraryGLES&) = delete;
};

}  // namespace impeller

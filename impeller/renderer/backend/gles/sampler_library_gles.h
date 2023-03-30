// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/renderer/sampler_descriptor.h"
#include "impeller/renderer/sampler_library.h"

namespace impeller {

class SamplerLibraryGLES final : public SamplerLibrary {
 public:
  // |SamplerLibrary|
  ~SamplerLibraryGLES() override;

 private:
  friend class ContextGLES;

  SamplerMap samplers_;

  SamplerLibraryGLES();

  // |SamplerLibrary|
  std::shared_ptr<const Sampler> GetSampler(
      SamplerDescriptor descriptor) override;

  FML_DISALLOW_COPY_AND_ASSIGN(SamplerLibraryGLES);
};

}  // namespace impeller

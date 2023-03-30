// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/base/backend_cast.h"
#include "impeller/core/sampler.h"

namespace impeller {

class TextureGLES;
class SamplerLibraryGLES;
class ProcTableGLES;

class SamplerGLES final : public Sampler,
                          public BackendCast<SamplerGLES, Sampler> {
 public:
  ~SamplerGLES();

  bool ConfigureBoundTexture(const TextureGLES& texture,
                             const ProcTableGLES& gl) const;

 private:
  friend class SamplerLibraryGLES;

  SamplerGLES(SamplerDescriptor desc);

  // |Sampler|
  bool IsValid() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(SamplerGLES);
};

}  // namespace impeller

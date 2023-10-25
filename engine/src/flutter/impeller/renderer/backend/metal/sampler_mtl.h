// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include "flutter/fml/macros.h"
#include "impeller/base/backend_cast.h"
#include "impeller/core/sampler.h"

namespace impeller {

class SamplerLibraryMTL;

class SamplerMTL final : public Sampler,
                         public BackendCast<SamplerMTL, Sampler> {
 public:
  SamplerMTL();

  // |Sampler|
  ~SamplerMTL() override;

  id<MTLSamplerState> GetMTLSamplerState() const;

 private:
  friend SamplerLibraryMTL;

  id<MTLSamplerState> state_ = nullptr;

  SamplerMTL(SamplerDescriptor desc, id<MTLSamplerState> state);

  // |Sampler|
  bool IsValid() const override;

  SamplerMTL(const SamplerMTL&) = delete;

  SamplerMTL& operator=(const SamplerMTL&) = delete;
};

}  // namespace impeller

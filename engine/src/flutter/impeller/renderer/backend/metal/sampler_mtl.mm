// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/sampler_mtl.h"

namespace impeller {

SamplerMTL::SamplerMTL(SamplerDescriptor desc, id<MTLSamplerState> state)
    : Sampler(std::move(desc)), state_(state) {}

SamplerMTL::~SamplerMTL() = default;

bool SamplerMTL::IsValid() const {
  return state_;
}

id<MTLSamplerState> SamplerMTL::GetMTLSamplerState() const {
  return state_;
}

}  // namespace impeller

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/sampler.h"

namespace impeller {

Sampler::Sampler(id<MTLSamplerState> state) : state_(state) {}

Sampler::~Sampler() = default;

bool Sampler::IsValid() const {
  return state_;
}

id<MTLSamplerState> Sampler::GetMTLSamplerState() const {
  return state_;
}

}  // namespace impeller

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/base/backend_cast.h"
#include "impeller/renderer/sampler.h"

namespace impeller {

class SamplerLibraryVK;

class SamplerVK final : public Sampler, public BackendCast<SamplerVK, Sampler> {
 public:
  SamplerVK();

  // |Sampler|
  ~SamplerVK() override;

 private:
  friend SamplerLibraryVK;

  SamplerVK(SamplerDescriptor desc);

  // |Sampler|
  bool IsValid() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(SamplerVK);
};

}  // namespace impeller

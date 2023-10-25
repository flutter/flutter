// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/core/sampler_descriptor.h"

namespace impeller {

class Sampler {
 public:
  virtual ~Sampler();

  virtual bool IsValid() const = 0;

  const SamplerDescriptor& GetDescriptor() const;

 protected:
  SamplerDescriptor desc_;

  explicit Sampler(SamplerDescriptor desc);

 private:
  Sampler(const Sampler&) = delete;

  Sampler& operator=(const Sampler&) = delete;
};

}  // namespace impeller

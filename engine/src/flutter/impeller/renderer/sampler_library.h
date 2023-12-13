// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_SAMPLER_LIBRARY_H_
#define FLUTTER_IMPELLER_RENDERER_SAMPLER_LIBRARY_H_

#include "impeller/core/sampler.h"
#include "impeller/core/sampler_descriptor.h"

namespace impeller {

class SamplerLibrary {
 public:
  virtual ~SamplerLibrary();

  virtual std::shared_ptr<const Sampler> GetSampler(
      SamplerDescriptor descriptor) = 0;

 protected:
  SamplerLibrary();

 private:
  SamplerLibrary(const SamplerLibrary&) = delete;

  SamplerLibrary& operator=(const SamplerLibrary&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_SAMPLER_LIBRARY_H_

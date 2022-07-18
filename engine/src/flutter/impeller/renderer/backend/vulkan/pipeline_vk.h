// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/base/backend_cast.h"
#include "impeller/renderer/pipeline.h"

namespace impeller {

class PipelineVK final : public Pipeline,
                         public BackendCast<PipelineVK, Pipeline> {
 public:
  // |Pipeline|
  ~PipelineVK() override;

 private:
  friend class PipelineLibraryMTL;

  PipelineVK(std::weak_ptr<PipelineLibrary> library, PipelineDescriptor desc);

  // |Pipeline|
  bool IsValid() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(PipelineVK);
};

}  // namespace impeller

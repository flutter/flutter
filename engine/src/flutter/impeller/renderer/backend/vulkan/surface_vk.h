// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/surface.h"

namespace impeller {

class SurfaceVK final : public Surface {
 public:
  // |Surface|
  ~SurfaceVK() override;

 private:
  SurfaceVK(RenderTarget target);

  // |Surface|
  bool Present() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(SurfaceVK);
};

}  // namespace impeller

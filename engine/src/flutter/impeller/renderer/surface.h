// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include <functional>
#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

class Surface {
 public:
  Surface(RenderPassDescriptor target_desc);

  ~Surface();

  const ISize& GetSize() const;

  bool IsValid() const;

  const RenderPassDescriptor& GetTargetRenderPassDescriptor() const;

 private:
  RenderPassDescriptor desc_;
  ISize size_;

  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(Surface);
};

}  // namespace impeller

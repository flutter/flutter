// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include <functional>
#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/compositor/context.h"
#include "impeller/compositor/render_pass.h"

namespace impeller {

class Surface {
 public:
  Surface(RenderPassDescriptor desc,
          std::function<bool(void)> present_callback);

  ~Surface();

  const Size& GetSize() const;

  bool Present() const;

  bool IsValid() const;

  const RenderPassDescriptor& GetRenderPassDescriptor() const;

 private:
  RenderPassDescriptor desc_;
  std::function<bool(void)> present_callback_;
  Size size_;

  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(Surface);
};

}  // namespace impeller

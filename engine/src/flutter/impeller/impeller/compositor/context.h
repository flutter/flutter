// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include "flutter/fml/macros.h"

namespace impeller {

class Context {
 public:
  Context();

  ~Context();

  bool IsValid() const;

 private:
  id<MTLDevice> device_;
  id<MTLCommandQueue> render_queue_;
  id<MTLCommandQueue> transfer_queue_;

  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(Context);
};

}  // namespace impeller

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "context.h"

#include "flutter/fml/logging.h"

namespace impeller {

Context::Context() : device_(::MTLCreateSystemDefaultDevice()) {
  if (!device_) {
    return;
  }

  render_queue_ = device_.newCommandQueue;
  transfer_queue_ = device_.newCommandQueue;

  if (!render_queue_ || !transfer_queue_) {
    return;
  }

  render_queue_.label = @"Impeller Render Queue";
  transfer_queue_.label = @"Impeller Transfer Queue";

  is_valid_ = true;
}

Context::~Context() = default;

bool Context::IsValid() const {
  return is_valid_;
}

id<MTLCommandQueue> Context::GetRenderQueue() const {
  return render_queue_;
}

id<MTLCommandQueue> Context::GetTransferQueue() const {
  return transfer_queue_;
}

}  // namespace impeller

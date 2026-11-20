// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/core/buffer_view.h"

namespace impeller {

std::shared_ptr<const DeviceBuffer> BufferView::TakeBuffer() {
  if (buffer_) {
    raw_buffer_ = buffer_.get();
    return std::move(buffer_);
  } else {
    return nullptr;
  }
}

}  // namespace impeller

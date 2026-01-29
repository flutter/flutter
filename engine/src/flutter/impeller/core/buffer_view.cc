// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/core/buffer_view.h"

#include "fml/logging.h"

namespace impeller {

BufferView::BufferView() : buffer_(nullptr), raw_buffer_({}), range_({}) {}

BufferView BufferView::CreateFromWeakDeviceBuffer(
    std::weak_ptr<const DeviceBuffer> buffer,
    Range range) {
  return {std::move(buffer), range};
}

BufferView BufferView::CreateFromSharedDeviceBuffer(
    std::shared_ptr<const DeviceBuffer> buffer,
    Range range) {
  return {std::move(buffer), range};
}

BufferView::BufferView(std::weak_ptr<const DeviceBuffer> buffer, Range range)
    : buffer_(), raw_buffer_(std::move(buffer)), range_(range) {}

BufferView::BufferView(std::shared_ptr<const DeviceBuffer> buffer, Range range)
    : buffer_(std::move(buffer)), raw_buffer_({}), range_(range) {}

const DeviceBuffer* BufferView::GetBuffer() const {
  if (!raw_buffer_.expired()) {
    return raw_buffer_.lock().get();
  }
  if (buffer_) {
    return buffer_.get();
  }
  FML_DCHECK(false) << "Buffer view no longer holds valid data";
  return nullptr;
}

std::shared_ptr<const DeviceBuffer> BufferView::TakeBuffer() {
  if (buffer_) {
    raw_buffer_ = buffer_;
    return std::move(buffer_);
  } else {
    return nullptr;
  }
}

BufferView::operator bool() const {
  return buffer_ || !raw_buffer_.expired();
}

}  // namespace impeller

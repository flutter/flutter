// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_CORE_BUFFER_VIEW_H_
#define FLUTTER_IMPELLER_CORE_BUFFER_VIEW_H_

#include <memory>
#include <utility>

#include "impeller/core/range.h"

namespace impeller {

class DeviceBuffer;

/// A specific range in a DeviceBuffer.
///
/// BufferView can maintain ownership over the DeviceBuffer or not depending on
/// if it is created with a std::shared_ptr or a raw pointer.
struct BufferView {
 public:
  BufferView() = default;

  BufferView(const DeviceBuffer* buffer, Range range)
      : raw_buffer_(buffer), range_(range) {}

  BufferView(std::shared_ptr<const DeviceBuffer> buffer, Range range)
      : buffer_(std::move(buffer)), range_(range) {}

  Range GetRange() const { return range_; }

  const DeviceBuffer* GetBuffer() const {
    return raw_buffer_ ? raw_buffer_ : buffer_.get();
  }

  std::shared_ptr<const DeviceBuffer> TakeBuffer();

  explicit operator bool() const { return buffer_ || raw_buffer_; }

 private:
  std::shared_ptr<const DeviceBuffer> buffer_;
  /// This is a non-owned DeviceBuffer. Steps should be taken to make sure this
  /// lives for the duration of the BufferView's life. Usually this is done
  /// automatically by the graphics API or in the case of Vulkan the HostBuffer
  /// or TrackedObjectsVK keeps it alive.
  const DeviceBuffer* raw_buffer_ = nullptr;
  Range range_ = {};
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_CORE_BUFFER_VIEW_H_

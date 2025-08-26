// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_CORE_SIMPLE_HOST_BUFFER_H_
#define FLUTTER_IMPELLER_CORE_SIMPLE_HOST_BUFFER_H_

#include "impeller/core/host_buffer.h"

namespace impeller {

class SimpleHostBuffer : public HostBuffer {
 public:
  explicit SimpleHostBuffer(
      const std::shared_ptr<Allocator>& allocator,
      const std::shared_ptr<const IdleWaiter>& idle_waiter,
      size_t minimum_uniform_alignment);
  virtual ~SimpleHostBuffer() override;
  [[nodiscard]] virtual BufferView Emplace(const void* buffer,
                                           size_t length,
                                           size_t align,
                                           BufferCategory category) override;
  virtual BufferView Emplace(size_t length,
                             size_t align,
                             BufferCategory category,
                             const EmplaceProc& cb) override;
  virtual size_t GetMinimumUniformAlignment() const override;
  virtual void Reset() override;
  virtual TestStateQuery GetStateForTest(BufferCategory category) override;

 private:
  [[nodiscard]] std::tuple<Range, std::shared_ptr<DeviceBuffer>, DeviceBuffer*>
  EmplaceInternal(const void* buffer, size_t length);

  std::tuple<Range, std::shared_ptr<DeviceBuffer>, DeviceBuffer*>
  EmplaceInternal(size_t length, size_t align, const EmplaceProc& cb);

  std::tuple<Range, std::shared_ptr<DeviceBuffer>, DeviceBuffer*>
  EmplaceInternal(const void* buffer, size_t length, size_t align);

  size_t GetLength() const { return offset_; }

  /// Attempt to create a new internal buffer if the existing capacity is not
  /// sufficient.
  ///
  /// A false return value indicates an unrecoverable allocation failure.
  [[nodiscard]] bool MaybeCreateNewBuffer();

  const std::shared_ptr<DeviceBuffer>& GetCurrentBuffer() const;

  [[nodiscard]] BufferView Emplace(const void* buffer, size_t length);

  std::shared_ptr<Allocator> allocator_;
  std::shared_ptr<const IdleWaiter> idle_waiter_;
  std::array<std::vector<std::shared_ptr<DeviceBuffer>>, kHostBufferArenaSize>
      device_buffers_;
  size_t current_buffer_ = 0u;
  size_t offset_ = 0u;
  size_t frame_index_ = 0u;
  size_t minimum_uniform_alignment_ = 0u;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_CORE_SIMPLE_HOST_BUFFER_H_

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_CORE_PARTITIONED_HOST_BUFFER_H_
#define FLUTTER_IMPELLER_CORE_PARTITIONED_HOST_BUFFER_H_

#include "impeller/core/simple_host_buffer.h"

namespace impeller {

class PartitionedHostBuffer : public HostBuffer {
 public:
  explicit PartitionedHostBuffer(
      const std::shared_ptr<Allocator>& allocator,
      const std::shared_ptr<const IdleWaiter>& idle_waiter,
      size_t minimum_uniform_alignment);

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
  SimpleHostBuffer& _buffer(BufferCategory category);

  SimpleHostBuffer _dataBuffer;
  SimpleHostBuffer _indexBuffer;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_CORE_PARTITIONED_HOST_BUFFER_H_

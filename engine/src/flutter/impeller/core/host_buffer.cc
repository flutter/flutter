// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/core/host_buffer.h"

#include "impeller/core/partitioned_host_buffer.h"
#include "impeller/core/simple_host_buffer.h"

namespace impeller {

std::shared_ptr<HostBuffer> HostBuffer::Create(
    const std::shared_ptr<Allocator>& allocator,
    const std::shared_ptr<const IdleWaiter>& idle_waiter,
    size_t minimum_uniform_alignment,
    bool partitionByCategory) {
  if (partitionByCategory) {
    return std::shared_ptr<PartitionedHostBuffer>(new PartitionedHostBuffer(
        allocator, idle_waiter, minimum_uniform_alignment));
  }
  return std::shared_ptr<HostBuffer>(
      new SimpleHostBuffer(allocator, idle_waiter, minimum_uniform_alignment));
}

}  // namespace impeller

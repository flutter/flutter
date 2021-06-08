// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include <string>

#include "flutter/fml/macros.h"

namespace impeller {

enum class StorageMode {
  kHostCoherent,
  kDevicePrivate,
};

class Context;
class DeviceBuffer;

class Allocator {
 public:
  ~Allocator();

  bool IsValid() const;

  std::shared_ptr<DeviceBuffer> CreateBuffer(StorageMode mode, size_t length);

  std::shared_ptr<DeviceBuffer> CreateBufferWithCopy(const uint8_t* buffer,
                                                     size_t length);

 private:
  friend class Context;

  // In the prototype, we are going to be allocating resources directly with the
  // MTLDevice APIs. But, in the future, this could be backed by named heaps
  // with specific limits.
  id<MTLDevice> device_;
  std::string allocator_label_;
  bool is_valid_ = false;

  Allocator(id<MTLDevice> device, std::string label);

  FML_DISALLOW_COPY_AND_ASSIGN(Allocator);
};

}  // namespace impeller

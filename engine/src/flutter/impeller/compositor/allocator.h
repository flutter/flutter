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
class Buffer;

class Allocator {
 public:
  ~Allocator();

  std::shared_ptr<Buffer> CreateBuffer(size_t length, std::string label);

 private:
  friend class Context;

  // In the prototype, we are going to be allocating resources directly with the
  // MTLDevice APIs. But, in the future, this could be backed by named heaps
  // with specific limits.
  id<MTLDevice> device_;
  StorageMode mode_;
  std::string allocator_label_;

  Allocator(id<MTLDevice> device, StorageMode type, std::string label);

  FML_DISALLOW_COPY_AND_ASSIGN(Allocator);
};

}  // namespace impeller

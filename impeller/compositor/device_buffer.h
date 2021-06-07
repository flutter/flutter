// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include <string>

#include "flutter/fml/macros.h"
#include "impeller/compositor/allocator.h"

namespace impeller {

class Buffer {
 public:
  ~Buffer();

 private:
  friend class Allocator;

  const id<MTLBuffer> buffer_;
  const size_t size_;
  const StorageMode mode_;
  const std::string label_;

  Buffer(id<MTLBuffer> buffer,
         size_t size,
         StorageMode mode,
         std::string label);

  FML_DISALLOW_COPY_AND_ASSIGN(Buffer);
};

}  // namespace impeller

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/device_buffer.h"

namespace impeller {

Buffer::Buffer(id<MTLBuffer> buffer,
               size_t size,
               StorageMode mode,
               std::string label)
    : buffer_(buffer), size_(size), mode_(mode), label_(std::move(label)) {}

Buffer::~Buffer() = default;

}  // namespace impeller

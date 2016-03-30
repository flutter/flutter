// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/services/media/common/cpp/shared_media_buffer_allocator.h"

namespace mojo {
namespace media {

SharedMediaBufferAllocator::~SharedMediaBufferAllocator() {
  std::lock_guard<std::mutex> lock(lock_);
}

void SharedMediaBufferAllocator::OnInit() {
  std::lock_guard<std::mutex> lock(lock_);
  fifo_allocator_.Reset(size());
}

}  // namespace media
}  // namespace mojo

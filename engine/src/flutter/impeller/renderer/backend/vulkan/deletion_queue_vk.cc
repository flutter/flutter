// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/deletion_queue_vk.h"

namespace impeller {

DeletionQueueVK::DeletionQueueVK() = default;

DeletionQueueVK::~DeletionQueueVK() {
  Flush();
}

void DeletionQueueVK::Flush() {
  for (auto it = deletors_.rbegin(); it != deletors_.rend(); ++it) {
    (*it)();
  }

  deletors_.clear();
}

void DeletionQueueVK::Push(Deletor&& deletor) {
  deletors_.push_back(std::move(deletor));
}

}  // namespace impeller

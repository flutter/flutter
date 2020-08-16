// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "include/flutter/engine_method_result.h"

#include <assert.h>
#include <iostream>

namespace flutter {
namespace internal {

ReplyManager::ReplyManager(BinaryReply reply_handler)
    : reply_handler_(std::move(reply_handler)) {
  assert(reply_handler_);
}

ReplyManager::~ReplyManager() {
  if (reply_handler_) {
    // Warn, rather than send a not-implemented response, since the engine may
    // no longer be valid at this point.
    std::cerr
        << "Warning: Failed to respond to a message. This is a memory leak."
        << std::endl;
  }
}

void ReplyManager::SendResponseData(const std::vector<uint8_t>* data) {
  if (!reply_handler_) {
    std::cerr
        << "Error: Only one of Success, Error, or NotImplemented can be "
           "called,"
        << " and it can be called exactly once. Ignoring duplicate result."
        << std::endl;
    return;
  }

  const uint8_t* message = data && !data->empty() ? data->data() : nullptr;
  size_t message_size = data ? data->size() : 0;
  reply_handler_(message, message_size);
  reply_handler_ = nullptr;
}

}  // namespace internal
}  // namespace flutter

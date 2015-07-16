// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/data_pipe_impl.h"

#include <algorithm>

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "mojo/edk/system/configuration.h"
#include "mojo/edk/system/message_in_transit.h"
#include "mojo/edk/system/message_in_transit_queue.h"

namespace mojo {
namespace system {

void DataPipeImpl::ConvertDataToMessages(const char* buffer,
                                         size_t* start_index,
                                         size_t* current_num_bytes,
                                         MessageInTransitQueue* message_queue) {
  // The maximum amount of data to send per message (make it a multiple of the
  // element size.
  size_t max_message_num_bytes = GetConfiguration().max_message_num_bytes;
  max_message_num_bytes -= max_message_num_bytes % element_num_bytes();
  DCHECK_GT(max_message_num_bytes, 0u);

  while (*current_num_bytes > 0) {
    size_t current_contiguous_num_bytes =
        (*start_index + *current_num_bytes > capacity_num_bytes())
            ? (capacity_num_bytes() - *start_index)
            : *current_num_bytes;
    size_t message_num_bytes =
        std::min(max_message_num_bytes, current_contiguous_num_bytes);

    // Note: |message_num_bytes| fits in a |uint32_t| since the capacity does.
    scoped_ptr<MessageInTransit> message(new MessageInTransit(
        MessageInTransit::Type::ENDPOINT_CLIENT,
        MessageInTransit::Subtype::ENDPOINT_CLIENT_DATA,
        static_cast<uint32_t>(message_num_bytes), buffer + *start_index));
    message_queue->AddMessage(message.Pass());

    DCHECK_LE(message_num_bytes, *current_num_bytes);
    *start_index += message_num_bytes;
    *start_index %= capacity_num_bytes();
    *current_num_bytes -= message_num_bytes;
  }
}

}  // namespace system
}  // namespace mojo

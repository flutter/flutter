// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_REMOTE_DATA_PIPE_ACK_H_
#define MOJO_EDK_SYSTEM_REMOTE_DATA_PIPE_ACK_H_

#include <stdint.h>

namespace mojo {
namespace system {

// Data payload for |MessageInTransit::Subtype::ENDPOINT_CLIENT_DATA_PIPE_ACK|
// messages.
struct RemoteDataPipeAck {
  uint32_t num_bytes_consumed;
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_REMOTE_DATA_PIPE_ACK_H_

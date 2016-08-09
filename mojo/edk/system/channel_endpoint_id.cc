// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/channel_endpoint_id.h"

namespace mojo {
namespace system {

const uint32_t ChannelEndpointId::kRemoteFlag;

ChannelEndpointId LocalChannelEndpointIdGenerator::GetNext() {
  ChannelEndpointId rv = next_;
  next_.value_ = (next_.value_ + 1) & ~ChannelEndpointId::kRemoteFlag;
  // Skip over the invalid value, in case we wrap.
  if (!next_.is_valid())
    next_.value_++;
  return rv;
}

ChannelEndpointId RemoteChannelEndpointIdGenerator::GetNext() {
  ChannelEndpointId rv = next_;
  next_.value_ = (next_.value_ + 1) | ChannelEndpointId::kRemoteFlag;
  return rv;
}

}  // namespace system
}  // namespace mojo

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_CHANNEL_ID_H_
#define MOJO_EDK_SYSTEM_CHANNEL_ID_H_

#include <stdint.h>

namespace mojo {
namespace system {

// IDs for |Channel|s managed by a |ChannelManager|. (IDs should be thought of
// as specific to a given |ChannelManager|.)
using ChannelId = uint64_t;

// 0 is never a valid |ChannelId|.
const ChannelId kInvalidChannelId = 0;

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_CHANNEL_ID_H_

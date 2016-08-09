// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file simply (forward) declares |mojo::embedder::ChannelInfo|, which is
// meant to be opaque to users of the embedder API.

#ifndef MOJO_EDK_EMBEDDER_CHANNEL_INFO_FORWARD_H_
#define MOJO_EDK_EMBEDDER_CHANNEL_INFO_FORWARD_H_

namespace mojo {
namespace embedder {

// This is an opaque type. The embedder API uses (returns and takes as
// arguments) pointers to this type. (We don't simply use |void*|, so that
// custom deleters and such can be used without additional wrappers.
struct ChannelInfo;

}  // namespace embedder
}  // namespace mojo

#endif  // MOJO_EDK_EMBEDDER_CHANNEL_INFO_FORWARD_H_

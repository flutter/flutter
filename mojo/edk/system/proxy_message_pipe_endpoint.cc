// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/proxy_message_pipe_endpoint.h"

#include <string.h>

#include <utility>

#include "base/logging.h"
#include "mojo/edk/system/channel_endpoint.h"
#include "mojo/edk/system/local_message_pipe_endpoint.h"
#include "mojo/edk/system/message_pipe_dispatcher.h"

using mojo::util::RefPtr;

namespace mojo {
namespace system {

ProxyMessagePipeEndpoint::ProxyMessagePipeEndpoint(
    RefPtr<ChannelEndpoint>&& channel_endpoint)
    : channel_endpoint_(std::move(channel_endpoint)) {}

ProxyMessagePipeEndpoint::~ProxyMessagePipeEndpoint() {
  DCHECK(!channel_endpoint_);
}

RefPtr<ChannelEndpoint> ProxyMessagePipeEndpoint::ReleaseChannelEndpoint() {
  DCHECK(channel_endpoint_);
  return std::move(channel_endpoint_);
}

MessagePipeEndpoint::Type ProxyMessagePipeEndpoint::GetType() const {
  return kTypeProxy;
}

bool ProxyMessagePipeEndpoint::OnPeerClose() {
  DetachIfNecessary();
  return false;
}

// Note: We may have to enqueue messages even when our (local) peer isn't open
// -- it may have been written to and closed immediately, before we were ready.
// This case is handled in |Run()| (which will call us).
void ProxyMessagePipeEndpoint::EnqueueMessage(
    std::unique_ptr<MessageInTransit> message) {
  DCHECK(channel_endpoint_);
  bool ok = channel_endpoint_->EnqueueMessage(std::move(message));
  LOG_IF(WARNING, !ok) << "Failed to write enqueue message to channel";
}

void ProxyMessagePipeEndpoint::Close() {
  DetachIfNecessary();
}

void ProxyMessagePipeEndpoint::DetachIfNecessary() {
  if (channel_endpoint_) {
    channel_endpoint_->DetachFromClient();
    channel_endpoint_ = nullptr;
  }
}

}  // namespace system
}  // namespace mojo

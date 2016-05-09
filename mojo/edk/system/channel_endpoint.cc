// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/channel_endpoint.h"

#include <utility>

#include "base/logging.h"
#include "mojo/edk/platform/thread_utils.h"
#include "mojo/edk/system/channel.h"
#include "mojo/edk/system/channel_endpoint_client.h"
#include "mojo/public/cpp/system/macros.h"

using mojo::platform::ThreadYield;
using mojo::util::MutexLocker;
using mojo::util::RefPtr;

namespace mojo {
namespace system {

bool ChannelEndpoint::EnqueueMessage(
    std::unique_ptr<MessageInTransit> message) {
  DCHECK(message);

  MutexLocker locker(&mutex_);

  switch (state_) {
    case State::PAUSED:
      channel_message_queue_.AddMessage(std::move(message));
      return true;
    case State::RUNNING:
      return WriteMessageNoLock(std::move(message));
    case State::DEAD:
      return false;
  }

  NOTREACHED();
  return false;
}

bool ChannelEndpoint::ReplaceClient(RefPtr<ChannelEndpointClient>&& client,
                                    unsigned client_port) {
  DCHECK(client);

  MutexLocker locker(&mutex_);
  DCHECK(client_);
  DCHECK(client != client_ || client_port != client_port_);
  client_ = std::move(client);
  client_port_ = client_port;
  return state_ != State::DEAD;
}

void ChannelEndpoint::DetachFromClient() {
  MutexLocker locker(&mutex_);
  DCHECK(client_);
  client_ = nullptr;

  if (!channel_)
    return;
  channel_->DetachEndpoint(this, local_id_, remote_id_);
  DieNoLock();
}

void ChannelEndpoint::AttachAndRun(Channel* channel,
                                   ChannelEndpointId local_id,
                                   ChannelEndpointId remote_id) {
  DCHECK(channel);
  DCHECK(local_id.is_valid());
  DCHECK(remote_id.is_valid());

  MutexLocker locker(&mutex_);
  DCHECK(state_ == State::PAUSED);
  DCHECK(!channel_);
  DCHECK(!local_id_.is_valid());
  DCHECK(!remote_id_.is_valid());
  state_ = State::RUNNING;
  channel_ = channel;
  local_id_ = local_id;
  remote_id_ = remote_id;

  while (!channel_message_queue_.IsEmpty()) {
    bool ok = WriteMessageNoLock(channel_message_queue_.GetMessage());
    LOG_IF(WARNING, !ok) << "Failed to write enqueue message to channel";
  }

  if (!client_) {
    channel_->DetachEndpoint(this, local_id_, remote_id_);
    DieNoLock();
  }
}

void ChannelEndpoint::OnReadMessage(std::unique_ptr<MessageInTransit> message) {
  if (message->type() == MessageInTransit::Type::ENDPOINT_CLIENT) {
    OnReadMessageForClient(std::move(message));
    return;
  }

  DCHECK_EQ(message->type(), MessageInTransit::Type::ENDPOINT);

  // TODO(vtl)
  // Note that this won't crash on Release builds, which is important (since the
  // other side may be malicious). Doing nothing is safe and will dispose of the
  // message.
  NOTREACHED();
}

void ChannelEndpoint::DetachFromChannel() {
  RefPtr<ChannelEndpointClient> client;
  unsigned client_port = 0;
  {
    MutexLocker locker(&mutex_);

    if (client_) {
      // Take a ref, and call |OnDetachFromChannel()| outside the lock.
      client = client_;
      client_port = client_port_;
    }

    // |channel_| may already be null if we already detached from the channel in
    // |DetachFromClient()| by calling |Channel::DetachEndpoint()| (and there
    // are racing detaches).
    if (channel_)
      DieNoLock();
    else
      DCHECK(state_ == State::DEAD);
  }

  // If |ReplaceClient()| is called (from another thread) after the above locked
  // section but before we call |OnDetachFromChannel()|, |ReplaceClient()|
  // returns false to notify the caller that the channel was already detached.
  // (The old client has to accept the arguably-spurious call to
  // |OnDetachFromChannel()|.)
  if (client)
    client->OnDetachFromChannel(client_port);
}

ChannelEndpoint::ChannelEndpoint(RefPtr<ChannelEndpointClient>&& client,
                                 unsigned client_port,
                                 MessageInTransitQueue* message_queue)
    : state_(State::PAUSED),
      client_(std::move(client)),
      client_port_(client_port),
      channel_(nullptr) {
  DCHECK(client_ || message_queue);

  if (message_queue)
    channel_message_queue_.Swap(message_queue);
}

ChannelEndpoint::~ChannelEndpoint() {
  DCHECK(!client_);
  DCHECK(!channel_);
  DCHECK(!local_id_.is_valid());
  DCHECK(!remote_id_.is_valid());
}

bool ChannelEndpoint::WriteMessageNoLock(
    std::unique_ptr<MessageInTransit> message) {
  DCHECK(message);

  mutex_.AssertHeld();

  DCHECK(channel_);
  DCHECK(local_id_.is_valid());
  DCHECK(remote_id_.is_valid());

  message->SerializeAndCloseHandles(channel_);
  message->set_source_id(local_id_);
  message->set_destination_id(remote_id_);
  return channel_->WriteMessage(std::move(message));
}

void ChannelEndpoint::OnReadMessageForClient(
    std::unique_ptr<MessageInTransit> message) {
  DCHECK_EQ(message->type(), MessageInTransit::Type::ENDPOINT_CLIENT);

  RefPtr<ChannelEndpointClient> client;
  unsigned client_port = 0;

  // This loop is to make |ReplaceClient()| work. We can't call the client's
  // |OnReadMessage()| under our lock, so by the time we do that, |client| may
  // no longer be our client.
  //
  // In that case, |client| must return false. We'll then yield, and retry with
  // the new client. (Theoretically, the client could be replaced again.)
  //
  // This solution isn't terribly elegant, but it's the least costly way of
  // handling/avoiding this (very unlikely) race. (Other solutions -- e.g.,
  // adding a client message queue, which the client only fetches messages from
  // -- impose significant cost in the common case.)
  for (;;) {
    {
      MutexLocker locker(&mutex_);
      if (!channel_ || !client_) {
        // This isn't a failure per se. (It just means that, e.g., the other end
        // of the message pipe closed first.)
        return;
      }

      // If we get here in a second (third, etc.) iteration of the loop, it's
      // because |ReplaceClient()| was called.
      DCHECK(client_ != client || client_port_ != client_port);

      // Take a ref, and call |OnReadMessage()| outside the lock.
      client = client_;
      client_port = client_port_;
    }

    if (client->OnReadMessage(client_port, message.get())) {
      ignore_result(message.release());
      break;
    }

    ThreadYield();
  }
}

void ChannelEndpoint::DieNoLock() {
  DCHECK(state_ == State::RUNNING);
  DCHECK(channel_);
  DCHECK(local_id_.is_valid());
  DCHECK(remote_id_.is_valid());

  state_ = State::DEAD;
  channel_ = nullptr;
  local_id_ = ChannelEndpointId();
  remote_id_ = ChannelEndpointId();
}

}  // namespace system
}  // namespace mojo

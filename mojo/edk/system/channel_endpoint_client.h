// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_CHANNEL_ENDPOINT_CLIENT_H_
#define MOJO_EDK_SYSTEM_CHANNEL_ENDPOINT_CLIENT_H_

#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "mojo/edk/system/system_impl_export.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

class MessageInTransit;

// Interface for receivers of messages from |ChannelEndpoint| (hence from
// |Channel|). |port| is simply the value passed to |ChannelEndpoint| on
// construction, and provides a lightweight way for an object to be the client
// of multiple |ChannelEndpoint|s. (|MessagePipe| implements this interface, in
// which case |port| is the port number for the |ProxyMessagePipeEndpoint|
// corresdponding to the |ChannelEndpoint|.)
//
// Implementations of this class should be thread-safe. |ChannelEndpointClient|
// *precedes* |ChannelEndpoint| in the lock order, so |ChannelEndpoint| should
// never call into this class with its lock held. (Instead, it should take a
// reference under its lock, release its lock, and make any needed call(s).)
//
// Note: As a consequence of this, all the client methods may be called even
// after |ChannelEndpoint::DetachFromClient()| has been called (so the
// |ChannelEndpoint| has apparently relinquished its pointer to the
// |ChannelEndpointClient|).
class MOJO_SYSTEM_IMPL_EXPORT ChannelEndpointClient
    : public base::RefCountedThreadSafe<ChannelEndpointClient> {
 public:
  // Called by |ChannelEndpoint| in response to its |OnReadMessage()|, which is
  // called by |Channel| when it receives a message for the |ChannelEndpoint|.
  // (|port| is the value passed to |ChannelEndpoint|'s constructor as
  // |client_port|.)
  //
  // This should return true if it accepted (and took ownership of) |message|.
  virtual bool OnReadMessage(unsigned port, MessageInTransit* message) = 0;

  // Called by |ChannelEndpoint| when the |Channel| is relinquishing its pointer
  // to the |ChannelEndpoint| (and vice versa). After this is called,
  // |OnReadMessage()| will no longer be called.
  virtual void OnDetachFromChannel(unsigned port) = 0;

 protected:
  ChannelEndpointClient() {}

  virtual ~ChannelEndpointClient() {}
  friend class base::RefCountedThreadSafe<ChannelEndpointClient>;

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(ChannelEndpointClient);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_CHANNEL_ENDPOINT_CLIENT_H_

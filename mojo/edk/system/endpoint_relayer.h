// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_ENDPOINT_RELAYER_H_
#define MOJO_EDK_SYSTEM_ENDPOINT_RELAYER_H_

#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "mojo/edk/system/channel_endpoint_client.h"
#include "mojo/edk/system/mutex.h"
#include "mojo/edk/system/system_impl_export.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

class ChannelEndpoint;

// This is a simple |ChannelEndpointClient| that just relays messages between
// two |ChannelEndpoint|s (without the overhead of |MessagePipe|).
class MOJO_SYSTEM_IMPL_EXPORT EndpointRelayer final
    : public ChannelEndpointClient {
 public:
  // A class that can inspect and optionally handle messages of type
  // |Type::ENDPOINT_CLIENT| received from either |ChannelEndpoint|.
  //
  // Instances of implementations of this class will be owned by
  // |EndpointRelayer|s.
  //
  // Destructors may not call methods of the |EndpointRelayer| (nor of the
  // |ChannelEndpoint|s).
  class MOJO_SYSTEM_IMPL_EXPORT Filter {
   public:
    virtual ~Filter() {}

    // Called by |EndpointRelayer::OnReadMessage()| for messages of type
    // |Type::ENDPOINT_CLIENT|. This is only called by the |EndpointRelayer| if
    // it is still the client of the sending endpoint.
    //
    // |endpoint| (which will not be null) is the |ChannelEndpoint|
    // corresponding to |port| (i.e., the endpoint the message was received
    // from), whereas |peer_endpoint| (which may be null) is that corresponding
    // to the peer port (i.e., the endpoint to which the message would be
    // relayed).
    //
    // This should return true if the message is consumed (in which case
    // ownership is transferred), and false if not (in which case the message
    // will be relayed as usual).
    //
    // This will always be called under |EndpointRelayer|'s lock. This may call
    // |ChannelEndpoint| methods. However, it may not call any of
    // |EndpointRelayer|'s methods.
    virtual bool OnReadMessage(ChannelEndpoint* endpoint,
                               ChannelEndpoint* peer_endpoint,
                               MessageInTransit* message) = 0;

   protected:
    Filter() {}

   private:
    MOJO_DISALLOW_COPY_AND_ASSIGN(Filter);
  };

  EndpointRelayer();

  // Gets the other port number (i.e., 0 -> 1, 1 -> 0).
  static unsigned GetPeerPort(unsigned port);

  // Initialize this object. This must be called before any other method.
  void Init(ChannelEndpoint* endpoint0,
            ChannelEndpoint* endpoint1) MOJO_NOT_THREAD_SAFE;

  // Sets (or resets) the filter, which can (optionally) handle/filter
  // |Type::ENDPOINT_CLIENT| messages (see |Filter| above).
  void SetFilter(scoped_ptr<Filter> filter);

  // |ChannelEndpointClient| methods:
  bool OnReadMessage(unsigned port, MessageInTransit* message) override;
  void OnDetachFromChannel(unsigned port) override;

 private:
  ~EndpointRelayer() override;

  Mutex mutex_;
  scoped_refptr<ChannelEndpoint> endpoints_[2] MOJO_GUARDED_BY(mutex_);
  scoped_ptr<Filter> filter_ MOJO_GUARDED_BY(mutex_);

  MOJO_DISALLOW_COPY_AND_ASSIGN(EndpointRelayer);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_ENDPOINT_RELAYER_H_

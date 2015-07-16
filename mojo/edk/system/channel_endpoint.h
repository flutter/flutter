// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_CHANNEL_ENDPOINT_H_
#define MOJO_EDK_SYSTEM_CHANNEL_ENDPOINT_H_

#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "mojo/edk/system/channel_endpoint_id.h"
#include "mojo/edk/system/message_in_transit_queue.h"
#include "mojo/edk/system/mutex.h"
#include "mojo/edk/system/system_impl_export.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

class Channel;
class ChannelEndpointClient;
class MessageInTransit;

// TODO(vtl): The plan:
//   - (Done.) Move |Channel::Endpoint| to |ChannelEndpoint|. Make it
//     refcounted, and not copyable. Make |Channel| a friend. Make things work.
//   - (Done.) Give |ChannelEndpoint| a lock. The lock order (in order of
//     allowable acquisition) is: |MessagePipe|, |ChannelEndpoint|, |Channel|.
//   - (Done) Stop having |Channel| as a friend.
//   - (Done) Move logic from |ProxyMessagePipeEndpoint| into |ChannelEndpoint|.
//     Right now, we have to go through lots of contortions to manipulate state
//     owned by |ProxyMessagePipeEndpoint| (in particular, |Channel::Endpoint|
//     doesn't know about the remote ID; the local ID is duplicated in two
//     places). Hollow out |ProxyMessagePipeEndpoint|, and have it just own a
//     reference to |ChannelEndpoint| (hence the refcounting).
//   - In essence, |ChannelEndpoint| becomes the thing that knows about
//     channel-specific aspects of an endpoint (notably local and remote IDs,
//     and knowledge about handshaking), and mediates between the |Channel| and
//     the |MessagePipe|.
//   - In the end state, |Channel| should no longer need to know about
//     |MessagePipe| and ports (but only |ChannelEndpoint|) and
//     |ProxyMessagePipeEndpoint| should no longer need to know about |Channel|
//     (ditto).
//
// Things as they are now, before I change everything (TODO(vtl): update this
// comment appropriately):
//
// Terminology:
//   - "Message pipe endpoint": In the implementation, a |MessagePipe| owns
//     two |MessagePipeEndpoint| objects, one for each port. The
//     |MessagePipeEndpoint| objects are only accessed via the |MessagePipe|
//     (which has the lock), with the additional information of the port
//     number. So as far as the channel is concerned, a message pipe endpoint
//     is a pointer to a |MessagePipe| together with the port number.
//       - The value of |port| in |EndpointInfo| refers to the
//         |ProxyMessagePipeEndpoint| (i.e., the endpoint that is logically on
//         the other side). Messages received by a channel for a message pipe
//         are thus written to the *peer* of this port.
//   - "Attached"/"detached": A message pipe endpoint is attached to a channel
//     if it has a pointer to it. It must be detached before the channel gives
//     up its pointer to it in order to break a reference cycle. (This cycle
//     is needed to allow a channel to be shut down cleanly, without shutting
//     down everything else first.)
//   - "Running" (message pipe endpoint): A message pipe endpoint is running
//     if messages written to it (via some |MessagePipeDispatcher|, to which
//     some |MojoHandle| is assigned) are being transmitted through the
//     channel.
//       - Before a message pipe endpoint is run, it will queue messages.
//       - When a message pipe endpoint is detached from a channel, it is also
//         taken out of the running state. After that point, messages should
//         no longer be written to it.
//   - "Normal" message pipe endpoint (state): The channel itself does not
//     have knowledge of whether a message pipe endpoint has started running
//     yet. It will *receive* messages for a message pipe in either state (but
//     the message pipe endpoint won't *send* messages to the channel if it
//     has not started running).
//   - "Zombie" message pipe endpoint (state): A message pipe endpoint is a
//     zombie if it is still in |local_id_to_endpoint_info_map_|, but the
//     channel is no longer forwarding messages to it (even if it may still be
//     receiving messages for it).
//       - There are various types of zombies, depending on the reason the
//         message pipe endpoint cannot yet be removed.
//       - If the remote side is closed, it will send a "remove" control
//         message. After the channel receives that message (to which it
//         responds with a "remove ack" control message), it knows that it
//         shouldn't receive any more messages for that message pipe endpoint
//         (local ID), but it must wait for the endpoint to detach. (It can't
//         do so without a race, since it can't call into the message pipe
//         under |mutex_|.) [TODO(vtl): When I add remotely-allocated IDs,
//         we'll have to remove the |EndpointInfo| from
//         |local_id_to_endpoint_info_map_| -- i.e., remove the local ID,
//         since it's no longer valid and may be reused by the remote side --
//         and keep the |EndpointInfo| alive in some other way.]
//       - If the local side is closed and the message pipe endpoint was
//         already running (so there are no queued messages left to send), it
//         will detach the endpoint, and send a "remove" control message.
//         However, the channel may still receive messages for that endpoint
//         until it receives a "remove ack" control message.
//       - If the local side is closed but the message pipe endpoint was not
//         yet running , the detaching is delayed until after it is run and
//         all the queued messages are sent to the channel. On being detached,
//         things proceed as in one of the above cases. The endpoint is *not*
//         a zombie until it is detached (or a "remove" message is received).
//         [TODO(vtl): Maybe we can get rid of this case? It'd only not yet be
//         running since under the current scheme it wouldn't have a remote ID
//         yet.]
//       - Note that even if the local side is closed, it may still receive a
//         "remove" message from the other side (if the other side is closed
//         simultaneously, and both sides send "remove" messages). In that
//         case, it must still remain alive until it receives the "remove
//         ack" (and it must ack the "remove" message that it received).
class MOJO_SYSTEM_IMPL_EXPORT ChannelEndpoint final
    : public base::RefCountedThreadSafe<ChannelEndpoint> {
 public:
  // Constructor for a |ChannelEndpoint| with the given client (specified by
  // |client| and |client_port|). Optionally takes messages from
  // |*message_queue| if |message_queue| is non-null.
  //
  // |client| may be null if this endpoint will never need to receive messages,
  // in which case |message_queue| should not be null. In that case, this
  // endpoint will simply send queued messages upon being attached to a
  // |Channel| and immediately detach itself.
  ChannelEndpoint(ChannelEndpointClient* client,
                  unsigned client_port,
                  MessageInTransitQueue* message_queue = nullptr);

  // Methods called by |ChannelEndpointClient|:

  // Called to enqueue an outbound message. (If |AttachAndRun()| has not yet
  // been called, the message will be enqueued and sent when |AttachAndRun()| is
  // called.)
  bool EnqueueMessage(scoped_ptr<MessageInTransit> message);

  // Called to *replace* current client with a new client (which must differ
  // from the existing client). This must not be called after
  // |DetachFromClient()| has been called.
  //
  // This returns true in the typical case, and false if this endpoint has been
  // detached from the channel, in which case the caller should probably call
  // its (new) client's |OnDetachFromChannel()|.
  bool ReplaceClient(ChannelEndpointClient* client, unsigned client_port);

  // Called before the |ChannelEndpointClient| gives up its reference to this
  // object.
  void DetachFromClient();

  // Methods called by |Channel|:

  // Called when the |Channel| takes a reference to this object. This will send
  // all queue messages (in |channel_message_queue_|).
  // TODO(vtl): Maybe rename this "OnAttach"?
  void AttachAndRun(Channel* channel,
                    ChannelEndpointId local_id,
                    ChannelEndpointId remote_id);

  // Called when the |Channel| receives a message for the |ChannelEndpoint|.
  void OnReadMessage(scoped_ptr<MessageInTransit> message);

  // Called before the |Channel| gives up its reference to this object.
  void DetachFromChannel();

 private:
  friend class base::RefCountedThreadSafe<ChannelEndpoint>;
  ~ChannelEndpoint();

  bool WriteMessageNoLock(scoped_ptr<MessageInTransit> message)
      MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);

  // Helper for |OnReadMessage()|, handling messages for the client.
  void OnReadMessageForClient(scoped_ptr<MessageInTransit> message);

  // Resets |channel_| to null (and sets |channel_state_| to
  // |ChannelState::DETACHED|). This may only be called if |channel_| is
  // non-null.
  void ResetChannelNoLock() MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);

  Mutex mutex_;

  // |client_| must be valid whenever it is non-null. Before |*client_| gives up
  // its reference to this object, it must call |DetachFromClient()|.
  // NOTE: This is a |scoped_refptr<>|, rather than a raw pointer, since the
  // |Channel| needs to keep the |MessagePipe| alive for the "proxy-proxy" case.
  // Possibly we'll be able to eliminate that case when we have full
  // multiprocess support.
  // WARNING: |ChannelEndpointClient| methods must not be called under |mutex_|.
  // Thus to make such a call, a reference must first be taken under |mutex_|
  // and the lock released.
  // TODO(vtl): Annotate the above rule using |MOJO_ACQUIRED_{BEFORE,AFTER}()|,
  // once clang actually checks such annotations.
  // https://github.com/domokit/mojo/issues/313
  // WARNING: Beware of interactions with |ReplaceClient()|. By the time the
  // call is made, the client may have changed. This must be detected and dealt
  // with.
  scoped_refptr<ChannelEndpointClient> client_ MOJO_GUARDED_BY(mutex_);
  unsigned client_port_ MOJO_GUARDED_BY(mutex_);

  // State with respect to interaction with the |Channel|.
  enum class ChannelState {
    // |AttachAndRun()| has not been called yet (|channel_| is null).
    NOT_YET_ATTACHED,
    // |AttachAndRun()| has been called, but not |DetachFromChannel()|
    // (|channel_| is non-null and valid).
    ATTACHED,
    // |DetachFromChannel()| has been called (|channel_| is null).
    DETACHED
  };
  ChannelState channel_state_ MOJO_GUARDED_BY(mutex_);
  // |channel_| must be valid whenever it is non-null. Before |*channel_| gives
  // up its reference to this object, it must call |DetachFromChannel()|.
  // |local_id_| and |remote_id_| are valid if and only |channel_| is non-null.
  Channel* channel_ MOJO_GUARDED_BY(mutex_);
  ChannelEndpointId local_id_ MOJO_GUARDED_BY(mutex_);
  ChannelEndpointId remote_id_ MOJO_GUARDED_BY(mutex_);

  // This queue is used before we're running on a channel and ready to send
  // messages to the channel.
  MessageInTransitQueue channel_message_queue_ MOJO_GUARDED_BY(mutex_);

  MOJO_DISALLOW_COPY_AND_ASSIGN(ChannelEndpoint);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_CHANNEL_ENDPOINT_H_

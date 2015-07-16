// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_CHANNEL_H_
#define MOJO_EDK_SYSTEM_CHANNEL_H_

#include <stdint.h>

#include "base/containers/hash_tables.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "base/threading/thread_checker.h"
#include "mojo/edk/embedder/scoped_platform_handle.h"
#include "mojo/edk/system/channel_endpoint.h"
#include "mojo/edk/system/channel_endpoint_id.h"
#include "mojo/edk/system/incoming_endpoint.h"
#include "mojo/edk/system/message_in_transit.h"
#include "mojo/edk/system/mutex.h"
#include "mojo/edk/system/raw_channel.h"
#include "mojo/edk/system/system_impl_export.h"
#include "mojo/public/c/system/types.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {

namespace embedder {
class PlatformSupport;
}

namespace system {

class ChannelEndpointClient;
class ChannelManager;
class MessageInTransitQueue;

// This class is mostly thread-safe. It must be created on an I/O thread.
// |Init()| must be called on that same thread before it becomes thread-safe (in
// particular, before references are given to any other thread) and |Shutdown()|
// must be called on that same thread before destruction. Its public methods are
// otherwise thread-safe. (Many private methods are restricted to the creation
// thread.) It may be destroyed on any thread, in the sense that the last
// reference to it may be released on any thread, with the proviso that
// |Shutdown()| must have been called first (so the pattern is that a "main"
// reference is kept on its creation thread and is released after |Shutdown()|
// is called, but other threads may have temporarily "dangling" references).
//
// Note the lock order (in order of allowable acquisition):
// |ChannelEndpointClient| (e.g., |MessagePipe|), |ChannelEndpoint|, |Channel|.
// Thus |Channel| may not call into |ChannelEndpoint| with |Channel|'s lock
// held.
class MOJO_SYSTEM_IMPL_EXPORT Channel final
    : public base::RefCountedThreadSafe<Channel>,
      public RawChannel::Delegate {
 public:
  // |platform_support| must remain alive until after |Shutdown()| is called.
  explicit Channel(embedder::PlatformSupport* platform_support);

  // This must be called on the creation thread before any other methods are
  // called, and before references to this object are given to any other
  // threads. |raw_channel| should be uninitialized.
  void Init(scoped_ptr<RawChannel> raw_channel) MOJO_NOT_THREAD_SAFE;

  // Sets the channel manager associated with this channel. This should be set
  // at most once and only called before |WillShutdownSoon()| (and
  // |Shutdown()|). (This is called by the channel manager when adding a
  // channel; this should not be called before the channel is managed by the
  // channel manager.)
  void SetChannelManager(ChannelManager* channel_manager);

  // This must be called on the creation thread before destruction (which can
  // happen on any thread).
  void Shutdown();

  // Signals that |Shutdown()| will be called soon (this may be called from any
  // thread, unlike |Shutdown()|). Warnings will be issued if, e.g., messages
  // are written after this is called; other warnings may be suppressed. (This
  // may be called multiple times, or not at all.)
  //
  // If set, the channel manager associated with this channel will be reset.
  void WillShutdownSoon();

  // Called to set (i.e., attach and run) the bootstrap (first) endpoint on the
  // channel. Both the local and remote IDs are the bootstrap ID (given by
  // |ChannelEndpointId::GetBootstrap()|).
  //
  // (Bootstrapping is symmetric: Both sides call this, which will establish the
  // first connection across a channel.)
  void SetBootstrapEndpoint(scoped_refptr<ChannelEndpoint> endpoint);

  // Like |SetBootstrapEndpoint()|, but with explicitly-specified local and
  // remote IDs.
  //
  // (Bootstrapping is still symmetric, though the sides should obviously
  // interchange local and remote IDs. This can be used to allow multiple
  // "bootstrap" endpoints, though this is really most useful for testing.)
  void SetBootstrapEndpointWithIds(scoped_refptr<ChannelEndpoint> endpoint,
                                   ChannelEndpointId local_id,
                                   ChannelEndpointId remote_id);

  // This forwards |message| verbatim to |raw_channel_|.
  bool WriteMessage(scoped_ptr<MessageInTransit> message);

  // See |RawChannel::IsWriteBufferEmpty()|.
  // TODO(vtl): Maybe we shouldn't expose this, and instead have a
  // |FlushWriteBufferAndShutdown()| or something like that.
  bool IsWriteBufferEmpty();

  // Removes the given endpoint from this channel (|local_id| and |remote_id|
  // are specified as an optimization; the latter should be an invalid
  // |ChannelEndpointId| if the endpoint is not yet running). Note: If this is
  // called, the |Channel| will *not* call
  // |ChannelEndpoint::DetachFromChannel()|.
  void DetachEndpoint(ChannelEndpoint* endpoint,
                      ChannelEndpointId local_id,
                      ChannelEndpointId remote_id);

  // Returns the size of a serialized endpoint (see |SerializeEndpoint...()| and
  // |DeserializeEndpoint()| below). This value will remain constant for a given
  // instance of |Channel|.
  size_t GetSerializedEndpointSize() const;

  // Endpoint serialization methods: From the |Channel|'s point of view, there
  // are three cases (discussed further below) and thus three methods.
  //
  // All three methods have a |destination| argument, which should be a buffer
  // to which auxiliary information will be written and which should be
  // transmitted to the peer |Channel| by some other means, but using this
  // |Channel|. It should be a buffer of (at least) the size returned by
  // |GetSerializedEndpointSize()| (exactly that much data will be written).
  //
  // All three also have a |message_queue| argument, which if non-null is the
  // queue of messages already received by the endpoint to be serialized.
  //
  // Note that "serialize" really means "send" -- the |endpoint| will be sent
  // "immediately". The contents of the |destination| buffer can then be used to
  // claim the rematerialized endpoint from the peer |Channel|. (|destination|
  // must be sent using this |Channel|, since otherwise it may be received
  // before it is valid to the peer |Channel|.)
  //
  // Case 1: The endpoint's peer is already closed.
  //
  // Case 2: The endpoint's peer is local (i.e., it has a
  // |ChannelEndpointClient| but no peer |ChannelEndpoint|).
  //
  // Case 3: The endpoint's peer is remote (i.e., it has a peer
  // |ChannelEndpoint|). (This has two subcases: the peer endpoint may be on
  // this |Channel| or another |Channel|.)
  void SerializeEndpointWithClosedPeer(void* destination,
                                       MessageInTransitQueue* message_queue);
  // This one returns the |ChannelEndpoint| for the serialized endpoint (which
  // can be used by, e.g., a |ProxyMessagePipeEndpoint|.
  scoped_refptr<ChannelEndpoint> SerializeEndpointWithLocalPeer(
      void* destination,
      MessageInTransitQueue* message_queue,
      ChannelEndpointClient* endpoint_client,
      unsigned endpoint_client_port);
  void SerializeEndpointWithRemotePeer(
      void* destination,
      MessageInTransitQueue* message_queue,
      scoped_refptr<ChannelEndpoint> peer_endpoint);

  // Deserializes an endpoint that was sent from the peer |Channel| (using
  // |SerializeEndpoint...()|. |source| should be (a copy of) the data that
  // |SerializeEndpoint...()| wrote, and must be (at least)
  // |GetSerializedEndpointSize()| bytes. This returns the deserialized
  // |IncomingEndpoint| (which can be converted into a |MessagePipe|) or null on
  // error.
  scoped_refptr<IncomingEndpoint> DeserializeEndpoint(const void* source);

  // See |RawChannel::GetSerializedPlatformHandleSize()|.
  size_t GetSerializedPlatformHandleSize() const;

  embedder::PlatformSupport* platform_support() const {
    return platform_support_;
  }

 private:
  friend class base::RefCountedThreadSafe<Channel>;
  ~Channel() override;

  // |RawChannel::Delegate| implementation (only called on the creation thread):
  void OnReadMessage(
      const MessageInTransit::View& message_view,
      embedder::ScopedPlatformHandleVectorPtr platform_handles) override;
  void OnError(Error error) override;

  // Helpers for |OnReadMessage| (only called on the creation thread):
  void OnReadMessageForEndpoint(
      const MessageInTransit::View& message_view,
      embedder::ScopedPlatformHandleVectorPtr platform_handles);
  void OnReadMessageForChannel(
      const MessageInTransit::View& message_view,
      embedder::ScopedPlatformHandleVectorPtr platform_handles);

  // Handles "attach and run endpoint" messages.
  bool OnAttachAndRunEndpoint(ChannelEndpointId local_id,
                              ChannelEndpointId remote_id);
  // Handles "remove endpoint" messages.
  bool OnRemoveEndpoint(ChannelEndpointId local_id,
                        ChannelEndpointId remote_id);
  // Handles "remove endpoint ack" messages.
  bool OnRemoveEndpointAck(ChannelEndpointId local_id);

  // Handles errors (e.g., invalid messages) from the remote side. Callable from
  // any thread.
  void HandleRemoteError(const char* error_message);
  // Handles internal errors/failures from the local side. Callable from any
  // thread.
  void HandleLocalError(const char* error_message);

  // Helper for |SerializeEndpoint...()|: Attaches the given (non-bootstrap)
  // endpoint to this channel and runs it. This assigns the endpoint both local
  // and remote IDs. This will also send a
  // |Subtype::CHANNEL_ATTACH_AND_RUN_ENDPOINT| message to the remote side to
  // tell it to create an endpoint as well. This returns the *remote* ID (one
  // for which |is_remote()| returns true).
  //
  // TODO(vtl): Maybe limit the number of attached message pipes.
  ChannelEndpointId AttachAndRunEndpoint(
      scoped_refptr<ChannelEndpoint> endpoint);

  // Helper to send channel control messages. Returns true on success. Callable
  // from any thread.
  bool SendControlMessage(MessageInTransit::Subtype subtype,
                          ChannelEndpointId source_id,
                          ChannelEndpointId destination_id)
      MOJO_LOCKS_EXCLUDED(mutex_);

  base::ThreadChecker creation_thread_checker_;

  embedder::PlatformSupport* const platform_support_;

  // Note: |ChannelEndpointClient|s (in particular, |MessagePipe|s) MUST NOT be
  // used under |mutex_|. E.g., |mutex_| can only be acquired after
  // |MessagePipe::lock_|, never before. Thus to call into a
  // |ChannelEndpointClient|, a reference should be acquired from
  // |local_id_to_endpoint_map_| under |mutex_| and then the lock released.
  // TODO(vtl): Annotate the above rule using |MOJO_ACQUIRED_{BEFORE,AFTER}()|,
  // once clang actually checks such annotations.
  // https://github.com/domokit/mojo/issues/313
  mutable Mutex mutex_;

  scoped_ptr<RawChannel> raw_channel_ MOJO_GUARDED_BY(mutex_);
  bool is_running_ MOJO_GUARDED_BY(mutex_);
  // Set when |WillShutdownSoon()| is called.
  bool is_shutting_down_ MOJO_GUARDED_BY(mutex_);

  // Has a reference to us.
  ChannelManager* channel_manager_ MOJO_GUARDED_BY(mutex_);

  using IdToEndpointMap =
      base::hash_map<ChannelEndpointId, scoped_refptr<ChannelEndpoint>>;
  // Map from local IDs to endpoints. If the endpoint is null, this means that
  // we're just waiting for the remove ack before removing the entry.
  IdToEndpointMap local_id_to_endpoint_map_ MOJO_GUARDED_BY(mutex_);
  // Note: The IDs generated by this should be checked for existence before use.
  LocalChannelEndpointIdGenerator local_id_generator_ MOJO_GUARDED_BY(mutex_);

  using IdToIncomingEndpointMap =
      base::hash_map<ChannelEndpointId, scoped_refptr<IncomingEndpoint>>;
  // Map from local IDs to incoming endpoints (i.e., those received inside other
  // messages, but not yet claimed via |DeserializeEndpoint()|).
  IdToIncomingEndpointMap incoming_endpoints_ MOJO_GUARDED_BY(mutex_);
  // TODO(vtl): We need to keep track of remote IDs (so that we don't collide
  // if/when we wrap).
  RemoteChannelEndpointIdGenerator remote_id_generator_ MOJO_GUARDED_BY(mutex_);

  MOJO_DISALLOW_COPY_AND_ASSIGN(Channel);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_CHANNEL_H_

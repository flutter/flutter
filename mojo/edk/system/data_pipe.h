// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_DATA_PIPE_H_
#define MOJO_EDK_SYSTEM_DATA_PIPE_H_

#include <stdint.h>

#include "base/compiler_specific.h"
#include "base/memory/scoped_ptr.h"
#include "base/synchronization/lock.h"
#include "mojo/edk/embedder/platform_handle_vector.h"
#include "mojo/edk/system/channel_endpoint_client.h"
#include "mojo/edk/system/handle_signals_state.h"
#include "mojo/edk/system/memory.h"
#include "mojo/edk/system/system_impl_export.h"
#include "mojo/public/c/system/data_pipe.h"
#include "mojo/public/c/system/types.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

class Awakable;
class AwakableList;
class Channel;
class ChannelEndpoint;
class DataPipeImpl;
class MessageInTransitQueue;

// |DataPipe| is a base class for secondary objects implementing data pipes,
// similar to |MessagePipe| (see the explanatory comment in core.cc). It is
// typically owned by the dispatcher(s) corresponding to the local endpoints.
// Its subclasses implement the three cases: local producer and consumer, local
// producer and remote consumer, and remote producer and local consumer. This
// class is thread-safe.
class MOJO_SYSTEM_IMPL_EXPORT DataPipe final : public ChannelEndpointClient {
 public:
  // The default options for |MojoCreateDataPipe()|. (Real uses should obtain
  // this via |ValidateCreateOptions()| with a null |in_options|; this is
  // exposed directly for testing convenience.)
  static MojoCreateDataPipeOptions GetDefaultCreateOptions();

  // Validates and/or sets default options for |MojoCreateDataPipeOptions|. If
  // non-null, |in_options| must point to a struct of at least
  // |in_options->struct_size| bytes. |out_options| must point to a (current)
  // |MojoCreateDataPipeOptions| and will be entirely overwritten on success (it
  // may be partly overwritten on failure).
  static MojoResult ValidateCreateOptions(
      UserPointer<const MojoCreateDataPipeOptions> in_options,
      MojoCreateDataPipeOptions* out_options);

  // Creates a local (both producer and consumer) data pipe (using
  // |LocalDataPipeImpl|. |validated_options| should be the output of
  // |ValidateOptions()|. In particular: |struct_size| is ignored (so
  // |validated_options| must be the current version of the struct) and
  // |capacity_num_bytes| must be nonzero.
  static DataPipe* CreateLocal(
      const MojoCreateDataPipeOptions& validated_options);

  // Creates a data pipe with a remote producer and a local consumer, using an
  // existing |ChannelEndpoint| (whose |ReplaceClient()| it'll call) and taking
  // |message_queue|'s contents as already-received incoming messages. If
  // |channel_endpoint| is null, this will create a "half-open" data pipe (with
  // only the consumer open). Note that this may fail, in which case it returns
  // null.
  static DataPipe* CreateRemoteProducerFromExisting(
      const MojoCreateDataPipeOptions& validated_options,
      MessageInTransitQueue* message_queue,
      ChannelEndpoint* channel_endpoint);

  // Creates a data pipe with a local producer and a remote consumer, using an
  // existing |ChannelEndpoint| (whose |ReplaceClient()| it'll call) and taking
  // |message_queue|'s contents as already-received incoming messages
  // (|message_queue| may be null). If |channel_endpoint| is null, this will
  // create a "half-open" data pipe (with only the producer open). Note that
  // this may fail, in which case it returns null.
  static DataPipe* CreateRemoteConsumerFromExisting(
      const MojoCreateDataPipeOptions& validated_options,
      size_t consumer_num_bytes,
      MessageInTransitQueue* message_queue,
      ChannelEndpoint* channel_endpoint);

  // Used by |DataPipeProducerDispatcher::Deserialize()|. Returns true on
  // success (in which case, |*data_pipe| is set appropriately) and false on
  // failure (in which case |*data_pipe| may or may not be set to null).
  static bool ProducerDeserialize(Channel* channel,
                                  const void* source,
                                  size_t size,
                                  scoped_refptr<DataPipe>* data_pipe);

  // Used by |DataPipeConsumerDispatcher::Deserialize()|. Returns true on
  // success (in which case, |*data_pipe| is set appropriately) and false on
  // failure (in which case |*data_pipe| may or may not be set to null).
  static bool ConsumerDeserialize(Channel* channel,
                                  const void* source,
                                  size_t size,
                                  scoped_refptr<DataPipe>* data_pipe);

  // These are called by the producer dispatcher to implement its methods of
  // corresponding names.
  void ProducerCancelAllAwakables();
  void ProducerClose();
  MojoResult ProducerWriteData(UserPointer<const void> elements,
                               UserPointer<uint32_t> num_bytes,
                               bool all_or_none);
  MojoResult ProducerBeginWriteData(UserPointer<void*> buffer,
                                    UserPointer<uint32_t> buffer_num_bytes,
                                    bool all_or_none);
  MojoResult ProducerEndWriteData(uint32_t num_bytes_written);
  HandleSignalsState ProducerGetHandleSignalsState();
  MojoResult ProducerAddAwakable(Awakable* awakable,
                                 MojoHandleSignals signals,
                                 uint32_t context,
                                 HandleSignalsState* signals_state);
  void ProducerRemoveAwakable(Awakable* awakable,
                              HandleSignalsState* signals_state);
  void ProducerStartSerialize(Channel* channel,
                              size_t* max_size,
                              size_t* max_platform_handles);
  bool ProducerEndSerialize(Channel* channel,
                            void* destination,
                            size_t* actual_size,
                            embedder::PlatformHandleVector* platform_handles);
  bool ProducerIsBusy() const;

  // These are called by the consumer dispatcher to implement its methods of
  // corresponding names.
  void ConsumerCancelAllAwakables();
  void ConsumerClose();
  // This does not validate its arguments, except to check that |*num_bytes| is
  // a multiple of |element_num_bytes_|.
  MojoResult ConsumerReadData(UserPointer<void> elements,
                              UserPointer<uint32_t> num_bytes,
                              bool all_or_none,
                              bool peek);
  MojoResult ConsumerDiscardData(UserPointer<uint32_t> num_bytes,
                                 bool all_or_none);
  MojoResult ConsumerQueryData(UserPointer<uint32_t> num_bytes);
  MojoResult ConsumerBeginReadData(UserPointer<const void*> buffer,
                                   UserPointer<uint32_t> buffer_num_bytes,
                                   bool all_or_none);
  MojoResult ConsumerEndReadData(uint32_t num_bytes_read);
  HandleSignalsState ConsumerGetHandleSignalsState();
  MojoResult ConsumerAddAwakable(Awakable* awakable,
                                 MojoHandleSignals signals,
                                 uint32_t context,
                                 HandleSignalsState* signals_state);
  void ConsumerRemoveAwakable(Awakable* awakable,
                              HandleSignalsState* signals_state);
  void ConsumerStartSerialize(Channel* channel,
                              size_t* max_size,
                              size_t* max_platform_handles);
  bool ConsumerEndSerialize(Channel* channel,
                            void* destination,
                            size_t* actual_size,
                            embedder::PlatformHandleVector* platform_handles);
  bool ConsumerIsBusy() const;

  // The following are only to be used by |DataPipeImpl| (and its subclasses):

  // Replaces |impl_| with |new_impl| (which must not be null). For use when
  // serializing data pipe dispatchers (i.e., in |ProducerEndSerialize()| and
  // |ConsumerEndSerialize()|). Returns the old value of |impl_| (in case the
  // caller needs to manage its lifetime).
  scoped_ptr<DataPipeImpl> ReplaceImplNoLock(scoped_ptr<DataPipeImpl> new_impl);
  void SetProducerClosedNoLock();
  void SetConsumerClosedNoLock();

  void ProducerCloseNoLock();
  void ConsumerCloseNoLock();

  // Thread-safe and fast (they don't take the lock):
  const MojoCreateDataPipeOptions& validated_options() const {
    return validated_options_;
  }
  size_t element_num_bytes() const {
    return validated_options_.element_num_bytes;
  }
  size_t capacity_num_bytes() const {
    return validated_options_.capacity_num_bytes;
  }

  // Must be called under lock.
  bool producer_open_no_lock() const {
    lock_.AssertAcquired();
    return producer_open_;
  }
  bool consumer_open_no_lock() const {
    lock_.AssertAcquired();
    return consumer_open_;
  }
  uint32_t producer_two_phase_max_num_bytes_written_no_lock() const {
    lock_.AssertAcquired();
    return producer_two_phase_max_num_bytes_written_;
  }
  uint32_t consumer_two_phase_max_num_bytes_read_no_lock() const {
    lock_.AssertAcquired();
    return consumer_two_phase_max_num_bytes_read_;
  }
  void set_producer_two_phase_max_num_bytes_written_no_lock(
      uint32_t num_bytes) {
    lock_.AssertAcquired();
    producer_two_phase_max_num_bytes_written_ = num_bytes;
  }
  void set_consumer_two_phase_max_num_bytes_read_no_lock(uint32_t num_bytes) {
    lock_.AssertAcquired();
    consumer_two_phase_max_num_bytes_read_ = num_bytes;
  }
  bool producer_in_two_phase_write_no_lock() const {
    lock_.AssertAcquired();
    return producer_two_phase_max_num_bytes_written_ > 0;
  }
  bool consumer_in_two_phase_read_no_lock() const {
    lock_.AssertAcquired();
    return consumer_two_phase_max_num_bytes_read_ > 0;
  }

 private:
  // |validated_options| should be the output of |ValidateOptions()|. In
  // particular: |struct_size| is ignored (so |validated_options| must be the
  // current version of the struct) and |capacity_num_bytes| must be nonzero.
  // TODO(vtl): |has_local_producer|/|has_local_consumer| shouldn't really be
  // arguments here. Instead, they should be determined from the |impl| ... but
  // the |impl|'s typically figures these out by examining the owner, i.e., the
  // |DataPipe| object. Probably, this indicates that more stuff should be moved
  // to |DataPipeImpl|, but for now we'll live with this.
  DataPipe(bool has_local_producer,
           bool has_local_consumer,
           const MojoCreateDataPipeOptions& validated_options,
           scoped_ptr<DataPipeImpl> impl);
  ~DataPipe() override;

  // |ChannelEndpointClient| implementation:
  bool OnReadMessage(unsigned port, MessageInTransit* message) override;
  void OnDetachFromChannel(unsigned port) override;

  void AwakeProducerAwakablesForStateChangeNoLock(
      const HandleSignalsState& new_producer_state);
  void AwakeConsumerAwakablesForStateChangeNoLock(
      const HandleSignalsState& new_consumer_state);

  void SetProducerClosed();
  void SetConsumerClosed();

  bool has_local_producer_no_lock() const {
    lock_.AssertAcquired();
    return !!producer_awakable_list_;
  }
  bool has_local_consumer_no_lock() const {
    lock_.AssertAcquired();
    return !!consumer_awakable_list_;
  }

  MSVC_SUPPRESS_WARNING(4324)
  const MojoCreateDataPipeOptions validated_options_;

  mutable base::Lock lock_;  // Protects the following members.
  // *Known* state of producer or consumer.
  bool producer_open_;
  bool consumer_open_;
  // Non-null only if the producer or consumer, respectively, is local.
  scoped_ptr<AwakableList> producer_awakable_list_;
  scoped_ptr<AwakableList> consumer_awakable_list_;
  // These are nonzero if and only if a two-phase write/read is in progress.
  uint32_t producer_two_phase_max_num_bytes_written_;
  uint32_t consumer_two_phase_max_num_bytes_read_;
  scoped_ptr<DataPipeImpl> impl_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(DataPipe);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_DATA_PIPE_H_

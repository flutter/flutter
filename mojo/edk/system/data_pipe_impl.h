// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_DATA_PIPE_IMPL_H_
#define MOJO_EDK_SYSTEM_DATA_PIPE_IMPL_H_

#include <stdint.h>

#include "mojo/edk/embedder/platform_handle_vector.h"
#include "mojo/edk/system/data_pipe.h"
#include "mojo/edk/system/handle_signals_state.h"
#include "mojo/edk/system/memory.h"
#include "mojo/edk/system/system_impl_export.h"
#include "mojo/public/c/system/data_pipe.h"
#include "mojo/public/c/system/macros.h"
#include "mojo/public/c/system/types.h"

namespace mojo {
namespace system {

class Channel;
class MessageInTransit;

// Base class/interface for classes that "implement" |DataPipe| for various
// situations (local versus remote). The methods, other than the constructor,
// |set_owner()|, and the destructor, are always protected by |DataPipe|'s
// |lock_|.
class MOJO_SYSTEM_IMPL_EXPORT DataPipeImpl {
 public:
  virtual ~DataPipeImpl() {}

  // This is only called by |DataPipe| during its construction.
  void set_owner(DataPipe* owner) { owner_ = owner; }

  virtual void ProducerClose() = 0;
  // |num_bytes.Get()| will be a nonzero multiple of |element_num_bytes()|.
  virtual MojoResult ProducerWriteData(UserPointer<const void> elements,
                                       UserPointer<uint32_t> num_bytes,
                                       uint32_t max_num_bytes_to_write,
                                       uint32_t min_num_bytes_to_write) = 0;
  virtual MojoResult ProducerBeginWriteData(
      UserPointer<void*> buffer,
      UserPointer<uint32_t> buffer_num_bytes,
      uint32_t min_num_bytes_to_write) = 0;
  virtual MojoResult ProducerEndWriteData(uint32_t num_bytes_written) = 0;
  // Note: A producer should not be writable during a two-phase write.
  virtual HandleSignalsState ProducerGetHandleSignalsState() const = 0;
  virtual void ProducerStartSerialize(Channel* channel,
                                      size_t* max_size,
                                      size_t* max_platform_handles) = 0;
  virtual bool ProducerEndSerialize(
      Channel* channel,
      void* destination,
      size_t* actual_size,
      embedder::PlatformHandleVector* platform_handles) = 0;

  virtual void ConsumerClose() = 0;
  // |num_bytes.Get()| will be a nonzero multiple of |element_num_bytes()|.
  virtual MojoResult ConsumerReadData(UserPointer<void> elements,
                                      UserPointer<uint32_t> num_bytes,
                                      uint32_t max_num_bytes_to_read,
                                      uint32_t min_num_bytes_to_read,
                                      bool peek) = 0;
  virtual MojoResult ConsumerDiscardData(UserPointer<uint32_t> num_bytes,
                                         uint32_t max_num_bytes_to_discard,
                                         uint32_t min_num_bytes_to_discard) = 0;
  // |num_bytes.Get()| will be a nonzero multiple of |element_num_bytes()|.
  virtual MojoResult ConsumerQueryData(UserPointer<uint32_t> num_bytes) = 0;
  virtual MojoResult ConsumerBeginReadData(
      UserPointer<const void*> buffer,
      UserPointer<uint32_t> buffer_num_bytes,
      uint32_t min_num_bytes_to_read) = 0;
  virtual MojoResult ConsumerEndReadData(uint32_t num_bytes_read) = 0;
  // Note: A consumer should not be writable during a two-phase read.
  virtual HandleSignalsState ConsumerGetHandleSignalsState() const = 0;
  virtual void ConsumerStartSerialize(Channel* channel,
                                      size_t* max_size,
                                      size_t* max_platform_handles) = 0;
  virtual bool ConsumerEndSerialize(
      Channel* channel,
      void* destination,
      size_t* actual_size,
      embedder::PlatformHandleVector* platform_handles) = 0;

  virtual bool OnReadMessage(unsigned port, MessageInTransit* message) = 0;
  virtual void OnDetachFromChannel(unsigned port) = 0;

 protected:
  DataPipeImpl() : owner_() {}

  // Helper to convert the given circular buffer into messages. The input is a
  // circular buffer |buffer| (with appropriate element size and capacity), with
  // current contents starting at |start_index| of length |current_num_bytes|.
  // This will convert all of the contents.
  void ConvertDataToMessages(const char* buffer,
                             size_t* start_index,
                             size_t* current_num_bytes,
                             MessageInTransitQueue* message_queue);

  DataPipe* owner() const { return owner_; }

  const MojoCreateDataPipeOptions& validated_options() const {
    return owner_->validated_options();
  }
  size_t element_num_bytes() const { return owner_->element_num_bytes(); }
  size_t capacity_num_bytes() const { return owner_->capacity_num_bytes(); }
  bool producer_open() const { return owner_->producer_open_no_lock(); }
  bool consumer_open() const { return owner_->consumer_open_no_lock(); }
  uint32_t producer_two_phase_max_num_bytes_written() const {
    return owner_->producer_two_phase_max_num_bytes_written_no_lock();
  }
  uint32_t consumer_two_phase_max_num_bytes_read() const {
    return owner_->consumer_two_phase_max_num_bytes_read_no_lock();
  }
  void set_producer_two_phase_max_num_bytes_written(uint32_t num_bytes) {
    owner_->set_producer_two_phase_max_num_bytes_written_no_lock(num_bytes);
  }
  void set_consumer_two_phase_max_num_bytes_read(uint32_t num_bytes) {
    owner_->set_consumer_two_phase_max_num_bytes_read_no_lock(num_bytes);
  }
  bool producer_in_two_phase_write() const {
    return owner_->producer_in_two_phase_write_no_lock();
  }
  bool consumer_in_two_phase_read() const {
    return owner_->consumer_in_two_phase_read_no_lock();
  }

 private:
  DataPipe* owner_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(DataPipeImpl);
};

// TODO(vtl): This is not the ideal place for the following structs; find
// somewhere better.

// Serialized form of a producer dispatcher. This will actually be followed by a
// serialized |ChannelEndpoint|; we want to preserve alignment guarantees.
struct MOJO_ALIGNAS(8) SerializedDataPipeProducerDispatcher {
  // Only validated (and thus canonicalized) options should be serialized.
  // However, the deserializer must revalidate (as with everything received).
  MojoCreateDataPipeOptions validated_options;
  // Number of bytes already enqueued to the consumer. Set to
  // |static_cast<size_t>(-1)| if the consumer is already closed, in which case
  // this will *not* be followed by a serialized |ChannelEndpoint|.
  size_t consumer_num_bytes;
};

// Serialized form of a consumer dispatcher. This will actually be followed by a
// serialized |ChannelEndpoint|; we want to preserve alignment guarantees.
struct MOJO_ALIGNAS(8) SerializedDataPipeConsumerDispatcher {
  // Only validated (and thus canonicalized) options should be serialized.
  // However, the deserializer must revalidate (as with everything received).
  MojoCreateDataPipeOptions validated_options;
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_DATA_PIPE_IMPL_H_

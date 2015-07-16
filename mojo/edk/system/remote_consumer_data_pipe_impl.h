// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_REMOTE_CONSUMER_DATA_PIPE_IMPL_H_
#define MOJO_EDK_SYSTEM_REMOTE_CONSUMER_DATA_PIPE_IMPL_H_

#include "base/memory/aligned_memory.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "mojo/edk/system/channel_endpoint.h"
#include "mojo/edk/system/data_pipe_impl.h"
#include "mojo/edk/system/system_impl_export.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

// |RemoteConsumerDataPipeImpl| is a subclass that "implements" |DataPipe| for
// data pipes whose producer is local and whose consumer is remote. See
// |DataPipeImpl| for more details.
class MOJO_SYSTEM_IMPL_EXPORT RemoteConsumerDataPipeImpl final
    : public DataPipeImpl {
 public:
  RemoteConsumerDataPipeImpl(ChannelEndpoint* channel_endpoint,
                             size_t consumer_num_bytes);
  ~RemoteConsumerDataPipeImpl() override;

  // Processes messages that were received and queued by an |IncomingEndpoint|.
  // |*consumer_num_bytes| should be set to the value from the
  // |SerializedDataPipeProducerDispatcher|. On success, returns true and
  // updates |*consumer_num_bytes|. On failure, returns false (it may or may not
  // modify |*consumer_num_bytes|). Always clears |*messages|.
  static bool ProcessMessagesFromIncomingEndpoint(
      const MojoCreateDataPipeOptions& validated_options,
      size_t* consumer_num_bytes,
      MessageInTransitQueue* messages);

 private:
  // |DataPipeImpl| implementation:
  // Note: None of the |Consumer...()| methods should be called, except
  // |ConsumerGetHandleSignalsState()|.
  void ProducerClose() override;
  MojoResult ProducerWriteData(UserPointer<const void> elements,
                               UserPointer<uint32_t> num_bytes,
                               uint32_t max_num_bytes_to_write,
                               uint32_t min_num_bytes_to_write) override;
  MojoResult ProducerBeginWriteData(UserPointer<void*> buffer,
                                    UserPointer<uint32_t> buffer_num_bytes,
                                    uint32_t min_num_bytes_to_write) override;
  MojoResult ProducerEndWriteData(uint32_t num_bytes_written) override;
  HandleSignalsState ProducerGetHandleSignalsState() const override;
  void ProducerStartSerialize(Channel* channel,
                              size_t* max_size,
                              size_t* max_platform_handles) override;
  bool ProducerEndSerialize(
      Channel* channel,
      void* destination,
      size_t* actual_size,
      embedder::PlatformHandleVector* platform_handles) override;
  void ConsumerClose() override;
  MojoResult ConsumerReadData(UserPointer<void> elements,
                              UserPointer<uint32_t> num_bytes,
                              uint32_t max_num_bytes_to_read,
                              uint32_t min_num_bytes_to_read,
                              bool peek) override;
  MojoResult ConsumerDiscardData(UserPointer<uint32_t> num_bytes,
                                 uint32_t max_num_bytes_to_discard,
                                 uint32_t min_num_bytes_to_discard) override;
  MojoResult ConsumerQueryData(UserPointer<uint32_t> num_bytes) override;
  MojoResult ConsumerBeginReadData(UserPointer<const void*> buffer,
                                   UserPointer<uint32_t> buffer_num_bytes,
                                   uint32_t min_num_bytes_to_read) override;
  MojoResult ConsumerEndReadData(uint32_t num_bytes_read) override;
  HandleSignalsState ConsumerGetHandleSignalsState() const override;
  void ConsumerStartSerialize(Channel* channel,
                              size_t* max_size,
                              size_t* max_platform_handles) override;
  bool ConsumerEndSerialize(
      Channel* channel,
      void* destination,
      size_t* actual_size,
      embedder::PlatformHandleVector* platform_handles) override;
  bool OnReadMessage(unsigned port, MessageInTransit* message) override;
  void OnDetachFromChannel(unsigned port) override;

  void EnsureBuffer();
  void DestroyBuffer();

  void Disconnect();

  // Should be valid if and only if |consumer_open()| returns true.
  scoped_refptr<ChannelEndpoint> channel_endpoint_;

  // The number of bytes we've sent the consumer, but don't *know* have been
  // consumed.
  size_t consumer_num_bytes_;

  // Used for two-phase writes.
  scoped_ptr<char, base::AlignedFreeDeleter> buffer_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(RemoteConsumerDataPipeImpl);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_REMOTE_CONSUMER_DATA_PIPE_IMPL_H_

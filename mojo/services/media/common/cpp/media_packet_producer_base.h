// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_MEDIA_COMMON_CPP_MEDIA_PACKET_PRODUCER_BASE_H_
#define MOJO_SERVICES_MEDIA_COMMON_CPP_MEDIA_PACKET_PRODUCER_BASE_H_

#include <limits>
#include <mutex>

#include "mojo/services/flog/cpp/flog.h"
#include "mojo/services/media/common/cpp/shared_buffer_set_allocator.h"
#include "mojo/services/media/common/cpp/thread_checker.h"
#include "mojo/services/media/common/interfaces/media_transport.mojom.h"
#include "mojo/services/media/logs/interfaces/media_packet_producer_channel.mojom.h"

namespace mojo {
namespace media {

// Base class for clients of MediaPacketConsumer.
class MediaPacketProducerBase {
 public:
  using ProducePacketCallback = std::function<void()>;

  MediaPacketProducerBase();

  virtual ~MediaPacketProducerBase();

  // Connects to the indicated consumer.
  void Connect(MediaPacketConsumerPtr consumer,
               const MediaPacketProducer::ConnectCallback& callback);

  // Disconnects from the consumer.
  void Disconnect() { consumer_.reset(); }

  // Determines if we are connected to a consumer.
  bool is_connected() { return consumer_.is_bound(); }

  // Resets to initial state.
  void Reset();

  // Flushes the consumer.
  void FlushConsumer(const MediaPacketConsumer::FlushCallback& callback);

  // Allocates a payload buffer of the specified size.
  void* AllocatePayloadBuffer(size_t size);

  // Releases a payload buffer obtained via AllocatePayloadBuffer.
  void ReleasePayloadBuffer(void* buffer);

  // Produces a packet and supplies it to the consumer.
  void ProducePacket(void* payload,
                     size_t size,
                     int64_t pts,
                     bool end_of_stream,
                     const ProducePacketCallback& callback);

  // Gets the current demand.
  const MediaPacketDemand& demand() const { return demand_; }

  // Determines whether the consumer is currently demanding a packet. The
  // |additional_packets_outstanding| parameter indicates the number of packets
  // that should be added to the current outstanding packet count when
  // determining demand. For example, a value of 1 means that the function
  // should determine demand as if one additional packet was outstanding.
  bool ShouldProducePacket(uint32_t additional_packets_outstanding);

 protected:
  // Called when demand is updated. If demand is updated in a SupplyPacket
  // callback, the DemandUpdatedCallback is called before the
  // ProducePacketCallback.
  // NOTE: We could provide a default implementation, but that makes 'this'
  // have a null value during member initialization, thereby breaking
  // FLOG_INSTANCE_CHANNEL. As a workaround, this method has been made pure
  // virtual.
  virtual void OnDemandUpdated(uint32_t min_packets_outstanding,
                               int64_t min_pts) = 0;

  // Called when a fatal error occurs. The default implementation does nothing.
  virtual void OnFailure();

 private:
  // Handles a demand update callback or, if called with default parameters,
  // initiates demand update requests.
  void HandleDemandUpdate(MediaPacketDemandPtr demand = nullptr);

  // Updates demand_ and calls demand_update_callback_ if it's set and demand
  // has changed.
  void UpdateDemand(const MediaPacketDemand& demand);

  SharedBufferSetAllocator allocator_;
  MediaPacketConsumerPtr consumer_;
  bool flush_in_progress_ = false;
  uint64_t prev_packet_label_ = 0;

  mutable std::mutex lock_;
  // Fields below are protected by lock_.
  MediaPacketDemand demand_;
  uint32_t packets_outstanding_ = 0;
  int64_t pts_last_produced_ = std::numeric_limits<int64_t>::min();
  bool end_of_stream_ = false;
  // Fields above are protected by lock_.

  DECLARE_THREAD_CHECKER(thread_checker_);

  FLOG_INSTANCE_CHANNEL(logs::MediaPacketProducerChannel, log_channel_);
};

}  // namespace media
}  // namespace mojo

#endif  // MOJO_SERVICES_MEDIA_COMMON_CPP_MEDIA_PACKET_PRODUCER_BASE_H_

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_MEDIA_COMMON_CPP_CIRCULAR_BUFFER_MEDIA_PIPE_ADAPTER_H_
#define MOJO_SERVICES_MEDIA_COMMON_CPP_CIRCULAR_BUFFER_MEDIA_PIPE_ADAPTER_H_

#include <atomic>
#include <deque>
#include <functional>
#include <limits>

#include "mojo/public/cpp/bindings/callback.h"
#include "mojo/public/cpp/environment/logging.h"
#include "mojo/services/media/common/interfaces/media_common.mojom.h"
#include "mojo/services/media/common/interfaces/media_transport.mojom.h"

namespace mojo {
namespace media {

// A class to help producers of media with the bookkeeping involved in using the
// shared buffer provided by a MediaConsumer mojo interface in a circular buffer
// fashion.
//
class CircularBufferMediaPipeAdapter {
 public:
  class MappedPacket {
   public:
    static constexpr size_t kMaxRegions = 2;
    MappedPacket();
    ~MappedPacket();

    const MediaPacketPtr& packet() const { return packet_; }

    void* data(size_t index) const {
      MOJO_DCHECK(index < MOJO_ARRAYSIZE(data_));
      return data_[index];
    }

    uint64_t length(size_t index) const {
      MOJO_DCHECK(index < MOJO_ARRAYSIZE(length_));
      return length_[index];
    }

   private:
    friend class CircularBufferMediaPipeAdapter;

    void Reset() {
      packet_.reset();
      data_[0] = data_[1] = nullptr;
      length_[0] = length_[1] = 0;
      cancel_wr_ = 0;
    }

    MediaPacketPtr packet_;
    void*    data_[2];
    uint64_t length_[2];
    uint64_t cancel_wr_;
    uint32_t flush_generation_;
  };

  /**
   * A callback definition, registered by users of the adapter.  The callback
   * will be called any time the adapter is in the signalled state, either
   * because there is room for more data in the pipe, or because the pipe has
   * entered into a fatal, unrecoverable state.
   *
   * @param state The current state of the adapter.  If the state is anything
   * but MediaResult::OK, the pipe is in a fatal, unrecoverable error state.
   */
  using SignalCbk = std::function<void(MediaResult state)>;

  /**
   * Constructor
   *
   * Create an adapter which will take ownership of the provided MediaConsumer
   * interface and assist in the process of generating MediaPackets and
   * marshalling them to the other side of the MediaConsumer.
   *
   * @param pipe A pointer to the MediaConsumer interface which will be used as
   * the target for MediaPackets.
   */
  explicit CircularBufferMediaPipeAdapter(MediaConsumerPtr pipe);

  /**
   * Destructor
   */
  ~CircularBufferMediaPipeAdapter();

  /**
   * Init
   *
   * Allocate a shared memory buffer of the specified size and begin the process
   * of marshalling it to the other side of the MediaConsumer.
   *
   * @param size The size in bytes of the shared memory buffer to allocate.
   */
  void Init(uint64_t size);

  /**
   * Set the signal callback for this media pipe adapter.  This callback will be
   * called when the adapter transitions from un-signalled to signalled and has
   * a valid callback, or when a valid callback is assigned (via a call to
   * Setllback) and the adapter is currently in the signalled state.
   *
   * Any callbacks in flight are guaranteed to be canceled or executed to
   * completion when SetCallback returns.
   *
   * It is the adapter's user's responsibility to manage the lifetime of the
   * callback and the adapter, and ensure that the callback is valid as long as
   * it is assigned to a adapter instance.
   *
   * @param cbk A reference to the callback to execute when the adapter becomes
   * signalled.  Pass nullptr to cancel any pending callbacks.
   */
  void SetSignalCallback(SignalCbk cbk);

  /**
   * Clear any existing signal callback.  Callbacks will no longer be made, even
   * if the adapter is in the signalled state.
   */
  void ResetSignalCallback() { SetSignalCallback(nullptr); }

  /**
   * Set the water marks (in bytes) for determining the signalled/un-signalled
   * state of the pipe.
   *
   * When the amount of data pending consumption in the pipe drops below the low
   * water mark (pending < mark), the pipe becomes signalled and any valid
   * callback which was previously set will be scheduled on the current run
   * queue.
   *
   * When the amount of data pending consumption in the pipe drops grows beyond
   * the high water mark (pending >= mark), the pipe becomes un-signalled no
   * further callbacks will be made until the amount of pending data falls below
   * the low water mark again.
   *
   * The adapter becomes un-signalled when the amount of pending data in it
   * exceeds the high water mark.  It will become signalled when the amount of
   * pending data in it is less than or equal to the low water mark.
   *
   * It is an error to set a hi/lo water mark pair such that lo > hi, and will
   * be ignored in non-debug builds.
   *
   * @param hi_water_mark The new value, in bytes, of the hi water mark to set.
   * @param lo_water_mark The new value, in bytes, of the lo water mark to set.
   */
  void SetWatermarks(uint64_t hi_water_mark, uint64_t lo_water_mark);

  /**
   * Attempt to create a media packet, reserving memory in the circular buffer
   * in the process.  Note, once created, packets must be sent in the same order
   * they were created, or canceled in they inverse order they were created.
   * Failure to follow these guidelines will result in an internal bookkeeping
   * error, and the pipe needing to reset/flush its state in order to recover.
   *
   * @param [in]  size The size, in bytes of the packet to create.
   * @param [in]  no_wrap When true, guarantees that the created packet will be
   *                      offset in way which guarantees that it does not wrap
   *                      around the internal circular buffer boundary.
   * @param [out] packet A structure which, upon success, will contain up to two
   *                     pointer and lengths describing the packet's payload in
   *                     shared memory, as well as a pointer to the packet
   *                     itself.
   * @return A media result indicating the success or failure of the operation.
   *
   * Possible failure codes include...
   *
   * MediaResult::BAD_STATE :
   * The pipe is in a faulted state.
   *
   * MediaResult::BUSY :
   * The pipe is in the middle of a flush operation, or waiting to fetch its
   * initial state.
   *
   * MediaResult::INSUFFICIENT_RESOURCES :
   * There is currently not enough space in the buffer to accommodate the
   * request.
   */
  MediaResult CreateMediaPacket(uint64_t size,
                                bool no_wrap,
                                MappedPacket* packet);

  /**
   * Send a previously created media packet across the pipe to the consumer.
   * @param [in] packet The pointer to the structure which describes the packet
   *                    to be sent.
   * @return A media result indicating the success or failure of the operation.
   */
  MediaResult SendMediaPacket(
      MappedPacket* packet,
      const MediaConsumer::SendPacketCallback& cbk =
        MediaConsumer::SendPacketCallback());

  /**
   * Cancel a packet previously created using CreateMediaPacket.
   * @note The packet canceled must not have been sent, and must be the most
   * recent non-canceled packet created using CreateMediaPacket.
   * @param [in] packet The pointer to the structure which describes the packet
   *                    to be canceled.
   * @return A media result indicating the success or failure of the operation.
   */
  MediaResult CancelMediaPacket(MappedPacket* packet);

  /**
   * Flush the media pipe.  Cancels all in flight payloads and resets the
   * internal bookkeeping.
   *
   * @note The media pipe will be un-signalled and unavailable for Create/Send
   * operations during the flush.
   */
  MediaResult Flush();

  uint64_t GetPending() const;
  uint64_t GetBufferSize() const;
  uint64_t AboveHiWater() const { return GetPending() >= hi_water_mark_; }
  uint64_t BelowLoWater() const { return GetPending() <  lo_water_mark_; }

 private:
  struct PacketState {
    PacketState(uint64_t post_consume_rd,
                uint32_t seq_num,
                const MediaConsumer::SendPacketCallback& cbk);
    ~PacketState();

    uint64_t post_consume_rd_;
    uint32_t seq_num_;
    MediaConsumer::SendPacketCallback cbk_;
  };
  using PacketStateQueue = std::deque<PacketState>;

  void HandleSendPacket(uint32_t seq_num, MediaConsumer::SendResult result);
  void HandleFlush();
  void HandleSignalCallback();

  void UpdateSignalled();
  void Fault(MediaResult reason);
  void Cleanup();

  bool Faulted() const {
    return (MediaResult::OK != internal_state_);
  }

  bool Busy() const {
    return flush_in_progress_;
  }

  // Pipe interface callbacks
  MediaConsumerPtr pipe_;
  MediaConsumer::FlushCallback pipe_flush_cbk_;
  Closure                      signalled_callback_;

  // A small helper which lets us nerf callbacks we may have directly scheduled
  // on the main run loop which may be in flight as we get destroyed.
  std::shared_ptr<CircularBufferMediaPipeAdapter*> thiz_;

  // State for managing signalled/un-signalled status and signal callbacks.
  SignalCbk signal_cbk_;
  bool      flush_in_progress_ = false;
  bool      fault_cbk_made_ = false;
  bool      cbk_scheduled_ = false;
  uint64_t  hi_water_mark_ = 0u;
  uint64_t  lo_water_mark_ = 0u;
  bool      signalled_ = false;

  MediaResult internal_state_ = MediaResult::OK;

  ScopedSharedBufferHandle buffer_handle_;
  void*    buffer_ = nullptr;
  uint64_t buffer_size_ = 0;
  uint64_t rd_, wr_;

  // Packet queue state
  std::atomic<uint32_t> flush_generation_;
  std::atomic<uint32_t> seq_num_gen_;
  PacketStateQueue in_flight_queue_;
};

}  // namespace media
}  // namespace mojo

#endif  // MOJO_SERVICES_MEDIA_COMMON_CPP_CIRCULAR_BUFFER_MEDIA_PIPE_ADAPTER_H_

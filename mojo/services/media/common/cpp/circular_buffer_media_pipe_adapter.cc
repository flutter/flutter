// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/environment/logging.h"
#include "mojo/public/cpp/utility/run_loop.h"
#include "mojo/services/media/common/cpp/circular_buffer_media_pipe_adapter.h"
#include "mojo/services/media/common/interfaces/media_common.mojom.h"
#include "mojo/services/media/common/interfaces/media_pipe.mojom.h"

namespace mojo {
namespace media {

constexpr size_t CircularBufferMediaPipeAdapter::MappedPacket::kMaxRegions;
CircularBufferMediaPipeAdapter::MappedPacket::MappedPacket() { }
CircularBufferMediaPipeAdapter::MappedPacket::~MappedPacket() {
  // If packet_ is non-null, it means that someone created a MappedPacket using
  // CreateMediaPacket, but they never sent it, and never canceled it.
  //
  // TODO(johngro): Should we maintain a reference to our pipe adapter and just
  // auto cancel this packet if the user forgets?  This could be Very Bad if
  // they have created and forgotten about multiple packets.
  MOJO_DCHECK(packet_.is_null());
}

CircularBufferMediaPipeAdapter::PacketState::PacketState(
    uint64_t post_consume_rd,
    uint32_t seq_num,
    const MediaPipe::SendPacketCallback& cbk)
  : post_consume_rd_(post_consume_rd),
    seq_num_(seq_num),
    cbk_(cbk) {}
CircularBufferMediaPipeAdapter::PacketState::~PacketState() { }

CircularBufferMediaPipeAdapter::CircularBufferMediaPipeAdapter(
    MediaPipePtr pipe)
  : pipe_(pipe.Pass())
  , thiz_(new CircularBufferMediaPipeAdapter*(this)) {
  MOJO_DCHECK(pipe_);
  MOJO_DCHECK(RunLoop::current());

  pipe_flush_cbk_ = MediaPipe::FlushCallback(
  [this] () {
    HandleFlush();
  });

  pipe_.set_connection_error_handler(
  [this]() {
    Fault(MediaResult::CONNECTION_LOST);
  });

  std::shared_ptr<CircularBufferMediaPipeAdapter*> thiz(thiz_);
  signalled_callback_ = Closure(
  [thiz] () {
    if (*thiz) {
      (*thiz)->HandleSignalCallback();
    }
  });
}

CircularBufferMediaPipeAdapter::~CircularBufferMediaPipeAdapter() {
  *thiz_ = nullptr;
  Cleanup();
}

void CircularBufferMediaPipeAdapter::Init(uint64_t size) {
  // Double Init?  Fault unless the user is asking us to set up a buffer of the
  // same size.
  if (buffer_handle_.is_valid()) {
    if (buffer_size_ != size) {
      Fault(MediaResult::BAD_STATE);
    }
    return;
  }

  // Make the buffer
  MojoResult res = CreateSharedBuffer(nullptr, size, &buffer_handle_);
  if (res != MOJO_RESULT_OK) {
    MOJO_LOG(ERROR) << "Failed to allocate buffer of size " << size
                    << " in " << __PRETTY_FUNCTION__
                    << " (error " << res << ")";
    Fault(MediaResult::INSUFFICIENT_RESOURCES);
    return;
  }

  buffer_size_ = size;

  // Map the buffer
  //
  // TODO(johngro) : We really only need write access to this buffer.
  // Ideally, we could request that using flags, but there does not seem to be
  // a way to do this right now.
  res = MapBuffer(buffer_handle_.get(),
                  0,
                  buffer_size_,
                  &buffer_,
                  MOJO_MAP_BUFFER_FLAG_NONE);
  if (res != MOJO_RESULT_OK) {
    MOJO_LOG(ERROR) << "Failed to map buffer in " << __PRETTY_FUNCTION__
                    << " (error " << res << ")";
    Fault(MediaResult::UNKNOWN_ERROR);
    return;
  }

  // Duplicate the buffer and send it to the other side of the pipe.
  //
  // TODO(johngro) : It would be nice if we could restrict this handle to be
  // read-only.
  ScopedSharedBufferHandle duplicated_handle;
  res = DuplicateBuffer(buffer_handle_.get(), nullptr, &duplicated_handle);
  if (res != MOJO_RESULT_OK) {
    MOJO_LOG(ERROR) << "Failed to duplicate handle in " << __PRETTY_FUNCTION__
                    << " (error " << res << ")";
    Fault(MediaResult::UNKNOWN_ERROR);
    return;
  }

  // TODO(johngro) : We should not have to send the buffer size, it should be an
  // intrinsic property of the buffer itself and be query-able via the handle.
  pipe_->SetBuffer(duplicated_handle.Pass(), buffer_size_);
}

void CircularBufferMediaPipeAdapter::SetSignalCallback(SignalCbk cbk) {
  bool schedule;
  signal_cbk_ = cbk;
  schedule = (signal_cbk_ != nullptr);

  // If the user supplied a non-null callback, make sure we schedule a
  // callback if we are currently signalled.
  if (schedule) {
    UpdateSignalled();
  }
}

void CircularBufferMediaPipeAdapter::SetWatermarks(uint64_t hi_water_mark,
                                                   uint64_t lo_water_mark) {
  // Nothing to do if the arguments make no sense.
  MOJO_DCHECK(hi_water_mark >= lo_water_mark);
  if (hi_water_mark < lo_water_mark) {
    return;
  }

  hi_water_mark_ = hi_water_mark;
  lo_water_mark_ = lo_water_mark;

  // Marks have moved, check if we should be signalled or not as a result.
  UpdateSignalled();
}

MediaResult CircularBufferMediaPipeAdapter::CreateMediaPacket(
    uint64_t size,
    bool no_wrap,
    MappedPacket* packet) {
  // Args ok?
  MOJO_DCHECK(packet);
  if (nullptr == packet) {
    return MediaResult::INVALID_ARGUMENT;
  }

  // If we are faulted, or busy, we cannot proceed.
  if (Faulted()) { return MediaResult::BAD_STATE; }
  if (Busy())    { return MediaResult::BUSY; }

  // Are we attempting to allocate something larger than the buffer can
  // possibly hold?
  MOJO_DCHECK(buffer_size_);
  if (size > (buffer_size_ - 1)) {
    return MediaResult::INSUFFICIENT_RESOURCES;
  }

  // Where should this allocation begin?
  //
  // If no-wrap was requested, and the end of the buffer comes before the read
  // pointer, and the distance between the write pointer and the end of the
  // buffer is too small to hold the requested size, then we need to pad out
  // to the start of the circular buffer.  Otherwise, the allocation can start
  // where the write pointer currently is.
  //
  // TODO(johngro): someday, take alignment restrictions into account.
  uint64_t alloc_start = wr_;
  if ((no_wrap) && (wr_ > rd_) && ((buffer_size_ - wr_) < size)) {
    alloc_start = 0;
  } else {
    alloc_start = wr_;
  }

  // Where should this allocation end, in non-modulo space?
  uint64_t alloc_end = alloc_start + size;

  // Does the end of the buffer exist within the pending region of the buffer?
  // If so, we do not have the space for this packet's payload.
  MOJO_DCHECK(wr_ < buffer_size_);
  MOJO_DCHECK(rd_ < buffer_size_);
  uint64_t non_mod_wr = wr_ + ((rd_ > wr_) ? buffer_size_ : 0);
  MOJO_DCHECK(non_mod_wr >= rd_);
  if ((alloc_end >= rd_) && (alloc_end < non_mod_wr)) {
    return MediaResult::INSUFFICIENT_RESOURCES;
  }

  // Looks like we have the room.  Allocate and fill out our packet.
  const MediaPacketPtr& p = (packet->packet_ = MediaPacket::New());
  const MediaPacketRegionPtr& r1 = (p->payload = MediaPacketRegion::New());
  const MediaPacketRegionPtr* r2 = nullptr;

  r1->offset = alloc_start;

  if (alloc_end > buffer_size_) {
    p->extra_payload    = Array<MediaPacketRegionPtr>::New(1);
    p->extra_payload[0] = MediaPacketRegion::New();

    r1->length = buffer_size_ - alloc_start;
    MOJO_DCHECK(size > r1->length);

    r2 = &(p->extra_payload[0]);
    (*r2)->offset = 0;
    (*r2)->length = size - r1->length;
  } else {
    p->extra_payload = Array<MediaPacketRegionPtr>::New(0);
    r1->length = size;
  }

  // Fill out the bookkeeping in our internal MappedPacket structure.
  packet->data_[0] = reinterpret_cast<uint8_t*>(buffer_) + r1->offset;
  packet->length_[0] = r1->length;
  packet->cancel_wr_ = wr_;
  packet->flush_generation_ = flush_generation_;
  if (nullptr != r2) {
    packet->data_[1] = reinterpret_cast<uint8_t*>(buffer_) + (*r2)->offset;
    packet->length_[1] = (*r2)->length;
  } else {
    packet->data_[1] = nullptr;
    packet->length_[1] = 0;
  }

  // Update our circular buffer bookkeeping, and we are done.
  wr_ = alloc_end % buffer_size_;

  // now that we have moved the write pointer, we may be signalled again.
  // Need to re-evaluate.
  UpdateSignalled();

  return MediaResult::OK;
}

MediaResult CircularBufferMediaPipeAdapter::SendMediaPacket(
    MappedPacket* packet,
    const MediaPipe::SendPacketCallback& cbk) {
  MOJO_DCHECK(packet && !packet->packet_.is_null());
  if (!packet || packet->packet_.is_null()) {
    return MediaResult::INVALID_ARGUMENT;
  }

  const MediaPacketPtr& p = packet->packet_;
  MOJO_DCHECK(!p->extra_payload.is_null());
  MOJO_DCHECK(p->extra_payload.size() <= 1u);

  uint64_t post_consume_rd = p->extra_payload.size()
    ? (p->extra_payload[0]->offset + p->extra_payload[0]->length)
    : (p->payload->offset + p->payload->length);

  // If the pipe is broken, make sure that we have entered into a fatal error
  // state.
  if (!pipe_.is_bound()) {
    Fault(MediaResult::CONNECTION_LOST);
  }

  // Sometime between when the user created this packet, and when they got
  // around to sending it, we either faulted, or we flushed one or more times.
  // Reset the packet, and tell the user that their payload was flushed (it
  // effectively was), so they know to not expect their callback to ever be
  // called.
  if (Faulted() || (packet->flush_generation_ != flush_generation_)) {
    packet->Reset();
    return MediaResult::FLUSHED;
  }

  // There should be no way for us to be busy at this point in time.
  //
  // Users cannot create MappedPackets while we are in the process of getting
  // state, so there should be no way for us to be here with a valid
  // MappedPacket while we are in the process of getting state.
  //
  // Similarly, users cannot create packets while a flush is in progress, and
  // the flush generation for a packet is captured as it is created.  When a
  // flush starts, the flush generation gets bumped.  If there is a flush in
  // progress, then the packet we have now should have a different flush
  // generation from our current flush generation, we should have bailed out
  // already in check above.
  MOJO_DCHECK(!Busy());

  MOJO_DCHECK(post_consume_rd <= buffer_size_);
  if (post_consume_rd == buffer_size_)
    post_consume_rd = 0;

  uint32_t seq_num = seq_num_gen_++;
  in_flight_queue_.emplace_back(post_consume_rd, seq_num, cbk);

  pipe_->SendPacket(
      packet->packet_.Pass(),
      [this, seq_num](MediaPipe::SendResult result) {
        HandleSendPacket(seq_num, result);
      });

  packet->Reset();

  return MediaResult::OK;
}

MediaResult CircularBufferMediaPipeAdapter::CancelMediaPacket(
    MappedPacket* packet) {
  MOJO_DCHECK(packet && !packet->packet_.is_null());
  if (!packet || packet->packet_.is_null()) {
    return MediaResult::INVALID_ARGUMENT;
  }

  // See comment in SendMediaPacket about these checks.
  if (Faulted() || (packet->flush_generation_ != flush_generation_)) {
    packet->Reset();
    return MediaResult::FLUSHED;
  }
  MOJO_DCHECK(!Busy());

  wr_ = packet->cancel_wr_;
  packet->Reset();
  UpdateSignalled();

  return MediaResult::OK;
}

MediaResult CircularBufferMediaPipeAdapter::Flush() {
  if (Faulted()) { return MediaResult::INTERNAL_ERROR; }
  if (Busy())    { return MediaResult::BUSY; }

  // TODO(johngro) : if our bookkeeping indicates that we are already
  // flushed, do we skip this or do we play dumb and do the flush anyway?
  // For now, we play dumb.
  in_flight_queue_.clear();
  rd_ = wr_ = 0;
  flush_in_progress_ = true;
  flush_generation_++;

  pipe_->Flush(pipe_flush_cbk_);

  return MediaResult::OK;
}

void CircularBufferMediaPipeAdapter::HandleSendPacket(
    uint32_t seq_num,
    MediaPipe::SendResult result) {
  MediaPipe::SendPacketCallback cbk;

  do {
    // There should be at least one element in the in-flight queue, and the
    // front of the queue's sequence number should match the sequence number of
    // the payload being returned to us.
    if (!in_flight_queue_.size() ||
        (in_flight_queue_.front().seq_num_ != seq_num)) {
      Fault(MediaResult::UNKNOWN_ERROR);
      break;
    }

    uint64_t new_rd = in_flight_queue_.front().post_consume_rd_;
    cbk = in_flight_queue_.front().cbk_;
    in_flight_queue_.pop_front();

    // Only update our internal bookkeeping if we are not in the process of
    // flushing.
    if (!flush_in_progress_) {
      // Now that this buffer has been consumed, the read pointer we are moving
      // to must exist somewhere between the current read pointer, and the
      // current write pointer (inclusively).  If we fail this check, we must
      // have some pretty serious internal bookkeeping trouble.
      uint64_t new_rd_non_modulo = new_rd + ((new_rd < rd_) ? buffer_size_ : 0);
      uint64_t wr_non_modulo     = wr_    + ((wr_    < rd_) ? buffer_size_ : 0);
      if (!((new_rd_non_modulo >= rd_) &&
            (new_rd_non_modulo <= wr_non_modulo))) {
        Fault(MediaResult::UNKNOWN_ERROR);
        break;
      }

      // Everything checks out.  Advance our read pointer, re-evaluate our
      // signalled vs. non-signalled state.
      rd_ = new_rd;
      UpdateSignalled();
    }
  } while (false);

  // If we managed to find a user registered callback for this packet, go ahead
  // and execute it now.
  if (!cbk.is_null()) {
    cbk.Run(result);
  }
}

void CircularBufferMediaPipeAdapter::HandleFlush() {
  // If we are in a perma-fault state, ignore this callback.
  if (Faulted()) { return; }

  if (!flush_in_progress_) {
    // If we don't think that there should be a flush in progress at this point,
    // then something is seriously wrong.  The other end of the pipe should not
    // be sending us flush complete callbacks if there is no flush in progress.
    Fault(MediaResult::PROTOCOL_ERROR);
    return;
  }

  // We are no longer flushing.  Update our bookkeeping and re-evaluate our
  // signalled vs. non-signalled state.
  rd_ = wr_ = 0;
  in_flight_queue_.pop_front();
  flush_in_progress_ = false;
  UpdateSignalled();
}

void CircularBufferMediaPipeAdapter::HandleSignalCallback() {
  // Clear the scheduled flag (also, it better be set otherwise how did we get
  // here?)
  MOJO_DCHECK(cbk_scheduled_);
  cbk_scheduled_ = false;

  // If we have made our final fault callback, or we are no longer signalled,
  // squash this callback.
  if (fault_cbk_made_ || !signalled_) {
    return;
  }

  // Looks like we should be dispatching this callback (presuming that we still
  // have one)
  if (signal_cbk_ != nullptr) {
    // If we are about to reported our final fatal state, set the flag to ensure
    // we make no further callbacks.
    if (Faulted()) {
      fault_cbk_made_ = true;
    }

    // Perform the callback.
    signal_cbk_(internal_state_);
  }
}

void CircularBufferMediaPipeAdapter::UpdateSignalled() {
  if (Faulted()) {
    // If we are in the unrecoverable fault state, we are signalled.
    signalled_ = true;
  } else if (Busy()) {
    // If we are busy, we are not signalled.
    signalled_ = false;
  } else {
    uint64_t pending = GetPending();
    if (!signalled_ && (pending < lo_water_mark_)) {
      // If we were not signalled, and the amt of pending data has dropped below
      // the low water mark, we are now signalled.
      signalled_ = true;
    } else if (signalled_ && (pending >= hi_water_mark_)) {
      // If we were signalled, and the amt of pending data has reached the high
      // water mark, we are now no longer signalled.
      signalled_ = false;
    }
  }

  // Schedule a callback if we are signalled, we don't already have a callback
  // scheduled, and we have not made our final fault callback.
  if (signalled_ && !cbk_scheduled_ && !fault_cbk_made_) {
    RunLoop* loop = RunLoop::current();
    MOJO_DCHECK(loop);

    loop->PostDelayedTask(signalled_callback_, 0);
    cbk_scheduled_ = true;
  }
}

void CircularBufferMediaPipeAdapter::Fault(MediaResult reason) {
  if (MediaResult::OK == internal_state_) {
    MOJO_LOG(ERROR) << "circular buffer media pipe adapter entering "
                       "unrecoverable fault state (reason = "
                    << reason << ")";
    internal_state_ = reason;
    Cleanup();
  }

  UpdateSignalled();
}

void CircularBufferMediaPipeAdapter::Cleanup() {
  // Close the connection to the service.
  if (pipe_.is_bound()) {
    pipe_.reset();
  }

  // If our buffer had been mapped, un-map it.  Then release it and reset our
  // internal state.
  if (nullptr != buffer_) {
    MojoResult res;
    res = UnmapBuffer(buffer_);
    MOJO_CHECK(res == MOJO_RESULT_OK);
  }

  buffer_ = nullptr;
  buffer_handle_.reset();
  rd_ = wr_ = 0;

  in_flight_queue_.clear();
  signal_cbk_ = nullptr;
  internal_state_ = MediaResult::SHUTTING_DOWN;
}

uint64_t CircularBufferMediaPipeAdapter::GetPending() const {
  // If we are not currently in sync with the other end of our pipe (we are only
  // in sync if we have the shared buffer mapped into our address space), then
  // there is no pending data.
  if (nullptr == buffer_)
    return 0;

  return (wr_ - rd_) + ((wr_ < rd_) ? buffer_size_ : 0);
}

uint64_t CircularBufferMediaPipeAdapter::GetBufferSize() const {
  if (nullptr == buffer_)
    return 0;

  MOJO_DCHECK(buffer_size_);
  return buffer_size_ - 1;
}

}  // namespace media
}  // namespace mojo

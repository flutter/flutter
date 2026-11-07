// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/recording.h"

#include <atomic>
#include <mutex>

namespace flutter {
namespace gpu {

/// Free chunks and recordings, shared by every context. A process holds one
/// because chunks are only memory, and because a recording can outlive the
/// isolate and engine that made it.
class RecordingPool {
 public:
  static RecordingPool& Get() {
    // Leaked, since recordings can be recycled during process teardown.
    static RecordingPool* pool = new RecordingPool();
    return *pool;
  }

  RecordingChunk* AcquireChunk() {
    {
      std::scoped_lock lock(mutex_);
      if (free_chunks_) {
        RecordingChunk* chunk = free_chunks_;
        free_chunks_ = chunk->next;
        free_chunk_count_--;
        chunk->next = nullptr;
        chunk->used = 0;
        return chunk;
      }
    }
    // Not value-initialized, which would zero the whole chunk.
    return new RecordingChunk;
  }

  void ReleaseChunks(RecordingChunk* chunks) {
    RecordingChunk* excess = nullptr;
    {
      std::scoped_lock lock(mutex_);
      while (chunks) {
        RecordingChunk* next = chunks->next;
        if (free_chunk_count_ < kMaxFreeChunks) {
          chunks->next = free_chunks_;
          free_chunks_ = chunks;
          free_chunk_count_++;
        } else {
          chunks->next = excess;
          excess = chunks;
        }
        chunks = next;
      }
    }
    while (excess) {
      RecordingChunk* next = excess->next;
      delete excess;
      excess = next;
    }
  }

  PassRecording::Ptr AcquireRecording(PassRecording::Kind kind) {
    PassRecording* recording = nullptr;
    {
      std::scoped_lock lock(mutex_);
      if (!free_recordings_.empty()) {
        recording = free_recordings_.back();
        free_recordings_.pop_back();
      }
    }
    if (!recording) {
      recording = new PassRecording();
    }
    recording->id_ = next_id_.fetch_add(1, std::memory_order_relaxed);
    recording->kind_ = kind;
    return PassRecording::Ptr(recording);
  }

  void Recycle(PassRecording* recording) {
    // The objects released here can run arbitrary destructors, so this
    // happens outside of the lock.
    recording->retained_.clear();
    recording->render_target = {};
    recording->ops.Reset();
    recording->draw_count = 0;
    recording->uniform_bind_count = 0;
    recording->texture_bind_count = 0;
    recording->vertex_buffer_bind_count = 0;
    {
      std::scoped_lock lock(mutex_);
      if (free_recordings_.size() < kMaxFreeRecordings) {
        free_recordings_.push_back(recording);
        return;
      }
    }
    delete recording;
  }

 private:
  // Bounds what stays allocated after a heavy frame. A workload above this
  // pays for a chunk every few hundred draws rather than failing.
  static constexpr size_t kMaxFreeChunks =
      32 * 1024 * 1024 / RecordingChunk::kSize;
  static constexpr size_t kMaxFreeRecordings = 128;

  RecordingPool() { free_recordings_.reserve(kMaxFreeRecordings); }

  std::mutex mutex_;
  RecordingChunk* free_chunks_ = nullptr;
  size_t free_chunk_count_ = 0;
  std::vector<PassRecording*> free_recordings_;
  // Zero is the initial value of a `RetainStamp`.
  std::atomic<uint64_t> next_id_ = 1;
};

OpStream::~OpStream() {
  Reset();
}

void OpStream::AddChunk() {
  RecordingChunk* chunk = RecordingPool::Get().AcquireChunk();
  if (tail_) {
    tail_->used = cursor_ - tail_->data;
    tail_->next = chunk;
  } else {
    head_ = chunk;
  }
  tail_ = chunk;
  cursor_ = chunk->data;
  limit_ = chunk->data + sizeof(chunk->data);
  chunk_count_++;
}

void OpStream::Reset() {
  if (head_) {
    RecordingPool::Get().ReleaseChunks(head_);
  }
  head_ = nullptr;
  tail_ = nullptr;
  cursor_ = nullptr;
  limit_ = nullptr;
  chunk_count_ = 0;
}

PassRecording::Ptr PassRecording::Acquire(Kind kind) {
  return RecordingPool::Get().AcquireRecording(kind);
}

void PassRecording::Recycler::operator()(PassRecording* recording) const {
  RecordingPool::Get().Recycle(recording);
}

}  // namespace gpu
}  // namespace flutter

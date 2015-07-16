// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains the command buffer helper class.

#ifndef GPU_COMMAND_BUFFER_CLIENT_CMD_BUFFER_HELPER_H_
#define GPU_COMMAND_BUFFER_CLIENT_CMD_BUFFER_HELPER_H_

#include <string.h>
#include <time.h>

#include "base/time/time.h"
#include "gpu/command_buffer/common/cmd_buffer_common.h"
#include "gpu/command_buffer/common/command_buffer.h"
#include "gpu/command_buffer/common/constants.h"
#include "gpu/gpu_export.h"

namespace gpu {

#if !defined(OS_ANDROID)
#define CMD_HELPER_PERIODIC_FLUSH_CHECK
const int kCommandsPerFlushCheck = 100;
const int kPeriodicFlushDelayInMicroseconds =
    base::Time::kMicrosecondsPerSecond / (5 * 60);
#endif

const int kAutoFlushSmall = 16;  // 1/16 of the buffer
const int kAutoFlushBig = 2;     // 1/2 of the buffer

// Command buffer helper class. This class simplifies ring buffer management:
// it will allocate the buffer, give it to the buffer interface, and let the
// user add commands to it, while taking care of the synchronization (put and
// get). It also provides a way to ensure commands have been executed, through
// the token mechanism:
//
// helper.AddCommand(...);
// helper.AddCommand(...);
// int32 token = helper.InsertToken();
// helper.AddCommand(...);
// helper.AddCommand(...);
// [...]
//
// helper.WaitForToken(token);  // this doesn't return until the first two
//                              // commands have been executed.
class GPU_EXPORT CommandBufferHelper {
 public:
  explicit CommandBufferHelper(CommandBuffer* command_buffer);
  virtual ~CommandBufferHelper();

  // Initializes the CommandBufferHelper.
  // Parameters:
  //   ring_buffer_size: The size of the ring buffer portion of the command
  //       buffer.
  bool Initialize(int32 ring_buffer_size);

  // Sets whether the command buffer should automatically flush periodically
  // to try to increase performance. Defaults to true.
  void SetAutomaticFlushes(bool enabled);

  // True if the context is lost.
  bool IsContextLost();

  // Asynchronously flushes the commands, setting the put pointer to let the
  // buffer interface know that new commands have been added. After a flush
  // returns, the command buffer service is aware of all pending commands.
  void Flush();

  // Ensures that commands up to the put pointer will be processed in the
  // command buffer service before any future commands on other command buffers
  // sharing a channel.
  void OrderingBarrier();

  // Waits until all the commands have been executed. Returns whether it
  // was successful. The function will fail if the command buffer service has
  // disconnected.
  bool Finish();

  // Waits until a given number of available entries are available.
  // Parameters:
  //   count: number of entries needed. This value must be at most
  //     the size of the buffer minus one.
  void WaitForAvailableEntries(int32 count);

  // Inserts a new token into the command buffer. This token either has a value
  // different from previously inserted tokens, or ensures that previously
  // inserted tokens with that value have already passed through the command
  // stream.
  // Returns:
  //   the value of the new token or -1 if the command buffer reader has
  //   shutdown.
  int32 InsertToken();

  // Returns true if the token has passed.
  // Parameters:
  //   the value of the token to check whether it has passed
  bool HasTokenPassed(int32 token) const {
    if (token > token_)
      return true;  // we wrapped
    return last_token_read() >= token;
  }

  // Waits until the token of a particular value has passed through the command
  // stream (i.e. commands inserted before that token have been executed).
  // NOTE: This will call Flush if it needs to block.
  // Parameters:
  //   the value of the token to wait for.
  void WaitForToken(int32 token);

  // Called prior to each command being issued. Waits for a certain amount of
  // space to be available. Returns address of space.
  void* GetSpace(int32 entries) {
#if defined(CMD_HELPER_PERIODIC_FLUSH_CHECK)
    // Allow this command buffer to be pre-empted by another if a "reasonable"
    // amount of work has been done. On highend machines, this reduces the
    // latency of GPU commands. However, on Android, this can cause the
    // kernel to thrash between generating GPU commands and executing them.
    ++commands_issued_;
    if (flush_automatically_ &&
        (commands_issued_ % kCommandsPerFlushCheck == 0)) {
      PeriodicFlushCheck();
    }
#endif

    // Test for immediate entries.
    if (entries > immediate_entry_count_) {
      WaitForAvailableEntries(entries);
      if (entries > immediate_entry_count_)
        return NULL;
    }

    DCHECK_LE(entries, immediate_entry_count_);

    // Allocate space and advance put_.
    CommandBufferEntry* space = &entries_[put_];
    put_ += entries;
    immediate_entry_count_ -= entries;

    DCHECK_LE(put_, total_entry_count_);
    return space;
  }

  template <typename T>
  void ForceNullCheck(T* data) {
#if defined(COMPILER_MSVC) && defined(ARCH_CPU_64_BITS) && !defined(__clang__)
    // 64-bit MSVC's alias analysis was determining that the command buffer
    // entry couldn't be NULL, so it optimized out the NULL check.
    // Dereferencing the same datatype through a volatile pointer seems to
    // prevent that from happening. http://crbug.com/361936
    // TODO(jbauman): Remove once we're on VC2015, http://crbug.com/412902
    if (data)
      static_cast<volatile T*>(data)->header;
#endif
  }

  // Typed version of GetSpace. Gets enough room for the given type and returns
  // a reference to it.
  template <typename T>
  T* GetCmdSpace() {
    static_assert(T::kArgFlags == cmd::kFixed,
                  "T::kArgFlags should equal cmd::kFixed");
    int32 space_needed = ComputeNumEntries(sizeof(T));
    T* data = static_cast<T*>(GetSpace(space_needed));
    ForceNullCheck(data);
    return data;
  }

  // Typed version of GetSpace for immediate commands.
  template <typename T>
  T* GetImmediateCmdSpace(size_t data_space) {
    static_assert(T::kArgFlags == cmd::kAtLeastN,
                  "T::kArgFlags should equal cmd::kAtLeastN");
    int32 space_needed = ComputeNumEntries(sizeof(T) + data_space);
    T* data = static_cast<T*>(GetSpace(space_needed));
    ForceNullCheck(data);
    return data;
  }

  // Typed version of GetSpace for immediate commands.
  template <typename T>
  T* GetImmediateCmdSpaceTotalSize(size_t total_space) {
    static_assert(T::kArgFlags == cmd::kAtLeastN,
                  "T::kArgFlags should equal cmd::kAtLeastN");
    int32 space_needed = ComputeNumEntries(total_space);
    T* data = static_cast<T*>(GetSpace(space_needed));
    ForceNullCheck(data);
    return data;
  }

  int32 last_token_read() const {
    return command_buffer_->GetLastToken();
  }

  int32 get_offset() const {
    return command_buffer_->GetLastState().get_offset;
  }

  // Common Commands
  void Noop(uint32 skip_count) {
    cmd::Noop* cmd = GetImmediateCmdSpace<cmd::Noop>(
        (skip_count - 1) * sizeof(CommandBufferEntry));
    if (cmd) {
      cmd->Init(skip_count);
    }
  }

  void SetToken(uint32 token) {
    cmd::SetToken* cmd = GetCmdSpace<cmd::SetToken>();
    if (cmd) {
      cmd->Init(token);
    }
  }

  void SetBucketSize(uint32 bucket_id, uint32 size) {
    cmd::SetBucketSize* cmd = GetCmdSpace<cmd::SetBucketSize>();
    if (cmd) {
      cmd->Init(bucket_id, size);
    }
  }

  void SetBucketData(uint32 bucket_id,
                     uint32 offset,
                     uint32 size,
                     uint32 shared_memory_id,
                     uint32 shared_memory_offset) {
    cmd::SetBucketData* cmd = GetCmdSpace<cmd::SetBucketData>();
    if (cmd) {
      cmd->Init(bucket_id,
                offset,
                size,
                shared_memory_id,
                shared_memory_offset);
    }
  }

  void SetBucketDataImmediate(
      uint32 bucket_id, uint32 offset, const void* data, uint32 size) {
    cmd::SetBucketDataImmediate* cmd =
        GetImmediateCmdSpace<cmd::SetBucketDataImmediate>(size);
    if (cmd) {
      cmd->Init(bucket_id, offset, size);
      memcpy(ImmediateDataAddress(cmd), data, size);
    }
  }

  void GetBucketStart(uint32 bucket_id,
                      uint32 result_memory_id,
                      uint32 result_memory_offset,
                      uint32 data_memory_size,
                      uint32 data_memory_id,
                      uint32 data_memory_offset) {
    cmd::GetBucketStart* cmd = GetCmdSpace<cmd::GetBucketStart>();
    if (cmd) {
      cmd->Init(bucket_id,
                result_memory_id,
                result_memory_offset,
                data_memory_size,
                data_memory_id,
                data_memory_offset);
    }
  }

  void GetBucketData(uint32 bucket_id,
                     uint32 offset,
                     uint32 size,
                     uint32 shared_memory_id,
                     uint32 shared_memory_offset) {
    cmd::GetBucketData* cmd = GetCmdSpace<cmd::GetBucketData>();
    if (cmd) {
      cmd->Init(bucket_id,
                offset,
                size,
                shared_memory_id,
                shared_memory_offset);
    }
  }

  CommandBuffer* command_buffer() const {
    return command_buffer_;
  }

  scoped_refptr<Buffer> get_ring_buffer() const { return ring_buffer_; }

  uint32 flush_generation() const { return flush_generation_; }

  void FreeRingBuffer();

  bool HaveRingBuffer() const {
    return ring_buffer_id_ != -1;
  }

  bool usable () const {
    return usable_;
  }

  void ClearUsable() {
    usable_ = false;
    CalcImmediateEntries(0);
  }

 private:
  // Returns the number of available entries (they may not be contiguous).
  int32 AvailableEntries() {
    return (get_offset() - put_ - 1 + total_entry_count_) % total_entry_count_;
  }

  void CalcImmediateEntries(int waiting_count);
  bool AllocateRingBuffer();
  void FreeResources();

  // Waits for the get offset to be in a specific range, inclusive. Returns
  // false if there was an error.
  bool WaitForGetOffsetInRange(int32 start, int32 end);

#if defined(CMD_HELPER_PERIODIC_FLUSH_CHECK)
  // Calls Flush if automatic flush conditions are met.
  void PeriodicFlushCheck();
#endif

  CommandBuffer* command_buffer_;
  int32 ring_buffer_id_;
  int32 ring_buffer_size_;
  scoped_refptr<gpu::Buffer> ring_buffer_;
  CommandBufferEntry* entries_;
  int32 total_entry_count_;  // the total number of entries
  int32 immediate_entry_count_;
  int32 token_;
  int32 put_;
  int32 last_put_sent_;
  int32 last_barrier_put_sent_;

#if defined(CMD_HELPER_PERIODIC_FLUSH_CHECK)
  int commands_issued_;
#endif

  bool usable_;
  bool context_lost_;
  bool flush_automatically_;

  base::TimeTicks last_flush_time_;

  // Incremented every time the helper flushes the command buffer.
  // Can be used to track when prior commands have been flushed.
  uint32 flush_generation_;

  friend class CommandBufferHelperTest;
  DISALLOW_COPY_AND_ASSIGN(CommandBufferHelper);
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_CLIENT_CMD_BUFFER_HELPER_H_

// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_GPU_SCHEDULER_H_
#define GPU_COMMAND_BUFFER_SERVICE_GPU_SCHEDULER_H_

#include <queue>

#include "base/atomic_ref_count.h"
#include "base/atomicops.h"
#include "base/callback.h"
#include "base/memory/linked_ptr.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/shared_memory.h"
#include "base/memory/weak_ptr.h"
#include "gpu/command_buffer/service/cmd_buffer_engine.h"
#include "gpu/command_buffer/service/cmd_parser.h"
#include "gpu/command_buffer/service/command_buffer_service.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder.h"
#include "gpu/gpu_export.h"

namespace gfx {
class GLFence;
}

namespace gpu {

class PreemptionFlag
    : public base::RefCountedThreadSafe<PreemptionFlag> {
 public:
  PreemptionFlag() : flag_(0) {}

  bool IsSet() { return !base::AtomicRefCountIsZero(&flag_); }
  void Set() { base::AtomicRefCountInc(&flag_); }
  void Reset() { base::subtle::NoBarrier_Store(&flag_, 0); }

 private:
  base::AtomicRefCount flag_;

  ~PreemptionFlag() {}

  friend class base::RefCountedThreadSafe<PreemptionFlag>;
};

// This class schedules commands that have been flushed. They are received via
// a command buffer and forwarded to a command parser. TODO(apatrick): This
// class should not know about the decoder. Do not add additional dependencies
// on it.
class GPU_EXPORT GpuScheduler
    : NON_EXPORTED_BASE(public CommandBufferEngine),
      public base::SupportsWeakPtr<GpuScheduler> {
 public:
  GpuScheduler(CommandBufferServiceBase* command_buffer,
               AsyncAPIInterface* handler,
               gles2::GLES2Decoder* decoder);

  ~GpuScheduler() override;

  void PutChanged();

  void SetPreemptByFlag(scoped_refptr<PreemptionFlag> flag) {
    preemption_flag_ = flag;
  }

  // Sets whether commands should be processed by this scheduler. Setting to
  // false unschedules. Setting to true reschedules. Whether or not the
  // scheduler is currently scheduled is "reference counted". Every call with
  // false must eventually be paired by a call with true.
  void SetScheduled(bool is_scheduled);

  // Returns whether the scheduler is currently able to process more commands.
  bool IsScheduled();

  // Returns whether the scheduler needs to be polled again in the future.
  bool HasMoreWork();

  typedef base::Callback<void(bool /* scheduled */)> SchedulingChangedCallback;

  // Sets a callback that is invoked just before scheduler is rescheduled
  // or descheduled. Takes ownership of callback object.
  void SetSchedulingChangedCallback(const SchedulingChangedCallback& callback);

  // Implementation of CommandBufferEngine.
  scoped_refptr<Buffer> GetSharedMemoryBuffer(int32 shm_id) override;
  void set_token(int32 token) override;
  bool SetGetBuffer(int32 transfer_buffer_id) override;
  bool SetGetOffset(int32 offset) override;
  int32 GetGetOffset() override;

  void SetCommandProcessedCallback(const base::Closure& callback);

  bool HasMoreIdleWork();
  void PerformIdleWork();

  CommandParser* parser() const {
    return parser_.get();
  }

  bool IsPreempted();

 private:
  // Artificially reschedule if the scheduler is still unscheduled after a
  // timeout.
  void RescheduleTimeOut();

  // The GpuScheduler holds a weak reference to the CommandBuffer. The
  // CommandBuffer owns the GpuScheduler and holds a strong reference to it
  // through the ProcessCommands callback.
  CommandBufferServiceBase* command_buffer_;

  // The parser uses this to execute commands.
  AsyncAPIInterface* handler_;

  // Does not own decoder. TODO(apatrick): The GpuScheduler shouldn't need a
  // pointer to the decoder, it is only used to initialize the CommandParser,
  // which could be an argument to the constructor, and to determine the
  // reason for context lost.
  gles2::GLES2Decoder* decoder_;

  // TODO(apatrick): The GpuScheduler currently creates and owns the parser.
  // This should be an argument to the constructor.
  scoped_ptr<CommandParser> parser_;

  // Greater than zero if this is waiting to be rescheduled before continuing.
  int unscheduled_count_;

  // The number of times this scheduler has been artificially rescheduled on
  // account of a timeout.
  int rescheduled_count_;

  SchedulingChangedCallback scheduling_changed_callback_;
  base::Closure descheduled_callback_;
  base::Closure command_processed_callback_;

  // If non-NULL and |preemption_flag_->IsSet()|, exit PutChanged early.
  scoped_refptr<PreemptionFlag> preemption_flag_;
  bool was_preempted_;

  // A factory for outstanding rescheduling tasks that is invalidated whenever
  // the scheduler is rescheduled.
  base::WeakPtrFactory<GpuScheduler> reschedule_task_factory_;

  DISALLOW_COPY_AND_ASSIGN(GpuScheduler);
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_GPU_SCHEDULER_H_

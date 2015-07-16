// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/gpu_scheduler.h"

#include "base/bind.h"
#include "base/command_line.h"
#include "base/compiler_specific.h"
#include "base/message_loop/message_loop.h"
#include "base/time/time.h"
#include "base/trace_event/trace_event.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_fence.h"
#include "ui/gl/gl_switches.h"

#if defined(OS_WIN)
#include "base/win/windows_version.h"
#endif

using ::base::SharedMemory;

namespace gpu {

#if defined(OS_WIN)
const int64 kRescheduleTimeOutDelay = 1000;
#endif

GpuScheduler::GpuScheduler(CommandBufferServiceBase* command_buffer,
                           AsyncAPIInterface* handler,
                           gles2::GLES2Decoder* decoder)
    : command_buffer_(command_buffer),
      handler_(handler),
      decoder_(decoder),
      unscheduled_count_(0),
      rescheduled_count_(0),
      was_preempted_(false),
      reschedule_task_factory_(this) {}

GpuScheduler::~GpuScheduler() {
}

void GpuScheduler::PutChanged() {
  TRACE_EVENT1(
     "gpu", "GpuScheduler:PutChanged",
     "decoder", decoder_ ? decoder_->GetLogger()->GetLogPrefix() : "None");

  CommandBuffer::State state = command_buffer_->GetLastState();

  // If there is no parser, exit.
  if (!parser_.get()) {
    DCHECK_EQ(state.get_offset, command_buffer_->GetPutOffset());
    return;
  }

  parser_->set_put(command_buffer_->GetPutOffset());
  if (state.error != error::kNoError)
    return;

  // One of the unschedule fence tasks might have unscheduled us.
  if (!IsScheduled())
    return;

  base::TimeTicks begin_time(base::TimeTicks::Now());
  error::Error error = error::kNoError;
  if (decoder_)
    decoder_->BeginDecoding();
  while (!parser_->IsEmpty()) {
    if (IsPreempted())
      break;

    DCHECK(IsScheduled());

    error = parser_->ProcessCommands(CommandParser::kParseCommandsSlice);

    if (error == error::kDeferCommandUntilLater) {
      DCHECK_GT(unscheduled_count_, 0);
      break;
    }

    // TODO(piman): various classes duplicate various pieces of state, leading
    // to needlessly complex update logic. It should be possible to simply
    // share the state across all of them.
    command_buffer_->SetGetOffset(static_cast<int32>(parser_->get()));

    if (error::IsError(error)) {
      command_buffer_->SetContextLostReason(decoder_->GetContextLostReason());
      command_buffer_->SetParseError(error);
      break;
    }

    if (!command_processed_callback_.is_null())
      command_processed_callback_.Run();

    if (unscheduled_count_ > 0)
      break;
  }

  if (decoder_) {
    if (!error::IsError(error) && decoder_->WasContextLost()) {
      command_buffer_->SetContextLostReason(decoder_->GetContextLostReason());
      command_buffer_->SetParseError(error::kLostContext);
    }
    decoder_->EndDecoding();
    decoder_->AddProcessingCommandsTime(base::TimeTicks::Now() - begin_time);
  }
}

void GpuScheduler::SetScheduled(bool scheduled) {
  TRACE_EVENT2("gpu", "GpuScheduler:SetScheduled", "this", this,
               "new unscheduled_count_",
               unscheduled_count_ + (scheduled? -1 : 1));
  if (scheduled) {
    // If the scheduler was rescheduled after a timeout, ignore the subsequent
    // calls to SetScheduled when they eventually arrive until they are all
    // accounted for.
    if (rescheduled_count_ > 0) {
      --rescheduled_count_;
      return;
    } else {
      --unscheduled_count_;
    }

    DCHECK_GE(unscheduled_count_, 0);

    if (unscheduled_count_ == 0) {
      TRACE_EVENT_ASYNC_END1("gpu", "ProcessingSwap", this,
                             "GpuScheduler", this);
      // When the scheduler transitions from the unscheduled to the scheduled
      // state, cancel the task that would reschedule it after a timeout.
      reschedule_task_factory_.InvalidateWeakPtrs();

      if (!scheduling_changed_callback_.is_null())
        scheduling_changed_callback_.Run(true);
    }
  } else {
    ++unscheduled_count_;
    if (unscheduled_count_ == 1) {
      TRACE_EVENT_ASYNC_BEGIN1("gpu", "ProcessingSwap", this,
                               "GpuScheduler", this);
#if defined(OS_WIN)
      if (base::win::GetVersion() < base::win::VERSION_VISTA) {
        // When the scheduler transitions from scheduled to unscheduled, post a
        // delayed task that it will force it back into a scheduled state after
        // a timeout. This should only be necessary on pre-Vista.
        base::MessageLoop::current()->PostDelayedTask(
            FROM_HERE,
            base::Bind(&GpuScheduler::RescheduleTimeOut,
                       reschedule_task_factory_.GetWeakPtr()),
            base::TimeDelta::FromMilliseconds(kRescheduleTimeOutDelay));
      }
#endif
      if (!scheduling_changed_callback_.is_null())
        scheduling_changed_callback_.Run(false);
    }
  }
}

bool GpuScheduler::IsScheduled() {
  return unscheduled_count_ == 0;
}

bool GpuScheduler::HasMoreWork() {
  return (decoder_ && decoder_->ProcessPendingQueries(false)) ||
         HasMoreIdleWork();
}

void GpuScheduler::SetSchedulingChangedCallback(
    const SchedulingChangedCallback& callback) {
  scheduling_changed_callback_ = callback;
}

scoped_refptr<Buffer> GpuScheduler::GetSharedMemoryBuffer(int32 shm_id) {
  return command_buffer_->GetTransferBuffer(shm_id);
}

void GpuScheduler::set_token(int32 token) {
  command_buffer_->SetToken(token);
}

bool GpuScheduler::SetGetBuffer(int32 transfer_buffer_id) {
  scoped_refptr<Buffer> ring_buffer =
      command_buffer_->GetTransferBuffer(transfer_buffer_id);
  if (!ring_buffer.get()) {
    return false;
  }

  if (!parser_.get()) {
    parser_.reset(new CommandParser(handler_));
  }

  parser_->SetBuffer(
      ring_buffer->memory(), ring_buffer->size(), 0, ring_buffer->size());

  SetGetOffset(0);
  return true;
}

bool GpuScheduler::SetGetOffset(int32 offset) {
  if (parser_->set_get(offset)) {
    command_buffer_->SetGetOffset(static_cast<int32>(parser_->get()));
    return true;
  }
  return false;
}

int32 GpuScheduler::GetGetOffset() {
  return parser_->get();
}

void GpuScheduler::SetCommandProcessedCallback(
    const base::Closure& callback) {
  command_processed_callback_ = callback;
}

bool GpuScheduler::IsPreempted() {
  if (!preemption_flag_.get())
    return false;

  if (!was_preempted_ && preemption_flag_->IsSet()) {
    TRACE_COUNTER_ID1("gpu", "GpuScheduler::Preempted", this, 1);
    was_preempted_ = true;
  } else if (was_preempted_ && !preemption_flag_->IsSet()) {
    TRACE_COUNTER_ID1("gpu", "GpuScheduler::Preempted", this, 0);
    was_preempted_ = false;
  }

  return preemption_flag_->IsSet();
}

bool GpuScheduler::HasMoreIdleWork() {
  return (decoder_ && decoder_->HasMoreIdleWork());
}

void GpuScheduler::PerformIdleWork() {
  if (!decoder_)
    return;
  decoder_->PerformIdleWork();
}

void GpuScheduler::RescheduleTimeOut() {
  int new_count = unscheduled_count_ + rescheduled_count_;

  rescheduled_count_ = 0;

  while (unscheduled_count_)
    SetScheduled(true);

  rescheduled_count_ = new_count;
}

}  // namespace gpu

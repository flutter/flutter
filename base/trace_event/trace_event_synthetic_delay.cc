// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/memory/singleton.h"
#include "base/third_party/dynamic_annotations/dynamic_annotations.h"
#include "base/trace_event/trace_event_synthetic_delay.h"

namespace {
const int kMaxSyntheticDelays = 32;
}  // namespace

namespace base {
namespace trace_event {

TraceEventSyntheticDelayClock::TraceEventSyntheticDelayClock() {}
TraceEventSyntheticDelayClock::~TraceEventSyntheticDelayClock() {}

class TraceEventSyntheticDelayRegistry : public TraceEventSyntheticDelayClock {
 public:
  static TraceEventSyntheticDelayRegistry* GetInstance();

  TraceEventSyntheticDelay* GetOrCreateDelay(const char* name);
  void ResetAllDelays();

  // TraceEventSyntheticDelayClock implementation.
  base::TimeTicks Now() override;

 private:
  TraceEventSyntheticDelayRegistry();

  friend struct DefaultSingletonTraits<TraceEventSyntheticDelayRegistry>;

  Lock lock_;
  TraceEventSyntheticDelay delays_[kMaxSyntheticDelays];
  TraceEventSyntheticDelay dummy_delay_;
  base::subtle::Atomic32 delay_count_;

  DISALLOW_COPY_AND_ASSIGN(TraceEventSyntheticDelayRegistry);
};

TraceEventSyntheticDelay::TraceEventSyntheticDelay()
    : mode_(STATIC), begin_count_(0), trigger_count_(0), clock_(NULL) {}

TraceEventSyntheticDelay::~TraceEventSyntheticDelay() {}

TraceEventSyntheticDelay* TraceEventSyntheticDelay::Lookup(
    const std::string& name) {
  return TraceEventSyntheticDelayRegistry::GetInstance()->GetOrCreateDelay(
      name.c_str());
}

void TraceEventSyntheticDelay::Initialize(
    const std::string& name,
    TraceEventSyntheticDelayClock* clock) {
  name_ = name;
  clock_ = clock;
}

void TraceEventSyntheticDelay::SetTargetDuration(
    base::TimeDelta target_duration) {
  AutoLock lock(lock_);
  target_duration_ = target_duration;
  trigger_count_ = 0;
  begin_count_ = 0;
}

void TraceEventSyntheticDelay::SetMode(Mode mode) {
  AutoLock lock(lock_);
  mode_ = mode;
}

void TraceEventSyntheticDelay::SetClock(TraceEventSyntheticDelayClock* clock) {
  AutoLock lock(lock_);
  clock_ = clock;
}

void TraceEventSyntheticDelay::Begin() {
  // Note that we check for a non-zero target duration without locking to keep
  // things quick for the common case when delays are disabled. Since the delay
  // calculation is done with a lock held, it will always be correct. The only
  // downside of this is that we may fail to apply some delays when the target
  // duration changes.
  ANNOTATE_BENIGN_RACE(&target_duration_, "Synthetic delay duration");
  if (!target_duration_.ToInternalValue())
    return;

  base::TimeTicks start_time = clock_->Now();
  {
    AutoLock lock(lock_);
    if (++begin_count_ != 1)
      return;
    end_time_ = CalculateEndTimeLocked(start_time);
  }
}

void TraceEventSyntheticDelay::BeginParallel(base::TimeTicks* out_end_time) {
  // See note in Begin().
  ANNOTATE_BENIGN_RACE(&target_duration_, "Synthetic delay duration");
  if (!target_duration_.ToInternalValue()) {
    *out_end_time = base::TimeTicks();
    return;
  }

  base::TimeTicks start_time = clock_->Now();
  {
    AutoLock lock(lock_);
    *out_end_time = CalculateEndTimeLocked(start_time);
  }
}

void TraceEventSyntheticDelay::End() {
  // See note in Begin().
  ANNOTATE_BENIGN_RACE(&target_duration_, "Synthetic delay duration");
  if (!target_duration_.ToInternalValue())
    return;

  base::TimeTicks end_time;
  {
    AutoLock lock(lock_);
    if (!begin_count_ || --begin_count_ != 0)
      return;
    end_time = end_time_;
  }
  if (!end_time.is_null())
    ApplyDelay(end_time);
}

void TraceEventSyntheticDelay::EndParallel(base::TimeTicks end_time) {
  if (!end_time.is_null())
    ApplyDelay(end_time);
}

base::TimeTicks TraceEventSyntheticDelay::CalculateEndTimeLocked(
    base::TimeTicks start_time) {
  if (mode_ == ONE_SHOT && trigger_count_++)
    return base::TimeTicks();
  else if (mode_ == ALTERNATING && trigger_count_++ % 2)
    return base::TimeTicks();
  return start_time + target_duration_;
}

void TraceEventSyntheticDelay::ApplyDelay(base::TimeTicks end_time) {
  TRACE_EVENT0("synthetic_delay", name_.c_str());
  while (clock_->Now() < end_time) {
    // Busy loop.
  }
}

TraceEventSyntheticDelayRegistry*
TraceEventSyntheticDelayRegistry::GetInstance() {
  return Singleton<
      TraceEventSyntheticDelayRegistry,
      LeakySingletonTraits<TraceEventSyntheticDelayRegistry> >::get();
}

TraceEventSyntheticDelayRegistry::TraceEventSyntheticDelayRegistry()
    : delay_count_(0) {}

TraceEventSyntheticDelay* TraceEventSyntheticDelayRegistry::GetOrCreateDelay(
    const char* name) {
  // Try to find an existing delay first without locking to make the common case
  // fast.
  int delay_count = base::subtle::Acquire_Load(&delay_count_);
  for (int i = 0; i < delay_count; ++i) {
    if (!strcmp(name, delays_[i].name_.c_str()))
      return &delays_[i];
  }

  AutoLock lock(lock_);
  delay_count = base::subtle::Acquire_Load(&delay_count_);
  for (int i = 0; i < delay_count; ++i) {
    if (!strcmp(name, delays_[i].name_.c_str()))
      return &delays_[i];
  }

  DCHECK(delay_count < kMaxSyntheticDelays)
      << "must increase kMaxSyntheticDelays";
  if (delay_count >= kMaxSyntheticDelays)
    return &dummy_delay_;

  delays_[delay_count].Initialize(std::string(name), this);
  base::subtle::Release_Store(&delay_count_, delay_count + 1);
  return &delays_[delay_count];
}

base::TimeTicks TraceEventSyntheticDelayRegistry::Now() {
  return base::TimeTicks::Now();
}

void TraceEventSyntheticDelayRegistry::ResetAllDelays() {
  AutoLock lock(lock_);
  int delay_count = base::subtle::Acquire_Load(&delay_count_);
  for (int i = 0; i < delay_count; ++i) {
    delays_[i].SetTargetDuration(base::TimeDelta());
    delays_[i].SetClock(this);
  }
}

void ResetTraceEventSyntheticDelays() {
  TraceEventSyntheticDelayRegistry::GetInstance()->ResetAllDelays();
}

}  // namespace trace_event
}  // namespace base

namespace trace_event_internal {

ScopedSyntheticDelay::ScopedSyntheticDelay(const char* name,
                                           base::subtle::AtomicWord* impl_ptr)
    : delay_impl_(GetOrCreateDelay(name, impl_ptr)) {
  delay_impl_->BeginParallel(&end_time_);
}

ScopedSyntheticDelay::~ScopedSyntheticDelay() {
  delay_impl_->EndParallel(end_time_);
}

base::trace_event::TraceEventSyntheticDelay* GetOrCreateDelay(
    const char* name,
    base::subtle::AtomicWord* impl_ptr) {
  base::trace_event::TraceEventSyntheticDelay* delay_impl =
      reinterpret_cast<base::trace_event::TraceEventSyntheticDelay*>(
          base::subtle::Acquire_Load(impl_ptr));
  if (!delay_impl) {
    delay_impl =
        base::trace_event::TraceEventSyntheticDelayRegistry::GetInstance()
            ->GetOrCreateDelay(name);
    base::subtle::Release_Store(
        impl_ptr, reinterpret_cast<base::subtle::AtomicWord>(delay_impl));
  }
  return delay_impl;
}

}  // namespace trace_event_internal

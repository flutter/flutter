// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The synthetic delay framework makes it possible to dynamically inject
// arbitrary delays into into different parts of the codebase. This can be used,
// for instance, for testing various task scheduling algorithms.
//
// The delays are specified in terms of a target duration for a given block of
// code. If the code executes faster than the duration, the thread is made to
// sleep until the deadline is met.
//
// Code can be instrumented for delays with two sets of macros. First, for
// delays that should apply within a scope, use the following macro:
//
//   TRACE_EVENT_SYNTHETIC_DELAY("cc.LayerTreeHost.DrawAndSwap");
//
// For delaying operations that span multiple scopes, use:
//
//   TRACE_EVENT_SYNTHETIC_DELAY_BEGIN("cc.Scheduler.BeginMainFrame");
//   ...
//   TRACE_EVENT_SYNTHETIC_DELAY_END("cc.Scheduler.BeginMainFrame");
//
// Here BEGIN establishes the start time for the delay and END executes the
// delay based on the remaining time. If BEGIN is called multiple times in a
// row, END should be called a corresponding number of times. Only the last
// call to END will have an effect.
//
// Note that a single delay may begin on one thread and end on another. This
// implies that a single delay cannot not be applied in several threads at once.

#ifndef BASE_TRACE_EVENT_TRACE_EVENT_SYNTHETIC_DELAY_H_
#define BASE_TRACE_EVENT_TRACE_EVENT_SYNTHETIC_DELAY_H_

#include "base/atomicops.h"
#include "base/synchronization/lock.h"
#include "base/time/time.h"
#include "base/trace_event/trace_event.h"

// Apply a named delay in the current scope.
#define TRACE_EVENT_SYNTHETIC_DELAY(name)                                     \
  static base::subtle::AtomicWord INTERNAL_TRACE_EVENT_UID(impl_ptr) = 0;     \
  trace_event_internal::ScopedSyntheticDelay INTERNAL_TRACE_EVENT_UID(delay)( \
      name, &INTERNAL_TRACE_EVENT_UID(impl_ptr));

// Begin a named delay, establishing its timing start point. May be called
// multiple times as long as the calls to TRACE_EVENT_SYNTHETIC_DELAY_END are
// balanced. Only the first call records the timing start point.
#define TRACE_EVENT_SYNTHETIC_DELAY_BEGIN(name)                          \
  do {                                                                   \
    static base::subtle::AtomicWord impl_ptr = 0;                        \
    trace_event_internal::GetOrCreateDelay(name, &impl_ptr)->Begin();    \
  } while (false)

// End a named delay. The delay is applied only if this call matches the
// first corresponding call to TRACE_EVENT_SYNTHETIC_DELAY_BEGIN with the
// same delay.
#define TRACE_EVENT_SYNTHETIC_DELAY_END(name)                         \
  do {                                                                \
    static base::subtle::AtomicWord impl_ptr = 0;                     \
    trace_event_internal::GetOrCreateDelay(name, &impl_ptr)->End();   \
  } while (false)

template <typename Type>
struct DefaultSingletonTraits;

namespace base {
namespace trace_event {

// Time source for computing delay durations. Used for testing.
class TRACE_EVENT_API_CLASS_EXPORT TraceEventSyntheticDelayClock {
 public:
  TraceEventSyntheticDelayClock();
  virtual ~TraceEventSyntheticDelayClock();
  virtual base::TimeTicks Now() = 0;

 private:
  DISALLOW_COPY_AND_ASSIGN(TraceEventSyntheticDelayClock);
};

// Single delay point instance.
class TRACE_EVENT_API_CLASS_EXPORT TraceEventSyntheticDelay {
 public:
  enum Mode {
    STATIC,      // Apply the configured delay every time.
    ONE_SHOT,    // Apply the configured delay just once.
    ALTERNATING  // Apply the configured delay every other time.
  };

  // Returns an existing named delay instance or creates a new one with |name|.
  static TraceEventSyntheticDelay* Lookup(const std::string& name);

  void SetTargetDuration(TimeDelta target_duration);
  void SetMode(Mode mode);
  void SetClock(TraceEventSyntheticDelayClock* clock);

  // Begin the delay, establishing its timing start point. May be called
  // multiple times as long as the calls to End() are balanced. Only the first
  // call records the timing start point.
  void Begin();

  // End the delay. The delay is applied only if this call matches the first
  // corresponding call to Begin() with the same delay.
  void End();

  // Begin a parallel instance of the delay. Several parallel instances may be
  // active simultaneously and will complete independently. The computed end
  // time for the delay is stored in |out_end_time|, which should later be
  // passed to EndParallel().
  void BeginParallel(base::TimeTicks* out_end_time);

  // End a previously started parallel delay. |end_time| is the delay end point
  // computed by BeginParallel().
  void EndParallel(base::TimeTicks end_time);

 private:
  TraceEventSyntheticDelay();
  ~TraceEventSyntheticDelay();
  friend class TraceEventSyntheticDelayRegistry;

  void Initialize(const std::string& name,
                  TraceEventSyntheticDelayClock* clock);
  base::TimeTicks CalculateEndTimeLocked(base::TimeTicks start_time);
  void ApplyDelay(base::TimeTicks end_time);

  Lock lock_;
  Mode mode_;
  std::string name_;
  int begin_count_;
  int trigger_count_;
  base::TimeTicks end_time_;
  base::TimeDelta target_duration_;
  TraceEventSyntheticDelayClock* clock_;

  DISALLOW_COPY_AND_ASSIGN(TraceEventSyntheticDelay);
};

// Set the target durations of all registered synthetic delay points to zero.
TRACE_EVENT_API_CLASS_EXPORT void ResetTraceEventSyntheticDelays();

}  // namespace trace_event
}  // namespace base

namespace trace_event_internal {

// Helper class for scoped delays. Do not use directly.
class TRACE_EVENT_API_CLASS_EXPORT ScopedSyntheticDelay {
 public:
  explicit ScopedSyntheticDelay(const char* name,
                                base::subtle::AtomicWord* impl_ptr);
  ~ScopedSyntheticDelay();

 private:
  base::trace_event::TraceEventSyntheticDelay* delay_impl_;
  base::TimeTicks end_time_;

  DISALLOW_COPY_AND_ASSIGN(ScopedSyntheticDelay);
};

// Helper for registering delays. Do not use directly.
TRACE_EVENT_API_CLASS_EXPORT base::trace_event::TraceEventSyntheticDelay*
    GetOrCreateDelay(const char* name, base::subtle::AtomicWord* impl_ptr);

}  // namespace trace_event_internal

#endif  // BASE_TRACE_EVENT_TRACE_EVENT_SYNTHETIC_DELAY_H_

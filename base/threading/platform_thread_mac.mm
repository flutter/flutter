// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/threading/platform_thread.h"

#import <Foundation/Foundation.h>
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <mach/thread_policy.h>
#include <sys/resource.h>

#include <algorithm>

#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/mac/mach_logging.h"
#include "base/threading/thread_id_name_manager.h"
#include "base/tracked_objects.h"

namespace base {

// If Cocoa is to be used on more than one thread, it must know that the
// application is multithreaded.  Since it's possible to enter Cocoa code
// from threads created by pthread_thread_create, Cocoa won't necessarily
// be aware that the application is multithreaded.  Spawning an NSThread is
// enough to get Cocoa to set up for multithreaded operation, so this is done
// if necessary before pthread_thread_create spawns any threads.
//
// http://developer.apple.com/documentation/Cocoa/Conceptual/Multithreading/CreatingThreads/chapter_4_section_4.html
void InitThreading() {
  static BOOL multithreaded = [NSThread isMultiThreaded];
  if (!multithreaded) {
    // +[NSObject class] is idempotent.
    [NSThread detachNewThreadSelector:@selector(class)
                             toTarget:[NSObject class]
                           withObject:nil];
    multithreaded = YES;

    DCHECK([NSThread isMultiThreaded]);
  }
}

// static
void PlatformThread::SetName(const std::string& name) {
  ThreadIdNameManager::GetInstance()->SetName(CurrentId(), name);
  tracked_objects::ThreadData::InitializeThreadContext(name);

  // Mac OS X does not expose the length limit of the name, so
  // hardcode it.
  const int kMaxNameLength = 63;
  std::string shortened_name = name.substr(0, kMaxNameLength);
  // pthread_setname() fails (harmlessly) in the sandbox, ignore when it does.
  // See http://crbug.com/47058
  pthread_setname_np(shortened_name.c_str());
}

namespace {

void SetPriorityNormal(mach_port_t mach_thread_id) {
  // Make thread standard policy.
  // Please note that this call could fail in rare cases depending
  // on runtime conditions.
  thread_standard_policy policy;
  kern_return_t result =
      thread_policy_set(mach_thread_id,
                        THREAD_STANDARD_POLICY,
                        reinterpret_cast<thread_policy_t>(&policy),
                        THREAD_STANDARD_POLICY_COUNT);

  if (result != KERN_SUCCESS)
    MACH_DVLOG(1, result) << "thread_policy_set";
}

// Enables time-contraint policy and priority suitable for low-latency,
// glitch-resistant audio.
void SetPriorityRealtimeAudio(mach_port_t mach_thread_id) {
  // Increase thread priority to real-time.

  // Please note that the thread_policy_set() calls may fail in
  // rare cases if the kernel decides the system is under heavy load
  // and is unable to handle boosting the thread priority.
  // In these cases we just return early and go on with life.

  // Make thread fixed priority.
  thread_extended_policy_data_t policy;
  policy.timeshare = 0;  // Set to 1 for a non-fixed thread.
  kern_return_t result =
      thread_policy_set(mach_thread_id,
                        THREAD_EXTENDED_POLICY,
                        reinterpret_cast<thread_policy_t>(&policy),
                        THREAD_EXTENDED_POLICY_COUNT);
  if (result != KERN_SUCCESS) {
    MACH_DVLOG(1, result) << "thread_policy_set";
    return;
  }

  // Set to relatively high priority.
  thread_precedence_policy_data_t precedence;
  precedence.importance = 63;
  result = thread_policy_set(mach_thread_id,
                             THREAD_PRECEDENCE_POLICY,
                             reinterpret_cast<thread_policy_t>(&precedence),
                             THREAD_PRECEDENCE_POLICY_COUNT);
  if (result != KERN_SUCCESS) {
    MACH_DVLOG(1, result) << "thread_policy_set";
    return;
  }

  // Most important, set real-time constraints.

  // Define the guaranteed and max fraction of time for the audio thread.
  // These "duty cycle" values can range from 0 to 1.  A value of 0.5
  // means the scheduler would give half the time to the thread.
  // These values have empirically been found to yield good behavior.
  // Good means that audio performance is high and other threads won't starve.
  const double kGuaranteedAudioDutyCycle = 0.75;
  const double kMaxAudioDutyCycle = 0.85;

  // Define constants determining how much time the audio thread can
  // use in a given time quantum.  All times are in milliseconds.

  // About 128 frames @44.1KHz
  const double kTimeQuantum = 2.9;

  // Time guaranteed each quantum.
  const double kAudioTimeNeeded = kGuaranteedAudioDutyCycle * kTimeQuantum;

  // Maximum time each quantum.
  const double kMaxTimeAllowed = kMaxAudioDutyCycle * kTimeQuantum;

  // Get the conversion factor from milliseconds to absolute time
  // which is what the time-constraints call needs.
  mach_timebase_info_data_t tb_info;
  mach_timebase_info(&tb_info);
  double ms_to_abs_time =
      (static_cast<double>(tb_info.denom) / tb_info.numer) * 1000000;

  thread_time_constraint_policy_data_t time_constraints;
  time_constraints.period = kTimeQuantum * ms_to_abs_time;
  time_constraints.computation = kAudioTimeNeeded * ms_to_abs_time;
  time_constraints.constraint = kMaxTimeAllowed * ms_to_abs_time;
  time_constraints.preemptible = 0;

  result =
      thread_policy_set(mach_thread_id,
                        THREAD_TIME_CONSTRAINT_POLICY,
                        reinterpret_cast<thread_policy_t>(&time_constraints),
                        THREAD_TIME_CONSTRAINT_POLICY_COUNT);
  MACH_DVLOG_IF(1, result != KERN_SUCCESS, result) << "thread_policy_set";

  return;
}

}  // anonymous namespace

// static
void PlatformThread::SetCurrentThreadPriority(ThreadPriority priority) {
  // Convert from pthread_t to mach thread identifier.
  mach_port_t mach_thread_id =
      pthread_mach_thread_np(PlatformThread::CurrentHandle().platform_handle());

  switch (priority) {
    case ThreadPriority::NORMAL:
      SetPriorityNormal(mach_thread_id);
      break;
    case ThreadPriority::REALTIME_AUDIO:
      SetPriorityRealtimeAudio(mach_thread_id);
      break;
    default:
      NOTREACHED() << "Unknown priority.";
      break;
  }
}

// static
ThreadPriority PlatformThread::GetCurrentThreadPriority() {
  NOTIMPLEMENTED();
  return ThreadPriority::NORMAL;
}

size_t GetDefaultThreadStackSize(const pthread_attr_t& attributes) {
#if defined(OS_IOS)
  return 0;
#else
  // The Mac OS X default for a pthread stack size is 512kB.
  // Libc-594.1.4/pthreads/pthread.c's pthread_attr_init uses
  // DEFAULT_STACK_SIZE for this purpose.
  //
  // 512kB isn't quite generous enough for some deeply recursive threads that
  // otherwise request the default stack size by specifying 0. Here, adopt
  // glibc's behavior as on Linux, which is to use the current stack size
  // limit (ulimit -s) as the default stack size. See
  // glibc-2.11.1/nptl/nptl-init.c's __pthread_initialize_minimal_internal. To
  // avoid setting the limit below the Mac OS X default or the minimum usable
  // stack size, these values are also considered. If any of these values
  // can't be determined, or if stack size is unlimited (ulimit -s unlimited),
  // stack_size is left at 0 to get the system default.
  //
  // Mac OS X normally only applies ulimit -s to the main thread stack. On
  // contemporary OS X and Linux systems alike, this value is generally 8MB
  // or in that neighborhood.
  size_t default_stack_size = 0;
  struct rlimit stack_rlimit;
  if (pthread_attr_getstacksize(&attributes, &default_stack_size) == 0 &&
      getrlimit(RLIMIT_STACK, &stack_rlimit) == 0 &&
      stack_rlimit.rlim_cur != RLIM_INFINITY) {
    default_stack_size =
        std::max(std::max(default_stack_size,
                          static_cast<size_t>(PTHREAD_STACK_MIN)),
                 static_cast<size_t>(stack_rlimit.rlim_cur));
  }
  return default_stack_size;
#endif
}

void InitOnThread() {
}

void TerminateOnThread() {
}

}  // namespace base

// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/threading/platform_thread.h"

#include <errno.h>
#include <sched.h>

#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/threading/thread_id_name_manager.h"
#include "base/tracked_objects.h"

#if !defined(OS_NACL)
#include <pthread.h>
#include <sys/prctl.h>
#include <sys/types.h>
#include <unistd.h>
#endif

namespace base {

namespace internal {

namespace {
#if !defined(OS_NACL)
const struct sched_param kRealTimePrio = {8};
#endif
}  // namespace

const ThreadPriorityToNiceValuePair kThreadPriorityToNiceValueMap[4] = {
    {ThreadPriority::BACKGROUND, 10},
    {ThreadPriority::NORMAL, 0},
    {ThreadPriority::DISPLAY, -6},
    {ThreadPriority::REALTIME_AUDIO, -10},
}

bool SetCurrentThreadPriorityForPlatform(ThreadPriority priority) {
#if !defined(OS_NACL)
  return priority == ThreadPriority::REALTIME_AUDIO &&
         pthread_setschedparam(pthread_self(), SCHED_RR, &kRealTimePrio) == 0;
#else
  return false;
#endif
}

bool GetCurrentThreadPriorityForPlatform(ThreadPriority* priority) {
#if !defined(OS_NACL)
  int maybe_sched_rr = 0;
  struct sched_param maybe_realtime_prio = {0};
  if (pthread_getschedparam(pthread_self(), &maybe_sched_rr,
                            &maybe_realtime_prio) == 0 &&
      maybe_sched_rr == SCHED_RR &&
      maybe_realtime_prio.sched_priority == kRealTimePrio.sched_priority) {
    *priority = ThreadPriority::REALTIME_AUDIO;
    return true;
  }
#endif
  return false;
}

}  // namespace internal

// static
void PlatformThread::SetName(const std::string& name) {
  ThreadIdNameManager::GetInstance()->SetName(CurrentId(), name);
  tracked_objects::ThreadData::InitializeThreadContext(name);

#if !defined(OS_NACL)
  // On FreeBSD we can get the thread names to show up in the debugger by
  // setting the process name for the LWP.  We don't want to do this for the
  // main thread because that would rename the process, causing tools like
  // killall to stop working.
  if (PlatformThread::CurrentId() == getpid())
    return;
  setproctitle("%s", name.c_str());
#endif  //  !defined(OS_NACL)
}

void InitThreading() {}

void InitOnThread() {}

void TerminateOnThread() {}

size_t GetDefaultThreadStackSize(const pthread_attr_t& attributes) {
#if !defined(THREAD_SANITIZER)
  return 0;
#else
  // ThreadSanitizer bloats the stack heavily. Evidence has been that the
  // default stack size isn't enough for some browser tests.
  return 2 * (1 << 23);  // 2 times 8192K (the default stack size on Linux).
#endif
}

}  // namespace base

// Copyright (c) 2005, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// ---
// Author: Sanjay Ghemawat
//         Chris Demetriou (refactoring)
//
// Profile current program by sampling stack-trace every so often

#include "config.h"
#include "getpc.h"      // should be first to get the _GNU_SOURCE dfn
#include <signal.h>
#include <assert.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>  // for getpid()
#endif
#if defined(HAVE_SYS_UCONTEXT_H)
#include <sys/ucontext.h>
#elif defined(HAVE_UCONTEXT_H)
#include <ucontext.h>
#elif defined(HAVE_CYGWIN_SIGNAL_H)
#include <cygwin/signal.h>
typedef ucontext ucontext_t;
#else
typedef int ucontext_t;   // just to quiet the compiler, mostly
#endif
#include <sys/time.h>
#include <string>
#include <gperftools/profiler.h>
#include <gperftools/stacktrace.h>
#include "base/commandlineflags.h"
#include "base/logging.h"
#include "base/googleinit.h"
#include "base/spinlock.h"
#include "base/sysinfo.h"             /* for GetUniquePathFromEnv, etc */
#include "profiledata.h"
#include "profile-handler.h"
#ifdef HAVE_CONFLICT_SIGNAL_H
#include "conflict-signal.h"          /* used on msvc machines */
#endif

using std::string;

// Collects up all profile data.  This is a singleton, which is
// initialized by a constructor at startup.
class CpuProfiler {
 public:
  CpuProfiler();
  ~CpuProfiler();

  // Start profiler to write profile info into fname
  bool Start(const char* fname, const ProfilerOptions* options);

  // Stop profiling and write the data to disk.
  void Stop();

  // Write the data to disk (and continue profiling).
  void FlushTable();

  bool Enabled();

  void GetCurrentState(ProfilerState* state);

  static CpuProfiler instance_;

 private:
  // This lock implements the locking requirements described in the ProfileData
  // documentation, specifically:
  //
  // lock_ is held all over all collector_ method calls except for the 'Add'
  // call made from the signal handler, to protect against concurrent use of
  // collector_'s control routines. Code other than signal handler must
  // unregister the signal handler before calling any collector_ method.
  // 'Add' method in the collector is protected by a guarantee from
  // ProfileHandle that only one instance of prof_handler can run at a time.
  SpinLock      lock_;
  ProfileData   collector_;

  // Filter function and its argument, if any.  (NULL means include all
  // samples).  Set at start, read-only while running.  Written while holding
  // lock_, read and executed in the context of SIGPROF interrupt.
  int           (*filter_)(void*);
  void*         filter_arg_;

  // Opaque token returned by the profile handler. To be used when calling
  // ProfileHandlerUnregisterCallback.
  ProfileHandlerToken* prof_handler_token_;

  // Sets up a callback to receive SIGPROF interrupt.
  void EnableHandler();

  // Disables receiving SIGPROF interrupt.
  void DisableHandler();

  // Signal handler that records the interrupted pc in the profile data.
  static void prof_handler(int sig, siginfo_t*, void* signal_ucontext,
                           void* cpu_profiler);
};

// Profile data structure singleton: Constructor will check to see if
// profiling should be enabled.  Destructor will write profile data
// out to disk.
CpuProfiler CpuProfiler::instance_;

// Initialize profiling: activated if getenv("CPUPROFILE") exists.
CpuProfiler::CpuProfiler()
    : prof_handler_token_(NULL) {
  // TODO(cgd) Move this code *out* of the CpuProfile constructor into a
  // separate object responsible for initialization. With ProfileHandler there
  // is no need to limit the number of profilers.
  char fname[PATH_MAX];
  if (!GetUniquePathFromEnv("CPUPROFILE", fname)) {
    return;
  }
  // We don't enable profiling if setuid -- it's a security risk
#ifdef HAVE_GETEUID
  if (getuid() != geteuid())
    return;
#endif

  if (!Start(fname, NULL)) {
    RAW_LOG(FATAL, "Can't turn on cpu profiling for '%s': %s\n",
            fname, strerror(errno));
  }
}

bool CpuProfiler::Start(const char* fname, const ProfilerOptions* options) {
  SpinLockHolder cl(&lock_);

  if (collector_.enabled()) {
    return false;
  }

  ProfileHandlerState prof_handler_state;
  ProfileHandlerGetState(&prof_handler_state);

  ProfileData::Options collector_options;
  collector_options.set_frequency(prof_handler_state.frequency);
  if (!collector_.Start(fname, collector_options)) {
    return false;
  }

  filter_ = NULL;
  if (options != NULL && options->filter_in_thread != NULL) {
    filter_ = options->filter_in_thread;
    filter_arg_ = options->filter_in_thread_arg;
  }

  // Setup handler for SIGPROF interrupts
  EnableHandler();

  return true;
}

CpuProfiler::~CpuProfiler() {
  Stop();
}

// Stop profiling and write out any collected profile data
void CpuProfiler::Stop() {
  SpinLockHolder cl(&lock_);

  if (!collector_.enabled()) {
    return;
  }

  // Unregister prof_handler to stop receiving SIGPROF interrupts before
  // stopping the collector.
  DisableHandler();

  // DisableHandler waits for the currently running callback to complete and
  // guarantees no future invocations. It is safe to stop the collector.
  collector_.Stop();
}

void CpuProfiler::FlushTable() {
  SpinLockHolder cl(&lock_);

  if (!collector_.enabled()) {
    return;
  }

  // Unregister prof_handler to stop receiving SIGPROF interrupts before
  // flushing the profile data.
  DisableHandler();

  // DisableHandler waits for the currently running callback to complete and
  // guarantees no future invocations. It is safe to flush the profile data.
  collector_.FlushTable();

  EnableHandler();
}

bool CpuProfiler::Enabled() {
  SpinLockHolder cl(&lock_);
  return collector_.enabled();
}

void CpuProfiler::GetCurrentState(ProfilerState* state) {
  ProfileData::State collector_state;
  {
    SpinLockHolder cl(&lock_);
    collector_.GetCurrentState(&collector_state);
  }

  state->enabled = collector_state.enabled;
  state->start_time = static_cast<time_t>(collector_state.start_time);
  state->samples_gathered = collector_state.samples_gathered;
  int buf_size = sizeof(state->profile_name);
  strncpy(state->profile_name, collector_state.profile_name, buf_size);
  state->profile_name[buf_size-1] = '\0';
}

void CpuProfiler::EnableHandler() {
  RAW_CHECK(prof_handler_token_ == NULL, "SIGPROF handler already registered");
  prof_handler_token_ = ProfileHandlerRegisterCallback(prof_handler, this);
  RAW_CHECK(prof_handler_token_ != NULL, "Failed to set up SIGPROF handler");
}

void CpuProfiler::DisableHandler() {
  RAW_CHECK(prof_handler_token_ != NULL, "SIGPROF handler is not registered");
  ProfileHandlerUnregisterCallback(prof_handler_token_);
  prof_handler_token_ = NULL;
}

// Signal handler that records the pc in the profile-data structure. We do no
// synchronization here.  profile-handler.cc guarantees that at most one
// instance of prof_handler() will run at a time. All other routines that
// access the data touched by prof_handler() disable this signal handler before
// accessing the data and therefore cannot execute concurrently with
// prof_handler().
void CpuProfiler::prof_handler(int sig, siginfo_t*, void* signal_ucontext,
                               void* cpu_profiler) {
  CpuProfiler* instance = static_cast<CpuProfiler*>(cpu_profiler);

  if (instance->filter_ == NULL ||
      (*instance->filter_)(instance->filter_arg_)) {
    void* stack[ProfileData::kMaxStackDepth];

    // The top-most active routine doesn't show up as a normal
    // frame, but as the "pc" value in the signal handler context.
    stack[0] = GetPC(*reinterpret_cast<ucontext_t*>(signal_ucontext));

    // We skip the top two stack trace entries (this function and one
    // signal handler frame) since they are artifacts of profiling and
    // should not be measured.  Other profiling related frames may be
    // removed by "pprof" at analysis time.  Instead of skipping the top
    // frames, we could skip nothing, but that would increase the
    // profile size unnecessarily.
    int depth = GetStackTraceWithContext(stack + 1, arraysize(stack) - 1,
                                         2, signal_ucontext);
    depth++;  // To account for pc value in stack[0];

    instance->collector_.Add(depth, stack);
  }
}

#if !(defined(__CYGWIN__) || defined(__CYGWIN32__))

extern "C" PERFTOOLS_DLL_DECL void ProfilerRegisterThread() {
  ProfileHandlerRegisterThread();
}

extern "C" PERFTOOLS_DLL_DECL void ProfilerFlush() {
  CpuProfiler::instance_.FlushTable();
}

extern "C" PERFTOOLS_DLL_DECL int ProfilingIsEnabledForAllThreads() {
  return CpuProfiler::instance_.Enabled();
}

extern "C" PERFTOOLS_DLL_DECL int ProfilerStart(const char* fname) {
  return CpuProfiler::instance_.Start(fname, NULL);
}

extern "C" PERFTOOLS_DLL_DECL int ProfilerStartWithOptions(
    const char *fname, const ProfilerOptions *options) {
  return CpuProfiler::instance_.Start(fname, options);
}

extern "C" PERFTOOLS_DLL_DECL void ProfilerStop() {
  CpuProfiler::instance_.Stop();
}

extern "C" PERFTOOLS_DLL_DECL void ProfilerGetCurrentState(
    ProfilerState* state) {
  CpuProfiler::instance_.GetCurrentState(state);
}

#else  // OS_CYGWIN

// ITIMER_PROF doesn't work under cygwin.  ITIMER_REAL is available, but doesn't
// work as well for profiling, and also interferes with alarm().  Because of
// these issues, unless a specific need is identified, profiler support is
// disabled under Cygwin.
extern "C" void ProfilerRegisterThread() { }
extern "C" void ProfilerFlush() { }
extern "C" int ProfilingIsEnabledForAllThreads() { return 0; }
extern "C" int ProfilerStart(const char* fname) { return 0; }
extern "C" int ProfilerStartWithOptions(const char *fname,
                                        const ProfilerOptions *options) {
  return 0;
}
extern "C" void ProfilerStop() { }
extern "C" void ProfilerGetCurrentState(ProfilerState* state) {
  memset(state, 0, sizeof(*state));
}

#endif  // OS_CYGWIN

// DEPRECATED routines
extern "C" PERFTOOLS_DLL_DECL void ProfilerEnable() { }
extern "C" PERFTOOLS_DLL_DECL void ProfilerDisable() { }

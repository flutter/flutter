/* Copyright (c) 2009, Google Inc.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ---
 * Author: Nabeel Mian
 *
 * This module manages the cpu profile timers and the associated interrupt
 * handler. When enabled, all registered threads in the program are profiled.
 * (Note: if using linux 2.4 or earlier, you must use the Thread class, in
 * google3/thread, to ensure all threads are profiled.)
 *
 * Any component interested in receiving a profile timer interrupt can do so by
 * registering a callback. All registered callbacks must be async-signal-safe.
 *
 * Note: This module requires the sole ownership of ITIMER_PROF timer and the
 * SIGPROF signal.
 */

#ifndef BASE_PROFILE_HANDLER_H_
#define BASE_PROFILE_HANDLER_H_

#include "config.h"
#include <signal.h>
#ifdef COMPILER_MSVC
#include "conflict-signal.h"
#endif
#include "base/basictypes.h"

/* All this code should be usable from within C apps. */
#ifdef __cplusplus
extern "C" {
#endif

/* Forward declaration. */
struct ProfileHandlerToken;

/*
 * Callback function to be used with ProfilefHandlerRegisterCallback. This
 * function will be called in the context of SIGPROF signal handler and must
 * be async-signal-safe. The first three arguments are the values provided by
 * the SIGPROF signal handler. We use void* to avoid using ucontext_t on
 * non-POSIX systems.
 *
 * Requirements:
 * - Callback must be async-signal-safe.
 * - None of the functions in ProfileHandler are async-signal-safe. Therefore,
 *   callback function *must* not call any of the ProfileHandler functions.
 * - Callback is not required to be re-entrant. At most one instance of
 *   callback can run at a time.
 *
 * Notes:
 * - The SIGPROF signal handler saves and restores errno, so the callback
 *   doesn't need to.
 * - Callback code *must* not acquire lock(s) to serialize access to data shared
 *   with the code outside the signal handler (callback must be
 *   async-signal-safe). If such a serialization is needed, follow the model
 *   used by profiler.cc:
 *
 *   When code other than the signal handler modifies the shared data it must:
 *   - Acquire lock.
 *   - Unregister the callback with the ProfileHandler.
 *   - Modify shared data.
 *   - Re-register the callback.
 *   - Release lock.
 *   and the callback code gets a lockless, read-write access to the data.
 */
typedef void (*ProfileHandlerCallback)(int sig, siginfo_t* sig_info,
                                       void* ucontext, void* callback_arg);

/*
 * Registers a new thread with profile handler and should be called only once
 * per thread. The main thread is registered at program startup. This routine
 * is called by the Thread module in google3/thread whenever a new thread is
 * created. This function is not async-signal-safe.
 */
void ProfileHandlerRegisterThread();

/*
 * Registers a callback routine. This callback function will be called in the
 * context of SIGPROF handler, so must be async-signal-safe. The returned token
 * is to be used when unregistering this callback via
 * ProfileHandlerUnregisterCallback. Registering the first callback enables
 * the SIGPROF signal handler. Caller must not free the returned token. This
 * function is not async-signal-safe.
 */
ProfileHandlerToken* ProfileHandlerRegisterCallback(
    ProfileHandlerCallback callback, void* callback_arg);

/*
 * Unregisters a previously registered callback. Expects the token returned
 * by the corresponding ProfileHandlerRegisterCallback and asserts that the
 * passed token is valid. Unregistering the last callback disables the SIGPROF
 * signal handler. It waits for the currently running callback to
 * complete before returning. This function is not async-signal-safe.
 */
void ProfileHandlerUnregisterCallback(ProfileHandlerToken* token);

/*
 * FOR TESTING ONLY
 * Unregisters all the callbacks, stops the timers (if shared) and disables the
 * SIGPROF handler. All the threads, including the main thread, need to be
 * re-registered after this call. This function is not async-signal-safe.
 */
void ProfileHandlerReset();

/*
 * Stores profile handler's current state. This function is not
 * async-signal-safe.
 */
struct ProfileHandlerState {
  int32 frequency;  /* Profiling frequency */
  int32 callback_count;  /* Number of callbacks registered */
  int64 interrupts;  /* Number of interrupts received */
  bool allowed; /* Profiling is allowed */
};
void ProfileHandlerGetState(struct ProfileHandlerState* state);

#ifdef __cplusplus
}  /* extern "C" */
#endif

#endif  /* BASE_PROFILE_HANDLER_H_ */

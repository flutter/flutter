/* Copyright (c) 2005, Google Inc.
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
 * Author: Sanjay Ghemawat
 *
 * Module for CPU profiling based on periodic pc-sampling.
 *
 * For full(er) information, see doc/cpuprofile.html
 *
 * This module is linked into your program with
 * no slowdown caused by this unless you activate the profiler
 * using one of the following methods:
 *
 *    1. Before starting the program, set the environment variable
 *       "PROFILE" to be the name of the file to which the profile
 *       data should be written.
 *
 *    2. Programmatically, start and stop the profiler using the
 *       routines "ProfilerStart(filename)" and "ProfilerStop()".
 *
 *
 * (Note: if using linux 2.4 or earlier, only the main thread may be
 * profiled.)
 *
 * Use pprof to view the resulting profile output.
 *    % pprof <path_to_executable> <profile_file_name>
 *    % pprof --gv  <path_to_executable> <profile_file_name>
 *
 * These functions are thread-safe.
 */

#ifndef BASE_PROFILER_H_
#define BASE_PROFILER_H_

#include <time.h>       /* For time_t */

/* Annoying stuff for windows; makes sure clients can import these functions */
#ifndef PERFTOOLS_DLL_DECL
# ifdef _WIN32
#   define PERFTOOLS_DLL_DECL  __declspec(dllimport)
# else
#   define PERFTOOLS_DLL_DECL
# endif
#endif

/* All this code should be usable from within C apps. */
#ifdef __cplusplus
extern "C" {
#endif

/* Profiler options, for use with ProfilerStartWithOptions.  To use:
 *
 *   struct ProfilerOptions options;
 *   memset(&options, 0, sizeof options);
 *
 * then fill in fields as needed.
 *
 * This structure is intended to be usable from C code, so no constructor
 * is provided to initialize it.  (Use memset as described above).
 */
struct ProfilerOptions {
  /* Filter function and argument.
   *
   * If filter_in_thread is not NULL, when a profiling tick is delivered
   * the profiler will call:
   *
   *   (*filter_in_thread)(filter_in_thread_arg)
   *
   * If it returns nonzero, the sample will be included in the profile.
   * Note that filter_in_thread runs in a signal handler, so must be
   * async-signal-safe.
   *
   * A typical use would be to set up filter results for each thread
   * in the system before starting the profiler, then to make
   * filter_in_thread be a very simple function which retrieves those
   * results in an async-signal-safe way.  Retrieval could be done
   * using thread-specific data, or using a shared data structure that
   * supports async-signal-safe lookups.
   */
  int (*filter_in_thread)(void *arg);
  void *filter_in_thread_arg;
};

/* Start profiling and write profile info into fname.
 *
 * This is equivalent to calling ProfilerStartWithOptions(fname, NULL).
 */
PERFTOOLS_DLL_DECL int ProfilerStart(const char* fname);

/* Start profiling and write profile into fname.
 *
 * The profiler is configured using the options given by 'options'.
 * Options which are not specified are given default values.
 *
 * 'options' may be NULL, in which case all are given default values.
 *
 * Returns nonzero if profiling was started sucessfully, or zero else.
 */
PERFTOOLS_DLL_DECL int ProfilerStartWithOptions(
    const char *fname, const struct ProfilerOptions *options);

/* Stop profiling. Can be started again with ProfilerStart(), but
 * the currently accumulated profiling data will be cleared.
 */
PERFTOOLS_DLL_DECL void ProfilerStop();

/* Flush any currently buffered profiling state to the profile file.
 * Has no effect if the profiler has not been started.
 */
PERFTOOLS_DLL_DECL void ProfilerFlush();


/* DEPRECATED: these functions were used to enable/disable profiling
 * in the current thread, but no longer do anything.
 */
PERFTOOLS_DLL_DECL void ProfilerEnable();
PERFTOOLS_DLL_DECL void ProfilerDisable();

/* Returns nonzero if profile is currently enabled, zero if it's not. */
PERFTOOLS_DLL_DECL int ProfilingIsEnabledForAllThreads();

/* Routine for registering new threads with the profiler.
 */
PERFTOOLS_DLL_DECL void ProfilerRegisterThread();

/* Stores state about profiler's current status into "*state". */
struct ProfilerState {
  int    enabled;             /* Is profiling currently enabled? */
  time_t start_time;          /* If enabled, when was profiling started? */
  char   profile_name[1024];  /* Name of profile file being written, or '\0' */
  int    samples_gathered;    /* Number of samples gathered so far (or 0) */
};
PERFTOOLS_DLL_DECL void ProfilerGetCurrentState(struct ProfilerState* state);

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  /* BASE_PROFILER_H_ */

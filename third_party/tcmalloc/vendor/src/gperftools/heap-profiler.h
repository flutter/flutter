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
 * Module for heap-profiling.
 *
 * For full(er) information, see doc/heapprofile.html
 *
 * This module can be linked into your program with
 * no slowdown caused by this unless you activate the profiler
 * using one of the following methods:
 *
 *    1. Before starting the program, set the environment variable
 *       "HEAPPROFILE" to be the name of the file to which the profile
 *       data should be written.
 *
 *    2. Programmatically, start and stop the profiler using the
 *       routines "HeapProfilerStart(filename)" and "HeapProfilerStop()".
 *
 */

#ifndef BASE_HEAP_PROFILER_H_
#define BASE_HEAP_PROFILER_H_

#include <stddef.h>

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

/* Start profiling and arrange to write profile data to file names
 * of the form: "prefix.0000", "prefix.0001", ...
 */
PERFTOOLS_DLL_DECL void HeapProfilerStart(const char* prefix);

/* Returns non-zero if we are currently profiling the heap.  (Returns
 * an int rather than a bool so it's usable from C.)  This is true
 * between calls to HeapProfilerStart() and HeapProfilerStop(), and
 * also if the program has been run with HEAPPROFILER, or some other
 * way to turn on whole-program profiling.
 */
int IsHeapProfilerRunning();

/* Stop heap profiling.  Can be restarted again with HeapProfilerStart(),
 * but the currently accumulated profiling information will be cleared.
 */
PERFTOOLS_DLL_DECL void HeapProfilerStop();

/* Dump a profile now - can be used for dumping at a hopefully
 * quiescent state in your program, in order to more easily track down
 * memory leaks. Will include the reason in the logged message
 */
PERFTOOLS_DLL_DECL void HeapProfilerDump(const char *reason);

/* Generate current heap profiling information.
 * Returns an empty string when heap profiling is not active.
 * The returned pointer is a '\0'-terminated string allocated using malloc()
 * and should be free()-ed as soon as the caller does not need it anymore.
 */
PERFTOOLS_DLL_DECL char* GetHeapProfile();

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  /* BASE_HEAP_PROFILER_H_ */

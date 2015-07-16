/* Copyright (c) 2005-2007, Google Inc.
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
 * Author: Markus Gutschke
 */

#ifndef _THREAD_LISTER_H
#define _THREAD_LISTER_H

#include <stdarg.h>
#include <sys/types.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef int (*ListAllProcessThreadsCallBack)(void *parameter,
                                             int num_threads,
                                             pid_t *thread_pids,
                                             va_list ap);

/* This function gets the list of all linux threads of the current process
 * passes them to the 'callback' along with the 'parameter' pointer; at the
 * call back call time all the threads are paused via
 * PTRACE_ATTACH.
 * The callback is executed from a separate thread which shares only the
 * address space, the filesystem, and the filehandles with the caller. Most
 * notably, it does not share the same pid and ppid; and if it terminates,
 * the rest of the application is still there. 'callback' is supposed to do
 * or arrange for ResumeAllProcessThreads. This happens automatically, if
 * the thread raises a synchronous signal (e.g. SIGSEGV); asynchronous
 * signals are blocked. If the 'callback' decides to unblock them, it must
 * ensure that they cannot terminate the application, or that
 * ResumeAllProcessThreads will get called.
 * It is an error for the 'callback' to make any library calls that could
 * acquire locks. Most notably, this means that most system calls have to
 * avoid going through libc. Also, this means that it is not legal to call
 * exit() or abort().
 * We return -1 on error and the return value of 'callback' on success.
 */
int ListAllProcessThreads(void *parameter,
                          ListAllProcessThreadsCallBack callback, ...);

/* This function resumes the list of all linux threads that
 * ListAllProcessThreads pauses before giving to its callback.
 * The function returns non-zero if at least one thread was
 * suspended and has now been resumed.
 */
int ResumeAllProcessThreads(int num_threads, pid_t *thread_pids);

#ifdef __cplusplus
}
#endif

#endif  /* _THREAD_LISTER_H */

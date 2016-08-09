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

#include "config.h"
#include <stdio.h>         /* needed for NULL on some powerpc platforms (?!) */
#ifdef HAVE_SYS_PRCTL
# include <sys/prctl.h>
#endif
#include "base/thread_lister.h"
#include "base/linuxthreads.h"
/* Include other thread listers here that define THREADS macro
 * only when they can provide a good implementation.
 */

#ifndef THREADS

/* Default trivial thread lister for single-threaded applications,
 * or if the multi-threading code has not been ported, yet.
 */

int ListAllProcessThreads(void *parameter,
                          ListAllProcessThreadsCallBack callback, ...) {
  int rc;
  va_list ap;
  pid_t pid;

#ifdef HAVE_SYS_PRCTL
  int dumpable = prctl(PR_GET_DUMPABLE, 0);
  if (!dumpable)
    prctl(PR_SET_DUMPABLE, 1);
#endif
  va_start(ap, callback);
  pid = getpid();
  rc = callback(parameter, 1, &pid, ap);
  va_end(ap);
#ifdef HAVE_SYS_PRCTL
  if (!dumpable)
    prctl(PR_SET_DUMPABLE, 0);
#endif
  return rc;
}

int ResumeAllProcessThreads(int num_threads, pid_t *thread_pids) {
  return 1;
}

#endif   /* ifndef THREADS */

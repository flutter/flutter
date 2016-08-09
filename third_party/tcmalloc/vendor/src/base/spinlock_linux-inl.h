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
 * This file is a Linux-specific part of spinlock_internal.cc
 */

#include <errno.h>
#include <sched.h>
#include <time.h>
#include <limits.h>
#include "base/linux_syscall_support.h"

#define FUTEX_WAIT 0
#define FUTEX_WAKE 1
#define FUTEX_PRIVATE_FLAG 128

static bool have_futex;
static int futex_private_flag = FUTEX_PRIVATE_FLAG;

namespace {
static struct InitModule {
  InitModule() {
    int x = 0;
    // futexes are ints, so we can use them only when
    // that's the same size as the lockword_ in SpinLock.
#ifdef __arm__
    // ARM linux doesn't support sys_futex1(void*, int, int, struct timespec*);
    have_futex = 0;
#else
    have_futex = (sizeof (Atomic32) == sizeof (int) &&
                  sys_futex(&x, FUTEX_WAKE, 1, 0) >= 0);
#endif
    if (have_futex &&
        sys_futex(&x, FUTEX_WAKE | futex_private_flag, 1, 0) < 0) {
      futex_private_flag = 0;
    }
  }
} init_module;

}  // anonymous namespace


namespace base {
namespace internal {

void SpinLockDelay(volatile Atomic32 *w, int32 value, int loop) {
  if (loop != 0) {
    int save_errno = errno;
    struct timespec tm;
    tm.tv_sec = 0;
    if (have_futex) {
      tm.tv_nsec = base::internal::SuggestedDelayNS(loop);
    } else {
      tm.tv_nsec = 2000001;   // above 2ms so linux 2.4 doesn't spin
    }
    if (have_futex) {
      tm.tv_nsec *= 16;  // increase the delay; we expect explicit wakeups
      sys_futex(reinterpret_cast<int *>(const_cast<Atomic32 *>(w)),
                FUTEX_WAIT | futex_private_flag,
                value, reinterpret_cast<struct kernel_timespec *>(&tm));
    } else {
      nanosleep(&tm, NULL);
    }
    errno = save_errno;
  }
}

void SpinLockWake(volatile Atomic32 *w, bool all) {
  if (have_futex) {
    sys_futex(reinterpret_cast<int *>(const_cast<Atomic32 *>(w)),
              FUTEX_WAKE | futex_private_flag, all? INT_MAX : 1, 0);
  }
}

} // namespace internal
} // namespace base

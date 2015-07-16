/* Copyright (c) 2006, Google Inc.
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
 */

#include <config.h>
#include "base/spinlock.h"
#include "base/synchronization_profiling.h"
#include "base/spinlock_internal.h"
#include "base/cycleclock.h"
#include "base/sysinfo.h"   /* for NumCPUs() */

// NOTE on the Lock-state values:
//
//   kSpinLockFree represents the unlocked state
//   kSpinLockHeld represents the locked state with no waiters
//
// Values greater than kSpinLockHeld represent the locked state with waiters,
// where the value is the time the current lock holder had to
// wait before obtaining the lock.  The kSpinLockSleeper state is a special
// "locked with waiters" state that indicates that a sleeper needs to
// be woken, but the thread that just released the lock didn't wait.

static int adaptive_spin_count = 0;

const base::LinkerInitialized SpinLock::LINKER_INITIALIZED =
    base::LINKER_INITIALIZED;

namespace {
struct SpinLock_InitHelper {
  SpinLock_InitHelper() {
    // On multi-cpu machines, spin for longer before yielding
    // the processor or sleeping.  Reduces idle time significantly.
    if (NumCPUs() > 1) {
      adaptive_spin_count = 1000;
    }
  }
};

// Hook into global constructor execution:
// We do not do adaptive spinning before that,
// but nothing lock-intensive should be going on at that time.
static SpinLock_InitHelper init_helper;

}  // unnamed namespace

// Monitor the lock to see if its value changes within some time period
// (adaptive_spin_count loop iterations).  A timestamp indicating
// when the thread initially started waiting for the lock is passed in via
// the initial_wait_timestamp value.  The total wait time in cycles for the
// lock is returned in the wait_cycles parameter.  The last value read
// from the lock is returned from the method.
Atomic32 SpinLock::SpinLoop(int64 initial_wait_timestamp,
                            Atomic32* wait_cycles) {
  int c = adaptive_spin_count;
  while (base::subtle::NoBarrier_Load(&lockword_) != kSpinLockFree && --c > 0) {
  }
  Atomic32 spin_loop_wait_cycles = CalculateWaitCycles(initial_wait_timestamp);
  Atomic32 lock_value =
      base::subtle::Acquire_CompareAndSwap(&lockword_, kSpinLockFree,
                                           spin_loop_wait_cycles);
  *wait_cycles = spin_loop_wait_cycles;
  return lock_value;
}

void SpinLock::SlowLock() {
  // The lock was not obtained initially, so this thread needs to wait for
  // it.  Record the current timestamp in the local variable wait_start_time
  // so the total wait time can be stored in the lockword once this thread
  // obtains the lock.
  int64 wait_start_time = CycleClock::Now();
  Atomic32 wait_cycles;
  Atomic32 lock_value = SpinLoop(wait_start_time, &wait_cycles);

  int lock_wait_call_count = 0;
  while (lock_value != kSpinLockFree) {
    // If the lock is currently held, but not marked as having a sleeper, mark
    // it as having a sleeper.
    if (lock_value == kSpinLockHeld) {
      // Here, just "mark" that the thread is going to sleep.  Don't store the
      // lock wait time in the lock as that will cause the current lock
      // owner to think it experienced contention.
      lock_value = base::subtle::Acquire_CompareAndSwap(&lockword_,
                                                        kSpinLockHeld,
                                                        kSpinLockSleeper);
      if (lock_value == kSpinLockHeld) {
        // Successfully transitioned to kSpinLockSleeper.  Pass
        // kSpinLockSleeper to the SpinLockWait routine to properly indicate
        // the last lock_value observed.
        lock_value = kSpinLockSleeper;
      } else if (lock_value == kSpinLockFree) {
        // Lock is free again, so try and aquire it before sleeping.  The
        // new lock state will be the number of cycles this thread waited if
        // this thread obtains the lock.
        lock_value = base::subtle::Acquire_CompareAndSwap(&lockword_,
                                                          kSpinLockFree,
                                                          wait_cycles);
        continue;  // skip the delay at the end of the loop
      }
    }

    // Wait for an OS specific delay.
    base::internal::SpinLockDelay(&lockword_, lock_value,
                                  ++lock_wait_call_count);
    // Spin again after returning from the wait routine to give this thread
    // some chance of obtaining the lock.
    lock_value = SpinLoop(wait_start_time, &wait_cycles);
  }
}

// The wait time for contentionz lock profiling must fit into 32 bits.
// However, the lower 32-bits of the cycle counter wrap around too quickly
// with high frequency processors, so a right-shift by 7 is performed to
// quickly divide the cycles by 128.  Using these 32 bits, reduces the
// granularity of time measurement to 128 cycles, and loses track
// of wait time for waits greater than 109 seconds on a 5 GHz machine
// [(2^32 cycles/5 Ghz)*128 = 109.95 seconds]. Waits this long should be
// very rare and the reduced granularity should not be an issue given
// processors in the Google fleet operate at a minimum of one billion
// cycles/sec.
enum { PROFILE_TIMESTAMP_SHIFT = 7 };

void SpinLock::SlowUnlock(uint64 wait_cycles) {
  base::internal::SpinLockWake(&lockword_, false);  // wake waiter if necessary

  // Collect contentionz profile info, expanding the wait_cycles back out to
  // the full value.  If wait_cycles is <= kSpinLockSleeper, then no wait
  // was actually performed, so don't record the wait time.  Note, that the
  // CalculateWaitCycles method adds in kSpinLockSleeper cycles
  // unconditionally to guarantee the wait time is not kSpinLockFree or
  // kSpinLockHeld.  The adding in of these small number of cycles may
  // overestimate the contention by a slight amount 50% of the time.  However,
  // if this code tried to correct for that addition by subtracting out the
  // kSpinLockSleeper amount that would underestimate the contention slightly
  // 50% of the time.  Both ways get the wrong answer, so the code
  // overestimates to be more conservative. Overestimating also makes the code
  // a little simpler.
  //
  if (wait_cycles > kSpinLockSleeper) {
    base::SubmitSpinLockProfileData(this,
                                    wait_cycles << PROFILE_TIMESTAMP_SHIFT);
  }
}

inline int32 SpinLock::CalculateWaitCycles(int64 wait_start_time) {
  int32 wait_cycles = ((CycleClock::Now() - wait_start_time) >>
                       PROFILE_TIMESTAMP_SHIFT);
  // The number of cycles waiting for the lock is used as both the
  // wait_cycles and lock value, so it can't be kSpinLockFree or
  // kSpinLockHeld.  Make sure the value returned is at least
  // kSpinLockSleeper.
  wait_cycles |= kSpinLockSleeper;
  return wait_cycles;
}

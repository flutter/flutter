// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// The purpose of this file is to supply the macro definintions necessary
// to make third_party/dmg_fp/dtoa.cc threadsafe.
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/synchronization/lock.h"

// We need two locks because they're sometimes grabbed at the same time.
// A single lock would lead to an attempted recursive grab.
static base::LazyInstance<base::Lock>::Leaky
    dtoa_lock_0 = LAZY_INSTANCE_INITIALIZER;
static base::LazyInstance<base::Lock>::Leaky
    dtoa_lock_1 = LAZY_INSTANCE_INITIALIZER;

/*
 * This define and the code below is to trigger thread-safe behavior
 * in dtoa.cc, per this comment from the file:
 *
 * #define MULTIPLE_THREADS if the system offers preemptively scheduled
 *	multiple threads.  In this case, you must provide (or suitably
 *	#define) two locks, acquired by ACQUIRE_DTOA_LOCK(n) and freed
 *	by FREE_DTOA_LOCK(n) for n = 0 or 1.  (The second lock, accessed
 *	in pow5mult, ensures lazy evaluation of only one copy of high
 *	powers of 5; omitting this lock would introduce a small
 *	probability of wasting memory, but would otherwise be harmless.)
 *	You must also invoke freedtoa(s) to free the value s returned by
 *	dtoa.  You may do so whether or not MULTIPLE_THREADS is #defined.
 */
#define MULTIPLE_THREADS

inline static void ACQUIRE_DTOA_LOCK(size_t n) {
  DCHECK(n < 2);
  base::Lock* lock = n == 0 ? dtoa_lock_0.Pointer() : dtoa_lock_1.Pointer();
  lock->Acquire();
}

inline static void FREE_DTOA_LOCK(size_t n) {
  DCHECK(n < 2);
  base::Lock* lock = n == 0 ? dtoa_lock_0.Pointer() : dtoa_lock_1.Pointer();
  lock->Release();
}

#include "base/third_party/dmg_fp/dtoa.cc"

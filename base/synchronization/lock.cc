// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is used for debugging assertion support.  The Lock class
// is functionally a wrapper around the LockImpl class, so the only
// real intelligence in the class is in the debugging logic.

#if !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)

#include "base/synchronization/lock.h"
#include "base/logging.h"

namespace base {

Lock::Lock() : lock_() {
}

Lock::~Lock() {
  DCHECK(owning_thread_ref_.is_null());
}

void Lock::AssertAcquired() const {
  DCHECK(owning_thread_ref_ == PlatformThread::CurrentRef());
}

void Lock::CheckHeldAndUnmark() {
  DCHECK(owning_thread_ref_ == PlatformThread::CurrentRef());
  owning_thread_ref_ = PlatformThreadRef();
}

void Lock::CheckUnheldAndMark() {
  DCHECK(owning_thread_ref_.is_null());
  owning_thread_ref_ = PlatformThread::CurrentRef();
}

}  // namespace base

#endif  // !NDEBUG || DCHECK_ALWAYS_ON

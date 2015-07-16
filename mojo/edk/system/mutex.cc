// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/mutex.h"

#if !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)

#include "base/logging.h"

namespace mojo {
namespace system {

Mutex::Mutex() : lock_() {
}

Mutex::~Mutex() {
  DCHECK(owning_thread_ref_.is_null());
}

void Mutex::AssertHeld() const {
  DCHECK(owning_thread_ref_ == base::PlatformThread::CurrentRef());
}

void Mutex::CheckHeldAndUnmark() {
  DCHECK(owning_thread_ref_ == base::PlatformThread::CurrentRef());
  owning_thread_ref_ = base::PlatformThreadRef();
}

void Mutex::CheckUnheldAndMark() {
  DCHECK(owning_thread_ref_.is_null());
  owning_thread_ref_ = base::PlatformThread::CurrentRef();
}

}  // namespace system
}  // namespace mojo

#endif  // !NDEBUG || DCHECK_ALWAYS_ON

// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/threading/thread_local.h"

#include <pthread.h>

#include "base/logging.h"

#if !defined(OS_ANDROID)

namespace base {
namespace internal {

// static
void ThreadLocalPlatform::AllocateSlot(SlotType* slot) {
  int error = pthread_key_create(slot, NULL);
  CHECK_EQ(error, 0);
}

// static
void ThreadLocalPlatform::FreeSlot(SlotType slot) {
  int error = pthread_key_delete(slot);
  DCHECK_EQ(0, error);
}

// static
void* ThreadLocalPlatform::GetValueFromSlot(SlotType slot) {
  return pthread_getspecific(slot);
}

// static
void ThreadLocalPlatform::SetValueInSlot(SlotType slot, void* value) {
  int error = pthread_setspecific(slot, value);
  DCHECK_EQ(error, 0);
}

}  // namespace internal
}  // namespace base

#endif  // !defined(OS_ANDROID)

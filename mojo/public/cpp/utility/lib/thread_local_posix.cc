// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/utility/lib/thread_local.h"

#include <assert.h>

namespace mojo {
namespace internal {

// static
void ThreadLocalPlatform::AllocateSlot(SlotType* slot) {
  if (pthread_key_create(slot, nullptr) != 0) {
    assert(false);
  }
}

// static
void ThreadLocalPlatform::FreeSlot(SlotType slot) {
  if (pthread_key_delete(slot) != 0) {
    assert(false);
  }
}

// static
void* ThreadLocalPlatform::GetValueFromSlot(SlotType slot) {
  return pthread_getspecific(slot);
}

// static
void ThreadLocalPlatform::SetValueInSlot(SlotType slot, void* value) {
  if (pthread_setspecific(slot, value) != 0) {
    assert(false);
  }
}

}  // namespace internal
}  // namespace mojo

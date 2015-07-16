// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/utility/lib/thread_local.h"

#include <assert.h>
#include <windows.h>

namespace mojo {
namespace internal {

// static
void ThreadLocalPlatform::AllocateSlot(SlotType* slot) {
  *slot = TlsAlloc();
  assert(*slot != TLS_OUT_OF_INDEXES);
}

// static
void ThreadLocalPlatform::FreeSlot(SlotType slot) {
  if (!TlsFree(slot)) {
    assert(false);
  }
}

// static
void* ThreadLocalPlatform::GetValueFromSlot(SlotType slot) {
  return TlsGetValue(slot);
}

// static
void ThreadLocalPlatform::SetValueInSlot(SlotType slot, void* value) {
  if (!TlsSetValue(slot, value)) {
    assert(false);
  }
}

}  // namespace internal
}  // namespace mojo

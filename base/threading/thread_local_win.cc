// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/threading/thread_local.h"

#include <windows.h>

#include "base/logging.h"

namespace base {
namespace internal {

// static
void ThreadLocalPlatform::AllocateSlot(SlotType* slot) {
  *slot = TlsAlloc();
  CHECK_NE(*slot, TLS_OUT_OF_INDEXES);
}

// static
void ThreadLocalPlatform::FreeSlot(SlotType slot) {
  if (!TlsFree(slot)) {
    NOTREACHED() << "Failed to deallocate tls slot with TlsFree().";
  }
}

// static
void* ThreadLocalPlatform::GetValueFromSlot(SlotType slot) {
  return TlsGetValue(slot);
}

// static
void ThreadLocalPlatform::SetValueInSlot(SlotType slot, void* value) {
  if (!TlsSetValue(slot, value)) {
    LOG(FATAL) << "Failed to TlsSetValue().";
  }
}

}  // namespace internal
}  // namespace base

// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_UTILITY_LIB_THREAD_LOCAL_H_
#define MOJO_PUBLIC_CPP_UTILITY_LIB_THREAD_LOCAL_H_

#ifndef _WIN32
#include <pthread.h>
#endif

#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace internal {

// Helper functions that abstract the cross-platform APIs.
struct ThreadLocalPlatform {
#ifdef _WIN32
  typedef unsigned long SlotType;
#else
  typedef pthread_key_t SlotType;
#endif

  static void AllocateSlot(SlotType* slot);
  static void FreeSlot(SlotType slot);
  static void* GetValueFromSlot(SlotType slot);
  static void SetValueInSlot(SlotType slot, void* value);
};

// This class is intended to be statically allocated.
template <typename P>
class ThreadLocalPointer {
 public:
  ThreadLocalPointer() : slot_() {}

  void Allocate() { ThreadLocalPlatform::AllocateSlot(&slot_); }

  void Free() { ThreadLocalPlatform::FreeSlot(slot_); }

  P* Get() {
    return static_cast<P*>(ThreadLocalPlatform::GetValueFromSlot(slot_));
  }

  void Set(P* value) { ThreadLocalPlatform::SetValueInSlot(slot_, value); }

 private:
  ThreadLocalPlatform::SlotType slot_;
};

}  // namespace internal
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_UTILITY_LIB_THREAD_LOCAL_H_

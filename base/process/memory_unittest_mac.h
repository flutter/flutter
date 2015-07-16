// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains helpers for the process_util_unittest to allow it to fully
// test the Mac code.

#ifndef BASE_PROCESS_MEMORY_UNITTEST_MAC_H_
#define BASE_PROCESS_MEMORY_UNITTEST_MAC_H_

#include "base/basictypes.h"

namespace base {

// Allocates memory via system allocators. Alas, they take a _signed_ size for
// allocation.
void* AllocateViaCFAllocatorSystemDefault(ssize_t size);
void* AllocateViaCFAllocatorMalloc(ssize_t size);
void* AllocateViaCFAllocatorMallocZone(ssize_t size);

#if !defined(ARCH_CPU_64_BITS)
// See process_util_unittest_mac.mm for an explanation of why this function
// isn't implemented for the 64-bit environment.

// Allocates a huge Objective C object.
void* AllocatePsychoticallyBigObjCObject();

#endif  // !ARCH_CPU_64_BITS

}  // namespace base

#endif  // BASE_PROCESS_MEMORY_UNITTEST_MAC_H_

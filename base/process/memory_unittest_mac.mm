// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/memory_unittest_mac.h"

#import <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>

#if !defined(ARCH_CPU_64_BITS)

// In the 64-bit environment, the Objective-C 2.0 Runtime Reference states
// that sizeof(anInstance) is constrained to 32 bits. That's not necessarily
// "psychotically big" and in fact a 64-bit program is expected to be able to
// successfully allocate an object that large, likely reserving a good deal of
// swap space. The only way to test the behavior of memory exhaustion for
// Objective-C allocation in this environment would be to loop over allocation
// of these large objects, but that would slowly consume all available memory
// and cause swap file proliferation. That's bad, so this behavior isn't
// tested in the 64-bit environment.

@interface PsychoticallyBigObjCObject : NSObject
{
  // In the 32-bit environment, the compiler limits Objective-C objects to
  // < 2GB in size.
  int justUnder2Gigs_[(2U * 1024 * 1024 * 1024 - 1) / sizeof(int)];
}

@end

@implementation PsychoticallyBigObjCObject

@end

namespace base {

void* AllocatePsychoticallyBigObjCObject() {
  return [[PsychoticallyBigObjCObject alloc] init];
}

}  // namespace base

#endif  // ARCH_CPU_64_BITS

namespace base {

void* AllocateViaCFAllocatorSystemDefault(ssize_t size) {
  return CFAllocatorAllocate(kCFAllocatorSystemDefault, size, 0);
}

void* AllocateViaCFAllocatorMalloc(ssize_t size) {
  return CFAllocatorAllocate(kCFAllocatorMalloc, size, 0);
}

void* AllocateViaCFAllocatorMallocZone(ssize_t size) {
  return CFAllocatorAllocate(kCFAllocatorMallocZone, size, 0);
}

}  // namespace base

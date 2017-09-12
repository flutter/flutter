// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/engine/wtf/AddressSpaceRandomization.h"

#include "flutter/sky/engine/wtf/PageAllocator.h"
#include "flutter/sky/engine/wtf/SpinLock.h"

namespace WTF {

namespace {

// This is the same PRNG as used by tcmalloc for mapping address randomness;
// see http://burtleburtle.net/bob/rand/smallprng.html
struct ranctx {
  int lock;
  bool initialized;
  uint32_t a;
  uint32_t b;
  uint32_t c;
  uint32_t d;
};

#define rot(x, k) (((x) << (k)) | ((x) >> (32 - (k))))

uint32_t ranvalInternal(ranctx* x) {
  uint32_t e = x->a - rot(x->b, 27);
  x->a = x->b ^ rot(x->c, 17);
  x->b = x->c + x->d;
  x->c = x->d + e;
  x->d = e + x->a;
  return x->d;
}

#undef rot

uint32_t ranval(ranctx* x) {
  spinLockLock(&x->lock);
  if (UNLIKELY(!x->initialized)) {
    x->initialized = true;
    char c;
    uint32_t seed = static_cast<uint32_t>(reinterpret_cast<uintptr_t>(&c));
    x->a = 0xf1ea5eed;
    x->b = x->c = x->d = seed;
    for (int i = 0; i < 20; ++i) {
      (void)ranvalInternal(x);
    }
  }
  uint32_t ret = ranvalInternal(x);
  spinLockUnlock(&x->lock);
  return ret;
}

static struct ranctx s_ranctx;

}  // namespace

// Calculates a random preferred mapping address. In calculating an
// address, we balance good ASLR against not fragmenting the address
// space too badly.
void* getRandomPageBase() {
  uintptr_t random;
  random = static_cast<uintptr_t>(ranval(&s_ranctx));
#if CPU(X86_64)
  random <<= 32UL;
  random |= static_cast<uintptr_t>(ranval(&s_ranctx));
  // This address mask gives a low liklihood of address space collisions.
  // We handle the situation gracefully if there is a collision.
#if OS(WIN)
  // 64-bit Windows has a bizarrely small 8TB user address space.
  // Allocates in the 1-5TB region.
  random &= 0x3ffffffffffUL;
  random += 0x10000000000UL;
#else
  // Linux and OS X support the full 47-bit user space of x64 processors.
  random &= 0x3fffffffffffUL;
#endif
#elif CPU(ARM64)
  // ARM64 on Linux has 39-bit user space.
  random &= 0x3fffffffffUL;
  random += 0x1000000000UL;
#else   // !CPU(X86_64) && !CPU(ARM64)
  // This is a good range on Windows, Linux and Mac.
  // Allocates in the 0.5-1.5GB region.
  random &= 0x3fffffff;
  random += 0x20000000;
#endif  // CPU(X86_64)
  random &= kPageAllocationGranularityBaseMask;
  return reinterpret_cast<void*>(random);
}

}  // namespace WTF

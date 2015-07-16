// Copyright (c) 2006-2008 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This module gets enough CPU information to optimize the
// atomicops module on x86.

#include <stdint.h>
#include <string.h>

#include "base/atomicops.h"

// Inline cpuid instruction.  In PIC compilations, %ebx contains the address
// of the global offset table.  To avoid breaking such executables, this code
// must preserve that register's value across cpuid instructions.
//
// The include guards are the same as in atomicops.h.
#if defined(__i386__)
#define cpuid(a, b, c, d, inp) \
  asm("mov %%ebx, %%edi\n"     \
      "cpuid\n"                \
      "xchg %%edi, %%ebx\n"    \
      : "=a" (a), "=D" (b), "=c" (c), "=d" (d) : "a" (inp))
#elif defined(__x86_64__)
#define cpuid(a, b, c, d, inp) \
  asm("mov %%rbx, %%rdi\n"     \
      "cpuid\n"                \
      "xchg %%rdi, %%rbx\n"    \
      : "=a" (a), "=D" (b), "=c" (c), "=d" (d) : "a" (inp))
#endif

#if defined(cpuid)        // initialize the struct only on x86

// Set the flags so that code will run correctly and conservatively, so even
// if we haven't been initialized yet, we're probably single threaded, and our
// default values should hopefully be pretty safe.
struct AtomicOps_x86CPUFeatureStruct AtomicOps_Internalx86CPUFeatures = {
  false, // bug can't exist before process spawns multiple threads
  false, // Chrome requires SSE2, but for transition assume not and initialize
         // this properly.
  false, // cmpxchg16b isn't present on early AMD64 CPUs.
};

namespace {

// Initialize the AtomicOps_Internalx86CPUFeatures struct.
void AtomicOps_Internalx86CPUFeaturesInit() {
  uint32_t eax;
  uint32_t ebx;
  uint32_t ecx;
  uint32_t edx;

  // Get vendor string (issue CPUID with eax = 0)
  cpuid(eax, ebx, ecx, edx, 0);
  char vendor[13];
  memcpy(vendor, &ebx, 4);
  memcpy(vendor + 4, &edx, 4);
  memcpy(vendor + 8, &ecx, 4);
  vendor[12] = 0;

  // get feature flags in ecx/edx, and family/model in eax
  cpuid(eax, ebx, ecx, edx, 1);

  int family = (eax >> 8) & 0xf;        // family and model fields
  int model = (eax >> 4) & 0xf;
  if (family == 0xf) {                  // use extended family and model fields
    family += (eax >> 20) & 0xff;
    model += ((eax >> 16) & 0xf) << 4;
  }

  // Opteron Rev E has a bug in which on very rare occasions a locked
  // instruction doesn't act as a read-acquire barrier if followed by a
  // non-locked read-modify-write instruction.  Rev F has this bug in
  // pre-release versions, but not in versions released to customers,
  // so we test only for Rev E, which is family 15, model 32..63 inclusive.
  if (strcmp(vendor, "AuthenticAMD") == 0 &&       // AMD
      family == 15 &&
      32 <= model && model <= 63) {
    AtomicOps_Internalx86CPUFeatures.has_amd_lock_mb_bug = true;
  } else {
    AtomicOps_Internalx86CPUFeatures.has_amd_lock_mb_bug = false;
  }

  // edx bit 26 is SSE2 which we use to tell use whether we can use mfence
  AtomicOps_Internalx86CPUFeatures.has_sse2 = ((edx >> 26) & 1);

  // ecx bit 13 indicates whether the cmpxchg16b instruction is supported
  AtomicOps_Internalx86CPUFeatures.has_cmpxchg16b = ((ecx >> 13) & 1);
}

class AtomicOpsx86Initializer {
 public:
  AtomicOpsx86Initializer() {
    AtomicOps_Internalx86CPUFeaturesInit();
  }
};

// A global to get use initialized on startup via static initialization :/
AtomicOpsx86Initializer g_initer;

}  // namespace

#endif  // if x86

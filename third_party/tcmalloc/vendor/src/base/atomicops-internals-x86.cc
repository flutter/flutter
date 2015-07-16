/* Copyright (c) 2007, Google Inc.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ---
 * This module gets enough CPU information to optimize the
 * atomicops module on x86.
 */

#include "base/atomicops.h"
#include "base/basictypes.h"
#include "base/googleinit.h"
#include "base/logging.h"
#include <string.h>

// This file only makes sense with atomicops-internals-x86.h -- it
// depends on structs that are defined in that file.  If atomicops.h
// doesn't sub-include that file, then we aren't needed, and shouldn't
// try to do anything.
#ifdef BASE_ATOMICOPS_INTERNALS_X86_H_

// Inline cpuid instruction.  In PIC compilations, %ebx contains the address
// of the global offset table.  To avoid breaking such executables, this code
// must preserve that register's value across cpuid instructions.
#if defined(__i386__)
#define cpuid(a, b, c, d, inp) \
  asm ("mov %%ebx, %%edi\n"    \
       "cpuid\n"               \
       "xchg %%edi, %%ebx\n"   \
       : "=a" (a), "=D" (b), "=c" (c), "=d" (d) : "a" (inp))
#elif defined (__x86_64__)
#define cpuid(a, b, c, d, inp) \
  asm ("mov %%rbx, %%rdi\n"    \
       "cpuid\n"               \
       "xchg %%rdi, %%rbx\n"   \
       : "=a" (a), "=D" (b), "=c" (c), "=d" (d) : "a" (inp))
#endif

#if defined(cpuid)        // initialize the struct only on x86

// Set the flags so that code will run correctly and conservatively
// until InitGoogle() is called.
struct AtomicOps_x86CPUFeatureStruct AtomicOps_Internalx86CPUFeatures = {
  false,          // bug can't exist before process spawns multiple threads
  false,          // no SSE2
  false,          // no cmpxchg16b
};

// Initialize the AtomicOps_Internalx86CPUFeatures struct.
static void AtomicOps_Internalx86CPUFeaturesInit() {
  uint32 eax;
  uint32 ebx;
  uint32 ecx;
  uint32 edx;

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

REGISTER_MODULE_INITIALIZER(atomicops_x86, {
  AtomicOps_Internalx86CPUFeaturesInit();
});

#endif

#endif  /* ifdef BASE_ATOMICOPS_INTERNALS_X86_H_ */

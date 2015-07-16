// Copyright (c) 2008, Google Inc.
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
// 
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// ---
// Author: Paul Pluzhnikov
//
// Allow dynamic symbol lookup in the kernel VDSO page.
//
// VDSOSupport -- a class representing kernel VDSO (if present).
//

#include "base/vdso_support.h"

#ifdef HAVE_VDSO_SUPPORT     // defined in vdso_support.h

#include <fcntl.h>
#include <stddef.h>   // for ptrdiff_t

#include "base/atomicops.h"  // for MemoryBarrier
#include "base/linux_syscall_support.h"
#include "base/logging.h"
#include "base/dynamic_annotations.h"
#include "base/basictypes.h"  // for COMPILE_ASSERT

using base::subtle::MemoryBarrier;

#ifndef AT_SYSINFO_EHDR
#define AT_SYSINFO_EHDR 33
#endif

namespace base {

const void *VDSOSupport::vdso_base_ = ElfMemImage::kInvalidBase;
VDSOSupport::GetCpuFn VDSOSupport::getcpu_fn_ = &InitAndGetCPU;
VDSOSupport::VDSOSupport()
    // If vdso_base_ is still set to kInvalidBase, we got here
    // before VDSOSupport::Init has been called. Call it now.
    : image_(vdso_base_ == ElfMemImage::kInvalidBase ? Init() : vdso_base_) {
}

// NOTE: we can't use GoogleOnceInit() below, because we can be
// called by tcmalloc, and none of the *once* stuff may be functional yet.
//
// In addition, we hope that the VDSOSupportHelper constructor
// causes this code to run before there are any threads, and before
// InitGoogle() has executed any chroot or setuid calls.
//
// Finally, even if there is a race here, it is harmless, because
// the operation should be idempotent.
const void *VDSOSupport::Init() {
  if (vdso_base_ == ElfMemImage::kInvalidBase) {
    // Valgrind zaps AT_SYSINFO_EHDR and friends from the auxv[]
    // on stack, and so glibc works as if VDSO was not present.
    // But going directly to kernel via /proc/self/auxv below bypasses
    // Valgrind zapping. So we check for Valgrind separately.
    if (RunningOnValgrind()) {
      vdso_base_ = NULL;
      getcpu_fn_ = &GetCPUViaSyscall;
      return NULL;
    }
    int fd = open("/proc/self/auxv", O_RDONLY);
    if (fd == -1) {
      // Kernel too old to have a VDSO.
      vdso_base_ = NULL;
      getcpu_fn_ = &GetCPUViaSyscall;
      return NULL;
    }
    ElfW(auxv_t) aux;
    while (read(fd, &aux, sizeof(aux)) == sizeof(aux)) {
      if (aux.a_type == AT_SYSINFO_EHDR) {
        COMPILE_ASSERT(sizeof(vdso_base_) == sizeof(aux.a_un.a_val),
                       unexpected_sizeof_pointer_NE_sizeof_a_val);
        vdso_base_ = reinterpret_cast<void *>(aux.a_un.a_val);
        break;
      }
    }
    close(fd);
    if (vdso_base_ == ElfMemImage::kInvalidBase) {
      // Didn't find AT_SYSINFO_EHDR in auxv[].
      vdso_base_ = NULL;
    }
  }
  GetCpuFn fn = &GetCPUViaSyscall;  // default if VDSO not present.
  if (vdso_base_) {
    VDSOSupport vdso;
    SymbolInfo info;
    if (vdso.LookupSymbol("__vdso_getcpu", "LINUX_2.6", STT_FUNC, &info)) {
      // Casting from an int to a pointer is not legal C++.  To emphasize
      // this, we use a C-style cast rather than a C++-style cast.
      fn = (GetCpuFn)(info.address);
    }
  }
  // Subtle: this code runs outside of any locks; prevent compiler
  // from assigning to getcpu_fn_ more than once.
  base::subtle::MemoryBarrier();
  getcpu_fn_ = fn;
  return vdso_base_;
}

const void *VDSOSupport::SetBase(const void *base) {
  CHECK(base != ElfMemImage::kInvalidBase);
  const void *old_base = vdso_base_;
  vdso_base_ = base;
  image_.Init(base);
  // Also reset getcpu_fn_, so GetCPU could be tested with simulated VDSO.
  getcpu_fn_ = &InitAndGetCPU;
  return old_base;
}

bool VDSOSupport::LookupSymbol(const char *name,
                               const char *version,
                               int type,
                               SymbolInfo *info) const {
  return image_.LookupSymbol(name, version, type, info);
}

bool VDSOSupport::LookupSymbolByAddress(const void *address,
                                        SymbolInfo *info_out) const {
  return image_.LookupSymbolByAddress(address, info_out);
}

// NOLINT on 'long' because this routine mimics kernel api.
long VDSOSupport::GetCPUViaSyscall(unsigned *cpu, void *, void *) { // NOLINT
#if defined(__NR_getcpu)
  return sys_getcpu(cpu, NULL, NULL);
#else
  // x86_64 never implemented sys_getcpu(), except as a VDSO call.
  errno = ENOSYS;
  return -1;
#endif
}

// Use fast __vdso_getcpu if available.
long VDSOSupport::InitAndGetCPU(unsigned *cpu, void *x, void *y) { // NOLINT
  Init();
  CHECK_NE(getcpu_fn_, &InitAndGetCPU); // << "Init() did not set getcpu_fn_";
  return (*getcpu_fn_)(cpu, x, y);
}

// This function must be very fast, and may be called from very
// low level (e.g. tcmalloc). Hence I avoid things like
// GoogleOnceInit() and ::operator new.
int GetCPU(void) {
  unsigned cpu;
  int ret_code = (*VDSOSupport::getcpu_fn_)(&cpu, NULL, NULL);
  return ret_code == 0 ? cpu : ret_code;
}

// We need to make sure VDSOSupport::Init() is called before
// the main() runs, since it might do something like setuid or
// chroot.  If VDSOSupport
// is used in any global constructor, this will happen, since
// VDSOSupport's constructor calls Init.  But if not, we need to
// ensure it here, with a global constructor of our own.  This
// is an allowed exception to the normal rule against non-trivial
// global constructors.
static class VDSOInitHelper {
 public:
  VDSOInitHelper() { VDSOSupport::Init(); }
} vdso_init_helper;
}

#endif  // HAVE_VDSO_SUPPORT

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
// VDSO stands for "Virtual Dynamic Shared Object" -- a page of
// executable code, which looks like a shared library, but doesn't
// necessarily exist anywhere on disk, and which gets mmap()ed into
// every process by kernels which support VDSO, such as 2.6.x for 32-bit
// executables, and 2.6.24 and above for 64-bit executables.
//
// More details could be found here:
// http://www.trilithium.com/johan/2005/08/linux-gate/
//
// VDSOSupport -- a class representing kernel VDSO (if present).
//
// Example usage:
//  VDSOSupport vdso;
//  VDSOSupport::SymbolInfo info;
//  typedef (*FN)(unsigned *, void *, void *);
//  FN fn = NULL;
//  if (vdso.LookupSymbol("__vdso_getcpu", "LINUX_2.6", STT_FUNC, &info)) {
//     fn = reinterpret_cast<FN>(info.address);
//  }

#ifndef BASE_VDSO_SUPPORT_H_
#define BASE_VDSO_SUPPORT_H_

#include <config.h>
#include "base/basictypes.h"
#include "base/elf_mem_image.h"

#ifdef HAVE_ELF_MEM_IMAGE

#define HAVE_VDSO_SUPPORT 1

#include <stdlib.h>     // for NULL

namespace base {

// NOTE: this class may be used from within tcmalloc, and can not
// use any memory allocation routines.
class VDSOSupport {
 public:
  VDSOSupport();

  typedef ElfMemImage::SymbolInfo SymbolInfo;
  typedef ElfMemImage::SymbolIterator SymbolIterator;

  // Answers whether we have a vdso at all.
  bool IsPresent() const { return image_.IsPresent(); }

  // Allow to iterate over all VDSO symbols.
  SymbolIterator begin() const { return image_.begin(); }
  SymbolIterator end() const { return image_.end(); }

  // Look up versioned dynamic symbol in the kernel VDSO.
  // Returns false if VDSO is not present, or doesn't contain given
  // symbol/version/type combination.
  // If info_out != NULL, additional details are filled in.
  bool LookupSymbol(const char *name, const char *version,
                    int symbol_type, SymbolInfo *info_out) const;

  // Find info about symbol (if any) which overlaps given address.
  // Returns true if symbol was found; false if VDSO isn't present
  // or doesn't have a symbol overlapping given address.
  // If info_out != NULL, additional details are filled in.
  bool LookupSymbolByAddress(const void *address, SymbolInfo *info_out) const;

  // Used only for testing. Replace real VDSO base with a mock.
  // Returns previous value of vdso_base_. After you are done testing,
  // you are expected to call SetBase() with previous value, in order to
  // reset state to the way it was.
  const void *SetBase(const void *s);

  // Computes vdso_base_ and returns it. Should be called as early as
  // possible; before any thread creation, chroot or setuid.
  static const void *Init();

 private:
  // image_ represents VDSO ELF image in memory.
  // image_.ehdr_ == NULL implies there is no VDSO.
  ElfMemImage image_;

  // Cached value of auxv AT_SYSINFO_EHDR, computed once.
  // This is a tri-state:
  //   kInvalidBase   => value hasn't been determined yet.
  //              0   => there is no VDSO.
  //           else   => vma of VDSO Elf{32,64}_Ehdr.
  //
  // When testing with mock VDSO, low bit is set.
  // The low bit is always available because vdso_base_ is
  // page-aligned.
  static const void *vdso_base_;

  // NOLINT on 'long' because these routines mimic kernel api.
  // The 'cache' parameter may be used by some versions of the kernel,
  // and should be NULL or point to a static buffer containing at
  // least two 'long's.
  static long InitAndGetCPU(unsigned *cpu, void *cache,     // NOLINT 'long'.
                            void *unused);
  static long GetCPUViaSyscall(unsigned *cpu, void *cache,  // NOLINT 'long'.
                               void *unused);
  typedef long (*GetCpuFn)(unsigned *cpu, void *cache,      // NOLINT 'long'.
                           void *unused);

  // This function pointer may point to InitAndGetCPU,
  // GetCPUViaSyscall, or __vdso_getcpu at different stages of initialization.
  static GetCpuFn getcpu_fn_;

  friend int GetCPU(void);  // Needs access to getcpu_fn_.

  DISALLOW_COPY_AND_ASSIGN(VDSOSupport);
};

// Same as sched_getcpu() on later glibc versions.
// Return current CPU, using (fast) __vdso_getcpu@LINUX_2.6 if present,
// otherwise use syscall(SYS_getcpu,...).
// May return -1 with errno == ENOSYS if the kernel doesn't
// support SYS_getcpu.
int GetCPU();
}  // namespace base

#endif  // HAVE_ELF_MEM_IMAGE

#endif  // BASE_VDSO_SUPPORT_H_

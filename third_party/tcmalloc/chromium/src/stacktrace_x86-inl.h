// Copyright (c) 2005, Google Inc.
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
// Author: Sanjay Ghemawat
//
// Produce stack trace

#ifndef BASE_STACKTRACE_X86_INL_H_
#define BASE_STACKTRACE_X86_INL_H_
// Note: this file is included into stacktrace.cc more than once.
// Anything that should only be defined once should be here:

#include "config.h"
#include <stdlib.h>   // for NULL
#include <assert.h>
#if defined(HAVE_SYS_UCONTEXT_H)
#include <sys/ucontext.h>
#elif defined(HAVE_UCONTEXT_H)
#include <ucontext.h>  // for ucontext_t
#elif defined(HAVE_CYGWIN_SIGNAL_H)
// cygwin/signal.h has a buglet where it uses pthread_attr_t without
// #including <pthread.h> itself.  So we have to do it.
# ifdef HAVE_PTHREAD
# include <pthread.h>
# endif
#include <cygwin/signal.h>
typedef ucontext ucontext_t;
#endif
#ifdef HAVE_STDINT_H
#include <stdint.h>   // for uintptr_t
#endif
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_MMAP
#include <sys/mman.h> // for msync
#include "base/vdso_support.h"
#endif

#include "gperftools/stacktrace.h"
#if defined(KEEP_SHADOW_STACKS)
#include "linux_shadow_stacks.h"
#endif  // KEEP_SHADOW_STACKS

#if defined(__linux__) && defined(__i386__) && defined(__ELF__) && defined(HAVE_MMAP)
// Count "push %reg" instructions in VDSO __kernel_vsyscall(),
// preceeding "syscall" or "sysenter".
// If __kernel_vsyscall uses frame pointer, answer 0.
//
// kMaxBytes tells how many instruction bytes of __kernel_vsyscall
// to analyze before giving up. Up to kMaxBytes+1 bytes of
// instructions could be accessed.
//
// Here are known __kernel_vsyscall instruction sequences:
//
// SYSENTER (linux-2.6.26/arch/x86/vdso/vdso32/sysenter.S).
// Used on Intel.
//  0xffffe400 <__kernel_vsyscall+0>:       push   %ecx
//  0xffffe401 <__kernel_vsyscall+1>:       push   %edx
//  0xffffe402 <__kernel_vsyscall+2>:       push   %ebp
//  0xffffe403 <__kernel_vsyscall+3>:       mov    %esp,%ebp
//  0xffffe405 <__kernel_vsyscall+5>:       sysenter
//
// SYSCALL (see linux-2.6.26/arch/x86/vdso/vdso32/syscall.S).
// Used on AMD.
//  0xffffe400 <__kernel_vsyscall+0>:       push   %ebp
//  0xffffe401 <__kernel_vsyscall+1>:       mov    %ecx,%ebp
//  0xffffe403 <__kernel_vsyscall+3>:       syscall
//
// i386 (see linux-2.6.26/arch/x86/vdso/vdso32/int80.S)
//  0xffffe400 <__kernel_vsyscall+0>:       int $0x80
//  0xffffe401 <__kernel_vsyscall+1>:       ret
//
static const int kMaxBytes = 10;

// We use assert()s instead of DCHECK()s -- this is too low level
// for DCHECK().

static int CountPushInstructions(const unsigned char *const addr) {
  int result = 0;
  for (int i = 0; i < kMaxBytes; ++i) {
    if (addr[i] == 0x89) {
      // "mov reg,reg"
      if (addr[i + 1] == 0xE5) {
        // Found "mov %esp,%ebp".
        return 0;
      }
      ++i;  // Skip register encoding byte.
    } else if (addr[i] == 0x0F &&
               (addr[i + 1] == 0x34 || addr[i + 1] == 0x05)) {
      // Found "sysenter" or "syscall".
      return result;
    } else if ((addr[i] & 0xF0) == 0x50) {
      // Found "push %reg".
      ++result;
    } else if (addr[i] == 0xCD && addr[i + 1] == 0x80) {
      // Found "int $0x80"
      assert(result == 0);
      return 0;
    } else {
      // Unexpected instruction.
      assert(0 == "unexpected instruction in __kernel_vsyscall");
      return 0;
    }
  }
  // Unexpected: didn't find SYSENTER or SYSCALL in
  // [__kernel_vsyscall, __kernel_vsyscall + kMaxBytes) interval.
  assert(0 == "did not find SYSENTER or SYSCALL in __kernel_vsyscall");
  return 0;
}
#endif

// Given a pointer to a stack frame, locate and return the calling
// stackframe, or return NULL if no stackframe can be found. Perform sanity
// checks (the strictness of which is controlled by the boolean parameter
// "STRICT_UNWINDING") to reduce the chance that a bad pointer is returned.
template<bool STRICT_UNWINDING, bool WITH_CONTEXT>
static void **NextStackFrame(void **old_sp, const void *uc) {
  void **new_sp = (void **) *old_sp;

#if defined(__linux__) && defined(__i386__) && defined(HAVE_VDSO_SUPPORT)
  if (WITH_CONTEXT && uc != NULL) {
    // How many "push %reg" instructions are there at __kernel_vsyscall?
    // This is constant for a given kernel and processor, so compute
    // it only once.
    static int num_push_instructions = -1;  // Sentinel: not computed yet.
    // Initialize with sentinel value: __kernel_rt_sigreturn can not possibly
    // be there.
    static const unsigned char *kernel_rt_sigreturn_address = NULL;
    static const unsigned char *kernel_vsyscall_address = NULL;
    if (num_push_instructions == -1) {
      base::VDSOSupport vdso;
      if (vdso.IsPresent()) {
        base::VDSOSupport::SymbolInfo rt_sigreturn_symbol_info;
        base::VDSOSupport::SymbolInfo vsyscall_symbol_info;
        if (!vdso.LookupSymbol("__kernel_rt_sigreturn", "LINUX_2.5",
                               STT_FUNC, &rt_sigreturn_symbol_info) ||
            !vdso.LookupSymbol("__kernel_vsyscall", "LINUX_2.5",
                               STT_FUNC, &vsyscall_symbol_info) ||
            rt_sigreturn_symbol_info.address == NULL ||
            vsyscall_symbol_info.address == NULL) {
          // Unexpected: 32-bit VDSO is present, yet one of the expected
          // symbols is missing or NULL.
          assert(0 == "VDSO is present, but doesn't have expected symbols");
          num_push_instructions = 0;
        } else {
          kernel_rt_sigreturn_address =
              reinterpret_cast<const unsigned char *>(
                  rt_sigreturn_symbol_info.address);
          kernel_vsyscall_address =
              reinterpret_cast<const unsigned char *>(
                  vsyscall_symbol_info.address);
          num_push_instructions =
              CountPushInstructions(kernel_vsyscall_address);
        }
      } else {
        num_push_instructions = 0;
      }
    }
    if (num_push_instructions != 0 && kernel_rt_sigreturn_address != NULL &&
        old_sp[1] == kernel_rt_sigreturn_address) {
      const ucontext_t *ucv = static_cast<const ucontext_t *>(uc);
      // This kernel does not use frame pointer in its VDSO code,
      // and so %ebp is not suitable for unwinding.
      void **const reg_ebp =
          reinterpret_cast<void **>(ucv->uc_mcontext.gregs[REG_EBP]);
      const unsigned char *const reg_eip =
          reinterpret_cast<unsigned char *>(ucv->uc_mcontext.gregs[REG_EIP]);
      if (new_sp == reg_ebp &&
          kernel_vsyscall_address <= reg_eip &&
          reg_eip - kernel_vsyscall_address < kMaxBytes) {
        // We "stepped up" to __kernel_vsyscall, but %ebp is not usable.
        // Restore from 'ucv' instead.
        void **const reg_esp =
            reinterpret_cast<void **>(ucv->uc_mcontext.gregs[REG_ESP]);
        // Check that alleged %esp is not NULL and is reasonably aligned.
        if (reg_esp &&
            ((uintptr_t)reg_esp & (sizeof(reg_esp) - 1)) == 0) {
          // Check that alleged %esp is actually readable. This is to prevent
          // "double fault" in case we hit the first fault due to e.g. stack
          // corruption.
          //
          // page_size is linker-initalized to avoid async-unsafe locking
          // that GCC would otherwise insert (__cxa_guard_acquire etc).
          static int page_size;
          if (page_size == 0) {
            // First time through.
            page_size = getpagesize();
          }
          void *const reg_esp_aligned =
              reinterpret_cast<void *>(
                  (uintptr_t)(reg_esp + num_push_instructions - 1) &
                  ~(page_size - 1));
          if (msync(reg_esp_aligned, page_size, MS_ASYNC) == 0) {
            // Alleged %esp is readable, use it for further unwinding.
            new_sp = reinterpret_cast<void **>(
                reg_esp[num_push_instructions - 1]);
          }
        }
      }
    }
  }
#endif

  // Check that the transition from frame pointer old_sp to frame
  // pointer new_sp isn't clearly bogus
  if (STRICT_UNWINDING) {
    // With the stack growing downwards, older stack frame must be
    // at a greater address that the current one.
    if (new_sp <= old_sp) return NULL;
    // Assume stack frames larger than 100,000 bytes are bogus.
    if ((uintptr_t)new_sp - (uintptr_t)old_sp > 100000) return NULL;
  } else {
    // In the non-strict mode, allow discontiguous stack frames.
    // (alternate-signal-stacks for example).
    if (new_sp == old_sp) return NULL;
    if (new_sp > old_sp) {
      // And allow frames upto about 1MB.
      const uintptr_t delta = (uintptr_t)new_sp - (uintptr_t)old_sp;
      const uintptr_t acceptable_delta = 1000000;
      if (delta > acceptable_delta) {
        return NULL;
      }
    }
  }
  if ((uintptr_t)new_sp & (sizeof(void *) - 1)) return NULL;
#ifdef __i386__
  // On 64-bit machines, the stack pointer can be very close to
  // 0xffffffff, so we explicitly check for a pointer into the
  // last two pages in the address space
  if ((uintptr_t)new_sp >= 0xffffe000) return NULL;
#endif
#ifdef HAVE_MMAP
  if (!STRICT_UNWINDING) {
    // Lax sanity checks cause a crash on AMD-based machines with
    // VDSO-enabled kernels.
    // Make an extra sanity check to insure new_sp is readable.
    // Note: NextStackFrame<false>() is only called while the program
    //       is already on its last leg, so it's ok to be slow here.
    static int page_size = getpagesize();
    void *new_sp_aligned = (void *)((uintptr_t)new_sp & ~(page_size - 1));
    if (msync(new_sp_aligned, page_size, MS_ASYNC) == -1)
      return NULL;
  }
#endif
  return new_sp;
}

#endif  // BASE_STACKTRACE_X86_INL_H_

// Note: this part of the file is included several times.
// Do not put globals below.

// The following 4 functions are generated from the code below:
//   GetStack{Trace,Frames}()
//   GetStack{Trace,Frames}WithContext()
//
// These functions take the following args:
//   void** result: the stack-trace, as an array
//   int* sizes: the size of each stack frame, as an array
//               (GetStackFrames* only)
//   int max_depth: the size of the result (and sizes) array(s)
//   int skip_count: how many stack pointers to skip before storing in result
//   void* ucp: a ucontext_t* (GetStack{Trace,Frames}WithContext only)

int GET_STACK_TRACE_OR_FRAMES {
  void **sp;
#if (__GNUC__ > 4) || (__GNUC__ == 4 && __GNUC_MINOR__ >= 2) || __llvm__
  // __builtin_frame_address(0) can return the wrong address on gcc-4.1.0-k8.
  // It's always correct on llvm, and the techniques below aren't (in
  // particular, llvm-gcc will make a copy of pcs, so it's not in sp[2]),
  // so we also prefer __builtin_frame_address when running under llvm.
  sp = reinterpret_cast<void**>(__builtin_frame_address(0));
#elif defined(__i386__)
  // Stack frame format:
  //    sp[0]   pointer to previous frame
  //    sp[1]   caller address
  //    sp[2]   first argument
  //    ...
  // NOTE: This will break under llvm, since result is a copy and not in sp[2]
  sp = (void **)&result - 2;
#elif defined(__x86_64__)
  unsigned long rbp;
  // Move the value of the register %rbp into the local variable rbp.
  // We need 'volatile' to prevent this instruction from getting moved
  // around during optimization to before function prologue is done.
  // An alternative way to achieve this
  // would be (before this __asm__ instruction) to call Noop() defined as
  //   static void Noop() __attribute__ ((noinline));  // prevent inlining
  //   static void Noop() { asm(""); }  // prevent optimizing-away
  __asm__ volatile ("mov %%rbp, %0" : "=r" (rbp));
  // Arguments are passed in registers on x86-64, so we can't just
  // offset from &result
  sp = (void **) rbp;
#else
# error Using stacktrace_x86-inl.h on a non x86 architecture!
#endif

  int n = 0;
#if defined(KEEP_SHADOW_STACKS)
  void **shadow_ip_stack;
  void **shadow_sp_stack;
  int stack_size;
  shadow_ip_stack = (void**) get_shadow_ip_stack(&stack_size);
  shadow_sp_stack = (void**) get_shadow_sp_stack(&stack_size);
  int shadow_index = stack_size - 1;
  for (int i = stack_size - 1; i >= 0; i--) {
    if (sp == shadow_sp_stack[i]) {
      shadow_index = i;
      break;
    }
  }
  void **prev_sp = NULL;
#endif  // KEEP_SHADOW_STACKS
  while (sp && n < max_depth) {
    if (*(sp+1) == reinterpret_cast<void *>(0)) {
      // In 64-bit code, we often see a frame that
      // points to itself and has a return address of 0.
      break;
    }
#if !IS_WITH_CONTEXT
    const void *const ucp = NULL;
#endif
    void **next_sp = NextStackFrame<!IS_STACK_FRAMES, IS_WITH_CONTEXT>(sp, ucp);
    if (skip_count > 0) {
      skip_count--;
#if defined(KEEP_SHADOW_STACKS)
      shadow_index--;
#endif  // KEEP_SHADOW_STACKS
    } else {
      result[n] = *(sp+1);
#if defined(KEEP_SHADOW_STACKS)
      if ((shadow_index > 0) && (sp == shadow_sp_stack[shadow_index])) {
        shadow_index--;
      }
#endif  // KEEP_SHADOW_STACKS

#if IS_STACK_FRAMES
      if (next_sp > sp) {
        sizes[n] = (uintptr_t)next_sp - (uintptr_t)sp;
      } else {
        // A frame-size of 0 is used to indicate unknown frame size.
        sizes[n] = 0;
      }
#endif
      n++;
    }
#if defined(KEEP_SHADOW_STACKS)
    prev_sp = sp;
#endif  // KEEP_SHADOW_STACKS
    sp = next_sp;
  }

#if defined(KEEP_SHADOW_STACKS)
  if (shadow_index >= 0) {
    for (int i = shadow_index; i >= 0; i--) {
      if (shadow_sp_stack[i] > prev_sp) {
        result[n] = shadow_ip_stack[i];
        if (n + 1 < max_depth) {
          n++;
          continue;
        }
      }
      break;
    }
  }
#endif  // KEEP_SHADOW_STACKS
  return n;
}

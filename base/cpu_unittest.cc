// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/cpu.h"
#include "build/build_config.h"

#include "testing/gtest/include/gtest/gtest.h"

// Tests whether we can run extended instructions represented by the CPU
// information. This test actually executes some extended instructions (such as
// MMX, SSE, etc.) supported by the CPU and sees we can run them without
// "undefined instruction" exceptions. That is, this test succeeds when this
// test finishes without a crash.
TEST(CPU, RunExtendedInstructions) {
#if defined(ARCH_CPU_X86_FAMILY)
  // Retrieve the CPU information.
  base::CPU cpu;

// TODO(jschuh): crbug.com/168866 Find a way to enable this on Win64.
#if defined(OS_WIN) && !defined(_M_X64)
  ASSERT_TRUE(cpu.has_mmx());

  // Execute an MMX instruction.
  __asm emms;

  if (cpu.has_sse()) {
    // Execute an SSE instruction.
    __asm xorps xmm0, xmm0;
  }

  if (cpu.has_sse2()) {
    // Execute an SSE 2 instruction.
    __asm psrldq xmm0, 0;
  }

  if (cpu.has_sse3()) {
    // Execute an SSE 3 instruction.
    __asm addsubpd xmm0, xmm0;
  }

  if (cpu.has_ssse3()) {
    // Execute a Supplimental SSE 3 instruction.
    __asm psignb xmm0, xmm0;
  }

  if (cpu.has_sse41()) {
    // Execute an SSE 4.1 instruction.
    __asm pmuldq xmm0, xmm0;
  }

  if (cpu.has_sse42()) {
    // Execute an SSE 4.2 instruction.
    __asm crc32 eax, eax;
  }
#elif defined(OS_POSIX) && defined(__x86_64__)
  ASSERT_TRUE(cpu.has_mmx());

  // Execute an MMX instruction.
  __asm__ __volatile__("emms\n" : : : "mm0");

  if (cpu.has_sse()) {
    // Execute an SSE instruction.
    __asm__ __volatile__("xorps %%xmm0, %%xmm0\n" : : : "xmm0");
  }

  if (cpu.has_sse2()) {
    // Execute an SSE 2 instruction.
    __asm__ __volatile__("psrldq $0, %%xmm0\n" : : : "xmm0");
  }

  if (cpu.has_sse3()) {
    // Execute an SSE 3 instruction.
    __asm__ __volatile__("addsubpd %%xmm0, %%xmm0\n" : : : "xmm0");
  }

  if (cpu.has_ssse3()) {
    // Execute a Supplimental SSE 3 instruction.
    __asm__ __volatile__("psignb %%xmm0, %%xmm0\n" : : : "xmm0");
  }

  if (cpu.has_sse41()) {
    // Execute an SSE 4.1 instruction.
    __asm__ __volatile__("pmuldq %%xmm0, %%xmm0\n" : : : "xmm0");
  }

  if (cpu.has_sse42()) {
    // Execute an SSE 4.2 instruction.
    __asm__ __volatile__("crc32 %%eax, %%eax\n" : : : "eax");
  }
#endif
#endif
}

/*
 * Copyright (C) 2006, 2007, 2008, 2009, 2013 Apple Inc. All rights reserved.
 * Copyright (C) 2007-2009 Torch Mobile, Inc.
 * Copyright (C) 2010, 2011 Research In Motion Limited. All rights reserved.
 * Copyright (C) 2013 Samsung Electronics. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_WTF_CPU_H_
#define SKY_ENGINE_WTF_CPU_H_

#include "flutter/sky/engine/wtf/Compiler.h"

/* CPU() - the target CPU architecture */
#define CPU(WTF_FEATURE) \
  (defined WTF_CPU_##WTF_FEATURE && WTF_CPU_##WTF_FEATURE)

/* ==== CPU() - the target CPU architecture ==== */

/* This defines CPU(BIG_ENDIAN) or nothing, as appropriate. */
/* This defines CPU(32BIT) or CPU(64BIT), as appropriate. */

/* CPU(X86) - i386 / x86 32-bit */
#if defined(__i386__) || defined(i386) || defined(_M_IX86) || \
    defined(_X86_) || defined(__THW_INTEL)
#define WTF_CPU_X86 1
#endif

/* CPU(X86_64) - AMD64 / Intel64 / x86_64 64-bit */
#if defined(__x86_64__) || defined(_M_X64)
#define WTF_CPU_X86_64 1
#define WTF_CPU_64BIT 1
#endif

/* CPU(ARM) - ARM, any version*/
#define WTF_ARM_ARCH_AT_LEAST(N) \
  (CPU(ARM) && defined(WTF_ARM_ARCH_VERSION) && WTF_ARM_ARCH_VERSION >= N)

#if defined(arm) || defined(__arm__) || defined(ARM) || defined(_ARM_)
#define WTF_CPU_ARM 1

#if defined(__ARMEB__)
#define WTF_CPU_BIG_ENDIAN 1

#elif !defined(__ARM_EABI__) && !defined(__EABI__) && !defined(__VFP_FP__) && \
    !defined(ANDROID)
#define WTF_CPU_MIDDLE_ENDIAN 1

#endif

/* Set WTF_ARM_ARCH_VERSION */
#if defined(__ARM_ARCH_4__) || defined(__ARM_ARCH_4T__) || \
    defined(__MARM_ARMV4__)
#define WTF_ARM_ARCH_VERSION 4

#elif defined(__ARM_ARCH_5__) || defined(__ARM_ARCH_5T__) || \
    defined(__MARM_ARMV5__)
#define WTF_ARM_ARCH_VERSION 5

#elif defined(__ARM_ARCH_5E__) || defined(__ARM_ARCH_5TE__) || \
    defined(__ARM_ARCH_5TEJ__)
#define WTF_ARM_ARCH_VERSION 5

#elif defined(__ARM_ARCH_6__) || defined(__ARM_ARCH_6J__) ||  \
    defined(__ARM_ARCH_6K__) || defined(__ARM_ARCH_6Z__) ||   \
    defined(__ARM_ARCH_6ZK__) || defined(__ARM_ARCH_6T2__) || \
    defined(__ARMV6__)
#define WTF_ARM_ARCH_VERSION 6

#elif defined(__ARM_ARCH_7A__) || defined(__ARM_ARCH_7R__) || \
    defined(__ARM_ARCH_7S__)
#define WTF_ARM_ARCH_VERSION 7

/* MSVC sets _M_ARM */
#elif defined(_M_ARM)
#define WTF_ARM_ARCH_VERSION _M_ARM
#else
#define WTF_ARM_ARCH_VERSION 0

#endif

/* Set WTF_THUMB_ARCH_VERSION */
#if defined(__ARM_ARCH_4T__)
#define WTF_THUMB_ARCH_VERSION 1

#elif defined(__ARM_ARCH_5T__) || defined(__ARM_ARCH_5TE__) || \
    defined(__ARM_ARCH_5TEJ__)
#define WTF_THUMB_ARCH_VERSION 2

#elif defined(__ARM_ARCH_6J__) || defined(__ARM_ARCH_6K__) || \
    defined(__ARM_ARCH_6Z__) || defined(__ARM_ARCH_6ZK__) ||  \
    defined(__ARM_ARCH_6M__)
#define WTF_THUMB_ARCH_VERSION 3

#elif defined(__ARM_ARCH_6T2__) || defined(__ARM_ARCH_7__) || \
    defined(__ARM_ARCH_7A__) || defined(__ARM_ARCH_7M__) ||   \
    defined(__ARM_ARCH_7R__) || defined(__ARM_ARCH_7S__)
#define WTF_THUMB_ARCH_VERSION 4

#else
#define WTF_THUMB_ARCH_VERSION 0
#endif

/* CPU(ARM_THUMB2) - Thumb2 instruction set is available */
#if !defined(WTF_CPU_ARM_THUMB2)
#if defined(thumb2) || defined(__thumb2__) || \
    ((defined(__thumb) || defined(__thumb__)) && WTF_THUMB_ARCH_VERSION == 4)
#define WTF_CPU_ARM_THUMB2 1
#elif WTF_ARM_ARCH_AT_LEAST(4)
#define WTF_CPU_ARM_THUMB2 0
#else
#error "Unsupported ARM architecture"
#endif
#endif /* !defined(WTF_CPU_ARM_THUMB2) */

#if defined(__ARM_NEON__) && !defined(WTF_CPU_ARM_NEON)
#define WTF_CPU_ARM_NEON 1
#endif

#if CPU(ARM_NEON)
// All NEON intrinsics usage can be disabled by this macro.
#define HAVE_ARM_NEON_INTRINSICS 1
#endif

#if defined(__ARM_ARCH_7S__)
#define WTF_CPU_APPLE_ARMV7S 1
#endif

#if !defined(WTF_CPU_64BIT)
#define WTF_CPU_32BIT 1
#endif

#endif /* ARM */

/* CPU(ARM64) - AArch64 64-bit */
#if defined(__aarch64__)
#define WTF_CPU_ARM64 1
#define WTF_CPU_64BIT 1
#endif

#endif  // SKY_ENGINE_WTF_CPU_H_

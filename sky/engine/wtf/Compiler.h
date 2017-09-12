/*
 * Copyright (C) 2011, 2012 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_WTF_COMPILER_H_
#define SKY_ENGINE_WTF_COMPILER_H_

/* COMPILER() - the compiler being used to build the project */
#define COMPILER(WTF_FEATURE) \
  (defined WTF_COMPILER_##WTF_FEATURE && WTF_COMPILER_##WTF_FEATURE)

/* ==== COMPILER() - the compiler being used to build the project ==== */

/* COMPILER(CLANG) - Clang  */
#if defined(__clang__)
#define WTF_COMPILER_CLANG 1

#define CLANG_PRAGMA(PRAGMA) _Pragma(PRAGMA)
#endif

#ifndef CLANG_PRAGMA
#define CLANG_PRAGMA(PRAGMA)
#endif

/* COMPILER(GCC) - GNU Compiler Collection */
#if defined(__GNUC__)
#define WTF_COMPILER_GCC 1
#define GCC_VERSION \
  (__GNUC__ * 10000 + __GNUC_MINOR__ * 100 + __GNUC_PATCHLEVEL__)
#define GCC_VERSION_AT_LEAST(major, minor, patch) \
  (GCC_VERSION >= (major * 10000 + minor * 100 + patch))
#else
/* Define this for !GCC compilers, just so we can write things like
 * GCC_VERSION_AT_LEAST(4, 1, 0). */
#define GCC_VERSION_AT_LEAST(major, minor, patch) 0
#endif

/* ==== Compiler features ==== */

/* ALWAYS_INLINE */

#ifndef ALWAYS_INLINE
#if COMPILER(GCC) && defined(NDEBUG)
#define ALWAYS_INLINE inline __attribute__((__always_inline__))
#else
#define ALWAYS_INLINE inline
#endif
#endif

/* NEVER_INLINE */

#ifndef NEVER_INLINE
#if COMPILER(GCC)
#define NEVER_INLINE __attribute__((__noinline__))
#else
#define NEVER_INLINE
#endif
#endif

/* UNLIKELY */

#ifndef UNLIKELY
#if COMPILER(GCC)
#define UNLIKELY(x) __builtin_expect((x), 0)
#else
#define UNLIKELY(x) (x)
#endif
#endif

/* LIKELY */

#ifndef LIKELY
#if COMPILER(GCC)
#define LIKELY(x) __builtin_expect((x), 1)
#else
#define LIKELY(x) (x)
#endif
#endif

/* NO_RETURN */

#ifndef NO_RETURN
#if COMPILER(GCC)
#define NO_RETURN __attribute((__noreturn__))
#else
#define NO_RETURN
#endif
#endif

/* WARN_UNUSED_RETURN */

#if COMPILER(GCC)
#define WARN_UNUSED_RETURN __attribute__((warn_unused_result))
#else
#define WARN_UNUSED_RETURN
#endif

/* ALLOW_UNUSED */

#if COMPILER(GCC)
#define ALLOW_UNUSED __attribute__((unused))
#else
#define ALLOW_UNUSED
#endif

/* REFERENCED_FROM_ASM */

#ifndef REFERENCED_FROM_ASM
#if COMPILER(GCC)
#define REFERENCED_FROM_ASM __attribute__((used))
#else
#define REFERENCED_FROM_ASM
#endif
#endif

/* WTF_PRETTY_FUNCTION */

#if COMPILER(GCC)
#define WTF_PRETTY_FUNCTION __PRETTY_FUNCTION__
#else
#define WTF_PRETTY_FUNCTION __FUNCTION__
#endif

#endif  // SKY_ENGINE_WTF_COMPILER_H_

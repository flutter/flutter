/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
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
 */

#ifndef SKY_ENGINE_PUBLIC_PLATFORM_WEBCOMMON_H_
#define SKY_ENGINE_PUBLIC_PLATFORM_WEBCOMMON_H_

#if !defined(BLINK_IMPLEMENTATION)
#define BLINK_IMPLEMENTATION 0
#endif

#if !defined(BLINK_PLATFORM_IMPLEMENTATION)
#define BLINK_PLATFORM_IMPLEMENTATION 0
#endif

#if !defined(BLINK_COMMON_IMPLEMENTATION)
#define BLINK_COMMON_IMPLEMENTATION 0
#endif

#if defined(COMPONENT_BUILD)
#define BLINK_EXPORT __attribute__((visibility("default")))
#define BLINK_PLATFORM_EXPORT __attribute__((visibility("default")))
#define BLINK_COMMON_EXPORT __attribute__((visibility("default")))
#else  // defined(COMPONENT_BUILD)
#define BLINK_EXPORT
#define BLINK_PLATFORM_EXPORT
#define BLINK_COMMON_EXPORT
#endif

// -----------------------------------------------------------------------------
// Basic types

#include <stddef.h>  // For size_t
#include <stdint.h>  // For int32_t

namespace blink {

// UTF-32 character type
typedef int32_t WebUChar32;

// UTF-16 character type
typedef unsigned short WebUChar;

// Latin-1 character type
typedef unsigned char WebLChar;

// -----------------------------------------------------------------------------
// Assertions

BLINK_COMMON_EXPORT void failedAssertion(const char* file,
                                         int line,
                                         const char* function,
                                         const char* assertion);

}  // namespace blink

// Ideally, only use inside the public directory but outside of INSIDE_BLINK
// blocks.  (Otherwise use WTF's ASSERT.)
#if defined(NDEBUG)
#define BLINK_ASSERT(assertion) ((void)0)
#else
#define BLINK_ASSERT(assertion)                                      \
  do {                                                               \
    if (!(assertion))                                                \
      failedAssertion(__FILE__, __LINE__, __FUNCTION__, #assertion); \
  } while (0)
#endif

#define BLINK_ASSERT_NOT_REACHED() BLINK_ASSERT(0)

#endif  // SKY_ENGINE_PUBLIC_PLATFORM_WEBCOMMON_H_

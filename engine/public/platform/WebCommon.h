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

#ifndef WebCommon_h
#define WebCommon_h

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
    #if defined(WIN32)
        #if BLINK_IMPLEMENTATION
            #define BLINK_EXPORT __declspec(dllexport)
        #else // BLINK_IMPLEMENTATION
            #define BLINK_EXPORT __declspec(dllimport)
        #endif
        #if BLINK_PLATFORM_IMPLEMENTATION
            #define BLINK_PLATFORM_EXPORT __declspec(dllexport)
        #else // BLINK_PLATFORM_IMPLEMENTATION
            #define BLINK_PLATFORM_EXPORT __declspec(dllimport)
        #endif
        #if BLINK_COMMON_IMPLEMENTATION
            #define BLINK_COMMON_EXPORT __declspec(dllexport)
        #else // BLINK_COMMON_IMPLEMENTATION
            #define BLINK_COMMON_EXPORT __declspec(dllimport)
        #endif
    #else // defined(WIN32)
        #define BLINK_EXPORT __attribute__((visibility("default")))
        #define BLINK_PLATFORM_EXPORT __attribute__((visibility("default")))
        #define BLINK_COMMON_EXPORT __attribute__((visibility("default")))
    #endif
#else // defined(COMPONENT_BUILD)
    #define BLINK_EXPORT
    #define BLINK_PLATFORM_EXPORT
    #define BLINK_COMMON_EXPORT
#endif


// -----------------------------------------------------------------------------
// Basic types

#include <stddef.h> // For size_t

#if defined(WIN32)
// Visual Studio doesn't have stdint.h.
typedef short int16_t;
typedef unsigned short uint16_t;
typedef int int32_t;
typedef unsigned int uint32_t;
typedef unsigned __int64 uint64_t;
#else
#include <stdint.h> // For int32_t
#endif

namespace blink {

// UTF-32 character type
typedef int32_t WebUChar32;

// UTF-16 character type
#if defined(WIN32)
typedef wchar_t WebUChar;
#else
typedef unsigned short WebUChar;
#endif

// Latin-1 character type
typedef unsigned char WebLChar;

// -----------------------------------------------------------------------------
// Assertions

BLINK_COMMON_EXPORT void failedAssertion(const char* file, int line, const char* function, const char* assertion);

} // namespace blink

// Ideally, only use inside the public directory but outside of INSIDE_BLINK blocks.  (Otherwise use WTF's ASSERT.)
#if defined(NDEBUG)
#define BLINK_ASSERT(assertion) ((void)0)
#else
#define BLINK_ASSERT(assertion) do { \
    if (!(assertion)) \
        failedAssertion(__FILE__, __LINE__, __FUNCTION__, #assertion); \
} while (0)
#endif

#define BLINK_ASSERT_NOT_REACHED() BLINK_ASSERT(0)

#endif

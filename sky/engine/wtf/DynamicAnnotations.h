/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
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

#ifndef SKY_ENGINE_WTF_DYNAMICANNOTATIONS_H_
#define SKY_ENGINE_WTF_DYNAMICANNOTATIONS_H_

/* This file defines dynamic annotations for use with dynamic analysis
 * tool such as ThreadSanitizer, Valgrind, etc.
 *
 * Dynamic annotation is a source code annotation that affects
 * the generated code (that is, the annotation is not a comment).
 * Each such annotation is attached to a particular
 * instruction and/or to a particular object (address) in the program.
 *
 * By using dynamic annotations a developer can give more details to the dynamic
 * analysis tool to improve its precision.
 *
 * In C/C++ program the annotations are represented as C macros.
 * With the default build flags, these macros are empty, hence don't affect
 * performance of a compiled binary.
 * If dynamic annotations are enabled, they just call no-op functions.
 * The dynamic analysis tools can intercept these functions and replace them
 * with their own implementations.
 *
 * See http://code.google.com/p/data-race-test/wiki/DynamicAnnotations for more
 * information.
 */

#include "flutter/sky/engine/wtf/OperatingSystem.h"
#include "flutter/sky/engine/wtf/WTFExport.h"

#if USE(DYNAMIC_ANNOTATIONS)
/* Tell data race detector that we're not interested in reports on the given
 * address range. */
#define WTF_ANNOTATE_BENIGN_RACE_SIZED(address, size, description) \
  WTFAnnotateBenignRaceSized(__FILE__, __LINE__, address, size, description)
#define WTF_ANNOTATE_BENIGN_RACE(pointer, description)                        \
  WTFAnnotateBenignRaceSized(__FILE__, __LINE__, pointer, sizeof(*(pointer)), \
                             description)

/* Annotations for user-defined synchronization mechanisms.
 * These annotations can be used to define happens-before arcs in user-defined
 * synchronization mechanisms: the race detector will infer an arc from
 * the former to the latter when they share the same argument pointer.
 *
 * The most common case requiring annotations is atomic reference counting:
 * bool deref() {
 *     ANNOTATE_HAPPENS_BEFORE(&m_refCount);
 *     if (!atomicDecrement(&m_refCount)) {
 *         // m_refCount is now 0
 *         ANNOTATE_HAPPENS_AFTER(&m_refCount);
 *         // "return true; happens-after each atomicDecrement of m_refCount"
 *         return true;
 *     }
 *     return false;
 * }
 */
#define WTF_ANNOTATE_HAPPENS_BEFORE(address) \
  WTFAnnotateHappensBefore(__FILE__, __LINE__, address)
#define WTF_ANNOTATE_HAPPENS_AFTER(address) \
  WTFAnnotateHappensAfter(__FILE__, __LINE__, address)

#ifdef __cplusplus
extern "C" {
#endif
/* Don't use these directly, use the above macros instead. */
WTF_EXPORT void WTFAnnotateBenignRaceSized(const char* file,
                                           int line,
                                           const volatile void* memory,
                                           long size,
                                           const char* description);
WTF_EXPORT void WTFAnnotateHappensBefore(const char* file,
                                         int line,
                                         const volatile void* address);
WTF_EXPORT void WTFAnnotateHappensAfter(const char* file,
                                        int line,
                                        const volatile void* address);
#ifdef __cplusplus
}  // extern "C"
#endif

#else  // USE(DYNAMIC_ANNOTATIONS)
/* These macros are empty when dynamic annotations are not enabled so you can
 * use them without affecting the performance of release binaries. */
#define WTF_ANNOTATE_BENIGN_RACE_SIZED(address, size, description)
#define WTF_ANNOTATE_BENIGN_RACE(pointer, description)
#define WTF_ANNOTATE_HAPPENS_BEFORE(address)
#define WTF_ANNOTATE_HAPPENS_AFTER(address)
#endif  // USE(DYNAMIC_ANNOTATIONS)

#endif  // SKY_ENGINE_WTF_DYNAMICANNOTATIONS_H_

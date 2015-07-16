/* Copyright (c) 2011, Google Inc.
 * All rights reserved.
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

#ifdef _MSC_VER
# include <windows.h>
#endif

#ifdef __cplusplus
# error "This file should be built as pure C to avoid name mangling"
#endif

#include <stdlib.h>
#include <string.h>

#include "base/third_party/dynamic_annotations/dynamic_annotations.h"

#ifdef __GNUC__
/* valgrind.h uses gcc extensions so it won't build with other compilers */
# include "base/third_party/valgrind/valgrind.h"
#endif

/* Compiler-based ThreadSanitizer defines
   DYNAMIC_ANNOTATIONS_EXTERNAL_IMPL = 1
   and provides its own definitions of the functions. */

#ifndef DYNAMIC_ANNOTATIONS_EXTERNAL_IMPL
# define DYNAMIC_ANNOTATIONS_EXTERNAL_IMPL 0
#endif

/* Each function is empty and called (via a macro) only in debug mode.
   The arguments are captured by dynamic tools at runtime. */

#if DYNAMIC_ANNOTATIONS_ENABLED == 1 \
    && DYNAMIC_ANNOTATIONS_EXTERNAL_IMPL == 0

/* Identical code folding(-Wl,--icf=all) countermeasures.
   This makes all Annotate* functions different, which prevents the linker from
   folding them. */
#ifdef __COUNTER__
#define DYNAMIC_ANNOTATIONS_IMPL \
  volatile short lineno = (__LINE__ << 8) + __COUNTER__; (void)lineno;
#else
#define DYNAMIC_ANNOTATIONS_IMPL \
  volatile short lineno = (__LINE__ << 8); (void)lineno;
#endif

/* WARNING: always add new annotations to the end of the list.
   Otherwise, lineno (see above) numbers for different Annotate* functions may
   conflict. */
void DYNAMIC_ANNOTATIONS_NAME(AnnotateRWLockCreate)(
    const char *file, int line, const volatile void *lock)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateRWLockDestroy)(
    const char *file, int line, const volatile void *lock)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateRWLockAcquired)(
    const char *file, int line, const volatile void *lock, long is_w)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateRWLockReleased)(
    const char *file, int line, const volatile void *lock, long is_w)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateBarrierInit)(
    const char *file, int line, const volatile void *barrier, long count,
    long reinitialization_allowed)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateBarrierWaitBefore)(
    const char *file, int line, const volatile void *barrier)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateBarrierWaitAfter)(
    const char *file, int line, const volatile void *barrier)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateBarrierDestroy)(
    const char *file, int line, const volatile void *barrier)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateCondVarWait)(
    const char *file, int line, const volatile void *cv,
    const volatile void *lock)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateCondVarSignal)(
    const char *file, int line, const volatile void *cv)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateCondVarSignalAll)(
    const char *file, int line, const volatile void *cv)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateHappensBefore)(
    const char *file, int line, const volatile void *obj)
{DYNAMIC_ANNOTATIONS_IMPL};

void DYNAMIC_ANNOTATIONS_NAME(AnnotateHappensAfter)(
    const char *file, int line, const volatile void *obj)
{DYNAMIC_ANNOTATIONS_IMPL};

void DYNAMIC_ANNOTATIONS_NAME(AnnotatePublishMemoryRange)(
    const char *file, int line, const volatile void *address, long size)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateUnpublishMemoryRange)(
    const char *file, int line, const volatile void *address, long size)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotatePCQCreate)(
    const char *file, int line, const volatile void *pcq)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotatePCQDestroy)(
    const char *file, int line, const volatile void *pcq)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotatePCQPut)(
    const char *file, int line, const volatile void *pcq)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotatePCQGet)(
    const char *file, int line, const volatile void *pcq)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateNewMemory)(
    const char *file, int line, const volatile void *mem, long size)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateExpectRace)(
    const char *file, int line, const volatile void *mem,
    const char *description)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateFlushExpectedRaces)(
    const char *file, int line)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateBenignRace)(
    const char *file, int line, const volatile void *mem,
    const char *description)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateBenignRaceSized)(
    const char *file, int line, const volatile void *mem, long size,
    const char *description)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateMutexIsUsedAsCondVar)(
    const char *file, int line, const volatile void *mu)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateMutexIsNotPHB)(
    const char *file, int line, const volatile void *mu)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateTraceMemory)(
    const char *file, int line, const volatile void *arg)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateThreadName)(
    const char *file, int line, const char *name)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateIgnoreReadsBegin)(
    const char *file, int line)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateIgnoreReadsEnd)(
    const char *file, int line)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateIgnoreWritesBegin)(
    const char *file, int line)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateIgnoreWritesEnd)(
    const char *file, int line)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateIgnoreSyncBegin)(
    const char *file, int line)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateIgnoreSyncEnd)(
    const char *file, int line)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateEnableRaceDetection)(
    const char *file, int line, int enable)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateNoOp)(
    const char *file, int line, const volatile void *arg)
{DYNAMIC_ANNOTATIONS_IMPL}

void DYNAMIC_ANNOTATIONS_NAME(AnnotateFlushState)(
    const char *file, int line)
{DYNAMIC_ANNOTATIONS_IMPL}

#endif  /* DYNAMIC_ANNOTATIONS_ENABLED == 1
    && DYNAMIC_ANNOTATIONS_EXTERNAL_IMPL == 0 */

#if DYNAMIC_ANNOTATIONS_PROVIDE_RUNNING_ON_VALGRIND == 1 \
    && DYNAMIC_ANNOTATIONS_EXTERNAL_IMPL == 0
static int GetRunningOnValgrind(void) {
#ifdef RUNNING_ON_VALGRIND
  if (RUNNING_ON_VALGRIND) return 1;
#endif

#ifndef _MSC_VER
  char *running_on_valgrind_str = getenv("RUNNING_ON_VALGRIND");
  if (running_on_valgrind_str) {
    return strcmp(running_on_valgrind_str, "0") != 0;
  }
#else
  /* Visual Studio issues warnings if we use getenv,
   * so we use GetEnvironmentVariableA instead.
   */
  char value[100] = "1";
  int res = GetEnvironmentVariableA("RUNNING_ON_VALGRIND",
                                    value, sizeof(value));
  /* value will remain "1" if res == 0 or res >= sizeof(value). The latter
   * can happen only if the given value is long, in this case it can't be "0".
   */
  if (res > 0 && strcmp(value, "0") != 0)
    return 1;
#endif
  return 0;
}

/* See the comments in dynamic_annotations.h */
int RunningOnValgrind(void) {
  static volatile int running_on_valgrind = -1;
  /* C doesn't have thread-safe initialization of statics, and we
     don't want to depend on pthread_once here, so hack it. */
  int local_running_on_valgrind = running_on_valgrind;
  if (local_running_on_valgrind == -1)
    running_on_valgrind = local_running_on_valgrind = GetRunningOnValgrind();
  return local_running_on_valgrind;
}

#endif /* DYNAMIC_ANNOTATIONS_PROVIDE_RUNNING_ON_VALGRIND == 1
    && DYNAMIC_ANNOTATIONS_EXTERNAL_IMPL == 0 */

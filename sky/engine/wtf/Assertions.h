/*
 * Copyright (C) 2003, 2006, 2007 Apple Inc.  All rights reserved.
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_WTF_ASSERTIONS_H_
#define SKY_ENGINE_WTF_ASSERTIONS_H_

/*
   No namespaces because this file has to be includable from C and Objective-C.

   Note, this file uses many GCC extensions, but it should be compatible with
   C, Objective C, C++, and Objective C++.

   For non-debug builds, everything is disabled by default, except for the
   RELEASE_ASSERT family of macros.

   Defining any of the symbols explicitly prevents this from having any effect.
*/

#include <cstddef>

#include "flutter/sky/engine/wtf/Compiler.h"
#include "flutter/sky/engine/wtf/OperatingSystem.h"
#include "flutter/sky/engine/wtf/WTFExport.h"

/* Users must test "#if ENABLE(ASSERT)", which helps ensure that code
   testing this macro has included this header. */
#ifndef ENABLE_ASSERT
#ifdef NDEBUG
/* Disable ASSERT* macros in release mode by default. */
#define ENABLE_ASSERT 0
#else
#define ENABLE_ASSERT 1
#endif /* NDEBUG */
#endif

#ifndef BACKTRACE_DISABLED
#define BACKTRACE_DISABLED !ENABLE(ASSERT)
#endif

#ifndef ASSERT_MSG_DISABLED
#define ASSERT_MSG_DISABLED !ENABLE(ASSERT)
#endif

#ifndef ASSERT_ARG_DISABLED
#define ASSERT_ARG_DISABLED !ENABLE(ASSERT)
#endif

#ifndef FATAL_DISABLED
#define FATAL_DISABLED !ENABLE(ASSERT)
#endif

#ifndef ERROR_DISABLED
#define ERROR_DISABLED !ENABLE(ASSERT)
#endif

#ifndef LOG_DISABLED
#define LOG_DISABLED !ENABLE(ASSERT)
#endif

/* WTF logging functions can process %@ in the format string to log a NSObject*
   but the printf format attribute emits a warning when %@ is used in the format
   string.  Until <rdar://problem/5195437> is resolved we can't include the
   attribute when being used from Objective-C code in case it decides to use %@.
 */
#if COMPILER(GCC) && !defined(__OBJC__)
#define WTF_ATTRIBUTE_PRINTF(formatStringArgument, extraArguments) \
  __attribute__((__format__(printf, formatStringArgument, extraArguments)))
#else
#define WTF_ATTRIBUTE_PRINTF(formatStringArgument, extraArguments)
#endif

/* These helper functions are always declared, but not necessarily always
 * defined if the corresponding function is disabled. */

#ifdef __cplusplus
extern "C" {
#endif

typedef enum { WTFLogChannelOff, WTFLogChannelOn } WTFLogChannelState;

typedef struct {
  WTFLogChannelState state;
} WTFLogChannel;

WTF_EXPORT void WTFReportAssertionFailure(const char* file,
                                          int line,
                                          const char* function,
                                          const char* assertion);
WTF_EXPORT void WTFReportAssertionFailureWithMessage(const char* file,
                                                     int line,
                                                     const char* function,
                                                     const char* assertion,
                                                     const char* format,
                                                     ...)
    WTF_ATTRIBUTE_PRINTF(5, 6);
WTF_EXPORT void WTFReportArgumentAssertionFailure(const char* file,
                                                  int line,
                                                  const char* function,
                                                  const char* argName,
                                                  const char* assertion);
WTF_EXPORT void WTFReportFatalError(const char* file,
                                    int line,
                                    const char* function,
                                    const char* format,
                                    ...) WTF_ATTRIBUTE_PRINTF(4, 5);
WTF_EXPORT void WTFReportError(const char* file,
                               int line,
                               const char* function,
                               const char* format,
                               ...) WTF_ATTRIBUTE_PRINTF(4, 5);
WTF_EXPORT void WTFLog(WTFLogChannel*, const char* format, ...)
    WTF_ATTRIBUTE_PRINTF(2, 3);
WTF_EXPORT void WTFLogVerbose(const char* file,
                              int line,
                              const char* function,
                              WTFLogChannel*,
                              const char* format,
                              ...) WTF_ATTRIBUTE_PRINTF(5, 6);
WTF_EXPORT void WTFLogAlways(const char* format, ...)
    WTF_ATTRIBUTE_PRINTF(1, 2);

WTF_EXPORT void WTFReportBacktrace();

#ifdef __cplusplus
}
#endif

/* IMMEDIATE_CRASH() - Like CRASH() below but crashes in the fastest, simplest
 * possible way with no attempt at logging. */
#ifndef IMMEDIATE_CRASH
#if COMPILER(GCC)
#define IMMEDIATE_CRASH() __builtin_trap()
#else
#define IMMEDIATE_CRASH() ((void (*)())0)()
#endif
#endif

/* CRASH() - Raises a fatal error resulting in program termination and
   triggering either the debugger or the crash reporter.

   Use CRASH() in response to known, unrecoverable errors like out-of-memory.
   Macro is enabled in both debug and release mode.
   To test for unknown errors and verify assumptions, use ASSERT instead, to
   avoid impacting performance in release builds.

   Signals are ignored by the crash reporter on OS X so we must do better.
*/
#ifndef CRASH
#define CRASH() \
  (WTFReportBacktrace(), (*(int*)0xfbadbeef = 0), IMMEDIATE_CRASH())
#endif

#if COMPILER(CLANG)
#define NO_RETURN_DUE_TO_CRASH NO_RETURN
#else
#define NO_RETURN_DUE_TO_CRASH
#endif

/* BACKTRACE

  Print a backtrace to the same location as ASSERT messages.
*/
#if BACKTRACE_DISABLED

#define BACKTRACE() ((void)0)

#else

#define BACKTRACE()       \
  do {                    \
    WTFReportBacktrace(); \
  } while (false)

#endif

/* ASSERT, ASSERT_NOT_REACHED, ASSERT_UNUSED

  These macros are compiled out of release builds.
  Expressions inside them are evaluated in debug builds only.
*/
#if OS(WIN)
/* FIXME: Change to use something other than ASSERT to avoid this conflict with
 * the underlying platform */
#undef ASSERT
#endif

#if ENABLE(ASSERT)

#define ASSERT(assertion)                                                      \
  (!(assertion) ? (WTFReportAssertionFailure(__FILE__, __LINE__,               \
                                             WTF_PRETTY_FUNCTION, #assertion), \
                   CRASH())                                                    \
                : (void)0)

#define ASSERT_AT(assertion, file, line, function)                     \
  (!(assertion)                                                        \
       ? (WTFReportAssertionFailure(file, line, function, #assertion), \
          CRASH())                                                     \
       : (void)0)

#define ASSERT_NOT_REACHED()                                               \
  do {                                                                     \
    WTFReportAssertionFailure(__FILE__, __LINE__, WTF_PRETTY_FUNCTION, 0); \
    CRASH();                                                               \
  } while (0)

#define ASSERT_UNUSED(variable, assertion) ASSERT(assertion)

#define NO_RETURN_DUE_TO_ASSERT NO_RETURN_DUE_TO_CRASH

#else

#define ASSERT(assertion) ((void)0)
#define ASSERT_AT(assertion, file, line, function) ((void)0)
#define ASSERT_NOT_REACHED() ((void)0)
#define NO_RETURN_DUE_TO_ASSERT

#define ASSERT_UNUSED(variable, assertion) ((void)variable)

#endif

/* ASSERT_WITH_SECURITY_IMPLICATION / RELEASE_ASSERT_WITH_SECURITY_IMPLICATION

   Use in places where failure of the assertion indicates a possible security
   vulnerability. Classes of these vulnerabilities include bad casts, out of
   bounds accesses, use-after-frees, etc. Please be sure to file bugs for these
   failures using the security template:
      http://code.google.com/p/chromium/issues/entry?template=Security%20Bug
*/
#ifdef ADDRESS_SANITIZER

#define ASSERT_WITH_SECURITY_IMPLICATION(assertion)                            \
  (!(assertion) ? (WTFReportAssertionFailure(__FILE__, __LINE__,               \
                                             WTF_PRETTY_FUNCTION, #assertion), \
                   CRASH())                                                    \
                : (void)0)

#define RELEASE_ASSERT_WITH_SECURITY_IMPLICATION(assertion) \
  ASSERT_WITH_SECURITY_IMPLICATION(assertion)

#else

#define ASSERT_WITH_SECURITY_IMPLICATION(assertion) ASSERT(assertion)
#define RELEASE_ASSERT_WITH_SECURITY_IMPLICATION(assertion) \
  RELEASE_ASSERT(assertion)

#endif

// Users must test "#if ENABLE(SECURITY_ASSERT)", which helps ensure
// that code testing this macro has included this header.
#if defined(ADDRESS_SANITIZER) || ENABLE(ASSERT)
#define ENABLE_SECURITY_ASSERT 1
#else
#define ENABLE_SECURITY_ASSERT 0
#endif

/* ASSERT_WITH_MESSAGE */

#if ASSERT_MSG_DISABLED
#define ASSERT_WITH_MESSAGE(assertion, ...) ((void)0)
#else
#define ASSERT_WITH_MESSAGE(assertion, ...)                                  \
  do                                                                         \
    if (!(assertion)) {                                                      \
      WTFReportAssertionFailureWithMessage(                                  \
          __FILE__, __LINE__, WTF_PRETTY_FUNCTION, #assertion, __VA_ARGS__); \
      CRASH();                                                               \
    }                                                                        \
  while (0)
#endif

/* ASSERT_WITH_MESSAGE_UNUSED */

#if ASSERT_MSG_DISABLED
#define ASSERT_WITH_MESSAGE_UNUSED(variable, assertion, ...) ((void)variable)
#else
#define ASSERT_WITH_MESSAGE_UNUSED(variable, assertion, ...)                 \
  do                                                                         \
    if (!(assertion)) {                                                      \
      WTFReportAssertionFailureWithMessage(                                  \
          __FILE__, __LINE__, WTF_PRETTY_FUNCTION, #assertion, __VA_ARGS__); \
      CRASH();                                                               \
    }                                                                        \
  while (0)
#endif

/* ASSERT_ARG */

#if ASSERT_ARG_DISABLED

#define ASSERT_ARG(argName, assertion) ((void)0)

#else

#define ASSERT_ARG(argName, assertion)                                    \
  do                                                                      \
    if (!(assertion)) {                                                   \
      WTFReportArgumentAssertionFailure(                                  \
          __FILE__, __LINE__, WTF_PRETTY_FUNCTION, #argName, #assertion); \
      CRASH();                                                            \
    }                                                                     \
  while (0)

#endif

/* COMPILE_ASSERT */
#ifndef COMPILE_ASSERT
#define COMPILE_ASSERT(exp, name) static_assert((exp), #name)
#endif

/* FATAL */

#if FATAL_DISABLED
#define FATAL(...) ((void)0)
#else
#define FATAL(...)                                                             \
  do {                                                                         \
    WTFReportFatalError(__FILE__, __LINE__, WTF_PRETTY_FUNCTION, __VA_ARGS__); \
    CRASH();                                                                   \
  } while (0)
#endif

/* WTF_LOG_ERROR */

#if ERROR_DISABLED
#define WTF_LOG_ERROR(...) ((void)0)
#else
#define WTF_LOG_ERROR(...) \
  WTFReportError(__FILE__, __LINE__, WTF_PRETTY_FUNCTION, __VA_ARGS__)
#endif

/* WTF_LOG */

#if LOG_DISABLED
#define WTF_LOG(channel, ...) ((void)0)
#else
#define WTF_LOG(channel, ...)                                        \
  WTFLog(&JOIN_LOG_CHANNEL_WITH_PREFIX(LOG_CHANNEL_PREFIX, channel), \
         __VA_ARGS__)
#define JOIN_LOG_CHANNEL_WITH_PREFIX(prefix, channel) \
  JOIN_LOG_CHANNEL_WITH_PREFIX_LEVEL_2(prefix, channel)
#define JOIN_LOG_CHANNEL_WITH_PREFIX_LEVEL_2(prefix, channel) prefix##channel
#endif

/* UNREACHABLE_FOR_PLATFORM */

#if COMPILER(CLANG)
/* This would be a macro except that its use of #pragma works best around
   a function. Hence it uses macro naming convention. */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmissing-noreturn"
static inline void UNREACHABLE_FOR_PLATFORM() {
  ASSERT_NOT_REACHED();
}
#pragma clang diagnostic pop
#else
#define UNREACHABLE_FOR_PLATFORM() ASSERT_NOT_REACHED()
#endif

/* RELEASE_ASSERT

   Use in places where failure of an assertion indicates a definite security
   vulnerability from which execution must not continue even in a release build.
   Please sure to file bugs for these failures using the security template:
      http://code.google.com/p/chromium/issues/entry?template=Security%20Bug
*/

#if ENABLE(ASSERT)
#define RELEASE_ASSERT(assertion) ASSERT(assertion)
#define RELEASE_ASSERT_WITH_MESSAGE(assertion, ...) \
  ASSERT_WITH_MESSAGE(assertion, __VA_ARGS__)
#define RELEASE_ASSERT_NOT_REACHED() ASSERT_NOT_REACHED()
#else
#define RELEASE_ASSERT(assertion) \
  (UNLIKELY(!(assertion)) ? (IMMEDIATE_CRASH()) : (void)0)
#define RELEASE_ASSERT_WITH_MESSAGE(assertion, ...) RELEASE_ASSERT(assertion)
#define RELEASE_ASSERT_NOT_REACHED() IMMEDIATE_CRASH()
#endif

/* DEFINE_COMPARISON_OPERATORS_WITH_REFERENCES */

// Allow equality comparisons of Objects by reference or pointer,
// interchangeably. This can be only used on types whose equality makes no other
// sense than pointer equality.
#define DEFINE_COMPARISON_OPERATORS_WITH_REFERENCES(thisType)    \
  inline bool operator==(const thisType& a, const thisType& b) { \
    return &a == &b;                                             \
  }                                                              \
  inline bool operator==(const thisType& a, const thisType* b) { \
    return &a == b;                                              \
  }                                                              \
  inline bool operator==(const thisType* a, const thisType& b) { \
    return a == &b;                                              \
  }                                                              \
  inline bool operator!=(const thisType& a, const thisType& b) { \
    return !(a == b);                                            \
  }                                                              \
  inline bool operator!=(const thisType& a, const thisType* b) { \
    return !(a == b);                                            \
  }                                                              \
  inline bool operator!=(const thisType* a, const thisType& b) { \
    return !(a == b);                                            \
  }

#define DEFINE_COMPARISON_OPERATORS_WITH_REFERENCES_REFCOUNTED(thisType)     \
  DEFINE_COMPARISON_OPERATORS_WITH_REFERENCES(thisType)                      \
  inline bool operator==(const PassRefPtr<thisType>& a, const thisType& b) { \
    return a.get() == &b;                                                    \
  }                                                                          \
  inline bool operator==(const thisType& a, const PassRefPtr<thisType>& b) { \
    return &a == b.get();                                                    \
  }                                                                          \
  inline bool operator!=(const PassRefPtr<thisType>& a, const thisType& b) { \
    return !(a == b);                                                        \
  }                                                                          \
  inline bool operator!=(const thisType& a, const PassRefPtr<thisType>& b) { \
    return !(a == b);                                                        \
  }

/* DEFINE_TYPE_CASTS */

#define DEFINE_TYPE_CASTS(thisType, argumentType, argumentName,            \
                          pointerPredicate, referencePredicate)            \
  inline thisType* to##thisType(argumentType* argumentName) {              \
    ASSERT_WITH_SECURITY_IMPLICATION(!argumentName || (pointerPredicate)); \
    return static_cast<thisType*>(argumentName);                           \
  }                                                                        \
  inline const thisType* to##thisType(const argumentType* argumentName) {  \
    ASSERT_WITH_SECURITY_IMPLICATION(!argumentName || (pointerPredicate)); \
    return static_cast<const thisType*>(argumentName);                     \
  }                                                                        \
  inline thisType& to##thisType(argumentType& argumentName) {              \
    ASSERT_WITH_SECURITY_IMPLICATION(referencePredicate);                  \
    return static_cast<thisType&>(argumentName);                           \
  }                                                                        \
  inline const thisType& to##thisType(const argumentType& argumentName) {  \
    ASSERT_WITH_SECURITY_IMPLICATION(referencePredicate);                  \
    return static_cast<const thisType&>(argumentName);                     \
  }                                                                        \
  void to##thisType(const thisType*);                                      \
  void to##thisType(const thisType&)

#endif  // SKY_ENGINE_WTF_ASSERTIONS_H_

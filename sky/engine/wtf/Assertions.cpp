/*
 * Copyright (C) 2003, 2006, 2007 Apple Inc.  All rights reserved.
 * Copyright (C) 2007-2009 Torch Mobile, Inc.
 * Copyright (C) 2011 University of Szeged. All rights reserved.
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

// The vprintf_stderr_common function triggers this error in the Mac build.
// Feel free to remove this pragma if this file builds on Mac.
// According to
// http://gcc.gnu.org/onlinedocs/gcc-4.2.1/gcc/Diagnostic-Pragmas.html#Diagnostic-Pragmas
// we need to place this directive before any data or functions are defined.
#pragma GCC diagnostic ignored "-Wmissing-format-attribute"

#include "flutter/sky/engine/wtf/Assertions.h"

#include "flutter/glue/stack_trace.h"
#include "flutter/sky/engine/wtf/Compiler.h"
#include "flutter/sky/engine/wtf/OwnPtr.h"
#include "flutter/sky/engine/wtf/PassOwnPtr.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if HAVE(SIGNAL_H)
#include <signal.h>
#endif

#if (OS(LINUX) && !defined(__UCLIBC__) && !defined(FNL_MUSL))
#include <cxxabi.h>
#include <dlfcn.h>
#include <execinfo.h>
#endif

#if OS(ANDROID)
#include <android/log.h>
#endif

extern "C" {

WTF_ATTRIBUTE_PRINTF(1, 0)
static void vprintf_stderr_common(const char* format, va_list args) {
#if OS(ANDROID)
  __android_log_vprint(ANDROID_LOG_WARN, "flutter", format, args);
#else
  vfprintf(stderr, format, args);
#endif
}

#if COMPILER(CLANG) || COMPILER(GCC)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wformat-nonliteral"
#endif

static void vprintf_stderr_with_prefix(const char* prefix,
                                       const char* format,
                                       va_list args) {
  size_t prefixLength = strlen(prefix);
  size_t formatLength = strlen(format);
  OwnPtr<char[]> formatWithPrefix =
      adoptArrayPtr(new char[prefixLength + formatLength + 1]);
  memcpy(formatWithPrefix.get(), prefix, prefixLength);
  memcpy(formatWithPrefix.get() + prefixLength, format, formatLength);
  formatWithPrefix[prefixLength + formatLength] = 0;

  vprintf_stderr_common(formatWithPrefix.get(), args);
}

static void vprintf_stderr_with_trailing_newline(const char* format,
                                                 va_list args) {
  size_t formatLength = strlen(format);
  if (formatLength && format[formatLength - 1] == '\n') {
    vprintf_stderr_common(format, args);
    return;
  }

  OwnPtr<char[]> formatWithNewline = adoptArrayPtr(new char[formatLength + 2]);
  memcpy(formatWithNewline.get(), format, formatLength);
  formatWithNewline[formatLength] = '\n';
  formatWithNewline[formatLength + 1] = 0;

  vprintf_stderr_common(formatWithNewline.get(), args);
}

#if COMPILER(CLANG) || COMPILER(GCC)
#pragma GCC diagnostic pop
#endif

WTF_ATTRIBUTE_PRINTF(1, 2)
static void printf_stderr_common(const char* format, ...) {
  va_list args;
  va_start(args, format);
  vprintf_stderr_common(format, args);
  va_end(args);
}

static void printCallSite(const char* file, int line, const char* function) {
  // By using this format, which matches the format used by MSVC for compiler
  // errors, developers using Visual Studio can double-click the file/line
  // number in the Output Window to have the editor navigate to that line of
  // code. It seems fine for other developers, too.
  printf_stderr_common("%s(%d) : %s\n", file, line, function);
}

void WTFReportAssertionFailure(const char* file,
                               int line,
                               const char* function,
                               const char* assertion) {
  if (assertion)
    printf_stderr_common("ASSERTION FAILED: %s\n", assertion);
  else
    printf_stderr_common("SHOULD NEVER BE REACHED\n");
  printCallSite(file, line, function);
}

void WTFReportAssertionFailureWithMessage(const char* file,
                                          int line,
                                          const char* function,
                                          const char* assertion,
                                          const char* format,
                                          ...) {
  va_list args;
  va_start(args, format);
  vprintf_stderr_with_prefix("ASSERTION FAILED: ", format, args);
  va_end(args);
  printf_stderr_common("\n%s\n", assertion);
  printCallSite(file, line, function);
}

void WTFReportArgumentAssertionFailure(const char* file,
                                       int line,
                                       const char* function,
                                       const char* argName,
                                       const char* assertion) {
  printf_stderr_common("ARGUMENT BAD: %s, %s\n", argName, assertion);
  printCallSite(file, line, function);
}

void WTFReportBacktrace() {
  glue::PrintStackTrace();
}

void WTFReportFatalError(const char* file,
                         int line,
                         const char* function,
                         const char* format,
                         ...) {
  va_list args;
  va_start(args, format);
  vprintf_stderr_with_prefix("FATAL ERROR: ", format, args);
  va_end(args);
  printf_stderr_common("\n");
  printCallSite(file, line, function);
}

void WTFReportError(const char* file,
                    int line,
                    const char* function,
                    const char* format,
                    ...) {
  va_list args;
  va_start(args, format);
  vprintf_stderr_with_prefix("ERROR: ", format, args);
  va_end(args);
  printf_stderr_common("\n");
  printCallSite(file, line, function);
}

void WTFLog(WTFLogChannel* channel, const char* format, ...) {
  if (channel->state != WTFLogChannelOn)
    return;

  va_list args;
  va_start(args, format);
  vprintf_stderr_with_trailing_newline(format, args);
  va_end(args);
}

void WTFLogVerbose(const char* file,
                   int line,
                   const char* function,
                   WTFLogChannel* channel,
                   const char* format,
                   ...) {
  if (channel->state != WTFLogChannelOn)
    return;

  va_list args;
  va_start(args, format);
  vprintf_stderr_with_trailing_newline(format, args);
  va_end(args);

  printCallSite(file, line, function);
}

void WTFLogAlways(const char* format, ...) {
  va_list args;
  va_start(args, format);
  vprintf_stderr_with_trailing_newline(format, args);
  va_end(args);
}

}  // extern "C"

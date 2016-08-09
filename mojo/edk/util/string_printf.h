// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// |printf()|-like formatting functions that output/append to C++ strings.
//
// TODO(vtl): We don't have the |PRINTF_FORMAT()| macros/warnings like
// Chromium's version -- should we? (I've rarely seen them being useful.)

#ifndef MOJO_EDK_UTIL_STRING_PRINTF_H_
#define MOJO_EDK_UTIL_STRING_PRINTF_H_

#include <stdarg.h>

#include <string>

#include "mojo/public/c/system/macros.h"

namespace mojo {
namespace util {

// Formats |printf()|-like input and returns it as an |std::string|.
std::string StringPrintf(const char* format, ...) MOJO_WARN_UNUSED_RESULT;

// Formats |vprintf()|-like input and returns it as an |std::string|.
std::string StringVPrintf(const char* format,
                          va_list ap) MOJO_WARN_UNUSED_RESULT;

// Formats |printf()|-like input and appends it to |*dest|.
void StringAppendf(std::string* dest, const char* format, ...);

// Formats |vprintf()|-like input and appends it to |*dest|.
void StringVAppendf(std::string* dest, const char* format, va_list ap);

}  // namespace util
}  // namespace mojo

#endif  // MOJO_EDK_UTIL_STRING_PRINTF_H_

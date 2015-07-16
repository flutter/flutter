// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "build/build_config.h"

#if defined(COMPILER_MSVC)
#include <intrin.h>
#endif

#include "base/location.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/stringprintf.h"

namespace tracked_objects {

Location::Location(const char* function_name,
                   const char* file_name,
                   int line_number,
                   const void* program_counter)
    : function_name_(function_name),
      file_name_(file_name),
      line_number_(line_number),
      program_counter_(program_counter) {
}

Location::Location()
    : function_name_("Unknown"),
      file_name_("Unknown"),
      line_number_(-1),
      program_counter_(NULL) {
}

Location::Location(const Location& other)
    : function_name_(other.function_name_),
      file_name_(other.file_name_),
      line_number_(other.line_number_),
      program_counter_(other.program_counter_) {
}

std::string Location::ToString() const {
  return std::string(function_name_) + "@" + file_name_ + ":" +
      base::IntToString(line_number_);
}

void Location::Write(bool display_filename, bool display_function_name,
                     std::string* output) const {
  base::StringAppendF(output, "%s[%d] ",
      display_filename ? file_name_ : "line",
      line_number_);

  if (display_function_name) {
    WriteFunctionName(output);
    output->push_back(' ');
  }
}

void Location::WriteFunctionName(std::string* output) const {
  // Translate "<" to "&lt;" for HTML safety.
  // TODO(jar): Support ASCII or html for logging in ASCII.
  for (const char *p = function_name_; *p; p++) {
    switch (*p) {
      case '<':
        output->append("&lt;");
        break;

      case '>':
        output->append("&gt;");
        break;

      default:
        output->push_back(*p);
        break;
    }
  }
}

//------------------------------------------------------------------------------
LocationSnapshot::LocationSnapshot() : line_number(-1) {
}

LocationSnapshot::LocationSnapshot(
    const tracked_objects::Location& location)
    : file_name(location.file_name()),
      function_name(location.function_name()),
      line_number(location.line_number()) {
}

LocationSnapshot::~LocationSnapshot() {
}

//------------------------------------------------------------------------------
#if defined(COMPILER_MSVC)
__declspec(noinline)
#endif
BASE_EXPORT const void* GetProgramCounter() {
#if defined(COMPILER_MSVC)
  return _ReturnAddress();
#elif defined(COMPILER_GCC) && !defined(OS_NACL)
  return __builtin_extract_return_addr(__builtin_return_address(0));
#else
  return NULL;
#endif
}

}  // namespace tracked_objects

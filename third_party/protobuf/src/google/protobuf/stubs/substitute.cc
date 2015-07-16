// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
// http://code.google.com/p/protobuf/
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// Author: kenton@google.com (Kenton Varda)

#include <google/protobuf/stubs/substitute.h>
#include <google/protobuf/stubs/strutil.h>
#include <google/protobuf/stubs/stl_util.h>

namespace google {
namespace protobuf {
namespace strings {

using internal::SubstituteArg;

// Returns the number of args in arg_array which were passed explicitly
// to Substitute().
static int CountSubstituteArgs(const SubstituteArg* const* args_array) {
  int count = 0;
  while (args_array[count] != NULL && args_array[count]->size() != -1) {
    ++count;
  }
  return count;
}

string Substitute(
    const char* format,
    const SubstituteArg& arg0, const SubstituteArg& arg1,
    const SubstituteArg& arg2, const SubstituteArg& arg3,
    const SubstituteArg& arg4, const SubstituteArg& arg5,
    const SubstituteArg& arg6, const SubstituteArg& arg7,
    const SubstituteArg& arg8, const SubstituteArg& arg9) {
  string result;
  SubstituteAndAppend(&result, format, arg0, arg1, arg2, arg3, arg4,
                                       arg5, arg6, arg7, arg8, arg9);
  return result;
}

void SubstituteAndAppend(
    string* output, const char* format,
    const SubstituteArg& arg0, const SubstituteArg& arg1,
    const SubstituteArg& arg2, const SubstituteArg& arg3,
    const SubstituteArg& arg4, const SubstituteArg& arg5,
    const SubstituteArg& arg6, const SubstituteArg& arg7,
    const SubstituteArg& arg8, const SubstituteArg& arg9) {
  const SubstituteArg* const args_array[] = {
    &arg0, &arg1, &arg2, &arg3, &arg4, &arg5, &arg6, &arg7, &arg8, &arg9, NULL
  };

  // Determine total size needed.
  int size = 0;
  for (int i = 0; format[i] != '\0'; i++) {
    if (format[i] == '$') {
      if (ascii_isdigit(format[i+1])) {
        int index = format[i+1] - '0';
        if (args_array[index]->size() == -1) {
          GOOGLE_LOG(DFATAL)
            << "strings::Substitute format string invalid: asked for \"$"
            << index << "\", but only " << CountSubstituteArgs(args_array)
            << " args were given.  Full format string was: \""
            << CEscape(format) << "\".";
          return;
        }
        size += args_array[index]->size();
        ++i;  // Skip next char.
      } else if (format[i+1] == '$') {
        ++size;
        ++i;  // Skip next char.
      } else {
        GOOGLE_LOG(DFATAL)
          << "Invalid strings::Substitute() format string: \""
          << CEscape(format) << "\".";
        return;
      }
    } else {
      ++size;
    }
  }

  if (size == 0) return;

  // Build the string.
  int original_size = output->size();
  STLStringResizeUninitialized(output, original_size + size);
  char* target = string_as_array(output) + original_size;
  for (int i = 0; format[i] != '\0'; i++) {
    if (format[i] == '$') {
      if (ascii_isdigit(format[i+1])) {
        const SubstituteArg* src = args_array[format[i+1] - '0'];
        memcpy(target, src->data(), src->size());
        target += src->size();
        ++i;  // Skip next char.
      } else if (format[i+1] == '$') {
        *target++ = '$';
        ++i;  // Skip next char.
      }
    } else {
      *target++ = format[i];
    }
  }

  GOOGLE_DCHECK_EQ(target - output->data(), output->size());
}

}  // namespace strings
}  // namespace protobuf
}  // namespace google

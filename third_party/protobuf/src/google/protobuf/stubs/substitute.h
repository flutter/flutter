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
// from google3/strings/substitute.h

#include <string>
#include <google/protobuf/stubs/common.h>
#include <google/protobuf/stubs/strutil.h>

#ifndef GOOGLE_PROTOBUF_STUBS_SUBSTITUTE_H_
#define GOOGLE_PROTOBUF_STUBS_SUBSTITUTE_H_

namespace google {
namespace protobuf {
namespace strings {

// ----------------------------------------------------------------------
// strings::Substitute()
// strings::SubstituteAndAppend()
//   Kind of like StringPrintf, but different.
//
//   Example:
//     string GetMessage(string first_name, string last_name, int age) {
//       return strings::Substitute("My name is $0 $1 and I am $2 years old.",
//                                  first_name, last_name, age);
//     }
//
//   Differences from StringPrintf:
//   * The format string does not identify the types of arguments.
//     Instead, the magic of C++ deals with this for us.  See below
//     for a list of accepted types.
//   * Substitutions in the format string are identified by a '$'
//     followed by a digit.  So, you can use arguments out-of-order and
//     use the same argument multiple times.
//   * It's much faster than StringPrintf.
//
//   Supported types:
//   * Strings (const char*, const string&)
//     * Note that this means you do not have to add .c_str() to all of
//       your strings.  In fact, you shouldn't; it will be slower.
//   * int32, int64, uint32, uint64:  Formatted using SimpleItoa().
//   * float, double:  Formatted using SimpleFtoa() and SimpleDtoa().
//   * bool:  Printed as "true" or "false".
//
//   SubstituteAndAppend() is like Substitute() but appends the result to
//   *output.  Example:
//
//     string str;
//     strings::SubstituteAndAppend(&str,
//                                  "My name is $0 $1 and I am $2 years old.",
//                                  first_name, last_name, age);
//
//   Substitute() is significantly faster than StringPrintf().  For very
//   large strings, it may be orders of magnitude faster.
// ----------------------------------------------------------------------

namespace internal {  // Implementation details.

class SubstituteArg {
 public:
  inline SubstituteArg(const char* value)
    : text_(value), size_(strlen(text_)) {}
  inline SubstituteArg(const string& value)
    : text_(value.data()), size_(value.size()) {}

  // Indicates that no argument was given.
  inline explicit SubstituteArg()
    : text_(NULL), size_(-1) {}

  // Primitives
  // We don't overload for signed and unsigned char because if people are
  // explicitly declaring their chars as signed or unsigned then they are
  // probably actually using them as 8-bit integers and would probably
  // prefer an integer representation.  But, we don't really know.  So, we
  // make the caller decide what to do.
  inline SubstituteArg(char value)
    : text_(scratch_), size_(1) { scratch_[0] = value; }
  inline SubstituteArg(short value)
    : text_(FastInt32ToBuffer(value, scratch_)), size_(strlen(text_)) {}
  inline SubstituteArg(unsigned short value)
    : text_(FastUInt32ToBuffer(value, scratch_)), size_(strlen(text_)) {}
  inline SubstituteArg(int value)
    : text_(FastInt32ToBuffer(value, scratch_)), size_(strlen(text_)) {}
  inline SubstituteArg(unsigned int value)
    : text_(FastUInt32ToBuffer(value, scratch_)), size_(strlen(text_)) {}
  inline SubstituteArg(long value)
    : text_(FastLongToBuffer(value, scratch_)), size_(strlen(text_)) {}
  inline SubstituteArg(unsigned long value)
    : text_(FastULongToBuffer(value, scratch_)), size_(strlen(text_)) {}
  inline SubstituteArg(long long value)
    : text_(FastInt64ToBuffer(value, scratch_)), size_(strlen(text_)) {}
  inline SubstituteArg(unsigned long long value)
    : text_(FastUInt64ToBuffer(value, scratch_)), size_(strlen(text_)) {}
  inline SubstituteArg(float value)
    : text_(FloatToBuffer(value, scratch_)), size_(strlen(text_)) {}
  inline SubstituteArg(double value)
    : text_(DoubleToBuffer(value, scratch_)), size_(strlen(text_)) {}
  inline SubstituteArg(bool value)
    : text_(value ? "true" : "false"), size_(strlen(text_)) {}

  inline const char* data() const { return text_; }
  inline int size() const { return size_; }

 private:
  const char* text_;
  int size_;
  char scratch_[kFastToBufferSize];
};

}  // namespace internal

LIBPROTOBUF_EXPORT string Substitute(
  const char* format,
  const internal::SubstituteArg& arg0 = internal::SubstituteArg(),
  const internal::SubstituteArg& arg1 = internal::SubstituteArg(),
  const internal::SubstituteArg& arg2 = internal::SubstituteArg(),
  const internal::SubstituteArg& arg3 = internal::SubstituteArg(),
  const internal::SubstituteArg& arg4 = internal::SubstituteArg(),
  const internal::SubstituteArg& arg5 = internal::SubstituteArg(),
  const internal::SubstituteArg& arg6 = internal::SubstituteArg(),
  const internal::SubstituteArg& arg7 = internal::SubstituteArg(),
  const internal::SubstituteArg& arg8 = internal::SubstituteArg(),
  const internal::SubstituteArg& arg9 = internal::SubstituteArg());

LIBPROTOBUF_EXPORT void SubstituteAndAppend(
  string* output, const char* format,
  const internal::SubstituteArg& arg0 = internal::SubstituteArg(),
  const internal::SubstituteArg& arg1 = internal::SubstituteArg(),
  const internal::SubstituteArg& arg2 = internal::SubstituteArg(),
  const internal::SubstituteArg& arg3 = internal::SubstituteArg(),
  const internal::SubstituteArg& arg4 = internal::SubstituteArg(),
  const internal::SubstituteArg& arg5 = internal::SubstituteArg(),
  const internal::SubstituteArg& arg6 = internal::SubstituteArg(),
  const internal::SubstituteArg& arg7 = internal::SubstituteArg(),
  const internal::SubstituteArg& arg8 = internal::SubstituteArg(),
  const internal::SubstituteArg& arg9 = internal::SubstituteArg());

}  // namespace strings
}  // namespace protobuf
}  // namespace google

#endif // GOOGLE_PROTOBUF_STUBS_SUBSTITUTE_H_

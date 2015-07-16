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
//  Based on original Protocol Buffers design by
//  Sanjay Ghemawat, Jeff Dean, and others.
//
// This file contains miscellaneous helper code used by generated code --
// including lite types -- but which should not be used directly by users.

#ifndef GOOGLE_PROTOBUF_GENERATED_MESSAGE_UTIL_H__
#define GOOGLE_PROTOBUF_GENERATED_MESSAGE_UTIL_H__

#include <string>

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/stubs/once.h>
namespace google {
namespace protobuf {
namespace internal {

// Annotation for the compiler to emit a deprecation message if a field marked
// with option 'deprecated=true' is used in the code, or for other things in
// generated code which are deprecated.
//
// For internal use in the pb.cc files, deprecation warnings are suppressed
// there.
#undef DEPRECATED_PROTOBUF_FIELD
#define PROTOBUF_DEPRECATED


// Constants for special floating point values.
LIBPROTOBUF_EXPORT double Infinity();
LIBPROTOBUF_EXPORT double NaN();

// Default empty string object. Don't use the pointer directly. Instead, call
// GetEmptyString() to get the reference.
LIBPROTOBUF_EXPORT extern const ::std::string* empty_string_;
LIBPROTOBUF_EXPORT extern ProtobufOnceType empty_string_once_init_;

LIBPROTOBUF_EXPORT void InitEmptyString();

LIBPROTOBUF_EXPORT const ::std::string& GetEmptyString();

// Defined in generated_message_reflection.cc -- not actually part of the lite
// library.
//
// TODO(jasonh): The various callers get this declaration from a variety of
// places: probably in most cases repeated_field.h. Clean these up so they all
// get the declaration from this file.
LIBPROTOBUF_EXPORT int StringSpaceUsedExcludingSelf(const string& str);

}  // namespace internal
}  // namespace protobuf

}  // namespace google
#endif  // GOOGLE_PROTOBUF_GENERATED_MESSAGE_UTIL_H__

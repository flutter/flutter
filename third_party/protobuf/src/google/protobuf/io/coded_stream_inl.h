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

// Author: jasonh@google.com (Jason Hsueh)
//
// Implements methods of coded_stream.h that need to be inlined for performance
// reasons, but should not be defined in a public header.

#ifndef GOOGLE_PROTOBUF_IO_CODED_STREAM_INL_H__
#define GOOGLE_PROTOBUF_IO_CODED_STREAM_INL_H__

#include <google/protobuf/io/coded_stream.h>
#include <string>
#include <google/protobuf/stubs/stl_util.h>

namespace google {
namespace protobuf {
namespace io {

inline bool CodedInputStream::InternalReadStringInline(string* buffer,
                                                       int size) {
  if (size < 0) return false;  // security: size is often user-supplied

  if (BufferSize() >= size) {
    STLStringResizeUninitialized(buffer, size);
    // When buffer is empty, string_as_array(buffer) will return NULL but memcpy
    // requires non-NULL pointers even when size is 0. Hench this check.
    if (size > 0) {
      memcpy(string_as_array(buffer), buffer_, size);
      Advance(size);
    }
    return true;
  }

  return ReadStringFallback(buffer, size);
}

}  // namespace io
}  // namespace protobuf
}  // namespace google
#endif  // GOOGLE_PROTOBUF_IO_CODED_STREAM_INL_H__

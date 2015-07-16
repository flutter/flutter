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
// emulates google3/file/base/file.h

#ifndef GOOGLE_PROTOBUF_TESTING_FILE_H__
#define GOOGLE_PROTOBUF_TESTING_FILE_H__

#include <google/protobuf/stubs/common.h>

namespace google {
namespace protobuf {

const int DEFAULT_FILE_MODE = 0777;

// Protocol buffer code only uses a couple static methods of File, and only
// in tests.
class File {
 public:
  // Check if the file exists.
  static bool Exists(const string& name);

  // Read an entire file to a string.  Return true if successful, false
  // otherwise.
  static bool ReadFileToString(const string& name, string* output);

  // Same as above, but crash on failure.
  static void ReadFileToStringOrDie(const string& name, string* output);

  // Create a file and write a string to it.
  static void WriteStringToFileOrDie(const string& contents,
                                     const string& name);

  // Create a directory.
  static bool CreateDir(const string& name, int mode);

  // Create a directory and all parent directories if necessary.
  static bool RecursivelyCreateDir(const string& path, int mode);

  // If "name" is a file, we delete it.  If it is a directory, we
  // call DeleteRecursively() for each file or directory (other than
  // dot and double-dot) within it, and then delete the directory itself.
  // The "dummy" parameters have a meaning in the original version of this
  // method but they are not used anywhere in protocol buffers.
  static void DeleteRecursively(const string& name,
                                void* dummy1, void* dummy2);

 private:
  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(File);
};

}  // namespace protobuf
}  // namespace google

#endif  // GOOGLE_PROTOBUF_TESTING_FILE_H__

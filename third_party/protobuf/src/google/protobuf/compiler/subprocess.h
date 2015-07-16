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

#ifndef GOOGLE_PROTOBUF_COMPILER_SUBPROCESS_H__
#define GOOGLE_PROTOBUF_COMPILER_SUBPROCESS_H__

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN   // right...
#include <windows.h>
#else  // _WIN32
#include <sys/types.h>
#include <unistd.h>
#endif  // !_WIN32
#include <google/protobuf/stubs/common.h>

#include <string>


namespace google {
namespace protobuf {

class Message;

namespace compiler {

// Utility class for launching sub-processes.
class Subprocess {
 public:
  Subprocess();
  ~Subprocess();

  enum SearchMode {
    SEARCH_PATH,   // Use PATH environment variable.
    EXACT_NAME     // Program is an exact file name; don't use the PATH.
  };

  // Start the subprocess.  Currently we don't provide a way to specify
  // arguments as protoc plugins don't have any.
  void Start(const string& program, SearchMode search_mode);

  // Serialize the input message and pipe it to the subprocess's stdin, then
  // close the pipe.  Meanwhile, read from the subprocess's stdout and parse
  // the data into *output.  All this is done carefully to avoid deadlocks.
  // Returns true if successful.  On any sort of error, returns false and sets
  // *error to a description of the problem.
  bool Communicate(const Message& input, Message* output, string* error);

#ifdef _WIN32
  // Given an error code, returns a human-readable error message.  This is
  // defined here so that CommandLineInterface can share it.
  static string Win32ErrorMessage(DWORD error_code);
#endif

 private:
#ifdef _WIN32
  DWORD process_start_error_;
  HANDLE child_handle_;

  // The file handles for our end of the child's pipes.  We close each and
  // set it to NULL when no longer needed.
  HANDLE child_stdin_;
  HANDLE child_stdout_;

#else  // _WIN32
  pid_t child_pid_;

  // The file descriptors for our end of the child's pipes.  We close each and
  // set it to -1 when no longer needed.
  int child_stdin_;
  int child_stdout_;

#endif  // !_WIN32
};

}  // namespace compiler
}  // namespace protobuf

}  // namespace google
#endif  // GOOGLE_PROTOBUF_COMPILER_SUBPROCESS_H__

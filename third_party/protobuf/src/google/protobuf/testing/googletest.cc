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
// emulates google3/testing/base/public/googletest.cc

#include <google/protobuf/testing/googletest.h>
#include <google/protobuf/testing/file.h>
#include <google/protobuf/stubs/strutil.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>
#include <stdlib.h>
#ifdef _MSC_VER
#include <io.h>
#include <direct.h>
#else
#include <unistd.h>
#endif
#include <stdio.h>
#include <fcntl.h>
#include <iostream>
#include <fstream>

namespace google {
namespace protobuf {

#ifdef _WIN32
#define mkdir(name, mode) mkdir(name)
#endif

#ifndef O_BINARY
#ifdef _O_BINARY
#define O_BINARY _O_BINARY
#else
#define O_BINARY 0     // If this isn't defined, the platform doesn't need it.
#endif
#endif

string TestSourceDir() {
#ifdef _MSC_VER
  // Look for the "src" directory.
  string prefix = ".";

  while (!File::Exists(prefix + "/src/google/protobuf")) {
    if (!File::Exists(prefix)) {
      GOOGLE_LOG(FATAL)
        << "Could not find protobuf source code.  Please run tests from "
           "somewhere within the protobuf source package.";
    }
    prefix += "/..";
  }
  return prefix + "/src";
#else
  // automake sets the "srcdir" environment variable.
  char* result = getenv("srcdir");
  if (result == NULL) {
    // Otherwise, the test must be run from the source directory.
    return ".";
  } else {
    return result;
  }
#endif
}

namespace {

string GetTemporaryDirectoryName() {
  // tmpnam() is generally not considered safe but we're only using it for
  // testing.  We cannot use tmpfile() or mkstemp() since we're creating a
  // directory.
  char b[L_tmpnam + 1];     // HPUX multithread return 0 if s is 0
  string result = tmpnam(b);
#ifdef _WIN32
  // On Win32, tmpnam() returns a file prefixed with '\', but which is supposed
  // to be used in the current working directory.  WTF?
  if (HasPrefixString(result, "\\")) {
    result.erase(0, 1);
  }
#endif  // _WIN32
  return result;
}

// Creates a temporary directory on demand and deletes it when the process
// quits.
class TempDirDeleter {
 public:
  TempDirDeleter() {}
  ~TempDirDeleter() {
    if (!name_.empty()) {
      File::DeleteRecursively(name_, NULL, NULL);
    }
  }

  string GetTempDir() {
    if (name_.empty()) {
      name_ = GetTemporaryDirectoryName();
      GOOGLE_CHECK(mkdir(name_.c_str(), 0777) == 0) << strerror(errno);

      // Stick a file in the directory that tells people what this is, in case
      // we abort and don't get a chance to delete it.
      File::WriteStringToFileOrDie("", name_ + "/TEMP_DIR_FOR_PROTOBUF_TESTS");
    }
    return name_;
  }

 private:
  string name_;
};

TempDirDeleter temp_dir_deleter_;

}  // namespace

string TestTempDir() {
  return temp_dir_deleter_.GetTempDir();
}

// TODO(kenton):  Share duplicated code below.  Too busy/lazy for now.

static string stdout_capture_filename_;
static string stderr_capture_filename_;
static int original_stdout_ = -1;
static int original_stderr_ = -1;

void CaptureTestStdout() {
  GOOGLE_CHECK_EQ(original_stdout_, -1) << "Already capturing.";

  stdout_capture_filename_ = TestTempDir() + "/captured_stdout";

  int fd = open(stdout_capture_filename_.c_str(),
                O_WRONLY | O_CREAT | O_EXCL | O_BINARY, 0777);
  GOOGLE_CHECK(fd >= 0) << "open: " << strerror(errno);

  original_stdout_ = dup(1);
  close(1);
  dup2(fd, 1);
  close(fd);
}

void CaptureTestStderr() {
  GOOGLE_CHECK_EQ(original_stderr_, -1) << "Already capturing.";

  stderr_capture_filename_ = TestTempDir() + "/captured_stderr";

  int fd = open(stderr_capture_filename_.c_str(),
                O_WRONLY | O_CREAT | O_EXCL | O_BINARY, 0777);
  GOOGLE_CHECK(fd >= 0) << "open: " << strerror(errno);

  original_stderr_ = dup(2);
  close(2);
  dup2(fd, 2);
  close(fd);
}

string GetCapturedTestStdout() {
  GOOGLE_CHECK_NE(original_stdout_, -1) << "Not capturing.";

  close(1);
  dup2(original_stdout_, 1);
  original_stdout_ = -1;

  string result;
  File::ReadFileToStringOrDie(stdout_capture_filename_, &result);

  remove(stdout_capture_filename_.c_str());

  return result;
}

string GetCapturedTestStderr() {
  GOOGLE_CHECK_NE(original_stderr_, -1) << "Not capturing.";

  close(2);
  dup2(original_stderr_, 2);
  original_stderr_ = -1;

  string result;
  File::ReadFileToStringOrDie(stderr_capture_filename_, &result);

  remove(stderr_capture_filename_.c_str());

  return result;
}

ScopedMemoryLog* ScopedMemoryLog::active_log_ = NULL;

ScopedMemoryLog::ScopedMemoryLog() {
  GOOGLE_CHECK(active_log_ == NULL);
  active_log_ = this;
  old_handler_ = SetLogHandler(&HandleLog);
}

ScopedMemoryLog::~ScopedMemoryLog() {
  SetLogHandler(old_handler_);
  active_log_ = NULL;
}

const vector<string>& ScopedMemoryLog::GetMessages(LogLevel level) {
  GOOGLE_CHECK(level == ERROR ||
               level == WARNING);
  return messages_[level];
}

void ScopedMemoryLog::HandleLog(LogLevel level, const char* filename,
                                int line, const string& message) {
  GOOGLE_CHECK(active_log_ != NULL);
  if (level == ERROR || level == WARNING) {
    active_log_->messages_[level].push_back(message);
  }
}

namespace {

// Force shutdown at process exit so that we can test for memory leaks.  To
// actually check for leaks, I suggest using the heap checker included with
// google-perftools.  Set it to "draconian" mode to ensure that every last
// call to malloc() has a corresponding free().
struct ForceShutdown {
  ~ForceShutdown() {
    ShutdownProtobufLibrary();
  }
} force_shutdown;

}  // namespace

}  // namespace protobuf
}  // namespace google

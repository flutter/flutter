// Copyright (c) 2007, Google Inc.
// All rights reserved.
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

// ---
// This file just provides storage for FLAGS_verbose.

#include <config.h>
#include "base/logging.h"
#include "base/commandlineflags.h"

DEFINE_int32(verbose, EnvToInt("PERFTOOLS_VERBOSE", 0),
             "Set to numbers >0 for more verbose output, or <0 for less.  "
             "--verbose == -4 means we log fatal errors only.");


#if defined(_WIN32) || defined(__CYGWIN__) || defined(__CYGWIN32__)

// While windows does have a POSIX-compatible API
// (_open/_write/_close), it acquires memory.  Using this lower-level
// windows API is the closest we can get to being "raw".
RawFD RawOpenForWriting(const char* filename) {
  // CreateFile allocates memory if file_name isn't absolute, so if
  // that ever becomes a problem then we ought to compute the absolute
  // path on its behalf (perhaps the ntdll/kernel function isn't aware
  // of the working directory?)
  RawFD fd = CreateFileA(filename, GENERIC_WRITE, 0, NULL,
                         CREATE_ALWAYS, 0, NULL);
  if (fd != kIllegalRawFD && GetLastError() == ERROR_ALREADY_EXISTS)
    SetEndOfFile(fd);    // truncate the existing file
  return fd;
}

void RawWrite(RawFD handle, const char* buf, size_t len) {
  while (len > 0) {
    DWORD wrote;
    BOOL ok = WriteFile(handle, buf, len, &wrote, NULL);
    // We do not use an asynchronous file handle, so ok==false means an error
    if (!ok) break;
    buf += wrote;
    len -= wrote;
  }
}

void RawClose(RawFD handle) {
  CloseHandle(handle);
}

#else  // _WIN32 || __CYGWIN__ || __CYGWIN32__

#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif

// Re-run fn until it doesn't cause EINTR.
#define NO_INTR(fn)  do {} while ((fn) < 0 && errno == EINTR)

RawFD RawOpenForWriting(const char* filename) {
  return open(filename, O_WRONLY|O_CREAT|O_TRUNC, 0664);
}

void RawWrite(RawFD fd, const char* buf, size_t len) {
  while (len > 0) {
    ssize_t r;
    NO_INTR(r = write(fd, buf, len));
    if (r <= 0) break;
    buf += r;
    len -= r;
  }
}

void RawClose(RawFD fd) {
  NO_INTR(close(fd));
}

#endif  // _WIN32 || __CYGWIN__ || __CYGWIN32__

// Copyright (c) 2009, Google Inc.
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
// Author: Craig Silverstein
//
// This forks out to pprof to do the actual symbolizing.  We might
// be better off writing our own in C++.

#include "config.h"
#include "symbolize.h"
#include <stdlib.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>   // for write()
#endif
#ifdef HAVE_SYS_SOCKET_H
#include <sys/socket.h>   // for socketpair() -- needed by Symbolize
#endif
#ifdef HAVE_SYS_WAIT_H
#include <sys/wait.h>   // for wait() -- needed by Symbolize
#endif
#ifdef HAVE_POLL_H
#include <poll.h>
#endif
#ifdef __MACH__
#include <mach-o/dyld.h>   // for GetProgramInvocationName()
#include <limits.h>        // for PATH_MAX
#endif
#if defined(__CYGWIN__) || defined(__CYGWIN32__)
#include <io.h>            // for get_osfhandle()
#endif
#include <string>
#include "base/commandlineflags.h"
#include "base/logging.h"
#include "base/sysinfo.h"

using std::string;
using tcmalloc::DumpProcSelfMaps;   // from sysinfo.h


DEFINE_string(symbolize_pprof,
              EnvToString("PPROF_PATH", "pprof"),
              "Path to pprof to call for reporting function names.");

// Returns NULL if we're on an OS where we can't get the invocation name.
// Using a static var is ok because we're not called from a thread.
static char* GetProgramInvocationName() {
#if defined(HAVE_PROGRAM_INVOCATION_NAME)
  extern char* program_invocation_name;  // gcc provides this
  return program_invocation_name;
#elif defined(__MACH__)
  // We don't want to allocate memory for this since we may be
  // calculating it when memory is corrupted.
  static char program_invocation_name[PATH_MAX];
  if (program_invocation_name[0] == '\0') {  // first time calculating
    uint32_t length = sizeof(program_invocation_name);
    if (_NSGetExecutablePath(program_invocation_name, &length))
      return NULL;
  }
  return program_invocation_name;
#else
  return NULL;   // figure out a way to get argv[0]
#endif
}

// Prints an error message when you can't run Symbolize().
static void PrintError(const char* reason) {
  RAW_LOG(ERROR,
          "*** WARNING: Cannot convert addresses to symbols in output below.\n"
          "*** Reason: %s\n"
          "*** If you cannot fix this, try running pprof directly.\n",
          reason);
}

void SymbolTable::Add(const void* addr) {
  symbolization_table_[addr] = "";
}

const char* SymbolTable::GetSymbol(const void* addr) {
  return symbolization_table_[addr];
}

// Updates symbolization_table with the pointers to symbol names corresponding
// to its keys. The symbol names are stored in out, which is allocated and
// freed by the caller of this routine.
// Note that the forking/etc is not thread-safe or re-entrant.  That's
// ok for the purpose we need -- reporting leaks detected by heap-checker
// -- but be careful if you decide to use this routine for other purposes.
// Returns number of symbols read on error.  If can't symbolize, returns 0
// and emits an error message about why.
int SymbolTable::Symbolize() {
#if !defined(HAVE_UNISTD_H)  || !defined(HAVE_SYS_SOCKET_H) || !defined(HAVE_SYS_WAIT_H)
  PrintError("Perftools does not know how to call a sub-process on this O/S");
  return 0;
#else
  const char* argv0 = GetProgramInvocationName();
  if (argv0 == NULL) {  // can't call symbolize if we can't figure out our name
    PrintError("Cannot figure out the name of this executable (argv0)");
    return 0;
  }
  if (access(FLAGS_symbolize_pprof, R_OK) != 0) {
    PrintError("Cannot find 'pprof' (is PPROF_PATH set correctly?)");
    return 0;
  }

  // All this work is to do two-way communication.  ugh.
  int *child_in = NULL;   // file descriptors
  int *child_out = NULL;  // for now, we don't worry about child_err
  int child_fds[5][2];    // socketpair may be called up to five times below

  // The client program may close its stdin and/or stdout and/or stderr
  // thus allowing socketpair to reuse file descriptors 0, 1 or 2.
  // In this case the communication between the forked processes may be broken
  // if either the parent or the child tries to close or duplicate these
  // descriptors. The loop below produces two pairs of file descriptors, each
  // greater than 2 (stderr).
  for (int i = 0; i < 5; i++) {
    if (socketpair(AF_UNIX, SOCK_STREAM, 0, child_fds[i]) == -1) {
      for (int j = 0; j < i; j++) {
        close(child_fds[j][0]);
        close(child_fds[j][1]);
        PrintError("Cannot create a socket pair");
        return 0;
      }
    } else {
      if ((child_fds[i][0] > 2) && (child_fds[i][1] > 2)) {
        if (child_in == NULL) {
          child_in = child_fds[i];
        } else {
          child_out = child_fds[i];
          for (int j = 0; j < i; j++) {
            if (child_fds[j] == child_in) continue;
            close(child_fds[j][0]);
            close(child_fds[j][1]);
          }
          break;
        }
      }
    }
  }

  switch (fork()) {
    case -1: {  // error
      close(child_in[0]);
      close(child_in[1]);
      close(child_out[0]);
      close(child_out[1]);
      PrintError("Unknown error calling fork()");
      return 0;
    }
    case 0: {  // child
      close(child_in[1]);   // child uses the 0's, parent uses the 1's
      close(child_out[1]);  // child uses the 0's, parent uses the 1's
      close(0);
      close(1);
      if (dup2(child_in[0], 0) == -1) _exit(1);
      if (dup2(child_out[0], 1) == -1) _exit(2);
      // Unset vars that might cause trouble when we fork
      unsetenv("CPUPROFILE");
      unsetenv("HEAPPROFILE");
      unsetenv("HEAPCHECK");
      unsetenv("PERFTOOLS_VERBOSE");
      execlp(FLAGS_symbolize_pprof, FLAGS_symbolize_pprof,
             "--symbols", argv0, NULL);
      _exit(3);  // if execvp fails, it's bad news for us
    }
    default: {  // parent
      close(child_in[0]);   // child uses the 0's, parent uses the 1's
      close(child_out[0]);  // child uses the 0's, parent uses the 1's
#ifdef HAVE_POLL_H
      // Waiting for 1ms seems to give the OS time to notice any errors.
      poll(0, 0, 1);
      // For maximum safety, we check to make sure the execlp
      // succeeded before trying to write.  (Otherwise we'll get a
      // SIGPIPE.)  For systems without poll.h, we'll just skip this
      // check, and trust that the user set PPROF_PATH correctly!
      struct pollfd pfd = { child_in[1], POLLOUT, 0 };
      if (!poll(&pfd, 1, 0) || !(pfd.revents & POLLOUT) ||
          (pfd.revents & (POLLHUP|POLLERR))) {
        PrintError("Cannot run 'pprof' (is PPROF_PATH set correctly?)");
        return 0;
      }
#endif
#if defined(__CYGWIN__) || defined(__CYGWIN32__)
      // On cygwin, DumpProcSelfMaps() takes a HANDLE, not an fd.  Convert.
      const HANDLE symbols_handle = (HANDLE) get_osfhandle(child_in[1]);
      DumpProcSelfMaps(symbols_handle);
#else
      DumpProcSelfMaps(child_in[1]);  // what pprof expects on stdin
#endif

      // Allocate 24 bytes = ("0x" + 8 bytes + "\n" + overhead) for each
      // address to feed to pprof.
      const int kOutBufSize = 24 * symbolization_table_.size();
      char *pprof_buffer = new char[kOutBufSize];
      int written = 0;
      for (SymbolMap::const_iterator iter = symbolization_table_.begin();
           iter != symbolization_table_.end(); ++iter) {
        written += snprintf(pprof_buffer + written, kOutBufSize - written,
                 // pprof expects format to be 0xXXXXXX
                 "0x%" PRIxPTR "\n", reinterpret_cast<uintptr_t>(iter->first));
      }
      write(child_in[1], pprof_buffer, strlen(pprof_buffer));
      close(child_in[1]);             // that's all we need to write

      const int kSymbolBufferSize = kSymbolSize * symbolization_table_.size();
      int total_bytes_read = 0;
      delete[] symbol_buffer_;
      symbol_buffer_ = new char[kSymbolBufferSize];
      memset(symbol_buffer_, '\0', kSymbolBufferSize);
      while (1) {
        int bytes_read = read(child_out[1], symbol_buffer_ + total_bytes_read,
                              kSymbolBufferSize - total_bytes_read);
        if (bytes_read < 0) {
          close(child_out[1]);
          PrintError("Cannot read data from pprof");
          return 0;
        } else if (bytes_read == 0) {
          close(child_out[1]);
          wait(NULL);
          break;
        } else {
          total_bytes_read += bytes_read;
        }
      }
      // We have successfully read the output of pprof into out.  Make sure
      // the last symbol is full (we can tell because it ends with a \n).
      if (total_bytes_read == 0 || symbol_buffer_[total_bytes_read - 1] != '\n')
        return 0;
      // make the symbolization_table_ values point to the output vector
      SymbolMap::iterator fill = symbolization_table_.begin();
      int num_symbols = 0;
      const char *current_name = symbol_buffer_;
      for (int i = 0; i < total_bytes_read; i++) {
        if (symbol_buffer_[i] == '\n') {
          fill->second = current_name;
          symbol_buffer_[i] = '\0';
          current_name = symbol_buffer_ + i + 1;
          fill++;
          num_symbols++;
        }
      }
      return num_symbols;
    }
  }
  PrintError("Unkown error (should never occur!)");
  return 0;  // shouldn't be reachable
#endif
}

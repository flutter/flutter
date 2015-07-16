// Copyright (c) 2006, Google Inc.
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

// All functions here are thread-hostile due to file caching unless
// commented otherwise.

#ifndef _SYSINFO_H_
#define _SYSINFO_H_

#include <config.h>

#include <time.h>
#if (defined(_WIN32) || defined(__MINGW32__)) && (!defined(__CYGWIN__) && !defined(__CYGWIN32__))
#include <windows.h>   // for DWORD
#include <TlHelp32.h>  // for CreateToolhelp32Snapshot
#endif
#ifdef HAVE_UNISTD_H
#include <unistd.h>    // for pid_t
#endif
#include <stddef.h>    // for size_t
#include <limits.h>    // for PATH_MAX
#include "base/basictypes.h"
#include "base/logging.h"   // for RawFD

// This getenv function is safe to call before the C runtime is initialized.
// On Windows, it utilizes GetEnvironmentVariable() and on unix it uses
// /proc/self/environ instead calling getenv().  It's intended to be used in
// routines that run before main(), when the state required for getenv() may
// not be set up yet.  In particular, errno isn't set up until relatively late
// (after the pthreads library has a chance to make it threadsafe), and
// getenv() doesn't work until then. 
// On some platforms, this call will utilize the same, static buffer for
// repeated GetenvBeforeMain() calls. Callers should not expect pointers from
// this routine to be long lived.
// Note that on unix, /proc only has the environment at the time the
// application was started, so this routine ignores setenv() calls/etc.  Also
// note it only reads the first 16K of the environment.
extern const char* GetenvBeforeMain(const char* name);

// This takes as an argument an environment-variable name (like
// CPUPROFILE) whose value is supposed to be a file-path, and sets
// path to that path, and returns true.  Non-trivial for surprising
// reasons, as documented in sysinfo.cc.  path must have space PATH_MAX.
extern bool GetUniquePathFromEnv(const char* env_name, char* path);

extern int NumCPUs();

void SleepForMilliseconds(int milliseconds);

// processor cycles per second of each processor.  Thread-safe.
extern double CyclesPerSecond(void);


//  Return true if we're running POSIX (e.g., NPTL on Linux) threads,
//  as opposed to a non-POSIX thread libary.  The thing that we care
//  about is whether a thread's pid is the same as the thread that
//  spawned it.  If so, this function returns true.
//  Thread-safe.
//  Note: We consider false negatives to be OK.
bool HasPosixThreads();

#ifndef SWIG  // SWIG doesn't like struct Buffer and variable arguments.

// A ProcMapsIterator abstracts access to /proc/maps for a given
// process. Needs to be stack-allocatable and avoid using stdio/malloc
// so it can be used in the google stack dumper, heap-profiler, etc.
//
// On Windows and Mac OS X, this iterator iterates *only* over DLLs
// mapped into this process space.  For Linux, FreeBSD, and Solaris,
// it iterates over *all* mapped memory regions, including anonymous
// mmaps.  For other O/Ss, it is unlikely to work at all, and Valid()
// will always return false.  Also note: this routine only works on
// FreeBSD if procfs is mounted: make sure this is in your /etc/fstab:
//    proc            /proc   procfs  rw 0 0
class ProcMapsIterator {
 public:
  struct Buffer {
#ifdef __FreeBSD__
    // FreeBSD requires us to read all of the maps file at once, so
    // we have to make a buffer that's "always" big enough
    static const size_t kBufSize = 102400;
#else   // a one-line buffer is good enough
    static const size_t kBufSize = PATH_MAX + 1024;
#endif
    char buf_[kBufSize];
  };


  // Create a new iterator for the specified pid.  pid can be 0 for "self".
  explicit ProcMapsIterator(pid_t pid);

  // Create an iterator with specified storage (for use in signal
  // handler). "buffer" should point to a ProcMapsIterator::Buffer
  // buffer can be NULL in which case a bufer will be allocated.
  ProcMapsIterator(pid_t pid, Buffer *buffer);

  // Iterate through maps_backing instead of maps if use_maps_backing
  // is true.  Otherwise the same as above.  buffer can be NULL and
  // it will allocate a buffer itself.
  ProcMapsIterator(pid_t pid, Buffer *buffer,
                   bool use_maps_backing);

  // Returns true if the iterator successfully initialized;
  bool Valid() const;

  // Returns a pointer to the most recently parsed line. Only valid
  // after Next() returns true, and until the iterator is destroyed or
  // Next() is called again.  This may give strange results on non-Linux
  // systems.  Prefer FormatLine() if that may be a concern.
  const char *CurrentLine() const { return stext_; }

  // Writes the "canonical" form of the /proc/xxx/maps info for a single
  // line to the passed-in buffer. Returns the number of bytes written,
  // or 0 if it was not able to write the complete line.  (To guarantee
  // success, buffer should have size at least Buffer::kBufSize.)
  // Takes as arguments values set via a call to Next().  The
  // "canonical" form of the line (taken from linux's /proc/xxx/maps):
  //    <start_addr(hex)>-<end_addr(hex)> <perms(rwxp)> <offset(hex)>   +
  //    <major_dev(hex)>:<minor_dev(hex)> <inode> <filename> Note: the
  // eg
  //    08048000-0804c000 r-xp 00000000 03:01 3793678    /bin/cat
  // If you don't have the dev_t (dev), feel free to pass in 0.
  // (Next() doesn't return a dev_t, though NextExt does.)
  //
  // Note: if filename and flags were obtained via a call to Next(),
  // then the output of this function is only valid if Next() returned
  // true, and only until the iterator is destroyed or Next() is
  // called again.  (Since filename, at least, points into CurrentLine.)
  static int FormatLine(char* buffer, int bufsize,
                        uint64 start, uint64 end, const char *flags,
                        uint64 offset, int64 inode, const char *filename,
                        dev_t dev);

  // Find the next entry in /proc/maps; return true if found or false
  // if at the end of the file.
  //
  // Any of the result pointers can be NULL if you're not interested
  // in those values.
  //
  // If "flags" and "filename" are passed, they end up pointing to
  // storage within the ProcMapsIterator that is valid only until the
  // iterator is destroyed or Next() is called again. The caller may
  // modify the contents of these strings (up as far as the first NUL,
  // and only until the subsequent call to Next()) if desired.

  // The offsets are all uint64 in order to handle the case of a
  // 32-bit process running on a 64-bit kernel
  //
  // IMPORTANT NOTE: see top-of-class notes for details about what
  // mapped regions Next() iterates over, depending on O/S.
  // TODO(csilvers): make flags and filename const.
  bool Next(uint64 *start, uint64 *end, char **flags,
            uint64 *offset, int64 *inode, char **filename);

  bool NextExt(uint64 *start, uint64 *end, char **flags,
               uint64 *offset, int64 *inode, char **filename,
               uint64 *file_mapping, uint64 *file_pages,
               uint64 *anon_mapping, uint64 *anon_pages,
               dev_t *dev);

  ~ProcMapsIterator();

 private:
  void Init(pid_t pid, Buffer *buffer, bool use_maps_backing);

  char *ibuf_;        // input buffer
  char *stext_;       // start of text
  char *etext_;       // end of text
  char *nextline_;    // start of next line
  char *ebuf_;        // end of buffer (1 char for a nul)
#if (defined(_WIN32) || defined(__MINGW32__)) && (!defined(__CYGWIN__) && !defined(__CYGWIN32__))
  HANDLE snapshot_;   // filehandle on dll info
  // In a change from the usual W-A pattern, there is no A variant of
  // MODULEENTRY32.  Tlhelp32.h #defines the W variant, but not the A.
  // We want the original A variants, and this #undef is the only
  // way I see to get them.  Redefining it when we're done prevents us
  // from affecting other .cc files.
# ifdef MODULEENTRY32  // Alias of W
#   undef MODULEENTRY32
  MODULEENTRY32 module_;   // info about current dll (and dll iterator)
#   define MODULEENTRY32 MODULEENTRY32W
# else  // It's the ascii, the one we want.
  MODULEENTRY32 module_;   // info about current dll (and dll iterator)
# endif
#elif defined(__MACH__)
  int current_image_; // dll's are called "images" in macos parlance
  int current_load_cmd_;   // the segment of this dll we're examining
#elif defined(__sun__)     // Solaris
  int fd_;
  char current_filename_[PATH_MAX];
#else
  int fd_;            // filehandle on /proc/*/maps
#endif
  pid_t pid_;
  char flags_[10];
  Buffer* dynamic_buffer_;  // dynamically-allocated Buffer
  bool using_maps_backing_; // true if we are looking at maps_backing instead of maps.
};

#endif  /* #ifndef SWIG */

// Helper routines

namespace tcmalloc {
int FillProcSelfMaps(char buf[], int size, bool* wrote_all);
void DumpProcSelfMaps(RawFD fd);
}

#endif   /* #ifndef _SYSINFO_H_ */

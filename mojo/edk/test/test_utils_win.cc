// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/test/test_utils.h"

#include <windows.h>
#include <fcntl.h>
#include <io.h>
#include <string.h>

namespace mojo {
namespace test {

bool BlockingWrite(const embedder::PlatformHandle& handle,
                   const void* buffer,
                   size_t bytes_to_write,
                   size_t* bytes_written) {
  OVERLAPPED overlapped = {0};
  DWORD bytes_written_dword = 0;

  if (!WriteFile(handle.handle, buffer, static_cast<DWORD>(bytes_to_write),
                 &bytes_written_dword, &overlapped)) {
    if (GetLastError() != ERROR_IO_PENDING ||
        !GetOverlappedResult(handle.handle, &overlapped, &bytes_written_dword,
                             TRUE)) {
      return false;
    }
  }

  *bytes_written = bytes_written_dword;
  return true;
}

bool BlockingRead(const embedder::PlatformHandle& handle,
                  void* buffer,
                  size_t buffer_size,
                  size_t* bytes_read) {
  OVERLAPPED overlapped = {0};
  DWORD bytes_read_dword = 0;

  if (!ReadFile(handle.handle, buffer, static_cast<DWORD>(buffer_size),
                &bytes_read_dword, &overlapped)) {
    if (GetLastError() != ERROR_IO_PENDING ||
        !GetOverlappedResult(handle.handle, &overlapped, &bytes_read_dword,
                             TRUE)) {
      return false;
    }
  }

  *bytes_read = bytes_read_dword;
  return true;
}

bool NonBlockingRead(const embedder::PlatformHandle& handle,
                     void* buffer,
                     size_t buffer_size,
                     size_t* bytes_read) {
  OVERLAPPED overlapped = {0};
  DWORD bytes_read_dword = 0;

  if (!ReadFile(handle.handle, buffer, static_cast<DWORD>(buffer_size),
                &bytes_read_dword, &overlapped)) {
    if (GetLastError() != ERROR_IO_PENDING)
      return false;

    CancelIo(handle.handle);

    if (!GetOverlappedResult(handle.handle, &overlapped, &bytes_read_dword,
                             TRUE)) {
      *bytes_read = 0;
      return true;
    }
  }

  *bytes_read = bytes_read_dword;
  return true;
}

embedder::ScopedPlatformHandle PlatformHandleFromFILE(base::ScopedFILE fp) {
  CHECK(fp);

  HANDLE rv = INVALID_HANDLE_VALUE;
  PCHECK(DuplicateHandle(
      GetCurrentProcess(),
      reinterpret_cast<HANDLE>(_get_osfhandle(_fileno(fp.get()))),
      GetCurrentProcess(), &rv, 0, TRUE, DUPLICATE_SAME_ACCESS))
      << "DuplicateHandle";
  return embedder::ScopedPlatformHandle(embedder::PlatformHandle(rv));
}

base::ScopedFILE FILEFromPlatformHandle(embedder::ScopedPlatformHandle h,
                                        const char* mode) {
  CHECK(h.is_valid());
  // Microsoft's documentation for |_open_osfhandle()| only discusses these
  // flags (and |_O_WTEXT|). Hmmm.
  int flags = 0;
  if (strchr(mode, 'a'))
    flags |= _O_APPEND;
  if (strchr(mode, 'r'))
    flags |= _O_RDONLY;
  if (strchr(mode, 't'))
    flags |= _O_TEXT;
  base::ScopedFILE rv(_fdopen(
      _open_osfhandle(reinterpret_cast<intptr_t>(h.release().handle), flags),
      mode));
  PCHECK(rv) << "_fdopen";
  return rv.Pass();
}

}  // namespace test
}  // namespace mojo

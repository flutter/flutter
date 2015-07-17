// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_FILES_MEMORY_MAPPED_FILE_H_
#define BASE_FILES_MEMORY_MAPPED_FILE_H_

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/files/file.h"
#include "build/build_config.h"

#if defined(OS_WIN)
#include <windows.h>
#endif

namespace base {

class FilePath;

class BASE_EXPORT MemoryMappedFile {
 public:
  // The default constructor sets all members to invalid/null values.
  MemoryMappedFile();
  ~MemoryMappedFile();

  // Used to hold information about a region [offset + size] of a file.
  struct BASE_EXPORT Region {
    static const Region kWholeFile;

    bool operator==(const Region& other) const;
    bool operator!=(const Region& other) const;

    // Start of the region (measured in bytes from the beginning of the file).
    int64 offset;

    // Length of the region in bytes.
    int64 size;
  };

  // Opens an existing file and maps it into memory. Access is restricted to
  // read only. If this object already points to a valid memory mapped file
  // then this method will fail and return false. If it cannot open the file,
  // the file does not exist, or the memory mapping fails, it will return false.
  // Later we may want to allow the user to specify access.
  bool Initialize(const FilePath& file_name);

  // As above, but works with an already-opened file. MemoryMappedFile takes
  // ownership of |file| and closes it when done.
  bool Initialize(File file);

  // As above, but works with a region of an already-opened file.
  bool Initialize(File file, const Region& region);

#if defined(OS_WIN)
  // Opens an existing file and maps it as an image section. Please refer to
  // the Initialize function above for additional information.
  bool InitializeAsImageSection(const FilePath& file_name);
#endif  // OS_WIN

  const uint8* data() const { return data_; }
  size_t length() const { return length_; }

  // Is file_ a valid file handle that points to an open, memory mapped file?
  bool IsValid() const;

 private:
  // Given the arbitrarily aligned memory region [start, size], returns the
  // boundaries of the region aligned to the granularity specified by the OS,
  // (a page on Linux, ~32k on Windows) as follows:
  // - |aligned_start| is page aligned and <= |start|.
  // - |aligned_size| is a multiple of the VM granularity and >= |size|.
  // - |offset| is the displacement of |start| w.r.t |aligned_start|.
  static void CalculateVMAlignedBoundaries(int64 start,
                                           int64 size,
                                           int64* aligned_start,
                                           int64* aligned_size,
                                           int32* offset);

  // Map the file to memory, set data_ to that memory address. Return true on
  // success, false on any kind of failure. This is a helper for Initialize().
  bool MapFileRegionToMemory(const Region& region);

  // Closes all open handles.
  void CloseHandles();

  File file_;
  uint8* data_;
  size_t length_;

#if defined(OS_WIN)
  win::ScopedHandle file_mapping_;
  bool image_;  // Map as an image.
#endif

  DISALLOW_COPY_AND_ASSIGN(MemoryMappedFile);
};

}  // namespace base

#endif  // BASE_FILES_MEMORY_MAPPED_FILE_H_

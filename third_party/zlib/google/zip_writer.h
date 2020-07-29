// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef THIRD_PARTY_ZLIB_GOOGLE_ZIP_WRITER_H_
#define THIRD_PARTY_ZLIB_GOOGLE_ZIP_WRITER_H_

#include <memory>
#include <vector>

#include "base/files/file_path.h"
#include "build/build_config.h"
#include "third_party/zlib/google/zip.h"

#if defined(USE_SYSTEM_MINIZIP)
#include <minizip/unzip.h>
#include <minizip/zip.h>
#else
#include "third_party/zlib/contrib/minizip/unzip.h"
#include "third_party/zlib/contrib/minizip/zip.h"
#endif

namespace zip {
namespace internal {

// A class used to write entries to a ZIP file and buffering the reading of
// files to limit the number of calls to the FileAccessor. This is for
// performance reasons as these calls may be expensive when IPC based).
// This class is so far internal and only used by zip.cc, but could be made
// public if needed.
class ZipWriter {
 public:
// Creates a writer that will write a ZIP file to |zip_file_fd|/|zip_file|
// and which entries (specifies with AddEntries) are relative to |root_dir|.
// All file reads are performed using |file_accessor|.
#if defined(OS_POSIX)
  static std::unique_ptr<ZipWriter> CreateWithFd(int zip_file_fd,
                                                 const base::FilePath& root_dir,
                                                 FileAccessor* file_accessor);
#endif
  static std::unique_ptr<ZipWriter> Create(const base::FilePath& zip_file,
                                           const base::FilePath& root_dir,
                                           FileAccessor* file_accessor);
  ~ZipWriter();

  // Writes the files at |paths| to the ZIP file and closes this Zip file.
  // Note that the the FilePaths must be relative to |root_dir| specified in the
  // Create method.
  // Returns true if all entries were written successfuly.
  bool WriteEntries(const std::vector<base::FilePath>& paths);

 private:
  ZipWriter(zipFile zip_file,
            const base::FilePath& root_dir,
            FileAccessor* file_accessor);

  // Writes the pending entries to the ZIP file if there are at least
  // |kMaxPendingEntriesCount| of them. If |force| is true, all pending entries
  // are written regardless of how many there are.
  // Returns false if writing an entry fails, true if no entry was written or
  // there was no error writing entries.
  bool FlushEntriesIfNeeded(bool force);

  // Adds the files at |paths| to the ZIP file. These FilePaths must be relative
  // to |root_dir| specified in the Create method.
  bool AddEntries(const std::vector<base::FilePath>& paths);

  // Closes the ZIP file.
  // Returns true if successful, false otherwise (typically if an entry failed
  // to be written).
  bool Close();

  // The entries that have been added but not yet written to the ZIP file.
  std::vector<base::FilePath> pending_entries_;

  // The actual zip file.
  zipFile zip_file_;

  // Path to the directory entry paths are relative to.
  base::FilePath root_dir_;

  // Abstraction over file access methods used to read files.
  FileAccessor* file_accessor_;

  DISALLOW_COPY_AND_ASSIGN(ZipWriter);
};

}  // namespace internal
}  // namespace zip

#endif  // THIRD_PARTY_ZLIB_GOOGLE_ZIP_WRITER_H_
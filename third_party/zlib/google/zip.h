// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef THIRD_PARTY_ZLIB_GOOGLE_ZIP_H_
#define THIRD_PARTY_ZLIB_GOOGLE_ZIP_H_

#include <vector>

#include "base/callback.h"
#include "base/files/file_path.h"
#include "base/files/platform_file.h"
#include "base/time/time.h"
#include "build/build_config.h"

namespace base {
class File;
}

namespace zip {

class WriterDelegate;

// Abstraction for file access operation required by Zip().
// Can be passed to the ZipParams for providing custom access to the files,
// for example over IPC.
// If none is provided, the files are accessed directly.
// All parameters paths are expected to be absolute.
class FileAccessor {
 public:
  virtual ~FileAccessor() = default;

  struct DirectoryContentEntry {
    DirectoryContentEntry(const base::FilePath& path, bool is_directory)
        : path(path), is_directory(is_directory) {}
    base::FilePath path;
    bool is_directory = false;
  };

  // Opens files specified in |paths|.
  // Directories should be mapped to invalid files.
  virtual std::vector<base::File> OpenFilesForReading(
      const std::vector<base::FilePath>& paths) = 0;

  virtual bool DirectoryExists(const base::FilePath& path) = 0;
  virtual std::vector<DirectoryContentEntry> ListDirectoryContent(
      const base::FilePath& dir_path) = 0;
  virtual base::Time GetLastModifiedTime(const base::FilePath& path) = 0;
};

class ZipParams {
 public:
  ZipParams(const base::FilePath& src_dir, const base::FilePath& dest_file);
#if defined(OS_POSIX)
  // Does not take ownership of |dest_fd|.
  ZipParams(const base::FilePath& src_dir, int dest_fd);

  int dest_fd() const { return dest_fd_; }
#endif

  const base::FilePath& src_dir() const { return src_dir_; }

  const base::FilePath& dest_file() const { return dest_file_; }

  // Restricts the files actually zipped to the paths listed in
  // |src_relative_paths|. They must be relative to the |src_dir| passed in the
  // constructor and will be used as the file names in the created zip file. All
  // source paths must be under |src_dir| in the file system hierarchy.
  void set_files_to_zip(const std::vector<base::FilePath>& src_relative_paths) {
    src_files_ = src_relative_paths;
  }
  const std::vector<base::FilePath>& files_to_zip() const { return src_files_; }

  using FilterCallback = base::RepeatingCallback<bool(const base::FilePath&)>;
  void set_filter_callback(FilterCallback filter_callback) {
    filter_callback_ = filter_callback;
  }
  const FilterCallback& filter_callback() const { return filter_callback_; }

  void set_include_hidden_files(bool include_hidden_files) {
    include_hidden_files_ = include_hidden_files;
  }
  bool include_hidden_files() const { return include_hidden_files_; }

  // Sets a custom file accessor for file operations. Default is to directly
  // access the files (with fopen and the rest).
  // Useful in cases where running in a sandbox process and file access has to
  // go through IPC, for example.
  void set_file_accessor(std::unique_ptr<FileAccessor> file_accessor) {
    file_accessor_ = std::move(file_accessor);
  }
  FileAccessor* file_accessor() const { return file_accessor_.get(); }

 private:
  base::FilePath src_dir_;

  base::FilePath dest_file_;
#if defined(OS_POSIX)
  int dest_fd_ = base::kInvalidPlatformFile;
#endif

  // The relative paths to the files that should be included in the zip file. If
  // this is empty, all files in |src_dir_| are included.
  std::vector<base::FilePath> src_files_;

  // Filter used to exclude files from the ZIP file. Only effective when
  // |src_files_| is empty.
  FilterCallback filter_callback_;

  // Whether hidden files should be included in the ZIP file. Only effective
  // when |src_files_| is empty.
  bool include_hidden_files_ = true;

  // Abstraction around file system access used to read files. An implementation
  // that accesses files directly is provided by default.
  std::unique_ptr<FileAccessor> file_accessor_;
};

// Zip files specified into a ZIP archives. The source files and ZIP destination
// files (as well as other settings) are specified in |params|.
bool Zip(const ZipParams& params);

// Zip the contents of src_dir into dest_file. src_path must be a directory.
// An entry will *not* be created in the zip for the root folder -- children
// of src_dir will be at the root level of the created zip. For each file in
// src_dir, include it only if the callback |filter_cb| returns true. Otherwise
// omit it.
using FilterCallback = base::RepeatingCallback<bool(const base::FilePath&)>;
bool ZipWithFilterCallback(const base::FilePath& src_dir,
                           const base::FilePath& dest_file,
                           const FilterCallback& filter_cb);

// Convenience method for callers who don't need to set up the filter callback.
// If |include_hidden_files| is true, files starting with "." are included.
// Otherwise they are omitted.
bool Zip(const base::FilePath& src_dir, const base::FilePath& dest_file,
         bool include_hidden_files);

#if defined(OS_POSIX)
// Zips files listed in |src_relative_paths| to destination specified by file
// descriptor |dest_fd|, without taking ownership of |dest_fd|. The paths listed
// in |src_relative_paths| are relative to the |src_dir| and will be used as the
// file names in the created zip file. All source paths must be under |src_dir|
// in the file system hierarchy.
bool ZipFiles(const base::FilePath& src_dir,
              const std::vector<base::FilePath>& src_relative_paths,
              int dest_fd);
#endif  // defined(OS_POSIX)

// Unzip the contents of zip_file into dest_dir.
// For each file in zip_file, include it only if the callback |filter_cb|
// returns true. Otherwise omit it.
// If |log_skipped_files| is true, files skipped during extraction are printed
// to debug log.
using FilterCallback = base::RepeatingCallback<bool(const base::FilePath&)>;
bool UnzipWithFilterCallback(const base::FilePath& zip_file,
                             const base::FilePath& dest_dir,
                             const FilterCallback& filter_cb,
                             bool log_skipped_files);

// Unzip the contents of zip_file, using the writers provided by writer_factory.
// For each file in zip_file, include it only if the callback |filter_cb|
// returns true. Otherwise omit it.
// If |log_skipped_files| is true, files skipped during extraction are printed
// to debug log.
typedef base::RepeatingCallback<std::unique_ptr<WriterDelegate>(
    const base::FilePath&)>
    WriterFactory;
typedef base::RepeatingCallback<bool(const base::FilePath&)> DirectoryCreator;
bool UnzipWithFilterAndWriters(const base::PlatformFile& zip_file,
                               const WriterFactory& writer_factory,
                               const DirectoryCreator& directory_creator,
                               const FilterCallback& filter_cb,
                               bool log_skipped_files);

// Unzip the contents of zip_file into dest_dir.
bool Unzip(const base::FilePath& zip_file, const base::FilePath& dest_dir);

}  // namespace zip

#endif  // THIRD_PARTY_ZLIB_GOOGLE_ZIP_H_

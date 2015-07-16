// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_FILES_FILE_ENUMERATOR_H_
#define BASE_FILES_FILE_ENUMERATOR_H_

#include <stack>
#include <vector>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/files/file_path.h"
#include "base/time/time.h"
#include "build/build_config.h"

#if defined(OS_WIN)
#include <windows.h>
#elif defined(OS_POSIX)
#include <sys/stat.h>
#include <unistd.h>
#endif

namespace base {

// A class for enumerating the files in a provided path. The order of the
// results is not guaranteed.
//
// This is blocking. Do not use on critical threads.
//
// Example:
//
//   base::FileEnumerator enum(my_dir, false, base::FileEnumerator::FILES,
//                             FILE_PATH_LITERAL("*.txt"));
//   for (base::FilePath name = enum.Next(); !name.empty(); name = enum.Next())
//     ...
class BASE_EXPORT FileEnumerator {
 public:
  // Note: copy & assign supported.
  class BASE_EXPORT FileInfo {
   public:
    FileInfo();
    ~FileInfo();

    bool IsDirectory() const;

    // The name of the file. This will not include any path information. This
    // is in constrast to the value returned by FileEnumerator.Next() which
    // includes the |root_path| passed into the FileEnumerator constructor.
    FilePath GetName() const;

    int64 GetSize() const;
    Time GetLastModifiedTime() const;

#if defined(OS_WIN)
    // Note that the cAlternateFileName (used to hold the "short" 8.3 name)
    // of the WIN32_FIND_DATA will be empty. Since we don't use short file
    // names, we tell Windows to omit it which speeds up the query slightly.
    const WIN32_FIND_DATA& find_data() const { return find_data_; }
#elif defined(OS_POSIX)
    const struct stat& stat() const { return stat_; }
#endif

   private:
    friend class FileEnumerator;

#if defined(OS_WIN)
    WIN32_FIND_DATA find_data_;
#elif defined(OS_POSIX)
    struct stat stat_;
    FilePath filename_;
#endif
  };

  enum FileType {
    FILES                 = 1 << 0,
    DIRECTORIES           = 1 << 1,
    INCLUDE_DOT_DOT       = 1 << 2,
#if defined(OS_POSIX)
    SHOW_SYM_LINKS        = 1 << 4,
#endif
  };

  // |root_path| is the starting directory to search for. It may or may not end
  // in a slash.
  //
  // If |recursive| is true, this will enumerate all matches in any
  // subdirectories matched as well. It does a breadth-first search, so all
  // files in one directory will be returned before any files in a
  // subdirectory.
  //
  // |file_type|, a bit mask of FileType, specifies whether the enumerator
  // should match files, directories, or both.
  //
  // |pattern| is an optional pattern for which files to match. This
  // works like shell globbing. For example, "*.txt" or "Foo???.doc".
  // However, be careful in specifying patterns that aren't cross platform
  // since the underlying code uses OS-specific matching routines.  In general,
  // Windows matching is less featureful than others, so test there first.
  // If unspecified, this will match all files.
  // NOTE: the pattern only matches the contents of root_path, not files in
  // recursive subdirectories.
  // TODO(erikkay): Fix the pattern matching to work at all levels.
  FileEnumerator(const FilePath& root_path,
                 bool recursive,
                 int file_type);
  FileEnumerator(const FilePath& root_path,
                 bool recursive,
                 int file_type,
                 const FilePath::StringType& pattern);
  ~FileEnumerator();

  // Returns the next file or an empty string if there are no more results.
  //
  // The returned path will incorporate the |root_path| passed in the
  // constructor: "<root_path>/file_name.txt". If the |root_path| is absolute,
  // then so will be the result of Next().
  FilePath Next();

  // Write the file info into |info|.
  FileInfo GetInfo() const;

 private:
  // Returns true if the given path should be skipped in enumeration.
  bool ShouldSkip(const FilePath& path);

#if defined(OS_WIN)
  // True when find_data_ is valid.
  bool has_find_data_;
  WIN32_FIND_DATA find_data_;
  HANDLE find_handle_;
#elif defined(OS_POSIX)

  // Read the filenames in source into the vector of DirectoryEntryInfo's
  static bool ReadDirectory(std::vector<FileInfo>* entries,
                            const FilePath& source, bool show_links);

  // The files in the current directory
  std::vector<FileInfo> directory_entries_;

  // The next entry to use from the directory_entries_ vector
  size_t current_directory_entry_;
#endif

  FilePath root_path_;
  bool recursive_;
  int file_type_;
  FilePath::StringType pattern_;  // Empty when we want to find everything.

  // A stack that keeps track of which subdirectories we still need to
  // enumerate in the breadth-first search.
  std::stack<FilePath> pending_paths_;

  DISALLOW_COPY_AND_ASSIGN(FileEnumerator);
};

}  // namespace base

#endif  // BASE_FILES_FILE_ENUMERATOR_H_

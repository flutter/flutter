// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef THIRD_PARTY_ZLIB_GOOGLE_ZIP_H_
#define THIRD_PARTY_ZLIB_GOOGLE_ZIP_H_

#include <vector>

#include "base/callback.h"
#include "base/files/file_path.h"

namespace zip {

// Zip the contents of src_dir into dest_file. src_path must be a directory.
// An entry will *not* be created in the zip for the root folder -- children
// of src_dir will be at the root level of the created zip. For each file in
// src_dir, include it only if the callback |filter_cb| returns true. Otherwise
// omit it.
typedef base::Callback<bool(const base::FilePath&)> FilterCallback;
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
bool Unzip(const base::FilePath& zip_file, const base::FilePath& dest_dir);

}  // namespace zip

#endif  // THIRD_PARTY_ZLIB_GOOGLE_ZIP_H_
